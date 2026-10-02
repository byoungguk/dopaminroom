# 도파민 (dopaminroom.kr)

강남 하이퍼블릭 도파민 홈페이지. Astro 정적 사이트 + Flask 관리자 페이지.

## 구조

| 경로 | 역할 |
|---|---|
| `content/site.json` | 사이트 내용 전부 (관리자 페이지가 수정) |
| `public/images/gallery/` | 갤러리 사진 (`01-설명.webp` 형식, 숫자가 정렬 순서) |
| `src/` | Astro 페이지·컴포넌트 |
| `admin/` | 관리자 페이지 (Flask) |
| `nginx/`, `scripts/`, `docker-compose.yml` | 서버 배포 구성 |
| `docs/` | 서버 구축 안내, 고객용 관리자 사용법 |

## 로컬 개발

```bash
npm install
npm run dev      # http://localhost:4321
npm run build    # dist/ 생성
```

관리자 페이지만 따로 띄울 때:

```bash
pip install -r admin/requirements.txt
DATA_FILE=$PWD/content/site.json GALLERY_DIR=$PWD/public/images/gallery \
STATE_DIR=$PWD/.admin ADMIN_USER=admin ADMIN_PASSWORD=test1234 \
python admin/app.py    # http://localhost:8000
```

## 서버 배포

- 새 서버 단독 운영: [docs/서버-구축-안내.md](docs/서버-구축-안내.md)
- 강남호빠 서버에 함께 올리기: [docs/기존서버에-추가하기.md](docs/기존서버에-추가하기.md)

```bash
cp .env.example .env   # 값 채우기
./scripts/deploy.sh    # 빌드 + 기동
./scripts/init-cert.sh # 도메인 연결 후 https
```

## 글(공지·소식) 작성

`src/content/blog/` 에 `.md` 파일 추가:

```md
---
title: '제목'
description: '요약'
pubDate: 2026-10-03
draft: false
---
본문...
```
