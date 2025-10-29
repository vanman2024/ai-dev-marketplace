// basic-queries.ts
// Basic content collection query patterns

import { getCollection, getEntry, type CollectionEntry } from 'astro:content';

/**
 * Get all entries from a collection
 */
export async function getAllBlogPosts() {
  const posts = await getCollection('blog');
  return posts;
}

/**
 * Get all published posts (exclude drafts)
 */
export async function getPublishedPosts() {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true;
  });
  return posts;
}

/**
 * Get single entry by slug
 */
export async function getPostBySlug(slug: string) {
  const post = await getEntry('blog', slug);
  return post;
}

/**
 * Get posts by author
 */
export async function getPostsByAuthor(authorName: string) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.author === authorName && data.draft !== true;
  });
  return posts;
}

/**
 * Get posts by tag
 */
export async function getPostsByTag(tag: string) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.tags?.includes(tag) && data.draft !== true;
  });
  return posts;
}

/**
 * Get featured posts
 */
export async function getFeaturedPosts() {
  const posts = await getCollection('blog', ({ data }) => {
    return data.featured === true && data.draft !== true;
  });
  return posts;
}

/**
 * Get recent posts (by publication date)
 */
export async function getRecentPosts(limit = 10) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true;
  });

  return posts
    .sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf())
    .slice(0, limit);
}

/**
 * Get posts published after a specific date
 */
export async function getPostsAfterDate(date: Date) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.pubDate >= date && data.draft !== true;
  });
  return posts;
}

/**
 * Get posts by multiple tags (AND logic)
 */
export async function getPostsByTags(tags: string[]) {
  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      tags.every(tag => data.tags?.includes(tag))
    );
  });
  return posts;
}

/**
 * Get posts by any of multiple tags (OR logic)
 */
export async function getPostsByAnyTag(tags: string[]) {
  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      tags.some(tag => data.tags?.includes(tag))
    );
  });
  return posts;
}

/**
 * Type-safe helper for post data
 */
export type BlogPost = CollectionEntry<'blog'>;

/**
 * Example usage in an Astro component:
 *
 * ---
 * import { getPublishedPosts, getRecentPosts } from './queries/basic-queries';
 *
 * const allPosts = await getPublishedPosts();
 * const recentPosts = await getRecentPosts(5);
 * ---
 *
 * <h1>Recent Posts</h1>
 * {recentPosts.map(post => (
 *   <article>
 *     <h2>{post.data.title}</h2>
 *     <p>{post.data.description}</p>
 *   </article>
 * ))}
 */
