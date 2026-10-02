#!/usr/bin/env bash
# Astro 정적 파일을 빌드한다. (one-shot 컨테이너)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ ! -f .env ]; then
  echo "[build] .env 파일이 없습니다. .env.example 을 복사해 값을 채우십시오." >&2
  exit 1
fi

export HOST_UID="$(id -u)"
export HOST_GID="$(id -g)"

echo "[build] Astro 빌드 시작"
docker compose --profile build run --rm astro

if [ ! -f "$ROOT/dist/index.html" ]; then
  echo "[build] 실패: dist/index.html 이 생성되지 않았습니다." >&2
  exit 1
fi

COUNT="$(find "$ROOT/dist" -type f | wc -l | tr -d ' ')"
echo "[build] 완료: dist 에 ${COUNT}개 파일 생성"
