#!/usr/bin/env bash
# 관리 페이지가 남긴 요청을 처리하는 상주 스크립트.
#
#   - .admin/rebuild.request 가 생기면 사이트를 다시 빌드한다.
#   - 인증서가 갱신되면 nginx 에 다시 읽힌다.
#
# 관리 컨테이너에 도커 권한을 주지 않기 위해, 빌드는 호스트에서 이 스크립트가 맡는다.
# systemd 서비스로 등록해 상시 실행한다.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STATE="$ROOT/.admin"
mkdir -p "$STATE"

# 인증서가 갱신되었으면 nginx 에 새 인증서를 다시 읽히고 표시 파일을 지운다.
reload_if_renewed() {
  local flag="$ROOT/certbot/conf/.renewed"
  [ -f "$flag" ] || sudo -n test -f "$flag" 2>/dev/null || return 0
  echo "[watch] $(date '+%F %T') 인증서가 갱신되었습니다. nginx 에 다시 읽힙니다."
  docker compose exec -T nginx nginx -s reload >/dev/null 2>&1 || true
  rm -f "$flag" 2>/dev/null || sudo -n rm -f "$flag" 2>/dev/null || true
}

echo "[watch] 감시를 시작합니다. (빌드 요청 5초, 인증서 확인 60초 간격)"
last_certcheck=0

while true; do
  if [ -f "$STATE/rebuild.request" ]; then
    rm -f "$STATE/rebuild.request"
    echo "[watch] $(date '+%F %T') 변경 감지. 다시 빌드합니다."
    if "$ROOT/scripts/build.sh" >/tmp/build.log 2>&1; then
      echo "$(date '+%F %T') 반영 완료" > "$STATE/last-build.txt"
      echo "[watch] 반영 완료"
    else
      echo "$(date '+%F %T') 반영 실패 - 로그 확인 필요" > "$STATE/last-build.txt"
      echo "[watch] 반영 실패" >&2
      tail -5 /tmp/build.log >&2
    fi
  fi

  now=$(date +%s)
  if [ $((now - last_certcheck)) -ge 60 ]; then
    reload_if_renewed
    last_certcheck=$now
  fi

  sleep 5
done
