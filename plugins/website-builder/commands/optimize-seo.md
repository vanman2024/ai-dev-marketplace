---
description: Optimize Astro website for SEO with meta tags, sitemap, robots.txt, and structured data
argument-hint: none
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), TodoWrite(*), mcp__context7
---

**Arguments**: $ARGUMENTS

Goal: Optimize Astro website for search engines with comprehensive SEO configuration including meta tags, sitemap, robots.txt, structured data, and Open Graph tags

Core Principles:
- Use Astro SEO best practices
- Generate sitemap automatically
- Add structured data (JSON-LD)
- Optimize meta tags and social sharing

Phase 1: Discovery & Requirements
Goal: Understand SEO optimization needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - Site name and description?
  - Primary domain URL?
  - Default social sharing image?
  - Generate sitemap? (recommended: yes)
  - Add structured data? (recommended: yes)
  - Support multiple languages?
- Load Astro SEO documentation via Context7
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing SEO setup

Actions:
- Check existing meta tags in layouts
- Check for sitemap configuration
- Check robots.txt
- Identify pages needing SEO optimization
- Update TodoWrite

Phase 3: SEO Implementation
Goal: Implement SEO optimizations

Actions:

Launch the website-architect agent to implement SEO.

Provide the agent with:
- SEO requirements from Phase 1
- Project structure from Phase 2
- Components to add:
  - SEO component with meta tags
  - Open Graph tags
  - Twitter Card tags
  - JSON-LD structured data
  - Sitemap generation (@astrojs/sitemap)
  - robots.txt configuration
- Expected output: Complete SEO setup with all components

Phase 4: Validation
Goal: Verify SEO implementation

Actions:

Launch the website-verifier agent to validate SEO.

Provide the agent with:
- SEO implementation from Phase 3
- Validation checklist:
  - Meta tags present on all pages
  - Sitemap generated correctly
  - robots.txt configured
  - Structured data valid
  - Social sharing tags complete
- Expected output: SEO validation report with any issues

Phase 5: Summary
Goal: Document SEO setup

Actions:
- Mark all todos complete
- Display SEO configuration
- Show sitemap URL
- Provide testing recommendations:
  - Google Rich Results Test
  - Facebook Sharing Debugger
  - Twitter Card Validator
- Show next steps (submit sitemap, monitor rankings)
