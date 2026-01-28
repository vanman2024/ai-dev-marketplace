---
description: Add Vercel AI SDK integration with streaming chat and model providers
argument-hint: [--provider openai|anthropic|google] [--with-chat]
---

# Add AI SDK

Integrate Vercel AI SDK into the Next.js project.

**Arguments:** `$ARGUMENTS`

## Execution

Use the ai-sdk-integration-agent to add AI SDK:

```
Task("Add AI SDK", @ai-sdk-integration-agent, {
  prompt: "Add Vercel AI SDK integration to this project:
    - Install ai package and provider packages (latest versions)
    - If --provider specified, install that provider (@ai-sdk/openai, etc.)
    - If no provider specified, install @ai-sdk/openai as default
    - Create lib/ai/config.ts for AI configuration
    - Create app/api/chat/route.ts for streaming chat endpoint
    - If --with-chat: Create components/chat/ with ChatInterface component
    - Add environment variables to .env.example
    - Follow project structure conventions"
})
```

## After Running

1. Add your API key to `.env.local`:
   ```
   OPENAI_API_KEY=your_api_key
   # or
   ANTHROPIC_API_KEY=your_api_key
   ```

2. Use in your components:
   ```typescript
   import { useChat } from 'ai/react'
   
   const { messages, input, handleSubmit } = useChat()
   ```
