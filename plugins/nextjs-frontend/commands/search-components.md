---
description: Search and add shadcn/ui components from component library
argument-hint: <search-query>
allowed-tools: Task, Read, Write, Bash, Glob, Grep, WebFetch, AskUserQuestion, mcp__context7, mcp__shadcn, mcp__figma-application, Skill
---
## Available Skills

This commands has access to the following skills from the nextjs-frontend plugin:

- **deployment-config**: Vercel deployment configuration and optimization for Next.js applications including vercel.json setup, environment variables, build optimization, edge functions, and deployment troubleshooting. Use when deploying to Vercel, configuring deployment settings, optimizing build performance, setting up environment variables, configuring edge functions, or when user mentions Vercel deployment, production setup, build errors, or deployment optimization.\n- **design-system-enforcement**: Mandatory design system guidelines for shadcn/ui with Tailwind v4. Enforces 4 font sizes, 2 weights, 8pt grid spacing, 60/30/10 color rule, OKLCH colors, and accessibility standards. Use when creating components, pages, or any UI elements. ALL agents MUST read and validate against design system before generating code.\n- **tailwind-shadcn-setup**: Setup Tailwind CSS and shadcn/ui component library for Next.js projects. Use when configuring Tailwind CSS, installing shadcn/ui, setting up design tokens, configuring dark mode, initializing component library, or when user mentions Tailwind setup, shadcn/ui installation, component system, design system, or theming.\n
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

Goal: Search shadcn/ui component library, display matching components, and add selected components to the project with configuration and usage examples.

Core Principles:

- Search before adding components
- Display component details and variants
- Ask user to confirm selection
- Provide usage examples after installation

Phase 1: Discovery

Goal: Parse search query and validate project environment

Actions:

Parse $ARGUMENTS for search query. If empty, ask user what component they're looking for.

Verify this is a Next.js project with shadcn/ui:
!{bash test -f components.json && echo "shadcn/ui detected" || echo "shadcn/ui not initialized"}

If components.json not found, suggest running initialization first.

Phase 2: Component Search

Goal: Search shadcn/ui component library and display results

Actions:

Task(description="Search shadcn/ui components", subagent_type="nextjs-frontend:ui-search-agent", prompt="You are the ui-search-agent. Search for shadcn/ui components matching '$ARGUMENTS'.

Search scope:

- Official shadcn/ui component registry
- Component categories: forms, layout, data-display, feedback, navigation
- Search by: name, description, use-case, keywords

For each matching component, provide:

1. Component name
2. Description (1-2 sentences)
3. Category
4. Dependencies (other components required)
5. Variants available
6. Common use cases
7. Installation command

Documentation to fetch:

- shadcn/ui component registry
- Component documentation pages
- Installation guides

Deliverable: Formatted list of matching components with details")

Wait for agent to complete.

Phase 3: Component Selection

Goal: Let user choose which component to add

Actions:

Display search results in organized format.

Use AskUserQuestion to ask:

- Which component would you like to add? (provide component name)
- Which variants/features do you want? (if applicable)
- Any customization preferences? (color scheme, size defaults)

Parse user selection and validate it exists in search results.

Phase 4: Installation

Goal: Add selected component to the project

Actions:

Install component using shadcn/ui CLI:
!{bash npx shadcn@latest add $COMPONENT_NAME -y}

Verify installation:
!{bash test -f components/ui/$COMPONENT_NAME.tsx && echo "Component installed" || echo "Installation failed"}

Read installed component to understand structure:
@components/ui/$COMPONENT_NAME.tsx

Phase 5: Usage Examples

Goal: Provide code examples showing how to use the component

Actions:

Display usage information:

- Import statement
- Basic usage example
- Props reference
- Common patterns
- Integration tips

Show where component is installed:

- File path: components/ui/$COMPONENT_NAME.tsx
- Dependencies installed (if any)

Suggest next steps:

- Create example page using the component
- Customize component styling
- Explore component variants

Phase 6: Summary

Goal: Confirm successful installation and provide guidance

Actions:

Summary:

- Component added: $COMPONENT_NAME
- Location: components/ui/$COMPONENT_NAME.tsx
- Dependencies: [list any additional components installed]
- Ready to import and use in your app

Quick start example:

- Import: from "@/components/ui/component-name"
- Usage: Add component to your page/component JSX
- Props: Check component file for available props

Additional resources:

- Official docs: https://ui.shadcn.com/docs/components/$COMPONENT_NAME
- Browse more: /nextjs-frontend:search-components <query>
- Add pages: /nextjs-frontend:add-page <name>
