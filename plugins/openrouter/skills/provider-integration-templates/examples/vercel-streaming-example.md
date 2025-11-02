# Vercel AI SDK Streaming Example

Complete example of setting up a streaming chat application with Vercel AI SDK and OpenRouter.

## Project Structure

```
my-app/
├── app/
│   ├── api/
│   │   └── chat/
│   │       └── route.ts          # API route
│   ├── page.tsx                  # Home page with chat
│   └── layout.tsx
├── components/
│   └── chat.tsx                  # Chat component
├── lib/
│   └── ai.ts                     # OpenRouter config
├── .env.local                    # Environment variables
├── package.json
└── tsconfig.json
```

## Step 1: Install Dependencies

```bash
# Using npm
npm install ai @ai-sdk/openai zod

# Using pnpm
pnpm add ai @ai-sdk/openai zod

# Using yarn
yarn add ai @ai-sdk/openai zod
```

## Step 2: Environment Variables

Create `.env.local`:

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet

# Optional: For OpenRouter rankings
OPENROUTER_SITE_URL=https://yourapp.com
OPENROUTER_SITE_NAME=YourApp
```

## Step 3: OpenRouter Configuration

Create `lib/ai.ts`:

```typescript
import { createOpenAI } from '@ai-sdk/openai';

export const openrouter = createOpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  headers: {
    'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
    'X-Title': process.env.OPENROUTER_SITE_NAME || 'My App',
  },
});

export const model = openrouter(
  process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet'
);
```

## Step 4: API Route

Create `app/api/chat/route.ts`:

```typescript
import { streamText } from 'ai';
import { model } from '@/lib/ai';

export const runtime = 'edge';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    model,
    messages,
    system: 'You are a helpful assistant.',
    temperature: 0.7,
    maxTokens: 2000,
  });

  return result.toDataStreamResponse();
}
```

## Step 5: Chat Component

Create `components/chat.tsx`:

```typescript
'use client';

import { useChat } from 'ai/react';

export default function Chat() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat();

  return (
    <div className="flex flex-col h-screen max-w-2xl mx-auto p-4">
      <div className="flex-1 overflow-y-auto space-y-4">
        {messages.map((m) => (
          <div key={m.id} className={m.role === 'user' ? 'text-right' : 'text-left'}>
            <div
              className={`inline-block px-4 py-2 rounded-lg ${
                m.role === 'user' ? 'bg-blue-500 text-white' : 'bg-gray-200'
              }`}
            >
              {m.content}
            </div>
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="flex gap-2 mt-4">
        <input
          value={input}
          onChange={handleInputChange}
          className="flex-1 px-4 py-2 border rounded"
          placeholder="Type a message..."
          disabled={isLoading}
        />
        <button
          type="submit"
          disabled={isLoading}
          className="px-4 py-2 bg-blue-500 text-white rounded"
        >
          Send
        </button>
      </form>
    </div>
  );
}
```

## Step 6: Use Component

Update `app/page.tsx`:

```typescript
import Chat from '@/components/chat';

export default function Home() {
  return (
    <main>
      <Chat />
    </main>
  );
}
```

## Step 7: Run Development Server

```bash
npm run dev
```

Visit `http://localhost:3000` and start chatting!

## Features

- **Real-time Streaming**: Responses stream token-by-token
- **Message History**: Automatically maintained by `useChat()`
- **Loading States**: Built-in loading indicators
- **Error Handling**: Automatic error recovery
- **Type Safety**: Full TypeScript support

## Customization

### Change Model

Update `.env.local`:

```bash
OPENROUTER_MODEL=openai/gpt-4-turbo
```

### Add System Prompt

Modify `app/api/chat/route.ts`:

```typescript
const result = await streamText({
  model,
  messages,
  system: 'You are a helpful coding assistant specialized in TypeScript.',
  // ...
});
```

### Adjust Temperature

Control response creativity:

```typescript
const result = await streamText({
  model,
  messages,
  temperature: 1.0, // More creative (0.0 - 2.0)
  // ...
});
```

### Add Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit';

const ratelimit = new Ratelimit({
  redis: /* ... */,
  limiter: Ratelimit.slidingWindow(10, '1 m'),
});

export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'anonymous';
  const { success } = await ratelimit.limit(ip);

  if (!success) {
    return new Response('Rate limit exceeded', { status: 429 });
  }

  // ... rest of handler
}
```

## Troubleshooting

**Issue**: Streaming not working
- Ensure `runtime = 'edge'` is set
- Check API key is valid
- Verify model supports streaming

**Issue**: CORS errors
- Add proper HTTP-Referer header
- Check OPENROUTER_SITE_URL is set

**Issue**: Model not found
- Verify model ID format: `provider/model-name`
- Check model is available on OpenRouter

## Next Steps

- Add tool calling (see `vercel-tools-example.md`)
- Implement conversation persistence
- Add authentication
- Deploy to Vercel
