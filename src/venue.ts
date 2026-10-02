// 사이트 내용은 content/site.json 에서 읽는다. (관리자 페이지가 이 파일을 수정한다)
// 갤러리는 public/images/gallery/ 의 파일 목록을 그대로 사용한다.
//   파일명 규칙: 01-설명.webp  → 앞의 숫자는 정렬 순서, 뒤는 설명(alt)
import fs from 'node:fs';
import path from 'node:path';
import data from '../content/site.json';

export const VENUE = data.venue;
export const STRENGTHS = data.strengths;
export const ROOMS = data.rooms;
export const AMENITIES = data.amenities;
export const STEPS = data.steps;
export const TIERS = data.tiers;
export const FEES = data.fees;
export const PRICE_NOTE = data.priceNote;
export const EVENTS = data.events;
export const FAQ = data.faq;
export const HERO_IMAGE = `images/${data.heroImage}`;

const GALLERY_DIR = path.join(process.cwd(), 'public', 'images', 'gallery');
const IMAGE_EXT = /\.(webp|jpe?g|png|avif)$/i;

function readGallery() {
  if (!fs.existsSync(GALLERY_DIR)) return [];
  return fs
    .readdirSync(GALLERY_DIR)
    .filter((file) => IMAGE_EXT.test(file))
    .sort((a, b) => a.localeCompare(b, 'ko'))
    .map((file) => ({
      src: `images/gallery/${file}`,
      // 01-샹들리에-룸.webp → "샹들리에 룸"
      alt: file.replace(IMAGE_EXT, '').replace(/^\d+[-_]?/, '').replace(/[-_]/g, ' ').trim() || '업소 사진',
    }));
}

export const PHOTOS = readGallery();
