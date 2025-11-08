---
description: Add React component from shadcn or Tailwind UI to Astro website with proper integration
argument-hint: component-name
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

Goal: Add React component (shadcn or Tailwind UI) to Astro website with proper React integration and styling

Core Principles:
- Use Astro's React integration (@astrojs/react)
- Support shadcn/ui components
- Support Tailwind UI components
- Maintain Tailwind CSS configuration

Phase 1: Discovery & Requirements
Goal: Determine which component to add

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for component name
- If details missing, use AskUserQuestion to gather:
  - Component source? (shadcn/ui, Tailwind UI, custom)
  - Component name? (e.g., button, card, hero)
  - Where to use? (page path or layout)
  - Client-side interactive? (Astro island with client:load)
- Use mcp__shadcn__search_items_in_registries to find component if shadcn
- Load Astro React integration docs via Context7
- Summarize requirements

Phase 2: Project Analysis
Goal: Check React integration setup

Actions:
- Check if @astrojs/react installed
- Check if Tailwind CSS configured
- Check for src/components directory
- Identify component dependencies
- Update TodoWrite

Phase 3: Implementation
Goal: Add the React component

Actions:

Launch the website-content agent to add the component.

Provide the agent with:
- Component name and source from Phase 1
- Integration requirements
- Component code (from shadcn MCP if applicable)
- Expected output: Component added to src/components with proper integration

Phase 4: Validation
Goal: Verify component was added correctly

Actions:
- Check component file created
- Verify React integration working
- Check Tailwind classes applied
- Validate component can be imported
- Update TodoWrite

Phase 5: Summary
Goal: Document what was created

Actions:
- Mark all todos complete
- Display component location
- Show import example
- Provide usage examples (static vs interactive island)
- Show next steps (use in pages, customize styling)
