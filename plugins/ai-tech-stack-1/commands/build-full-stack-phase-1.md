---
description: "Phase 1: Foundation - Next.js frontend, FastAPI backend, Supabase database"
argument-hint: [app-name]
allowed-tools: SlashCommand, AskUserQuestion, TodoWrite, Read, Write, Bash(*), Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Deploy foundation layer (Next.js + FastAPI + Supabase) with progressive context management.

Core Principles:
- ALWAYS include FastAPI backend (required for full stack)
- Deploy both frontend AND backend
- Setup Supabase with proper schemas
- Save state for Phase 2

Phase 1: Mode Detection
Goal: Detect if running in spec-driven mode or interactive mode

CONTEXT: Fresh start - can use 3 agents

Actions:
- Create todo list for Phase 1
- Parse $ARGUMENTS for app name (default: "my-ai-app")
- Detect mode:
  !{bash if [ -d "specs" ] && [ "$(ls -A specs 2>/dev/null)" ]; then echo "spec-driven"; else echo "interactive"; fi}
- Store mode: !{bash echo '{"mode": "'$(if [ -d "specs" ] && [ "$(ls -A specs 2>/dev/null)" ]; then echo "spec-driven"; else echo "interactive"; fi)'"}' > .ai-stack-mode.json}
- Mark Mode Detection complete

Phase 2A: Load ALL Documentation (If specs/ exists)
Goal: Load comprehensive architecture docs and ALL specs for implementation

CONTEXT: Early - 3 agents OK

Actions (ONLY if mode = spec-driven):
- Display: "📚 Loading architecture documentation and specifications..."

- Load Architecture Documentation (~250KB):
  @docs/architecture/frontend.md
  @docs/architecture/backend.md
  @docs/architecture/data.md
  @docs/architecture/ai.md
  @docs/architecture/infrastructure.md
  @docs/architecture/security.md
  @docs/architecture/integrations.md

- Load Architectural Decisions:
  @docs/adr/0001-adoption-of-ai-tech-stack-1.md
  @docs/adr/0002-nextjs-15-for-frontend.md
  @docs/adr/0003-fastapi-for-backend.md
  @docs/adr/0004-supabase-for-database.md
  @docs/adr/0005-multi-ai-provider-strategy.md
  @docs/adr/0006-mem0-for-user-memory.md
  @docs/adr/0007-vercel-and-flyio-deployment.md

- Load Roadmap:
  @docs/ROADMAP.md

- Find and count ALL feature specs:
  !{bash ls -d specs/*/ 2>/dev/null | wc -l}
  !{bash ls -d specs/*/ 2>/dev/null}

- Load ALL spec files (for context):
  !{bash for dir in specs/*/; do echo "=== $(basename $dir) ==="; cat "$dir/spec.md" 2>/dev/null | head -50; done}

- Parse architecture docs to extract:
  - Frontend pages/components (from docs/architecture/frontend.md)
  - Backend API endpoints (from docs/architecture/backend.md)
  - Database schema (from docs/architecture/data.md)
  - AI agents/tools (from docs/architecture/ai.md)
  - Auth requirements (from docs/architecture/security.md)

- Write comprehensive config to .ai-stack-config.json:
  !{bash cat > .ai-stack-config.json << 'EOF'
{
  "appName": "$ARGUMENTS",
  "mode": "spec-driven",
  "docsLoaded": {
    "architecture": ["frontend", "backend", "data", "ai", "infrastructure", "security", "integrations"],
    "adr": 7,
    "roadmap": true
  },
  "specsFound": $(ls -d specs/*/ 2>/dev/null | wc -l),
  "specDirectories": $(ls -d specs/*/ 2>/dev/null | xargs -n1 basename | jq -R . | jq -s .),
  "phase": 1,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

- Display: "✅ Loaded ~250KB architecture docs + $(ls -d specs/*/ 2>/dev/null | wc -l) feature specs"
- Mark Documentation Loading complete

Phase 2B: Interactive Discovery (If no specs/)
Goal: Gather requirements via questions

CONTEXT: Early - 3 agents OK

Actions (ONLY if mode = interactive):
- Use AskUserQuestion to gather:
  1. App type (Red AI / Chatbot / RAG System / Multi-Agent Platform)
  2. Backend features (REST API / GraphQL / WebSockets / Background tasks / Celery workers)
  3. Database features (Multi-tenant / Vector search / Realtime subscriptions / File storage)
  4. Auth (Email/password / OAuth providers / Magic link / MFA / JWT tokens)
- Write config to .ai-stack-config.json:
  !{bash cat > .ai-stack-config.json << 'EOF'
{
  "appName": "$ARGUMENTS"
  "mode": "interactive"
  "appType": "[from answers]"
  "backend": ["[features from answers]"]
  "database": ["[features from answers]"]
  "auth": ["[from answers]"]
  "phase": 1
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}
- Mark Interactive Discovery complete

Phase 2C: Task Orchestration
Goal: Create execution plan for parallel foundation deployment

CONTEXT: Early - specs ready for analysis

Actions:
- Execute task layering immediately:
  !{slashcommand /iterate:tasks phase-1-foundation}
- This analyzes specs and creates:
  - Task layers for parallel execution
  - Layer 0 (Parallel): Next.js init || FastAPI init || Supabase setup
  - Dependencies mapped automatically
  - Agent assignments optimized
- Save execution plan to .ai-stack-phase-1-tasks.json
- Verify: !{bash test -f .ai-stack-phase-1-tasks.json && echo "✅ Task layers ready" || echo "⚠️  Creating manual plan"}
- Mark task orchestration complete

Phase 3: Next.js Frontend - Complete Build
Goal: Build comprehensive Next.js 15 application

CONTEXT: Early - 3 agents OK

Actions:
- Update .ai-stack-config.json phase to 3
- Execute immediately: !{slashcommand /nextjs-frontend:build-full-stack $ARGUMENTS}
- This builds COMPLETE frontend with:
  - Next.js 15 App Router, TypeScript, Tailwind
  - Feature discovery (Supabase, AI SDK)
  - Multiple pages (dashboard, chat, settings, etc.)
  - Custom components (UI, forms, layouts)
  - Design system enforcement
  - Full integration validation
- Verify: !{bash test -f "$ARGUMENTS/package.json" && echo "✅ Frontend created" || echo "❌ Failed"}
- Mark Frontend complete

Phase 4: FastAPI Backend - Complete AI Backend
Goal: Build comprehensive AI-powered FastAPI backend

CONTEXT: Early - 3 agents OK

Actions:
- Update .ai-stack-config.json phase to 4
- Create backend directory: !{bash mkdir -p "$ARGUMENTS-backend"}
- Execute immediately: !{slashcommand /fastapi-backend:init-ai-app "$ARGUMENTS-backend"}
- This builds COMPLETE AI backend with:
  - FastAPI app with src/app layout
  - Mem0 integration (memory_manager.py, mem0_client.py)
  - Async SQLAlchemy with PostgreSQL
  - Database models (User, Conversation)
  - Memory endpoints (POST/GET/DELETE memory)
  - Chat endpoint with memory context
  - Alembic migrations
  - Docker Compose with PostgreSQL
  - Testing infrastructure (pytest)
  - Makefile for dev commands
- Verify: !{bash test -f "$ARGUMENTS-backend/main.py" && echo "✅ Backend created" || echo "❌ Failed"}
- Mark Backend complete

Phase 5: Supabase Database
Goal: Setup Supabase with AI-optimized schemas

CONTEXT: Early - 3 agents OK

Actions:
- Update .ai-stack-config.json phase to 5
- Change to frontend dir: !{bash cd "$ARGUMENTS"}
- Extract app type from config: !{bash APP_TYPE=$(jq -r '.appType' .ai-stack-config.json); echo "$APP_TYPE"}
- Execute immediately: !{slashcommand /supabase:init-ai-app "$APP_TYPE"}
- This creates (tailored to app type):
  - Database schema for AI apps (chat/rag/agents/multi-tenant)
  - Auth configuration (OAuth providers)
  - RLS policies (security)
  - pgvector extension (for RAG/embeddings)
  - Storage buckets (for files)
  - Realtime subscriptions (for chat)
- Verify: !{bash test -f "$ARGUMENTS/.env.local" && grep -q "SUPABASE" "$ARGUMENTS/.env.local" && echo "✅ Supabase configured" || echo "❌ Failed"}
- Mark Database complete

Phase 6: Backend-Database Connection
Goal: Wire FastAPI to Supabase

CONTEXT: Still early - 2-3 agents OK

Actions:
- Update .ai-stack-config.json phase to 6
- Add Supabase client to backend:
  !{bash cd "$ARGUMENTS-backend" && pip install supabase-py python-dotenv}
- Create .env in backend with Supabase credentials
- Copy from frontend .env.local: !{bash grep "SUPABASE" "$ARGUMENTS/.env.local" > "$ARGUMENTS-backend/.env"}
- Create lib/supabase.py in backend for database client
- Verify connection: !{bash cd "$ARGUMENTS-backend" && python -c "from supabase import create_client; print('✅ Supabase client works')" || echo "❌ Failed"}
- Mark Connection complete

Phase 6B: Validation & Task Sync
Goal: Verify Phase 1 completion and update task status

CONTEXT: Still early - validation commands OK

Actions:
- Validate foundation against specs:
  !{slashcommand /planning:analyze-project}
- Verify tech stack correctly installed:
  !{slashcommand /foundation:detect}
- Update task completion status:
  !{slashcommand /iterate:sync phase-1-complete}
- Check for missing requirements
- Document any gaps in PHASE-1-GAPS.md if found
- Mark Phase 1 validation complete

Phase 7: Summary Phase 1
Goal: Save state and prepare for Phase 2

Actions:
- Mark all Phase 1 todos complete
- Update .ai-stack-config.json:
  !{bash jq '.phase = 1 | .phase1Complete = true | .completedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > .ai-stack-config.tmp && mv .ai-stack-config.tmp .ai-stack-config.json}

- Write PHASE-1-SUMMARY.md:
  - Frontend: $ARGUMENTS (Next.js 15)
  - Backend: $ARGUMENTS-backend (FastAPI)
  - Database: Supabase configured
  - Connection: Backend connected to Supabase
  - Status: Ready for Phase 2

- Display: @PHASE-1-SUMMARY.md

- Instruct user: "Phase 1 complete! Run /ai-tech-stack-1:build-full-stack-phase-2 to continue"

## What Phase 1 Creates

**Frontend ($ARGUMENTS/):**
- Next.js 15 with App Router
- TypeScript configuration
- Tailwind CSS
- app/ directory structure
- package.json with dependencies

**Backend ($ARGUMENTS-backend/):**
- FastAPI application
- main.py entry point
- routers/ for API routes
- models/ for data models
- requirements.txt
- Dockerfile
- .env with Supabase credentials

**Database:**
- Supabase project configured
- Auth tables
- RLS policies
- Environment variables

**Total Time:** ~35 minutes (extended for comprehensive builds - Next.js full stack, AI backend, database)
