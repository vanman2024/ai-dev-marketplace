# AI Tech Stack 1 Plugin

**Complete AI application stack orchestrator** - Deploys production-ready Next.js + FastAPI + Vercel AI SDK + Supabase + Mem0 + Claude Agent SDK + MCP servers with progressive context management.

## Overview

ai-tech-stack-1 orchestrates existing plugins to deploy the COMPLETE AI Tech Stack 1:

✅ **Next.js 15** - Frontend with App Router, TypeScript, Tailwind
✅ **FastAPI** - Backend API (ALWAYS included)
✅ **Vercel AI SDK** - Streaming AI, multi-model support
✅ **Supabase** - Database, auth, storage, pgvector
✅ **Mem0** - Memory persistence (user/agent/session)
✅ **Claude Agent SDK** - Agent orchestration, custom tools
✅ **MCP Servers** - Pre-configured (supabase, memory, filesystem)
✅ **shadcn/Tailwind UI** - Production UI components
✅ **Deployment** - Vercel (frontend) + Fly.io (backend)

## Complete Stack Architecture

```
Frontend (Next.js 15)              Backend (FastAPI)
├─ Vercel AI SDK                   ├─ AI Providers
│  ├─ Streaming chat                │  ├─ Anthropic (Claude)
│  ├─ Multi-model                   │  ├─ OpenAI (GPT)
│  └─ Tool calling                  │  └─ Google (Gemini)
├─ Mem0 Client                      ├─ Claude Agent SDK
│  ├─ User memory                   │  ├─ Custom tools
│  ├─ Agent memory                  │  ├─ Subagents
│  └─ Session memory                │  └─ Orchestration
├─ shadcn/Tailwind UI               ├─ Mem0 Operations
│  ├─ Chat components               │  ├─ Memory CRUD
│  ├─ Forms                         │  └─ Search
│  └─ Layouts                       ├─ Supabase Client
└─ API Client → Backend             │  ├─ Database ops
                                    │  ├─ Auth
                                    │  └─ Storage
Database (Supabase)                 └─ MCP Servers
├─ PostgreSQL + pgvector               ├─ supabase
├─ Auth tables                         ├─ memory
├─ RLS policies                        └─ filesystem
├─ Memory tables (Mem0)
└─ Vector embeddings (RAG)

Deploy: Vercel + Fly.io + Supabase Cloud
```

## Installation

```bash
# Already installed if you're reading this
# Commands are registered in ~/.claude/settings.json
```

## Commands

### `/ai-tech-stack-1:build-full-stack [app-name]`

**Master orchestrator** - Deploys complete stack in 3 sequential phases.

**What it deploys:**
1. **Phase 1: Foundation** (20 min)
   - Next.js 15 frontend
   - FastAPI backend (ALWAYS)
   - Supabase database + auth
   - Backend ↔ Database connection

2. **Phase 2: AI Features** (25 min)
   - Vercel AI SDK (frontend + backend)
   - Mem0 memory persistence
   - Claude Agent SDK integration
   - MCP server configuration

3. **Phase 3: Integration** (25 min)
   - Frontend ↔ Backend connection
   - shadcn/Tailwind UI components
   - Vercel deployment config
   - Fly.io deployment config
   - Complete validation

**Progressive Context Management:**
- Phase 1: Up to 3 agents (context small)
- Phase 2: Limit to 2 agents (context growing)
- Phase 3: 1 agent max or none (context large)

**Usage:**
```bash
/ai-tech-stack-1:build-full-stack red-ai
```

**Time:** ~70 minutes total (slow but reliable, prevents hang)

**Dual-Mode Detection:**
- **Interactive Mode**: No specs found - asks questions via AskUserQuestion
- **Spec-Driven Mode**: Detects `specs/` directory - auto-configures from spec files
- Automatically reads `spec.md`, `plan.md` files and parses requirements
- No questions needed - "go nuts" mode for projects with existing specs

### Phase Commands (Can Run Individually)

#### `/ai-tech-stack-1:build-full-stack-phase-1 [app-name]`

Deploy foundation layer only.

**Creates:**
- Next.js 15 frontend (`app-name/`)
- FastAPI backend (`app-name-backend/`)
- Supabase database
- Backend connected to Supabase

**Time:** ~20 minutes

#### `/ai-tech-stack-1:build-full-stack-phase-2`

Add AI features (requires Phase 1 complete).

**Adds:**
- Vercel AI SDK streaming
- Multi-model support (Claude, OpenAI, Google)
- Mem0 memory (frontend + backend)
- Claude Agent SDK
- MCP server configs

**Time:** ~25 minutes

#### `/ai-tech-stack-1:build-full-stack-phase-3`

Wire services and deploy (requires Phase 2 complete).

**Adds:**
- Frontend ↔ Backend API connection
- shadcn/Tailwind UI components (button, input, card, avatar, chat)
- CORS configuration
- Vercel deployment config
- Fly.io deployment config
- Environment documentation

**Time:** ~25 minutes

### `/ai-tech-stack-1:resume`

Resume from saved state when context becomes too large.

**Usage:**
```bash
# If context grows too large during any phase
/ai-tech-stack-1:resume
```

### `/ai-tech-stack-1:validate [app-directory]`

Validate complete stack deployment.

**Usage:**
```bash
/ai-tech-stack-1:validate
/ai-tech-stack-1:validate my-app
```

## Use Cases

### Red AI Deployment (Spec-Driven Mode)
Multi-pillar AI platform with cost tracking, multi-model orchestration, prompt management.

**With Existing Specs** (Auto-configured):
```bash
cd redai  # Project with specs/ directory
/ai-tech-stack-1:build-full-stack red-ai
# Automatically detects:
# - specs/001-red-seal-ai/spec.md (architecture details)
# - Claude Agent SDK orchestration
# - MCP multi-agent architecture
# - Mem0 memory layer
# - Auto-configures without questions
# Result: Complete stack built from specs
```

**Without Specs** (Interactive Mode):
```bash
/ai-tech-stack-1:build-full-stack red-ai
# Asks questions:
# - App type: Red AI
# - Features: streaming, multi-model, cost tracking, memory, vector search
# - Auth: email, OAuth (Google, GitHub)
# - Deployment: Vercel, Fly.io, Supabase Cloud
```

### AI Chatbot
Conversational AI with streaming and memory.

### RAG System
Vector search with Supabase pgvector and embeddings.

### Multi-Agent Platform
Complex agent orchestration with Claude Agent SDK.

## What Gets Created

### Directory Structure
```
your-app/                           # Next.js frontend
├── app/
│   ├── api/chat/route.ts          # AI streaming endpoint
│   ├── page.tsx                    # Main page
│   └── layout.tsx                  # Root layout
├── components/
│   └── ui/                         # shadcn components
├── lib/
│   ├── api-client.ts               # Backend API client
│   ├── supabase.ts                 # Supabase client
│   └── mem0/                       # Memory operations
├── package.json
├── .env.local                      # Environment variables
├── vercel.json                     # Vercel deployment
└── .mcp.json                       # MCP servers

your-app-backend/                   # FastAPI backend
├── main.py                         # FastAPI app
├── routers/
│   ├── ai.py                       # AI endpoints
│   └── api.py                      # REST endpoints
├── models/                         # Pydantic models
├── lib/
│   ├── supabase.py                 # Supabase client
│   └── mem0/                       # Memory operations
├── agents/                         # Claude Agent SDK
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Docker image
├── fly.toml                        # Fly.io deployment
├── .env                            # Environment variables
└── .mcp.json                       # MCP servers

.ai-stack-config.json              # Deployment state
DEPLOYMENT-COMPLETE.md             # Final summary
ENVIRONMENT.md                     # Env var documentation
```

### Environment Variables

**Frontend (.env.local):**
```bash
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_BACKEND_URL=http://localhost:8000
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
```

**Backend (.env):**
```bash
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
MEM0_API_KEY=  # if using Mem0 Platform
```

## Progressive Context Management

The key innovation preventing infinite scrolling:

**Problem:** Late in conversation, launching multiple agents causes hang.

**Solution:** Progressively limit agents as context grows:
- **Phase 1** (fresh context): 3 agents max
- **Phase 2** (growing): 2 agents max
- **Phase 3** (large): 1 agent or none

**Resumption:** If context becomes too large, state saved in `.ai-stack-config.json` for resumption with `/ai-tech-stack-1:resume`

## Spec-Driven Mode (Auto-Configuration)

When running inside a project with existing specs, the orchestrator automatically detects and parses spec files.

### Supported Spec Structures

**Red AI Pattern** (numbered directories):
```
specs/
├── 001-red-seal-ai/
│   ├── spec.md              # Feature specification with architecture
│   ├── plan.md              # Implementation plan
│   ├── data-model.md        # Database schema
│   ├── quickstart.md        # Quick start guide
│   ├── research.md          # Research findings
│   ├── tasks.md             # Implementation tasks
│   └── contracts/           # API contracts
├── 002-mentorship-marketplace/
├── 003-create-an-employer/
└── 004-the-skilled-trades/
```

### Auto-Detection Logic

Phase 1 automatically:
1. Detects `specs/` directory existence
2. Finds all `spec.md` and `plan.md` files
3. Parses for:
   - App type (platform, chatbot, RAG, multi-agent)
   - Backend features (REST, GraphQL, WebSockets, FastAPI)
   - Database features (vector/pgvector, multi-tenant, realtime)
   - Auth requirements (OAuth, email, MFA)
   - AI architecture (Claude Agent SDK, MCP servers, Mem0, Vercel AI SDK)
4. Auto-fills `.ai-stack-config.json`
5. Skips interactive questions
6. Proceeds to build

**Result**: "Go nuts" mode - builds complete stack from specs without questions.

## Local Development

After deployment completes:

```bash
# Terminal 1: Frontend
cd your-app
npm run dev
# Visit: http://localhost:3000

# Terminal 2: Backend
cd your-app-backend
pip install -r requirements.txt
uvicorn main:app --reload
# API: http://localhost:8000
```

## Production Deployment

### Deploy Frontend to Vercel
```bash
cd your-app
vercel --prod
# Update NEXT_PUBLIC_BACKEND_URL with production backend URL
```

### Deploy Backend to Fly.io
```bash
cd your-app-backend
fly deploy
# Note the URL: https://your-app-backend.fly.dev
```

### Configure Supabase
Already done during deployment! Just add production API keys.

## Technology Stack

### Required Plugins
- `nextjs-frontend` - Next.js 15 setup
- `fastapi-backend` - FastAPI backend creation
- `vercel-ai-sdk` - AI streaming and multi-model
- `supabase` - Database, auth, realtime
- `mem0` - Memory persistence
- `fastmcp` - MCP server tools (optional for custom servers)
- `claude-agent-sdk` - Agent orchestration

### Stack Components
- **Next.js 15** - App Router, Server Components, TypeScript
- **FastAPI** - Python async API framework
- **Vercel AI SDK** - Streaming, multi-model, tools
- **Supabase** - PostgreSQL, RLS, Auth, Realtime, pgvector
- **Mem0** - User/agent/session memory
- **Claude Agent SDK** - Custom tools, subagents, orchestration
- **MCP Servers** - Supabase, memory, filesystem (pre-configured)
- **shadcn/ui** - React components
- **Tailwind CSS** - Utility-first styling

## Files Created During Deployment

- `.ai-stack-config.json` - Deployment state (for resumption)
- `PHASE-1-SUMMARY.md` - Phase 1 completion summary
- `PHASE-2-SUMMARY.md` - Phase 2 completion summary
- `DEPLOYMENT-COMPLETE.md` - Final deployment summary
- `ENVIRONMENT.md` - Environment variables documentation
- `VALIDATION-REPORT.md` - Validation results (from /validate)
- `validation-errors.txt` - Errors if validation fails
- `error-log.txt` - Errors if any phase fails

## Troubleshooting

### Phase fails
State is saved. Fix the issue and run the same phase again, or use `/ai-tech-stack-1:resume`.

### Context becomes too large
Run `/ai-tech-stack-1:resume` to continue with fresh context.

### Build errors
Run `/ai-tech-stack-1:validate` to check all components.

### MCP servers not working
Check `.mcp.json` in both frontend and backend directories.

## Example: Complete Red AI Deployment

```bash
# Start deployment (will take ~70 minutes)
/ai-tech-stack-1:build-full-stack red-ai

# Phase 1 runs automatically (Foundation) - 20 min
# Phase 2 runs automatically (AI Features) - 25 min
# Phase 3 runs automatically (Integration) - 25 min

# Result: Complete Red AI foundation ready!

# Local development
cd red-ai && npm run dev              # Frontend
cd red-ai-backend && uvicorn main:app --reload  # Backend

# Production deployment
cd red-ai && vercel --prod            # Frontend to Vercel
cd red-ai-backend && fly deploy       # Backend to Fly.io
```

## Architecture Documentation

See `docs/AI-TECH-STACK-ARCHITECTURE.md` for complete architecture details including:
- Kitchen vs Appliances philosophy
- Astro (marketing sites) vs Next.js (applications) distinction
- Complete technology decision tree
- Plugin composition patterns

## Contributing

To modify this plugin:

1. Edit commands in `commands/`
2. Update `plugin.json` if adding/removing commands
3. Test with `/ai-tech-stack-1:validate`
4. Commit changes

## Support

- **Documentation:** This README + `docs/AI-TECH-STACK-ARCHITECTURE.md`
- **Issues:** Report at ai-dev-marketplace repository
- **Plugin Builder:** Use `/domain-plugin-builder:*` commands

## License

MIT - Part of AI Dev Marketplace
