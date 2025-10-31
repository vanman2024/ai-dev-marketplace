# Documentation Site with Content Collections

Complete documentation site with search, sidebar navigation, and version control.

## Content Collections Schema

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const docs = defineCollection({
  type: 'content'
  schema: z.object({
    title: z.string()
    description: z.string()
    category: z.enum(['guide', 'reference', 'tutorial', 'api'])
    order: z.number().default(0)
    version: z.string().default('1.0')
    lastUpdated: z.date()
    tags: z.array(z.string()).default([])
    related: z.array(z.string()).default([])
  })
});

export const collections = { docs };
```

## Documentation Layout

```astro
---
// src/layouts/DocsLayout.astro
import { getCollection } from 'astro:content';

const allDocs = await getCollection('docs');
const categories = ['guide', 'reference', 'tutorial', 'api'];

const sidebar = categories.map(cat => ({
  category: cat
  docs: allDocs
    .filter(d => d.data.category === cat)
    .sort((a, b) => a.data.order - b.data.order)
}));

const { frontmatter, headings } = Astro.props;
---

<div class="docs-layout">
  <aside class="sidebar">
    {sidebar.map(({ category, docs }) => (
      <div>
        <h3>{category}</h3>
        <ul>
          {docs.map(doc => (
            <li>
              <a href={`/docs/${doc.slug}`}>{doc.data.title}</a>
            </li>
          ))}
        </ul>
      </div>
    ))}
  </aside>

  <main>
    <article>
      <h1>{frontmatter.title}</h1>
      <p>{frontmatter.description}</p>
      <slot />
    </article>

    <aside class="toc">
      <h4>On this page</h4>
      <ul>
        {headings.map(({ text, slug }) => (
          <li><a href={`#${slug}`}>{text}</a></li>
        ))}
      </ul>
    </aside>
  </main>
</div>
```

## Search Functionality

```typescript
// src/pages/api/search.json.ts
import { getCollection } from 'astro:content';
import type { APIRoute } from 'astro';

export const GET: APIRoute = async ({ url }) => {
  const query = url.searchParams.get('q')?.toLowerCase();
  if (!query) return new Response(JSON.stringify([]), { status: 200 });

  const docs = await getCollection('docs');
  const results = docs.filter(doc =>
    doc.data.title.toLowerCase().includes(query) ||
    doc.data.description.toLowerCase().includes(query) ||
    doc.data.tags.some(tag => tag.toLowerCase().includes(query))
  );

  return new Response(JSON.stringify(results.map(r => ({
    slug: r.slug
    title: r.data.title
    description: r.data.description
  }))), {
    headers: { 'Content-Type': 'application/json' }
  });
};
```
