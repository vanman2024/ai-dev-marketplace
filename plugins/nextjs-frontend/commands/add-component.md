---
description: Add component with shadcn/ui integration and TypeScript
argument-hint: <component-name>
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

Goal: Create a new React component with shadcn/ui integration, TypeScript types, and proper file structure

Core Principles:
- Understand component requirements before building
- Follow Next.js and shadcn/ui conventions
- Use TypeScript for type safety
- Follow existing project patterns

Phase 1: Parse Arguments
Goal: Extract component name from user input

Actions:
- Parse $ARGUMENTS for component name
- Validate component name is in kebab-case or PascalCase
- Example: !{bash echo "$ARGUMENTS" | grep -E '^[a-z-]+$|^[A-Z][a-zA-Z]+$'}

Phase 2: Discovery
Goal: Gather component requirements and understand project structure

Actions:
- Use AskUserQuestion to determine:
  - Component type: UI component, feature component, or layout component?
  - Does it need shadcn/ui primitives (Button, Input, Card, etc.)?
  - Should it be client-side or server component?
  - Any specific props or functionality needed?
- Load Next.js config to understand project setup
- Example: @next.config.js
- Check existing component structure
- Example: !{bash find . -type f -name "*.tsx" -path "*/components/*" | head -5}

Phase 3: Pattern Analysis
Goal: Understand existing component conventions

Actions:
- Read 2-3 existing components to identify patterns
- Check for component directory structure (flat vs nested)
- Identify naming conventions (PascalCase files, index exports)
- Note import patterns and common utilities
- Example: !{bash ls -la app/components/ src/components/ components/ 2>/dev/null | head -20}

Phase 4: Load Design System (MANDATORY)
Goal: Ensure design system exists and load it into context

Actions:
- Check if design system exists: !{bash test -f .design-system.md && echo "✅ Design system found" || echo "❌ ERROR: Design system missing - run /nextjs-frontend:init first"}
- If missing, STOP and tell user to run /nextjs-frontend:init first
- Read design system rules: @.design-system.md

**Design System Rules Now Loaded from .design-system.md:**
(Agent now has design system in context and will follow these rules automatically)

Phase 5: Implementation
Goal: Create the component using component-builder-agent

Actions:

Task(description="Build React component", subagent_type="component-builder-agent", prompt="You are the component-builder-agent. Create a new React component for $ARGUMENTS.

Context from Discovery:
- Component name: $ARGUMENTS
- Project type: Next.js with TypeScript
- Available: shadcn/ui primitives, Tailwind CSS
- Component conventions: Follow existing patterns identified

**MANDATORY: Design System Rules (MUST FOLLOW):**
- Typography: 4 font sizes max (text-sm, text-base, text-lg, text-xl), 2 weights (font-normal, font-semibold)
- Spacing: 8pt grid ONLY (p-2, p-4, p-6, p-8 = 8px, 16px, 24px, 32px)
- Colors: 60/30/10 rule (60% bg-background, 30% text-foreground, 10% bg-primary)
- Use OKLCH colors from theme (bg-background, text-foreground, bg-primary, etc.)
- WCAG AA accessibility (4.5:1 contrast for text)

Requirements:
- Create component file with proper TypeScript types
- Use functional component with React.FC or direct typing
- Include Props interface if component accepts props
- Add shadcn/ui components if specified by user
- Follow Next.js 13+ conventions (use client/server directives as needed)
- Include proper imports and exports
- Add JSDoc comments for props
- Follow existing project structure
- **APPLY DESIGN SYSTEM RULES ABOVE**

Deliverable:
- Component file at appropriate location
- Proper TypeScript types
- shadcn/ui integration if needed
- Export statement for easy imports
- **Design system compliant styling**")

Phase 5: Verification & Design System Enforcement
Goal: Verify component was created correctly and follows design system

**IMPORTANT: Load design system enforcement skill:**

!{skill design-system-enforcement}

This loads design system rules, validation scripts, and auto-fix patterns.

Actions:
- Check that component file exists
- Example: !{bash find . -name "*$ARGUMENTS*" -type f 2>/dev/null}
- Run TypeScript type checking if available
- Example: !{bash npm run typecheck 2>/dev/null || npx tsc --noEmit 2>/dev/null || echo "Type check not available"}
- Verify imports resolve correctly
- **Validate against design system using loaded skill patterns:**
  - Check font sizes (must be 4 max)
  - Check font weights (must be 2 max)
  - Validate 8pt grid spacing
  - Check color usage (60/30/10 rule)
  - Validate OKLCH color format
  - Auto-fix violations if detected
- List component location for user reference

Phase 6: Usage Instructions
Goal: Show user how to use the new component

Actions:
- Display component file path
- Show import statement example
- Provide basic usage example
- Suggest next steps:
  - Add to Storybook if using
  - Create tests
  - Add to component library documentation
  - Integrate into pages/layouts
