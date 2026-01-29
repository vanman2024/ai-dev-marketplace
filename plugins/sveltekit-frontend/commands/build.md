---
description: Build complete SvelteKit frontend application for new or existing projects with components, routing, and integrations
argument-hint: [project-name] [--existing]
---

# Build SvelteKit Frontend

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(app-shell-agent) Analyze project for SvelteKit setup.

Detect: Existing project, TypeScript, styling
Check: package.json, existing routes
Output: Setup strategy
```

---

## Phase 2: Project Scaffold

**Goal:** Set up SvelteKit application

**Actions:**

```
Task(app-shell-agent) Create SvelteKit scaffold.

Requirements:
- Initialize SvelteKit project
- Configure TypeScript
- Set up Tailwind CSS
- Create folder structure
- Add base configuration
```

---

## Phase 3: Routing

**Goal:** Set up routing structure

**Actions:**

```
Task(routing-wiring-agent) Configure routing.

Requirements:
- Create route structure
- Set up layouts
- Add load functions
- Configure hooks
- Add error handling
```

---

## Phase 4: Components

**Goal:** Create component library

**Actions:**

```
Task(component-builder-agent) Create components.

Requirements:
- Set up component structure
- Create base components
- Add props/slots patterns
- Configure styling
- Create layout components
```

---

## Phase 5: Pages

**Goal:** Create page templates

**Actions:**

```
Task(page-generator-agent) Generate pages.

Requirements:
- Create main pages
- Add page templates
- Set up load functions
- Configure SEO
- Add transitions
```

---

## Phase 6: Design System

**Goal:** Enforce design patterns

**Actions:**

```
Task(design-enforcer-agent) Set up design system.

Requirements:
- Configure design tokens
- Set up theming
- Add consistent styling
- Create documentation
```

---

## Summary

**Output:**

```
✅ SvelteKit Frontend Complete

To add features:
  /sveltekit-frontend:add page <name>       # Add page
  /sveltekit-frontend:add component <name>  # Add component
  /sveltekit-frontend:add layout <name>     # Add layout
  /sveltekit-frontend:add api <name>        # Add API route
  /sveltekit-frontend:add migrate           # HTML migration

To run:
  npm run dev
```
