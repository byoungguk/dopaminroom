import { getCollection } from 'astro:content';

// 공개 글만 최신순으로 반환 (draft: true 제외)
export async function getPublishedPosts() {
  const posts = await getCollection('blog', ({ data }) => !data.draft);
  return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}
