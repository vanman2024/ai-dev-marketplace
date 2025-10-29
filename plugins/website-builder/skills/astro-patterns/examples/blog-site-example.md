# Blog Site Example

Complete example of an Astro blog with content collections, dynamic routes, and layouts.

## Project Structure

```
src/
├── content/
│   ├── config.ts
│   └── blog/
│       ├── post-1.md
│       └── post-2.md
├── layouts/
│   ├── BaseLayout.astro
│   └── BlogLayout.astro
├── pages/
│   ├── index.astro
│   ├── blog/
│   │   ├── index.astro
│   │   └── [slug].astro
│   └── about.astro
└── components/
    └── BlogCard.astro
```

## Content Collection Config

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date(),
    author: z.string(),
    tags: z.array(z.string()).optional(),
    image: z.string().optional(),
  }),
});

export const collections = { blog };
```

## Blog Post Example

```markdown
---
title: 'My First Blog Post'
description: 'Learn how to build with Astro'
pubDate: 2025-01-15
author: 'Jane Doe'
tags: ['astro', 'web development']
---

# Welcome to My Blog

This is my first post using Astro and content collections!

## Features

- Fast performance
- SEO optimized
- Easy to write
```

## Blog List Page

```astro
---
// src/pages/blog/index.astro
import { getCollection } from 'astro:content';
import BaseLayout from '../../layouts/BaseLayout.astro';
import BlogCard from '../../components/BlogCard.astro';

const posts = (await getCollection('blog')).sort(
  (a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);
---

<BaseLayout title="Blog">
  <h1>Blog Posts</h1>
  <div class="post-grid">
    {posts.map(post => (
      <BlogCard
        href={`/blog/${post.slug}`}
        title={post.data.title}
        description={post.data.description}
        pubDate={post.data.pubDate}
      />
    ))}
  </div>
</BaseLayout>
```

## Results

- ✅ Type-safe content with Zod schemas
- ✅ Automatic routing for blog posts
- ✅ Fast static generation
- ✅ SEO-friendly URLs
