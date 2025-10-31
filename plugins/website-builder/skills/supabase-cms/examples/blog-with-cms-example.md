# Blog with Supabase CMS Example

Complete example showing Astro blog integrated with Supabase CMS backend.

## Setup

### 1. Create Database Schema

```sql
-- Run in Supabase SQL Editor
CREATE TABLE posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  title TEXT NOT NULL
  slug TEXT NOT NULL UNIQUE
  content TEXT NOT NULL
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published'))
  published_at TIMESTAMPTZ
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view published" ON posts
FOR SELECT TO public USING (status = 'published');
```

### 2. Install Dependencies

```bash
npm install @supabase/supabase-js
```

### 3. Configure Environment

```bash
# .env
PUBLIC_SUPABASE_URL=your-project-url
PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### 4. Create Supabase Client

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.PUBLIC_SUPABASE_URL
  import.meta.env.PUBLIC_SUPABASE_ANON_KEY
);
```

### 5. Query Posts in Astro

```astro
---
// src/pages/blog/[slug].astro
import { supabase } from '../../lib/supabase';

export async function getStaticPaths() {
  const { data: posts } = await supabase
    .from('posts')
    .select('slug')
    .eq('status', 'published');

  return posts.map(post => ({
    params: { slug: post.slug }
  }));
}

const { slug } = Astro.params;

const { data: post } = await supabase
  .from('posts')
  .select('*')
  .eq('slug', slug)
  .eq('status', 'published')
  .single();
---

<article>
  <h1>{post.title}</h1>
  <div set:html={post.content} />
</article>
```

## Benefits

- ✅ Real-time content updates
- ✅ Draft/publish workflow
- ✅ Multi-author support
- ✅ Database-backed content
- ✅ RLS security
