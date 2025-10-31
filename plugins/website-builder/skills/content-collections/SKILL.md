---
name: content-collections
description: Astro content collections setup, type-safe schemas, query patterns, and frontmatter validation. Use when building Astro sites, setting up content collections, creating collection schemas, querying content, validating frontmatter, or when user mentions Astro collections, content management, MDX content, type-safe content, or collection queries.
allowed-tools: - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# Content Collections Management for Astro

Complete content collections setup and management for Astro projects, including type-safe schemas, query patterns, frontmatter validation, and content organization.

## Overview

This skill provides comprehensive support for Astro content collections:
- Schema definition with Zod validation
- Type-safe query patterns
- Frontmatter validation and testing
- Collection setup and configuration
- Content organization best practices

## Instructions

### 1. Initial Setup

Run the setup script to initialize content collections in an Astro project:

```bash
bash scripts/setup-content-collections.sh [project-path]
```

This script:
- Creates `src/content/config.ts` if not exists
- Sets up collection directories
- Adds TypeScript types generation
- Configures content collection imports

### 2. Define Collection Schemas

Use schema templates to define type-safe collection schemas:

**TypeScript Schema (Recommended):**
```bash
# Read template for reference
Read: templates/schemas/blog-collection-schema.ts
Read: templates/schemas/docs-collection-schema.ts
```

**Python Schema (for build scripts):**
```bash
# For Python-based content generation
Read: templates/python/collection-schema.py
```

### 3. Generate TypeScript Types

Generate TypeScript types from your collection schemas:

```bash
bash scripts/generate-types.sh [project-path]
```

This creates:
- `src/content/config.ts` exports
- Type definitions in `.astro/types.d.ts`
- Auto-completion for collection queries

### 4. Query Content Collections

Use query builder patterns for type-safe content retrieval:

**TypeScript Queries:**
```bash
Read: templates/queries/basic-queries.ts
Read: templates/queries/advanced-queries.ts
Read: templates/queries/filtered-queries.ts
```

**Python Queries (for build scripts):**
```bash
Read: templates/python/query-patterns.py
```

### 5. Validate Frontmatter

Validate content frontmatter against schemas:

```bash
bash scripts/validate-frontmatter.sh [collection-name] [content-path]
```

This script:
- Checks frontmatter against schema
- Reports validation errors
- Suggests fixes for common issues

### 6. Build Query Patterns

Generate optimized query patterns:

```bash
bash scripts/query-builder.sh [collection-name] [query-type]
```

Query types:
- `all` - Get all entries
- `filtered` - Filter by frontmatter fields
- `sorted` - Sort by date/title/custom field
- `paginated` - Paginate results
- `related` - Find related content

### 7. Test Collections

Run comprehensive collection tests:

```bash
bash scripts/test-collections.sh [project-path]
```

Tests include:
- Schema validation
- Type checking
- Query performance
- Frontmatter completeness

## Scripts Reference

All scripts located in `scripts/`:

1. **setup-content-collections.sh** - Initialize content collections structure
2. **validate-frontmatter.sh** - Validate content against schemas
3. **generate-types.sh** - Generate TypeScript types from schemas
4. **query-builder.sh** - Build optimized query patterns
5. **test-collections.sh** - Run comprehensive collection tests

## Templates Reference

### TypeScript Templates (`templates/typescript/`)
1. **blog-collection.ts** - Blog post collection schema
2. **docs-collection.ts** - Documentation collection schema
3. **basic-queries.ts** - Common query patterns
4. **advanced-queries.ts** - Complex filtering and sorting
5. **paginated-queries.ts** - Pagination patterns
6. **related-content.ts** - Related content finding

### Python Templates (`templates/python/`)
1. **collection-schema.py** - Python schema definitions
2. **query-patterns.py** - Python query builders
3. **frontmatter-validator.py** - Validation utilities

### Schema Templates (`templates/schemas/`)
1. **blog-collection-schema.ts** - Blog post schema with Zod
2. **docs-collection-schema.ts** - Documentation schema
3. **product-collection-schema.ts** - E-commerce product schema
4. **author-collection-schema.ts** - Author profile schema

### Query Templates (`templates/queries/`)
1. **basic-queries.ts** - getAllEntries, getEntryBySlug
2. **advanced-queries.ts** - Complex filtering
3. **filtered-queries.ts** - Category, tag, date filtering
4. **sorted-queries.ts** - Sorting patterns
5. **paginated-queries.ts** - Pagination with prev/next
6. **related-queries.ts** - Related content algorithms

### Validation Templates (`templates/validation/`)
1. **schema-validator.ts** - Zod schema validation
2. **frontmatter-checker.ts** - Frontmatter completeness
3. **type-checker.ts** - TypeScript type validation

## Examples

See comprehensive examples in `examples/`:

1. **basic-usage.md** - Getting started with content collections
2. **advanced-usage.md** - Complex schemas and queries
3. **common-patterns.md** - Typical content collection patterns
4. **error-handling.md** - Common errors and solutions
5. **integration.md** - Integration with MDX, images, and components

## Common Patterns

### Blog Collection Schema
```typescript
import { defineCollection, z } from 'astro:content';

const blogCollection = defineCollection({
  schema: z.object({
    title: z.string()
    description: z.string()
    pubDate: z.date()
    updatedDate: z.date().optional()
    heroImage: z.string().optional()
    tags: z.array(z.string()).default([])
    author: z.string()
    draft: z.boolean().default(false)
  })
});

export const collections = { blog: blogCollection };
```

### Type-Safe Queries
```typescript
import { getCollection, getEntry } from 'astro:content';

// Get all published blog posts
const posts = await getCollection('blog', ({ data }) => {
  return data.draft !== true;
});

// Get single post by slug
const post = await getEntry('blog', 'my-post-slug');

// Sort by date descending
const sortedPosts = posts.sort((a, b) =>
  b.data.pubDate.valueOf() - a.data.pubDate.valueOf()
);
```

### Frontmatter Validation
```typescript
import { z } from 'zod';

const blogSchema = z.object({
  title: z.string().min(1, "Title required")
  description: z.string().max(160, "Description too long")
  pubDate: z.date()
});

// Validate frontmatter
const result = blogSchema.safeParse(frontmatter);
if (!result.success) {
  console.error(result.error.format());
}
```

## Requirements

- Astro 3.0+ or 4.0+ (content collections support)
- Node.js 18+
- TypeScript 5.0+ (for type generation)
- Zod 3.0+ (for schema validation)
- Python 3.8+ (optional, for Python templates)

## Best Practices

1. **Schema Design**:
   - Use specific types (date, enum) over strings
   - Add descriptions for better auto-completion
   - Set sensible defaults for optional fields
   - Use unions for variant content types

2. **Query Optimization**:
   - Filter in getCollection() not after
   - Use getEntry() for single items
   - Cache results when possible
   - Minimize data fetched per query

3. **Frontmatter Validation**:
   - Validate during build time
   - Provide clear error messages
   - Test with invalid data
   - Document required fields

4. **Content Organization**:
   - Group by collection type
   - Use consistent slug patterns
   - Separate drafts with boolean flag
   - Version control all content

## Troubleshooting

Common issues and solutions documented in `examples/error-handling.md`:
- Schema validation errors
- Type generation failures
- Query performance issues
- Frontmatter parsing errors
- Content not appearing

## Related Skills

- `mdx-integration` - MDX component usage in content
- `image-optimization` - Image handling in content
- `seo-optimization` - SEO for content collections
- `static-generation` - Static site generation patterns

---

**Skill Version**: 1.0.0
**Last Updated**: 2025-10-28
**Plugin**: website-builder
