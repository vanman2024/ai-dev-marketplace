---
description: Scaffold complete Next.js application with sidebar, header, footer, and navigation from architecture docs using shadcn application blocks
argument-hint: [project-name]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Arguments**: $ARGUMENTS

Goal: Build complete application scaffold with navigation, layout components, and route structure from architecture documentation using shadcn/ui application blocks

Core Principles:
- Discover architecture docs dynamically (don't assume paths!)
- Use shadcn application blocks (examples) not individual components
- Build complete navigation structure from architecture specs
- Follow Next.js 15 App Router conventions

Phase 1: Discovery & Setup
Goal: Find architecture documentation and understand application structure

Actions:
- Create TodoWrite list with phases
- Discover architecture docs using Glob: !{glob docs/architecture/**/frontend.md}
- If found: Read architecture and extract layout requirements, navigation routes, page structure
- If not found: Ask user what layout type needed (Dashboard, Marketing, Admin Panel, Custom)
- Update TodoWrite

Phase 2: Search shadcn Application Blocks
Goal: Find complete application scaffolds in shadcn registry

Actions:
- Update TodoWrite status
- Search shadcn MCP for APPLICATION BLOCKS using get_item_examples_from_registries
- Query for: example-dashboard, example-sidebar, example-header, example-admin-panel
- Review implementation code, note dependencies, understand layout structure
- Update TodoWrite

Phase 3: Generate Layout Components
Goal: Build sidebar, header, footer, and navigation using component-builder-agent

Actions:
- Update TodoWrite status
- Launch component-builder-agent THREE times in parallel using Task tool:
  1. Sidebar: Build components/layout/sidebar.tsx with navigation routes from architecture, shadcn components, design system compliance
  2. Header: Build components/layout/header.tsx with user menu, theme toggle, branding, search if needed
  3. Footer: Build components/layout/footer.tsx with copyright, links, responsive design
- Wait for all agents to complete
- Update TodoWrite

Phase 4: Wire Navigation & Layout
Goal: Create dashboard layout with all components integrated

Actions:
- Update TodoWrite status
- Launch page-generator-agent using Task tool to create app/(dashboard)/layout.tsx
- Layout should import Sidebar, Header, Footer components and arrange with flexbox
- Follow design system for spacing, colors, typography
- Wait for completion
- Update TodoWrite

Phase 5: Validation
Goal: Verify everything works correctly

Actions:
- Update TodoWrite status
- Check files created: !{bash ls -la components/layout/*.tsx app/\(dashboard\)/layout.tsx 2>/dev/null | wc -l}
- Run type check: !{bash npm run type-check || npx tsc --noEmit}
- Verify design system: /nextjs-frontend:enforce-design-system components/layout/
- Update TodoWrite: Mark all complete

Phase 6: Summary
Goal: Report what was built and next steps

Actions:
- Display summary of created components
- List navigation routes wired from architecture
- Confirm design system compliance, dark mode, responsive design
- Show next steps: npm run dev, add pages with /nextjs-frontend:add-page
- Reference architecture file source and route count
