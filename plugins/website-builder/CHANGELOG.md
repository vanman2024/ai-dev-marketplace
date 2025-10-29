# Changelog

All notable changes to the website-builder plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-28

### Added

#### Commands (10 total)
- `/website-builder:init` - Initialize new Astro website with AI content generation, MDX, and optional integrations
- `/website-builder:add-page` - Add static page with MDX support and optional AI content generation
- `/website-builder:add-blog` - Add blog functionality with content collections, MDX posts, and RSS feed
- `/website-builder:add-component` - Add React component from shadcn or Tailwind UI with proper integration
- `/website-builder:integrate-supabase-cms` - Integrate Supabase as CMS backend with content management workflows
- `/website-builder:integrate-content-generation` - Setup content-image-generation MCP for AI features
- `/website-builder:generate-content` - Generate AI-powered content using Claude Sonnet 4 or Gemini 2.0
- `/website-builder:generate-images` - Generate AI-powered images using Google Imagen 3/4
- `/website-builder:optimize-seo` - Optimize website for SEO with meta tags, sitemap, robots.txt, structured data
- `/website-builder:deploy` - Deploy Astro website to Vercel with optimized build configuration

#### Agents (5 total)
- `website-setup` - Initialize and configure Astro projects with dependencies and MCP integration
- `website-architect` - Design database schemas, SEO configuration, and technical architecture
- `website-content` - Create and manage pages, blog posts, layouts, and MDX components
- `website-ai-generator` - Generate AI content and images using content-image-generation MCP
- `website-verifier` - Validate SEO, accessibility, performance, and deployment readiness

#### Skills (5 total)
- `astro-patterns` - Astro best practices, routing patterns, and component architecture
- `content-collections` - Content collections setup, schemas, queries, and frontmatter management
- `component-integration` - React, MDX, and Tailwind integration patterns for Astro
- `supabase-cms` - Supabase CMS integration, schema design, RLS policies, content management
- `ai-content-generation` - AI-powered content and image generation with Google Imagen, Veo, Claude, Gemini

#### Documentation
- Comprehensive README.md with quick start guide
- MCP server configuration example (.mcp.json.example)
- Installation and setup instructions
- Troubleshooting guide
- Cost estimation guidance
- Example workflows for common use cases

#### Features
- Full Astro 4.x support with Islands architecture
- AI content generation with Claude Sonnet 4 and Gemini 2.0 Pro
- AI image generation with Google Imagen 3/4
- AI video generation with Google Veo 2/3
- Supabase CMS integration with PostgreSQL and RLS
- React component integration (shadcn/ui, Tailwind UI)
- MDX support for rich content authoring
- SEO optimization with meta tags, sitemaps, structured data
- Vercel deployment with optimized configuration
- Real-time content updates with Supabase Realtime
- Draft/publish workflows for content management
- Content versioning and audit trails
- Cost tracking for AI generation

### Technical Details
- Plugin framework version: 1.0
- Minimum Claude Code version: Latest
- Required MCP servers: content-image-generation
- Supported frameworks: Astro 4.x
- Node.js version: 18.x or higher

### Dependencies
- @supabase/supabase-js
- @astrojs/react
- @astrojs/mdx
- @astrojs/tailwind
- @astrojs/sitemap
- Google Cloud SDK (for Imagen/Veo)
- Anthropic API (for Claude)

[1.0.0]: https://github.com/ai-dev-marketplace/plugins/releases/tag/website-builder-v1.0.0
