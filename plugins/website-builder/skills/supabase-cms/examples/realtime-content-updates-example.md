# Real-time Content Updates Example

This example demonstrates how to implement real-time content updates using Supabase Realtime for collaborative editing and live content synchronization.

## Prerequisites

- Supabase project with Realtime enabled
- Posts table created
- Supabase client configured

## Enable Realtime on Your Table

```sql
-- Enable realtime for posts table
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- Or enable for all tables in public schema
ALTER PUBLICATION supabase_realtime ADD TABLE ALL IN SCHEMA public;
```

## TypeScript Implementation

### 1. Basic Content Subscription

```typescript
// src/lib/supabase/realtime/content-subscription.ts
import { supabase } from '../client';
import type { RealtimeChannel } from '@supabase/supabase-js';

export function subscribeToContentChanges(
  callback: (payload: any) => void
): RealtimeChannel {
  const channel = supabase
    .channel('content-changes')
    .on(
      'postgres_changes'
      {
        event: '*'
        schema: 'public'
        table: 'posts'
      }
      (payload) => {
        console.log('Content change detected:', payload);
        callback(payload);
      }
    )
    .subscribe();

  return channel;
}

export async function unsubscribe(channel: RealtimeChannel) {
  await supabase.removeChannel(channel);
}
```

### 2. Real-time Post List Component

```typescript
// src/components/RealtimePostList.tsx
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';

interface Post {
  id: string;
  title: string;
  status: string;
  published_at: string | null;
  updated_at: string;
}

export function RealtimePostList() {
  const [posts, setPosts] = useState<Post[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadPosts();

    // Subscribe to realtime changes
    const channel = supabase
      .channel('posts-changes')
      .on(
        'postgres_changes'
        {
          event: '*'
          schema: 'public'
          table: 'posts'
        }
        handleRealtimeUpdate
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  async function loadPosts() {
    const { data, error } = await supabase
      .from('posts')
      .select('id, title, status, published_at, updated_at')
      .eq('status', 'published')
      .order('published_at', { ascending: false });

    if (error) {
      console.error('Error loading posts:', error);
      return;
    }

    setPosts(data || []);
    setIsLoading(false);
  }

  function handleRealtimeUpdate(payload: any) {
    console.log('Realtime update:', payload);

    switch (payload.eventType) {
      case 'INSERT':
        // Add new post if it's published
        if (payload.new.status === 'published') {
          setPosts((prev) => [payload.new, ...prev]);
        }
        break;

      case 'UPDATE':
        setPosts((prev) =>
          prev.map((post) =>
            post.id === payload.new.id ? payload.new : post
          ).filter((post) => post.status === 'published')
        );
        break;

      case 'DELETE':
        setPosts((prev) =>
          prev.filter((post) => post.id !== payload.old.id)
        );
        break;
    }
  }

  if (isLoading) {
    return <div>Loading posts...</div>;
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Latest Posts (Live)</h2>
      <div className="grid gap-4">
        {posts.map((post) => (
          <article key={post.id} className="border rounded-lg p-4">
            <h3 className="text-xl font-semibold">{post.title}</h3>
            <p className="text-sm text-gray-600">
              Status: {post.status} | Updated: {new Date(post.updated_at).toLocaleString()}
            </p>
          </article>
        ))}
      </div>
    </div>
  );
}
```

### 3. Collaborative Editor with Presence

```typescript
// src/components/CollaborativeEditor.tsx
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';

interface User {
  id: string;
  name: string;
}

export function CollaborativeEditor({ postId }: { postId: string }) {
  const [content, setContent] = useState('');
  const [activeUsers, setActiveUsers] = useState<User[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    loadPost();

    // Subscribe to content changes
    const contentChannel = supabase
      .channel(`post-${postId}`)
      .on(
        'postgres_changes'
        {
          event: 'UPDATE'
          schema: 'public'
          table: 'posts'
          filter: `id=eq.${postId}`
        }
        (payload) => {
          // Only update if change came from another user
          if (payload.new.content !== content) {
            setContent(payload.new.content);
          }
        }
      )
      .subscribe();

    // Presence tracking - who's viewing this post
    const presenceChannel = supabase.channel(`presence-${postId}`, {
      config: {
        presence: {
          key: postId
        }
      }
    });

    presenceChannel
      .on('presence', { event: 'sync' }, () => {
        const state = presenceChannel.presenceState();
        const users = Object.values(state)
          .flat()
          .map((presence: any) => presence.user);
        setActiveUsers(users);
      })
      .on('presence', { event: 'join' }, ({ newPresences }) => {
        console.log('User joined:', newPresences);
      })
      .on('presence', { event: 'leave' }, ({ leftPresences }) => {
        console.log('User left:', leftPresences);
      })
      .subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          // Track current user
          const { data: { user } } = await supabase.auth.getUser();
          if (user) {
            await presenceChannel.track({
              user: {
                id: user.id
                name: user.email
              }
              online_at: new Date().toISOString()
            });
          }
        }
      });

    return () => {
      supabase.removeChannel(contentChannel);
      supabase.removeChannel(presenceChannel);
    };
  }, [postId]);

  async function loadPost() {
    const { data, error } = await supabase
      .from('posts')
      .select('content')
      .eq('id', postId)
      .single();

    if (error) {
      console.error('Error loading post:', error);
      return;
    }

    setContent(data.content);
  }

  async function saveContent() {
    setIsSaving(true);

    const { error } = await supabase
      .from('posts')
      .update({
        content
        updated_at: new Date().toISOString()
      })
      .eq('id', postId);

    if (error) {
      console.error('Error saving:', error);
    }

    setIsSaving(false);
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <div className="flex gap-2">
          <span className="text-sm text-gray-600">Active users:</span>
          {activeUsers.map((user) => (
            <span key={user.id} className="px-2 py-1 bg-blue-100 rounded text-sm">
              {user.name}
            </span>
          ))}
        </div>
        <button
          onClick={saveContent}
          disabled={isSaving}
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          {isSaving ? 'Saving...' : 'Save'}
        </button>
      </div>

      <textarea
        value={content}
        onChange={(e) => setContent(e.target.value)}
        className="w-full h-96 p-4 border rounded font-mono"
        placeholder="Write your content here..."
      />
    </div>
  );
}
```

### 4. Live Notification System

```typescript
// src/components/LiveNotifications.tsx
import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';

interface Notification {
  id: string;
  message: string;
  timestamp: string;
}

export function LiveNotifications() {
  const [notifications, setNotifications] = useState<Notification[]>([]);

  useEffect(() => {
    // Subscribe to new published posts
    const channel = supabase
      .channel('new-published-posts')
      .on(
        'postgres_changes'
        {
          event: 'UPDATE'
          schema: 'public'
          table: 'posts'
          filter: 'status=eq.published'
        }
        (payload) => {
          // Only notify when status changes to published
          if (payload.new.status === 'published' && payload.old.status !== 'published') {
            addNotification(`New post published: ${payload.new.title}`);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  function addNotification(message: string) {
    const notification = {
      id: crypto.randomUUID()
      message
      timestamp: new Date().toISOString()
    };

    setNotifications((prev) => [notification, ...prev.slice(0, 4)]);

    // Auto-remove after 5 seconds
    setTimeout(() => {
      setNotifications((prev) => prev.filter((n) => n.id !== notification.id));
    }, 5000);
  }

  return (
    <div className="fixed top-4 right-4 space-y-2 z-50">
      {notifications.map((notification) => (
        <div
          key={notification.id}
          className="bg-blue-500 text-white px-4 py-3 rounded shadow-lg animate-slide-in"
        >
          <p>{notification.message}</p>
          <p className="text-xs opacity-75">
            {new Date(notification.timestamp).toLocaleTimeString()}
          </p>
        </div>
      ))}
    </div>
  );
}
```

### 5. Astro Integration

```astro
---
// src/pages/dashboard/live-posts.astro
import { RealtimePostList } from '@/components/RealtimePostList';
import { LiveNotifications } from '@/components/LiveNotifications';
---

<html>
  <head>
    <title>Live Posts Dashboard</title>
  </head>
  <body>
    <div class="container mx-auto p-8">
      <RealtimePostList client:load />
      <LiveNotifications client:load />
    </div>
  </body>
</html>
```

## Channel Management Best Practices

```typescript
// src/lib/supabase/realtime/channel-manager.ts
class ChannelManager {
  private channels: Map<string, RealtimeChannel> = new Map();

  subscribe(channelName: string, config: any): RealtimeChannel {
    // Reuse existing channel if already subscribed
    if (this.channels.has(channelName)) {
      return this.channels.get(channelName)!;
    }

    const channel = supabase.channel(channelName);

    // Configure channel
    if (config.postgresChanges) {
      channel.on('postgres_changes', config.postgresChanges.filter, config.postgresChanges.callback);
    }

    if (config.presence) {
      channel.on('presence', { event: 'sync' }, config.presence.sync);
    }

    channel.subscribe();
    this.channels.set(channelName, channel);

    return channel;
  }

  async unsubscribe(channelName: string) {
    const channel = this.channels.get(channelName);
    if (channel) {
      await supabase.removeChannel(channel);
      this.channels.delete(channelName);
    }
  }

  async unsubscribeAll() {
    for (const channel of this.channels.values()) {
      await supabase.removeChannel(channel);
    }
    this.channels.clear();
  }
}

export const channelManager = new ChannelManager();
```

## Setup Steps

1. Enable Realtime for your tables:
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE posts;
   ```

2. Configure Realtime in your Supabase dashboard:
   - Go to Database → Replication
   - Enable Realtime for `posts` table
   - Configure RLS policies to allow subscriptions

3. Test Realtime subscriptions:
   ```typescript
   const channel = supabase
     .channel('test')
     .on('postgres_changes', { event: '*', schema: 'public', table: 'posts' }, console.log)
     .subscribe();
   ```

## Performance Considerations

- **Limit channels**: Don't create too many channels per client (recommended: < 100)
- **Use filters**: Filter at the database level with `filter: 'column=eq.value'`
- **Debounce updates**: Batch rapid changes to avoid flooding
- **Clean up subscriptions**: Always unsubscribe when components unmount
- **Monitor connection**: Handle reconnection logic for network interruptions

## Troubleshooting

### Realtime not working?

1. Check if Realtime is enabled for your table:
   ```sql
   SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
   ```

2. Verify RLS policies allow subscriptions
3. Check browser console for connection errors
4. Ensure you're on a compatible Supabase plan

### Connection drops?

Implement reconnection logic:

```typescript
channel.subscribe((status) => {
  if (status === 'CHANNEL_ERROR') {
    // Retry connection
    setTimeout(() => channel.subscribe(), 5000);
  }
});
```
