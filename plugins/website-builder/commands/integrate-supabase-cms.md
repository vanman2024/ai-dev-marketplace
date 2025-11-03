---
description: Integrate Supabase as CMS backend for Astro website with content management and draft/publish workflows
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__figma-design-system, mcp__context7, Skill
---
## Available Skills

This commands has access to the following skills from the website-builder plugin:

- **ai-content-generation**: AI-powered content and image generation using content-image-generation MCP with Google Imagen 3/4, Veo 2/3, Claude Sonnet, and Gemini 2.0. Use when generating marketing content, creating hero images, building blog posts, generating product descriptions, creating videos, optimizing AI prompts, estimating generation costs, or when user mentions Imagen, Veo, AI content, AI images, content generation, image generation, video generation, marketing copy, or Google AI.\n- **astro-patterns**: Astro best practices, routing patterns, component architecture, and static site generation techniques. Use when building Astro websites, setting up routing, designing component architecture, configuring static site generation, optimizing build performance, implementing content strategies, or when user mentions Astro patterns, routing, component design, SSG, static sites, or Astro best practices.\n- **astro-setup**: Provides installation, prerequisite checking, and project initialization for Astro websites with AI Tech Stack 1 integration\n- **component-integration**: React, MDX, and Tailwind CSS integration patterns for Astro websites. Use when adding React components, configuring MDX content, setting up Tailwind styling, integrating component libraries, building interactive UI elements, or when user mentions React integration, MDX setup, Tailwind configuration, component patterns, or UI frameworks.\n- **content-collections**: Astro content collections setup, type-safe schemas, query patterns, and frontmatter validation. Use when building Astro sites, setting up content collections, creating collection schemas, querying content, validating frontmatter, or when user mentions Astro collections, content management, MDX content, type-safe content, or collection queries.\n- **supabase-cms**: Supabase CMS integration patterns, schema design, RLS policies, and content management for Astro websites. Use when building CMS systems, setting up Supabase backends, creating content schemas, implementing RLS security, or when user mentions Supabase CMS, headless CMS, content management, database schemas, or Row Level Security.\n
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

Goal: Integrate Supabase as a headless CMS backend for Astro website with content tables, draft/publish workflows, and real-time updates

Core Principles:
- Use Supabase PostgreSQL for content storage
- Implement draft/publish workflow with RLS policies
- Support content types (pages, posts, media)
- Enable real-time content updates

Phase 1: Discovery & Requirements
Goal: Understand CMS integration needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - What content types? (pages, posts, media, custom)
  - Need draft/publish workflow? (recommended: yes)
  - Need multi-author support?
  - Need content versioning?
  - Existing Supabase project or create new?
- Load Supabase CMS patterns via Context7
- Load Astro content integration docs
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing setup

Actions:
- Check if Supabase already configured
- Check Astro project structure
- Identify content integration points
- Plan database schema
- Update TodoWrite

Phase 3: Implementation
Goal: Setup Supabase CMS integration

Actions:

Launch the website-architect agent to integrate Supabase CMS.

Provide the agent with:
- CMS requirements from Phase 1
- Project structure from Phase 2
- Database schema design
- Content types and workflows
- Expected output: Complete Supabase integration with content tables, RLS policies, and Astro client

Phase 4: Validation
Goal: Verify CMS integration works

Actions:
- Check database schema created
- Verify RLS policies applied
- Check Supabase client configured
- Test content fetch from Astro
- Update TodoWrite

Phase 5: Summary
Goal: Document integration

Actions:
- Mark all todos complete
- Display database schema
- Show how to create/update content
- Provide example queries
- Show next steps (add content, configure auth)
