# Dynamic Routing and API Endpoints Example

Complete guide to dynamic routing, API endpoints, and content-driven pages in Astro.

## Dynamic Route Pages

```astro
---
// src/pages/blog/[slug].astro
import { getCollection } from 'astro:content';
import BlogLayout from '@/layouts/BlogLayout.astro';

export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map(post => ({
    params: { slug: post.slug }
    props: { post }
  }));
}

const { post } = Astro.props;
const { Content } = await post.render();
---

<BlogLayout frontmatter={post.data}>
  <Content />
</BlogLayout>
```

## Catch-All Routes

```astro
---
// src/pages/docs/[...path].astro
import { getCollection } from 'astro:content';

export async function getStaticPaths() {
  const docs = await getCollection('docs');
  return docs.map(doc => ({
    params: { path: doc.slug }
    props: { doc }
  }));
}

const { doc } = Astro.props;
const { Content, headings } = await doc.render();
---

<div class="docs-container">
  <aside>{/* TOC from headings */}</aside>
  <Content />
</div>
```

## API Endpoints

```typescript
// src/pages/api/posts.json.ts
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async () => {
  const posts = await getCollection('blog', ({ data }) => !data.draft);

  return new Response(JSON.stringify({
    posts: posts.map(p => ({
      slug: p.slug
      title: p.data.title
      date: p.data.date
    }))
  }), {
    status: 200
    headers: { 'Content-Type': 'application/json' }
  });
};

export const POST: APIRoute = async ({ request }) => {
  const data = await request.json();
  // Handle POST request
  return new Response(JSON.stringify({ success: true }), {
    status: 201
    headers: { 'Content-Type': 'application/json' }
  });
};
```

## Pagination

```astro
---
// src/pages/blog/[...page].astro
import type { GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';

export const getStaticPaths = (async ({ paginate }) => {
  const posts = await getCollection('blog');
  return paginate(posts, { pageSize: 10 });
}) satisfies GetStaticPaths;

const { page } = Astro.props;
---

<div class="blog-grid">
  {page.data.map(post => <PostCard post={post} />)}
</div>

<nav>
  {page.url.prev && <a href={page.url.prev}>← Previous</a>}
  <span>Page {page.currentPage} of {page.lastPage}</span>
  {page.url.next && <a href={page.url.next}>Next →</a>}
</nav>
```

## Middleware

```typescript
// src/middleware.ts
import { defineMiddleware } from 'astro:middleware';

export const onRequest = defineMiddleware(async (context, next) => {
  // Add auth check
  const token = context.cookies.get('auth-token');
  context.locals.isAuth = !!token;

  // Add timing
  const start = Date.now();
  const response = await next();
  console.log(`${context.url.pathname} took ${Date.now() - start}ms`);

  return response;
});
```

## Redirects

```typescript
// astro.config.mjs
export default defineConfig({
  redirects: {
    '/old-blog': '/blog'
    '/posts/[slug]': '/blog/[slug]'
    '/about': {
      status: 301
      destination: '/company/about'
    }
  }
});
```

## 404 Page

```astro
---
// src/pages/404.astro
import BaseLayout from '@/layouts/BaseLayout.astro';
---

<BaseLayout title="Page Not Found">
  <div class="error-page">
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
    <a href="/">Go Home</a>
  </div>
</BaseLayout>
```
