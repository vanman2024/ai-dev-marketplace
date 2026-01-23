---
description: Generate SvelteKit pages, components, and routing from feature specs or existing HTML. Orchestrates page-generator, component-builder, and routing-wiring agents with design system enforcement.
argument-hint: <feature-id> [--html <path>] [--page-only|--component-only|--wiring-only]
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, TodoWrite, AskUserQuestion
---

**Arguments**: $ARGUMENTS

# SvelteKit Generate Command

**Purpose:** Full page generation pipeline from spec file OR HTML prototype → components → page → routing → validation

This command orchestrates multiple agents to generate production-ready SvelteKit pages with:
- **Worktree isolation** (work in feature branch, not master)
- Design system compliance (MANDATORY first step)
- shadcn-svelte components
- Store with API integration
- WebSocket real-time updates
- Proper routing and wiring

---

## Phase 0: Worktree Verification (MANDATORY FIRST)

**CRITICAL:** Before any generation, verify we're in the correct worktree.

### Step 1: Check current location

```bash
pwd
git branch --show-current
```

### Step 2: Verify we're in a worktree for this feature

**Check if current directory contains the feature ID or is a worktree:**

```bash
# Current path should contain feature ID or be in worktrees folder
pwd | grep -E "(worktrees|$FEATURE_ID)"
```

### Step 3: If NOT in the correct worktree

**STOP and instruct user:**

```
ERROR: Not in worktree for $FEATURE_ID

Current location: $(pwd)
Current branch: $(git branch --show-current)

To continue, either:

1. Switch to existing worktree:
   cd /path/to/worktrees/$FEATURE_ID

2. Or create new worktree:
   git worktree add -b feat/$FEATURE_ID ../$(basename $(pwd))-worktrees/$FEATURE_ID
   cd ../$(basename $(pwd))-worktrees/$FEATURE_ID

Then run this command again.
```

### Step 4: If in correct worktree, store the path

```bash
WORKTREE_PATH=$(pwd)
echo "Working in: $WORKTREE_PATH"
echo "Branch: $(git branch --show-current)"
```

**ALL SUBSEQUENT PHASES USE $WORKTREE_PATH FOR FILE OPERATIONS.**

---

## Phase 1: Parse Arguments & Find Source

**Extract from $ARGUMENTS:**
- `feature-id` - Feature ID like F001, F017, W001, etc.
- `--html <path>` - Path to existing HTML file to migrate (extracts functionality)
- `--page-only` - Skip components, only generate page
- `--component-only` - Only generate components
- `--wiring-only` - Only wire existing page to backend

### Option A: If `--html` flag provided

**Read the HTML file to extract existing functionality:**

```bash
# Read the specified HTML file
cat $HTML_PATH
```

**HTML locations to check (in order):**
1. Exact path provided: `$HTML_PATH`
2. Frontend views: `frontend/views/$NAME.html`
3. Views folder: `views/$NAME.html`

**Extract from HTML:**
1. **API Endpoints** - Every `fetch()` call
2. **WebSocket Messages** - Every `ws.onmessage` handler
3. **State Variables** - All `let` declarations that hold data
4. **Event Handlers** - All `onclick`, `onsubmit`, `onchange`
5. **Render Functions** - How data maps to DOM elements
6. **DOM Structure** - Layout, grids, cards, tables

### Option B: If no `--html` flag, find spec file

```bash
# Try specs/features/ first
find specs/features -name "*$FEATURE_ID*" -type d 2>/dev/null | head -1

# Try specs/website/ for website pages
find specs/website -name "*$FEATURE_ID*" -type d 2>/dev/null | head -1

# Try specs/infrastructure/ for infra pages
find specs/infrastructure -name "*$FEATURE_ID*" -type d 2>/dev/null | head -1
```

**Read spec.md:**
- Extract page requirements
- Extract API endpoints needed
- Extract component requirements
- Extract data model/types
- Extract WebSocket message types

### Option C: If neither found

Use AskUserQuestion to gather:
1. Page route (e.g., `/dashboard`, `/settings`)
2. Page title and description
3. Data sources (API endpoints)
4. Components needed (cards, tables, forms)
5. Real-time updates needed?

---

## Phase 2: Load Design System (MANDATORY)

**CRITICAL:** Before ANY code generation, load the design system from THESE EXACT LOCATIONS.

### Step 1: Read Design System Documentation

```bash
# PRIMARY LOCATION - Read this first
cat frontend/svelte/design-system.md
```

**If not found at primary location, check alternatives:**
```bash
cat design-system.md 2>/dev/null
cat docs/design-system.md 2>/dev/null
```

**If still not found, load plugin skill:**
```
Read: ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/sveltekit-frontend/skills/design-system-enforcement/SKILL.md
```

### Step 2: Read CSS Variables (ALWAYS)

```bash
# PRIMARY LOCATION - Contains actual color tokens, spacing, typography
cat frontend/svelte/src/app.css
```

**Extract from app.css:**
- CSS custom properties (--text-*, --bg-*, --space-*, etc.)
- Color palette (light and dark mode)
- Typography scale
- Spacing scale
- Component tokens (--card-radius, --btn-radius, etc.)

### Step 3: Store Design Context

After reading both files, you MUST have:

| Category | Allowed Values | Source |
|----------|----------------|--------|
| Typography | `text-3xl`, `text-2xl`, `text-base`, `text-sm` | design-system.md |
| Weights | `font-semibold`, `font-normal` | design-system.md |
| Spacing | `p-2`, `p-4`, `p-6`, `p-8` (8pt grid) | app.css |
| Colors | Semantic only: `bg-background`, `text-foreground`, `bg-primary`, etc. | app.css |
| Components | shadcn-svelte from `$lib/components/ui/` | design-system.md |

**PASS THIS CONTEXT TO ALL AGENTS IN SUBSEQUENT PHASES.**

---

## Phase 3: Generate Components (if needed)

**Skip if:** `--page-only` or `--wiring-only` flag set

**Use Task tool to spawn component-builder-agent:**

```
Task(
  subagent_type: "sveltekit-frontend:component-builder-agent",
  prompt: """
  Generate components for feature: $FEATURE_ID

  SOURCE: [spec.md content OR HTML analysis from Phase 1]

  DESIGN SYSTEM (from frontend/svelte/design-system.md):
  - Typography: ONLY text-3xl, text-2xl, text-base, text-sm
  - Weights: ONLY font-semibold, font-normal
  - Spacing: 8pt grid (p-2, p-4, p-6, p-8)
  - Colors: Semantic only (bg-background, text-foreground, etc.)

  CSS VARIABLES (from frontend/svelte/src/app.css):
  [Include relevant CSS custom properties]

  COMPONENTS NEEDED:
  [List from spec.md or extracted from HTML]

  Requirements:
  1. Read design-system-enforcement skill first
  2. Use shadcn-svelte from $lib/components/ui/
  3. Follow 4 sizes, 2 weights, 8pt grid strictly
  4. Place in frontend/svelte/src/lib/components/features/$FEATURE_ID/
  5. Export from index.ts
  """
)
```

**Expected output:**
- New component files in `frontend/svelte/src/lib/components/features/[feature]/`
- TypeScript props interfaces
- Proper shadcn-svelte imports

---

## Phase 4: Generate Page

**Skip if:** `--component-only` or `--wiring-only` flag set

**Use Task tool to spawn page-generator-agent:**

```
Task(
  subagent_type: "sveltekit-frontend:page-generator-agent",
  prompt: """
  Generate page for feature: $FEATURE_ID

  SOURCE: [spec.md path OR HTML file path from Phase 1]

  IF HTML SOURCE PROVIDED:
  - Read: $HTML_PATH
  - Extract ALL fetch() calls → store methods
  - Extract ALL ws.onmessage handlers → WebSocket routing
  - Extract ALL event handlers → Svelte on:click/on:submit
  - Extract render logic → Svelte {#each} and {#if}

  DESIGN SYSTEM (from frontend/svelte/design-system.md):
  - Typography: ONLY text-3xl, text-2xl, text-base, text-sm
  - Weights: ONLY font-semibold, font-normal
  - Spacing: 8pt grid (p-2, p-4, p-6, p-8)
  - Colors: Semantic only (bg-background, text-foreground, etc.)

  CSS VARIABLES (from frontend/svelte/src/app.css):
  [Include relevant CSS custom properties]

  PAGE DETAILS:
  - Route: $ROUTE (e.g., /dashboard)
  - Title: $TITLE
  - Description: $DESCRIPTION

  API ENDPOINTS:
  [List from spec.md or extracted from HTML fetch() calls]

  DATA MODEL:
  [Types from spec.md or inferred from HTML]

  WEBSOCKET MESSAGES:
  [Message types from spec.md or extracted from HTML ws.onmessage]

  Requirements:
  1. Create store at frontend/svelte/src/lib/stores/[name].ts
  2. Create page at frontend/svelte/src/routes/[route]/+page.svelte
  3. Include loading, error, and empty states
  4. Wire to WebSocket store for real-time updates
  5. Follow page-generator-agent patterns exactly
  6. Migrate ALL functionality from HTML - not just visual copy
  """
)
```

**Expected output:**
- Store file: `frontend/svelte/src/lib/stores/[name].ts`
- Page file: `frontend/svelte/src/routes/[route]/+page.svelte`
- Type additions: `frontend/svelte/src/lib/api/types.ts`

---

## Phase 5: Wire Routing

**Skip if:** `--component-only` flag set

**Use Task tool to spawn routing-wiring-agent:**

```
Task(
  subagent_type: "sveltekit-frontend:routing-wiring-agent",
  prompt: """
  Wire routing for feature: $FEATURE_ID

  PAGE: frontend/svelte/src/routes/$ROUTE/+page.svelte
  STORE: frontend/svelte/src/lib/stores/$STORE_NAME.ts

  API ENDPOINTS:
  [List endpoints - from spec or HTML]

  WEBSOCKET MESSAGES:
  [List message types - from spec or HTML]

  Requirements:
  1. Verify store has load() method for each endpoint
  2. Verify page calls store.load() in onMount
  3. Add WebSocket message handlers to frontend/svelte/src/lib/stores/websocket.ts
  4. Verify all data bindings use $store prefix
  5. Test data flow end-to-end
  """
)
```

**Expected output:**
- WebSocket store updated with new message handlers
- Navigation updated if needed
- All data flows verified

---

## Phase 6: Validate Design System

**Use Task tool to spawn design-enforcer-agent:**

```
Task(
  subagent_type: "sveltekit-frontend:design-enforcer-agent",
  prompt: """
  Validate design system compliance for feature: $FEATURE_ID

  DESIGN SYSTEM SOURCE: frontend/svelte/design-system.md
  CSS VARIABLES SOURCE: frontend/svelte/src/app.css

  FILES TO CHECK:
  - frontend/svelte/src/routes/$ROUTE/+page.svelte
  - frontend/svelte/src/lib/components/features/$FEATURE_ID/*.svelte

  RULES TO ENFORCE:
  - Typography: ONLY text-3xl, text-2xl, text-base, text-sm
  - Weights: ONLY font-semibold, font-normal
  - Spacing: 8pt grid (no arbitrary values like p-[13px])
  - Colors: Semantic only (no bg-blue-500, text-gray-700)
  - Components: shadcn-svelte from $lib/components/ui/

  Output:
  - List any violations found
  - Suggest fixes for each violation
  - Auto-fix if safe to do so
  """
)
```

---

## Phase 7: Summary

**Display generation summary:**

```
SvelteKit Generation Complete!
================================

Feature: $FEATURE_ID
Source: [spec.md | HTML: $HTML_PATH]
Route: /$ROUTE

Design System Used:
------------------
- Documentation: frontend/svelte/design-system.md
- CSS Variables: frontend/svelte/src/app.css

Files Created/Modified:
-----------------------
Components:
  - frontend/svelte/src/lib/components/features/$FEATURE_ID/[Component].svelte

Store:
  - frontend/svelte/src/lib/stores/$STORE_NAME.ts

Page:
  - frontend/svelte/src/routes/$ROUTE/+page.svelte

Types:
  - frontend/svelte/src/lib/api/types.ts (updated)

WebSocket:
  - frontend/svelte/src/lib/stores/websocket.ts (updated)

Design System Validation:
------------------------
[Pass/Fail status and any warnings]

API Endpoints Wired:
-------------------
- GET /api/$ENDPOINT → store.load()
- POST /api/$ENDPOINT → store.create()
[etc.]

WebSocket Messages:
------------------
- $MESSAGE_TYPE:updated → store.updateItem()
[etc.]

Next Steps:
----------
1. Start dev server: cd frontend/svelte && bun run dev
2. Navigate to /$ROUTE
3. Check Network tab for API calls
4. Test real-time updates via WebSocket

To validate again:
  /sveltekit-frontend:enforce-design-system $ROUTE
```

---

## Error Handling

**If spec file AND HTML not found:**
- Prompt user for page details via AskUserQuestion
- Generate based on user input

**If design system not found:**
- Run `/sveltekit-frontend:init-design-system` first
- Then continue generation

**If API endpoints don't exist:**
- Warn user that backend routes need to be created
- List required endpoints

**If components already exist:**
- Ask user if they want to overwrite or skip

---

## Flag Behaviors

| Flag | Phase 3 | Phase 4 | Phase 5 | Phase 6 |
|------|---------|---------|---------|---------|
| (none) | ✓ | ✓ | ✓ | ✓ |
| `--html <path>` | ✓ | ✓ | ✓ | ✓ |
| `--page-only` | ✗ | ✓ | ✓ | ✓ |
| `--component-only` | ✓ | ✗ | ✗ | ✓ |
| `--wiring-only` | ✗ | ✗ | ✓ | ✓ |

---

## Examples

### Generate from spec file
```
/sveltekit-frontend:generate F025
```

### Generate from existing HTML prototype
```
/sveltekit-frontend:generate F025 --html frontend/views/dashboard-view.html
```

### Migrate specific HTML file (auto-detect feature)
```
/sveltekit-frontend:generate --html frontend/views/worktrees-view.html
```

### Generate only the page (components already exist)
```
/sveltekit-frontend:generate F025 --page-only
```

### Wire existing page to backend
```
/sveltekit-frontend:generate F025 --wiring-only
```

### Generate components only from HTML
```
/sveltekit-frontend:generate F025 --html frontend/views/reports-view.html --component-only
```

---

## Design System File Locations (Reference)

| File | Location | Purpose |
|------|----------|---------|
| Design docs | `frontend/svelte/design-system.md` | Rules, patterns, examples |
| CSS variables | `frontend/svelte/src/app.css` | Actual tokens, colors, spacing |
| Plugin skill | `~/.claude/plugins/.../design-system-enforcement/SKILL.md` | Fallback rules |

**HTML Prototype Locations:**
| Pattern | Location |
|---------|----------|
| Views | `frontend/views/*.html` |
| Specific | `frontend/views/[name]-view.html` |
