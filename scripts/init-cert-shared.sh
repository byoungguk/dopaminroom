#!/usr/bin/env bash
# 강남호빠 서버에 함께 올린 경우의 인증서 발급 스크립트.
#
# 인증서와 certbot 컨테이너는 그 프로젝트(기본 ~/blog)가 가지고 있으므로,
# 발급도 그쪽 compose 로 실행하고 443 설정만 활성화한다.
#
#   테스트:  ./scripts/init-cert-shared.sh --dry-run
#   실제:    ./scripts/init-cert-shared.sh
#
# 단독 서버로 운영할 때는 이 스크립트가 아니라 scripts/init-cert.sh 를 쓴다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BLOG_DIR="${BLOG_DIR:-$HOME/blog}"
DOMAIN="${DOMAIN:-dopaminroom.kr}"
PRIMARY="$DOMAIN"
SECONDARY="www.$DOMAIN"

DRY_RUN=""
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN="--dry-run"
  echo "[cert] dry-run 모드: 실제 인증서는 발급되지 않습니다."
fi

if [ ! -f "$BLOG_DIR/docker-compose.yml" ]; then
  echo "[cert] 중단: $BLOG_DIR 에서 기존 서버 구성을 찾지 못했습니다." >&2
  echo "[cert] BLOG_DIR=/경로 형태로 지정해 다시 실행하십시오." >&2
  exit 1
fi

# 1) 이 서버를 실제로 가리키는 호스트만 고른다.
#    가리키지 않는 호스트를 넣으면 발급 전체가 실패한다.
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
  echo "[cert] 중단: ${PRIMARY} 이(가) 이 서버를 가리키지 않습니다." >&2
  echo "[cert] 메일플러그 DNS 의 A 레코드를 ${SERVER_IP} 로 바꾼 뒤 다시 실행하십시오." >&2
  exit 1
fi

cd "$BLOG_DIR"

# 2) 이미 발급되어 있으면 다시 요청하지 않는다. (발급 횟수 제한 때문)
CERT_FILE="$BLOG_DIR/certbot/conf/live/${PRIMARY}/fullchain.pem"
if [ -f "$CERT_FILE" ] || sudo -n test -f "$CERT_FILE" 2>/dev/null; then
  echo "[cert] 이미 발급된 인증서가 있습니다. 설정만 다시 적용합니다."
else
  # 3) 웹루트 도달 여부 사전 확인
  mkdir -p "$BLOG_DIR/certbot/www/.well-known/acme-challenge"
  echo "ok" > "$BLOG_DIR/certbot/www/.well-known/acme-challenge/healthcheck"
  if ! curl -sS --max-time 10 "http://${PRIMARY}/.well-known/acme-challenge/healthcheck" | grep -q ok; then
    echo "[cert] 실패: ACME 웹루트에 접근할 수 없습니다." >&2
    echo "[cert] nginx 가 떠 있는지, 80 포트가 열려 있는지 확인하십시오." >&2
    rm -f "$BLOG_DIR/certbot/www/.well-known/acme-challenge/healthcheck"
    exit 1
  fi
  rm -f "$BLOG_DIR/certbot/www/.well-known/acme-challenge/healthcheck"
  echo "[cert] 웹루트 확인 완료"

  echo "[cert] certbot 실행"
  if ! docker compose run --rm --entrypoint certbot certbot \
        certonly --webroot -w /var/www/certbot \
        --cert-name "$PRIMARY" \
        "${DOMAIN_ARGS[@]}" \
        --register-unsafely-without-email --agree-tos --no-eff-email --non-interactive \
        ${DRY_RUN}; then
    echo "[cert] 실패: 인증서 발급에 실패했습니다." >&2
    exit 1
  fi

  if [ -n "$DRY_RUN" ]; then
    echo "[cert] dry-run 성공. 옵션 없이 다시 실행하여 실제 발급을 진행하십시오."
    exit 0
  fi
fi

# 4) 443 설정 활성화
CONF_D="$BLOG_DIR/nginx/conf.d"
cp "$CONF_D/dopaminroom-ssl.conf.disabled" "$CONF_D/dopaminroom-ssl.conf"

if ! docker compose exec -T nginx nginx -t; then
  echo "[cert] 실패: nginx 설정 검증에 실패했습니다. 443 설정을 되돌립니다." >&2
  rm -f "$CONF_D/dopaminroom-ssl.conf"
  docker compose exec -T nginx nginx -s reload >/dev/null 2>&1 || true
  exit 1
fi
docker compose exec -T nginx nginx -s reload

echo "[cert] 완료: https://${PRIMARY}"
echo "[cert] 이제 ${ROOT}/.env 의 BASE_URL 을 https://${PRIMARY}/ 로 바꾸고"
echo "[cert] ${ROOT}/scripts/build.sh 를 실행하십시오."
