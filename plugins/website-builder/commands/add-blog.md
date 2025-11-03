---
description: Add blog functionality to Astro website with content collections, MDX posts, and RSS feed
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, Skill
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

Goal: Add complete blog functionality to Astro website including content collections, blog post templates, list pages, RSS feed, and pagination

Core Principles:
- Use Astro content collections for blog posts
- Support MDX for rich blog content
- Generate RSS feed automatically
- Implement pagination for post lists

Phase 1: Discovery & Requirements
Goal: Understand blog configuration

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Blog URL path? (e.g., /blog, /articles)
  - Posts per page for pagination? (default: 10)
  - Include RSS feed? (recommended: yes)
  - Include tags/categories?
  - Generate sample blog posts with AI?
- Load Astro content collections documentation via Context7
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing project structure

Actions:
- Check for src/content directory
- Check astro.config.mjs for content collections
- Identify existing blog setup (if any)
- Plan blog directory structure
- Update TodoWrite

Phase 3: Implementation
Goal: Add blog functionality

Actions:

Launch the website-content agent to add blog functionality.

Provide the agent with:
- Blog configuration from Phase 1
- Project structure from Phase 2
- Content collections schema
- Expected output: Complete blog with posts, list pages, RSS, pagination

Phase 4: Validation
Goal: Verify blog was added correctly

Actions:
- Check content collections configured
- Verify blog post schema defined
- Check blog pages created (list, individual post, pagination)
- Validate RSS feed generation
- Update TodoWrite

Phase 5: Summary
Goal: Document what was created

Actions:
- Mark all todos complete
- Display blog structure
- Show how to add new blog posts
- Provide example blog post frontmatter
- Show next steps (write posts, generate content with AI)
