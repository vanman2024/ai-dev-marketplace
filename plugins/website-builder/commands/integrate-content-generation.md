---
description: Setup content-image-generation MCP server for AI-powered content and image generation
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__content-image-generation, mcp__context7, Skill
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

Goal: Setup and configure content-image-generation MCP server for AI-powered content generation (Claude/Gemini) and image generation (Google Imagen 3/4)

Core Principles:
- Configure content-image-generation MCP server
- Setup Google Cloud credentials for Imagen
- Configure Anthropic/Google AI API keys
- Integrate with Astro project

Phase 1: Discovery & Requirements
Goal: Understand MCP integration needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Have Google Cloud project with Vertex AI enabled?
  - Have Anthropic API key for content generation?
  - Have Google AI API key (optional alternative)?
  - Where to store MCP configuration? (.mcp.json in project root)
  - Need to generate sample content now?
- Load content-image-generation MCP documentation
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing setup

Actions:
- Check if .mcp.json already exists
- Check for existing MCP servers configured
- Verify Astro project structure
- Check for environment variable files
- Update TodoWrite

Phase 3: Implementation
Goal: Configure MCP server

Actions:

Launch the website-setup agent to configure content-image-generation MCP.

Provide the agent with:
- MCP server location: mcp-servers/content-image-generation-mcp
- Configuration requirements from Phase 1
- Project structure from Phase 2
- Environment variables needed:
  - GOOGLE_CLOUD_PROJECT
  - ANTHROPIC_API_KEY
  - GOOGLE_AI_API_KEY (optional)
- Expected output: .mcp.json configuration, .env.example template, integration guide

Phase 4: Validation
Goal: Verify MCP integration works

Actions:
- Check .mcp.json created and valid
- Verify MCP server can be loaded
- Test basic MCP connection
- Update TodoWrite

Phase 5: Summary
Goal: Document integration

Actions:
- Mark all todos complete
- Display MCP configuration
- Show available MCP tools: - generate_image_imagen3 (Google Imagen 3/4 image generation)
  - batch_generate_images (batch image generation)
  - generate_video_veo3 (Google Veo 2/3 video generation)
  - generate_marketing_content (Claude/Gemini content generation)
  - calculate_cost_estimate (campaign cost estimation)
- Provide usage examples
- Show next steps (generate content, generate images)
