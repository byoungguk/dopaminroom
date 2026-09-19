# 도파민룸 블로그 (dopaminroom.kr)

Astro 5 기반 정적 블로그.

## 실행
```bash
npm install
npm run dev      # http://localhost:4321
npm run build    # dist/ 생성
npm run preview  # 빌드 결과 미리보기
```

## 글 쓰기
`src/content/blog/`에 `.md` 파일 추가:
```md
---
title: '제목'
description: '목록·검색결과에 보일 요약'
pubDate: 2026-09-19
tags: ['태그']
draft: false   # true면 비공개
---
본문...
```
파일 이름이 주소가 됩니다: `my-post.md` → `/blog/my-post/`

## 구조
| 경로 | 역할 |
|---|---|
| `src/consts.ts` | 사이트 이름·설명·메뉴 |
| `src/styles/global.css` | 색상·폰트 변수 (디자인 톤 변경) |
| `src/layouts/` | 공통 레이아웃, 글 레이아웃 |
| `src/components/` | 헤더·푸터·글 카드 등 |
| `src/pages/` | 홈, 블로그 목록/상세, 소개, 404, RSS |
