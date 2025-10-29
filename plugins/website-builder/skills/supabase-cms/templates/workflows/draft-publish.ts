// Draft/Publish workflow for content management
import { supabase } from '../client/supabase-client';

// Create a draft post
export async function createDraft(postData: {
  title: string;
  slug: string;
  content: string;
  author_id: string;
}) {
  const { data, error } = await supabase
    .from('posts')
    .insert({
      ...postData,
      status: 'draft'
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Publish a draft
export async function publishPost(postId: string) {
  const { data, error } = await supabase
    .from('posts')
    .update({
      status: 'published',
      published_at: new Date().toISOString()
    })
    .eq('id', postId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Unpublish a post (back to draft)
export async function unpublishPost(postId: string) {
  const { data, error } = await supabase
    .from('posts')
    .update({
      status: 'draft',
      published_at: null
    })
    .eq('id', postId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Schedule post for future publishing
export async function schedulePost(postId: string, publishDate: Date) {
  const { data, error } = await supabase
    .from('posts')
    .update({
      status: 'scheduled',
      published_at: publishDate.toISOString()
    })
    .eq('id', postId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

// Archive a post
export async function archivePost(postId: string) {
  const { data, error } = await supabase
    .from('posts')
    .update({ status: 'archived' })
    .eq('id', postId)
    .select()
    .single();

  if (error) throw error;
  return data;
}
