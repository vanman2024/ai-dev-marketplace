---
description: "Phase 1: Foundation - Next.js frontend, FastAPI backend, Supabase database"
argument-hint: [app-name]
allowed-tools: SlashCommand, AskUserQuestion, TodoWrite, Read, Write, Bash(*)
---

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

Phase 2A: Spec-Driven Discovery (If specs/ exists)
Goal: Auto-configure from existing specs

CONTEXT: Early - 3 agents OK

Actions (ONLY if mode = spec-driven):
- Find spec directories: !{bash ls -d specs/*/ 2>/dev/null | head -5}
- Verify spec file exists: !{bash SPEC_FILE=$(find specs -name "spec.md" -o -name "plan.md" 2>/dev/null | head -1); if [ -z "$SPEC_FILE" ]; then echo "⚠️ ERROR: specs/ directory exists but no spec.md or plan.md found"; echo "Falling back to interactive mode"; exit 1; else echo "Found: $SPEC_FILE"; fi}
- If no valid spec found: Fall back to Phase 2B (interactive mode)
- Read primary spec: !{bash find specs -name "spec.md" -o -name "plan.md" | head -1 | xargs cat}
- Parse spec for:
  - App type (search for "platform", "chatbot", "RAG", "multi-agent")
  - Backend features (search for "REST", "GraphQL", "WebSockets", "FastAPI")
  - Database features (search for "vector", "pgvector", "multi-tenant", "realtime")
  - Auth requirements (search for "OAuth", "email", "authentication", "MFA")
  - AI architecture (search for "Claude Agent SDK", "MCP", "Mem0", "Vercel AI SDK")
- Write auto-detected config to .ai-stack-config.json:
  !{bash cat > .ai-stack-config.json << 'EOF'
{
  "appName": "$ARGUMENTS"
  "mode": "spec-driven"
  "appType": "[detected from spec]"
  "backend": ["[detected features]"]
  "database": ["[detected features]"]
  "auth": ["[detected from spec]"]
  "aiArchitecture": {
    "claudeAgentSDK": "[detected bool]"
    "mcpServers": ["[detected servers]"]
    "mem0": "[detected bool]"
    "vercelAISDK": "[detected bool]"
  }
  "phase": 1
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}
- Display: "📋 Auto-detected configuration from specs/"
- Mark Spec-Driven Discovery complete

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

Phase 3: Next.js Frontend - Complete Build
Goal: Build comprehensive Next.js 15 application

CONTEXT: Early - 3 agents OK

Actions:
- Update .ai-stack-config.json phase to 3
- SlashCommand: /nextjs-frontend:build-full-stack $ARGUMENTS
- Wait for completion before proceeding
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
- SlashCommand: /fastapi-backend:init-ai-app "$ARGUMENTS-backend"
- Wait for completion before proceeding
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
- SlashCommand: /supabase:init-ai-app "$APP_TYPE"
- Wait for completion before proceeding
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
