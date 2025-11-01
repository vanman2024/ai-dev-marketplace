# OpenRouter Plugin

Unified interface for 500+ LLM models with intelligent routing, cost optimization, and framework integrations.

## Overview

The OpenRouter plugin provides comprehensive SDK integration for accessing 500+ models from 60+ providers including OpenAI, Anthropic, Google, Meta, and more. It supports intelligent model routing, cost optimization, and seamless integration with popular frameworks like Vercel AI SDK and LangChain.

## Features

- **500+ Models**: Access to models from OpenAI, Anthropic, Google, Meta, Mistral, and more
- **Intelligent Routing**: Cost-aware model selection and automatic fallback strategies
- **Framework Integration**: Vercel AI SDK, LangChain, OpenAI SDK, PydanticAI support
- **Cost Optimization**: Budget controls, usage tracking, and cost-effective routing
- **Multi-Language**: TypeScript, JavaScript, and Python support

## Commands

### `/openrouter:init [project-path]`
Initialize OpenRouter SDK with API key configuration, model selection, and framework integration setup.

**Example:**
```bash
/openrouter:init
```

### `/openrouter:add-vercel-ai-sdk [feature]`
Add Vercel AI SDK integration with OpenRouter provider for streaming, chat, and tool calling.

**Features:** streaming, chat, tools, all

**Example:**
```bash
/openrouter:add-vercel-ai-sdk streaming
/openrouter:add-vercel-ai-sdk all
```

### `/openrouter:add-langchain [feature]`
Add LangChain integration with OpenRouter for chains, agents, and RAG.

**Features:** chains, agents, rag, all

**Example:**
```bash
/openrouter:add-langchain agents
/openrouter:add-langchain all
```

### `/openrouter:add-model-routing [routing-strategy]`
Configure intelligent model routing and cost optimization with fallback strategies.

**Strategies:** cost, speed, quality, balanced, custom

**Example:**
```bash
/openrouter:add-model-routing cost
/openrouter:add-model-routing balanced
```

### `/openrouter:configure [setting-name] [value]`
Configure OpenRouter settings, API keys, and preferences.

**Actions:** set, get, list, reset

**Example:**
```bash
/openrouter:configure set api-key sk-or-v1-...
/openrouter:configure get
/openrouter:configure list
```

## Agents

- **openrouter-setup-agent**: Initialize OpenRouter SDK with framework detection and environment setup
- **openrouter-vercel-integration-agent**: Integrate Vercel AI SDK with OpenRouter provider
- **openrouter-langchain-agent**: Integrate LangChain with OpenRouter for chains, agents, and RAG
- **openrouter-routing-agent**: Configure intelligent model routing and cost optimization

## Quick Start

1. **Initialize OpenRouter:**
   ```bash
   /openrouter:init
   ```

2. **Get your API key** at https://openrouter.ai/keys

3. **Choose your integration:**
   - For Next.js apps: `/openrouter:add-vercel-ai-sdk all`
   - For Python projects: `/openrouter:add-langchain all`
   - For cost optimization: `/openrouter:add-model-routing cost`

4. **Configure settings:**
   ```bash
   /openrouter:configure set api-key YOUR_KEY
   ```

## Supported Frameworks

### Vercel AI SDK (TypeScript/JavaScript)
- Streaming text generation with `streamText()`
- Chat interfaces with `useChat()` hook
- Tool calling with Zod schemas
- Next.js App Router and Pages Router support

### LangChain (Python/TypeScript)
- Chain composition with LCEL
- Agent development with tools
- RAG with vector stores (Chroma, FAISS, Pinecone)
- Memory and conversation history

### OpenAI SDK (TypeScript/Python)
- Drop-in replacement for OpenAI API
- Compatible with existing OpenAI code
- Access to 500+ models via routing

## Model Routing

OpenRouter provides intelligent routing to optimize for cost, speed, or quality:

- **Cost-optimized**: Free models → low-cost → premium fallback
- **Speed-optimized**: Fastest models with streaming enabled
- **Quality-optimized**: Premium models with high-quality fallbacks
- **Balanced**: Task-based dynamic routing with cost/quality tradeoffs

## Popular Models

- **anthropic/claude-3.5-sonnet**: Best quality, great for complex tasks
- **openai/gpt-4-turbo**: High quality, strong reasoning
- **google/gemini-pro-1.5**: Cost-effective, good performance
- **meta-llama/llama-3.1-70b-instruct**: Open source, free tier available

Browse all models at: https://openrouter.ai/models

## Environment Variables

```bash
OPENROUTER_API_KEY=sk-or-v1-...          # Required: Your API key
OPENROUTER_APP_NAME=my-app               # Recommended: For request tracking
OPENROUTER_SITE_URL=https://myapp.com    # Recommended: For attribution
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1  # Optional: Custom endpoint
```

## Documentation

- OpenRouter Docs: https://openrouter.ai/docs
- Model Browser: https://openrouter.ai/models
- Request Builder: https://openrouter.ai/request-builder
- Activity Dashboard: https://openrouter.ai/activity

## License

MIT
