---
description: Build a complete full-stack AI application with Vercel AI SDK including frontend UI, backend API, streaming, and AI provider integration
argument-hint: <project-name> [framework]
---

# Build Full-Stack AI App

**Project Name:** `$0`
**Framework Preference:** `$1`

---

## Execution Notice

When invoked, YOU execute these phases using available tools.

---

## Available Skills

- **agent-workflow-patterns**: AI agent workflow patterns
- **generative-ui-patterns**: Generative UI with AI SDK RSC
- **provider-config-validator**: Provider configuration validation
- **rag-implementation**: RAG implementation patterns
- **testing-patterns**: Testing patterns for AI SDK

---

## Security Requirements

@docs/security/SECURITY-RULES.md

**Key requirements:**

- Never hardcode API keys
- Use `.env.example` with placeholders
- Document key acquisition

---

## Phase 1: Project Discovery

**Goal:** Gather project requirements

**Actions:**

1. Use `$0` as project name, or ask: "What should we name your project?"
2. Framework from `$1` or ask: "Next.js, React (Vite), SvelteKit, or Node.js API only?"
3. Ask: "Primary AI provider? OpenAI, Anthropic, Google, xAI, or AI Gateway (unified access)?"
4. Ask: "Include generative UI components? (yes/no)"

---

## Phase 2: Fetch Documentation

**Goal:** Get essential docs for selected stack

**Actions (parallel fetch):**

```
WebFetch: https://ai-sdk.dev/docs/introduction
WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/overview
WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/overview
WebFetch: https://ai-sdk.dev/providers/ai-sdk-providers/[selected-provider]
```

If AI Gateway selected:

```
WebFetch: https://ai-sdk.dev/providers/ai-sdk-providers/ai-gateway
```

If generative UI selected:

```
WebFetch: https://ai-sdk.dev/docs/ai-sdk-rsc/overview
```

---

## Phase 3: Project Scaffold

**Goal:** Create complete project structure

**Actions:**

1. **Create project directory** with `$0` name

2. **Initialize based on framework:**

   **Next.js (App Router):**

   ```bash
   npx create-next-app@latest $1 --typescript --tailwind --eslint --app --src-dir
   cd $1
   npm install ai @ai-sdk/[provider]
   ```

   **React (Vite):**

   ```bash
   npm create vite@latest $1 -- --template react-ts
   cd $1
   npm install ai @ai-sdk/[provider]
   ```

   **SvelteKit:**

   ```bash
   npx sv create $1 --template minimal --types ts
   cd $1
   npm install ai @ai-sdk/[provider]
   ```

   **Node.js API:**

   ```bash
   mkdir $1 && cd $1
   npm init -y
   npm install ai @ai-sdk/[provider] express
   npm install -D typescript @types/node tsx
   ```

3. **If AI Gateway selected:**
   ```bash
   # No additional package needed - gateway is built into 'ai' package
   # Just import { gateway } from 'ai'
   ```

---

## Phase 4: Core Implementation

**Goal:** Implement full-stack AI features

### Backend API Route

**Next.js (`app/api/chat/route.ts`):**

```typescript
import { streamText } from 'ai';
import { openai } from '@ai-sdk/openai'; // or selected provider

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: openai('gpt-4o'),
    messages,
  });

  return result.toDataStreamResponse();
}
```

**If AI Gateway:**

```typescript
import { streamText, gateway } from 'ai';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: gateway('openai/gpt-4o'), // Unified provider access
    messages,
    providerOptions: {
      gateway: {
        // Optional: model fallbacks
        models: [
          'anthropic/claude-sonnet-4-20250514',
          'google/gemini-2.0-flash',
        ],
      },
    },
  });

  return result.toDataStreamResponse();
}
```

### Frontend Chat UI

**Next.js/React (`app/page.tsx` or `src/App.tsx`):**

```typescript
'use client';

import { useChat } from '@ai-sdk/react';

export default function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();

  return (
    <div className="flex flex-col h-screen max-w-2xl mx-auto p-4">
      <div className="flex-1 overflow-y-auto space-y-4">
        {messages.map((m) => (
          <div key={m.id} className={`p-3 rounded-lg ${
            m.role === 'user' ? 'bg-blue-100 ml-auto' : 'bg-gray-100'
          }`}>
            <p className="font-semibold">{m.role === 'user' ? 'You' : 'AI'}</p>
            <p>{m.content}</p>
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="flex gap-2 mt-4">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Type a message..."
          className="flex-1 p-2 border rounded"
          disabled={isLoading}
        />
        <button
          type="submit"
          disabled={isLoading}
          className="px-4 py-2 bg-blue-500 text-white rounded disabled:opacity-50"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```

---

## Phase 5: Environment Setup

**Goal:** Configure secure environment

**Actions:**

1. **Create `.env.example`:**

   ```env
   # AI Provider API Key
   OPENAI_API_KEY=your_openai_key_here
   # Or for other providers:
   # ANTHROPIC_API_KEY=your_anthropic_key_here
   # GOOGLE_GENERATIVE_AI_API_KEY=your_google_key_here
   # XAI_API_KEY=your_xai_key_here
   ```

2. **If AI Gateway on Vercel:**

   ```env
   # AI Gateway uses Vercel's secure credential storage
   # Configure providers in Vercel Dashboard > AI > Providers
   # Or use BYOK (Bring Your Own Key) with standard env vars
   ```

3. **Update `.gitignore`:**

   ```
   .env
   .env.local
   ```

4. **Document API key acquisition** in README.md

---

## Phase 6: Verification

**Goal:** Ensure everything works

**Actions:**

Invoke appropriate verifier based on language:

- **TypeScript**: `Task(vercel-ai-verifier-ts)`
- **JavaScript**: `Task(vercel-ai-verifier-js)`
- **Python**: `Task(vercel-ai-verifier-py)`

Verify:

- Packages installed correctly
- TypeScript compiles without errors
- Dev server starts
- API route responds
- Chat UI renders

---

## Phase 7: Next Steps

**Goal:** Guide user to add more features

**Output:**

```
✅ Full-stack AI app created: $1

To run:
  cd $1
  npm run dev

To add features, use /vercel-ai-sdk:add <feature>:

  /vercel-ai-sdk:add tools          # Function/tool calling
  /vercel-ai-sdk:add ai-gateway     # Multi-provider AI Gateway
  /vercel-ai-sdk:add generative-ui  # AI-generated React components
  /vercel-ai-sdk:add middleware     # Custom model middleware
  /vercel-ai-sdk:add mcp            # Model Context Protocol
  /vercel-ai-sdk:add rag            # Retrieval augmented generation
  /vercel-ai-sdk:add attachments    # File uploads
  /vercel-ai-sdk:add production     # Observability & deployment

Resources:
  📖 Docs: https://ai-sdk.dev/docs
  🔧 Examples: https://ai-sdk.dev/examples
  🚀 Deploy: https://vercel.com/new
```

---

## Important Notes

- Creates COMPLETE working app with chat UI and API
- Use `/vercel-ai-sdk:add` to incrementally add features
- AI Gateway provides unified access to all major providers
- Always verify with appropriate language verifier
