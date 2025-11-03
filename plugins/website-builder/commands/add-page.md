---
description: Add new static page to Astro website with MDX support and optional AI content generation
argument-hint: page-name
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, mcp__content-image-generation, Skill
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

Goal: Add a new static page to existing Astro website with MDX support, layout integration, and optional AI-generated content

Core Principles:
- Follow Astro file-based routing conventions
- Use MDX for content with frontmatter
- Support AI content generation via MCP
- Integrate with existing layouts and components

Phase 1: Discovery & Requirements
Goal: Understand the page to create

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for page name/path
- If details missing, use AskUserQuestion to gather:
  - What's the page name? (e.g., about, pricing, contact)
  - Page type? (static content, form, hero+features)
  - Generate content with AI? (use content-image-generation MCP)
  - Use existing layout or create new?
- Load Astro routing documentation via Context7
- Summarize requirements

Phase 2: Project Analysis
Goal: Analyze existing Astro project

Actions:
- Check for src/pages directory
- Identify existing layouts in src/layouts
- Check content collections configuration
- Determine routing path for new page
- Update TodoWrite

Phase 3: Implementation
Goal: Create the new page

Actions:

Launch the website-content agent to create the page.

Provide the agent with:
- Page name and path from Phase 1
- Layout to use
- Content structure
- AI generation preferences
- Expected output: New MDX page with frontmatter, layout, and content

Phase 4: Validation
Goal: Verify page was created correctly

Actions:
- Check page file created in correct location
- Verify frontmatter is valid
- Check layout reference is correct
- Validate MDX syntax
- Update TodoWrite

Phase 5: Summary
Goal: Document what was created

Actions:
- Mark all todos complete
- Display page path and URL
- Show page preview command
- Provide next steps (add content, generate images, optimize SEO)
