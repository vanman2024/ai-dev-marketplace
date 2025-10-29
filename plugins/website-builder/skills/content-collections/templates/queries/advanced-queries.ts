// advanced-queries.ts
// Advanced content collection query patterns with complex filtering

import { getCollection, type CollectionEntry } from 'astro:content';

/**
 * Get posts with complex filtering
 */
export async function getFilteredPosts(options: {
  tags?: string[];
  author?: string;
  featured?: boolean;
  dateFrom?: Date;
  dateTo?: Date;
  excludeDrafts?: boolean;
  limit?: number;
}) {
  const {
    tags,
    author,
    featured,
    dateFrom,
    dateTo,
    excludeDrafts = true,
    limit,
  } = options;

  let posts = await getCollection('blog', ({ data }) => {
    // Draft filter
    if (excludeDrafts && data.draft) return false;

    // Author filter
    if (author && data.author !== author) return false;

    // Featured filter
    if (featured !== undefined && data.featured !== featured) return false;

    // Date range filter
    if (dateFrom && data.pubDate < dateFrom) return false;
    if (dateTo && data.pubDate > dateTo) return false;

    // Tags filter (all tags must match)
    if (tags && tags.length > 0) {
      const hasAllTags = tags.every(tag => data.tags?.includes(tag));
      if (!hasAllTags) return false;
    }

    return true;
  });

  // Apply limit if specified
  if (limit) {
    posts = posts.slice(0, limit);
  }

  return posts;
}

/**
 * Search posts by keyword in title and description
 */
export async function searchPosts(keyword: string) {
  const lowerKeyword = keyword.toLowerCase();

  const posts = await getCollection('blog', ({ data }) => {
    if (data.draft) return false;

    const titleMatch = data.title.toLowerCase().includes(lowerKeyword);
    const descMatch = data.description.toLowerCase().includes(lowerKeyword);

    return titleMatch || descMatch;
  });

  return posts;
}

/**
 * Get posts grouped by category/tag
 */
export async function getPostsGroupedByTag() {
  const posts = await getCollection('blog', ({ data }) => data.draft !== true);

  const grouped: Record<string, CollectionEntry<'blog'>[]> = {};

  posts.forEach(post => {
    post.data.tags?.forEach(tag => {
      if (!grouped[tag]) {
        grouped[tag] = [];
      }
      grouped[tag].push(post);
    });
  });

  return grouped;
}

/**
 * Get posts with pagination metadata
 */
export async function getPaginatedPosts(page = 1, postsPerPage = 10) {
  const allPosts = await getCollection('blog', ({ data }) => {
    return data.draft !== true;
  });

  // Sort by date descending
  const sortedPosts = allPosts.sort(
    (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
  );

  const totalPages = Math.ceil(sortedPosts.length / postsPerPage);
  const startIndex = (page - 1) * postsPerPage;
  const endIndex = startIndex + postsPerPage;

  const posts = sortedPosts.slice(startIndex, endIndex);

  return {
    posts,
    pagination: {
      currentPage: page,
      totalPages,
      totalPosts: sortedPosts.length,
      postsPerPage,
      hasNextPage: page < totalPages,
      hasPrevPage: page > 1,
      nextPage: page < totalPages ? page + 1 : null,
      prevPage: page > 1 ? page - 1 : null,
    },
  };
}

/**
 * Get related posts based on shared tags
 */
export async function getRelatedPosts(
  currentSlug: string,
  limit = 5
): Promise<CollectionEntry<'blog'>[]> {
  const currentPost = await getCollection('blog').then(posts =>
    posts.find(p => p.slug === currentSlug)
  );

  if (!currentPost) return [];

  const allPosts = await getCollection('blog', ({ data, slug }) => {
    return data.draft !== true && slug !== currentSlug;
  });

  // Score posts by shared tags
  const scoredPosts = allPosts.map(post => {
    const sharedTags = post.data.tags?.filter(tag =>
      currentPost.data.tags?.includes(tag)
    );
    const score = sharedTags?.length || 0;

    return { post, score };
  });

  // Sort by score and return top results
  return scoredPosts
    .filter(({ score }) => score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(({ post }) => post);
}

/**
 * Get post statistics
 */
export async function getPostStatistics() {
  const posts = await getCollection('blog');

  const stats = {
    total: posts.length,
    published: posts.filter(p => !p.data.draft).length,
    drafts: posts.filter(p => p.data.draft).length,
    featured: posts.filter(p => p.data.featured).length,
    byAuthor: {} as Record<string, number>,
    byTag: {} as Record<string, number>,
    avgTagsPerPost: 0,
  };

  // Count by author
  posts.forEach(post => {
    const author = post.data.author;
    stats.byAuthor[author] = (stats.byAuthor[author] || 0) + 1;
  });

  // Count by tag
  let totalTags = 0;
  posts.forEach(post => {
    post.data.tags?.forEach(tag => {
      stats.byTag[tag] = (stats.byTag[tag] || 0) + 1;
      totalTags++;
    });
  });

  stats.avgTagsPerPost = totalTags / posts.length;

  return stats;
}

/**
 * Get posts by date range with grouping
 */
export async function getPostsByDateRange(
  startDate: Date,
  endDate: Date,
  groupBy: 'day' | 'week' | 'month' = 'month'
) {
  const posts = await getCollection('blog', ({ data }) => {
    return (
      data.draft !== true &&
      data.pubDate >= startDate &&
      data.pubDate <= endDate
    );
  });

  // Group posts by date
  const grouped: Record<string, CollectionEntry<'blog'>[]> = {};

  posts.forEach(post => {
    const date = post.data.pubDate;
    let key: string;

    switch (groupBy) {
      case 'day':
        key = date.toISOString().split('T')[0];
        break;
      case 'week':
        const week = Math.floor(date.getTime() / (7 * 24 * 60 * 60 * 1000));
        key = `week-${week}`;
        break;
      case 'month':
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        break;
    }

    if (!grouped[key]) {
      grouped[key] = [];
    }
    grouped[key].push(post);
  });

  return grouped;
}

/**
 * Get all unique tags with post counts
 */
export async function getAllTagsWithCounts() {
  const posts = await getCollection('blog', ({ data }) => data.draft !== true);

  const tagCounts: Record<string, number> = {};

  posts.forEach(post => {
    post.data.tags?.forEach(tag => {
      tagCounts[tag] = (tagCounts[tag] || 0) + 1;
    });
  });

  // Convert to array and sort by count
  return Object.entries(tagCounts)
    .map(([tag, count]) => ({ tag, count }))
    .sort((a, b) => b.count - a.count);
}

/**
 * Example usage:
 *
 * // Filter posts with multiple criteria
 * const filtered = await getFilteredPosts({
 *   tags: ['astro', 'tutorial'],
 *   featured: true,
 *   dateFrom: new Date('2024-01-01'),
 *   limit: 10
 * });
 *
 * // Search posts
 * const results = await searchPosts('content collections');
 *
 * // Get paginated posts
 * const { posts, pagination } = await getPaginatedPosts(1, 10);
 *
 * // Get related posts
 * const related = await getRelatedPosts('my-post-slug', 5);
 */
