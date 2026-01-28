---
description: Build complete SvelteKit application - initializes if needed, then runs specialized agents for app shell, components, pages, routing, and design enforcement
argument-hint: <project-name> [--from-spec <spec-path>]
---

# Build Complete SvelteKit Application

**Goal:** Create a production-ready SvelteKit application by orchestrating all specialized agents.

**This command handles everything** - from initialization to full app with components, pages, routing, and backend integration.

## Stack (Always Use Latest Versions)

- **SvelteKit** - Latest with Svelte 5
- **Tailwind CSS** - Latest
- **shadcn-svelte** - Latest component library
- **Bun** - Latest runtime and package manager

**IMPORTANT:** Always use the latest versions. Check npm for current versions.

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

```
Task("Initialize SvelteKit project", @app-shell-agent, {
  prompt: "Initialize SvelteKit project:
    - Create SvelteKit project with Bun
    - Configure TypeScript
    - Set up Tailwind CSS
    - Install shadcn-svelte
    - Create +layout.svelte with navigation
    Set up complete project scaffold."
})
```

**Wait for setup to complete before proceeding.**

### Phase 3: Parallel Agent Execution

```
// Agent 1: Component Building
Task("Build all components", @component-builder-agent, {
  prompt: "Build ALL components from architecture docs:
    - Discover docs/architecture/**/frontend.md
    - Extract complete component list
    - Create using shadcn-svelte patterns
    - Build all components concurrently
    Follow design system from architecture."
})

// Agent 2: Page Generation
Task("Generate all pages", @page-generator-agent, {
  prompt: "Generate ALL pages from architecture docs:
    - Create +page.svelte files for each route
    - Implement load functions for data
    - Add form actions where needed
    - Follow SvelteKit conventions
    Build pages concurrently."
})

// Agent 3: Routing & Backend Wiring
Task("Wire up routing", @routing-wiring-agent, {
  prompt: "Configure routing and API integration:
    - Set up route groups
    - Configure API routes in +server.ts
    - Wire frontend to Bun backend
    - Add authentication guards
    Follow API spec from architecture."
})

// Agent 4: Design Enforcement
Task("Enforce design system", @design-enforcer-agent, {
  prompt: "Validate design system compliance:
    - Check component styling
    - Verify Tailwind usage
    - Validate accessibility
    - Ensure consistent patterns
    Report any design violations."
})
```

### Phase 4: Migration Support (if applicable)

```
Task("Migrate HTML if needed", @html-to-svelte-migration-agent, {
  prompt: "If HTML prototypes exist, migrate them:
    - Convert HTML to Svelte components
    - Wire up event handlers
    - Add reactivity
    - Connect to data sources
    Skip if no HTML templates."
})
```

### Phase 5: Final Output

**Provide summary:**
- List all created files
- Show project structure
- Provide run commands:
  ```bash
  # Development
  bun run dev
  
  # Build
  bun run build
  
  # Preview
  bun run preview
  ```
- Note any manual steps needed

## Utility Commands

- `/sveltekit-frontend:create-page` - Add single page
- `/sveltekit-frontend:create-component` - Add single component
- `/sveltekit-frontend:add-routing` - Configure routing
- `/sveltekit-frontend:migrate-html` - Convert HTML to Svelte
