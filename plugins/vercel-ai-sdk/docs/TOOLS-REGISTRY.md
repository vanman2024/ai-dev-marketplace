# AI SDK Tools Registry - MCP & Agent Tools

> **Source**: https://ai-sdk.dev/tools-registry
> **Version**: AI SDK 6 (Latest)
> **Generated**: January 2026

---

## 📚 Table of Contents

1. [Overview](#overview)
2. [Available Tools](#available-tools)
3. [Tool Categories](#tool-categories)

---

## Overview

| Page                  | URL                                                                       |
| --------------------- | ------------------------------------------------------------------------- |
| Tools Registry        | https://ai-sdk.dev/tools-registry                                         |
| Tools Registry Source | https://github.com/vercel/ai/blob/main/content/tools-registry/registry.ts |

The Tools Registry provides pre-built tools that can be used with AI SDK agents for common tasks like web search, code execution, and data retrieval.

---

## Available Tools

| Tool                     | URL                                                 | Description                            |
| ------------------------ | --------------------------------------------------- | -------------------------------------- |
| Code Execution           | https://ai-sdk.dev/tools-registry/code-execution    | Execute code in sandboxed environments |
| Exa                      | https://ai-sdk.dev/tools-registry/exa               | Exa neural search API                  |
| Parallel                 | https://ai-sdk.dev/tools-registry/parallel          | Execute tools in parallel              |
| ctx-zip                  | https://ai-sdk.dev/tools-registry/ctx-zip           | Context compression tool               |
| Perplexity Search        | https://ai-sdk.dev/tools-registry/perplexity-search | Web search via Perplexity              |
| Tavily                   | https://ai-sdk.dev/tools-registry/tavily            | Tavily search API                      |
| Firecrawl                | https://ai-sdk.dev/tools-registry/firecrawl         | Web scraping & crawling                |
| Amazon Bedrock AgentCore | https://ai-sdk.dev/tools-registry/bedrock-agentcore | AWS Bedrock agent tools                |
| Superagent               | https://ai-sdk.dev/tools-registry/superagent        | Superagent integration                 |
| Tako Search              | https://ai-sdk.dev/tools-registry/tako-search       | Tako search engine                     |
| Valyu                    | https://ai-sdk.dev/tools-registry/valyu             | Valyu data API                         |
| Airweave                 | https://ai-sdk.dev/tools-registry/airweave          | Airweave integration                   |
| bash-tool                | https://ai-sdk.dev/tools-registry/bash-tool         | Execute bash commands                  |

---

## Tool Categories

### Search & Web Tools

| Tool              | URL                                                 | Use Case                          |
| ----------------- | --------------------------------------------------- | --------------------------------- |
| Exa               | https://ai-sdk.dev/tools-registry/exa               | Neural/semantic web search        |
| Perplexity Search | https://ai-sdk.dev/tools-registry/perplexity-search | AI-powered web search             |
| Tavily            | https://ai-sdk.dev/tools-registry/tavily            | Research & fact-finding           |
| Firecrawl         | https://ai-sdk.dev/tools-registry/firecrawl         | Web scraping & content extraction |
| Tako Search       | https://ai-sdk.dev/tools-registry/tako-search       | Alternative search engine         |

### Code & Execution Tools

| Tool           | URL                                              | Use Case                |
| -------------- | ------------------------------------------------ | ----------------------- |
| Code Execution | https://ai-sdk.dev/tools-registry/code-execution | Run code securely       |
| bash-tool      | https://ai-sdk.dev/tools-registry/bash-tool      | Shell command execution |

### Utility Tools

| Tool     | URL                                        | Use Case                    |
| -------- | ------------------------------------------ | --------------------------- |
| Parallel | https://ai-sdk.dev/tools-registry/parallel | Concurrent tool execution   |
| ctx-zip  | https://ai-sdk.dev/tools-registry/ctx-zip  | Context window optimization |

### Platform Integrations

| Tool                     | URL                                                 | Use Case               |
| ------------------------ | --------------------------------------------------- | ---------------------- |
| Amazon Bedrock AgentCore | https://ai-sdk.dev/tools-registry/bedrock-agentcore | AWS agent capabilities |
| Superagent               | https://ai-sdk.dev/tools-registry/superagent        | Superagent platform    |
| Valyu                    | https://ai-sdk.dev/tools-registry/valyu             | Data access            |
| Airweave                 | https://ai-sdk.dev/tools-registry/airweave          | Airweave platform      |

---

## Usage Example

```typescript
import { generateText, tool } from 'ai';
import { createTavilySearchTool } from '@ai-sdk/tavily';

const result = await generateText({
  model: 'openai/gpt-4o',
  prompt: 'Search for the latest AI news',
  tools: {
    search: createTavilySearchTool({
      apiKey: process.env.TAVILY_API_KEY,
    }),
  },
});
```

---

## Summary

| Category               | Count  |
| ---------------------- | ------ |
| Search & Web Tools     | 5      |
| Code & Execution Tools | 2      |
| Utility Tools          | 2      |
| Platform Integrations  | 4      |
| **Total**              | **13** |

---

_This document was auto-generated by scraping AI SDK Tools Registry at https://ai-sdk.dev/tools-registry_
