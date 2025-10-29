# Blog with Tags Example

Complete example showing content collections with tag filtering and dynamic routes.

## Setup Content Collection

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    pubDate: z.date(),
    tags: z.array(z.string()).default([]),
  }),
});

export const collections = { blog };
```

## Create Blog Posts

```markdown
---
// src/content/blog/astro-intro.md
title: 'Introduction to Astro'
description: 'Learn the basics of Astro framework'
pubDate: 2025-01-15
tags: ['astro', 'tutorial', 'javascript']
---

Content here...
```

## Query Posts by Tag

```astro
---
// src/pages/tags/[tag].astro
import { getCollection } from 'astro:content';

export async function getStaticPaths() {
  const allPosts = await getCollection('blog');
  const allTags = [...new Set(allPosts.flatMap(post => post.data.tags))];

  return allTags.map(tag => ({
    params: { tag },
    props: {
      posts: allPosts.filter(post =>
        post.data.tags.includes(tag)
      )
    }
  }));
}

const { tag } = Astro.params;
const { posts } = Astro.props;
---

<h1>Posts tagged with "{tag}"</h1>
{posts.map(post => (
  <article>
    <h2><a href={`/blog/${post.slug}`}>{post.data.title}</a></h2>
    <p>{post.data.description}</p>
  </article>
))}
```

## Benefits

- ✅ Type-safe tag filtering
- ✅ Automatic tag pages generation
- ✅ SEO-friendly URLs (/tags/astro, /tags/tutorial)
- ✅ Fast static generation
