---
description: Add React component from shadcn or Tailwind UI to Astro website with proper integration
argument-hint: component-name
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite, mcp__shadcn, mcp__context7
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
