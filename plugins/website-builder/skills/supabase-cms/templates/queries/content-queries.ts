// Content query patterns for Supabase CMS
import { supabase } from './supabase-client';

// Get all published posts
export async function getPublishedPosts() {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('status', 'published')
    .order('published_at', { ascending: false });

  if (error) throw error;
  return data;
}

// Get single post by slug
export async function getPostBySlug(slug: string) {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('slug', slug)
    .eq('status', 'published')
    .single();

  if (error) throw error;
  return data;
}

// Get posts by category
export async function getPostsByCategory(category: string) {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .eq('category', category)
    .eq('status', 'published')
    .order('published_at', { ascending: false });

  if (error) throw error;
  return data;
}

// Get posts by tag
export async function getPostsByTag(tag: string) {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .contains('tags', [tag])
    .eq('status', 'published')
    .order('published_at', { ascending: false });

  if (error) throw error;
  return data;
}

// Search posts
export async function searchPosts(query: string) {
  const { data, error } = await supabase
    .from('posts')
    .select('*')
    .or(`title.ilike.%${query}%,content.ilike.%${query}%`)
    .eq('status', 'published')
    .order('published_at', { ascending: false });

  if (error) throw error;
  return data;
}
