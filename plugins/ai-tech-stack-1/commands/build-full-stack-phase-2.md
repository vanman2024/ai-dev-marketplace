---
description: "Phase 2: AI Features - Vercel AI SDK, Mem0, Claude Agent SDK, MCP servers"
argument-hint: none
allowed-tools: SlashCommand, TodoWrite, Read, Write, Bash(*), Grep, Skill
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

Goal: Add AI capabilities (Vercel AI SDK + Mem0 + Claude Agent SDK + MCP) with progressive context management.

Core Principles:
- Add streaming AI to frontend
- Configure memory persistence
- Integrate Claude Agent SDK
- Setup MCP servers (use existing, don't create new)
- Progressive context limits apply

Phase 1: Load State
Goal: Read Phase 1 config and determine app details

CONTEXT: Mid-conversation - limit to 2 agents

Actions:
- Check .ai-stack-config.json exists:
  !{bash test -f .ai-stack-config.json && echo "Found" || echo "Not found"}
- If not found: Error and STOP
- Load config: @.ai-stack-config.json
- Verify phase1Complete is true
- Extract appName and features
- Create Phase 2 todo list

Phase 1B: AI Environment & Task Orchestration
Goal: Verify AI dependencies and create execution plan

CONTEXT: Mid - validation commands OK

Actions:
- Verify AI environment ready:
  !{slashcommand /foundation:env-check}
- Check for AI SDK dependencies (npm packages available)
- Execute task layering:
  !{slashcommand /iterate:tasks phase-2-ai-features}
- This creates layered execution plan:
  - Layer 0 (Parallel): Vercel AI SDK frontend || Vercel AI SDK backend
  - Layer 1 (Parallel after Layer 0): Mem0 memory || Claude Agent SDK
- Save execution plan to .ai-stack-phase-2-tasks.json
- Mark AI orchestration complete

Phase 2: Vercel AI SDK - Complete AI Integration
Goal: Build comprehensive AI SDK implementation

CONTEXT: Mid - 2 agents max

Actions:
- Update .ai-stack-config.json phase to 2
- Change to frontend: !{bash cd "$APP_NAME"}
- Execute immediately: !{slashcommand /vercel-ai-sdk:build-full-stack}
- This builds COMPLETE AI SDK integration with:
  - Core: Streaming, Tool calling, Chat functionality
  - UI Features: Generative UI, useObject, useCompletion, Message persistence, File attachments
  - Data Features: Embeddings generation, RAG with vector database, Structured data
  - Production: Telemetry/observability, Rate limiting, Error handling, Testing, Middleware
  - Advanced: AI agents and workflows, MCP tools integration, Image generation, Audio processing
  - Multi-provider support (Claude, OpenAI, Google)
  - Complete chat interface with all features
- Verify: !{bash test -f "$APP_NAME/app/api/chat/route.ts" && echo "✅ AI SDK added" || echo "❌ Failed"}
- Mark AI SDK complete

Phase 3: Vercel AI SDK Backend
Goal: Add AI SDK to FastAPI backend

CONTEXT: Mid - 2 agents max

Actions:
- Change to backend: !{bash cd "$APP_NAME-backend"}
- Add dependencies:
  !{bash echo "anthropic\nopenai\ngoogle-generativeai" >> requirements.txt}
  !{bash pip install -r requirements.txt}
- Create routers/ai.py with AI endpoints
- Add chat endpoint that mirrors frontend API
- Add cost tracking utilities
- Verify: !{bash grep -q "anthropic" "$APP_NAME-backend/requirements.txt" && echo "✅ Backend AI ready" || echo "❌ Failed"}
- Mark Backend AI complete

Phase 4: Mem0 Memory - Complete Memory System
Goal: Build comprehensive memory persistence with Mem0

CONTEXT: Mid - 2 agents max

Actions:
- Update .ai-stack-config.json phase to 4
- Change to frontend: !{bash cd "$APP_NAME"}
- Execute immediately: !{slashcommand /mem0:init-oss}
- Execute immediately: !{slashcommand /mem0:add-conversation-memory}
- Execute immediately: !{slashcommand /mem0:add-user-memory}
- Execute immediately: !{slashcommand /mem0:test}
- This builds COMPLETE memory system with:
  - Mem0 OSS package with Supabase backend
  - pgvector extension for embeddings
  - Memory tables (memories, memory_relationships)
  - Conversation memory (chat context, history)
  - User memory (preferences, facts, context)
  - Graph memory (entity relationships)
  - Memory operations (add, search, update, delete)
  - User/agent/session memory schemas
  - Testing and validation
- Copy Mem0 setup to backend:
  !{bash cp -r "$APP_NAME/lib/mem0" "$APP_NAME-backend/lib/" 2>/dev/null || echo "Copy memory utils"}
- Verify: !{bash grep -q "mem0" "$APP_NAME/package.json" && echo "✅ Mem0 configured" || echo "❌ Failed"}
- Mark Memory complete

Phase 5: Claude Agent SDK - Complete Production Agent
Goal: Build comprehensive agent orchestration system

CONTEXT: Late - 1 agent only

Actions:
- Update .ai-stack-config.json phase to 5
- Change to backend: !{bash cd "$APP_NAME-backend"}
- Execute immediately: !{slashcommand /claude-agent-sdk:build-full-app "$APP_NAME-backend"}
- This builds COMPLETE production agent with:
  - Core: Streaming responses, Session management
  - Integration: MCP servers, Custom tools
  - Advanced: Subagents, Permissions, Hosting config
  - Enhancement: System prompts, Slash commands, Skills, Plugins
  - Tracking: Cost tracking, Todo tracking
  - Full agents/ directory with specialized agents
  - Tool orchestration and routing
  - Production-ready error handling
- Verify: !{bash grep -q "claude-agent-sdk" "$APP_NAME-backend/requirements.txt" && echo "✅ Complete Agent SDK built" || echo "❌ Failed"}
- Mark Agent SDK complete

Phase 5B: AI Validation & Task Sync
Goal: Verify AI features integrated correctly

CONTEXT: Late - validation OK but limited agents

Actions:
- Validate AI integration against specs:
  !{slashcommand /planning:analyze-project}
- Update task completion status:
  !{slashcommand /iterate:sync phase-2-complete}
- Check for missing AI features
- Document any gaps found
- Mark Phase 2 AI validation complete

Phase 6: MCP Server Configuration Note
Goal: Document MCP server configuration (pre-configured in plugins)

CONTEXT: Late - 1 agent only

Actions:
- Update .ai-stack-config.json phase to 6
- Note: MCP servers are pre-configured in plugin .mcp.json files:
  - nextjs-frontend/.mcp.json: shadcn, tailwind-ui, figma, supabase, context7
  - supabase/.mcp.json: supabase MCP server
  - mem0/.mcp.json: OpenMemory MCP server
- ENV variables already configured by /supabase:init in Phase 1:
  - SUPABASE_URL (✅ configured)
  - SUPABASE_ANON_KEY (✅ configured)
  - SUPABASE_SERVICE_ROLE_KEY (✅ configured)
- Users may need to add optional API keys for enhanced features:
  - MEM0_API_KEY (optional, if using Mem0 Platform instead of OSS)
  - CONTEXT7_API_KEY (optional, if using Context7 MCP server)
  - FIGMA_ACCESS_TOKEN (optional, if using Figma MCP server)
- No dynamic MCP server creation during orchestration
- MCP servers run locally (npx) or can be deployed to FastMCP Cloud later
- Verify: !{bash echo "✅ MCP documented (pre-configured in plugins)"}
- Mark MCP note complete

Phase 7: Summary Phase 2
Goal: Save state and prepare for Phase 3

Actions:
- Mark all Phase 2 todos complete
- Update .ai-stack-config.json:
  !{bash jq '.phase = 2 | .phase2Complete = true | .completedAt = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' .ai-stack-config.json > .ai-stack-config.tmp && mv .ai-stack-config.tmp .ai-stack-config.json}

- Write PHASE-2-SUMMARY.md:
  - Vercel AI SDK: Frontend + Backend
  - Mem0: Memory persistence configured
  - Claude Agent SDK: Orchestration ready
  - MCP Servers: supabase, memory, filesystem
  - Status: Ready for Phase 3 (Integration)

- Display: @PHASE-2-SUMMARY.md

- Instruct user: "Phase 2 complete! Run /ai-tech-stack-1:build-full-stack-phase-3 to continue"

## What Phase 2 Adds

**Frontend AI:**
- Vercel AI SDK with streaming
- Chat UI components
- Multi-model support
- Mem0 memory client

**Backend AI - COMPLETE Production Agent:**
- AI provider clients (Anthropic, OpenAI, Google)
- Chat endpoints with streaming
- **Complete Claude Agent SDK application:**
  - Session management and state tracking
  - MCP server integration
  - Custom tool definitions and routing
  - Subagent orchestration system
  - Permission management
  - Hosting configuration (production-ready)
  - System prompts and context management
  - Slash command handlers
  - Skills system
  - Plugin architecture
  - Cost tracking and analytics
  - Todo tracking and task management
  - Production error handling

**Infrastructure:**
- Mem0 memory tables in Supabase
- MCP server configurations
- Memory operations
- Complete agents/ directory with specialized agents

**Total Time:** ~60 minutes (extended for comprehensive AI SDK, complete memory system, and production agent)
