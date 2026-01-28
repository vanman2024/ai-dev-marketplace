---
description: Build complete Next.js 15 application - runs all specialized agents in parallel for setup, scaffolding, pages, components, integrations, and optimization
argument-hint: <project-name> [--from-spec <spec-path>]
---

# Build Complete Next.js Application

**Goal:** Create a production-ready Next.js 15 application by orchestrating all specialized agents in parallel.

## Arguments

- `$ARGUMENTS` - Project name and optional spec path
- `--from-spec <path>` - Build from architecture specification

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**
1. Parse `$ARGUMENTS` for project name and spec path
2. Check if project exists or needs creation
3. Discover architecture documentation:
   ```
   !{glob docs/architecture/**/*.md}
   !{glob specs/*/spec.md}
   ```
4. Create execution plan based on what's found

### Phase 2: Project Initialization (if needed)

**If no project exists, run setup agent:**

```
Task("Initialize Next.js 15 project", @nextjs-setup-agent, {
  prompt: "Initialize Next.js 15 project named '$PROJECT_NAME' with:
    - TypeScript strict mode
    - Tailwind CSS v4
    - App Router architecture
    - shadcn/ui component library
    - Environment variable templates
    Create proper project structure and configuration."
})
```

**Wait for setup to complete before proceeding.**

### Phase 3: Parallel Agent Execution

**Launch ALL specialized agents simultaneously using Task():**

```
// Agent 1: Application Scaffolding
Task("Build app scaffold", @app-scaffolding-agent, {
  prompt: "Build complete application scaffold with:
    - Sidebar navigation from architecture docs
    - Header with user menu and theme toggle
    - Footer with links
    - Dashboard layout (app/(dashboard)/layout.tsx)
    Use shadcn application blocks, follow design system."
})

// Agent 2: Component Builder
Task("Build all components", @component-builder-agent, {
  prompt: "Build ALL components from architecture docs in parallel:
    - Discover docs/architecture/**/frontend.md
    - Extract complete component list
    - Create all components concurrently
    - Use shadcn/ui, TypeScript, Tailwind CSS
    - Follow design system enforcement"
})

// Agent 3: Page Generator
Task("Generate all pages", @page-generator-agent, {
  prompt: "Generate ALL pages from architecture docs in parallel:
    - Discover docs/architecture/**/frontend.md
    - Extract complete page/route list
    - Create all pages concurrently
    - Follow App Router conventions
    - Import generated components"
})

// Agent 4: API Route Generator
Task("Generate API routes", @api-route-generator-agent, {
  prompt: "Generate ALL API routes from architecture docs:
    - Discover docs/architecture/**/api.md or backend.md
    - Create route handlers in app/api/
    - Include proper error handling
    - Add TypeScript types"
})

// Agent 5: Supabase Integration (if needed)
Task("Integrate Supabase", @supabase-integration-agent, {
  prompt: "Integrate Supabase if architecture requires:
    - Check for database requirements in specs
    - Setup Supabase client
    - Create database types
    - Add auth if needed"
})

// Agent 6: AI SDK Integration (if needed)
Task("Integrate Vercel AI SDK", @ai-sdk-integration-agent, {
  prompt: "Integrate Vercel AI SDK if architecture requires:
    - Check for AI/chat requirements in specs
    - Setup AI providers
    - Create streaming chat components
    - Add API routes for AI"
})
```

### Phase 4: Design System Verification

**After all agents complete, verify design system compliance:**

```
Task("Verify design system", @design-enforcer-agent, {
  prompt: "Audit all generated components and pages:
    - Check typography (4 sizes, 2 weights)
    - Verify spacing (8pt grid)
    - Validate colors (60/30/10 rule)
    - Ensure shadcn/ui usage
    Report any violations"
})
```

### Phase 5: Final Validation

**Validation Steps:**
1. Run TypeScript check: `npx tsc --noEmit`
2. Run lint check: `npm run lint`
3. Verify build: `npm run build`
4. Generate summary of created files

## Specialized Agents

| Agent | Responsibility |
|-------|----------------|
| `@nextjs-setup-agent` | Project init, TypeScript, Tailwind, shadcn |
| `@app-scaffolding-agent` | Layouts, navigation, sidebars |
| `@component-builder-agent` | All React components in parallel |
| `@page-generator-agent` | All pages/routes in parallel |
| `@api-route-generator-agent` | API route handlers |
| `@supabase-integration-agent` | Database and auth integration |
| `@ai-sdk-integration-agent` | AI/chat features |
| `@design-enforcer-agent` | Design system validation |
| `@design-patterns-agent` | UI pattern recommendations |
| `@ui-search-agent` | Component discovery |

## Skills Auto-Loaded

These skills provide context during development:
- **design-system**: Project design tokens and constraints
- **component-patterns**: Existing component patterns in project
- **page-patterns**: App Router page conventions
- **api-route-patterns**: API route conventions

## Output

Upon completion:
1. ✅ Working Next.js 15 application
2. ✅ All pages and components from architecture
3. ✅ API routes configured
4. ✅ Integrations (Supabase, AI SDK) if needed
5. ✅ Design system compliant
6. ✅ TypeScript passing
7. ✅ Ready to run with `npm run dev`
