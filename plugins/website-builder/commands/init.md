---
description: Initialize new Astro website project with AI content generation, MDX, and optional integrations
argument-hint: project-name
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, mcp__content-image-generation
---

**Arguments**: $ARGUMENTS

Goal: Create a production-ready Astro website with AI content generation, MDX support, component integration, and optional Supabase CMS

Core Principles:
- Use Astro best practices from official documentation
- Integrate content-image-generation MCP for AI capabilities
- Support React components (shadcn + Tailwind UI)
- Create complete, runnable project

Phase 1: Discovery & Requirements
Goal: Understand what website to build

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for project name
- If no project name provided, use AskUserQuestion to gather:
  - What's the project name?
  - Website type? (marketing site, blog, documentation, landing page)
  - Include AI content generation? (content-image-generation MCP)
  - Include Supabase CMS backend?
  - Include React components? (shadcn + Tailwind UI)
- Load Astro documentation using Context7:
  - Use mcp__context7__resolve-library-id to find Astro
  - Use mcp__context7__get-library-docs for Astro project structure
- Summarize requirements

Phase 2: Project Structure Planning
Goal: Design the Astro project structure

Actions:
- Determine directory structure based on website type
- Plan content collections for MDX
- Plan component integration strategy
- Identify dependencies (Astro, React, Tailwind, etc.)
- Update TodoWrite

Phase 3: Implementation
Goal: Create the Astro website project

Actions:

Step 1: Run automated initialization script
- Execute the astro-setup skill's init-project.sh script
- Script handles: prerequisites check, npm create astro, integrations, dependencies, directory structure, env files
- Command: bash /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/website-builder/skills/astro-setup/scripts/init-project.sh <project-name> --template=<website-type>
- The script will:
  - Check Node.js 18.14.1+ requirement
  - Create Astro project with TypeScript strictest mode
  - Install integrations: React, MDX, Tailwind, Sitemap
  - Install dependencies: @supabase/supabase-js, zod, date-fns
  - Create directory structure (src/lib, src/content/blog, public/images)
  - Generate utility files (utils.ts, supabase.ts)
  - Create SEO component
  - Setup .env.example and .env files
  - Update astro.config.mjs with all integrations

Step 2: Additional customizations based on requirements
If user requested specific integrations from Phase 1:

Launch the website-setup agent for additional customizations:
- Project name: $ARGUMENTS
- Website type from Phase 1
- Requirements from Phase 1
- Structure plan from Phase 2
- Astro documentation context
- Expected output: Customized features beyond base installation

Phase 4: Validation
Goal: Verify the project was created correctly

Actions:
- Check all required files exist (astro.config.mjs, package.json, tsconfig.json)
- Verify dependencies installed
- Check content collections configured
- Validate MCP configuration if included
- Update TodoWrite

Phase 5: Summary
Goal: Document what was created

Actions:
- Mark all todos complete
- Display project structure created
- Show installation and setup instructions
- Provide next steps (add pages, generate content, deploy)
