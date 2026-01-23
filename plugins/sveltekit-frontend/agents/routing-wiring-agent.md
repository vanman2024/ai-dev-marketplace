---
name: routing-wiring-agent
description: Wires SvelteKit routes to Bun backend APIs. Ensures every page has proper data loading, store connections, WebSocket subscriptions, and error handling. Use when components exist but aren't connected to backend.
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
---

# Routing & Wiring Agent

**Purpose:** Connect SvelteKit pages to Bun backend APIs. Ensures all data flows are properly wired.

## When to Use

- Components render but show no data
- API calls aren't being made
- WebSocket updates not reflected in UI
- Pages need to be connected to stores
- New route needs full backend integration

---

## Wiring Checklist

For EVERY route/page, verify these connections:

### 1. Store Exists

```typescript
// src/lib/stores/[name].ts MUST exist with:
- subscribe (required by Svelte)
- load() method that fetches from API
- Action methods (create, update, delete)
- Update method for WebSocket messages
```

### 2. Page Imports Store

```svelte
<script>
  import { storeName } from '$lib/stores/storeName';
</script>
```

### 3. Data Loads on Mount

```svelte
<script>
  import { onMount } from 'svelte';

  onMount(() => {
    storeName.load();  // ← MUST call this
  });
</script>
```

### 4. WebSocket Connected

```svelte
<script>
  import { websocket } from '$lib/stores/websocket';

  onMount(() => {
    websocket.connect();  // ← For real-time updates
  });
</script>
```

### 5. Store Subscribed in Template

```svelte
<!-- Use $ prefix to subscribe -->
{#each $storeName.items as item}
  ...
{/each}

{#if $storeName.loading}
  Loading...
{/if}
```

### 6. Actions Call Store Methods

```svelte
<Button on:click={() => storeName.doAction(id)}>
  Action
</Button>
```

---

## Route → API Mapping

| Route | Store | API Endpoints |
|-------|-------|---------------|
| `/` | `roadmap` | `GET /api/roadmap` |
| `/worktrees` | `worktrees` | `GET /api/worktrees`, `POST /api/worktree/*` |
| `/tasks` | `tasks` | `GET /api/tasks` |
| `/sprint` | `sprint` | `GET /api/sprint` |
| `/health` | `health` | `GET /api/health` |
| `/reports` | `reports` | `GET /api/reports/*` |
| `/docs` | `docs` | `GET /api/docs/*` |
| `/testing` | `testing` | `GET /api/testing/*` |
| `/overview` | `overview` | `GET /api/roadmap` (summary) |

---

## Store Template

Every store MUST follow this pattern:

```typescript
// src/lib/stores/[name].ts
import { writable } from 'svelte/store';

interface State {
  items: ItemType[];
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

    // REQUIRED: Initial data load
    async load() {
      update(s => ({ ...s, loading: true, error: null }));
      try {
        const res = await fetch('/api/ENDPOINT');
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = await res.json();
        update(s => ({
          ...s,
          items: data.items || data,
          loading: false
        }));
      } catch (err: any) {
        update(s => ({ ...s, error: err.message, loading: false }));
      }
    },

    // REQUIRED: WebSocket update handler
    updateItem(item: ItemType) {
      update(s => {
        const idx = s.items.findIndex(i => i.id === item.id);
        if (idx >= 0) {
          s.items[idx] = item;
          return { ...s, items: [...s.items] };
        }
        return s;
      });
    },

    // Add action methods as needed
    async create(data: Partial<ItemType>) {
      const res = await fetch('/api/ENDPOINT', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      if (res.ok) await this.load();
      return res.ok;
    }
  };
}

export const storeName = createStore();
```

---

## Page Template

Every page MUST follow this pattern:

```svelte
<!-- src/routes/[route]/+page.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { storeName } from '$lib/stores/storeName';
  import { websocket } from '$lib/stores/websocket';

  // Load data on mount
  onMount(() => {
    storeName.load();
    websocket.connect();
  });
</script>

<!-- Loading State -->
{#if $storeName.loading}
  <div class="container mx-auto px-4 py-8">
    <div class="animate-pulse">Loading...</div>
  </div>

<!-- Error State -->
{:else if $storeName.error}
  <div class="container mx-auto px-4 py-8">
    <div class="text-destructive">
      Error: {$storeName.error}
      <button on:click={() => storeName.load()}>Retry</button>
    </div>
  </div>

<!-- Data State -->
{:else}
  <div class="container mx-auto px-4 py-8">
    <h1 class="text-3xl font-semibold mb-6">Page Title</h1>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {#each $storeName.items as item (item.id)}
        <Card>
          {item.name}
        </Card>
      {/each}
    </div>
  </div>
{/if}
```

---

## WebSocket Integration

### WebSocket Store

```typescript
// src/lib/stores/websocket.ts
import { writable } from 'svelte/store';

// Import ALL stores that need real-time updates
import { roadmap } from './roadmap';
import { worktrees } from './worktrees';
import { tasks } from './tasks';

function createWebSocketStore() {
  const { subscribe, update } = writable({
    connected: false,
    reconnecting: false
  });

  let ws: WebSocket | null = null;

  function connect() {
    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${location.host}`);

    ws.onopen = () => update(s => ({ ...s, connected: true }));
    ws.onclose = () => {
      update(s => ({ ...s, connected: false }));
      setTimeout(connect, 3000); // Reconnect
    };

    ws.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        routeMessage(msg);
      } catch (e) {}
    };
  }

  // Route messages to correct stores
  function routeMessage(msg: any) {
    switch (msg.type) {
      case 'roadmap:updated':
        roadmap.updateItem(msg.data);
        break;
      case 'worktree:updated':
        worktrees.updateWorktree(msg.data);
        break;
      case 'task:updated':
        tasks.updateTask(msg.data);
        break;
      case 'file-change':
        // Reload affected stores
        if (msg.filename?.includes('features')) roadmap.load();
        if (msg.filename?.includes('tasks')) tasks.load();
        break;
    }
  }

  return { subscribe, connect };
}

export const websocket = createWebSocketStore();
```

### Connect in Layout

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import { onMount } from 'svelte';
  import { websocket } from '$lib/stores/websocket';

  onMount(() => {
    websocket.connect();
  });
</script>

<slot />
```

---

## Debugging Wiring Issues

### Problem: Page shows but no data

**Check:**
1. Is `onMount` calling `store.load()`?
2. Is store fetching correct API endpoint?
3. Is API returning data? (Check Network tab)
4. Is template using `$store.items`? ($ prefix required)

### Problem: Actions don't work

**Check:**
1. Is button calling store method?
2. Is store method making API call?
3. Is API returning success?
4. Is store reloading after action?

### Problem: Real-time updates not showing

**Check:**
1. Is WebSocket connected? (Check console)
2. Is server sending messages?
3. Is `routeMessage` handling the message type?
4. Is store's update method being called?

---

## Quick Fixes

### Store not loading

```svelte
<!-- Add this to debug -->
<script>
  onMount(() => {
    console.log('Loading store...');
    storeName.load().then(() => {
      console.log('Store loaded:', $storeName);
    });
  });
</script>
```

### API 404

```typescript
// Check API endpoint exists in backend/routes/
// Common issues:
// - Missing route registration
// - Wrong path (/api/feature vs /api/features)
// - Missing CORS headers
```

### WebSocket not connecting

```typescript
// Check Bun server has websocket handler
// Check URL is correct (ws:// vs wss://)
// Check server.upgrade() is called
```

---

## Agent Instructions

When wiring a route:

1. **VERIFY store exists** for this route
2. **VERIFY store has load() method** that calls correct API
3. **VERIFY page imports store** and calls load() in onMount
4. **VERIFY template uses $store** (with $ prefix)
5. **VERIFY WebSocket store routes** messages to this store
6. **TEST by loading page** and checking Network tab

**OUTPUT:** For each route, confirm:
- Store file path
- API endpoints connected
- WebSocket message types handled
- Page file path
- All data flows verified
