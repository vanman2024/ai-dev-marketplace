---
description: Add blog functionality to Astro website with content collections, MDX posts, and RSS feed
argument-hint: none
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), mcp__context7
---

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
