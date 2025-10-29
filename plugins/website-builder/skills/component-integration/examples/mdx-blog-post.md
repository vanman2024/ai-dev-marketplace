# MDX Blog Post with Custom Components

This example demonstrates how to create rich, interactive blog posts using MDX (Markdown + JSX) with custom React components in Astro.

## Prerequisites

- Astro project with MDX integration (`npx astro add mdx`)
- React integration configured
- Tailwind CSS for styling

## Step 1: Configure MDX in Astro

```typescript
// astro.config.mjs
import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import react from '@astrojs/react';

export default defineConfig({
  integrations: [
    mdx({
      syntaxHighlight: 'shiki',
      shikiConfig: { theme: 'github-dark' },
      remarkPlugins: [],
      rehypePlugins: [],
    }),
    react()
  ]
});
```

## Step 2: Create Custom MDX Components

### Callout Component

```typescript
// src/components/mdx/Callout.tsx
import type { ReactNode } from 'react';

interface CalloutProps {
  type?: 'info' | 'warning' | 'error' | 'success';
  title?: string;
  children: ReactNode;
}

export function Callout({ type = 'info', title, children }: CalloutProps) {
  const styles = {
    info: 'bg-blue-50 border-blue-500 text-blue-900',
    warning: 'bg-yellow-50 border-yellow-500 text-yellow-900',
    error: 'bg-red-50 border-red-500 text-red-900',
    success: 'bg-green-50 border-green-500 text-green-900'
  };

  const icons = {
    info: '💡',
    warning: '⚠️',
    error: '❌',
    success: '✅'
  };

  return (
    <div className={`border-l-4 p-4 my-4 rounded ${styles[type]}`}>
      {title && (
        <div className="flex items-center gap-2 font-bold mb-2">
          <span>{icons[type]}</span>
          <span>{title}</span>
        </div>
      )}
      <div className="prose prose-sm">{children}</div>
    </div>
  );
}
```

### Code Sandbox Component

```typescript
// src/components/mdx/CodeSandbox.tsx
interface CodeSandboxProps {
  id: string;
  title?: string;
  height?: number;
}

export function CodeSandbox({ id, title, height = 500 }: CodeSandboxProps) {
  return (
    <div className="my-6">
      {title && <h3 className="text-lg font-bold mb-2">{title}</h3>}
      <iframe
        src={`https://codesandbox.io/embed/${id}?fontsize=14&hidenavigation=1&theme=dark`}
        style={{
          width: '100%',
          height: `${height}px`,
          border: 0,
          borderRadius: '4px',
          overflow: 'hidden'
        }}
        title={title || 'CodeSandbox'}
        allow="accelerometer; ambient-light-sensor; camera; encrypted-media; geolocation; gyroscope; hid; microphone; midi; payment; usb; vr; xr-spatial-tracking"
        sandbox="allow-forms allow-modals allow-popups allow-presentation allow-same-origin allow-scripts"
      />
    </div>
  );
}
```

### Interactive Demo Component

```typescript
// src/components/mdx/InteractiveDemo.tsx
import { useState } from 'react';
import type { ReactNode } from 'react';

interface InteractiveDemoProps {
  title: string;
  children: ReactNode;
  code?: string;
}

export function InteractiveDemo({ title, children, code }: InteractiveDemoProps) {
  const [showCode, setShowCode] = useState(false);

  return (
    <div className="border rounded-lg my-6 overflow-hidden">
      <div className="bg-gray-100 px-4 py-2 flex justify-between items-center">
        <h4 className="font-bold">{title}</h4>
        {code && (
          <button
            onClick={() => setShowCode(!showCode)}
            className="text-sm text-blue-600 hover:text-blue-800"
          >
            {showCode ? 'Hide' : 'Show'} Code
          </button>
        )}
      </div>
      <div className="p-6 bg-white">
        {children}
      </div>
      {code && showCode && (
        <div className="bg-gray-900 p-4">
          <pre className="text-sm text-gray-100 overflow-x-auto">
            <code>{code}</code>
          </pre>
        </div>
      )}
    </div>
  );
}
```

### Table of Contents Component

```typescript
// src/components/mdx/TableOfContents.tsx
import { useEffect, useState } from 'react';

interface Heading {
  id: string;
  text: string;
  level: number;
}

export function TableOfContents() {
  const [headings, setHeadings] = useState<Heading[]>([]);
  const [activeId, setActiveId] = useState('');

  useEffect(() => {
    // Extract headings from the document
    const elements = document.querySelectorAll('h2, h3, h4');
    const headingData: Heading[] = Array.from(elements).map((element) => ({
      id: element.id,
      text: element.textContent || '',
      level: parseInt(element.tagName.charAt(1))
    }));
    setHeadings(headingData);

    // Track active heading based on scroll
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveId(entry.target.id);
          }
        });
      },
      { rootMargin: '-100px 0px -80% 0px' }
    );

    elements.forEach((element) => observer.observe(element));

    return () => observer.disconnect();
  }, []);

  return (
    <nav className="sticky top-4 border rounded-lg p-4 bg-white">
      <h3 className="font-bold mb-2">Table of Contents</h3>
      <ul className="space-y-1">
        {headings.map((heading) => (
          <li
            key={heading.id}
            style={{ marginLeft: `${(heading.level - 2) * 16}px` }}
          >
            <a
              href={`#${heading.id}`}
              className={`text-sm hover:text-blue-600 ${
                activeId === heading.id ? 'text-blue-600 font-semibold' : 'text-gray-600'
              }`}
            >
              {heading.text}
            </a>
          </li>
        ))}
      </ul>
    </nav>
  );
}
```

## Step 3: Create MDX Layout

```astro
---
// src/layouts/BlogPost.astro
import { TableOfContents } from '@/components/mdx/TableOfContents';

interface Props {
  frontmatter: {
    title: string;
    description: string;
    author: string;
    date: string;
    tags?: string[];
  };
}

const { frontmatter } = Astro.props;
---

<html>
  <head>
    <title>{frontmatter.title}</title>
    <meta name="description" content={frontmatter.description} />
  </head>
  <body>
    <div class="max-w-7xl mx-auto px-4 py-8">
      <div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <!-- Main content -->
        <article class="lg:col-span-3 prose prose-lg max-w-none">
          <header class="mb-8">
            <h1 class="text-4xl font-bold mb-2">{frontmatter.title}</h1>
            <p class="text-gray-600">{frontmatter.description}</p>
            <div class="flex items-center gap-4 mt-4 text-sm text-gray-500">
              <span>By {frontmatter.author}</span>
              <span>•</span>
              <time>{new Date(frontmatter.date).toLocaleDateString()}</time>
            </div>
            {frontmatter.tags && (
              <div class="flex gap-2 mt-4">
                {frontmatter.tags.map((tag) => (
                  <span class="px-3 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </header>

          <slot />
        </article>

        <!-- Table of contents -->
        <aside class="lg:col-span-1">
          <TableOfContents client:load />
        </aside>
      </div>
    </div>
  </body>
</html>
```

## Step 4: Create MDX Blog Post

```mdx
---
# src/content/blog/interactive-components-guide.mdx
layout: ../../layouts/BlogPost.astro
title: "Building Interactive Components with React and Astro"
description: "Learn how to create rich, interactive content using MDX and React components"
author: "John Doe"
date: "2024-01-15"
tags: ["React", "Astro", "MDX", "Tutorial"]
---

import { Callout } from '../../components/mdx/Callout';
import { CodeSandbox } from '../../components/mdx/CodeSandbox';
import { InteractiveDemo } from '../../components/mdx/InteractiveDemo';
import { Counter } from '../../components/Counter';

## Introduction

This guide will teach you how to build interactive components using React and Astro's islands architecture.

<Callout type="info" title="Prerequisites">
  Make sure you have Node.js 18+ installed and a basic understanding of React and Astro.
</Callout>

## Getting Started

First, let's understand why MDX is powerful for technical content:

1. **Markdown simplicity** - Write content in familiar Markdown syntax
2. **JSX power** - Embed React components anywhere
3. **Type safety** - Full TypeScript support for components
4. **Performance** - Islands architecture for optimal loading

<Callout type="warning" title="Performance Tip">
  Use `client:visible` for components below the fold to reduce initial JavaScript bundle size.
</Callout>

## Interactive Example

Here's a live counter component you can interact with right in this blog post:

<InteractiveDemo
  title="Counter Component"
  code={`function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
}`}
>
  <Counter client:visible initialCount={0} />
</InteractiveDemo>

Pretty cool, right? The component is fully interactive within your blog post content.

## Code Sandbox Integration

You can embed live coding environments directly in your posts:

<CodeSandbox
  id="react-new"
  title="Try React Online"
  height={400}
/>

## Best Practices

<Callout type="success" title="Pro Tip">
  Always use semantic HTML and proper heading hierarchy for better SEO and accessibility.
</Callout>

### Performance Optimization

1. Use `client:visible` for below-the-fold components
2. Lazy load heavy interactive features
3. Minimize JavaScript bundle size
4. Use static rendering where possible

### Accessibility

- Add `alt` text to all images
- Use semantic HTML elements
- Ensure keyboard navigation works
- Test with screen readers

## Conclusion

MDX gives you the best of both worlds: the simplicity of Markdown and the power of React components.

<Callout type="info">
  Check out the [Astro documentation](https://docs.astro.build) for more MDX examples.
</Callout>
```

## Step 5: Configure Content Collections for MDX

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content',
  schema: z.object({
    title: z.string(),
    description: z.string(),
    author: z.string(),
    date: z.string().transform((str) => new Date(str)),
    tags: z.array(z.string()).optional(),
    draft: z.boolean().default(false),
  }),
});

export const collections = { blog };
```

## Step 6: List Blog Posts

```astro
---
// src/pages/blog/index.astro
import { getCollection } from 'astro:content';

const posts = await getCollection('blog', ({ data }) => {
  return !data.draft;
});

// Sort by date, newest first
const sortedPosts = posts.sort((a, b) =>
  b.data.date.getTime() - a.data.date.getTime()
);
---

<html>
  <body>
    <div class="max-w-4xl mx-auto px-4 py-8">
      <h1 class="text-4xl font-bold mb-8">Blog Posts</h1>
      <div class="space-y-6">
        {sortedPosts.map((post) => (
          <article class="border rounded-lg p-6 hover:shadow-lg transition">
            <h2 class="text-2xl font-bold mb-2">
              <a href={`/blog/${post.slug}`} class="hover:text-blue-600">
                {post.data.title}
              </a>
            </h2>
            <p class="text-gray-600 mb-4">{post.data.description}</p>
            <div class="flex items-center gap-4 text-sm text-gray-500">
              <span>By {post.data.author}</span>
              <span>•</span>
              <time>{post.data.date.toLocaleDateString()}</time>
            </div>
            {post.data.tags && (
              <div class="flex gap-2 mt-4">
                {post.data.tags.map((tag) => (
                  <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded">
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </article>
        ))}
      </div>
    </div>
  </body>
</html>
```

## Step 7: Dynamic Blog Post Pages

```astro
---
// src/pages/blog/[...slug].astro
import { getCollection } from 'astro:content';

export async function getStaticPaths() {
  const posts = await getCollection('blog');
  return posts.map((post) => ({
    params: { slug: post.slug },
    props: { post },
  }));
}

const { post } = Astro.props;
const { Content } = await post.render();
---

<Content />
```

## Custom Components You Can Create

### YouTube Embed

```typescript
export function YouTube({ id }: { id: string }) {
  return (
    <div className="aspect-video my-6">
      <iframe
        src={`https://www.youtube.com/embed/${id}`}
        className="w-full h-full rounded-lg"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
      />
    </div>
  );
}
```

### Tweet Embed

```typescript
export function Tweet({ id }: { id: string }) {
  return (
    <blockquote className="twitter-tweet">
      <a href={`https://twitter.com/x/status/${id}`}>View tweet</a>
    </blockquote>
  );
}
```

### Mermaid Diagram

```typescript
import { useEffect, useRef } from 'react';
import mermaid from 'mermaid';

export function Mermaid({ chart }: { chart: string }) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (ref.current) {
      mermaid.render('mermaid-diagram', chart).then(({ svg }) => {
        ref.current!.innerHTML = svg;
      });
    }
  }, [chart]);

  return <div ref={ref} className="my-6" />;
}
```

## Best Practices

1. **Keep MDX components reusable** - Design components that work in multiple contexts
2. **Use client directives wisely** - Only hydrate what needs interactivity
3. **Organize components** - Keep MDX components in a dedicated directory
4. **Type everything** - Use TypeScript interfaces for all component props
5. **Test components** - Ensure components work in both SSR and client contexts
6. **Optimize images** - Use Astro's Image component for automatic optimization
7. **Add syntax highlighting** - Configure Shiki or Prism for code blocks
8. **Mobile-first** - Test all interactive components on mobile devices

## Summary

MDX enables you to create rich, interactive blog posts that combine the simplicity of Markdown with the power of React components. Use it to build engaging technical content, tutorials, and documentation.
