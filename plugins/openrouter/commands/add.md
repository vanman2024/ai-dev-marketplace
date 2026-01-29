---
description: Add a specific feature to an existing OpenRouter project. Features include vercel-ai, langchain, routing, fallback, models.
argument-hint: <feature> [options]
---

# Add OpenRouter Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Framework Integration Features

**If `$0` = "vercel-ai":**

```
Task(openrouter-vercel-integration-agent) Add VERCEL AI SDK integration.

Requirements:
- Integration type: $1 (provider, middleware, full - default: provider)
- Create OpenRouter provider
- Configure streaming support
- Add tool support
- Set up response handling
```

**If `$0` = "langchain":**

```
Task(openrouter-langchain-agent) Add LANGCHAIN integration.

Requirements:
- Integration type: $1 (chat, llm, embeddings - default: chat)
- Create LangChain wrapper
- Configure callbacks
- Add chain support
- Set up memory integration
```

### Routing Features

**If `$0` = "routing":**

```
Task(openrouter-routing-agent) Add MODEL ROUTING.

Requirements:
- Strategy: $1 (cost, latency, quality, custom - default: cost)
- Models: $2 (model list or auto)
- Configure routing logic
- Set up model selection
- Add cost tracking
- Configure fallbacks
```

**If `$0` = "fallback":**

```
Task(openrouter-routing-agent) Add FALLBACK configuration.

Requirements:
- Fallback strategy: $1 (chain, parallel, smart - default: chain)
- Set up fallback models
- Configure retry logic
- Add error handling
- Set timeout thresholds
```

### Model Features

**If `$0` = "models":**

```
Task(openrouter-setup-agent) Configure MODELS.

Requirements:
- Model type: $1 (chat, code, vision, cheap - default: chat)
- Action: $2 (list, add, configure - default: list)
- Fetch available models
- Configure model settings
- Add to routing config
```

---

## Usage Examples

```bash
# Framework integrations
/openrouter:add vercel-ai provider
/openrouter:add vercel-ai full
/openrouter:add langchain chat

# Routing
/openrouter:add routing cost
/openrouter:add routing latency
/openrouter:add routing custom

# Fallbacks
/openrouter:add fallback chain
/openrouter:add fallback smart

# Models
/openrouter:add models chat list
/openrouter:add models vision configure
```

---

## Feature Reference

| Feature     | Agent              | $1 Options                  | Description           |
| ----------- | ------------------ | --------------------------- | --------------------- |
| `vercel-ai` | vercel-integration | provider/middleware/full    | Vercel AI SDK         |
| `langchain` | langchain-agent    | chat/llm/embeddings         | LangChain integration |
| `routing`   | routing-agent      | cost/latency/quality/custom | Model routing         |
| `fallback`  | routing-agent      | chain/parallel/smart        | Fallback config       |
| `models`    | setup-agent        | chat/code/vision/cheap      | Model configuration   |
