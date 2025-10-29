// filtered-queries.ts
// Specialized filtering patterns for common use cases

import { getCollection, type CollectionEntry } from 'astro:content';

/**
 * Filter posts by category (from tags or custom field)
 */
export async function getPostsByCategory(category: string) {
  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      (data.categories?.includes(category) || data.tags?.includes(category))
    );
  });

  return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

/**
 * Get posts from current year
 */
export async function getPostsThisYear() {
  const currentYear = new Date().getFullYear();

  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      data.pubDate.getFullYear() === currentYear
    );
  });

  return posts;
}

/**
 * Get posts from current month
 */
export async function getPostsThisMonth() {
  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth();

  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      data.pubDate.getFullYear() === currentYear &&
      data.pubDate.getMonth() === currentMonth
    );
  });

  return posts;
}

/**
 * Get posts updated recently (within last N days)
 */
export async function getRecentlyUpdatedPosts(days = 7) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      data.updatedDate &&
      data.updatedDate >= cutoffDate
    );
  });

  return posts.sort((a, b) => {
    const aDate = a.data.updatedDate || a.data.pubDate;
    const bDate = b.data.updatedDate || b.data.pubDate;
    return bDate.valueOf() - aDate.valueOf();
  });
}

/**
 * Get posts by multiple authors
 */
export async function getPostsByAuthors(authors: string[]) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true && authors.includes(data.author);
  });

  return posts;
}

/**
 * Get popular posts (by view count or rating if available)
 * This assumes you have custom fields for popularity metrics
 */
export async function getPopularPosts(limit = 10) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true;
  });

  // Sort by custom popularity metric if available
  // Fallback to publication date
  return posts
    .sort((a, b) => {
      // If you have view count or rating fields:
      // return (b.data.viewCount || 0) - (a.data.viewCount || 0);
      return b.data.pubDate.valueOf() - a.data.pubDate.valueOf();
    })
    .slice(0, limit);
}

/**
 * Get posts with hero images
 */
export async function getPostsWithImages() {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true && data.heroImage !== undefined;
  });

  return posts;
}

/**
 * Get posts without hero images (for maintenance)
 */
export async function getPostsWithoutImages() {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true && !data.heroImage;
  });

  return posts;
}

/**
 * Get posts in a specific series
 */
export async function getPostsInSeries(seriesName: string) {
  const posts = await getCollection('blog', ({ data }) => {
    return data.draft !== true && data.series === seriesName;
  });

  // Sort by series order if available
  return posts.sort((a, b) => {
    const orderA = a.data.seriesOrder || 999;
    const orderB = b.data.seriesOrder || 999;
    return orderA - orderB;
  });
}

/**
 * Get posts with specific reading time range (in minutes)
 */
export async function getPostsByReadingTime(minMinutes: number, maxMinutes: number) {
  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      data.readingTime !== undefined &&
      data.readingTime >= minMinutes &&
      data.readingTime <= maxMinutes
    );
  });

  return posts;
}

/**
 * Get quick reads (< 5 minutes)
 */
export async function getQuickReads() {
  return getPostsByReadingTime(0, 5);
}

/**
 * Get in-depth articles (> 15 minutes)
 */
export async function getInDepthArticles() {
  return getPostsByReadingTime(15, 999);
}

/**
 * Get posts excluding specific tags
 */
export async function getPostsExcludingTags(excludeTags: string[]) {
  const posts = await getCollection('blog', ({ data }) => {
    if (data.draft) return false;

    // Check if post has any excluded tags
    const hasExcludedTag = excludeTags.some(tag =>
      data.tags?.includes(tag)
    );

    return !hasExcludedTag;
  });

  return posts;
}

/**
 * Get posts by tag with minimum post count
 * Returns tags that have at least minCount posts
 */
export async function getPostsByPopularTags(minCount = 3) {
  const posts = await getCollection('blog', ({ data }) => data.draft !== true);

  // Count posts per tag
  const tagCounts: Record<string, CollectionEntry<'blog'>[]> = {};

  posts.forEach(post => {
    post.data.tags?.forEach(tag => {
      if (!tagCounts[tag]) {
        tagCounts[tag] = [];
      }
      tagCounts[tag].push(post);
    });
  });

  // Filter tags by minimum count
  const popularTags = Object.entries(tagCounts)
    .filter(([_, posts]) => posts.length >= minCount)
    .reduce((acc, [tag, posts]) => {
      acc[tag] = posts;
      return acc;
    }, {} as Record<string, CollectionEntry<'blog'>[]>);

  return popularTags;
}

/**
 * Get archive structure (year -> month -> posts)
 */
export async function getArchiveStructure() {
  const posts = await getCollection('blog', ({ data }) => data.draft !== true);

  const archive: Record<number, Record<number, CollectionEntry<'blog'>[]>> = {};

  posts.forEach(post => {
    const year = post.data.pubDate.getFullYear();
    const month = post.data.pubDate.getMonth() + 1;

    if (!archive[year]) {
      archive[year] = {};
    }
    if (!archive[year][month]) {
      archive[year][month] = [];
    }

    archive[year][month].push(post);
  });

  return archive;
}

/**
 * Example usage:
 *
 * // Get posts by category
 * const tutorials = await getPostsByCategory('tutorial');
 *
 * // Get recent updates
 * const updated = await getRecentlyUpdatedPosts(7);
 *
 * // Get posts in series
 * const seriesPosts = await getPostsInSeries('Astro Basics');
 *
 * // Get quick reads
 * const quickReads = await getQuickReads();
 *
 * // Get archive structure
 * const archive = await getArchiveStructure();
 */
