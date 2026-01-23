# SvelteKit Frontend Plugin

SvelteKit frontend development with **Tailwind CSS v4**, **shadcn-svelte**, and **Bun server** integration. Mirrors the `nextjs-frontend` plugin for consistent cross-framework development.

## Overview

This plugin enforces:
- **Design System** - 4 font sizes, 2 weights, 8pt grid, 60/30/10 colors, OKLCH
- **shadcn-svelte Components** - Pre-built accessible UI components
- **Bun Server Patterns** - Routing, WebSocket, stores integration
- **Consistent Standards** - Same rules as Next.js projects

## Documentation Links

| Resource | URL |
|----------|-----|
| Bun Docs | https://bun.com/docs |
| Bun + SvelteKit | https://bun.com/docs/guides/ecosystem/sveltekit |
| shadcn-svelte | https://www.shadcn-svelte.com |
| Tailwind CSS | https://tailwindcss.com/docs |

## Skills

### 1. design-system-enforcement

**MANDATORY** - Agents MUST read before generating any UI code.

**Enforces:**
- Typography: `text-3xl`, `text-2xl`, `text-base`, `text-sm` ONLY
- Weights: `font-semibold`, `font-normal` ONLY
- Spacing: 8pt grid (`p-2`, `p-4`, `p-6`, `gap-4`, etc.)
- Colors: Semantic only (`bg-background`, `text-foreground`, `bg-primary`)
- Components: shadcn-svelte from `$lib/components/ui/`

### 2. bun-sveltekit-patterns

**Reference** for routing, stores, and backend integration.

**Covers:**
- SvelteKit route structure (`+page.svelte`, `+layout.svelte`)
- Svelte store patterns (writable, derived)
- WebSocket integration
- Bun server route handlers
- API client patterns

## Quick Reference

### Typography (4 sizes ONLY)

```svelte
<h1 class="text-3xl font-semibold">Page Title</h1>
<h2 class="text-2xl font-semibold">Section</h2>
<p class="text-base">Body text</p>
<span class="text-sm text-muted-foreground">Label</span>
```

### Spacing (8pt grid)

```svelte
<div class="p-4 m-2 gap-4">  <!-- 16px, 8px, 16px -->
<div class="p-6 gap-2">       <!-- 24px, 8px -->
```

### Colors (semantic ONLY)

```svelte
<!-- ✅ Correct -->
<div class="bg-background text-foreground">
<div class="bg-card border-border">
<Button variant="primary">CTA</Button>

<!-- ❌ Wrong -->
<div class="bg-blue-500 text-gray-700">
```

### Components

```svelte
<script>
  import { Button } from "$lib/components/ui/button";
  import * as Card from "$lib/components/ui/card";
  import { Badge } from "$lib/components/ui/badge";
  import { Input } from "$lib/components/ui/input";
</script>

<Card.Root>
  <Card.Header>
    <Card.Title>Title</Card.Title>
  </Card.Header>
  <Card.Content>
    Content
  </Card.Content>
  <Card.Footer class="flex gap-2">
    <Button variant="outline">Cancel</Button>
    <Button>Save</Button>
  </Card.Footer>
</Card.Root>
```

## Route Structure

```
src/routes/
├── +layout.svelte      # Global nav
├── +page.svelte        # Home (/)
├── worktrees/+page.svelte
├── tasks/+page.svelte
├── sprint/+page.svelte
├── health/+page.svelte
├── reports/+page.svelte
├── docs/+page.svelte
├── testing/+page.svelte
└── overview/+page.svelte
```

## Store Pattern

```typescript
// src/lib/stores/example.ts
import { writable } from 'svelte/store';

interface State {
  items: Item[];
  loading: boolean;
  error: string | null;
}

function createStore() {
  const { subscribe, update } = writable<State>({
    items: [],
    loading: true,
    error: null
  });

  return {
    subscribe,
    async load() {
      update(s => ({ ...s, loading: true }));
      const res = await fetch('/api/items');
      const data = await res.json();
      update(s => ({ ...s, items: data, loading: false }));
    }
  };
}

export const store = createStore();
```

## Cross-Framework Consistency

| Rule | Next.js Plugin | SvelteKit Plugin |
|------|----------------|------------------|
| Typography | 4 sizes, 2 weights | 4 sizes, 2 weights |
| Spacing | 8pt grid | 8pt grid |
| Colors | OKLCH, 60/30/10 | OKLCH, 60/30/10 |
| Components | shadcn/ui | shadcn-svelte |
| CSS | Tailwind v4 | Tailwind v4 |
| Backend | FastAPI | Bun Server |

**Same design rules, different frameworks.**

## Commands

| Command | Description |
|---------|-------------|
| `/sveltekit-frontend:init-design-system` | Initialize design system |
| `/sveltekit-frontend:enforce-design-system` | Validate components |
| `/sveltekit-frontend:add-component` | Add shadcn-svelte component |
| `/sveltekit-frontend:add-page` | Create new route page |

## License

MIT
