---
description: Initialize Next.js 15 App Router project with AI SDK, Supabase, and shadcn/ui
argument-hint: <project-name>
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite, mcp__context7, Skill
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

Goal: Create a production-ready Next.js 15 application with App Router, TypeScript, Tailwind CSS, shadcn/ui, Vercel AI SDK, and Supabase integration.

Core Principles:
- Detect project requirements before creating
- Ask clarifying questions for configuration
- Use official templates and best practices
- Validate setup after creation

Phase 1: Requirements Gathering

Goal: Understand project requirements and configuration preferences

Actions:

Parse $ARGUMENTS for project name. If not provided, ask user.

Use AskUserQuestion to gather:
- AI providers to integrate (Anthropic, OpenAI, Google, or all)
- Authentication needed (yes/no)
- Database features (basic CRUD, real-time, vector search)
- UI component preferences (minimal, standard, comprehensive)

Phase 2: Project Setup

Goal: Invoke nextjs-setup-agent to create project structure

Actions:

Task(description="Setup Next.js 15 project", subagent_type="nextjs-frontend:nextjs-setup-agent", prompt="You are the nextjs-setup-agent. Initialize a Next.js 15 App Router project for $ARGUMENTS.

Requirements:
- Project name: $PROJECT_NAME
- Framework: Next.js 15 with App Router
- Language: TypeScript with strict mode
- Styling: Tailwind CSS
- UI Components: shadcn/ui
- AI Providers: $AI_PROVIDERS
- Database: Supabase
- Authentication: $AUTH_ENABLED

Tasks:
1. Create Next.js 15 project with create-next-app
2. Configure TypeScript with strict settings
3. Setup Tailwind CSS with custom configuration
4. Initialize shadcn/ui component library
5. Install Vercel AI SDK and configure providers
6. Setup Supabase client and environment variables
7. Create basic project structure (app/, components/, lib/)
8. Generate example API route with AI streaming
9. Create example page with chat interface

Documentation sources to fetch:
- Next.js 15 App Router setup
- Vercel AI SDK integration
- Supabase client configuration
- shadcn/ui installation

Deliverable: Complete working Next.js project ready for development")

Wait for agent to complete.

Phase 3: Validation

Goal: Verify the project was created successfully

Actions:

Check project directory exists:
!{bash test -d "$PROJECT_NAME" && echo "✅ Project created" || echo "❌ Project not found"}

Verify key files:
!{bash ls $PROJECT_NAME/package.json $PROJECT_NAME/tsconfig.json $PROJECT_NAME/tailwind.config.ts $PROJECT_NAME/.env.local 2>/dev/null | wc -l}

Run type checking:
!{bash cd $PROJECT_NAME && npm run build}

Phase 4: Summary

Goal: Provide next steps and usage instructions

Actions:

Display summary:
- Project created at: ./$PROJECT_NAME
- Framework: Next.js 15 App Router
- Features enabled: TypeScript, Tailwind, shadcn/ui, AI SDK, Supabase
- Environment variables configured in .env.local

Next steps:
1. cd $PROJECT_NAME
2. Update .env.local with your API keys
3. npm run dev
4. Visit http://localhost:3000

Additional commands:
- /nextjs-frontend:add-page <page-name> - Add new pages
- /nextjs-frontend:add-component <name> - Add components
- /nextjs-frontend:integrate-ai-sdk - Add more AI features
- /nextjs-frontend:search-components - Browse shadcn/ui components
