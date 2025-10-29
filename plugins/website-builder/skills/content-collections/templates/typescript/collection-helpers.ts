// Helper functions for working with content collections
import { getCollection, type CollectionEntry } from 'astro:content';

export async function getPublishedPosts() {
  const posts = await getCollection('blog', ({ data }) => {
    return !data.draft;
  });
  return posts.sort((a, b) => b.data.date.getTime() - a.data.date.getTime());
}

export async function getPostsByTag(tag: string) {
  const posts = await getPublishedPosts();
  return posts.filter(post => post.data.tags.includes(tag));
}

export async function getAllTags() {
  const posts = await getPublishedPosts();
  const tags = new Set<string>();
  posts.forEach(post => post.data.tags.forEach(tag => tags.add(tag)));
  return Array.from(tags).sort();
}

export async function getRelatedPosts(currentSlug: string, limit: number = 3) {
  const allPosts = await getPublishedPosts();
  const currentPost = allPosts.find(p => p.slug === currentSlug);
  if (!currentPost) return [];

  return allPosts
    .filter(p => p.slug !== currentSlug)
    .filter(p => p.data.tags.some(tag => currentPost.data.tags.includes(tag)))
    .slice(0, limit);
}
