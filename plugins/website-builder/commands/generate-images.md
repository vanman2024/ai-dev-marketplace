---
description: Generate AI-powered images for hero sections, blog posts, and marketing using Google Imagen
argument-hint: image-type
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

Goal: Generate AI-powered images using Google Imagen 3/4 for hero sections, blog posts, and marketing materials

Core Principles:
- Use content-image-generation MCP for image generation
- Support multiple image types (hero, blog header, product, icon)
- Allow aspect ratio and quality customization
- Save images to project assets

Phase 1: Discovery & Requirements
Goal: Understand what images to generate

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for image type (hero, blog, product, icon)
- Use AskUserQuestion to gather:
  - What image type? (hero section, blog header, product image, icon, custom)
  - Image description/prompt?
  - Aspect ratio? (1:1, 16:9, 4:3, 9:16)
  - Quality? (SD or HD)
  - How many images? (single or batch)
  - Use Imagen 3 or Imagen 4?
- Summarize requirements

Phase 2: Project Analysis
Goal: Check project structure

Actions:
- Check if content-image-generation MCP configured
- Identify assets directory for saving images
- Check existing image patterns
- Update TodoWrite

Phase 3: Image Generation
Goal: Generate AI images

Actions:

Launch the website-ai-generator agent to generate images.

Provide the agent with:
- Image requirements from Phase 1
- Project structure from Phase 2
- MCP tools to use:
  - generate_image_imagen3 (for single image)
  - batch_generate_images (for multiple images)
- Image parameters:
  - Prompt (enhanced with image_prompt_enhancer if needed)
  - Negative prompt (optional)
  - Aspect ratio selection
  - Quality (SD or HD)
  - Output format (PNG, JPEG, WebP)
  - Seed (for reproducibility)
- Expected output: Images saved to assets directory

Phase 4: Validation
Goal: Verify images generated successfully

Actions:
- Check images saved to correct location
- Verify image quality and dimensions
- Display image paths and preview
- Update TodoWrite

Phase 5: Summary
Goal: Document generated images

Actions:
- Mark all todos complete
- Display image locations
- Show cost breakdown for generation
- Provide usage examples (how to reference in pages)
- Show next steps (optimize images, add to content)
