---
description: Add new page to Next.js application with App Router conventions
argument-hint: <page-name>
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

Goal: Create a new Next.js page following App Router conventions with proper routing, metadata, and component structure.

Core Principles:
- Follow Next.js App Router conventions and best practices
- Ask user about page requirements before generating
- Detect existing patterns and match codebase style
- Validate page creation and provide clear usage instructions

Phase 1: Parse Arguments
Goal: Extract page name from arguments

Actions:
- Parse $ARGUMENTS to extract page name
- Validate page name format (should be kebab-case for routes)
- Example: "about" -> /app/about/page.tsx
- Example: "blog/[slug]" -> /app/blog/[slug]/page.tsx

Phase 2: Gather Requirements
Goal: Understand page type and requirements

Actions:
- Use AskUserQuestion to gather:
  - Page type: Static, Dynamic (with params), Protected (requires auth), or API route?
  - Layout needs: Should it use root layout or custom layout?
  - Data fetching: Server-side data fetching needed?
  - UI components: Any specific shadcn/ui components to include?
  - Metadata: Page title, description, OpenGraph tags?
- Store responses for agent context

Phase 3: Analyze Existing Structure
Goal: Understand current app structure and patterns

Actions:
- Check if app directory exists: !{bash test -d app && echo "App Router" || echo "Pages Router"}
- Load existing page examples to match patterns
- Find similar pages: !{bash find app -name "page.tsx" -type f 2>/dev/null | head -5}
- Read one example page to understand structure
- Identify layout files: !{bash find app -name "layout.tsx" -type f 2>/dev/null}

Phase 3.5: Load Design System (MANDATORY)
Goal: Ensure design system exists and load it into context

Actions:
- Check if design system exists: !{bash test -f .design-system.md && echo "✅ Design system found" || echo "❌ ERROR: Design system missing - run /nextjs-frontend:init first"}
- If missing, STOP and tell user to run /nextjs-frontend:init first
- Read design system rules: @.design-system.md

Phase 4: Page Generation
Goal: Generate page with proper structure

Actions:

Task(description="Generate Next.js page", subagent_type="page-generator-agent", prompt="You are the page-generator-agent. Create a new Next.js App Router page for: $ARGUMENTS

User Requirements:
- Page name: [from parsed arguments]
- Page type: [from user responses]
- Layout needs: [from user responses]
- Data fetching: [from user responses]
- UI components: [from user responses]
- Metadata: [from user responses]

Context from codebase:
- Router type: [App Router or Pages Router]
- Existing patterns: [from analyzed pages]
- Layout structure: [from analyzed layouts]

**MANDATORY: Design System Rules (MUST FOLLOW):**
- Typography: 4 font sizes max (text-sm, text-base, text-lg, text-xl), 2 weights (font-normal, font-semibold)
- Spacing: 8pt grid ONLY (p-2, p-4, p-6, p-8 = 8px, 16px, 24px, 32px)
- Colors: 60/30/10 rule (60% bg-background, 30% text-foreground, 10% bg-primary)
- Use OKLCH colors from theme
- WCAG AA accessibility standards

Tasks:
1. Create page.tsx at correct location (app/[page-name]/page.tsx)
2. Add proper TypeScript types for params/searchParams if dynamic
3. Include metadata export with provided title/description
4. Add server component or client component directive as needed
5. Implement data fetching if required
6. Include shadcn/ui components if specified
7. Add loading.tsx if async data fetching
8. Add error.tsx for error boundaries
9. Match existing code style and patterns

Deliverable: Complete page implementation with all files created and proper Next.js conventions followed.")

Phase 5: Validation
Goal: Verify page was created correctly

Actions:
- Check page file exists: !{bash test -f app/$ARGUMENTS/page.tsx && echo "Created" || echo "Missing"}
- Verify TypeScript compiles: !{bash npx tsc --noEmit 2>&1 | head -20}
- Check for common issues (missing imports, type errors)
- List created files: !{bash find app/$ARGUMENTS -type f 2>/dev/null}

Phase 6: Summary
Goal: Provide usage instructions

Actions:
- Display page route: http://localhost:3000/[page-name]
- Show created files with absolute paths
- Explain how to:
  - Navigate to the page (Link component or direct URL)
  - Add to navigation if applicable
  - Customize metadata
  - Add data fetching
- Suggest next steps:
  - Add to main navigation
  - Create related API routes if needed
  - Add tests for the page
  - Update sitemap.xml
