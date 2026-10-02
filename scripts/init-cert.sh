#!/usr/bin/env bash
# 최초 1회만 실행한다. 80 포트 상태에서 인증서를 발급한 뒤 443 설정을 활성화한다.
#
#   테스트:  ./scripts/init-cert.sh --dry-run
#   실제:    ./scripts/init-cert.sh
#
# --dry-run 은 Let's Encrypt 스테이징 검증만 수행하며 실제 인증서를 발급하지 않는다.
# 발급 횟수 제한이 있으므로 실 발급 전에 반드시 --dry-run 으로 확인한다.
#
# 대표 주소(USE_WWW 값에 따라 www 유무)를 정하고, 실제로 이 서버를 가리키는
# 호스트만 골라 인증서에 담는다. 가리키지 않는 호스트를 넣으면 발급 전체가 실패한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DRY_RUN=""
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN="--dry-run"
  echo "[cert] dry-run 모드: 실제 인증서는 발급되지 않습니다."
fi

if [ ! -f .env ]; then
  echo "[cert] .env 파일이 없습니다." >&2
  exit 1
fi
# shellcheck disable=SC1091
set -a; . ./.env; set +a

: "${DOMAIN:?[cert] .env 의 DOMAIN 값이 비어 있습니다.}"
CERT_DOMAIN="${DOMAIN_PUNYCODE:-$DOMAIN}"

# 대표 주소. USE_WWW=1 이면 www 붙은 주소가 대표가 된다.
USE_WWW="${USE_WWW:-1}"
if [ "$USE_WWW" = "1" ]; then
  PRIMARY="www.${CERT_DOMAIN}"
  SECONDARY="${CERT_DOMAIN}"
else
  PRIMARY="${CERT_DOMAIN}"
  SECONDARY="www.${CERT_DOMAIN}"
fi

# EMAIL 이 비어 있거나 CHANGE_ME 이면 이메일 없이 발급한다.
# 만료 알림 메일은 오지 않지만 certbot 컨테이너가 12시간 주기로
# 자동 갱신하므로 운영에는 지장이 없다.
if [ -z "${EMAIL:-}" ] || echo "${EMAIL}" | grep -qi "CHANGE_ME"; then
  ACCOUNT_ARGS=(--register-unsafely-without-email)
  echo "[cert] 알림 이메일 없이 발급합니다."
else
  ACCOUNT_ARGS=(--email "$EMAIL")
  echo "[cert] 알림 이메일: ${EMAIL}"
fi

CONF_D="$ROOT/nginx/conf.d"
BACKUP="$(mktemp -d)"
cp "$CONF_D/site.conf" "$BACKUP/site.conf"
[ -f "$CONF_D/site-ssl.conf" ] && cp "$CONF_D/site-ssl.conf" "$BACKUP/site-ssl.conf"

# 443 설정을 만드는 함수. 발급 직후와 재적용 때 모두 쓴다.
apply_ssl_conf() {
  sed -e "s|__CERTNAME__|${PRIMARY}|g" \
      -e "s|__PRIMARY__|${PRIMARY}|g" \
      -e "s|__DOMAIN__|${CERT_DOMAIN}|g" \
      "$CONF_D/site-ssl.conf.disabled" > "$CONF_D/site-ssl.conf"
  sed -e "s|__PRIMARY__|${PRIMARY}|g" \
      -e "s|__DOMAIN__|${CERT_DOMAIN}|g" \
      "$CONF_D/site.conf.redirect" > "$CONF_D/site.conf"
}

# 중단되거나 실패해도 사이트가 끊기지 않게 원래 설정으로 되돌린다.
# 443 설정이 있었으면 그것까지 함께 되살린다. site.conf 만 되돌리면
# https 로 넘기는데 받아줄 서버가 없는 상태가 되어 접속이 끊긴다.
rollback() {
  echo "[cert] 롤백: 이전 설정으로 되돌립니다." >&2
  cp "$BACKUP/site.conf" "$CONF_D/site.conf"
  if [ -f "$BACKUP/site-ssl.conf" ]; then
    cp "$BACKUP/site-ssl.conf" "$CONF_D/site-ssl.conf"
  else
    rm -f "$CONF_D/site-ssl.conf"
  fi
  docker compose up -d nginx >/dev/null 2>&1 || true
  docker compose exec -T nginx nginx -s reload >/dev/null 2>&1 || true
}

# 강제 종료 신호에도 롤백이 돌게 한다.
trap 'rollback; exit 130' INT TERM

echo "[cert] 대표 주소: ${PRIMARY}"

# 1) 이 서버를 실제로 가리키는 호스트만 고른다
SERVER_IP="$(curl -sS --max-time 10 https://api.ipify.org 2>/dev/null || true)"
if [ -z "$SERVER_IP" ]; then
  echo "[cert] 중단: 서버의 공인 IP 를 확인하지 못했습니다." >&2
  exit 1
fi
echo "[cert] 이 서버의 주소: ${SERVER_IP}"

DOMAIN_ARGS=()
for host in "$PRIMARY" "$SECONDARY"; do
  RESOLVED="$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -1)"
  if [ "$RESOLVED" = "$SERVER_IP" ]; then
    DOMAIN_ARGS+=(-d "$host")
    echo "[cert] 포함: ${host}"
  else
    echo "[cert] 제외: ${host} (연결된 주소 ${RESOLVED:-없음})"
  fi
done

if [ ${#DOMAIN_ARGS[@]} -eq 0 ] || [ "${DOMAIN_ARGS[1]}" != "$PRIMARY" ]; then
  echo "[cert] 중단: 대표 주소 ${PRIMARY} 이(가) 이 서버를 가리키지 않습니다." >&2
  echo "[cert] A 레코드를 ${SERVER_IP} 로 설정한 뒤 다시 실행하십시오." >&2
  exit 1
fi

# 이미 발급된 인증서가 있으면 다시 요청하지 않고 설정만 다시 적용한다.
# 같은 인증서를 반복해서 요청하면 발급 횟수 제한에 걸린다.
CERT_FILE="$ROOT/certbot/conf/live/${PRIMARY}/fullchain.pem"
if [ -f "$CERT_FILE" ] || sudo -n test -f "$CERT_FILE" 2>/dev/null; then
  echo "[cert] 이미 발급된 인증서가 있습니다. 설정만 다시 적용합니다."
  apply_ssl_conf
  docker compose up -d nginx >/dev/null
  if ! docker compose exec -T nginx nginx -t; then
    rollback
    exit 1
  fi
  docker compose exec -T nginx nginx -s reload
  echo "[cert] 완료: https://${PRIMARY}"
  exit 0
fi

# 2) 443 설정을 지우고 site.conf 도 80 포트 전용으로 되돌린 뒤 기동한다.
#    site.conf 를 그대로 두면 https 로 넘기는데 받아줄 서버가 없어 접속이 끊긴다.
rm -f "$CONF_D/site-ssl.conf"
if grep -q "return 301 https" "$CONF_D/site.conf" 2>/dev/null; then
  cp "$CONF_D/site.conf.stage1" "$CONF_D/site.conf"
fi
echo "[cert] nginx 기동 (80 포트 전용)"
docker compose up -d nginx
sleep 3
docker compose exec -T nginx nginx -t

# 3) 웹루트 도달 여부 사전 확인
mkdir -p "$ROOT/certbot/www/.well-known/acme-challenge"
echo "ok" > "$ROOT/certbot/www/.well-known/acme-challenge/healthcheck"
if ! curl -sS --max-time 10 "http://localhost:${HTTP_PORT}/.well-known/acme-challenge/healthcheck" | grep -q ok; then
  echo "[cert] 실패: ACME 웹루트에 접근할 수 없습니다. nginx 설정과 포트 매핑을 확인하십시오." >&2
  rm -f "$ROOT/certbot/www/.well-known/acme-challenge/healthcheck"
  exit 1
fi
rm -f "$ROOT/certbot/www/.well-known/acme-challenge/healthcheck"
echo "[cert] 웹루트 확인 완료"

# 4) 인증서 발급
echo "[cert] certbot 실행"
if ! docker compose run --rm --entrypoint certbot certbot \
      certonly --webroot -w /var/www/certbot \
      --cert-name "$PRIMARY" \
      "${DOMAIN_ARGS[@]}" \
      "${ACCOUNT_ARGS[@]}" --agree-tos --no-eff-email --non-interactive \
      ${DRY_RUN}; then
  echo "[cert] 실패: 인증서 발급에 실패했습니다." >&2
  echo "[cert] 확인 항목" >&2
  echo "  - ${PRIMARY} 의 A 레코드가 ${SERVER_IP} 를 가리키는지" >&2
  echo "  - 80 포트가 방화벽/보안그룹에서 0.0.0.0/0 으로 열려 있는지" >&2
  rollback
  exit 1
fi

if [ -n "$DRY_RUN" ]; then
  echo "[cert] dry-run 성공. 이제 옵션 없이 다시 실행하여 실제 발급을 진행하십시오."
  exit 0
fi

# 5) 443 설정 활성화 + 80 은 리다이렉트로 교체
echo "[cert] SSL 설정 활성화"
apply_ssl_conf

docker compose up -d nginx
sleep 2
if ! docker compose exec -T nginx nginx -t; then
  echo "[cert] 실패: SSL 설정 검증에 실패했습니다." >&2
  rollback
  exit 1
fi
docker compose exec -T nginx nginx -s reload

echo "[cert] 완료: https://${PRIMARY} 으로 접속을 확인하십시오."
echo "[cert] 갱신은 certbot 컨테이너가 12시간 주기로 자동 시도하며,"
echo "[cert] 수동 갱신은 ./scripts/renew-cert.sh 를 실행합니다."
