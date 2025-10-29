# Portfolio with Projects Collection

Portfolio site showcasing projects with case studies and filtering.

## Projects Schema

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const projects = defineCollection({
  type: 'content',
  schema: ({ image }) => z.object({
    title: z.string(),
    description: z.string(),
    category: z.enum(['web', 'mobile', 'design', 'other']),
    tags: z.array(z.string()),
    featured: z.boolean().default(false),
    thumbnail: image(),
    gallery: z.array(image()).default([]),
    link: z.string().url().optional(),
    github: z.string().url().optional(),
    date: z.date(),
    client: z.string().optional(),
    role: z.string()
  })
});

export const collections = { projects };
```

## Projects Grid

```astro
---
// src/pages/projects/index.astro
import { getCollection } from 'astro:content';
import { Image } from 'astro:assets';

const projects = await getCollection('projects');
const categories = ['web', 'mobile', 'design', 'other'];
---

<div class="container">
  <h1>Projects</h1>

  <div class="filters">
    {categories.map(cat => (
      <button data-category={cat}>{cat}</button>
    ))}
  </div>

  <div class="projects-grid">
    {projects.map(project => (
      <article data-category={project.data.category}>
        <a href={`/projects/${project.slug}`}>
          <Image
            src={project.data.thumbnail}
            alt={project.data.title}
            width={600}
            height={400}
          />
          <h2>{project.data.title}</h2>
          <p>{project.data.description}</p>
          <div class="tags">
            {project.data.tags.map(tag => <span>{tag}</span>)}
          </div>
        </a>
      </article>
    ))}
  </div>
</div>

<script>
  document.querySelectorAll('[data-category]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const category = e.target.dataset.category;
      document.querySelectorAll('.projects-grid article').forEach(article => {
        article.style.display =
          article.dataset.category === category ? 'block' : 'none';
      });
    });
  });
</script>
```
