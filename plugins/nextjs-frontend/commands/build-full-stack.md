---
description: Complete Next.js application from initialization to deployment
argument-hint: <project-name>
---
## Available Skills

This commands has access to the following skills from the nextjs-frontend plugin:

- **deployment-config**: Vercel deployment configuration and optimization for Next.js applications including vercel.json setup, environment variables, build optimization, edge functions, and deployment troubleshooting. Use when deploying to Vercel, configuring deployment settings, optimizing build performance, setting up environment variables, configuring edge functions, or when user mentions Vercel deployment, production setup, build errors, or deployment optimization.
- **design-system-enforcement**: Mandatory design system guidelines for shadcn/ui with Tailwind v4. Enforces 4 font sizes, 2 weights, 8pt grid spacing, 60/30/10 color rule, OKLCH colors, and accessibility standards. Use when creating components, pages, or any UI elements. ALL agents MUST read and validate against design system before generating code.
- **tailwind-shadcn-setup**: Setup Tailwind CSS and shadcn/ui component library for Next.js projects. Use when configuring Tailwind CSS, installing shadcn/ui, setting up design tokens, configuring dark mode, initializing component library, or when user mentions Tailwind setup, shadcn/ui installation, component system, design system, or theming.

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
- Run initialization: /nextjs-frontend:init $ARGUMENTS
- Update TodoWrite: Mark initialization complete

Phase 2: Feature Discovery
Goal: Determine what features to integrate - auto-detect from architecture or ask user

Actions:
- **Discover** architecture docs dynamically (don't assume path!):
  !{bash find docs/architecture -name "frontend.md" 2>/dev/null | head -1 | grep -q . && echo "spec-driven" || echo "interactive"}

- If spec-driven (architecture docs exist):
  - Find and load architecture file dynamically:
    !{bash ARCH_FILE=$(find docs/architecture -name "frontend.md" 2>/dev/null | head -1); echo "$ARCH_FILE"}
  - Load frontend architecture: @$ARCH_FILE
  - Auto-detect features:
    - Supabase: Search for "Supabase", "database", "auth" in architecture
    - AI SDK: Search for "Vercel AI SDK", "chat", "streaming" in architecture
  - Extract pages from architecture (look for "Pages:", "Routes:", etc.)
  - Extract components from architecture (look for "Components:", etc.)
  - Display: "📋 Auto-detected from architecture docs (found: $ARCH_FILE)"
  - Store in config

- If interactive (no architecture docs):
  - Ask user using AskUserQuestion:
    "What features to add? 1=Supabase, 2=AI SDK, 3=Both, 4=Neither"
  - Store response for next phases

- Update TodoWrite: Mark feature discovery complete

Phase 3: Supabase Integration (Conditional)
Goal: Add Supabase if detected or requested

Actions:
- If spec-driven and Supabase detected: /nextjs-frontend:integrate-supabase $ARGUMENTS
- If interactive and user selected 1 or 3: /nextjs-frontend:integrate-supabase $ARGUMENTS
- Update TodoWrite

Phase 4: AI SDK Integration (Conditional)
Goal: Add AI SDK if detected or requested

Actions:
- If spec-driven and AI SDK detected: /nextjs-frontend:integrate-ai-sdk $ARGUMENTS
- If interactive and user selected 2 or 3: /nextjs-frontend:integrate-ai-sdk $ARGUMENTS
- Update TodoWrite

Phase 5: Page Creation
Goal: Build main application pages from architecture or user input

Actions:
- **Discover** architecture docs dynamically:
  !{bash find docs/architecture -name "frontend.md" 2>/dev/null | head -1 | grep -q . && echo "spec-driven" || echo "interactive"}

- If spec-driven:
  - Find architecture file:
    !{bash ARCH_FILE=$(find docs/architecture -name "frontend.md" 2>/dev/null | head -1); echo "$ARCH_FILE"}
  - Extract page list from architecture:
    !{bash ARCH_FILE=$(find docs/architecture -name "frontend.md" 2>/dev/null | head -1); grep "^### Page:" "$ARCH_FILE" | sed 's/^### Page: //' | head -20}
  - For each page found: /nextjs-frontend:add-page <route-name>
  - NOTE: page-generator-agent will use Glob to find and read architecture docs
  - Display: "✅ Creating pages from architecture (agents will discover docs dynamically)"

- If interactive:
  - Ask user: "List pages to create (one per line, format: PageName - /route)"
  - For each page: /nextjs-frontend:add-page <route-name>

- Update TodoWrite after pages complete

Phase 6: Component Creation
Goal: Build reusable components from architecture or user input

Actions:
- **Discover** architecture docs dynamically:
  !{bash find docs/architecture -name "frontend.md" 2>/dev/null | head -1 | grep -q . && echo "spec-driven" || echo "interactive"}

- If spec-driven:
  - Find architecture file:
    !{bash ARCH_FILE=$(find docs/architecture -name "frontend.md" 2>/dev/null | head -1); echo "$ARCH_FILE"}
  - Extract component list from architecture:
    !{bash ARCH_FILE=$(find docs/architecture -name "frontend.md" 2>/dev/null | head -1); grep "^### Component:" "$ARCH_FILE" | sed 's/^### Component: //' | head -20}
  - For each component found: /nextjs-frontend:add-component <component-name>
  - NOTE: component-builder-agent will use Glob to find and read architecture docs
  - Display: "✅ Creating components from architecture (agents will discover docs dynamically)"

- If interactive:
  - Ask user: "List components to create (one per line, e.g., Header, Footer, Card)"
  - For each component: /nextjs-frontend:add-component <component-name>

- Update TodoWrite after components complete

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
