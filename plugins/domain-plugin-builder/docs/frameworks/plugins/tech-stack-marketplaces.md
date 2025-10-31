# Tech Stack Marketplaces - Architecture Guide

> Build curated AI tech stack marketplaces by composing individual plugins from the master repository.

**Purpose**: Create opinionated, production-ready tech stacks as reusable marketplace collections.

---

## The Kitchen Philosophy 🏠

### Understanding the Architecture Through Analogy

**AI Tech Stack 1 = The Kitchen**

Think of AI Tech Stack 1 as a **fully-equipped professional kitchen**:
- 🔥 **Stove** (Next.js) - Your main cooking platform
- 🌡️ **Oven** (Vercel AI SDK) - Multi-model orchestration and AI magic
- 🧊 **Fridge** (Supabase) - Data storage, fresh ingredients on demand
- 🔪 **Counters & Knives** (React + Tailwind) - UI workspace and tools
- 🍽️ **Dishwasher** (Testing tools) - Quality assurance and cleanup

**This kitchen can cook ANY meal!** Breakfast, lunch, dinner, desserts - the foundation stays the same.

### Extensions = Specialized Appliances 🔧

For specific recipes (domain-specific needs), you add **specialized appliances**:
- ☕ **Espresso Machine** (Imagen/Veo) - Professional image/video generation
- 🍦 **Ice Cream Maker** (DALL-E) - Alternative image creation
- 🥩 **Sous Vide** (Custom MCP tools) - Precision domain workflows
- 🍞 **Bread Maker** (Specific integrations) - Specialized automation
- 🫖 **Tea Set** (Audio generation) - Voice and sound production

**The Key Principle**: You only add the specialized appliances you need for YOUR recipe!

### Why This Matters

**Clean, Focused Foundation**:
- ✅ Kitchen (AI Tech Stack 1) is universal - works for any AI application
- ✅ Foundation is stable, well-tested, production-ready
- ✅ Learn the kitchen once, use it for every project

**Modular Extensions**:
- ✅ Extensions are optional - add only what you need
- ✅ Plug in seamlessly via FastMCP
- ✅ Swappable - use DALL-E instead of Imagen, your choice
- ✅ Isolated - extension issues don't break the foundation

**Real-World Example**:

```bash
# Building AI Marketing Automation?

# 1. Start with the kitchen (93% of your infrastructure)
/ai-tech-stack-1:init marketing-automation
# Result: Complete Next.js + Vercel AI SDK + Supabase + Mem0 setup

# 2. Add the espresso machine (7% domain-specific)
npm install @google-cloud/aiplatform
# Build google-vertex-ai-mcp server for Imagen/Veo

# 3. Cook your meal!
# Complete marketing automation in days, not months
# Generate websites, images, videos, content - all automated
```

**Cost Breakdown**:
- Kitchen (AI Tech Stack 1): $60-$555/month for unlimited projects
- Espresso Machine (Google Vertex AI): Usage-based ($0.02-$0.50 per asset)
- **Total**: Base + exactly what you use

### The Pattern in Practice

**DON'T do this** ❌:
```bash
# Building everything from scratch
- Figure out Next.js setup (2 weeks)
- Configure Supabase (1 week)
- Set up authentication (1 week)
- Add Vercel AI SDK (1 week)
- Integrate Mem0 (1 week)
- Add image generation (1 week)
- Add video generation (1 week)
= 8 weeks of setup before building features
```

**DO this** ✅:
```bash
# Use the kitchen + add appliances
/ai-tech-stack-1:init my-app           # 1 day - complete foundation
npm install @google-cloud/aiplatform   # 1 hour - add extension
# Build custom MCP server               # 1-2 days
= 3 days of setup, 7+ weeks building features
```

---

## Overview

Tech stack marketplaces are **curated collections** of plugins that work together to provide a complete development environment for a specific AI technology stack. This guide explains the three-tier marketplace architecture that separates lifecycle plugins, tech-specific plugins, and curated tech stacks.

### Key Concepts

**Lifecycle Marketplace** (`dev-lifecycle-marketplace`):
- Contains software development lifecycle plugins (01-core, 02-develop, 03-planning, 04-iterate, 05-quality)
- **Tech-agnostic** - works with any programming language or framework
- Handles: project setup, feature development, planning, iteration, testing, deployment
- GitHub: https://github.com/vanman2024/dev-lifecycle-marketplace (formerly project-automation)

**Tech Plugins Master Repository** (`ai-plugins-marketplace`):
- Contains ALL tech-specific plugins (AI SDKs, frameworks, databases, UI libraries)
- Single source of truth for tech plugin code
- Includes: vercel-ai-sdk, claude-agent-sdk, mem0-integration, supabase-backend, nextjs-frontend, etc.
- Plus build tools: domain-plugin-builder
- GitHub: https://github.com/vanman2024/ai-plugins-marketplace (formerly ai-dev-marketplace)

**Tech Stack Marketplaces** (`ai-tech-stack-1`, `ai-tech-stack-2`, etc.):
- Lightweight repositories containing only `marketplace.json` + README
- Reference plugins from ai-plugins-marketplace via GitHub
- Curated for specific tech stacks (TypeScript + Next.js + Vercel AI, Python + FastAPI, etc.)
- Easy to create and maintain

---

## Marketplace Organization Strategy

### Why Separate Marketplaces?

**Problem with Single Marketplace:**
Mixing lifecycle plugins (01-core, 02-develop) with tech-specific plugins (vercel-ai-sdk, supabase) in one marketplace creates confusion:
- Hard to discover what's lifecycle vs. tech-specific
- Users might install lifecycle plugins when they only need tech plugins
- Different update cadences (lifecycle is stable, tech plugins change with SDK updates)

**Solution: Three-Tier Architecture**

```
┌─────────────────────────────────────────┐
│  dev-lifecycle-marketplace              │  ← Lifecycle (tech-agnostic)
│  - 01-core, 02-develop, 03-planning     │
│  - 04-iterate, 05-quality               │
└─────────────────────────────────────────┘
              ↓ (optional)
┌─────────────────────────────────────────┐
│  ai-plugins-marketplace (MASTER REPO)   │  ← Tech plugins (all of them)
│  - domain-plugin-builder                │
│  - vercel-ai-sdk, claude-agent-sdk      │
│  - mem0, supabase, nextjs, etc.         │
└─────────────────────────────────────────┘
              ↓ (references)
┌─────────────────────────────────────────┐
│  ai-tech-stack-1-marketplace            │  ← Curated collection
│  References: vercel-ai-sdk, mem0,       │
│              supabase, nextjs            │
└─────────────────────────────────────────┘
```

### How They Work Together

**Scenario: Building an AI SaaS Product**

```bash
# 1. Add lifecycle marketplace (optional - for general dev workflows)
/plugin marketplace add vanman2024/dev-lifecycle-marketplace

# 2. Add tech plugins marketplace (master repo)
/plugin marketplace add vanman2024/ai-plugins-marketplace

# 3. Use lifecycle plugin to set up project
/core:project-setup

# 4. Install tech-specific plugins
/plugin install vercel-ai-sdk@ai-plugins-marketplace --project
/plugin install mem0-integration@ai-plugins-marketplace --project
/plugin install supabase-backend@ai-plugins-marketplace --project

# 5. Use tech plugins to build features
/vercel-ai-sdk:new-app my-ai-app
/mem0-integration:setup
/supabase-backend:create-project

# 6. Use lifecycle plugin to iterate
/iterate:refactor "optimize-memory-usage"

# 7. Use lifecycle plugin for quality
/quality:test
```

**OR use a curated tech stack:**

```bash
# 1. Add lifecycle marketplace (still useful for iteration/quality)
/plugin marketplace add vanman2024/dev-lifecycle-marketplace

# 2. Add curated tech stack
/plugin marketplace add vanman2024/ai-tech-stack-1-marketplace

# 3. Install orchestrator that sets up everything
/plugin install full-stack-orchestrator@ai-tech-stack-1 --project
/full-stack:setup
# This installs vercel-ai-sdk, mem0, supabase, nextjs automatically

# 4. Use lifecycle plugins for development process
/iterate:adjust
/quality:test
```

**Key Point**: Lifecycle and tech plugins are **complementary**:
- **Lifecycle**: HOW you develop (setup, iterate, test, deploy)
- **Tech**: WHAT you develop with (Vercel AI, Supabase, Next.js)

---

## Architecture

### The Three-Tier Repository Structure

**Tier 1: Lifecycle Marketplace** (Tech-Agnostic Development Process)

```
dev-lifecycle-marketplace/             ← https://github.com/vanman2024/dev-lifecycle-marketplace
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   ├── 01-core/                       ← Project setup, git, env, MCP
│   ├── 02-develop/                    ← Feature development, code generation
│   ├── 03-planning/                   ← Specs, architecture, docs
│   ├── 04-iterate/                    ← Refactoring, adjustments
│   └── 05-quality/                    ← Testing, validation, security
└── README.md
```

**Tier 2: Tech Plugins Master Repository** (All Tech-Specific Plugins)

```
ai-plugins-marketplace/                ← https://github.com/vanman2024/ai-plugins-marketplace
├── .claude-plugin/
│   └── marketplace.json               ← Tech plugins only (no lifecycle)
├── plugins/
│   ├── domain-plugin-builder/         ← Build tools
│   ├── vercel-ai-sdk/                 ← AI SDK plugins
│   ├── openai-sdk-direct/
│   ├── claude-agent-sdk/
│   ├── anthropic-sdk/
│   ├── mem0-integration/              ← Integration plugins
│   ├── langchain-integration/
│   ├── supabase-backend/              ← Backend plugins
│   ├── postgres-backend/
│   ├── mongodb-backend/
│   ├── nextjs-frontend/               ← Frontend plugins
│   ├── react-frontend/
│   ├── fastapi-backend/               ← Python backend
│   ├── shadcn-ui/                     ← UI plugins
│   ├── tailwind-css/
│   └── ... (ALL plugins we build)
└── README.md
```

**Benefits**:
- ✅ Single source of truth for all plugin code
- ✅ One place to build, test, and maintain plugins
- ✅ Version control for all plugins in one repo
- ✅ Easy to discover all available plugins

### Tech Stack Marketplace Pattern

```
ai-tech-stack-1-marketplace/           ← CURATED COLLECTION (lightweight)
├── .claude-plugin/
│   └── marketplace.json               ← References plugins from master
└── README.md                          ← Documents the stack

marketplace.json (150 lines):
{
  "name": "ai-tech-stack-1"
  "description": "TypeScript + Next.js + Vercel AI SDK + Supabase + Mem0"
  "plugins": [
    {
      "name": "vercel-ai-sdk"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/vercel-ai-sdk"
      }
    }
    {
      "name": "mem0-integration"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/mem0-integration"
      }
    }
    {
      "name": "supabase-backend"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/supabase-backend"
      }
    }
    {
      "name": "nextjs-frontend"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/nextjs-frontend"
      }
    }
  ]
}
```

**Benefits**:
- ✅ Lightweight (just JSON + README, no plugin code)
- ✅ References master repo (no duplication)
- ✅ Easy to create new tech stacks
- ✅ Can pin specific plugin versions
- ✅ Clear, opinionated stack for specific use cases

---

## Building Tech Stack Marketplaces

### Step 1: Build Individual Plugins in Master Repo

All plugins are built in `ai-dev-marketplace/plugins/`:

```bash
cd ai-dev-marketplace/

# Build SDK plugins
/domain-plugin-builder:plugin-create vercel-ai-sdk "Modular Vercel AI SDK plugin"
/domain-plugin-builder:plugin-create claude-agent-sdk "Claude Agent SDK plugin"
/domain-plugin-builder:plugin-create mem0-integration "Mem0 memory integration"

# Build backend plugins
/domain-plugin-builder:plugin-create supabase-backend "Supabase backend setup"
/domain-plugin-builder:plugin-create postgres-backend "PostgreSQL backend"

# Build frontend plugins
/domain-plugin-builder:plugin-create nextjs-frontend "Next.js frontend scaffold"
/domain-plugin-builder:plugin-create shadcn-ui "Shadcn UI components"

# Commit and push to master repo
git add plugins/
git commit -m "Add new plugins for tech stacks"
git push origin master
```

**Result**: All plugins live in `ai-dev-marketplace/plugins/` and are available via GitHub.

### Step 2: Create Tech Stack Marketplace Repository

Create a new lightweight repository for your tech stack:

```bash
# Create new repo
mkdir ai-tech-stack-1-marketplace
cd ai-tech-stack-1-marketplace

# Create marketplace structure
mkdir -p .claude-plugin
touch .claude-plugin/marketplace.json
touch README.md

# Initialize git
git init
git add .
git commit -m "Initial tech stack marketplace"
git remote add origin https://github.com/vanman2024/ai-tech-stack-1-marketplace.git
git push -u origin main
```

### Step 3: Write marketplace.json

Create `.claude-plugin/marketplace.json` that references plugins from master repo:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json"
  "name": "ai-tech-stack-1"
  "version": "1.0.0"
  "description": "Production-ready AI tech stack: TypeScript + Next.js + Vercel AI SDK + Supabase + Mem0"
  "owner": {
    "name": "Your Name"
    "email": "your@email.com"
  }
  "plugins": [
    {
      "name": "vercel-ai-sdk"
      "description": "Modular Vercel AI SDK with feature bundles"
      "version": "1.0.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/vercel-ai-sdk"
      }
      "category": "ai-sdk"
      "keywords": ["vercel", "ai", "sdk", "streaming", "rag"]
    }
    {
      "name": "mem0-integration"
      "description": "Mem0 memory management integration"
      "version": "1.0.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/mem0-integration"
      }
      "category": "integration"
      "keywords": ["mem0", "memory", "context"]
    }
    {
      "name": "supabase-backend"
      "description": "Supabase backend setup and integration"
      "version": "1.0.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/supabase-backend"
      }
      "category": "backend"
      "keywords": ["supabase", "database", "auth", "storage"]
    }
    {
      "name": "nextjs-frontend"
      "description": "Next.js frontend with React and TypeScript"
      "version": "1.0.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/nextjs-frontend"
      }
      "category": "frontend"
      "keywords": ["nextjs", "react", "typescript", "frontend"]
    }
    {
      "name": "shadcn-ui"
      "description": "Shadcn UI component library"
      "version": "1.0.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/shadcn-ui"
      }
      "category": "ui"
      "keywords": ["shadcn", "ui", "components", "tailwind"]
    }
  ]
}
```

**Key Points**:
- Each plugin entry uses `"source": {"source": "github", "repo": "...", "path": "..."}` to reference master repo
- No plugin code is duplicated
- Can pin specific versions by referencing git tags/commits
- Metadata (description, keywords, category) helps with discovery

### Step 4: Write README

Document the tech stack in `README.md`:

```markdown
# AI Tech Stack 1 - TypeScript Full Stack

Production-ready AI application tech stack with modern TypeScript, Next.js, and best-in-class AI tools.

## Stack Overview

- **AI SDK**: Vercel AI SDK (streaming, tools, chat, RAG)
- **Memory**: Mem0 (conversation memory, context persistence)
- **Backend**: Supabase (database, auth, storage, edge functions)
- **Frontend**: Next.js 15 + React 19 + TypeScript
- **UI**: Shadcn UI + Tailwind CSS
- **Language**: TypeScript

## Installation

```bash
# Add this tech stack marketplace
/plugin marketplace add vanman2024/ai-tech-stack-1-marketplace

# Install all plugins (project-scoped)
/plugin install vercel-ai-sdk@ai-tech-stack-1 --project
/plugin install mem0-integration@ai-tech-stack-1 --project
/plugin install supabase-backend@ai-tech-stack-1 --project
/plugin install nextjs-frontend@ai-tech-stack-1 --project
/plugin install shadcn-ui@ai-tech-stack-1 --project
```

## Quick Start

```bash
# 1. Create new Next.js app with Vercel AI SDK
/vercel-ai-sdk:new-app my-ai-app

# 2. Set up Supabase backend
/supabase-backend:create-project

# 3. Integrate Mem0 for memory
/mem0-integration:setup

# 4. Add Shadcn UI components
/shadcn-ui:init

# 5. Add AI features
/vercel-ai-sdk:add-streaming
/vercel-ai-sdk:add-chat
/vercel-ai-sdk:add-rag
```

## Use Cases

- AI chatbots with memory
- RAG applications with knowledge bases
- Full-stack AI SaaS products
- Internal AI tools and dashboards

## Plugins Included

| Plugin | Purpose | Version |
|:-------|:--------|:--------|
| vercel-ai-sdk | AI SDK with streaming, tools, chat, RAG | 1.0.0 |
| mem0-integration | Conversation memory and context | 1.0.0 |
| supabase-backend | Database, auth, storage | 1.0.0 |
| nextjs-frontend | Next.js + React frontend | 1.0.0 |
| shadcn-ui | UI component library | 1.0.0 |

## Swapping Components

You can swap individual components:

```bash
# Swap Vercel AI SDK for OpenAI SDK
/plugin uninstall vercel-ai-sdk
/plugin marketplace add vanman2024/ai-dev-marketplace
/plugin install openai-sdk-direct@ai-dev-marketplace --project

# Swap Supabase for PostgreSQL
/plugin uninstall supabase-backend
/plugin install postgres-backend@ai-dev-marketplace --project
```

## License

MIT
```

### Step 5: Push and Distribute

```bash
git add .
git commit -m "Complete tech stack 1 marketplace"
git push origin main
```

**Users can now install:**
```bash
/plugin marketplace add vanman2024/ai-tech-stack-1-marketplace
/plugin install vercel-ai-sdk@ai-tech-stack-1 --project
```

---

## Example Tech Stacks

### Tech Stack 1: TypeScript Full Stack (AI SaaS)

**The Kitchen Setup** 🏠

**Use Case**: Production AI chatbots, RAG apps, AI SaaS products

**The Kitchen (Foundation)**:
- 🔥 Next.js 15 + React 19 (Cooking platform)
- 🌡️ Vercel AI SDK (AI orchestration)
- 🧊 Supabase (Database + Auth + Storage)
- 💾 Mem0 (Memory management)
- 🎨 shadcn/ui + Tailwind (Beautiful UI)
- 💳 Stripe (Payments)

**Specialized Appliances (Optional Extensions)**:
- ☕ Imagen/Veo (google-vertex-ai-mcp)
- 🍦 DALL-E (openai-dalle-mcp)
- 🎵 ElevenLabs (audio-generation-mcp)

**Analogy**: This is like a **restaurant kitchen** - complete foundation for cooking any dish (building any AI app), with specialized equipment available when needed.

**Ideal For**:
- AI-powered SaaS products
- Customer-facing AI chatbots
- Internal AI tools with authentication
- Marketing automation systems
- Content generation platforms

---

### Tech Stack 2: Python Backend (AI APIs)

**The Kitchen Setup** 🏠

**Use Case**: AI API services, microservices, data processing

**The Kitchen (Foundation)**:
- 🔥 FastAPI (Python API platform)
- 🌡️ LangChain (AI orchestration)
- 🧊 PostgreSQL (Database)
- 💾 Redis (Caching)
- 🔧 Celery (Background tasks)

**Specialized Appliances (Optional Extensions)**:
- ☕ OpenAI direct integration
- 🥩 Custom ML model serving
- 📊 Data pipeline tools

**Analogy**: This is like a **commercial bakery kitchen** - specialized for high-volume production (APIs at scale), with industrial equipment for specific outputs.

**Ideal For**:
- AI API endpoints
- Data processing pipelines
- Microservices architecture
- ML model serving

---

### Tech Stack 3: Agent Framework (Autonomous AI)

**The Kitchen Setup** 🏠

**Use Case**: Autonomous AI agents, multi-step reasoning, complex workflows

**The Kitchen (Foundation)**:
- 🔥 Claude Agent SDK (Agent platform)
- 🌡️ Anthropic API (Claude models)
- 🧊 Supabase (State persistence)
- 💾 Mem0 (Agent memory)
- 🔧 LangChain (Orchestration)

**Specialized Appliances (Optional Extensions)**:
- 🔍 Web scraping tools
- 📧 Email automation
- 📊 Analytics integrations

**Analogy**: This is like a **test kitchen with robotic assistants** - autonomous systems that can cook entire meals on their own (multi-step AI workflows).

**Ideal For**:
- Autonomous AI agents
- Multi-step reasoning systems
- Complex AI workflows
- Research assistants

---

### Tech Stack 4: Local-First AI (Privacy-Focused)

**The Kitchen Setup** 🏠

**Use Case**: On-premise AI, privacy-sensitive applications

**The Kitchen (Foundation)**:
- 🔥 Ollama (Local LLMs)
- 🌡️ Local model serving
- 🧊 SQLite (Local database)
- 💾 ChromaDB (Local vectors)
- 🎨 React (Simple frontend)

**Specialized Appliances (Optional Extensions)**:
- 🔒 On-premise image generation
- 🗂️ Local document processing

**Analogy**: This is like a **home kitchen** - everything runs locally, no cloud dependencies, complete privacy (air-gapped cooking).

**Ideal For**:
- Healthcare applications
- Financial services
- Privacy-focused products
- Air-gapped environments

---

### Creating Your Own Tech Stack: The Kitchen Builder 🔧

**Step 1: Choose Your Kitchen Size**

```bash
# Small Kitchen (Startup/MVP)
- Next.js + Vercel AI SDK + Supabase free tier
- Cost: $0-$60/month
- Serves: 1-1000 users

# Medium Kitchen (Growing SaaS)
- Next.js + Vercel AI SDK + Supabase Pro + Claude API
- Cost: $200-$1000/month
- Serves: 1000-50,000 users

# Large Kitchen (Enterprise)
- Next.js + Vercel AI SDK + Supabase Enterprise + Multi-model
- Cost: $2000+/month
- Serves: 50,000+ users
```

**Step 2: Add Your Specialized Appliances**

```bash
# For image generation (add espresso machine)
npm install @google-cloud/aiplatform

# For video generation (add sous vide)
npm install video-generation-sdk

# For audio (add tea set)
npm install elevenlabs-sdk

# For custom domain tools (add bread maker)
# Build custom MCP server
```

**Step 3: Document Your Recipe**

```markdown
# My Custom Tech Stack

## The Kitchen (Foundation)
- [List your base components]

## Specialized Appliances (Extensions)
- [List your domain-specific tools]

## Recipe (Quick Start)
1. Initialize foundation
2. Add extensions
3. Configure
4. Build features
```

---

## Swapping and Mixing Components

### Swap Individual Components

Users can swap out components from your tech stack:

```bash
# Start with Tech Stack 1
/plugin marketplace add vanman2024/ai-tech-stack-1-marketplace
/plugin install vercel-ai-sdk@ai-tech-stack-1 --project

# But swap the AI SDK for direct OpenAI
/plugin uninstall vercel-ai-sdk
/plugin marketplace add vanman2024/ai-dev-marketplace
/plugin install openai-sdk-direct@ai-dev-marketplace --project
```

### Offer Alternatives in Your Stack

Include alternative plugins in your marketplace for flexibility:

```json
{
  "plugins": [
    {
      "name": "vercel-ai-sdk"
      "description": "AI SDK (Recommended for full-stack apps)"
      "source": {"source": "github", "repo": "...", "path": "plugins/vercel-ai-sdk"}
    }
    {
      "name": "openai-sdk-direct"
      "description": "AI SDK Alternative: Direct OpenAI integration"
      "source": {"source": "github", "repo": "...", "path": "plugins/openai-sdk-direct"}
    }
    {
      "name": "supabase-backend"
      "description": "Backend (Recommended for rapid development)"
      "source": {"source": "github", "repo": "...", "path": "plugins/supabase-backend"}
    }
    {
      "name": "postgres-backend"
      "description": "Backend Alternative: Self-hosted PostgreSQL"
      "source": {"source": "github", "repo": "...", "path": "plugins/postgres-backend"}
    }
  ]
}
```

Users can then choose which variant to install.

---

## Version Pinning

Pin specific plugin versions in your tech stack:

```json
{
  "plugins": [
    {
      "name": "vercel-ai-sdk"
      "version": "1.2.0"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/vercel-ai-sdk"
        "ref": "v1.2.0"
      }
    }
  ]
}
```

**Benefits**:
- Ensures compatibility within your stack
- Prevents breaking changes
- Can upgrade versions in controlled manner

---

## Workflow Summary

### 1. Build Plugins (Master Repo)

```bash
cd ai-dev-marketplace/
/domain-plugin-builder:plugin-create my-new-plugin "Description"
git add plugins/my-new-plugin/
git commit -m "Add my-new-plugin"
git push
```

### 2. Create Tech Stack Marketplace

```bash
mkdir ai-tech-stack-N-marketplace
cd ai-tech-stack-N-marketplace
mkdir .claude-plugin
# Create marketplace.json (references master repo plugins)
# Create README.md (documents the stack)
git init && git push
```

### 3. Users Install

```bash
/plugin marketplace add vanman2024/ai-tech-stack-N-marketplace
/plugin install plugin-name@ai-tech-stack-N --project
```

---

## Hybrid Documentation Pattern

### The Problem: Static vs. On-Demand Documentation

**Static Documentation** (`docs/` folder in plugin):
- ✅ Version-controlled with plugin
- ✅ Works offline
- ✅ Curated and vetted content
- ❌ Can become outdated as SDKs evolve
- ❌ Requires manual updates

**Context7 On-Demand** (MCP server):
- ✅ Always up-to-date with latest SDK changes
- ✅ No manual doc maintenance
- ✅ Fetches directly from official sources
- ❌ Requires internet connection
- ❌ Not version-controlled
- ❌ Pulls raw docs (may need filtering)

**Solution: Use BOTH!**

### Hybrid Documentation Strategy

Each tech plugin should include:

```
vercel-ai-sdk/
├── docs/
│   ├── vercel-ai-sdk-overview.md         ← Static: Curated intro/concepts
│   ├── architecture-guide.md             ← Static: How to use the plugin
│   ├── api-reference-links.md            ← Static: Links for Context7
│   └── examples/
│       ├── basic-chatbot.md              ← Static: Curated examples
│       └── rag-implementation.md
├── commands/
│   ├── init.md                           ← Uses STATIC docs
│   ├── new-app.md                        ← Uses STATIC docs
│   └── add-feature.md                    ← Uses Context7 for latest API
```

### When to Use Each

**Use Static Docs For:**
- Plugin initialization (`/plugin:init`)
- Foundational concepts and architecture
- Curated examples and tutorials
- Quick reference guides
- Offline usage

**Use Context7 For:**
- Implementing new features (`/plugin:add-feature`)
- Checking latest API changes
- Getting detailed method signatures
- Exploring new SDK capabilities
- When you need the absolute latest info

### Implementation Example

**Command: `/vercel-ai-sdk:init`** (Uses Static Docs)

```markdown
---
description: Initialize Vercel AI SDK in your project
allowed-tools: Read(*), Write(*), Bash(*), Glob(*)
---

Phase 1: Load Core Documentation
Goal: Understand Vercel AI SDK fundamentals

Actions:
- Read plugin's curated documentation:
  - @plugins/vercel-ai-sdk/docs/vercel-ai-sdk-overview.md
  - @plugins/vercel-ai-sdk/docs/architecture-guide.md
- This provides foundation, concepts, and plugin usage patterns
- Works offline, version-controlled, curated content

Phase 2: Project Setup
Goal: Install and configure Vercel AI SDK

Actions:
- Install packages based on docs
- Create config files
- Set up environment variables
```

**Command: `/vercel-ai-sdk:add-streaming`** (Uses Context7)

```markdown
---
description: Add streaming capability to your app
allowed-tools: Task, Read(*), Write(*), Bash(*), mcp__context7__*
---

Phase 1: Fetch Latest Streaming Documentation
Goal: Get up-to-date API reference for streaming

Actions:
- Use Context7 to fetch latest docs:
  - mcp__context7__get-library-docs('/vercel/ai-sdk', topic: 'streaming')
  - This ensures we have the latest streaming API
- Read local examples for patterns:
  - @plugins/vercel-ai-sdk/docs/examples/streaming-implementation.md

Phase 2: Detect Framework
Goal: Determine which streaming approach to use

Actions:
- Check package.json for framework
- Choose appropriate API (streamText vs useChat)

Phase 3: Implement Streaming
Goal: Add streaming using latest API from Context7

Actions:
- Invoke the general-purpose agent to implement streaming
- Agent uses the Context7 docs fetched in Phase 1
- Agent references local examples for patterns
```

### Plugin Documentation Structure

**Recommended `docs/` folder structure:**

```
plugins/your-plugin/docs/
├── README.md                          ← Quick start
├── overview.md                        ← Concepts, architecture
├── installation.md                    ← Setup guide
├── api-reference-links.md             ← URLs for Context7
├── examples/
│   ├── 01-basic-setup.md
│   ├── 02-advanced-features.md
│   └── 03-production-ready.md
├── troubleshooting.md                 ← Common issues
└── changelog.md                       ← Version history
```

**`api-reference-links.md` example:**

```markdown
# API Reference Links (For Context7)

## Core Documentation
- Context7 Library ID: `/vercel/ai-sdk`
- Homepage: https://ai-sdk.dev

## Topics for Context7
- Streaming: `topic: 'streaming'`
- Tools: `topic: 'tools'`
- Chat: `topic: 'chat'`
- RAG: `topic: 'rag'`
- Embeddings: `topic: 'embeddings'`

## Usage in Commands
\`\`\`
mcp__context7__get-library-docs('/vercel/ai-sdk', topic: 'streaming')
\`\`\`
```

### Benefits of Hybrid Approach

✅ **Best of both worlds**: Curated stability + on-demand freshness
✅ **Offline capable**: Core functionality works without internet
✅ **Always current**: Features use latest API docs
✅ **Reduced maintenance**: Don't need to update all docs constantly
✅ **Clear separation**: Init uses static, features use Context7

---

## Plugin Initialization Pattern

### The Three-Phase Initialization

When building tech-specific plugins that integrate SDKs or frameworks, follow this initialization pattern:

```markdown
# Command: /plugin-name:init

Phase 1: Load Static Curated Documentation
Goal: Understand core concepts and plugin architecture

Actions:
- Read plugin's curated docs:
  - @plugins/plugin-name/docs/overview.md
  - @plugins/plugin-name/docs/architecture-guide.md
- Provides: Concepts, design patterns, plugin-specific workflows
- Why: Curated, stable, offline-accessible foundation

Phase 2: Fetch Latest API Documentation
Goal: Get current API reference and latest features

Actions:
- Use Context7 to fetch up-to-date docs:
  - mcp__context7__resolve-library-id('library-name')
  - mcp__context7__get-library-docs('/org/library')
- Provides: Latest API methods, breaking changes, new features
- Why: Ensures compatibility with current SDK version

Phase 3: Project Setup & Integration
Goal: Install, configure, and integrate into project

Actions:
- Detect existing project structure (package.json, etc.)
- Install required packages
- Create configuration files
- Set up environment variables
- Add example code/templates
- Run verification checks
```

### Example: Claude Agent SDK Initialization

```markdown
# /claude-agent-sdk:init

**Arguments**: $ARGUMENTS

Goal: Initialize Claude Agent SDK in your project with latest documentation

Phase 1: Load Core Concepts
Goal: Understand Claude Agent SDK architecture

Actions:
- Read curated plugin documentation:
  - @plugins/claude-agent-sdk/docs/claude-agent-sdk-overview.md
  - @plugins/claude-agent-sdk/docs/agent-patterns.md
- Understand: Agent lifecycles, tool calling, state management
- Review example agents from docs/examples/

Phase 2: Fetch Latest API Reference
Goal: Get current Claude SDK API documentation

Actions:
- Resolve Claude SDK library ID:
  - mcp__context7__resolve-library-id('anthropic-sdk-typescript')
- Fetch latest API docs:
  - mcp__context7__get-library-docs('/anthropic/anthropic-sdk-typescript')
- Get agent-specific docs:
  - mcp__context7__get-library-docs('/anthropic/anthropic-sdk-typescript', topic: 'agents')

Phase 3: Project Setup
Goal: Install and configure Claude Agent SDK

Actions:
- Detect project type (TypeScript/JavaScript/Python)
- Install packages:
  - TypeScript: @anthropic-ai/sdk, @anthropic-ai/agent-sdk
  - Python: anthropic, anthropic-agent-sdk
- Create config file: claude-agent.config.json
- Set up environment variables (.env):
  - ANTHROPIC_API_KEY
  - AGENT_MAX_ITERATIONS
- Create example agent: agents/example-agent.ts
- Run verification: Test API connection

Phase 4: Verification
Goal: Ensure successful setup

Actions:
- Run test agent
- Verify API key works
- Check dependencies installed
- Provide next steps
```

### When to Use Initialization Pattern

Use this pattern when:
- ✅ Plugin integrates an external SDK or framework
- ✅ Users need foundational knowledge before using the plugin
- ✅ Setup requires both static docs (concepts) AND latest docs (API)
- ✅ Project configuration is complex

Don't use for:
- ❌ Simple utility plugins (no SDK integration)
- ❌ Plugins with no external dependencies
- ❌ Commands that add single features (use direct Context7)

### Best Practices for Initialization

**Do:**
- ✅ Load static docs first (concepts, architecture)
- ✅ Fetch latest API docs second (current reference)
- ✅ Provide clear "next steps" after initialization
- ✅ Include example code/templates
- ✅ Verify setup works before completing

**Don't:**
- ❌ Fetch ALL docs upfront (overwhelming, slow)
- ❌ Skip static docs (users need foundation)
- ❌ Assume project structure (detect and adapt)
- ❌ Leave users without next steps

---

## Best Practices

### For Plugin Development (Master Repo)

- ✅ Build all plugins in `ai-dev-marketplace/plugins/`
- ✅ Use domain-plugin-builder for consistency
- ✅ Test plugins before committing
- ✅ Use semantic versioning
- ✅ Document plugins thoroughly
- ✅ Tag releases for version pinning

### For Tech Stack Curation

- ✅ Keep marketplace repos lightweight (JSON + README only)
- ✅ Document the stack's use case clearly
- ✅ Explain plugin choices (why Vercel AI vs OpenAI)
- ✅ Provide quick start guide
- ✅ List alternatives for swappable components
- ✅ Pin versions for stability
- ✅ Update regularly as plugins evolve

### For Users

- ✅ Use project-scoped installation (`--project`)
- ✅ Install only what you need
- ✅ Understand you can swap components
- ✅ Check tech stack README for recommended workflow
- ✅ Report issues to marketplace maintainer

---

## Plugins as Extensions: The Compilation Pattern

### The Core Insight

**Extensions don't have to be separate MCP servers** - they can be **Claude Code plugins** that wrap MCP servers, skills, agents, and commands into reusable packages.

### The Plugin-as-Extension Pattern

```
The 5-10% Domain-Specific Work → Build as Plugins → Reusable Everywhere
```

**Once you build domain functionality as a plugin, it becomes an extension for ANY project.**

#### Example: Building the Google Vertex AI Extension

**Step 1: Build the MCP Server** (the 5-10% domain logic)

```bash
# Separate repository
google-vertex-ai-mcp-server/
├── pyproject.toml
├── src/
│   └── main.py              # FastMCP server with Imagen/Veo tools
└── tools/
    ├── imagen.py            # Image generation
    └── veo.py               # Video generation
```

**Step 2: Build the Plugin** (wraps the MCP server + adds commands/skills/docs)

```bash
# In ai-dev-marketplace/plugins/
/domain-plugin-builder:plugin-create google-vertex-ai \
  "Image and video generation with Google Vertex AI"

# Result:
plugins/google-vertex-ai/
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md              # Setup the MCP server
│   ├── generate-image.md    # Use Imagen
│   ├── generate-video.md    # Use Veo
│   └── batch-generate.md    # Batch operations
├── agents/
│   └── media-generator.md   # Specialized agent
├── skills/
│   ├── imagen-prompting/    # Image prompt best practices
│   └── veo-prompting/       # Video prompt structure
├── docs/
│   ├── overview.md
│   ├── pricing.md
│   └── examples/
└── .mcp.json                # Points to external MCP server
```

**Step 3: Now It's Reusable Everywhere**

```bash
# Marketing Automation App
cd ~/marketing-automation
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:generate-image "product hero shot"

# E-commerce Platform
cd ~/ecommerce-platform
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:batch-generate 50 product images

# Social Media Tool
cd ~/social-media-tool
/plugin install google-vertex-ai@ai-dev-marketplace --project
/google-vertex-ai:generate-video "product demo 10 seconds"
```

### Composing Tech Stacks from Plugin Extensions

**The Kitchen + Appliances Model in Practice:**

```bash
# Foundation (AI Tech Stack 1) - 90-95%
/ai-tech-stack-1:init my-app
# Installs: Next.js, Vercel AI SDK, Supabase, Mem0, FastMCP

# Extensions (Plugins) - 5-10%
/plugin install google-vertex-ai@ai-dev-marketplace --project
/plugin install elevenlabs-audio@ai-dev-marketplace --project
/plugin install sendgrid-campaigns@ai-dev-marketplace --project
/plugin install stripe-advanced@ai-dev-marketplace --project

# Result: Complete app assembled from modular pieces
```

### The 5-10% Domain Plugin Library

Build domain-specific functionality as plugins once, use everywhere:

```
ai-dev-marketplace/plugins/           ← Master repository

Foundation Plugins (90-95%):
├── vercel-ai-sdk/                    ← Core AI SDK
├── mem0-integration/                 ← Memory
├── supabase-backend/                 ← Database
├── nextjs-frontend/                  ← Frontend
└── fastmcp/                          ← Tool framework

Extension Plugins (5-10%):
├── google-vertex-ai/                 ← Images/videos
├── openai-dalle/                     ← Alternative images
├── elevenlabs-audio/                 ← Audio generation
├── sendgrid-campaigns/               ← Email marketing
├── stripe-advanced/                  ← Complex payments
├── analytics-dashboard/              ← Custom analytics
├── social-media-apis/                ← Social publishing
├── inventory-management/             ← E-commerce
└── custom-ml-models/                 ← Your ML models
```

**Each extension plugin:**
- ✅ Contains commands, agents, skills, docs
- ✅ References external MCP server (if needed)
- ✅ Can be installed project-scoped
- ✅ Works with ANY foundation (not just AI Tech Stack 1)
- ✅ Reusable across unlimited projects

### Real-World Compilation Examples

#### Example 1: Marketing Automation System

```bash
# Foundation (Kitchen)
/ai-tech-stack-1:init marketing-automation

# Extensions (Appliances)
/plugin install google-vertex-ai --project        # Images/videos
/plugin install claude-agent-sdk --project        # Multi-agent workflows
/plugin install sendgrid-campaigns --project      # Email automation
/plugin install analytics-dashboard --project     # Tracking

# Result:
Kitchen: $60-$200/month (fixed)
Appliances: $0.02-$0.50 per asset (usage-based)
Build time: 3 days setup + 2 weeks features = < 3 weeks total
```

#### Example 2: E-commerce Product Studio

```bash
# Foundation
/ai-tech-stack-1:init product-studio

# Extensions
/plugin install google-vertex-ai --project        # Product photos
/plugin install openai-dalle --project            # Alternative images
/plugin install inventory-management --project    # Stock tracking
/plugin install stripe-advanced --project         # Payments

# Result:
Complete product photo generation + management system
Assembled from pre-built, tested plugins
```

#### Example 3: Social Media Management Platform

```bash
# Foundation
/ai-tech-stack-1:init social-platform

# Extensions
/plugin install google-vertex-ai --project        # Images/videos
/plugin install elevenlabs-audio --project        # Voiceovers
/plugin install social-media-apis --project       # Publishing
/plugin install analytics-dashboard --project     # Performance tracking

# Result:
Full social media automation platform
Using modular, swappable components
```

### Benefits of Plugin-Based Extensions

**1. Build Once, Use Everywhere** 🔄
```bash
# Build the plugin once (1-2 days)
/domain-plugin-builder:plugin-create my-extension

# Use in unlimited projects (minutes)
cd ~/any-project
/plugin install my-extension@ai-dev-marketplace --project
```

**2. True Modularity** 🧩
- Each plugin is self-contained
- Clear dependencies
- Can be swapped easily
- Version controlled independently

**3. Easy Distribution** 📦
- Publish to ai-dev-marketplace once
- Available to all users via GitHub
- Centralized updates and bug fixes

**4. Mix and Match** 🎨
```bash
# Use different combinations for different projects
Project A: AI Stack 1 + Imagen + SendGrid
Project B: AI Stack 1 + DALL-E + Stripe
Project C: AI Stack 1 + Imagen + Audio + Analytics
```

**5. Rapid Development** ⚡
- Foundation: 90-95% ready (days)
- Extensions: 5-10% plugin install (minutes)
- Focus time on unique business logic

### Creating Extension Plugins: The Template

**Standard extension plugin structure:**

```
plugins/your-extension/
├── .claude-plugin/
│   └── plugin.json           # Metadata
│
├── commands/
│   ├── init.md               # "Setup this extension"
│   ├── use-feature.md        # "Use the main feature"
│   └── configure.md          # "Configure settings"
│
├── agents/                   # Optional: Specialized agents
│   └── specialist.md
│
├── skills/                   # Optional: Domain knowledge
│   └── best-practices/
│       ├── SKILL.md
│       ├── examples.md
│       └── reference.md
│
├── docs/
│   ├── overview.md           # What this does
│   ├── integration.md        # How to integrate
│   ├── api-reference.md      # API documentation
│   └── examples/             # Real usage examples
│
├── .mcp.json                 # Optional: MCP server config
│   {
│     "mcpServers": {
│       "your-extension": {
│         "command": "python"
│         "args": ["-m", "your-extension-mcp"]
│       }
│     }
│   }
│
└── README.md                 # Quick start
```

### The Compilation Workflow

**How teams build complete applications:**

```bash
# Day 1: Foundation
/ai-tech-stack-1:init new-project
# Result: Complete Next.js + AI + Database setup

# Day 2: Add Extensions
/plugin install extension-a@ai-dev-marketplace --project
/plugin install extension-b@ai-dev-marketplace --project
/plugin install extension-c@ai-dev-marketplace --project
# Result: All domain-specific tools ready

# Days 3-14: Build Features
/extension-a:generate-assets
/extension-b:configure-workflow
/extension-c:setup-integration
# Result: Unique business logic using pre-built tools

# Day 15: Deploy
/deploy:prepare
/deploy:run vercel
# Result: Production app live
```

### Extension Plugin Categories

**Organize extensions by category:**

```bash
# Media Generation
plugins/google-vertex-ai/         # Images + Videos
plugins/openai-dalle/             # Alternative images
plugins/elevenlabs-audio/         # Audio + Voice
plugins/runway-video/             # Alternative videos

# Marketing & Communication
plugins/sendgrid-campaigns/       # Email marketing
plugins/social-media-apis/        # Social publishing
plugins/sms-campaigns/            # SMS automation
plugins/notification-center/      # Multi-channel notifications

# Payments & Commerce
plugins/stripe-advanced/          # Complex payment flows
plugins/paypal-integration/       # Alternative payment
plugins/inventory-management/     # Stock tracking
plugins/order-fulfillment/        # Shipping automation

# Analytics & Monitoring
plugins/analytics-dashboard/      # Custom analytics
plugins/ab-testing/               # Experimentation
plugins/user-tracking/            # Behavior tracking
plugins/performance-monitoring/   # System health

# AI & ML
plugins/claude-agent-sdk/         # Multi-agent workflows
plugins/langchain-advanced/       # Complex chains
plugins/custom-ml-models/         # Your trained models
plugins/vector-search/            # Advanced RAG
```

### From Monolith to Modular

**Traditional approach** ❌:
```bash
# Build everything from scratch
- 2 weeks: Next.js setup
- 1 week: Database setup
- 1 week: Authentication
- 2 weeks: AI integration
- 2 weeks: Image generation
- 1 week: Video generation
- 1 week: Email system
- 2 weeks: Payment system
= 12 weeks before building features
```

**Plugin composition approach** ✅:
```bash
# Assemble from pre-built plugins
- 1 day: /ai-tech-stack-1:init
- 1 hour: /plugin install google-vertex-ai
- 1 hour: /plugin install sendgrid-campaigns
- 1 hour: /plugin install stripe-advanced
= 1 day infrastructure, 11 weeks building features
```

### Summary: The Compilation Pattern

**The Vision:**
1. **Build the foundation once** (AI Tech Stack 1) - 90-95% reusable
2. **Build domain plugins once** (Extensions) - 5-10% domain-specific
3. **Compile projects rapidly** - Mix and match plugins as needed

**The Reality:**
- ✅ Foundation plugins: Stable, production-ready, well-tested
- ✅ Extension plugins: Domain-specific, modular, swappable
- ✅ Tech stacks: Curated combinations for specific use cases
- ✅ Projects: Assembled in days, not months

**The Result:**
A **plugin ecosystem** where every piece is reusable, composable, and production-ready. Build the 5-10% domain-specific logic as plugins, then use them everywhere! 🚀

---

## Real-World Example: Marketing Automation Extensions

### The Two Plugins Needed

For the **AI Marketing Automation System**, you only need **two extension plugins** (5% of the total system):

#### Plugin 1: google-imagen ☕ (The Espresso Machine)

```bash
plugins/google-imagen/
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md                    # "Setup Imagen API"
│   ├── generate-image.md          # "Generate single image"
│   ├── batch-generate.md          # "Generate multiple images"
│   └── style-transfer.md          # "Apply brand style"
├── skills/
│   └── imagen-prompting/
│       ├── SKILL.md               # Imagen prompt engineering
│       ├── examples.md            # 50+ example prompts
│       └── reference.md           # Imagen 3/4 features
├── docs/
│   ├── overview.md                # What Imagen can do
│   ├── pricing.md                 # $0.02-$0.06 per image
│   ├── models.md                  # Imagen 3, 4, Fast, Ultra
│   └── examples/
│       ├── product-photography.md
│       ├── hero-backgrounds.md
│       └── social-media-graphics.md
└── .mcp.json                      # Points to imagen-mcp-server
```

**What it provides**:
- ✅ Generate product images ($0.02-$0.06 each)
- ✅ Hero backgrounds, feature illustrations
- ✅ Social media graphics (1:1, 16:9, 9:16)
- ✅ Brand-consistent style across all images
- ✅ Batch generation (200 req/min with Fast model)

#### Plugin 2: google-veo 🎬 (The Sous Vide)

```bash
plugins/google-veo/
├── .claude-plugin/plugin.json
├── commands/
│   ├── init.md                    # "Setup Veo API"
│   ├── generate-video.md          # "Generate video"
│   ├── add-audio.md               # "Add synchronized audio"
│   └── batch-videos.md            # "Generate multiple videos"
├── skills/
│   └── veo-prompting/
│       ├── SKILL.md               # 8-component video prompts
│       ├── examples.md            # Video prompt templates
│       └── reference.md           # Veo 2/3 capabilities
├── docs/
│   ├── overview.md                # What Veo can do
│   ├── pricing.md                 # $0.10-$0.50 per second
│   ├── models.md                  # Veo 2, 3, Fast variants
│   └── examples/
│       ├── product-demos.md
│       ├── testimonials.md
│       └── explainer-videos.md
└── .mcp.json                      # Points to veo-mcp-server
```

**What it provides**:
- ✅ Generate marketing videos ($0.10-$0.50 per second)
- ✅ Product demos, testimonials, explainers
- ✅ Synchronized audio with perfect lip-sync (Veo 3)
- ✅ Cinematic quality (1080p, 24-30 fps)
- ✅ Fast iteration for rapid content creation

### Assembly Instructions

```bash
# Step 1: Initialize Foundation (95%)
/ai-tech-stack-1:init marketing-automation
# Installs: Next.js, Vercel AI SDK, Supabase, Mem0, FastMCP, Stripe

# Step 2: Add the Two Extension Plugins (5%)
/plugin install google-imagen@ai-dev-marketplace --project
/plugin install google-veo@ai-dev-marketplace --project

# Step 3: Initialize Extensions
/google-imagen:init
/google-veo:init

# Step 4: Generate Marketing Campaign
/google-imagen:batch-generate 25 "product shots, hero backgrounds, feature illustrations"
/google-veo:generate-video "10 second product demo with audio"
/google-veo:generate-video "customer testimonial 8 seconds"

# Result: Complete marketing automation system
# Foundation: $60-$200/month (fixed)
# Extensions: $43.82 per product launch (usage-based)
```

### The Cost Breakdown

**Foundation (AI Tech Stack 1) - 95%**:
| Component | Monthly Cost |
|-----------|--------------|
| Vercel | $0 - $20 |
| Supabase | $0 - $25 |
| Claude API | $50 - $500+ |
| Mem0 | $0 (self-hosted) |
| **Foundation Total** | **$50 - $545/month** |

**Extensions (Two Plugins) - 5%**:
| Component | Per Launch Cost |
|-----------|-----------------|
| Imagen (25 images) | $0.50 - $1.50 |
| Veo (2 videos, 20 sec) | $2.00 - $10.00 |
| Text generation | $0.05 |
| Website deployment | $1.27 |
| **Extensions Total** | **$3.82 - $12.82 per launch** |

**Total System**:
- Infrastructure: $50-$545/month (unlimited launches)
- Per Launch: $3.82-$12.82 (scales with usage)

### Building These Plugins

**Option A: Two Separate Plugins** (recommended for modularity)

```bash
cd ai-dev-marketplace/plugins

# Build Imagen plugin
/domain-plugin-builder:plugin-create google-imagen \
  "Image generation with Imagen 3/4"

# Build Veo plugin
/domain-plugin-builder:plugin-create google-veo \
  "Video generation with Veo 2/3"

# Build two separate MCP servers
mkdir ../../imagen-mcp-server
mkdir ../../veo-mcp-server
```

**Benefits**:
- ✅ Can use Imagen without Veo (or vice versa)
- ✅ Independent versioning
- ✅ Clear separation of concerns
- ✅ Easier to swap alternatives (DALL-E for images, Sora for videos)

**Option B: Combined Plugin** (simpler for bundled usage)

```bash
cd ai-dev-marketplace/plugins

# Build combined plugin
/domain-plugin-builder:plugin-create google-vertex-ai \
  "Image and video generation with Google Vertex AI"

# Single MCP server with both tools
mkdir ../../google-vertex-ai-mcp-server
```

**Benefits**:
- ✅ Single installation
- ✅ Shared configuration (one API key)
- ✅ Coordinated updates
- ✅ Simpler for users

### Alternative: Pre-Built Tech Stack Marketplace

Create a curated marketplace with everything bundled:

```bash
# Create new tech stack repository
mkdir ai-tech-stack-marketing-automation
cd ai-tech-stack-marketing-automation
mkdir .claude-plugin
```

**File: `.claude-plugin/marketplace.json`**

```json
{
  "name": "ai-tech-stack-marketing-automation"
  "version": "1.0.0"
  "description": "Complete marketing automation: AI Stack 1 + Imagen + Veo"
  "plugins": [
    // Foundation (95%)
    {
      "name": "vercel-ai-sdk"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/vercel-ai-sdk"
      }
    }
    {
      "name": "mem0-integration"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/mem0-integration"
      }
    }
    {
      "name": "supabase-backend"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/supabase-backend"
      }
    }
    {
      "name": "nextjs-frontend"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/nextjs-frontend"
      }
    }
    // Extensions (5%)
    {
      "name": "google-imagen"
      "description": "Image generation extension"
      "category": "extension"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/google-imagen"
      }
    }
    {
      "name": "google-veo"
      "description": "Video generation extension"
      "category": "extension"
      "source": {
        "source": "github"
        "repo": "vanman2024/ai-dev-marketplace"
        "path": "plugins/google-veo"
      }
    }
  ]
}
```

**Then users install everything at once:**

```bash
# Add the curated marketplace
/plugin marketplace add vanman2024/ai-tech-stack-marketing-automation

# Install foundation + extensions in one command
/plugin install vercel-ai-sdk@marketing-automation --project
/plugin install mem0-integration@marketing-automation --project
/plugin install supabase-backend@marketing-automation --project
/plugin install nextjs-frontend@marketing-automation --project
/plugin install google-imagen@marketing-automation --project
/plugin install google-veo@marketing-automation --project

# Or use an orchestrator command (future enhancement)
/marketing-automation:setup
# Installs all 6 plugins automatically
```

### Swapping Extensions

Users can swap the image/video generation plugins:

```bash
# Using Imagen + Veo (Google)
/plugin install google-imagen --project
/plugin install google-veo --project

# Or swap for alternatives
/plugin uninstall google-imagen
/plugin install openai-dalle --project      # Alternative images

/plugin uninstall google-veo
/plugin install runway-video --project      # Alternative videos

# Foundation (AI Tech Stack 1) stays the same!
```

### The Plugin Ecosystem Vision

```
ai-dev-marketplace/plugins/

Foundation (90-95%):
├── vercel-ai-sdk/
├── mem0-integration/
├── supabase-backend/
├── nextjs-frontend/
└── fastmcp/

Media Generation Extensions (5-10%):
├── google-imagen/          ← Build these two!
├── google-veo/             ← Build these two!
├── openai-dalle/           ← Alternative
├── runway-video/           ← Alternative
├── elevenlabs-audio/       ← Audio extension
└── midjourney-images/      ← Alternative

Marketing Extensions:
├── sendgrid-campaigns/
├── social-media-apis/
└── analytics-dashboard/

Payment Extensions:
├── stripe-advanced/
└── paypal-integration/
```

**Result**: Build `google-imagen` and `google-veo` once (1-2 weeks), then use them in:
- ✅ Marketing automation systems
- ✅ E-commerce product studios
- ✅ Social media management tools
- ✅ Content generation platforms
- ✅ Any app needing images/videos

---

## Relationship to ai-dev-marketplace

**ai-dev-marketplace** (Master Repository):
- Contains ALL plugins (lifecycle, SDK, framework, build tools)
- Used directly for plugin development
- Can be added as a marketplace for accessing individual plugins
- Serves as the source for tech stack marketplaces

**Tech Stack Marketplaces** (Curated Collections):
- Reference plugins from ai-dev-marketplace
- Provide opinionated, tested combinations
- Easier for users to discover "golden paths"
- Can coexist with ai-dev-marketplace

**Users can use both:**
```bash
# Add master repo for individual plugins
/plugin marketplace add vanman2024/ai-dev-marketplace

# Add tech stack for curated experience
/plugin marketplace add vanman2024/ai-tech-stack-1-marketplace

# Mix and match as needed
```

---

## Next Steps

1. **Build individual plugins** in ai-dev-marketplace using domain-plugin-builder
2. **Create your first tech stack marketplace** for your most-used stack
3. **Document the stack** with clear use cases and quick start
4. **Share with your team** or publish publicly
5. **Iterate** based on feedback and usage

---

**See Also**:
- [Claude Code Plugins](./03-claude-code-plugins.md) - Plugin structure and components
- [Plugin Marketplaces](./04-plugin-marketplaces.md) - Marketplace creation and distribution
- [Domain Plugin Builder](../README.md) - Building plugins with the framework

---

**Purpose**: Architecture guide for building tech-stack-specific plugin marketplaces
**Load when**: Planning or creating curated tech stack collections
