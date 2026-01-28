---
description: Build complete Next.js application - initializes project if needed, then runs all specialized agents in parallel for scaffolding, pages, components, integrations, and optimization
argument-hint: <project-name> [--from-spec <spec-path>]
---

# Build Complete Next.js Application

**Goal:** Create a production-ready Next.js application by orchestrating all specialized agents in parallel.

**This command handles everything** - from initialization to full build. If no project exists, it creates one. If a project exists, it enhances it.

## Stack (Always Use Latest Versions)

- **Next.js** - Latest App Router with React Server Components
- **React** - Latest with Server Components, Actions, use() hook
- **TypeScript** - Latest with strict mode
- **Tailwind CSS** - Latest (native CSS, OKLCH colors)
- **shadcn/ui** - Latest component library
- **Supabase** - Latest for auth, database, realtime
- **Vercel AI SDK** - Latest for multi-modal AI, streaming

**IMPORTANT:** Always check for and use the most recent stable versions of all dependencies. Use `npm info <package> version` or check official documentation for current versions.

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
Task("Initialize Next.js project", @nextjs-setup-agent, {
  prompt: "Initialize Next.js project named '$PROJECT_NAME' with:
    - TypeScript strict mode (latest version)
    - Tailwind CSS (latest, native CSS)
    - React App Router architecture
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
    - Use shadcn/ui, TypeScript, Tailwind CSS v4
    - Follow design system enforcement"
})

// Agent 3: Page Generator
Task("Generate all pages", @page-generator-agent, {
  prompt: "Generate ALL pages from architecture docs in parallel:
    - Discover docs/architecture/**/frontend.md
    - Extract complete page/route list
    - Create all pages concurrently
    - Follow React 19 App Router conventions
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

// Agent 5: Supabase Integration
Task("Integrate Supabase", @supabase-integration-agent, {
  prompt: "Integrate Supabase for database and auth:
    - Setup @supabase/supabase-js v2.x client
    - Create database types from schema
    - Add auth with @supabase/ssr
    - Setup Row Level Security patterns
    - Create server/client utility files"
})

// Agent 6: AI SDK Integration
Task("Integrate Vercel AI SDK", @ai-sdk-integration-agent, {
  prompt: "Integrate Vercel AI SDK 4.x:
    - Setup ai package with providers
    - Create streaming chat components
    - Add API routes for AI endpoints
    - Support multi-modal (text, image, audio)"
})

// Agent 7: Design Patterns Analysis
Task("Analyze design patterns", @design-patterns-agent, {
  prompt: "Analyze architecture for UI patterns:
    - Review component requirements
    - Suggest shadcn/ui component matches
    - Identify custom component needs
    - Recommend layout patterns"
})

// Agent 8: UI Component Search
Task("Search UI components", @ui-search-agent, {
  prompt: "Search shadcn/ui registry for needed components:
    - Find matching components for requirements
    - Check component dependencies
    - Identify installation commands
    - Note customization needs"
})
```

### Phase 4: Design System Verification

**After all agents complete, verify design system compliance:**

```
Task("Verify design system", @design-enforcer-agent, {
  prompt: "Audit all generated components and pages:
    - Check typography (4 sizes, 2 weights)
    - Verify spacing (8pt grid)
    - Validate colors (60/30/10 rule, OKLCH)
    - Ensure shadcn/ui usage
    - Check Tailwind v4 syntax
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

| Agent                         | Responsibility                     |
| ----------------------------- | ---------------------------------- |
| `@nextjs-setup-agent`         | Project init, TypeScript, Tailwind |
| `@app-scaffolding-agent`      | Layouts, navigation, sidebars      |
| `@component-builder-agent`    | All React components in parallel   |
| `@page-generator-agent`       | All pages/routes in parallel       |
| `@api-route-generator-agent`  | API route handlers                 |
| `@supabase-integration-agent` | Database, auth, realtime           |
| `@ai-sdk-integration-agent`   | AI SDK, multi-modal                |
| `@design-enforcer-agent`      | Design system validation           |
| `@design-patterns-agent`      | UI pattern recommendations         |
| `@ui-search-agent`            | Component discovery                |

## Skills Auto-Loaded

These skills provide context during development:

- **design-system**: Project design tokens and constraints
- **component-patterns**: Existing component patterns in project
- **page-patterns**: App Router page conventions
- **api-route-patterns**: API route conventions

## Output

Upon completion:

1. ✅ Working Next.js application (latest)
2. ✅ All pages and components from architecture
3. ✅ API routes configured
4. ✅ Integrations (Supabase, AI SDK) if needed
5. ✅ Design system compliant
6. ✅ TypeScript passing
7. ✅ Ready to run with `npm run dev`
