# AI Tech Stack 1: Complete Definition

**Full-Stack AI Application Platform**

---

## Overview

Complete, production-ready tech stack for building sophisticated AI-powered applications with multi-agent capabilities, persistent memory, and MCP server architecture.

### The Kitchen Philosophy 🏠

**AI Tech Stack 1 = The Kitchen**

Think of AI Tech Stack 1 as a **fully-equipped kitchen** with all the essential appliances:
- 🔥 **Stove** (Next.js) - Core cooking platform
- 🌡️ **Oven** (Vercel AI SDK) - Multi-model orchestration
- 🧊 **Fridge** (Supabase) - Data storage and auth
- 🔪 **Counters** (React + Tailwind) - Workspace and UI
- 🍽️ **Dishwasher** (Testing/Quality tools) - Cleanup and validation

**This kitchen works for cooking ANY meal!** Whether you're making breakfast, lunch, dinner, or desserts - the foundation is the same.

### Extensions = Specialized Appliances 🔧

For specific recipes, you add **specialized appliances** as extensions:
- ☕ **Espresso Machine** (Imagen/Veo) - High-quality image/video generation
- 🍦 **Ice Cream Maker** (DALL-E) - Alternative image generation
- 🥩 **Sous Vide** (Custom MCP tools) - Precision custom workflows
- 🍞 **Bread Maker** (Specific integrations) - Domain-specific automation

**You only add what you need for YOUR recipe!**

This pattern keeps AI Tech Stack 1 **universal and focused** - it provides the essential foundation that works for any AI application. Domain-specific needs get their own modular extensions that plug in seamlessly.

**Example**: Building an AI Marketing Automation System?
- ✅ **Use the kitchen** (AI Tech Stack 1: Next.js, Vercel AI SDK, Supabase, Mem0)
- ➕ **Add the espresso machine** (Google Vertex AI extension for Imagen/Veo)
- 🚀 **Cook your meal** (Complete marketing automation in days!)

---

**Use Cases:**
- Multi-pillar AI platforms (like RedAI)
- AI-powered SaaS products
- AI assistant/chatbot applications
- RAG-based knowledge systems
- Multi-agent orchestration systems
- Marketing automation systems
- Content generation platforms
- Any AI-powered application

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
- **Models:** Claude 4.5 Sonnet

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

## The Extension Pattern: Adding Specialized Capabilities

### Philosophy: Kitchen + Specialized Appliances

AI Tech Stack 1 is your **fully-equipped kitchen** - it has everything you need for general cooking (AI app development). But sometimes you need specialized appliances for specific recipes.

### When to Add Extensions

**Use the base kitchen (AI Tech Stack 1) for:**
- ✅ User authentication and management
- ✅ Database operations (PostgreSQL with pgvector)
- ✅ AI text generation (Claude, GPT-4, Gemini)
- ✅ Streaming responses
- ✅ Tool calling and function execution
- ✅ Memory and context management (Mem0)
- ✅ Real-time updates
- ✅ Payment processing (Stripe)
- ✅ File storage and uploads
- ✅ API endpoint creation

**Add specialized appliances (extensions) for:**
- 🎨 **Image Generation** - Imagen, DALL-E, Midjourney, Stable Diffusion
- 🎬 **Video Generation** - Veo, Sora, Runway, Pika
- 🎵 **Audio Generation** - ElevenLabs, Murf, Play.ht
- 📊 **Data Processing** - Custom analytics, ML models, ETL pipelines
- 🔧 **Domain Tools** - Industry-specific APIs and workflows
- 🌐 **External Integrations** - CRM, marketing tools, payment gateways

### Extension Architecture

```
┌─────────────────────────────────────────────────┐
│  AI Tech Stack 1 (The Kitchen)                  │
│  ✅ Next.js, React, Tailwind                    │
│  ✅ Vercel AI SDK (multi-model)                 │
│  ✅ Supabase (database, auth, storage)          │
│  ✅ Mem0 (memory management)                    │
│  ✅ FastMCP (tool framework)                    │
│  ✅ Stripe (payments)                           │
│  ✅ Testing & deployment infrastructure         │
└─────────────────────────────────────────────────┘
                    ↓
        Plug in extensions as needed
                    ↓
┌─────────────────────────────────────────────────┐
│  Extensions (Specialized Appliances)            │
│                                                 │
│  📦 google-vertex-ai-mcp/                       │
│     ├── generate_image_imagen3()                │
│     └── generate_video_veo3()                   │
│                                                 │
│  📦 openai-dalle-mcp/                           │
│     └── generate_image_dalle3()                 │
│                                                 │
│  📦 elevenlabs-audio-mcp/                       │
│     └── generate_voice()                        │
│                                                 │
│  📦 your-custom-domain-mcp/                     │
│     └── your_specific_tools()                   │
└─────────────────────────────────────────────────┘
```

### Example: Marketing Automation System

**The Recipe**: AI-powered marketing automation that generates complete product launches

**The Kitchen (AI Tech Stack 1)** provides:
- ✅ Next.js web app with beautiful UI
- ✅ User accounts and authentication (Supabase)
- ✅ AI text generation for copy (Vercel AI SDK → Claude/Gemini)
- ✅ Brand context storage (Mem0)
- ✅ Payment processing (Stripe)
- ✅ Real-time progress updates
- ✅ Generation history tracking

**The Specialized Appliances (Extensions)** add:
- ☕ **Espresso Machine** (google-vertex-ai-mcp):
  - Imagen 3/4: Generate 25 product images ($0.02 - $0.06 each)
  - Veo 2/3: Generate marketing videos ($0.10 - $0.50 per second)
  - Custom MCP server wrapping Google Vertex AI APIs

**Total System Cost**: 93% infrastructure from AI Tech Stack 1, 7% from extension

**Implementation**:
```bash
# 1. Start with the kitchen
/ai-tech-stack-1:init marketing-automation

# 2. Add the espresso machine
npm install @google-cloud/aiplatform
# Build google-vertex-ai-mcp server

# 3. Configure MCP server in config/ai/mcp-servers.yaml

# 4. Use in your app (Vercel AI SDK calls MCP tools)
```

### Real-World Extension Examples

**E-commerce Product Photography**:
- Kitchen: Next.js + Vercel AI SDK + Supabase
- Appliance: Imagen 4 Ultra for high-quality product shots
- Result: Automated product photo generation pipeline

**Video Marketing Platform**:
- Kitchen: Next.js + Vercel AI SDK + Supabase + Mem0
- Appliances: Veo 3 (video) + ElevenLabs (voiceover)
- Result: Complete video marketing automation

**Multi-modal Content Generator**:
- Kitchen: Next.js + Vercel AI SDK + Supabase
- Appliances: DALL-E 3 (images) + Claude Sonnet (text) + Play.ht (audio)
- Result: Blog posts with custom images and audio versions

### Benefits of This Pattern

**1. Clean Separation** 🎯
- Core infrastructure stays focused and stable
- Extensions are isolated and swappable
- Can update AI Tech Stack 1 without breaking extensions

**2. Reusable Foundation** 🔄
- Build the kitchen once, use for many recipes
- Same infrastructure for chatbot, marketing tool, or data app
- Only add domain-specific tools when needed

**3. Cost Effective** 💰
- Don't pay for capabilities you don't use
- Extensions scale with usage
- Base infrastructure has generous free tiers

**4. Easy to Learn** 📚
- Master the kitchen first (one learning curve)
- Add appliances incrementally as needed
- Clear documentation for each extension

**5. Rapid Development** ⚡
- Start with complete foundation (days, not months)
- Add specialized features quickly
- Focus on unique business logic, not infrastructure

### Building Your Own Extensions

**Use FastMCP to create custom MCP servers:**

```python
# mcp-servers/your-domain-tools/main.py
from fastmcp import FastMCP

mcp = FastMCP("Your Domain Tools")

@mcp.tool()
async def your_custom_tool(param: str) -> dict:
    """Your domain-specific functionality"""
    # Integration with external API
    # Custom business logic
    # Data processing
    return result

if __name__ == "__main__":
    mcp.run()
```

**Configure in your AI Tech Stack 1 project:**

```yaml
# config/ai/mcp-servers.yaml
mcp_servers:
  your-domain-tools:
    command: "python"
    args: ["-m", "your-domain-tools"]
    env:
      YOUR_API_KEY: "${YOUR_API_KEY}"
```

**Use in Vercel AI SDK:**

```typescript
// Wrap MCP tool for Vercel AI SDK
import { tool } from 'ai'

const yourCustomTool = tool({
  description: 'Your domain-specific tool',
  parameters: z.object({ param: z.string() }),
  execute: async ({ param }) => {
    return await callMCPTool('your-domain-tools', 'your_custom_tool', { param })
  }
})
```

### Extensions as Plugins: The Modular Approach

**Key Insight**: Extensions don't have to be standalone MCP servers - they can be **Claude Code plugins** themselves!

#### The Plugin-as-Extension Pattern

Once you build domain-specific functionality as a **Claude Code plugin**, it becomes a reusable extension for ANY project:

```
plugins/google-vertex-ai/           ← Plugin = Extension
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   └── image-generator.md
├── commands/
│   ├── generate-image.md
│   └── generate-video.md
├── skills/
│   ├── imagen-prompting/
│   └── veo-prompting/
├── docs/
│   └── google-vertex-ai-guide.md
└── .mcp.json                       ← References external MCP server
```

**The plugin contains**:
- 📋 **Commands**: `/google-vertex-ai:generate-image`, `/generate-video`
- 🤖 **Agents**: Specialized agents for image/video generation
- 🎯 **Skills**: Prompting techniques, best practices
- 📚 **Docs**: Usage guides, examples
- 🔧 **MCP Config**: Points to external MCP server

**The MCP server lives separately**:
```
google-vertex-ai-mcp-server/        ← Separate project
├── pyproject.toml
├── src/
│   └── main.py                     ← FastMCP server
└── tools/
    ├── imagen.py
    └── veo.py
```

#### Why This Pattern is Powerful

**1. Build Once, Use Everywhere** 🔄

```bash
# Build the extension plugin once
cd ai-dev-marketplace/plugins
/domain-plugin-builder:plugin-create google-vertex-ai "Image/video generation"

# Use in ANY project
cd ~/my-marketing-app
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:generate-image "product shot"

cd ~/my-ecommerce-app
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:generate-image "hero image"

cd ~/my-social-media-tool
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:generate-video "product demo"
```

**2. Compose Tech Stacks from Plugins** 🧩

```bash
# Tech Stack 1 (Foundation)
/plugin install vercel-ai-sdk --project
/plugin install supabase-backend --project
/plugin install nextjs-frontend --project

# Extensions (Just add plugins)
/plugin install google-vertex-ai --project     # Images/videos
/plugin install elevenlabs-audio --project     # Audio
/plugin install custom-analytics --project     # Analytics
```

**3. Mix and Match as Needed** 🎨

```bash
# Marketing Automation App
AI Tech Stack 1 (Kitchen)
+ google-vertex-ai (Images/videos)
+ sendgrid-campaigns (Email)
+ analytics-dashboard (Tracking)

# E-commerce Product Tool
AI Tech Stack 1 (Kitchen)
+ google-vertex-ai (Product photos)
+ stripe-advanced (Complex payments)
+ inventory-management (Stock tracking)

# Social Media Manager
AI Tech Stack 1 (Kitchen)
+ google-vertex-ai (Images/videos)
+ elevenlabs-audio (Voiceovers)
+ social-media-apis (Publishing)
```

#### The 5-10% Domain-Specific Plugins

**The Philosophy**: Build the domain-specific 5-10% as plugins, then they become reusable extensions:

```
AI Tech Stack 1 (90-95% - Foundation)
  ├── Next.js
  ├── Vercel AI SDK
  ├── Supabase
  ├── Mem0
  └── FastMCP

Domain-Specific Plugins (5-10% - Extensions)
  ├── google-vertex-ai           ← Reusable in ANY app
  ├── elevenlabs-audio            ← Reusable in ANY app
  ├── sendgrid-campaigns          ← Reusable in ANY app
  ├── stripe-advanced             ← Reusable in ANY app
  ├── analytics-dashboard         ← Reusable in ANY app
  └── your-custom-domain          ← Reusable in ANY app
```

**Once built, these plugins are available for**:
- ✅ Any project using AI Tech Stack 1
- ✅ Any project NOT using AI Tech Stack 1
- ✅ Standalone usage (just the plugin)
- ✅ Part of curated tech stack marketplaces

#### The Marketing Automation Extensions: Two Plugins

For the **AI Marketing Automation System**, you need just **two extension plugins** to add to AI Tech Stack 1:

#### Extension Plugin 1: Imagen (Image Generation) ☕

```bash
plugins/google-imagen/                 ← The "Espresso Machine"
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md                        # Setup Imagen API
│   ├── generate-image.md              # Single image
│   ├── batch-generate.md              # Multiple images
│   └── style-transfer.md              # Brand consistency
├── skills/
│   └── imagen-prompting/              # Image prompt best practices
├── docs/
│   ├── overview.md                    # Imagen 3/4 guide
│   ├── pricing.md                     # $0.02-$0.06 per image
│   └── examples/                      # Product shots, heroes, social
└── .mcp.json                          # Points to imagen-mcp-server
```

**What it does**:
- ✅ Generate 25 product images for website ($0.50-$1.50)
- ✅ Create social media graphics (1:1, 16:9, 9:16)
- ✅ Hero backgrounds, feature illustrations
- ✅ Brand-consistent style across all images
- ✅ Fast generation (200 req/min with Imagen Fast)

**Cost**: $0.02-$0.06 per image (usage-based)

#### Extension Plugin 2: Veo (Video Generation) 🎬

```bash
plugins/google-veo/                    ← The "Sous Vide"
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md                        # Setup Veo API
│   ├── generate-video.md              # Single video
│   ├── add-audio.md                   # With synchronized audio
│   └── batch-videos.md                # Multiple videos
├── skills/
│   └── veo-prompting/                 # 8-component video prompts
├── docs/
│   ├── overview.md                    # Veo 2/3 guide
│   ├── pricing.md                     # $0.10-$0.50 per second
│   └── examples/                      # Demos, testimonials, explainers
└── .mcp.json                          # Points to veo-mcp-server
```

**What it does**:
- ✅ Generate 2 marketing videos (10 seconds each, $2-$8)
- ✅ Product demos, customer testimonials, explainer videos
- ✅ Synchronized audio with perfect lip-sync (Veo 3)
- ✅ Cinematic quality at 1080p, 24-30 fps
- ✅ Fast generation for rapid iteration

**Cost**: $0.10-$0.50 per second (usage-based)

### Quick Setup for Marketing Automation

```bash
# Step 1: Initialize with AI Tech Stack 1 (Foundation - 95%)
/ai-tech-stack-1:init marketing-automation
# Result: Next.js, Vercel AI SDK, Supabase, Mem0, Stripe all set up

# Step 2: Add the two extension plugins (5%)
/plugin install google-imagen@ai-dev-marketplace --project
/plugin install google-veo@ai-dev-marketplace --project

# Step 3: Initialize the extensions
/google-imagen:init
/google-veo:init

# Step 4: Generate complete marketing campaign
/google-imagen:batch-generate 25 images "product shots, hero backgrounds"
/google-veo:generate-video "10 second product demo"

# Result: Complete marketing automation system ready!
# Total cost: $43.82 per product launch
```

### Building These Two Plugins

**Plugin 1: google-imagen**

```bash
cd ai-dev-marketplace/plugins

# Create the plugin
/domain-plugin-builder:plugin-create google-imagen \
  "Image generation with Imagen 3/4"

# Build the external MCP server
cd ../../
mkdir imagen-mcp-server
cd imagen-mcp-server

# Create FastMCP server
# main.py with @mcp.tool() for generate_image_imagen3()
# Configure with Google Vertex AI credentials
```

**Plugin 2: google-veo**

```bash
cd ai-dev-marketplace/plugins

# Create the plugin
/domain-plugin-builder:plugin-create google-veo \
  "Video generation with Veo 2/3"

# Build the external MCP server
cd ../../
mkdir veo-mcp-server
cd veo-mcp-server

# Create FastMCP server
# main.py with @mcp.tool() for generate_video_veo3()
# Configure with Google Vertex AI credentials
```

**Or combine them:**

```bash
# Single plugin with both capabilities
/domain-plugin-builder:plugin-create google-vertex-ai \
  "Image and video generation with Imagen 3/4 and Veo 2/3"

# Single MCP server with both tools
google-vertex-ai-mcp-server/
├── tools/
│   ├── imagen.py    # Image generation tools
│   └── veo.py       # Video generation tools
```

### The Complete Stack

```
AI Tech Stack 1 (95% - Foundation)
├── Next.js 15 + React 19
├── Vercel AI SDK
├── Supabase
├── Mem0
├── FastMCP
└── Stripe

Extension Plugins (5% - Domain-Specific)
├── google-imagen (Image generation)
└── google-veo (Video generation)

= Complete Marketing Automation System
```

### Alternative: Pre-Built Tech Stack

Or create a curated tech stack marketplace with everything:

```json
// ai-tech-stack-marketing-automation/marketplace.json
{
  "name": "ai-tech-stack-marketing-automation",
  "description": "Complete marketing automation with AI Tech Stack 1 + Imagen + Veo",
  "plugins": [
    // Foundation (from AI Tech Stack 1)
    {"name": "vercel-ai-sdk", "source": "..."},
    {"name": "mem0-integration", "source": "..."},
    {"name": "supabase-backend", "source": "..."},
    {"name": "nextjs-frontend", "source": "..."},
    
    // Extensions (new)
    {"name": "google-imagen", "source": "...", "category": "extension"},
    {"name": "google-veo", "source": "...", "category": "extension"}
  ]
}
```

Then users just:
```bash
/plugin marketplace add vanman2024/ai-tech-stack-marketing-automation
/plugin install google-imagen@marketing-automation --project
/plugin install google-veo@marketing-automation --project
```

---

### Creating Extension Plugins

**Step 1: Build the MCP Server** (if needed)

```bash
# Separate project for the MCP server
mkdir google-vertex-ai-mcp-server
cd google-vertex-ai-mcp-server

# Build with FastMCP
fastmcp init
# Add your tools, resources, prompts
```

**Step 2: Build the Plugin** (wraps the MCP server)

```bash
cd ai-dev-marketplace/plugins

# Create plugin structure
/domain-plugin-builder:plugin-create google-vertex-ai \
  "Image and video generation with Imagen 3/4 and Veo 2/3"

# Result:
plugins/google-vertex-ai/
├── .claude-plugin/plugin.json
├── agents/image-video-specialist.md
├── commands/
│   ├── init.md                    # Setup MCP server
│   ├── generate-image.md          # Use MCP tools
│   ├── generate-video.md          # Use MCP tools
│   └── batch-generate.md          # Batch operations
├── skills/
│   ├── imagen-prompting/          # Prompting best practices
│   └── veo-prompting/             # Video prompt structure
├── docs/
│   ├── overview.md                # How to use
│   ├── pricing.md                 # Cost guidance
│   └── examples/                  # Real examples
└── .mcp.json                      # Points to MCP server
```

**Step 3: Reference from Tech Stacks**

```json
// ai-tech-stack-1-marketplace/marketplace.json
{
  "plugins": [
    // Foundation plugins...
    {
      "name": "google-vertex-ai",
      "description": "Optional: Image/video generation extension",
      "version": "1.0.0",
      "source": {
        "source": "github",
        "repo": "vanman2024/ai-dev-marketplace",
        "path": "plugins/google-vertex-ai"
      },
      "category": "extension",
      "optional": true
    }
  ]
}
```

#### Extension Plugin Structure

**Anatomy of an extension plugin:**

```
plugins/your-extension/
├── .claude-plugin/
│   └── plugin.json                 # Metadata
│
├── commands/
│   ├── init.md                     # "Setup this extension"
│   ├── use-feature.md              # "Use the feature"
│   └── configure.md                # "Configure settings"
│
├── agents/                         # Optional: Specialized agents
│   └── specialist.md
│
├── skills/                         # Optional: Domain knowledge
│   └── best-practices/
│
├── docs/
│   ├── overview.md                 # What this extension does
│   ├── integration-guide.md        # How to integrate
│   ├── api-reference.md            # API docs
│   └── examples/                   # Usage examples
│
├── .mcp.json                       # Optional: MCP server config
│   {
│     "mcpServers": {
│       "your-extension": {
│         "command": "python",
│         "args": ["-m", "your-extension-mcp"],
│         "env": {
│           "API_KEY": "${YOUR_API_KEY}"
│         }
│       }
│     }
│   }
│
└── README.md                       # Quick reference
```

#### Real-World Extension Examples

**Image Generation Extension:**
```bash
plugins/google-vertex-ai/
- Commands: /generate-image, /generate-video, /batch-generate
- Skills: Imagen prompting, Veo video structure
- MCP Server: google-vertex-ai-mcp-server (separate repo)
- Cost: 5-10% of total project (just the domain logic)
- Reusable: Marketing, e-commerce, social media, any app
```

**Audio Generation Extension:**
```bash
plugins/elevenlabs-audio/
- Commands: /generate-voice, /clone-voice, /generate-sound
- Skills: Voice prompting, emotion control
- MCP Server: elevenlabs-mcp-server (separate repo)
- Cost: 5% of total project
- Reusable: Podcasts, videos, audiobooks, accessibility
```

**Email Marketing Extension:**
```bash
plugins/sendgrid-campaigns/
- Commands: /create-campaign, /send-email, /manage-lists
- Skills: Email best practices, deliverability
- MCP Server: sendgrid-mcp-server (separate repo)
- Cost: 5% of total project
- Reusable: Marketing apps, notifications, newsletters
```

#### The Compilation Pattern

**Building complete apps by composing plugins:**

```bash
# Start with foundation
/ai-tech-stack-1:init my-app

# Add extensions (just install plugins)
/plugin install google-vertex-ai@ai-dev-marketplace --project
/plugin install elevenlabs-audio@ai-dev-marketplace --project
/plugin install sendgrid-campaigns@ai-dev-marketplace --project

# Use them immediately
/google-vertex-ai:generate-image "hero background"
/elevenlabs-audio:generate-voice "Welcome to our platform"
/sendgrid-campaigns:create-campaign "launch-announcement"

# Result: Complete app in hours, not weeks
# Foundation (90%) + Extensions (10%) = 100% functionality
```

#### Benefits of Plugin-Based Extensions

**1. True Modularity** 🧩
- Each extension is self-contained
- Can be used independently
- Clear dependencies

**2. Easy Distribution** 📦
- Publish to ai-dev-marketplace once
- Available to all users
- Version control and updates centralized

**3. Discoverability** 🔍
- Users can browse available extensions
- Search by category, keywords
- See usage examples

**4. Consistency** 📋
- All extensions follow same structure
- Familiar patterns for developers
- Documented with examples

**5. Rapid Development** ⚡
- Build extension once (1-2 days)
- Use in unlimited projects (minutes)
- Focus on unique business logic

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
