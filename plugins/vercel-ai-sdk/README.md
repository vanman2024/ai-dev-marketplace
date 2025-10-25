# Vercel AI SDK Plugin

Modular Vercel AI SDK development plugin with incremental feature addition. Build AI applications step-by-step with focused commands.

## Overview

This plugin helps you build Vercel AI SDK applications using a **modular approach**:
1. Create minimal scaffold with `/vercel-ai-sdk:new-app`
2. Add features incrementally as needed
3. Each command focuses on ONE capability with minimal docs

**Why Modular?**
- Manageable doc fetching (2-5 URLs per command)
- Add only what you need
- Learn incrementally
- Adapts to any framework (Next.js, React, Node.js, Python, etc.)

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

## Agents

### Verifier Agents

These agents validate your Vercel AI SDK setup:

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

**Invoked automatically** by commands after setup.

---

## Workflow Example

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

✅ **Modular**: Add features one at a time
✅ **Framework Agnostic**: Works with Next.js, React, Node.js, Python, etc.
✅ **Minimal Docs**: Each command fetches 2-5 URLs (not overwhelming)
✅ **Auto-Verification**: Agents check your setup
✅ **Multi-Provider**: Easily switch between OpenAI, Anthropic, Google, etc.
✅ **Best Practices**: Follows official SDK documentation

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
