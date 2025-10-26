# AI Tech Stack 1: Complete Definition

**Full-Stack AI Application Platform**

---

## Overview

Complete, production-ready tech stack for building sophisticated AI-powered applications with multi-agent capabilities, persistent memory, and MCP server architecture.

**Use Cases:**
- Multi-pillar AI platforms (like RedAI)
- AI-powered SaaS products
- AI assistant/chatbot applications
- RAG-based knowledge systems
- Multi-agent orchestration systems

---

## Complete Stack Components

### 🎨 Frontend Layer

#### **Next.js 14+ (App Router)**
- **Role:** React framework, routing, SSR/ISR
- **Why:** Industry standard for production React apps
- **Features needed:** App Router, Server Components, API routes

#### **React 18+**
- **Role:** UI library
- **Why:** Component-based architecture, largest ecosystem
- **Features needed:** Hooks, Context, Suspense

#### **Tailwind CSS**
- **Role:** Utility-first styling
- **Why:** Fast development, consistent design system
- **Features needed:** Custom theme, dark mode support

#### **shadcn/ui**
- **Role:** Component library
- **Why:** Accessible, customizable, modern
- **Features needed:** Form components, dialogs, data tables

#### **Additional Frontend Tools:**
- Framer Motion (animations)
- React Hook Form + Zod (form validation)
- Lucide React (icons)

---

### 🔧 Backend/API Layer

#### **FastAPI (Python)**
- **Role:** REST API framework
- **Why:** Fast, async, automatic OpenAPI docs, Python ecosystem
- **Features needed:**
  - Async request handling
  - WebSocket support (for streaming)
  - Dependency injection
  - Background tasks
  - OpenAPI/Swagger docs

**OR**

#### **Next.js API Routes (TypeScript)**
- **Role:** API endpoints
- **Why:** Unified codebase with frontend
- **Features needed:**
  - Route handlers
  - Middleware
  - Server actions

**Decision Point:** Use FastAPI for complex AI logic, Next.js API routes for simple CRUD

---

### 🗄️ Database & Storage

#### **Supabase**
- **Role:** PostgreSQL database, auth, storage, real-time
- **Why:** Complete backend-as-a-service, open source
- **Features needed:**
  - PostgreSQL with pgvector (for embeddings)
  - Row-level security (RLS)
  - Real-time subscriptions
  - Authentication (email, OAuth, magic links)
  - Storage (file uploads)
  - Edge Functions (optional)

**Tables/Schema:**
- users (authentication, profiles)
- conversations (chat history)
- messages (individual messages with embeddings)
- memories (Mem0 persistence)
- ai_usage_tracking (cost tracking)
- prompts (versioned prompt templates)

---

### 🤖 AI Layer

#### **Vercel AI SDK**
- **Role:** AI orchestration, streaming, tool calling
- **Why:** Framework-agnostic, multi-provider, streaming support
- **Features needed:**
  - `streamText()` - streaming responses
  - `generateObject()` - structured outputs
  - `generateText()` - non-streaming completions
  - Tool calling with zod schemas
  - Multi-provider support (OpenAI, Anthropic, etc.)

#### **Mem0**
- **Role:** AI memory management
- **Why:** Persistent conversation memory, user preferences
- **Features needed:**
  - User memory (preferences, context)
  - Conversation memory (history, summaries)
  - Entity extraction
  - Memory search and retrieval
  - Supabase integration for persistence

#### **Claude Agent SDK** (Optional but recommended)
- **Role:** Agent framework for complex workflows
- **Why:** Multi-step reasoning, tool orchestration
- **Features needed:**
  - Agent workflows
  - Loop control
  - State management
  - Multi-agent coordination

---

### 🔌 MCP Infrastructure

#### **FastMCP**
- **Role:** Building custom MCP servers
- **Why:** Extend functionality with custom tools
- **Features needed:**
  - Tool definitions
  - Resource providers
  - Prompt templates
  - Server lifecycle management

**Custom MCP Servers Built:**
- Database operations (Supabase queries)
- File operations (document processing)
- External API integrations
- Custom business logic tools

**MCP Servers Used (Build-time):**
- `supabase` - Database scaffolding
- `playwright` - E2E testing
- `context7` - Documentation fetching
- `filesystem` - File operations during build

---

### 🌐 Integration/APIs

#### **Claude API (Anthropic)**
- **Role:** Primary LLM provider
- **Why:** Best reasoning, long context, tool use
- **Models:** Claude 3.5 Sonnet, Claude 3 Opus

#### **OpenAI API** (Optional)
- **Role:** Fallback provider, embeddings
- **Why:** Reliability, embeddings quality
- **Models:** GPT-4, text-embedding-3-large

#### **Additional Integrations:**
- Stripe (payments) - if SaaS
- SendGrid/Resend (emails)
- Analytics (PostHog, Mixpanel)

---

## Project Structure

```
project-root/
├── frontend/                       # Next.js application
│   ├── src/
│   │   ├── app/                   # App Router pages
│   │   ├── components/            # React components
│   │   ├── lib/                   # Utilities, hooks
│   │   └── styles/                # Global styles
│   ├── public/                    # Static assets
│   ├── package.json
│   └── next.config.js
│
├── backend/                        # FastAPI application (optional)
│   ├── app/
│   │   ├── api/                   # API routes
│   │   ├── models/                # Data models
│   │   ├── services/              # Business logic
│   │   └── core/                  # Config, dependencies
│   ├── requirements.txt
│   └── main.py
│
├── mcp-servers/                    # Custom MCP servers
│   ├── database-server/           # Supabase MCP
│   ├── file-server/               # File operations
│   └── custom-tools/              # Business-specific tools
│
├── supabase/                       # Supabase project
│   ├── migrations/                # Database migrations
│   ├── functions/                 # Edge functions
│   └── seed.sql                   # Seed data
│
├── config/
│   ├── ai/
│   │   ├── models.yaml            # AI provider config
│   │   └── mcp-servers.yaml       # MCP configuration
│   └── prompts/                   # Prompt templates
│
├── docs/                          # Documentation
└── .env.example                   # Environment variables
```

---

## Environment Variables

### Required

```bash
# Database (Supabase)
DATABASE_URL=
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# AI Providers
ANTHROPIC_API_KEY=
OPENAI_API_KEY=                    # Optional fallback

# Mem0
MEM0_API_KEY=                      # If using hosted
# OR self-hosted Mem0 with Supabase

# Authentication (Supabase handles this)
NEXTAUTH_SECRET=                   # If using NextAuth instead

# Optional
STRIPE_SECRET_KEY=                 # For payments
SENDGRID_API_KEY=                  # For emails
```

---

## Key Capabilities

### ✅ What This Stack Enables

**AI Capabilities:**
- ✅ Streaming AI responses with real-time UI updates
- ✅ Tool calling (function calling) for dynamic actions
- ✅ Multi-step reasoning with agent workflows
- ✅ Persistent memory across conversations
- ✅ RAG (Retrieval Augmented Generation) with vector search
- ✅ Multi-provider failover (Claude → OpenAI)
- ✅ Cost tracking and usage monitoring
- ✅ Prompt versioning and A/B testing

**Backend Capabilities:**
- ✅ User authentication and authorization
- ✅ Real-time database subscriptions
- ✅ File upload and storage
- ✅ Vector similarity search (pgvector)
- ✅ Row-level security (RLS)
- ✅ Background job processing
- ✅ WebSocket support

**Frontend Capabilities:**
- ✅ Server-side rendering (SSR)
- ✅ Static site generation (SSG)
- ✅ Real-time UI updates
- ✅ Responsive design (mobile-first)
- ✅ Dark mode support
- ✅ Accessibility (WCAG 2.1 AA)
- ✅ SEO optimization

**MCP Capabilities:**
- ✅ Custom tool integration
- ✅ Multi-agent coordination
- ✅ External API wrapping
- ✅ Database operations as tools
- ✅ File system operations

---

## Development Workflow

### Phase 1: Initialize Stack

```bash
# 1. Create Next.js app
/vercel-ai-sdk:new-app my-app

# 2. Initialize Supabase
/supabase:init

# 3. Setup Mem0
/mem0:init

# 4. Setup FastAPI backend (if needed)
/fastapi:init

# 5. Setup FastMCP
/fastmcp:init
```

### Phase 2: Build Core Features

```bash
# Add AI streaming
/vercel-ai-sdk:add-streaming

# Add tool calling
/vercel-ai-sdk:add-tools

# Add chat UI
/vercel-ai-sdk:add-chat

# Add RAG
/vercel-ai-sdk:add-data-features

# Add memory
/mem0:add-conversation-memory
```

### Phase 3: Add Production Features

```bash
# Production readiness
/vercel-ai-sdk:add-production

# Testing
/quality:test-generate

# Security audit
/quality:security
```

### Phase 4: Deploy

```bash
# Deploy prep
/deploy:prepare

# Deploy to Vercel (frontend + API routes)
/deploy:run vercel

# Deploy FastAPI to Railway/Fly.io (if using)
/deploy:run railway
```

---

## Cost Estimation

**Monthly Costs (Small-Medium Scale):**

| Component | Tier | Monthly Cost |
|-----------|------|--------------|
| Supabase | Free → Pro | $0 - $25 |
| Vercel | Hobby → Pro | $0 - $20 |
| Anthropic API | Usage-based | $50 - $500+ |
| Mem0 | Self-hosted | $0 (storage only) |
| FastAPI Hosting | Railway/Fly | $5 - $25 |
| **Total** | | **$55 - $570+** |

**Scale Notes:**
- Supabase free tier: 500MB database, 1GB file storage
- Vercel free tier: Unlimited hobby projects
- AI costs scale with usage (tokens)
- Can run Mem0 on Supabase (no extra cost)

---

## Documentation Links Required

### Core SDKs

**Vercel AI SDK:**
- Main docs: https://ai-sdk.dev/docs
- Streaming: https://ai-sdk.dev/docs/ai-sdk-ui/streaming
- Tools: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
- Agents: https://ai-sdk.dev/docs/agents/overview

**Mem0:**
- Docs: https://docs.mem0.ai/
- Python client: https://docs.mem0.ai/components/memory/quickstart
- Supabase integration: https://docs.mem0.ai/integrations/supabase

**Claude Agent SDK:**
- Docs: https://docs.anthropic.com/en/docs/agents
- Quickstart: https://docs.anthropic.com/en/docs/agents/quickstart
- Workflows: https://docs.anthropic.com/en/docs/agents/workflows

**Supabase:**
- Docs: https://supabase.com/docs
- Auth: https://supabase.com/docs/guides/auth
- Database: https://supabase.com/docs/guides/database
- pgvector: https://supabase.com/docs/guides/database/extensions/pgvector

**Next.js:**
- Docs: https://nextjs.org/docs
- App Router: https://nextjs.org/docs/app
- API Routes: https://nextjs.org/docs/app/building-your-application/routing/route-handlers

**FastAPI:**
- Docs: https://fastapi.tiangolo.com/
- Async: https://fastapi.tiangolo.com/async/
- WebSockets: https://fastapi.tiangolo.com/advanced/websockets/

**FastMCP:**
- Docs: https://github.com/jlowin/fastmcp
- Examples: https://github.com/jlowin/fastmcp/tree/main/examples

---

## Plugin References

All plugins installed from **ai-dev-marketplace**:

```bash
# Install complete stack
claude marketplace add ai-dev-marketplace \
  --source github:vanman2024/ai-dev-marketplace

# Individual plugins
claude plugin install vercel-ai-sdk
claude plugin install mem0
claude plugin install supabase
claude plugin install nextjs
claude plugin install fastapi
claude plugin install fastmcp
claude plugin install agent-sdk-dev
claude plugin install anthropic-sdk 
```

---

## RedAI-Specific Additions

Based on RedAI implementation, add:

### Cost Tracking Infrastructure

```typescript
// src/lib/ai/cost-tracker.ts
- Multi-provider cost tracking
- Per-user usage limits
- CSV export for analysis
- Prometheus metrics
```

### Model Orchestration

```typescript
// src/lib/ai/model-orchestrator.ts
- Automatic provider failover
- Load balancing
- Cost optimization
- Health monitoring
```

### Prompt Management

```typescript
// src/lib/ai/prompt-manager.ts
- Versioned prompt templates
- A/B testing
- Analytics integration
```

---

## Testing Strategy

### Unit Tests
- Component tests (React Testing Library)
- API endpoint tests (FastAPI TestClient)
- Utility function tests (Jest/Vitest)

### Integration Tests
- Database operations (Supabase local)
- AI provider mocks (test without API calls)
- MCP server integration

### E2E Tests
- User flows (Playwright)
- AI conversation flows
- Payment flows (if applicable)

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Vercel Edge Network                                     │
│ ├── Next.js Frontend (SSR/ISR)                         │
│ ├── API Routes (serverless functions)                  │
│ └── Edge Functions (optional)                          │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ Railway/Fly.io (Optional)                               │
│ └── FastAPI Backend                                     │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ Supabase                                                │
│ ├── PostgreSQL + pgvector                              │
│ ├── Authentication                                      │
│ ├── Storage                                             │
│ └── Real-time                                           │
└─────────────────────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────────────────────┐
│ External Services                                       │
│ ├── Anthropic API (Claude)                             │
│ ├── OpenAI API (fallback)                              │
│ ├── Mem0 (if hosted)                                   │
│ └── Other APIs                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Success Criteria

A project using **AI Tech Stack 1** should achieve:

✅ Sub-200ms API response times (p95)
✅ < 50ms Time to First Token (streaming)
✅ 99.9% uptime (with multi-provider failover)
✅ < $0.50 cost per 1000 user interactions
✅ 80%+ test coverage
✅ WCAG 2.1 AA accessibility
✅ Lighthouse score > 90
✅ Zero critical security vulnerabilities

---

## Next Steps

1. **Review this definition** - Confirm all components are needed
2. **Build plugins** - Create individual plugins for each component
3. **Create tech stack marketplace** - Bundle all plugins together
4. **Build RedAI** - Use this stack to rebuild/enhance RedAI
5. **Document learnings** - Update this doc with real-world insights

---

**Version:** 1.0.0
**Last Updated:** 2025-10-25
**Maintained by:** ai-dev-marketplace team
