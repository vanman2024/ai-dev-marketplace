---
description: Build complete OpenRouter integration - initializes if needed, then runs specialized agents for multi-model routing, fallbacks, and SDK integration
argument-hint: <project-name> [--sdk <vercel-ai|langchain>]
---

# Build Complete OpenRouter Integration

**Goal:** Create a production-ready OpenRouter integration with intelligent model routing.

**This command handles everything** - from setup to full integration with model routing, fallbacks, and cost optimization.

## Stack (Always Use Latest Versions)

- **OpenRouter API** - Latest endpoints
- **Vercel AI SDK** / **LangChain** - Latest versions
- Framework-appropriate HTTP client

**IMPORTANT:** Always use the latest SDK versions. Check npm/pip for current versions.

## Arguments

- `$ARGUMENTS` - Project name and optional SDK preference
- `--sdk <name>` - Preferred SDK (vercel-ai, langchain)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and SDK preference
2. Auto-detect framework (Next.js → Vercel AI SDK, Python → LangChain)
3. Discover architecture documentation for model requirements
4. Create routing strategy based on use cases

### Phase 2: OpenRouter Setup

```
Task("Initialize OpenRouter", @openrouter-setup-agent, {
  prompt: "Initialize OpenRouter integration:
    - Configure API key from environment
    - Set up HTTP client with proper headers
    - Configure base URL and site info
    - Create OpenRouter client wrapper
    Detect framework and use appropriate patterns."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Model Routing
Task("Configure routing", @openrouter-routing-agent, {
  prompt: "Implement intelligent model routing:
    - Define model tiers (fast/cheap vs smart/expensive)
    - Implement automatic fallbacks
    - Add cost tracking and limits
    - Create routing middleware
    Follow use cases from architecture docs."
})

// Agent 2: SDK Integration (based on preference)
Task("Integrate SDK", @openrouter-vercel-integration-agent, {
  prompt: "Integrate with Vercel AI SDK:
    - Configure createOpenRouter provider
    - Set up streaming responses
    - Add tool/function calling support
    - Implement structured outputs
    Or use LangChain if Python project."
})
```

### Phase 4: Final Output

**Provide summary:**

- List configured models and routing rules
- Show cost optimization settings
- Provide usage examples:
  ```typescript
  // Streaming chat
  const result = await streamText({
    model: openrouter('anthropic/claude-sonnet'),
    messages: [{ role: 'user', content: 'Hello' }],
  });
  ```

## Utility Commands

- `/openrouter:configure` - Configure API keys only
- `/openrouter:add-model-routing` - Add routing logic
- `/openrouter:add-vercel-ai-sdk` - Vercel AI SDK integration
- `/openrouter:add-langchain` - LangChain integration
