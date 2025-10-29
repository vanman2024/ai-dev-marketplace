---
description: Add new static page to Astro website with MDX support and optional AI content generation
argument-hint: page-name
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), mcp__context7, mcp__content-image-generation
---

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
