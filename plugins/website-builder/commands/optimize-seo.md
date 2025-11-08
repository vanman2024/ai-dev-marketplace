---
description: Optimize Astro website for SEO with meta tags, sitemap, robots.txt, and structured data
argument-hint: none
---
## Available Skills

This commands has access to the following skills from the website-builder plugin:

- **ai-content-generation**: AI-powered content and image generation using content-image-generation MCP with Google Imagen 3/4, Veo 2/3, Claude Sonnet, and Gemini 2.0. Use when generating marketing content, creating hero images, building blog posts, generating product descriptions, creating videos, optimizing AI prompts, estimating generation costs, or when user mentions Imagen, Veo, AI content, AI images, content generation, image generation, video generation, marketing copy, or Google AI.
- **astro-patterns**: Astro best practices, routing patterns, component architecture, and static site generation techniques. Use when building Astro websites, setting up routing, designing component architecture, configuring static site generation, optimizing build performance, implementing content strategies, or when user mentions Astro patterns, routing, component design, SSG, static sites, or Astro best practices.
- **astro-setup**: Provides installation, prerequisite checking, and project initialization for Astro websites with AI Tech Stack 1 integration
- **component-integration**: React, MDX, and Tailwind CSS integration patterns for Astro websites. Use when adding React components, configuring MDX content, setting up Tailwind styling, integrating component libraries, building interactive UI elements, or when user mentions React integration, MDX setup, Tailwind configuration, component patterns, or UI frameworks.
- **content-collections**: Astro content collections setup, type-safe schemas, query patterns, and frontmatter validation. Use when building Astro sites, setting up content collections, creating collection schemas, querying content, validating frontmatter, or when user mentions Astro collections, content management, MDX content, type-safe content, or collection queries.
- **supabase-cms**: Supabase CMS integration patterns, schema design, RLS policies, and content management for Astro websites. Use when building CMS systems, setting up Supabase backends, creating content schemas, implementing RLS security, or when user mentions Supabase CMS, headless CMS, content management, database schemas, or Row Level Security.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Optimize Astro website for search engines with comprehensive SEO configuration including meta tags, sitemap, robots.txt, structured data, and Open Graph tags

Core Principles:
- Use Astro SEO best practices
- Generate sitemap automatically
- Add structured data (JSON-LD)
- Optimize meta tags and social sharing

Phase 1: Discovery & Requirements
Goal: Understand SEO optimization needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Site name and description?
  - Primary domain URL?
  - Default social sharing image?
  - Generate sitemap? (recommended: yes)
  - Add structured data? (recommended: yes)
  - Support multiple languages?
- Load Astro SEO documentation via Context7
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing SEO setup

Actions:
- Check existing meta tags in layouts
- Check for sitemap configuration
- Check robots.txt
- Identify pages needing SEO optimization
- Update TodoWrite

Phase 3: SEO Implementation
Goal: Implement SEO optimizations

Actions:

Launch the website-architect agent to implement SEO.

Provide the agent with:
- SEO requirements from Phase 1
- Project structure from Phase 2
- Components to add:
  - SEO component with meta tags
  - Open Graph tags
  - Twitter Card tags
  - JSON-LD structured data
  - Sitemap generation (@astrojs/sitemap)
  - robots.txt configuration
- Expected output: Complete SEO setup with all components

Phase 4: Validation
Goal: Verify SEO implementation

Actions:

Launch the website-verifier agent to validate SEO.

Provide the agent with:
- SEO implementation from Phase 3
- Validation checklist:
  - Meta tags present on all pages
  - Sitemap generated correctly
  - robots.txt configured
  - Structured data valid
  - Social sharing tags complete
- Expected output: SEO validation report with any issues

Phase 5: Summary
Goal: Document SEO setup

Actions:
- Mark all todos complete
- Display SEO configuration
- Show sitemap URL
- Provide testing recommendations:
  - Google Rich Results Test
  - Facebook Sharing Debugger
  - Twitter Card Validator
- Show next steps (submit sitemap, monitor rankings)
