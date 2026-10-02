#!/usr/bin/env bash
# 인증서를 갱신하고, 갱신된 경우에만 nginx 를 reload 한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
set -a; . ./.env; set +a
CERT_DOMAIN="${DOMAIN_PUNYCODE:-${DOMAIN}}"
# 인증서 이름은 대표 주소를 따른다 (init-cert.sh 의 --cert-name 과 동일)
USE_WWW="${USE_WWW:-1}"
if [ "$USE_WWW" = "1" ]; then
  CERT_NAME="www.${CERT_DOMAIN}"
else
  CERT_NAME="${CERT_DOMAIN}"
fi
CERT_FILE="$ROOT/certbot/conf/live/${CERT_NAME}/fullchain.pem"

if [ ! -f "$CERT_FILE" ]; then
  echo "[renew] 발급된 인증서가 없습니다. 먼저 ./scripts/init-cert.sh 를 실행하십시오." >&2
  exit 1
fi

BEFORE="$(sha256sum "$CERT_FILE" | awk '{print $1}')"

echo "[renew] certbot renew 실행"
docker compose run --rm --entrypoint certbot certbot renew --webroot -w /var/www/certbot

AFTER="$(sha256sum "$CERT_FILE" | awk '{print $1}')"

if [ "$BEFORE" != "$AFTER" ]; then
  echo "[renew] 인증서가 갱신되었습니다. nginx reload"
  docker compose exec -T nginx nginx -s reload
else
  echo "[renew] 갱신 대상이 아닙니다. (만료 30일 이내부터 갱신됩니다)"
fi

echo "[renew] 만료일:"
docker compose run --rm --entrypoint openssl certbot x509 -enddate -noout \
  -in "/etc/letsencrypt/live/${CERT_NAME}/fullchain.pem" || true
