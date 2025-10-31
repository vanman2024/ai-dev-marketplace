# Astro Project Structure - AI Tech Stack 1

Complete directory structure for Astro websites with AI Tech Stack 1 integrations.

## Default Structure

```
my-astro-project/
├── src/
│   ├── pages/              # Routes (REQUIRED)
│   │   ├── index.astro     # Homepage (/)
│   │   ├── about.astro     # About page (/about)
│   │   ├── blog/           # Blog routes
│   │   │   ├── index.astro # Blog listing (/blog)
│   │   │   └── [slug].astro # Dynamic blog post (/blog/my-post)
│   │   └── api/            # API routes
│   │       └── hello.ts    # API endpoint (/api/hello)
│   │
│   ├── components/         # Reusable components
│   │   ├── Header.astro
│   │   ├── Footer.astro
│   │   ├── SEO.astro       # SEO meta tags
│   │   └── react/          # React components
│   │       └── Counter.tsx
│   │
│   ├── layouts/            # Layout templates
│   │   ├── BaseLayout.astro # Default layout
│   │   ├── BlogLayout.astro # Blog post layout
│   │   └── DocsLayout.astro # Documentation layout
│   │
│   ├── content/            # Content collections
│   │   ├── config.ts       # Content schema definitions
│   │   ├── blog/           # Blog posts
│   │   │   ├── post-1.md
│   │   │   └── post-2.mdx
│   │   └── docs/           # Documentation
│   │       └── getting-started.md
│   │
│   ├── styles/             # Global styles
│   │   ├── global.css      # Global CSS
│   │   └── utilities.css   # Utility classes
│   │
│   ├── lib/                # Utilities and helpers
│   │   ├── supabase.ts     # Supabase client
│   │   ├── utils.ts        # Helper functions
│   │   └── constants.ts    # Constants
│   │
│   └── env.d.ts            # TypeScript environment types
│
├── public/                 # Static assets (copied as-is)
│   ├── favicon.svg
│   ├── robots.txt
│   ├── images/             # Static images
│   └── fonts/              # Web fonts
│
├── .env.example            # Environment variable template
├── .gitignore              # Git ignore rules
├── astro.config.mjs        # Astro configuration
├── package.json            # Dependencies and scripts
├── tailwind.config.js      # Tailwind CSS config
├── tsconfig.json           # TypeScript config
└── README.md               # Project documentation
```

## Directory Purposes

### **src/** - Source Code
All processed code lives here. Astro compiles, bundles, and optimizes everything in src/.

### **src/pages/** - Routes (REQUIRED)
- File-based routing: `src/pages/about.astro` → `/about`
- Dynamic routes: `src/pages/blog/[slug].astro` → `/blog/my-post`
- API routes: `src/pages/api/hello.ts` → `/api/hello`
- **This is the only mandatory directory**

### **src/components/** - Reusable Components
- `.astro` components (Astro's syntax)
- React/Vue/Svelte components
- Can be organized by framework: `components/react/`, `components/vue/`

### **src/layouts/** - Page Layouts
- Shared UI structure across multiple pages
- Typically wraps page content with header, footer, navigation
- Example: `BaseLayout.astro`, `BlogLayout.astro`

### **src/content/** - Content Collections
- Markdown/MDX files organized by collection
- Type-safe with Zod schemas defined in `content/config.ts`
- Automatically generates TypeScript types

### **src/styles/** - CSS Files
- Global stylesheets
- Tailwind CSS utilities
- Component-specific styles

### **src/lib/** - Utilities
- Helper functions
- API clients (Supabase, external APIs)
- Constants and configuration
- Type definitions

### **public/** - Static Assets
- Files copied to build output without processing
- Images, fonts, favicons
- `robots.txt`, `sitemap.xml`, manifests
- **Do not import these in code** - reference by path only

## Configuration Files

### **astro.config.mjs**
Main configuration file. Defines:
- Integrations (@astrojs/react, @astrojs/mdx, etc.)
- Output mode (static, server, hybrid)
- Build options
- Markdown settings

### **tsconfig.json**
TypeScript configuration for:
- Path aliases
- Type checking strictness
- Module resolution
- Integration with Astro's types

### **tailwind.config.js**
Tailwind CSS configuration:
- Content paths (where to look for classes)
- Theme customization
- Plugins

### **package.json**
Scripts and dependencies:
```json
{
  "scripts": {
    "dev": "astro dev"
    "build": "astro check && astro build"
    "preview": "astro preview"
  }
}
```

## AI Tech Stack 1 Additions

### **src/lib/supabase.ts**
Supabase client initialization for database queries.

### **src/lib/ai-content.ts**
Integration with content-image-generation MCP server.

### **src/content/config.ts**
Content collection schemas with Zod validation.

### **.env.example**
Template for environment variables:
```bash
# Supabase
PUBLIC_SUPABASE_URL=your-project.supabase.co
PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# AI Services
GOOGLE_API_KEY=your-google-api-key
ANTHROPIC_API_KEY=your-anthropic-key

# MCP Servers (if using)
MCP_CONTENT_GENERATION_URL=http://localhost:3000
```

## Best Practices

1. **Keep src/ organized**: All processed code goes in src/
2. **Public/ is static only**: No imports, just direct file references
3. **Use content collections**: Type-safe content management for blogs/docs
4. **Leverage layouts**: Share common UI structure across pages
5. **Component organization**: Group by feature or framework
6. **API routes**: Use src/pages/api/ for server endpoints
7. **TypeScript**: Enable strict mode for better type safety

## File Naming Conventions

- Pages: `kebab-case.astro` → `/kebab-case`
- Components: `PascalCase.astro` or `PascalCase.tsx`
- Layouts: `LayoutName.astro`
- Dynamic routes: `[param].astro` or `[...slug].astro`
- API routes: `endpoint.ts` or `endpoint.js`

## Content Collections

```typescript
// src/content/config.ts
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  schema: z.object({
    title: z.string()
    description: z.string()
    pubDate: z.date()
    author: z.string()
    image: z.string().optional()
    tags: z.array(z.string()).default([])
  })
});

export const collections = { blog };
```

This structure provides a solid foundation for building AI-powered Astro websites with full-stack capabilities.
