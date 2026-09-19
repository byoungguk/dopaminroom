import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// GitHub Actions 배포 시 SITE_URL / BASE_PATH 가 주입됨. 로컬·도메인 연결 후에는 기본값 사용.
export default defineConfig({
  site: process.env.SITE_URL || 'https://dopaminroom.kr',
  base: process.env.BASE_PATH || '/',
  integrations: [sitemap()],
});
