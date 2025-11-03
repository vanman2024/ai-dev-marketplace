---
description: Integrate Supabase as CMS backend for Astro website with content management and draft/publish workflows
argument-hint: none
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__figma-design-system, mcp__context7, Skill
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

Goal: Integrate Supabase as a headless CMS backend for Astro website with content tables, draft/publish workflows, and real-time updates

Core Principles:
- Use Supabase PostgreSQL for content storage
- Implement draft/publish workflow with RLS policies
- Support content types (pages, posts, media)
- Enable real-time content updates

Phase 1: Discovery & Requirements
Goal: Understand CMS integration needs

Actions:
- Create todo list with all phases using TodoWrite
- Use AskUserQuestion to gather:
  - What content types? (pages, posts, media, custom)
  - Need draft/publish workflow? (recommended: yes)
  - Need multi-author support?
  - Need content versioning?
  - Existing Supabase project or create new?
- Load Supabase CMS patterns via Context7
- Load Astro content integration docs
- Summarize requirements

Phase 2: Project Analysis
Goal: Check existing setup

Actions:
- Check if Supabase already configured
- Check Astro project structure
- Identify content integration points
- Plan database schema
- Update TodoWrite

Phase 3: Implementation
Goal: Setup Supabase CMS integration

Actions:

Launch the website-architect agent to integrate Supabase CMS.

Provide the agent with:
- CMS requirements from Phase 1
- Project structure from Phase 2
- Database schema design
- Content types and workflows
- Expected output: Complete Supabase integration with content tables, RLS policies, and Astro client

Phase 4: Validation
Goal: Verify CMS integration works

Actions:
- Check database schema created
- Verify RLS policies applied
- Check Supabase client configured
- Test content fetch from Astro
- Update TodoWrite

Phase 5: Summary
Goal: Document integration

Actions:
- Mark all todos complete
- Display database schema
- Show how to create/update content
- Provide example queries
- Show next steps (add content, configure auth)
