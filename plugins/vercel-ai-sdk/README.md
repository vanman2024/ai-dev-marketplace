# Vercel AI SDK Plugin

Modular Vercel AI SDK development plugin with **feature bundles** and **specialized agents**. Build AI applications incrementally or all-at-once.

## Overview

This plugin helps you build Vercel AI SDK applications using **two approaches**:

### Incremental Approach (Modular)
1. Create minimal scaffold with `/vercel-ai-sdk:new-app`
2. Add core features one-by-one (streaming, tools, chat)
3. Add feature bundles as needed (UI, data, production, advanced)

### Full-Stack Approach (All-at-Once)
1. Run `/vercel-ai-sdk:build-full-stack`
2. Answer a few questions
3. Get a complete production-ready app with all features

**Why This Architecture?**
- **Manageable**: Feature bundles group related capabilities (4-7 URLs each)
- **Flexible**: Add only what you need, or build everything at once
- **Specialized Agents**: Each feature bundle has a dedicated agent that fetches docs as needed
- **Framework Agnostic**: Works with Next.js, React, Node.js, Python, etc.

## Commands

### 1. `/vercel-ai-sdk:new-app [project-name]`

**Purpose**: Create initial Vercel AI SDK project scaffold

**What it does:**
- Creates project directory and initializes framework
- Installs `ai` package + one AI provider
- Sets up environment variables
- Creates minimal working example
- **NO features** - just basic structure

**Fetches**: 4 URLs (intro, foundations, getting-started, provider)

**Example:**
```bash
/vercel-ai-sdk:new-app my-chatbot
```

**Then asks:**
- Language? (TypeScript, JavaScript, Python)
- Framework? (Next.js, React, Node.js, etc.)
- AI Provider? (OpenAI, Anthropic, Google, xAI)

**Creates:** Working scaffold ready for features

---

### 2. `/vercel-ai-sdk:add-streaming`

**Purpose**: Add text streaming capability

**What it does:**
- Detects your framework
- Adds `streamText()` or `useChat()` hook
- Creates streaming example
- Verifies TypeScript compilation

**Fetches**: 3 URLs (streaming docs)

**Use when**: You want real-time AI responses

---

### 3. `/vercel-ai-sdk:add-tools`

**Purpose**: Add tool/function calling

**What it does:**
- Creates tool schemas (with zod)
- Implements tool handlers
- Adds 1-2 example tools
- Integrates with existing AI calls

**Fetches**: 3 URLs (tools docs)

**Use when**: AI needs to call your functions

---

### 4. `/vercel-ai-sdk:add-chat`

**Purpose**: Add chat UI with message persistence

**What it does:**
- Creates chat interface components
- Adds `useChat()` hook (or framework equivalent)
- Implements message persistence
- Creates API route/endpoint
- Adds styling

**Fetches**: 3 URLs (chatbot UI docs)

**Use when**: Building a chat application

---

### 5. `/vercel-ai-sdk:add-provider`

**Purpose**: Add another AI provider

**What it does:**
- Installs provider package
- Updates environment variables
- Shows how to use new provider
- Documents how to switch providers

**Fetches**: 2 URLs (provider docs)

**Use when**: Want to use multiple AI providers

---

## Feature Bundle Commands

These commands add multiple related features at once using specialized agents:

### 6. `/vercel-ai-sdk:add-ui-features`

**Purpose**: Add advanced UI capabilities

**What it does (via vercel-ai-ui-agent):**
- Generative UI with AI SDK RSC (Next.js App Router)
- `useObject` hook for structured outputs in UI
- `useCompletion` hook for text completion
- Message persistence with database integration
- File attachments and multi-modal support
- Message metadata and resume streams

**Fetches**: 5-9 URLs (fetched progressively by agent as needed)

**Use when**: Need advanced UI features beyond basic chat

---

### 7. `/vercel-ai-sdk:add-data-features`

**Purpose**: Add AI-powered data processing

**What it does (via vercel-ai-data-agent):**
- Embeddings generation with `embed()` and `embedMany()`
- Vector database integration (Pinecone, Weaviate, Chroma, pgvector)
- RAG pipeline with document chunking and retrieval
- Structured data generation with `generateObject`/`streamObject`
- Semantic search functionality

**Fetches**: 4-9 URLs (fetched progressively by agent)

**Use when**: Building knowledge bases, RAG systems, or semantic search

---

### 8. `/vercel-ai-sdk:add-production`

**Purpose**: Make your app production-ready

**What it does (via vercel-ai-production-agent):**
- Telemetry/observability with OpenTelemetry
- Rate limiting (Redis/Upstash or edge-based)
- Comprehensive error handling patterns
- Testing infrastructure with mocks (>80% coverage goal)
- Middleware for auth, validation, logging

**Fetches**: 5-10 URLs (fetched progressively by agent)

**Use when**: Preparing for production deployment

---

### 9. `/vercel-ai-sdk:add-advanced`

**Purpose**: Add cutting-edge AI capabilities

**What it does (via vercel-ai-advanced-agent):**
- AI agents with workflows and loop control
- MCP (Model Context Protocol) tools integration
- Image generation (DALL-E, Fal AI)
- Audio transcription (Whisper)
- Text-to-speech synthesis
- Multi-step reasoning patterns

**Fetches**: 6-15 URLs (fetched progressively by agent)

**Use when**: Building autonomous agents or multi-modal features

---

### 10. `/vercel-ai-sdk:build-full-stack`

**Purpose**: Build complete production app from scratch

**What it does:**
Chains all commands together sequentially:
1. Creates scaffold (`new-app`)
2. Adds core features (`add-streaming`, `add-tools`, `add-chat`)
3. Adds UI features (`add-ui-features`)
4. Adds data features (`add-data-features`)
5. Adds production features (`add-production`)
6. Optionally adds advanced features (`add-advanced`)

**Fetches**: 0 URLs (delegates to other commands which call agents)

**Use when**: Want a complete app with everything configured

---

## Agents

### Core Commands Agents (Verifiers)

These agents validate your Vercel AI SDK setup after core commands:

- **vercel-ai-verifier-ts**: TypeScript project verification
- **vercel-ai-verifier-js**: JavaScript project verification
- **vercel-ai-verifier-py**: Python project verification

**What they check:**
- SDK installation and versions
- Configuration files (package.json, tsconfig.json)
- Proper SDK usage patterns
- Type safety (for TypeScript)
- Environment setup
- Security (no hardcoded API keys)
- Best practices from official docs

**Invoked automatically** by core commands after setup.

---

### Feature Bundle Agents (Specialized)

These agents implement feature bundles and fetch documentation progressively:

#### **vercel-ai-ui-agent**
- Handles all UI features (generative UI, useObject, persistence, attachments)
- Fetches UI-specific docs as needed across 5 phases
- Adapts to framework (Next.js, React, etc.)
- Implements database integration for persistence

#### **vercel-ai-data-agent**
- Handles data features (embeddings, RAG, structured data)
- Fetches data/vector DB docs progressively
- Designs vector database schemas
- Implements RAG pipelines and semantic search

#### **vercel-ai-production-agent**
- Handles production readiness (telemetry, rate limiting, testing)
- Fetches production docs progressively
- Sets up monitoring and observability
- Implements comprehensive testing

#### **vercel-ai-advanced-agent**
- Handles advanced features (agents, MCP, image/audio generation)
- Fetches advanced docs progressively
- Designs agent workflows with loop control
- Implements multi-modal capabilities

**Key Feature**: All specialized agents **spread WebFetch calls across phases** instead of loading all docs upfront, making documentation fetching more manageable.

---

## Workflow Examples

### Incremental Build (Modular)

```bash
# Step 1: Create scaffold (TypeScript + Next.js + OpenAI)
/vercel-ai-sdk:new-app my-ai-app

# Step 2: Add streaming
/vercel-ai-sdk:add-streaming

# Step 3: Add tool calling
/vercel-ai-sdk:add-tools

# Step 4: Add chat UI
/vercel-ai-sdk:add-chat

# Step 5: Add Anthropic provider
/vercel-ai-sdk:add-provider
```

Result: Full-featured AI chat app with streaming, tools, and multi-provider support!

### Full-Stack Build (All-at-Once)

```bash
# One command to build everything
/vercel-ai-sdk:build-full-stack my-complete-app
```

**Then answer:**
- Project name?
- Framework? (Next.js, React, Node.js, etc.)
- AI Provider? (OpenAI, Anthropic, etc.)
- Want all features or subset?

**Result**: Production-ready app with:
- ✅ Core features (streaming, tools, chat)
- ✅ Advanced UI (generative UI, useObject, persistence)
- ✅ Data features (embeddings, RAG, structured data)
- ✅ Production ready (telemetry, rate limiting, testing)
- ✅ Advanced features (agents, MCP, image/audio) - optional

### Feature Bundle Build (Targeted)

```bash
# Start with basics
/vercel-ai-sdk:new-app my-app
/vercel-ai-sdk:add-streaming

# Add only what you need
/vercel-ai-sdk:add-ui-features       # Advanced UI
/vercel-ai-sdk:add-data-features     # RAG & embeddings
/vercel-ai-sdk:add-production        # Production readiness
```

Result: Targeted app with only the features you need!

---

## Supported Frameworks

### Frontend/Fullstack
- **Next.js** (App Router or Pages Router)
- **React** (with Vite)
- **Svelte** (with SvelteKit)
- **Vue** (with Nuxt)

### Backend
- **Node.js** (Express, Fastify, or standalone)
- **Python** (FastAPI, Flask)

All commands **detect your framework** and adapt accordingly.

---

## Supported AI Providers

- **OpenAI** (GPT-4, GPT-3.5)
- **Anthropic** (Claude)
- **Google** (Gemini)
- **xAI** (Grok)
- **Azure** (OpenAI on Azure)
- **Amazon Bedrock**
- **Groq**
- **Mistral**
- **DeepSeek**
- **Cohere**
- **Fireworks**

Add providers incrementally with `/vercel-ai-sdk:add-provider`

---

## Key Features

✅ **Two Build Modes**: Incremental (modular) or all-at-once (full-stack)
✅ **Feature Bundles**: Related features grouped together (UI, Data, Production, Advanced)
✅ **Specialized Agents**: Each bundle has a dedicated agent that fetches docs progressively
✅ **Framework Agnostic**: Works with Next.js, React, Node.js, Python, etc.
✅ **Progressive Doc Fetching**: Agents spread WebFetch calls across phases (not all upfront)
✅ **Auto-Verification**: Verifier agents check your setup after core commands
✅ **Multi-Provider**: Easily switch between OpenAI, Anthropic, Google, xAI, etc.
✅ **Production Ready**: Includes telemetry, rate limiting, testing, error handling
✅ **Best Practices**: Follows official Vercel AI SDK documentation
✅ **Scalable Architecture**: 10 commands, 7 agents (instead of 30+ commands)

---

## Resources

### Official Documentation
- **Vercel AI SDK**: https://ai-sdk.dev/docs
- **Getting Started**: https://ai-sdk.dev/docs/getting-started
- **API Reference**: https://ai-sdk.dev/docs/reference
- **Providers**: https://ai-sdk.dev/providers

### Templates & Examples
- **Templates**: https://vercel.com/templates?type=ai
- **Chatbot Starter**: https://vercel.com/templates/next.js/nextjs-ai-chatbot
- **RAG Template**: https://vercel.com/templates/next.js/ai-sdk-internal-knowledge-base
- **Multi-Modal Chat**: https://vercel.com/templates/next.js/multi-modal-chatbot

### Cookbook
- **All Guides**: https://ai-sdk.dev/cookbook
- **RAG Agent**: https://ai-sdk.dev/cookbook/guides/rag-chatbot
- **SQL Agent**: https://ai-sdk.dev/cookbook/guides/natural-language-postgres
- **Computer Use Agent**: https://ai-sdk.dev/cookbook/guides/computer-use
- **Slackbot Agent**: https://ai-sdk.dev/cookbook/guides/slackbot

### Framework Examples
- **Next.js**: https://github.com/vercel/ai/tree/main/examples/next-openai
- **Nuxt**: https://github.com/vercel/ai/tree/main/examples/nuxt-openai
- **SvelteKit**: https://github.com/vercel/ai/tree/main/examples/sveltekit-openai

### Agents (Advanced)
- **Building Agents**: https://ai-sdk.dev/docs/agents/building-agents
- **Workflow Patterns**: https://ai-sdk.dev/docs/agents/workflows
- **Loop Control**: https://ai-sdk.dev/docs/agents/loop-control

---

## Installation

This plugin is part of the **ai-dev-marketplace**. Install via:

```bash
# Clone the marketplace
git clone https://github.com/vanman2024/ai-dev-marketplace.git

# The plugin is in plugins/vercel-ai-sdk/
```

Or install as a standalone Claude Code plugin (if published to marketplace).

---

## Version

**Current Version**: 1.0.0

**SDK Compatibility**: Vercel AI SDK v5+ (beta 6 coming soon)

**Note**: Vercel AI SDK is moving fast. Commands fetch latest docs dynamically to stay current.

---

## Contributing

Contributions welcome! This plugin is part of:
- **Repository**: https://github.com/vanman2024/ai-dev-marketplace
- **Plugin Directory**: `plugins/vercel-ai-sdk/`

---

## License

MIT License - see LICENSE file

---

**Built with the domain-plugin-builder framework**
