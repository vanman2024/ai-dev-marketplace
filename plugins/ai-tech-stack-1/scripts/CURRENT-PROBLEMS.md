# Critical Problems with AI Tech Stack 1 Phases

## The Core Problem

**Phases create empty frameworks, NOT actual implementations from specs.**

## What Actually Happens Now

### Phase 0: Planning (WORKS ✅)
Creates comprehensive documentation:
- `docs/architecture/` (7 files, ~150KB)
  - frontend.md, backend.md, data.md, ai.md, infrastructure.md, security.md, integrations.md
- `docs/adr/` (7 ADRs, ~88KB)
  - 0001-adoption-of-ai-tech-stack-1.md
  - 0002-nextjs-15-for-frontend.md
  - 0003-fastapi-for-backend.md
  - 0004-supabase-for-database.md
  - 0005-multi-ai-provider-strategy.md
  - 0006-mem0-for-user-memory.md
  - 0007-vercel-and-flyio-deployment.md
- `docs/ROADMAP.md`
- `specs/*/` (if /planning:init-project was run)
  - spec.md (647 lines!)
  - plan.md
  - tasks.md (45 tasks)
  - data-model.md
  - contracts/api-contracts.md
  - research.md
  - reports/

### Phase 1: Foundation ❌ DOESN'T READ SPECS
**What it does:**
- `/nextjs-frontend:build-full-stack` → Creates blank Next.js app
- `/fastapi-backend:init-ai-app` → Creates blank FastAPI app
- `/supabase:init-ai-app` → Creates empty schema

**What it SHOULD do:**
- Read `docs/architecture/frontend.md` (17KB of requirements)
- Read `docs/architecture/backend.md` (24KB of API design)
- Read `docs/architecture/data.md` (17KB of schema design)
- Read `specs/*/plan.md` for each feature
- Read `specs/*/data-model.md` for database schema
- Read `specs/*/contracts/api-contracts.md` for endpoints
- **IMPLEMENT** the actual pages, components, API routes, database tables

### Phase 2: AI Features ❌ DOESN'T READ SPECS
**What it does:**
- `/vercel-ai-sdk:build-full-stack` → Adds basic chat template
- `/mem0:init-oss` → Configures empty mem0
- `/claude-agent-sdk:build-full-app` → Creates agent boilerplate

**What it SHOULD do:**
- Read `docs/architecture/ai.md` (24KB of AI architecture)
- Read `specs/*/spec.md` for AI requirements
- Read `specs/*/plan.md` for agent design
- **IMPLEMENT** the actual AI features, agents, tools, prompts

### Phase 3: Integration ❌ ONLY 2 COMMANDS
**What it does:**
- `/nextjs-frontend:add-component button`
- `/nextjs-frontend:search-components chat`

**What it SHOULD do:**
- Read `docs/architecture/integrations.md` (19KB)
- Wire frontend ↔ backend based on API contracts
- Implement actual feature components from specs
- Connect AI to UI based on architecture

### Phases 4-5: Testing & Deployment ❌ GENERIC
Don't reference any of the actual implemented features or specs.

## What Files Are Created vs What's Needed

### RedAI Example Files Created:
```
docs/
├── architecture/
│   ├── ai.md (24KB) ← COMPREHENSIVE AI DESIGN
│   ├── backend.md (24KB) ← COMPLETE API DESIGN
│   ├── data.md (17KB) ← FULL SCHEMA DESIGN
│   ├── frontend.md (17KB) ← ALL PAGES/COMPONENTS
│   ├── infrastructure.md (15KB)
│   ├── integrations.md (19KB)
│   └── security.md (18KB)
├── adr/ (7 ADRs)
└── ROADMAP.md

specs/
├── 001-red-seal-ai/
│   ├── spec.md (647 lines)
│   ├── plan.md
│   ├── tasks.md (45 tasks: T001-T045)
│   ├── data-model.md
│   ├── contracts/
│   │   ├── api-contracts.md
│   │   ├── analytics-api-contracts.md
│   │   └── test-contracts.md
│   ├── research.md
│   └── reports/CTO_REVIEW.md
├── 002-mentorship-marketplace/ (same structure)
├── 003-create-an-employer/ (same structure)
└── 004-the-skilled-trades/ (same structure)
```

**Total Documentation:** ~600KB of comprehensive specs
**What gets implemented:** Blank framework templates

## The Missing Link

**Phases 1-5 need to:**

1. **Load all relevant documentation** from Phase 0
2. **Parse specs/*/tasks.md** for implementation tasks
3. **Read architecture/*.md** for design requirements
4. **Extract from specs/*/contracts/** for API definitions
5. **Pull from specs/*/data-model.md** for database schema
6. **Reference specs/*/spec.md** for feature requirements
7. **ACTUALLY BUILD** the features, not just framework scaffolding

## Example: What Phase 1 SHOULD Do

Instead of creating blank Next.js:

```bash
# Current (WRONG):
/nextjs-frontend:build-full-stack my-app
# Creates: Empty Next.js with no features

# What it SHOULD do:
/nextjs-frontend:build-full-stack my-app
  1. Read docs/architecture/frontend.md
  2. Parse all page requirements
  3. Read specs/*/spec.md for feature list
  4. For each feature:
     - Create pages from architecture/frontend.md
     - Build components from specs/*/plan.md
     - Wire to API from specs/*/contracts/
  5. Generate actual implementation, not templates
```

## Root Cause

**Commands are framework-agnostic initializers, not spec-driven builders.**

They initialize frameworks but don't:
- Read project documentation
- Parse feature specifications
- Extract implementation requirements
- Generate actual business logic
- Wire features together

## Solution Needed

**Option 1: Add "implementation phases"**
- Phase 0: Planning
- Phase 1: Foundation (frameworks only)
- **Phase 2: Feature Implementation** ← NEW (reads specs, builds features)
- Phase 3: AI Features (implementation)
- Phase 4: Integration
- Phase 5: Testing
- Phase 6: Deployment

**Option 2: Make existing phases spec-aware**
- Modify Phase 1 commands to accept `--from-specs` flag
- Read docs/architecture/ and specs/ before generating
- Build actual features, not blank templates

**Option 3: Implement from tasks.md**
- Add Phase 2.5: Task Execution
- Read specs/*/tasks.md
- Execute T001-T045 sequentially or in parallel
- Each task implements actual code from spec

## The Vision Gap

**User expectation:**
"Run `/ai-tech-stack-1:build-full-stack red-ai` and get a WORKING Red Seal AI app with study features, agents, memory, etc."

**Current reality:**
"Run command, get empty Next.js + FastAPI + Supabase with no features implemented."

**The gap:**
~600KB of comprehensive specs → 0KB of feature implementation

## Recommendation

We need to decide:
1. Should phases build FROM specs or just framework scaffolding?
2. If from specs, which phase reads and implements them?
3. How do we handle the specs/*/tasks.md (45 tasks per feature)?
4. Should unused plugins (rag-pipeline, elevenlabs, openrouter) be integrated?
5. Do we need more phases for actual feature development?
