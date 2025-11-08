---
description: Generate AI-powered content for pages, blogs, and marketing copy using content-image-generation MCP
argument-hint: content-type
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

Goal: Generate AI-powered marketing content, blog posts, and page copy using Claude Sonnet 4 or Gemini 2.0 via content-image-generation MCP

Core Principles:
- Use content-image-generation MCP for AI content generation
- Support multiple content types (hero copy, blog posts, product descriptions)
- Allow customization of tone, style, and length
- Save generated content to project

Phase 1: Discovery & Requirements
Goal: Understand what content to generate

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for content type (hero, blog, product, custom)
- Use AskUserQuestion to gather:
  - What content type? (hero section, blog post, product description, landing page)
  - What's the topic/subject?
  - Tone and style? (professional, casual, technical, marketing)
  - Target audience?
  - Length preference? (short, medium, long)
  - Which AI model? (Claude Sonnet 4, Gemini 2.0 Pro)
- Summarize requirements

Phase 2: Project Analysis
Goal: Check project structure

Actions:
- Check if content-image-generation MCP configured
- Identify where to save generated content
- Check existing content patterns
- Update TodoWrite

Phase 3: Content Generation
Goal: Generate AI content

Actions:

Launch the website-ai-generator agent to generate content.

Provide the agent with:
- Content requirements from Phase 1
- Project structure from Phase 2
- MCP tool to use: generate_marketing_content
- Content parameters:
  - Topic and subject matter
  - Tone and style preferences
  - Target audience
  - Desired length
  - AI model selection
- Expected output: Generated content saved to appropriate location

Phase 4: Content Review
Goal: Review and refine generated content

Actions:

Launch the website-content agent to review and integrate content.

Provide the agent with:
- Generated content from Phase 3
- Integration requirements
- Format requirements (MDX, HTML, plain text)
- Expected output: Polished content ready for use

Phase 5: Summary
Goal: Document generated content

Actions:
- Mark all todos complete
- Display generated content preview
- Show file location
- Provide cost estimate for generation
- Show next steps (edit content, generate images, publish)
