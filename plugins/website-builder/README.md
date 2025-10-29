# Website Builder Plugin

AI-powered website builder for creating modern websites with Astro, MDX, AI content generation, Supabase CMS, and component integration.

## Overview

The website-builder plugin provides comprehensive support for building production-ready websites using:

- **Astro 4.x** - Modern static site generator with Islands architecture
- **AI Content Generation** - Google Imagen 3/4, Veo 2/3, Claude Sonnet 4, Gemini 2.0
- **Supabase CMS** - Headless CMS with PostgreSQL and real-time updates
- **Component Integration** - React, MDX, shadcn/ui, Tailwind CSS
- **SEO Optimization** - Meta tags, sitemaps, structured data
- **Deployment** - Optimized Vercel deployment

## Features

### 10 Slash Commands

1. `/website-builder:init` - Initialize new Astro website with AI features
2. `/website-builder:add-page` - Add static page with MDX and AI content
3. `/website-builder:add-blog` - Add blog with content collections and RSS
4. `/website-builder:add-component` - Add React components from shadcn/Tailwind UI
5. `/website-builder:integrate-supabase-cms` - Setup Supabase CMS backend
6. `/website-builder:integrate-content-generation` - Setup AI content/image generation
7. `/website-builder:generate-content` - Generate AI marketing copy and blog posts
8. `/website-builder:generate-images` - Generate AI images with Google Imagen
9. `/website-builder:optimize-seo` - Add comprehensive SEO configuration
10. `/website-builder:deploy` - Deploy to Vercel with optimization

### 5 Specialized Agents

1. **website-setup** - Initialize and configure Astro projects
2. **website-architect** - Design schemas, SEO, and architecture
3. **website-content** - Create pages, blog posts, and MDX components
4. **website-ai-generator** - Generate AI content and images
5. **website-verifier** - Validate SEO, accessibility, and deployment readiness

### 5 Comprehensive Skills

1. **astro-patterns** - Astro best practices and routing patterns
2. **content-collections** - Content collections setup and management
3. **component-integration** - React, MDX, and Tailwind integration
4. **supabase-cms** - Supabase CMS integration and RLS policies
5. **ai-content-generation** - AI-powered content and image generation

## Quick Start

### 1. Initialize a New Website

```bash
/website-builder:init my-website
```

This creates:
- Astro project with TypeScript
- React and MDX integration
- Tailwind CSS styling
- Content collections setup
- MCP server configuration

### 2. Add AI Content Generation

```bash
/website-builder:integrate-content-generation
```

Configures:
- content-image-generation MCP server
- Google Cloud credentials
- Anthropic API key
- Image/video output directory

### 3. Generate Content

```bash
/website-builder:generate-content hero
```

Generates:
- Marketing copy with Claude Sonnet 4 or Gemini 2.0
- Hero sections, blog posts, product descriptions
- Customizable tone, style, and length

### 4. Generate Images

```bash
/website-builder:generate-images hero
```

Generates:
- Images with Google Imagen 3/4
- Multiple aspect ratios (1:1, 16:9, 4:3, 9:16)
- SD or HD quality
- Batch generation support

### 5. Add Supabase CMS

```bash
/website-builder:integrate-supabase-cms
```

Sets up:
- Content tables (pages, posts, media)
- RLS policies for security
- Draft/publish workflows
- Real-time updates

### 6. Deploy to Vercel

```bash
/website-builder:deploy
```

Deploys with:
- Optimized build configuration
- Environment variables
- SEO meta tags
- Sitemap and robots.txt

## MCP Server Setup

### Content & Image Generation

The plugin uses the `content-image-generation` MCP server for AI features.

**Configuration:**

1. Copy `.mcp.json.example` to your project root as `.mcp.json`
2. Set environment variables:

```bash
GOOGLE_CLOUD_PROJECT=your-google-cloud-project-id
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_AI_API_KEY=... # Optional, for Gemini
```

3. Available MCP tools:
   - `generate_image_imagen3` - Generate single image
   - `batch_generate_images` - Generate multiple images
   - `generate_video_veo3` - Generate videos
   - `generate_marketing_content` - Generate text content
   - `calculate_cost_estimate` - Estimate campaign costs

## Architecture

### Static vs Dynamic

Astro supports multiple rendering modes:

- **Static (SSG)**: Pre-built at build time, fast but requires rebuild
- **Server-rendered (SSR)**: Rendered on request, dynamic data
- **Hybrid**: Mix static and server-rendered pages
- **Islands**: Static with interactive React components

**Recommendation**: Start with static (default), add SSR for dynamic features.

### Content Management

Two options:

1. **Content Collections** (File-based)
   - Git-versioned markdown/MDX files
   - Type-safe with Zod schemas
   - Fast builds, simple deployment

2. **Supabase CMS** (Database-based)
   - Real-time updates
   - Multi-author workflows
   - Draft/publish states
   - Content versioning

**Recommendation**: Content collections for blogs, Supabase for complex CMS needs.

## Cost Estimation

AI generation costs (approximate):

- **Images**: $0.020-0.050 per image (SD vs HD)
- **Videos**: $0.15-0.20 per video
- **Content**: $0.0005-0.003 per request (Gemini vs Claude)

Use `/website-builder:generate-content` with cost estimation before generating.

## Examples

### Create a Marketing Landing Page

```bash
# 1. Initialize project
/website-builder:init landing-page

# 2. Setup AI generation
/website-builder:integrate-content-generation

# 3. Generate hero content
/website-builder:generate-content hero

# 4. Generate hero image
/website-builder:generate-images hero

# 5. Add components
/website-builder:add-component button
/website-builder:add-component card

# 6. Optimize SEO
/website-builder:optimize-seo

# 7. Deploy
/website-builder:deploy
```

### Create a Blog with CMS

```bash
# 1. Initialize project
/website-builder:init my-blog

# 2. Add blog functionality
/website-builder:add-blog

# 3. Setup Supabase CMS
/website-builder:integrate-supabase-cms

# 4. Generate blog posts
/website-builder:generate-content blog

# 5. Generate blog images
/website-builder:generate-images blog

# 6. Deploy
/website-builder:deploy
```

## Troubleshooting

### MCP Server Not Found

Ensure the content-image-generation MCP server is installed:

```bash
cd ../../mcp-servers/content-image-generation-mcp
uv pip install -e .
```

### Build Errors

Run validation before deploying:

```bash
npm run build
npm run typecheck
```

### AI Generation Fails

Check environment variables:

```bash
# Verify credentials set
echo $GOOGLE_CLOUD_PROJECT
echo $ANTHROPIC_API_KEY
```

## Contributing

This plugin is part of the AI Dev Marketplace. For issues or feature requests, please see the main repository.

## License

MIT License - See LICENSE file for details
