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
- Complete start-to-finish-to-production workflow
- Orchestrate 6 phases sequentially (lifecycle → implementation → quality → deployment)
- Progressive context management (prevents infinite scrolling)
- Save state between phases
- Comprehensive testing and validation

Phase 0: Dev Lifecycle Foundation
Goal: Project detection, specs, environment setup, git hooks (Phase 0)

CONTEXT: Fresh start - lifecycle setup

Actions:
- Create master todo list with all 6 phases
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-0 $ARGUMENTS
- Wait for Phase 0 to complete before proceeding
- This establishes:
  - Project detection (/foundation:detect)
  - Specs creation/validation (/planning:spec)
  - Environment verification (/foundation:env-check)
  - Git hooks installation (/foundation:hooks-setup)
  - MCP documentation (pre-configured in plugins)
- Verify: !{bash test -f .ai-stack-config.json && jq -e '.phase0Complete == true' .ai-stack-config.json && echo "✅ Phase 0 complete" || echo "❌ Phase 0 failed"}
- If failed: STOP, display error, ask to retry
- If success: Mark Phase 0 complete
- Time: ~10 minutes

Phase 1: Execute Foundation
Goal: Deploy Next.js + FastAPI + Supabase (Phase 1)

CONTEXT: Early - can use 3 agents

Actions:
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
Goal: Wire services + UI components (Phase 3)

CONTEXT: Late conversation - 1 agent max or NO agents

Actions:
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-3
- Wait for Phase 3 to complete before proceeding
- This adds:
  - Frontend ↔ Backend connection
  - shadcn/Tailwind UI components
  - Deployment configs (Vercel, Fly.io)
- Verify: !{bash jq -e '.phase3Complete == true' .ai-stack-config.json && echo "✅ Phase 3 complete" || echo "❌ Phase 3 failed"}
- If failed: STOP, display error, ask to retry
- If success: Mark Phase 3 complete
- Time: ~25 minutes

Phase 4: Testing & Quality Assurance
Goal: Run comprehensive tests and security scans (Phase 4)

CONTEXT: Very late - NO agents, lifecycle commands only

Actions:
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-4
- Wait for Phase 4 to complete before proceeding
- This runs:
  - Newman API testing (/quality:test newman)
  - Playwright E2E testing (/quality:test playwright)
  - Security vulnerability scans (/quality:security)
- Verify: !{bash jq -e '.phase4Complete == true' .ai-stack-config.json && echo "✅ Phase 4 complete" || echo "❌ Phase 4 failed"}
- If tests failed: STOP, display errors, ask to fix and retry
- If tests passed: Mark Phase 4 complete
- Time: ~30 minutes

Phase 5: Production Deployment
Goal: Deploy to Vercel + Fly.io and validate (Phase 5)

CONTEXT: Very late - NO agents, lifecycle commands only

Actions:
- SlashCommand: /ai-tech-stack-1:build-full-stack-phase-5
- Wait for Phase 5 to complete before proceeding
- This executes:
  - Pre-flight checks (/deployment:prepare)
  - Actual deployment (/deployment:deploy)
  - Post-deployment validation (/deployment:validate)
- Verify: !{bash jq -e '.phase5Complete == true' .ai-stack-config.json && echo "✅ Phase 5 complete" || echo "❌ Phase 5 failed"}
- If deployment failed: STOP, display errors
- If deployment succeeded: Mark Phase 5 complete, capture URLs
- Time: ~30 minutes

Phase 6: Versioning & Final Summary
Goal: Version bump, changelog, complete summary

CONTEXT: Very late - NO agents

Actions:
- Version management:
  - SlashCommand: /versioning:bump patch
  - Generate changelog from commits
- Sync documentation:
  - SlashCommand: /iterate:sync
  - Update docs with deployment state
- Update .ai-stack-config.json:
  - phase6Complete: true
  - allPhasesComplete: true
  - deploymentUrls: [frontend, backend]
- Mark all todos complete
- Display final summary: @DEPLOYMENT-COMPLETE.md
- Show next steps:
  - Production URLs
  - Environment variables configured
  - Version and changelog
  - Monitoring and logs
- Total time: ~2.5-3 hours (Phase 0: 10min, Phase 1-3: 70min, Phase 4: 30min, Phase 5: 30min, Phase 6: 10min)

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

This builds the FULL AI Tech Stack 1 with complete lifecycle:
✅ Phase 0: Project detection, specs, environment, git hooks
✅ Phase 1: Next.js 15 frontend + FastAPI backend + Supabase database
✅ Phase 2: Vercel AI SDK + Mem0 + Claude Agent SDK + MCP
✅ Phase 3: Frontend ↔ Backend wiring + shadcn/UI components
✅ Phase 4: Newman API testing + Playwright E2E + Security scans
✅ Phase 5: Actual deployment to Vercel + Fly.io + Health validation
✅ Phase 6: Version bump + Changelog + Documentation sync

## Usage

Deploy complete start-to-finish-to-production Red AI stack:
/ai-tech-stack-1:build-full-stack red-ai

The orchestrator will:
0. Run Phase 0 (Dev Lifecycle Foundation) - 10 min
1. Run Phase 1 (Foundation) - 20 min
2. Run Phase 2 (AI Features) - 25 min
3. Run Phase 3 (Integration) - 25 min
4. Run Phase 4 (Testing & Quality) - 30 min
5. Run Phase 5 (Production Deployment) - 30 min
6. Run Phase 6 (Versioning & Summary) - 10 min

Total: ~2.5-3 hours (complete automation, start to production)
