#!/usr/bin/env bash
# 빌드 후 nginx / certbot / admin 을 기동하고 응답을 확인한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# shellcheck disable=SC1091
set -a; . ./.env; set +a

echo "[deploy] 1/4 빌드"
"$ROOT/scripts/build.sh"

echo "[deploy] 2/4 컨테이너 기동"
docker compose up -d --build admin
docker compose up -d nginx certbot

echo "[deploy] 3/4 nginx 설정 재적용"
docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

echo "[deploy] 4/4 응답 확인"
curl -I -sS --max-time 15 "http://localhost:${HTTP_PORT:-80}/" | head -n 1
curl -sS --max-time 15 -o /dev/null -w "admin: %{http_code}\n" "http://localhost:${HTTP_PORT:-80}/admin/login"
