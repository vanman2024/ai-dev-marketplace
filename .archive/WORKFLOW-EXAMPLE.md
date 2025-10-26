# Workflow Example: Lifecycle + Tech Plugins Working Together

This document shows how **dev-lifecycle-marketplace** (how you develop) and **ai-dev-marketplace** (what you develop with) work together to build a complete AI chatbot application.

---

## Scenario: Building an AI Chatbot with RAG

**Goal:** Build a production-ready AI chatbot that:
- Uses Vercel AI SDK for streaming responses
- Stores conversation history in Supabase
- Implements RAG for internal knowledge base
- Deploys to Vercel

**Marketplaces Used:**
- `dev-lifecycle-marketplace` (optional - for structured workflow)
- `ai-dev-marketplace` (required - for tech tools)

---

## Setup: Install Both Marketplaces

```bash
# Clone both marketplaces
git clone https://github.com/vanman2024/dev-lifecycle-marketplace.git
git clone https://github.com/vanman2024/ai-dev-marketplace.git

# Install lifecycle plugins (optional but recommended)
cd dev-lifecycle-marketplace
claude plugin install 01-core --project
claude plugin install 02-develop --project
claude plugin install 03-planning --project
claude plugin install 04-iterate --project
claude plugin install 05-quality --project

# Install tech plugins (required for this project)
cd ../ai-dev-marketplace
claude plugin install vercel-ai-sdk --project
claude plugin install supabase --project
claude plugin install nextjs --project
```

Or install individually:

```bash
# Lifecycle commands
claude plugin install 01-core --source github:vanman2024/dev-lifecycle-marketplace/plugins/01-core

# Tech plugins
claude plugin install vercel-ai-sdk --source github:vanman2024/ai-dev-marketplace/plugins/vercel-ai-sdk
```

---

## Phase 1: Foundation & Setup (Lifecycle)

**Commands from:** `dev-lifecycle-marketplace` (01-core)

```bash
# 1. Initialize project structure
/core:init my-ai-chatbot

# Claude asks:
# - Project type? (Web app, API, Desktop, etc.)
# - Framework preference? (Next.js, React, Node.js, etc.)

# Output:
# ✅ Created project directory
# ✅ Initialized git repository
# ✅ Created .claude/ configuration folder
# ✅ Detected/initialized package.json
```

```bash
# 2. Detect tech stack (if existing project)
/core:detect

# Output:
# ✅ Framework: Next.js 14 (App Router)
# ✅ UI: React + Tailwind CSS
# ✅ Package Manager: npm
# ✅ Saved to .claude/project.json
```

**Result:** Project initialized with basic structure and tech stack detected.

---

## Phase 2: Planning & Architecture (Lifecycle)

**Commands from:** `dev-lifecycle-marketplace` (03-planning)

```bash
# 1. Create project specification
/planning:spec create ai-chatbot-spec

# Claude asks about requirements:
# - What features do you need?
# - What AI capabilities?
# - What data storage?
# - What deployment target?

# Output:
# ✅ Created specs/ai-chatbot-spec/
#    - requirements.md
#    - user-stories.md
#    - acceptance-criteria.md
```

```bash
# 2. Create architecture plan
/planning:architecture

# Output:
# ✅ Created docs/architecture/
#    - system-design.md (component diagram)
#    - data-flow.md (how data moves)
#    - tech-decisions.md (why Vercel AI SDK, Supabase, etc.)
```

**Result:** Complete specification and architecture documentation.

---

## Phase 3: Tech Stack Setup (Tech Plugins)

**Commands from:** `ai-dev-marketplace` (tech plugins)

### 3.1. Initialize Vercel AI SDK

```bash
# Create AI SDK scaffold
/vercel-ai-sdk:new-app my-ai-chatbot

# Claude asks:
# - Framework? (Already knows: Next.js from /core:detect)
# - AI Provider? (OpenAI, Anthropic, Google, xAI)
# - Language? (Already knows: TypeScript)

# Output:
# ✅ Installed: ai, @ai-sdk/openai
# ✅ Created: .env.example
# ✅ Created: app/api/chat/route.ts (basic endpoint)
# ✅ Created: app/chat/page.tsx (basic UI)
```

### 3.2. Initialize Supabase

```bash
# Setup Supabase for conversation storage
/supabase:init

# Claude asks:
# - Create new project or connect existing?
# - Enable realtime?
# - Setup auth?

# Output:
# ✅ Installed: @supabase/supabase-js
# ✅ Created: lib/supabase.ts (client)
# ✅ Created: supabase/migrations/ (database migrations)
# ✅ Created schema for conversations table
# ✅ Added SUPABASE_URL and SUPABASE_ANON_KEY to .env.example
```

### 3.3. Initialize Next.js (if not already)

```bash
# Configure Next.js for AI app
/nextjs:configure-for-ai

# Output:
# ✅ Updated next.config.js (streaming, API routes)
# ✅ Created middleware.ts (rate limiting)
# ✅ Configured TypeScript for AI SDK types
```

**Result:** All tech tools initialized and configured to work together.

---

## Phase 4: Feature Development (Tech Plugins)

**Commands from:** `ai-dev-marketplace` (tech plugins)

### 4.1. Add Core AI Features

```bash
# Add streaming responses
/vercel-ai-sdk:add-streaming

# Output:
# ✅ Updated app/api/chat/route.ts with streamText()
# ✅ Updated app/chat/page.tsx with useChat() hook
# ✅ Added streaming UI components
```

```bash
# Add tool calling
/vercel-ai-sdk:add-tools

# Output:
# ✅ Created tools/knowledge-base.ts (search tool)
# ✅ Created tools/calculator.ts (example tool)
# ✅ Integrated with streaming endpoint
```

```bash
# Add chat UI with persistence
/vercel-ai-sdk:add-chat

# Output:
# ✅ Created full chat interface
# ✅ Integrated Supabase for message persistence
# ✅ Added message history loading
```

### 4.2. Add Data Features

```bash
# Add RAG capabilities
/vercel-ai-sdk:add-data-features

# Claude asks:
# - Vector database? (Supabase pgvector, Pinecone, Weaviate)
# - Document sources? (Files, URLs, Database)
# - Chunking strategy? (Semantic, Fixed, Hybrid)

# Specialized agent (vercel-ai-data-agent) runs:
# ✅ Installed: @ai-sdk/openai (embeddings)
# ✅ Created: lib/embeddings.ts (embed() function)
# ✅ Created: lib/vector-store.ts (Supabase pgvector integration)
# ✅ Created: lib/rag-pipeline.ts (chunking + retrieval)
# ✅ Created: app/api/ingest/route.ts (document ingestion)
# ✅ Updated: app/api/chat/route.ts (RAG integration)
# ✅ Added: Supabase migration for pgvector
```

### 4.3. Add Production Features

```bash
# Make production-ready
/vercel-ai-sdk:add-production

# Claude asks:
# - Telemetry provider? (OpenTelemetry, DataDog, Vercel Analytics)
# - Rate limiting strategy? (Redis, Edge, Memory)
# - Test coverage target? (80%, 90%, 100%)

# Specialized agent (vercel-ai-production-agent) runs:
# ✅ Created: lib/telemetry.ts (OpenTelemetry setup)
# ✅ Created: lib/rate-limit.ts (Upstash Redis)
# ✅ Created: lib/errors.ts (error handling middleware)
# ✅ Created: tests/ (>80% coverage goal)
# ✅ Updated: app/api/chat/route.ts (telemetry + rate limiting)
# ✅ Added: monitoring dashboard config
```

**Result:** Complete AI chatbot with streaming, RAG, persistence, and production features.

---

## Phase 5: Testing & Validation (Lifecycle)

**Commands from:** `dev-lifecycle-marketplace` (05-quality)

```bash
# 1. Generate tests for new features
/quality:test-generate

# Output:
# ✅ Generated unit tests for all API routes
# ✅ Generated integration tests for RAG pipeline
# ✅ Generated E2E tests for chat flow
```

```bash
# 2. Run all tests
/quality:test

# Output:
# ✅ Unit tests: 45/45 passing
# ✅ Integration tests: 12/12 passing
# ✅ E2E tests: 8/8 passing
# ✅ Coverage: 87%
```

```bash
# 3. Security audit
/quality:security

# Output:
# ✅ No hardcoded secrets found
# ✅ All dependencies up to date
# ✅ OWASP checks passed
# ⚠️  Warning: Consider adding rate limiting to /api/ingest
```

```bash
# 4. Performance validation
/quality:performance

# Output:
# ✅ API response time: <200ms (p95)
# ✅ Streaming latency: <50ms (TTFT)
# ✅ Vector search: <100ms
# ⚠️  Consider caching for embeddings
```

**Result:** Comprehensive testing and validation complete.

---

## Phase 6: Iteration & Refinement (Lifecycle)

**Commands from:** `dev-lifecycle-marketplace` (04-iterate)

```bash
# 1. Adjust feature based on feedback
/iterate:adjust

# Claude asks:
# - What needs to change?
# User: "Add conversation titles and search"

# Output:
# ✅ Updated conversation schema
# ✅ Added title generation (AI summarization)
# ✅ Added search endpoint with embeddings
# ✅ Updated UI with search bar
```

```bash
# 2. Refactor for performance
/iterate:refactor optimize-rag

# Output:
# ✅ Added caching layer for embeddings
# ✅ Optimized vector search query
# ✅ Reduced API calls by 40%
```

```bash
# 3. Sync changes across team
/iterate:sync

# Output:
# ✅ Committed changes with descriptive message
# ✅ Pushed to feature branch
# ✅ Created PR with summary
```

**Result:** Features refined based on feedback and performance optimized.

---

## Phase 7: Deployment (Lifecycle)

**Commands from:** `dev-lifecycle-marketplace` (06-deploy - coming soon)

```bash
# 1. Prepare for deployment
/deploy:prepare

# Output:
# ✅ Environment variables documented
# ✅ Build optimized for production
# ✅ Database migrations ready
# ✅ Secrets configured in Vercel dashboard
```

```bash
# 2. Deploy to production
/deploy:run vercel

# Output:
# ✅ Deployed to Vercel
# ✅ Database migrated (Supabase)
# ✅ Environment variables set
# ✅ Production URL: https://my-ai-chatbot.vercel.app
```

```bash
# 3. Validate deployment
/deploy:validate

# Output:
# ✅ Health check: passing
# ✅ API endpoints: responding
# ✅ Database: connected
# ✅ Telemetry: reporting
```

**Result:** Application deployed and validated in production.

---

## Complete Workflow Summary

### Lifecycle Commands (How You Develop)

| Phase | Command | Purpose |
|-------|---------|---------|
| **1. Foundation** | `/core:init` | Initialize project |
| | `/core:detect` | Detect tech stack |
| **2. Planning** | `/planning:spec` | Create specification |
| | `/planning:architecture` | Design architecture |
| **3. Quality** | `/quality:test-generate` | Generate tests |
| | `/quality:test` | Run tests |
| | `/quality:security` | Security audit |
| | `/quality:performance` | Performance check |
| **4. Iteration** | `/iterate:adjust` | Modify features |
| | `/iterate:refactor` | Improve code |
| | `/iterate:sync` | Sync changes |
| **5. Deploy** | `/deploy:prepare` | Prep for deployment |
| | `/deploy:run` | Deploy to production |

### Tech Plugin Commands (What You Develop With)

| Plugin | Command | Purpose |
|--------|---------|---------|
| **vercel-ai-sdk** | `/vercel-ai-sdk:new-app` | Initialize AI SDK |
| | `/vercel-ai-sdk:add-streaming` | Add streaming |
| | `/vercel-ai-sdk:add-tools` | Add tool calling |
| | `/vercel-ai-sdk:add-chat` | Add chat UI |
| | `/vercel-ai-sdk:add-data-features` | Add RAG |
| | `/vercel-ai-sdk:add-production` | Production features |
| **supabase** | `/supabase:init` | Initialize Supabase |
| | `/supabase:create-table` | Create tables |
| | `/supabase:enable-vector` | Enable pgvector |
| **nextjs** | `/nextjs:configure-for-ai` | Configure for AI |

---

## Key Insights

### Why Separate Marketplaces?

1. **Lifecycle plugins are optional**
   - Some teams already have their own workflow
   - Tech plugins work standalone without lifecycle commands
   - Lifecycle provides structure but isn't required

2. **Tech plugins are reusable**
   - Same Vercel AI SDK plugin works with ANY workflow
   - Can swap tech choices without changing process
   - Build once, use in multiple projects

3. **Clean separation of concerns**
   - Lifecycle = process and methodology
   - Tech = specific tools and frameworks
   - No coupling between the two

### Plugin Coordination

**Lifecycle commands read `.claude/project.json`:**
```json
{
  "framework": "nextjs",
  "ai_sdk": "vercel-ai-sdk",
  "database": "supabase",
  "deployment": "vercel"
}
```

**Tech plugins update `.claude/project.json`:**
```bash
# When you run /vercel-ai-sdk:new-app
# It adds: "ai_sdk": "vercel-ai-sdk"

# When you run /supabase:init
# It adds: "database": "supabase"
```

**Result:** Commands know what's installed and adapt accordingly.

---

## Alternative Workflows

### Option 1: Tech Plugins Only (No Lifecycle)

```bash
# Direct tech plugin usage without lifecycle structure
/vercel-ai-sdk:new-app my-app
/vercel-ai-sdk:add-streaming
/vercel-ai-sdk:add-data-features
/supabase:init
npm run dev
```

**When to use:** Quick prototyping, small projects, experienced teams with their own process.

### Option 2: Lifecycle + Minimal Tech

```bash
# Use lifecycle structure, manually choose tech
/core:init
/planning:spec
# Manually install Vercel AI SDK
npm install ai @ai-sdk/openai
# Code manually or use AI assistance
/quality:test
/deploy:run
```

**When to use:** Custom tech stack not covered by plugins, maximum control.

### Option 3: Full Automation (Recommended)

```bash
# Lifecycle + Tech plugins for complete automation
/core:init
/planning:spec
/vercel-ai-sdk:build-full-stack  # One command for everything
/quality:test
/deploy:run
```

**When to use:** New projects, teams wanting standardization, rapid development.

---

## Swapping Components Mid-Project

### Scenario: Switch from Vercel AI SDK to LangChain

```bash
# 1. Remove current SDK
claude plugin uninstall vercel-ai-sdk

# 2. Install alternative
claude plugin install langchain --source github:vanman2024/ai-dev-marketplace/plugins/langchain

# 3. Re-initialize (adapts to existing code)
/langchain:init --migrate-from=vercel-ai-sdk

# Output:
# ✅ Detected existing AI code
# ✅ Converted useChat() to LangChain equivalent
# ✅ Migrated tool definitions to LangChain format
# ✅ Updated dependencies
# ✅ Tests updated and passing
```

**Why this works:** Both plugins follow same patterns, commands have similar names, lifecycle commands are agnostic.

---

## Summary: Why This Architecture Works

### Three-Tier Benefits

**Tier 1: dev-lifecycle-marketplace**
- ✅ Provides structured workflow (optional)
- ✅ Works with any tech stack
- ✅ Enforces best practices
- ✅ Coordinates multi-agent work

**Tier 2: ai-dev-marketplace**
- ✅ Master repository of all tech plugins
- ✅ Install only what you need
- ✅ Swap components easily
- ✅ Source of truth for plugins

**Tier 3: tech-stack-marketplaces**
- ✅ Curated combinations for specific use cases
- ✅ Tested configurations
- ✅ Opinionated but swappable
- ✅ Fast project setup

### Flexibility

- Use all three tiers OR just tier 2
- Mix lifecycle commands with manual coding
- Swap any tech component at any time
- Add/remove marketplaces as needed
- Progressive enhancement: start simple, add features incrementally

---

**The best of both worlds: structured workflow + flexible tech choices.**
