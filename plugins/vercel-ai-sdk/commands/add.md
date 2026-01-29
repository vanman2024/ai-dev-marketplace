---
description: Add a specific feature to an existing Vercel AI SDK application. Features include streaming, tools, chat, ai-gateway, generative-ui, middleware, mcp, rag, attachments, multi-modal, agents, production, database, observability, testing.
argument-hint: <feature> [sub-options]
---

# Add Vercel AI SDK Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Core Features

**If `$0` = "streaming":**

```
Task(vercel-ai-orchestrator-agent) Implement STREAMING for this Vercel AI SDK project.

Requirements:
- Set up streamText() for text generation
- Configure useChat() hook with streaming
- Handle partial responses and loading states
- Implement stream cancellation with AbortController
- Stream type: $1 (text, object, ui - default: text)
```

**If `$0` = "tools":**

```
Task(vercel-ai-tools-agent) Implement TOOL CALLING for this Vercel AI SDK project.

Requirements:
- Define tools with tool() helper and Zod schemas
- Implement tool execution handlers
- Configure multi-step tool flows with maxSteps
- Handle tool results and errors
- Tool type: $1 (single, multi-step, automatic - default: multi-step)
```

**If `$0` = "chat":**

```
Task(vercel-ai-ui-agent) Implement CHAT INTERFACE for this Vercel AI SDK project.

Requirements:
- Set up useChat() hook from @ai-sdk/react
- Implement message history management
- Add typing indicators and loading states
- Handle errors gracefully
- Framework: $1 (react, svelte, vue - default: react)
```

**If `$0` = "completion":**

```
Task(vercel-ai-ui-agent) Implement TEXT COMPLETION for this Vercel AI SDK project.

Requirements:
- Set up useCompletion() hook
- Configure streaming text completion
- Handle partial text updates
- Implement completion UI
```

### AI Gateway & Providers

**If `$0` = "ai-gateway":**

```
Task(vercel-ai-gateway-agent) Implement AI GATEWAY for this Vercel AI SDK project.

Requirements:
- Configure unified provider access with gateway()
- Set up model fallbacks for reliability
- Implement provider routing (order, only options)
- Configure usage tracking (user, tags)
- Enable credit monitoring
- Auth mode: $1 (vercel-oidc, byok - default: byok)
- Fallback models: $2 (if provided)
```

**If `$0` = "provider":**

```
Task(vercel-ai-provider-agent) Add AI PROVIDER to this Vercel AI SDK project.

Requirements:
- Provider: $1 (openai, anthropic, google, xai, groq, mistral, cohere, amazon-bedrock, azure)
- Install @ai-sdk/[provider] package
- Configure environment variables
- Set up provider instance
- Document model options
```

**If `$0` = "custom-provider":**

```
Task(vercel-ai-provider-agent) Create CUSTOM PROVIDER for this Vercel AI SDK project.

Requirements:
- Implement LanguageModelV1 interface
- Handle API authentication
- Process streaming responses
- Map to AI SDK format
- Provider name: $1 (if provided)
```

### Advanced UI Features

**If `$0` = "generative-ui":**

```
Task(vercel-ai-elements-agent) Implement GENERATIVE UI for this Vercel AI SDK project.

Requirements:
- Set up AI SDK RSC with streamUI()
- Create streaming React components
- Implement server actions for AI calls
- Handle component state management
- Component type: $1 (cards, charts, forms - if provided)
```

**If `$0` = "elements":**

```
Task(vercel-ai-elements-agent) Implement AI ELEMENTS for this Vercel AI SDK project.

Requirements:
- Add @ai-sdk/react-elements package
- Set up AI input components
- Implement AI-enhanced form elements
- Configure element behaviors
```

**If `$0` = "attachments":**

```
Task(vercel-ai-ui-agent) Implement FILE ATTACHMENTS for this Vercel AI SDK project.

Requirements:
- Configure useChat() with attachments support
- Handle file uploads (images, documents)
- Process multi-modal inputs
- Display attachment previews
- File types: $1 (images, documents, all - default: all)
```

**If `$0` = "multi-modal":**

```
Task(vercel-ai-advanced-agent) Implement MULTI-MODAL support for this Vercel AI SDK project.

Requirements:
- Handle image inputs (base64, URL)
- Configure vision-capable models
- Process audio inputs (if supported)
- Implement multi-modal message formats
- Mode: $1 (vision, audio, all - default: vision)
```

### Middleware & Processing

**If `$0` = "middleware":**

```
Task(vercel-ai-middleware-agent) Implement LANGUAGE MODEL MIDDLEWARE for this Vercel AI SDK project.

Requirements:
- Set up wrapLanguageModel() for model wrapping
- Middleware type: $1 (logging, caching, guardrails, reasoning - default: logging)
- Implement request/response transformation
- Add built-in middleware: extractReasoning, simulateStreaming, defaultSettings
- Chain multiple middleware layers
```

**If `$0` = "guardrails":**

```
Task(vercel-ai-middleware-agent) Implement AI GUARDRAILS for this Vercel AI SDK project.

Requirements:
- Create content filtering middleware
- Implement input validation
- Add output safety checks
- Configure rate limiting
- Guardrail type: $1 (content, rate, both - default: both)
```

### Data & Persistence

**If `$0` = "rag":**

```
Task(vercel-ai-data-agent) Implement RAG for this Vercel AI SDK project.

Requirements:
- Set up embedding generation with embed() or embedMany()
- Configure vector storage
- Implement semantic search
- Build retrieval pipeline
- Vector DB: $1 (pinecone, supabase, vercel-postgres - if provided)
```

**If `$0` = "database":**

```
Task(vercel-ai-database-agent) Implement DATABASE INTEGRATION for this Vercel AI SDK project.

Requirements:
- Set up chat history persistence
- Configure message storage schema
- Implement conversation retrieval
- Handle session management
- Database: $1 (postgres, supabase, prisma - default: prisma)
```

**If `$0` = "structured-output":**

```
Task(vercel-ai-data-agent) Implement STRUCTURED OUTPUT for this Vercel AI SDK project.

Requirements:
- Use generateObject() for typed outputs
- Define Zod schemas for validation
- Handle partial object streaming
- Implement error recovery
- Schema type: $1 (if provided, e.g., "user-profile", "product")
```

### MCP & Agents

**If `$0` = "mcp":**

```
Task(vercel-ai-tools-agent) Implement MCP INTEGRATION for this Vercel AI SDK project.

Requirements:
- Set up @ai-sdk/mcp package
- Configure MCP server connection
- Transform MCP tools to AI SDK tools
- Handle tool execution through MCP
- Transport: $1 (stdio, sse - default: stdio)
- Server: $2 (if provided)
```

**If `$0` = "agents":**

```
Task(vercel-ai-advanced-agent) Implement AI AGENTS for this Vercel AI SDK project.

Requirements:
- Pattern: $1 (react, planning, multi-agent - default: react)
- Implement agent loop with maxSteps
- Configure tool orchestration
- Handle agent state management
- Build autonomous workflows
```

**If `$0` = "multi-agent":**

```
Task(vercel-ai-advanced-agent) Implement MULTI-AGENT SYSTEM for this Vercel AI SDK project.

Requirements:
- Define agent roles and capabilities
- Implement agent routing/orchestration
- Set up inter-agent communication
- Handle task delegation
- Number of agents: $1 (default: 2)
```

### Production & Deployment

**If `$0` = "production":**

```
Task(vercel-ai-production-agent) Implement PRODUCTION SETUP for this Vercel AI SDK project.

Requirements:
- Configure error handling and retries
- Set up rate limiting
- Implement cost tracking
- Add health checks
- Configure for Vercel deployment
```

**If `$0` = "observability":**

```
Task(vercel-ai-production-agent) Implement OBSERVABILITY for this Vercel AI SDK project.

Requirements:
- Enable AI SDK telemetry
- Set up OpenTelemetry integration
- Configure Vercel AI Analytics
- Implement custom logging
- Provider: $1 (vercel, langfuse, langsmith - default: vercel)
```

**If `$0` = "testing":**

```
Task(vercel-ai-production-agent) Implement TESTING for this Vercel AI SDK project.

Requirements:
- Set up mock providers for testing
- Create streaming response mocks
- Implement tool call tests
- Build integration test suite
- Framework: $1 (vitest, jest - default: vitest)
```

**If `$0` = "caching":**

```
Task(vercel-ai-middleware-agent) Implement RESPONSE CACHING for this Vercel AI SDK project.

Requirements:
- Set up caching middleware
- Configure cache keys and TTL
- Implement cache invalidation
- Track cache hit rates
- Cache backend: $1 (memory, redis, vercel-kv - default: memory)
```

---

## Usage Examples

```bash
# Core features
/vercel-ai-sdk:add streaming
/vercel-ai-sdk:add tools multi-step
/vercel-ai-sdk:add chat react

# AI Gateway & providers
/vercel-ai-sdk:add ai-gateway byok
/vercel-ai-sdk:add provider anthropic
/vercel-ai-sdk:add custom-provider my-llm

# Advanced UI
/vercel-ai-sdk:add generative-ui cards
/vercel-ai-sdk:add attachments images
/vercel-ai-sdk:add multi-modal vision

# Middleware
/vercel-ai-sdk:add middleware guardrails
/vercel-ai-sdk:add guardrails content

# Data & persistence
/vercel-ai-sdk:add rag pinecone
/vercel-ai-sdk:add database supabase
/vercel-ai-sdk:add structured-output

# MCP & agents
/vercel-ai-sdk:add mcp stdio filesystem
/vercel-ai-sdk:add agents react
/vercel-ai-sdk:add multi-agent 3

# Production
/vercel-ai-sdk:add production
/vercel-ai-sdk:add observability langfuse
/vercel-ai-sdk:add testing vitest
```

---

## Feature Reference

| Feature             | Agent        | $1 Options                           | Description             |
| ------------------- | ------------ | ------------------------------------ | ----------------------- |
| `streaming`         | orchestrator | text/object/ui                       | Real-time streaming     |
| `tools`             | tools        | single/multi-step/automatic          | Function calling        |
| `chat`              | ui           | react/svelte/vue                     | Chat interface          |
| `completion`        | ui           | -                                    | Text completion         |
| `ai-gateway`        | gateway      | vercel-oidc/byok                     | Multi-provider gateway  |
| `provider`          | provider     | openai/anthropic/google/xai/etc      | Add AI provider         |
| `custom-provider`   | provider     | provider-name                        | Custom provider         |
| `generative-ui`     | elements     | cards/charts/forms                   | AI-generated components |
| `elements`          | elements     | -                                    | AI input elements       |
| `attachments`       | ui           | images/documents/all                 | File uploads            |
| `multi-modal`       | advanced     | vision/audio/all                     | Multi-modal inputs      |
| `middleware`        | middleware   | logging/caching/guardrails/reasoning | Model middleware        |
| `guardrails`        | middleware   | content/rate/both                    | Safety guardrails       |
| `rag`               | data         | pinecone/supabase/vercel-postgres    | RAG implementation      |
| `database`          | database     | postgres/supabase/prisma             | Data persistence        |
| `structured-output` | data         | schema-type                          | Typed JSON outputs      |
| `mcp`               | tools        | stdio/sse + server-name              | MCP integration         |
| `agents`            | advanced     | react/planning/multi-agent           | AI agent patterns       |
| `multi-agent`       | advanced     | agent-count                          | Multi-agent systems     |
| `production`        | production   | -                                    | Production hardening    |
| `observability`     | production   | vercel/langfuse/langsmith            | Monitoring & analytics  |
| `testing`           | production   | vitest/jest                          | Test suite setup        |
| `caching`           | middleware   | memory/redis/vercel-kv               | Response caching        |
