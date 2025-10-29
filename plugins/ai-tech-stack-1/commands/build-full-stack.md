---
description: Deploy complete AI application stack by orchestrating plugin commands with progressive context management
argument-hint: [app-name]
allowed-tools: SlashCommand(*), AskUserQuestion(*), TodoWrite(*), Read(*), Write(*), Bash(*)
---

**Arguments**: $ARGUMENTS

Goal: Deploy production-ready AI application by orchestrating existing plugin commands with progressive context management to prevent infinite scrolling.

Core Principles:
- Orchestrate existing plugin commands (don't recreate functionality)
- Progressive context: 3 agents early → 2 mid → 1 late
- Sequential execution with explicit waits
- Save state for resumption if context grows too large

Phase 1: Discovery
Goal: Gather all requirements upfront

Actions:
- Create todo list with TodoWrite for all phases
- Parse $ARGUMENTS for app name (default: "my-ai-app")
- Use AskUserQuestion to gather:
  1. App type (Red AI / Chatbot / RAG / Multi-Agent)
  2. Features needed (streaming / multi-model / cost tracking / memory / vector search / MCP tools / realtime)
  3. Auth (email / OAuth / magic link / MFA)
  4. Deployment (Vercel / Fly.io / Supabase Cloud / Self-hosted)
- Write answers to .deployment-config.json
- Mark Phase 1 complete

Phase 2: Frontend (10 min)
Goal: Initialize Next.js 15 frontend

CONTEXT: Early - up to 3 agents OK

Actions:
- Update .deployment-config.json phase to 2
- SlashCommand: /nextjs-frontend:init $ARGUMENTS
- Wait for completion before proceeding
- Verify: !{bash test -f "$ARGUMENTS/package.json" && echo "✅" || echo "❌"}
- Mark Phase 2 complete

Phase 3: Database (10 min)
Goal: Setup Supabase with auth

CONTEXT: Early - up to 3 agents OK

Actions:
- Update .deployment-config.json phase to 3
- SlashCommand: /supabase:init-ai-app
- Wait for completion before proceeding
- Verify: !{bash test -f "$ARGUMENTS/.env.local" && echo "✅" || echo "❌"}
- Mark Phase 3 complete

Phase 4: AI Features (15 min)
Goal: Integrate Vercel AI SDK

CONTEXT: Mid - limit to 2 agents

Actions:
- Update .deployment-config.json phase to 4
- SlashCommand: /vercel-ai-sdk:add-streaming
- Wait for completion before proceeding
- If multi-model: SlashCommand: /vercel-ai-sdk:add-provider openai
- Wait for completion
- Verify: !{bash test -f "$ARGUMENTS/app/api/chat/route.ts" && echo "✅" || echo "❌"}
- Mark Phase 4 complete

Phase 5: Memory (10 min)
Goal: Configure Mem0

CONTEXT: Mid - limit to 2 agents

Actions:
- Update .deployment-config.json phase to 5
- SlashCommand: /mem0:init-oss
- Wait for completion before proceeding
- Verify: !{bash grep -q "mem0" "$ARGUMENTS/package.json" && echo "✅" || echo "❌"}
- Mark Phase 5 complete

Phase 6: MCP Tools (10 min, optional)
Goal: Add FastMCP if needed

CONTEXT: Late - 1 agent only

Actions:
- If MCP selected: SlashCommand: /fastmcp:new-server $ARGUMENTS-tools
- Wait for completion before proceeding
- Verify: !{bash test -f "$ARGUMENTS-tools/src/index.ts" && echo "✅" || echo "❌"}
- Mark Phase 6 complete

Phase 7: Validation (5 min)
Goal: Verify stack works

CONTEXT: Very late - NO agents

Actions:
- Update .deployment-config.json phase to 7
- Run: !{bash npm run --prefix "$ARGUMENTS" build}
- Run: !{bash npm run --prefix "$ARGUMENTS" typecheck}
- If validation fails: STOP, write error-log.txt, ask to retry
- If passes: Mark Phase 7 complete

Phase 8: Summary
Goal: Document deployment

Actions:
- Mark all todos complete
- Update .deployment-config.json with status: complete
- Write DEPLOYMENT-SUMMARY.md with:
  - App name and type
  - Features installed
  - Environment variables needed
  - Next steps
- Display summary: @DEPLOYMENT-SUMMARY.md

## Context Management

Early (1-3): 3 agents max
Mid (4-5): 2 agents max
Late (6): 1 agent only
Very Late (7-8): No agents

If context becomes too large, state saved in .deployment-config.json for resumption with /ai-tech-stack-1:resume

Total time: 60-90 minutes (slow but reliable)
