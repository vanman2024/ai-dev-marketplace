---
description: Deploy Astro website to Vercel with optimized build configuration and environment variables
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, Skill
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

Goal: Deploy Astro website to Vercel with optimized build settings, environment variables, and production configuration

Core Principles:
- Use Vercel CLI for deployment
- Optimize build configuration for Astro
- Configure environment variables securely
- Validate before deploying

Phase 1: Discovery & Requirements
Goal: Understand deployment configuration

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Deploy to production or preview?
  - Vercel project already exists?
  - Environment variables needed?
  - Custom domain configured?
  - Need to configure build settings?
- Load Vercel deployment docs via Context7
- Summarize requirements

Phase 2: Pre-Deployment Validation
Goal: Verify project is ready for deployment

Actions:

Launch the website-verifier agent to validate deployment readiness.

Provide the agent with:
- Project structure and configuration
- Validation checks:
  - Build succeeds locally
  - No build errors or warnings
  - Environment variables documented
  - SEO meta tags configured
  - Sitemap generated
  - All pages render correctly
- Expected output: Deployment readiness report with any blockers

Phase 3: Deployment Configuration
Goal: Configure Vercel deployment

Actions:

Launch the website-architect agent to configure deployment.

Provide the agent with:
- Deployment requirements from Phase 1
- Validation results from Phase 2
- Configuration to add:
  - vercel.json with build settings
  - .vercelignore for excluded files
  - Environment variable documentation
  - Build output directory configuration
  - Node.js version specification
- Expected output: Complete Vercel configuration files

Phase 4: Deploy
Goal: Execute deployment to Vercel

Actions:
- Check if Vercel CLI installed
- Install if needed: !{bash npm install -g vercel}
- Run deployment: !{bash vercel --prod} or !{bash vercel} for preview
- Capture deployment URL
- Update TodoWrite

Phase 5: Post-Deployment Validation
Goal: Verify deployment succeeded

Actions:
- Check deployment status
- Verify site is accessible
- Test key pages load correctly
- Verify environment variables applied
- Update TodoWrite

Phase 6: Summary
Goal: Document deployment

Actions:
- Mark all todos complete
- Display deployment URL
- Show environment variables configured
- Provide monitoring recommendations
- Show next steps (configure custom domain, setup analytics)
