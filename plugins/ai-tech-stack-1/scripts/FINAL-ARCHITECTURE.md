# AI Tech Stack 1: Spec-Driven Architecture

## The Complete Flow

### Phase 0: Create Architecture Foundation

**Commands run:**
1. `/planning:architecture design` → Creates `docs/architecture/*.md` (~150KB)
2. `/planning:decide` → Creates `docs/adr/*.md` (~88KB ADRs)
3. `/planning:roadmap` → Creates `docs/ROADMAP.md`
4. `/planning:init-project` → Reads architecture, creates `specs/001-020/`

**Output:**
- `docs/architecture/` - Comprehensive technical specifications
- `docs/adr/` - Architectural decision records
- `docs/ROADMAP.md` - Development timeline
- `specs/*/` - Feature specifications broken down from architecture

---

### Phase 1: Build Foundation Stack

**Mode Detection:**
```bash
test -f docs/architecture/frontend.md && echo "spec-driven" || echo "interactive"
```

#### If Spec-Driven (Architecture Exists):

**Command extracts compact summaries:**
```bash
# Get page list (compact)
grep "^### Page:" docs/architecture/frontend.md

# Get component list (compact)
grep "^### Component:" docs/architecture/frontend.md

# Feature detection
grep -qi "supabase" docs/architecture/frontend.md
```

**Command calls agents with page/component names:**
```
/nextjs-frontend:add-page dashboard
/nextjs-frontend:add-page chat
/nextjs-frontend:add-component header
```

**Agents read full architecture:**
- `page-generator-agent` reads `docs/architecture/frontend.md`
- Finds "### Page: dashboard" section
- Extracts ALL requirements for that page
- Builds complete page with features

**Result:** Real pages/components built from architecture specs!

#### If Interactive (No Architecture):

**Command asks user:**
- "What pages to create?"
- "What components to create?"

**Agents generate from user input:**
- Generic templates
- User provides requirements

---

## Architecture Document Structure

### docs/architecture/frontend.md Example:
```markdown
# Frontend Architecture

## Pages

### Page: Dashboard
Route: /dashboard
Type: Server Component
Features:
- Display user stats
- Show recent activity
- Integrate with stats API endpoint

### Page: Chat
Route: /chat
Type: Client Component
Features:
- Real-time messaging
- AI chat interface
- Message history
- Streaming responses

## Components

### Component: Header
Location: src/components/layout/Header.tsx
Type: Server Component
Features:
- Logo
- Navigation menu
- User profile dropdown
- Auth state

### Component: ChatInterface
Location: src/components/chat/ChatInterface.tsx
Type: Client Component
Features:
- Message list
- Input form
- Streaming message display
- Voice input support
```

---

## Command vs Agent Responsibilities

### Commands Should:
✅ Extract **compact lists** from architecture (page names, component names, endpoint names)
✅ Detect **features** (Supabase? AI SDK? Auth?)
✅ Count items (`grep -c`)
✅ Pass **item names** to agents
✅ Orchestrate flow

### Commands Should NOT:
❌ Load full architecture docs into memory (@docs loads full files)
❌ Pass massive content to agents in prompts
❌ Duplicate what agents can read themselves

### Agents Should:
✅ Read **full architecture** docs themselves
✅ Extract **detailed requirements** for their specific item
✅ Build actual implementation from specs
✅ Fetch latest API documentation when needed

### Agents Should NOT:
❌ Rely only on command prompts for requirements
❌ Build generic templates when architecture exists

---

## File Reading Patterns

### Command (Compact Extraction):
```bash
# Get list only
!{bash grep "^### Page:" docs/architecture/frontend.md | sed 's/^### Page: //'}

# Feature detection
!{bash grep -qi "supabase" docs/architecture/frontend.md && echo "yes" || echo "no"}

# Count
!{bash grep -c "^### Component:" docs/architecture/frontend.md}
```

### Agent (Full Detail Reading):
```markdown
### 1. Architecture Discovery
- Read: docs/architecture/frontend.md (if exists)
- Extract section for specific item being built
- Get all requirements, features, dependencies
```

---

## Benefits of This Approach

1. **Efficient Context Usage:**
   - Commands: Small grep outputs (10-50 lines)
   - Agents: Read only when building (on-demand)

2. **Scalable:**
   - Can handle 100+ pages in architecture
   - Command just extracts names
   - Each agent reads details for ITS item

3. **Flexible:**
   - Spec-driven: Builds from architecture
   - Interactive: Falls back to user input
   - Works with or without architecture docs

4. **Accurate:**
   - Agents get FULL details from source docs
   - No information lost in command→agent handoff
   - Architecture is single source of truth

---

## Example: Building Dashboard Page

### Command (`build-full-stack.md`):
```bash
# Extract page list
grep "^### Page:" docs/architecture/frontend.md
# Output: "Dashboard, Chat, Settings, Profile"

# For each page:
/nextjs-frontend:add-page dashboard
```

### Agent (`page-generator-agent.md`):
```markdown
Phase 1: Read Architecture
- Read: docs/architecture/frontend.md
- Find section: "### Page: Dashboard"
- Extract:
  - Route: /dashboard
  - Type: Server Component
  - Features: user stats, activity feed, stats API
  - Layout: uses DashboardLayout
  - Data: fetches from /api/stats

Phase 2: Build Page
- Create: app/dashboard/page.tsx
- Implement: async Server Component
- Add: data fetching from /api/stats
- Include: loading.tsx, error.tsx
- Apply: proper metadata
```

### Result:
```typescript
// app/dashboard/page.tsx - REAL implementation
import { Suspense } from 'react'
import { DashboardStats } from '@/components/dashboard/Stats'
import { ActivityFeed } from '@/components/dashboard/ActivityFeed'

export const metadata = {
  title: 'Dashboard - RedAI',
  description: 'Your Red Seal AI dashboard'
}

async function getStats() {
  const res = await fetch('http://localhost:8000/api/stats')
  return res.json()
}

export default async function DashboardPage() {
  const stats = await getStats()

  return (
    <div className="container mx-auto p-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      <Suspense fallback={<div>Loading stats...</div>}>
        <DashboardStats data={stats} />
      </Suspense>
      <ActivityFeed />
    </div>
  )
}
```

NOT a generic template - ACTUAL implementation from architecture!

---

## Status

### ✅ Implemented:
- Phase 0 creates architecture BEFORE specs
- Phase 1 detects spec-driven mode
- `/nextjs-frontend:build-full-stack` extracts compact lists
- `page-generator-agent` reads full architecture
- Commands use grep for compact extraction
- Agents read docs for full details

### 🚧 In Progress:
- Update component-builder-agent
- Update fastapi agents
- Update supabase agents

### 📋 TODO:
- Update all agents to read architecture
- Test full flow end-to-end
- Verify 600KB architecture → actual implementation
