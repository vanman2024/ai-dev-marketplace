---
description: Deploy complete AI application stack by orchestrating 3-phase deployment with progressive context management
argument-hint: [app-name]
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*)
---

**Arguments**: $ARGUMENTS

Goal: Deploy COMPLETE production-ready AI application stack by orchestrating 3 sequential phases with progressive context management.

## Complete AI Tech Stack 1

**Frontend:**
- Next.js 15 (App Router, TypeScript, Tailwind)
- Vercel AI SDK (streaming, multi-model)
- shadcn/Tailwind UI components
- Mem0 memory client

**Backend:**
- FastAPI (REST API, WebSockets)
- AI providers (Claude, OpenAI, Google)
- Claude Agent SDK (orchestration, custom tools)
- Mem0 memory operations
- Supabase client

**Database:**
- Supabase (PostgreSQL, Auth, Storage)
- pgvector (embeddings, RAG)
- RLS policies (security)
- Memory tables (Mem0)

**MCP Servers:**
- supabase (database operations)
- memory (user/agent/session memory)
- filesystem (file operations)

**Deployment:**
- Vercel (frontend)
- Fly.io (backend)
- Supabase Cloud (database)

Core Principles:
- Orchestrate 3 phases sequentially
- Progressive context management (prevents infinite scrolling)
- Save state between phases
- Comprehensive validation

Phase 1: Execute Foundation
Goal: Deploy Next.js + FastAPI + Supabase (Phase 1)

CONTEXT: Fresh start - can use 3 agents

Actions:
- Create master todo list with all 3 phases
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-1 $ARGUMENTS
- Wait for Phase 1 to complete before proceeding
- This creates:
  - Next.js 15 frontend
  - FastAPI backend (ALWAYS)
  - Supabase database
  - Backend connected to database
- Verify: !{bash test -f .ai-stack-config.json && jq -e '.phase1Complete == true' .ai-stack-config.json && echo "✅ Phase 1 complete" || echo "❌ Phase 1 failed"}
- If failed: STOP, display error, ask to retry
- If success: Mark Phase 1 complete
- Time: ~20 minutes

Phase 2: Execute AI Features
Goal: Deploy Vercel AI SDK + Mem0 + Agent SDK + MCP (Phase 2)

CONTEXT: Mid-conversation - limit to 2 agents max

Actions:
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-2
- Wait for Phase 2 to complete before proceeding
- This adds:
  - Vercel AI SDK (frontend + backend)
  - Mem0 memory persistence
  - Claude Agent SDK orchestration
  - MCP server configuration
- Verify: !{bash jq -e '.phase2Complete == true' .ai-stack-config.json && echo "✅ Phase 2 complete" || echo "❌ Phase 2 failed"}
- If failed: STOP, display error, ask to retry
- If success: Mark Phase 2 complete
- Time: ~25 minutes

Phase 3: Execute Integration
Goal: Wire services + UI + Deploy (Phase 3)

CONTEXT: Late conversation - 1 agent max or NO agents

Actions:
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-3
- Wait for Phase 3 to complete before proceeding
- This adds:
  - Frontend ↔ Backend connection
  - shadcn/Tailwind UI components
  - Vercel deployment config
  - Fly.io deployment config
  - Complete validation
- Verify: !{bash jq -e '.phase3Complete == true && .allPhasesComplete == true' .ai-stack-config.json && echo "✅ Phase 3 complete" || echo "❌ Phase 3 failed"}
- If failed: STOP, display error, ask to retry
- If success: Mark Phase 3 complete
- Time: ~25 minutes

Phase 4: Final Summary
Goal: Display complete deployment summary

Actions:
- Mark all todos complete
- Display final summary: @DEPLOYMENT-COMPLETE.md
- Show next steps:
  - Local development commands
  - Production deployment commands
  - Environment variable checklist
- Total time: ~70 minutes

## Progressive Context Management

**Early (Phase 1):**
- Up to 3 agents allowed
- Context is small
- Can handle parallel operations

**Mid (Phase 2):**
- Limit to 2 agents maximum
- Context growing
- Reduce parallelism

**Late (Phase 3):**
- 1 agent max or NO agents
- Context large
- Sequential only to prevent hang

## Resumption Pattern

If context becomes too large at any phase:
- State saved in .ai-stack-config.json
- Run: /ai-tech-stack-1:resume
- Continues from last completed phase
- Fresh context prevents infinite scrolling

## Complete Stack Components

This builds the FULL AI Tech Stack 1:
✅ Next.js 15 frontend
✅ FastAPI backend (ALWAYS)
✅ Vercel AI SDK (streaming, multi-model)
✅ Supabase (database, auth, storage)
✅ Mem0 (memory persistence)
✅ Claude Agent SDK (orchestration)
✅ MCP servers (pre-configured)
✅ shadcn/Tailwind UI components
✅ Deployment configs (Vercel + Fly.io)

## Usage

Deploy complete Red AI stack:
/ai-tech-stack-1:build-full-stack red-ai

The orchestrator will:
1. Run Phase 1 (Foundation) - 20 min
2. Run Phase 2 (AI Features) - 25 min
3. Run Phase 3 (Integration) - 25 min
4. Display complete summary

Total: ~70 minutes (slow but reliable, prevents hang)
