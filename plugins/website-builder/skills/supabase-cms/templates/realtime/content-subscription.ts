// Real-time content updates with Supabase Realtime
import { supabase } from '../client/supabase-client';
import type { RealtimeChannel } from '@supabase/supabase-js';

// Subscribe to content changes
export function subscribeToContentChanges(
  callback: (payload: any) => void
): RealtimeChannel {
  const channel = supabase
    .channel('content-changes')
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'posts'
      },
      (payload) => {
        console.log('Content change detected:', payload);
        callback(payload);
      }
    )
    .subscribe();

  return channel;
}

// Subscribe to specific post changes
export function subscribeToPost(
  postId: string,
  callback: (payload: any) => void
): RealtimeChannel {
  const channel = supabase
    .channel(`post-${postId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'posts',
        filter: `id=eq.${postId}`
      },
      callback
    )
    .subscribe();

  return channel;
}

// Unsubscribe from channel
export async function unsubscribe(channel: RealtimeChannel) {
  await supabase.removeChannel(channel);
}

// Subscribe to new published posts only
export function subscribeToNewPublishedPosts(
  callback: (post: any) => void
): RealtimeChannel {
  const channel = supabase
    .channel('new-published-posts')
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'posts',
        filter: 'status=eq.published'
      },
      (payload) => {
        if (payload.new.status === 'published' && payload.old.status !== 'published') {
          callback(payload.new);
        }
      }
    )
    .subscribe();

  return channel;
}
