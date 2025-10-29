// Paginated query patterns for large datasets
import { supabase } from './supabase-client';

const POSTS_PER_PAGE = 10;

// Get paginated posts
export async function getPaginatedPosts(page: number = 1) {
  const from = (page - 1) * POSTS_PER_PAGE;
  const to = from + POSTS_PER_PAGE - 1;

  const { data, error, count } = await supabase
    .from('posts')
    .select('*', { count: 'exact' })
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .range(from, to);

  if (error) throw error;

  return {
    posts: data,
    totalCount: count || 0,
    currentPage: page,
    totalPages: Math.ceil((count || 0) / POSTS_PER_PAGE),
    hasMore: to < (count || 0)
  };
}

// Get paginated posts with cursor-based pagination
export async function getCursorPaginatedPosts(cursor?: string, limit: number = 10) {
  let query = supabase
    .from('posts')
    .select('*')
    .eq('status', 'published')
    .order('published_at', { ascending: false })
    .limit(limit);

  if (cursor) {
    query = query.lt('published_at', cursor);
  }

  const { data, error } = await query;

  if (error) throw error;

  return {
    posts: data,
    nextCursor: data.length > 0 ? data[data.length - 1].published_at : null,
    hasMore: data.length === limit
  };
}
