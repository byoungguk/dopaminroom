// 배포 경로(base)를 붙인 내부 링크. 도메인 연결 전 github.io/저장소명/ 에서도 링크가 동작하게 함.
const base = import.meta.env.BASE_URL.replace(/\/$/, '');

export const withBase = (path: string) => `${base}${path}`;
