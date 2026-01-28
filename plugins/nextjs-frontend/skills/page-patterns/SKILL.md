---
name: page-patterns
description: Load Next.js App Router page patterns. Use when creating pages, routes, layouts, or discussing page structure. Auto-invokes when user mentions page, route, layout, app router, or navigation.
---

# Next.js App Router Page Patterns

**Purpose:** Ensure consistent page structure following App Router conventions.

## Discover Existing Pages

!find app -name "page.tsx" -type f 2>/dev/null | head -10 || echo "No existing pages found"

## Current Layout Structure

!cat app/layout.tsx 2>/dev/null | head -50 || echo "No root layout found"

## Page File Conventions

| File            | Purpose                        |
| --------------- | ------------------------------ |
| `page.tsx`      | Route UI                       |
| `layout.tsx`    | Shared layout (wraps children) |
| `loading.tsx`   | Loading UI (Suspense fallback) |
| `error.tsx`     | Error boundary                 |
| `not-found.tsx` | 404 page                       |

## Standard Page Template

```tsx
// app/[feature]/page.tsx
import { Metadata } from 'next';

// 1. Metadata export for SEO
export const metadata: Metadata = {
  title: 'Page Title | Site Name',
  description: 'Page description for SEO',
};

// 2. Page component (async for data fetching)
export default async function FeaturePage() {
  // Server-side data fetching
  const data = await fetchData();

  return (
    <div className="container py-8 space-y-6">
      <header className="space-y-2">
        <h1 className="text-2xl font-semibold">Page Title</h1>
        <p className="text-muted-foreground">Page description</p>
      </header>

      <main>{/* Page content */}</main>
    </div>
  );
}
```

## Dynamic Routes

```tsx
// app/posts/[slug]/page.tsx
interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);
  return { title: post.title };
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await getPost(slug);

  return <article>{/* ... */}</article>;
}

// Generate static params for SSG
export async function generateStaticParams() {
  const posts = await getPosts();
  return posts.map((post) => ({ slug: post.slug }));
}
```

## Layout Pattern

```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-screen">
      <aside className="w-64 border-r p-4">
        <Sidebar />
      </aside>
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
```

## Route Groups (Organizing without URL)

```
app/
├── (marketing)/        # Group - doesn't affect URL
│   ├── layout.tsx      # Marketing layout
│   ├── page.tsx        # / (home)
│   └── about/page.tsx  # /about
├── (dashboard)/        # Group
│   ├── layout.tsx      # Dashboard layout (with sidebar)
│   └── settings/page.tsx  # /settings
```
