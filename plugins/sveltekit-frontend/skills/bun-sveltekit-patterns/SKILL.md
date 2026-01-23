---
name: bun-sveltekit-patterns
description: SvelteKit + Bun server patterns for routing, data loading, stores, and WebSocket integration. Reference this for consistent frontend-backend wiring. Includes Bun documentation links.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, WebFetch
---

# SvelteKit + Bun Server Patterns

**Purpose:** Ensure consistent routing, data loading, and component patterns when building SvelteKit frontends with Bun servers.

## Documentation References

### Bun Core Docs
- [Bun Runtime](https://bun.com/docs)
- [HTTP Server](https://bun.com/docs/runtime/http/server)
- [Routing](https://bun.com/docs/runtime/http/routing)
- [WebSockets](https://bun.com/docs/runtime/http/websockets)
- [File I/O](https://bun.com/docs/runtime/file-io)

### SvelteKit + Bun
- [Build an app with SvelteKit and Bun](https://bun.com/docs/guides/ecosystem/sveltekit)
- [Test Svelte components with bun test](https://bun.com/docs/guides/test/svelte-test)

### Testing
- [Bun Test Runner](https://bun.com/docs/test)
- [DOM Testing](https://bun.com/docs/test/dom)
- [Testing Library with Bun](https://bun.com/docs/guides/test/testing-library)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (SvelteKit)                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Routes    │  │   Stores    │  │      Components         │  │
│  │  +page.svelte  │  projects.ts │  │  $lib/components/ui/    │  │
│  │  +layout.svelte│  roadmap.ts  │  │  Button, Card, Badge... │  │
│  └──────┬──────┘  └──────┬──────┘  └─────────────────────────┘  │
│         │                │                                       │
│         │    fetch()     │    Svelte stores                     │
│         ▼                ▼                                       │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ HTTP + WebSocket
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     BACKEND (Bun Server)                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │   Routes    │  │  Services   │  │        Stores           │  │
│  │ routes/     │  │ services/   │  │  sessionStore.ts        │  │
│  │ roadmap.ts  │  │ dataLoader  │  │  cacheStore.ts          │  │
│  │ worktrees.ts│  │ gitOps      │  │  branchStore.ts         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## SvelteKit Route Patterns

### Directory Structure

```
src/routes/
├── +layout.svelte      # Global layout with nav
├── +page.svelte        # Home page (/)
├── worktrees/
│   └── +page.svelte    # /worktrees
├── tasks/
│   └── +page.svelte    # /tasks
├── sprint/
│   └── +page.svelte    # /sprint
├── health/
│   └── +page.svelte    # /health
├── reports/
│   └── +page.svelte    # /reports
├── docs/
│   └── +page.svelte    # /docs
├── testing/
│   └── +page.svelte    # /testing
└── overview/
    └── +page.svelte    # /overview
```

### Standard Page Template

```svelte
<!-- src/routes/[route]/+page.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { storeNameHere } from '$lib/stores/storeNameHere';
  import * as Card from '$lib/components/ui/card';
  import { Button } from '$lib/components/ui/button';

  // Load data on mount
  onMount(() => {
    storeNameHere.load();
  });
</script>

<div class="container mx-auto px-4 py-8">
  <header class="mb-6">
    <h1 class="text-3xl font-semibold">Page Title</h1>
    <p class="text-sm text-muted-foreground mt-2">
      Page description here
    </p>
  </header>

  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {#each $storeNameHere.items as item (item.id)}
      <Card.Root>
        <Card.Header>
          <Card.Title class="text-base font-semibold">{item.name}</Card.Title>
        </Card.Header>
        <Card.Content>
          <p class="text-sm text-muted-foreground">{item.description}</p>
        </Card.Content>
      </Card.Root>
    {/each}
  </div>
</div>
```

### Layout with Navigation

```svelte
<!-- src/routes/+layout.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import '../app.css';

  const navItems = [
    { path: '/', label: 'Roadmap' },
    { path: '/worktrees', label: 'Worktrees' },
    { path: '/tasks', label: 'Tasks' },
    { path: '/sprint', label: 'Sprint' },
    { path: '/health', label: 'Health' },
    { path: '/reports', label: 'Reports' },
    { path: '/docs', label: 'Docs' },
    { path: '/testing', label: 'Testing' },
    { path: '/overview', label: 'Overview' }
  ];
</script>

<nav class="bg-card border-b border-border sticky top-0 z-50">
  <div class="container mx-auto px-4 flex items-center justify-between h-16">
    <a href="/" class="text-2xl font-semibold">Dashboard</a>
    <div class="flex gap-2">
      {#each navItems as item}
        <a
          href={item.path}
          class="px-4 py-2 text-sm rounded-md transition-colors
                 {$page.url.pathname === item.path
                   ? 'bg-primary text-primary-foreground'
                   : 'text-muted-foreground hover:bg-muted'}"
        >
          {item.label}
        </a>
      {/each}
    </div>
  </div>
</nav>

<main>
  <slot />
</main>
```

---

## Svelte Store Patterns

### Standard Store Structure

```typescript
// src/lib/stores/roadmap.ts
import { writable, derived } from 'svelte/store';
import type { Feature, Infrastructure } from '$lib/api/types';

interface RoadmapState {
  features: Feature[];
  infrastructure: Infrastructure[];
  loading: boolean;
  error: string | null;
}

function createRoadmapStore() {
  const { subscribe, set, update } = writable<RoadmapState>({
    features: [],
    infrastructure: [],
    loading: true,
    error: null
  });

  return {
    subscribe,

    async load() {
      update(s => ({ ...s, loading: true, error: null }));
      try {
        const res = await fetch('/api/roadmap');
        if (!res.ok) throw new Error('Failed to load roadmap');
        const data = await res.json();
        update(s => ({
          ...s,
          features: data.features,
          infrastructure: data.infrastructure,
          loading: false
        }));
      } catch (err: any) {
        update(s => ({ ...s, error: err.message, loading: false }));
      }
    },

    updateItem(item: Feature | Infrastructure) {
      update(s => {
        if (item.id.startsWith('F')) {
          const idx = s.features.findIndex(f => f.id === item.id);
          if (idx >= 0) s.features[idx] = item as Feature;
        } else if (item.id.startsWith('I')) {
          const idx = s.infrastructure.findIndex(i => i.id === item.id);
          if (idx >= 0) s.infrastructure[idx] = item as Infrastructure;
        }
        return { ...s };
      });
    }
  };
}

export const roadmap = createRoadmapStore();

// Derived stores for filtering
export const filteredFeatures = derived(
  roadmap,
  $roadmap => (status: string, phase: string) => {
    let items = $roadmap.features;
    if (status !== 'all') items = items.filter(f => f.status === status);
    if (phase !== 'all') items = items.filter(f => f.phase === parseInt(phase));
    return items;
  }
);
```

### WebSocket Store

```typescript
// src/lib/stores/websocket.ts
import { writable } from 'svelte/store';
import { roadmap } from './roadmap';
import { worktrees } from './worktrees';

interface WSState {
  connected: boolean;
  reconnecting: boolean;
}

function createWebSocketStore() {
  const { subscribe, update } = writable<WSState>({
    connected: false,
    reconnecting: false
  });

  let ws: WebSocket | null = null;
  let reconnectTimer: ReturnType<typeof setTimeout> | null = null;

  function connect() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${window.location.host}`);

    ws.onopen = () => {
      update(s => ({ ...s, connected: true, reconnecting: false }));
    };

    ws.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data);
        handleMessage(message);
      } catch (e) {
        console.error('[WS] Parse error:', e);
      }
    };

    ws.onclose = () => {
      update(s => ({ ...s, connected: false, reconnecting: true }));
      reconnectTimer = setTimeout(connect, 3000);
    };
  }

  function handleMessage(message: any) {
    switch (message.type) {
      case 'roadmap:updated':
        roadmap.updateItem(message.data);
        break;
      case 'worktree:updated':
        worktrees.updateWorktree(message.data);
        break;
      case 'file-change':
        // Trigger data reload
        roadmap.load();
        break;
    }
  }

  return {
    subscribe,
    connect,
    disconnect: () => {
      ws?.close();
      if (reconnectTimer) clearTimeout(reconnectTimer);
    }
  };
}

export const websocket = createWebSocketStore();
```

---

## API Client Pattern

```typescript
// src/lib/api/client.ts
const BASE_URL = '';  // Same origin

export interface ApiResponse<T> {
  data?: T;
  error?: string;
}

export async function apiGet<T>(endpoint: string): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(`${BASE_URL}${endpoint}`);
    if (!res.ok) {
      const error = await res.json();
      return { error: error.message || 'Request failed' };
    }
    return { data: await res.json() };
  } catch (err: any) {
    return { error: err.message };
  }
}

export async function apiPost<T>(endpoint: string, body: any): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const error = await res.json();
      return { error: error.message || 'Request failed' };
    }
    return { data: await res.json() };
  } catch (err: any) {
    return { error: err.message };
  }
}
```

---

## Bun Server Route Patterns

### Route Handler Structure

```typescript
// backend/routes/roadmap.ts
import { corsHeaders } from '../utils/cors';
import { dataLoader } from '../services/dataLoader';

export async function getRoadmap(req: Request): Promise<Response> {
  try {
    const data = dataLoader.load();
    return Response.json(data, { headers: corsHeaders });
  } catch (err: any) {
    return Response.json(
      { error: err.message },
      { status: 500, headers: corsHeaders }
    );
  }
}

export async function getFeature(req: Request, id: string): Promise<Response> {
  try {
    const data = dataLoader.load();
    const feature = data.features.find(f => f.id === id);
    if (!feature) {
      return Response.json(
        { error: 'Feature not found' },
        { status: 404, headers: corsHeaders }
      );
    }
    return Response.json(feature, { headers: corsHeaders });
  } catch (err: any) {
    return Response.json(
      { error: err.message },
      { status: 500, headers: corsHeaders }
    );
  }
}
```

### Route Registration

```typescript
// backend/routes/index.ts
import { getRoadmap, getFeature } from './roadmap';
import { getWorktrees, startWorktree, stopWorktree } from './worktrees';
import { getProjects, switchProject } from './projects';

type Handler = (req: Request, ...args: string[]) => Promise<Response> | Response;

interface Route {
  pattern: RegExp;
  method: string;
  handler: Handler;
}

export const routes: Route[] = [
  // Roadmap
  { pattern: /^\/api\/roadmap$/, method: 'GET', handler: getRoadmap },
  { pattern: /^\/api\/features\/(\w+)$/, method: 'GET', handler: getFeature },

  // Worktrees
  { pattern: /^\/api\/worktrees$/, method: 'GET', handler: getWorktrees },
  { pattern: /^\/api\/worktree\/start$/, method: 'POST', handler: startWorktree },
  { pattern: /^\/api\/worktree\/stop$/, method: 'POST', handler: stopWorktree },

  // Projects
  { pattern: /^\/api\/projects$/, method: 'GET', handler: getProjects },
  { pattern: /^\/api\/projects\/switch$/, method: 'POST', handler: switchProject },
];

export function matchRoute(path: string, method: string): { handler: Handler; params: string[] } | null {
  for (const route of routes) {
    if (route.method !== method) continue;
    const match = path.match(route.pattern);
    if (match) {
      return { handler: route.handler, params: match.slice(1) };
    }
  }
  return null;
}
```

### Server Entry Point

```typescript
// backend/server.ts
import { matchRoute } from './routes';
import { serveStatic } from './routes/static';
import { websocketHandler } from './websocket/handler';
import { corsHeaders } from './utils/cors';

const PORT = 8001;

Bun.serve({
  port: PORT,

  async fetch(req, server) {
    const url = new URL(req.url);
    const path = url.pathname;

    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Handle WebSocket upgrade
    if (req.headers.get('upgrade') === 'websocket') {
      const success = server.upgrade(req);
      return success ? undefined : new Response('WebSocket upgrade failed', { status: 500 });
    }

    // Match API routes
    const matched = matchRoute(path, req.method);
    if (matched) {
      return matched.handler(req, ...matched.params);
    }

    // Serve static files (SvelteKit build)
    return serveStatic(path);
  },

  websocket: websocketHandler
});

console.log(`Server running at http://localhost:${PORT}`);
```

---

## Component Standardization

### Every New Component MUST:

1. **Import from shadcn-svelte:**
   ```svelte
   <script>
     import { Button } from "$lib/components/ui/button";
     import * as Card from "$lib/components/ui/card";
     import { Badge } from "$lib/components/ui/badge";
   </script>
   ```

2. **Use 4 font sizes only:**
   - `text-3xl` (32px) - Page titles
   - `text-2xl` (24px) - Section headings
   - `text-base` (16px) - Body text
   - `text-sm` (14px) - Labels, meta

3. **Use 2 font weights only:**
   - `font-semibold` - Headings
   - `font-normal` (default) - Body

4. **Use 8pt grid spacing:**
   - `p-2`, `p-4`, `p-6`, `p-8` - Padding
   - `m-2`, `m-4`, `m-6`, `m-8` - Margin
   - `gap-2`, `gap-4`, `gap-6` - Grid/flex gaps

5. **Use semantic colors:**
   - `bg-background`, `bg-card`, `bg-muted` - Backgrounds
   - `text-foreground`, `text-muted-foreground` - Text
   - `bg-primary text-primary-foreground` - CTAs only (10%)

---

## Vite Configuration for Bun

```typescript
// vite.config.ts
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [sveltekit()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8001',
        changeOrigin: true
      }
    }
  }
});
```

---

**Framework:** SvelteKit + Bun Server
**UI:** Tailwind CSS v4 + shadcn-svelte
**Version:** 1.0.0
