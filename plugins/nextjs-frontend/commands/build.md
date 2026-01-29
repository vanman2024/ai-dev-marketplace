---
description: Build complete Next.js frontend application for new or existing projects with App Router, components, API routes, and integrations
argument-hint: [project-name] [--existing]
---

# Build Next.js Frontend

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(nextjs-setup-agent) Analyze project for Next.js setup.

Detect: Existing project, TypeScript, styling
Check: package.json, existing pages/app
Output: Setup strategy
```

---

## Phase 2: Project Scaffold

**Goal:** Set up Next.js application

**Actions:**

```
Task(app-scaffolding-agent) Create Next.js scaffold.

Requirements:
- Initialize Next.js with App Router
- Configure TypeScript
- Set up Tailwind CSS
- Create folder structure
- Add base configuration
```

---

## Phase 3: Design System

**Goal:** Set up UI components

**Actions:**

```
Task(component-builder-agent) Create component library.

Requirements:
- Install shadcn/ui
- Set up design tokens
- Create base components
- Configure theming
- Add layout components
```

---

## Phase 4: Page Structure

**Goal:** Create page layouts

**Actions:**

```
Task(page-generator-agent) Create page structure.

Requirements:
- Create root layout
- Add main pages (home, about)
- Set up route groups
- Configure metadata
- Add loading/error states
```

---

## Phase 5: API Routes

**Goal:** Set up API layer

**Actions:**

```
Task(api-route-generator-agent) Create API routes.

Requirements:
- Create API route structure
- Set up route handlers
- Add request validation
- Configure error handling
- Add middleware
```

---

## Phase 6: Database Integration

**Goal:** Connect to database

**Actions:**

```
Task(supabase-integration-agent) Set up database.

Requirements:
- Configure Supabase client
- Set up server/client instances
- Add database types
- Create data access patterns
```

---

## Phase 7: AI Integration

**Goal:** Add AI features

**Actions:**

```
Task(ai-sdk-integration-agent) Set up AI features.

Requirements:
- Install Vercel AI SDK
- Configure AI routes
- Add streaming support
- Create chat components
```

---

## Summary

**Output:**

```
✅ Next.js Frontend Complete

To add features:
  /nextjs-frontend:add page <name>        # Add page
  /nextjs-frontend:add component <name>   # Add component
  /nextjs-frontend:add api <name>         # Add API route
  /nextjs-frontend:add auth               # Add auth
  /nextjs-frontend:add ai                 # Add AI features

To run:
  npm run dev
```
