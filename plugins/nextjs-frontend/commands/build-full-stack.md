---
description: Complete Next.js application from initialization to deployment
argument-hint: <project-name>
allowed-tools: SlashCommand, Task, Read, Write, Bash, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Build a complete Next.js application from scratch through deployment-ready state

Core Principles:
- Orchestrate specialized commands sequentially
- Ask about features before building
- Track progress throughout workflow
- Wait for each command to complete before proceeding

Phase 1: Initialize Project
Goal: Create new Next.js project with TypeScript and Tailwind

Actions:
- Create TodoWrite list for tracking full workflow
- Run initialization command:

/nextjs-frontend:init $ARGUMENTS

CRITICAL: Wait for init command to complete before proceeding.

Update TodoWrite: Mark initialization complete.

Phase 2: Feature Discovery
Goal: Determine what features to integrate

Actions:
- Ask user using AskUserQuestion:
  "What features to add? 1=Supabase, 2=AI SDK, 3=Both, 4=Neither"
- Store response for next phases
- Update TodoWrite: Mark feature discovery complete

Phase 3: Supabase Integration (Conditional)
Goal: Add Supabase if requested

Actions:
- If user selected 1 or 3, run: /nextjs-frontend:integrate-supabase $ARGUMENTS
- Wait for completion, then update TodoWrite

Phase 4: AI SDK Integration (Conditional)
Goal: Add AI SDK if requested

Actions:
- If user selected 2 or 3, run: /nextjs-frontend:integrate-ai-sdk $ARGUMENTS
- Wait for completion, then update TodoWrite

Phase 5: Page Creation
Goal: Build main application pages

Actions:
- Ask user: "List pages to create (one per line, format: PageName - /route)"
- For each page, run sequentially: /nextjs-frontend:add-page <route-name>
- CRITICAL: Wait for each command to complete before next
- Update TodoWrite after each page

Phase 6: Component Creation
Goal: Build reusable components

Actions:
- Ask user: "List components to create (one per line, e.g., Header, Footer, Card)"
- For each component, run sequentially: /nextjs-frontend:add-component <component-name>
- CRITICAL: Wait for each command to complete before next
- Update TodoWrite after each component

Phase 7: Design System Enforcement
Goal: Ensure consistent styling and design patterns

Actions:
- Run: !{bash bash /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/nextjs-frontend/skills/design-system-enforcement/scripts/validate-design-system.sh}
- Fix any issues automatically
- Update TodoWrite: Mark design system complete

Phase 8: Final Summary
Goal: Report completion and next steps

Actions:
- Mark all TodoWrite items complete
- Display summary:

BUILD COMPLETE: $ARGUMENTS

Created:
- Next.js app with TypeScript and Tailwind CSS
- Features: [list integrations]
- Pages: [list pages]
- Components: [list components]
- Design system validated

Next Steps:
1. cd $ARGUMENTS && npm run dev
2. Review /app and /components directories
3. Configure tailwind.config.ts and next.config.js
4. Add .env.local variables
5. npx vercel deploy

Ready for development!
