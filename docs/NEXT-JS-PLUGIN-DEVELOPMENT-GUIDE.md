# Next.js Frontend Plugin Development Guide

## AI Development Marketplace - Plugin Architecture

This guide documents how to build **Next.js frontend plugins** for the AI Development Marketplace. Our plugins use Next.js as the primary frontend framework for building AI-powered applications with modern tooling and best practices.

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Plugin Structure](#plugin-structure)
4. [Next.js Integration Patterns](#nextjs-integration-patterns)
5. [AI-First Frontend Development](#ai-first-frontend-development)
6. [Testing & Quality Assurance](#testing--quality-assurance)
7. [Deployment Strategies](#deployment-strategies)
8. [Plugin Development Workflow](#plugin-development-workflow)
9. [API Integration Patterns](#api-integration-patterns)
10. [FastAPI Backend Integration](#fastapi-backend-integration)
11. [Mem0 Memory Management](#mem0-memory-management)
12. [Complete Tech Stack Examples](#complete-tech-stack-examples)
13. [Best Practices](#best-practices)

---

## Overview

### What We're Building

The AI Development Marketplace consists of **8 core plugins** that work together to build complete AI applications:

| Plugin             | Purpose                     | Frontend Framework | Target Use Case     |
| ------------------ | --------------------------- | ------------------ | ------------------- |
| `ai-tech-stack-1`  | Complete stack orchestrator | **Next.js 15**     | Full AI platforms   |
| `vercel-ai-sdk`    | AI streaming & models       | **Next.js 15**     | Chat applications   |
| `supabase`         | Database & auth             | **Next.js 15**     | Data-driven apps    |
| `mem0`             | AI memory management        | **Next.js 15**     | Persistent AI       |
| `claude-agent-sdk` | Agent orchestration         | **Next.js 15**     | Multi-agent systems |
| `elevenlabs`       | Voice & audio AI            | **Next.js 15**     | Voice-enabled apps  |
| `openrouter`       | Multi-model routing         | **Next.js 15**     | Model optimization  |
| `website-builder`  | Marketing sites             | **Astro**          | Static content      |

### Why Next.js for AI Applications

✅ **App Router** - Perfect for AI streaming with Server Components  
✅ **Server Actions** - Seamless frontend ↔ backend integration  
✅ **Streaming Support** - Native AI response streaming  
✅ **Type Safety** - TypeScript-first with excellent AI SDK support  
✅ **Performance** - Optimized for real-time AI interactions  
✅ **Deployment** - Vercel integration for production AI apps

### Kitchen vs Appliances Philosophy

Our architecture separates:

- **Kitchen (Next.js)**: Applications with complex interactivity, real-time features, user dashboards
- **Appliances (Astro)**: Marketing sites, documentation, static content

**Rule**: If it has AI streaming, real-time features, or complex state → **Next.js**  
**Rule**: If it's marketing content, docs, or static → **Astro**

---

## Architecture Principles

### 1. Progressive Context Management

**Problem**: Late in conversation, context becomes huge, causing hangs.

**Solution**: Phase-based deployment with agent limits:

```typescript
// Phase 1: Foundation (fresh context)
const MAX_AGENTS_PHASE_1 = 3;

// Phase 2: AI Features (growing context)
const MAX_AGENTS_PHASE_2 = 2;

// Phase 3: Integration (large context)
const MAX_AGENTS_PHASE_3 = 1;

// Auto-resume with saved state
if (contextTooLarge) {
  saveState('.ai-stack-config.json');
  executeCommand('/plugin:resume');
}
```

### 2. Dual-Mode Detection

**Interactive Mode**: No specs found - ask questions  
**Spec-Driven Mode**: `specs/` directory found - auto-configure

```typescript
// Automatic spec detection
if (fs.existsSync('specs/')) {
  // Parse spec.md, plan.md files
  const config = parseSpecFiles();
  return buildAutomatic(config);
} else {
  // Ask user questions
  const answers = await askUserQuestions();
  return buildInteractive(answers);
}
```

### 3. Plugin Composition

Each plugin is **self-contained** but **composable**:

```bash
# Individual plugin usage
/vercel-ai-sdk:new-app my-chat
/supabase:setup

# Orchestrated usage (ai-tech-stack-1)
/ai-tech-stack-1:build-full-stack my-app
# Internally calls:
# - /vercel-ai-sdk:build-full-stack
# - /supabase:setup
# - /mem0:add-memory
# - etc.
```

---

## Plugin Structure

### Standard Directory Layout

```
plugins/your-plugin/
├── README.md                    # Plugin documentation
├── commands/                    # Command implementations
│   ├── new-app.md              # Create new Next.js app
│   ├── add-features.md         # Add specific features
│   ├── deploy.md               # Deployment commands
│   └── validate.md             # Validation commands
├── agents/                     # Specialized agents
│   ├── setup-agent.md          # Initial setup
│   ├── ui-agent.md             # UI components
│   ├── api-agent.md            # API integration
│   └── deploy-agent.md         # Deployment
├── docs/                       # Additional documentation
│   ├── architecture.md         # Architecture decisions
│   ├── examples.md             # Usage examples
│   └── troubleshooting.md      # Common issues
├── skills/                     # Reusable skills
│   ├── nextjs-setup/           # Next.js project setup
│   ├── typescript-config/      # TypeScript configuration
│   ├── tailwind-setup/         # Tailwind CSS setup
│   └── deployment-config/      # Deployment configurations
└── .claude-plugin/
    └── plugin.json             # Plugin metadata
```

### Plugin Metadata Structure

Each plugin uses a simple `README.md` with metadata header and command documentation. The marketplace metadata is centralized in `.claude-plugin/marketplace.json`.

**Plugin README.md Structure:**

```markdown
# Plugin Name

Description of plugin functionality.

## Commands

### `/plugin-name:command-name`

Command description and usage.

## MCP Servers Used

- **supabase-mcp**: Database operations, auth, storage
- **shadcn-mcp**: shadcn/ui components and design system
- **tailwind-ui-mcp**: Tailwind CSS design system from Supabase
- **figma-mcp-application**: Application UI components from Figma
- **figma-mcp-ecommerce**: E-commerce UI components from Figma
- **figma-mcp-marketing**: Marketing UI components from Figma

## Integration Points

- Supabase (database, auth, design system)
- Vercel AI SDK (streaming, models)
- Tailwind CSS (with shadcn/ui + design system components)
- shadcn/ui + Figma MCP servers for component integration
- MCP servers for tool integration
```

**Marketplace Registration:**
Plugins are registered in the central `.claude-plugin/marketplace.json` file with basic metadata only.

## MCP Server Integration

### Core MCP Servers

Our plugins leverage these MCP servers for tool integration:

#### **supabase-mcp**

- Database operations (CRUD, queries, migrations)
- Authentication management
- Storage operations (file upload/download)
- Real-time subscriptions

#### **shadcn-mcp**

- shadcn/ui component access
- Pre-built React components with Tailwind CSS
- Component library integration
- Design system patterns

#### **tailwind-ui-mcp**

- Tailwind CSS design system from Supabase
- Pre-built component library
- Design system integration
- Component configuration and theming

#### **figma-mcp-application**

- Application UI components from Figma
- Application-specific design patterns
- User interface elements

#### **figma-mcp-ecommerce**

- E-commerce UI components from Figma
- Shopping cart, product, and checkout components
- E-commerce design patterns

#### **figma-mcp-marketing**

- Marketing UI components from Figma
- Landing page and promotional components
- Marketing design patterns

---

```

---

## Next.js Integration Patterns

### 1. App Router Architecture

**Standard Next.js 15 App Router Structure:**

```

app/
├── layout.tsx # Root layout with providers
├── page.tsx # Home page
├── globals.css # Global styles (Tailwind)
├── api/ # API routes
│ ├── chat/route.ts # AI streaming endpoint
│ ├── auth/route.ts # Authentication
│ └── data/route.ts # Data operations
├── dashboard/ # Protected routes
│ ├── layout.tsx # Dashboard layout
│ ├── page.tsx # Dashboard home
│ └── chat/page.tsx # Chat interface
└── components/ # Reusable components
├── ui/ # shadcn/ui components
├── chat/ # Chat components
└── providers/ # Context providers

````

### 2. Server Components + Client Components Pattern

**Server Components** (default) for:
- Data fetching
- AI model configuration
- Database queries
- Static content

**Client Components** (`'use client'`) for:
- Real-time streaming
- User interactions
- State management
- Browser APIs

```typescript
// app/chat/page.tsx (Server Component)
import { ChatInterface } from '@/components/chat/ChatInterface'
import { getSessionHistory } from '@/lib/db'

export default async function ChatPage() {
  const history = await getSessionHistory()

  return (
    <div className="container mx-auto p-4">
      <h1>AI Chat</h1>
      <ChatInterface initialHistory={history} />
    </div>
  )
}

// components/chat/ChatInterface.tsx (Client Component)
'use client'

import { useChat } from 'ai/react'
import { useState } from 'react'

export function ChatInterface({ initialHistory }) {
  const { messages, input, handleInputChange, handleSubmit } = useChat({
    api: '/api/chat',
    initialMessages: initialHistory
  })

  return (
    <div className="chat-container">
      {/* Chat UI */}
    </div>
  )
}
````

### 3. API Routes for AI Integration

```typescript
// app/api/chat/route.ts
import { streamText } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';
import { auth } from '@/lib/auth';

export async function POST(req: Request) {
  const { messages } = await req.json();
  const user = await auth();

  if (!user) {
    return new Response('Unauthorized', { status: 401 });
  }

  const result = await streamText({
    model: anthropic('claude-3-5-sonnet-20241022'),
    messages,
    tools: {
      // Custom tools
    },
  });

  return result.toDataStreamResponse();
}
```

### 4. Environment Configuration

```typescript
// .env.local (development)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=

// .env.production (production)
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_API_KEY=
NEXT_PUBLIC_BACKEND_URL=https://api.yourapp.com
```

---

## AI-First Frontend Development

### 1. Streaming AI Responses

**Pattern**: Use Vercel AI SDK for streaming:

````typescript
### 2. Enhanced Streaming with Tool Calling

**Advanced Pattern with FastAPI Backend Integration:**

```typescript
// components/chat/StreamingChat.tsx
'use client';

import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { useState } from 'react';

interface ToolCall {
  type: string;
  name: string;
  arguments: Record<string, any>;
  result?: any;
}

interface EnhancedMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  toolCalls?: ToolCall[];
}

export function EnhancedStreamingChat() {
  const [sessionId] = useState(() => `session_${Date.now()}`);

  const { messages, sendMessage, input, handleInputChange, isLoading } = useChat<EnhancedMessage>({
    transport: new DefaultChatTransport({
      api: 'http://localhost:8000/api/chat/stream', // FastAPI backend
    }),
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('auth_token')}`,
    },
    body: {
      session_id: sessionId,
      model: 'gpt-4',
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    sendMessage({
      text: input,
    });
  };

  return (
    <div className="flex flex-col h-full">
      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`flex ${
              message.role === 'user' ? 'justify-end' : 'justify-start'
            }`}
          >
            <div
              className={`max-w-xs lg:max-w-md px-4 py-2 rounded-lg ${
                message.role === 'user'
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-100 text-gray-800'
              }`}
            >
              <div className="whitespace-pre-wrap">
                {message.content}
              </div>

              {/* Tool calls display */}
              {message.toolCalls && message.toolCalls.length > 0 && (
                <div className="mt-2 space-y-1">
                  {message.toolCalls.map((toolCall, index) => (
                    <div key={index} className="text-xs">
                      <Badge variant="secondary" className="mr-1">
                        🔧 {toolCall.name}
                      </Badge>
                      {toolCall.result && (
                        <div className="mt-1 p-2 bg-gray-50 rounded text-xs">
                          {JSON.stringify(toolCall.result, null, 2)}
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-gray-100 px-4 py-2 rounded-lg">
              <div className="animate-pulse">AI is thinking...</div>
            </div>
          </div>
        )}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="p-4 border-t">
        <div className="flex space-x-2">
          <Input
            value={input}
            onChange={handleInputChange}
            placeholder="Type your message..."
            className="flex-1"
            disabled={isLoading}
          />
          <Button type="submit" disabled={isLoading || !input.trim()}>
            Send
          </Button>
        </div>
        <div className="text-xs text-gray-500 mt-1">
          Session: {sessionId} • Connected to FastAPI backend
        </div>
      </form>
    </div>
  );
}
````

### 2. Multi-Model Support

```typescript
// lib/ai-models.ts
import { anthropic } from '@ai-sdk/anthropic';
import { openai } from '@ai-sdk/openai';
import { google } from '@ai-sdk/google';

export const models = {
  claude: anthropic('claude-3-5-sonnet-20241022'),
  gpt4: openai('gpt-4-turbo'),
  gemini: google('gemini-1.5-pro'),
};

export function getModel(modelName: string) {
  return models[modelName] || models.claude;
}

// app/api/chat/route.ts
import { getModel } from '@/lib/ai-models';

export async function POST(req: Request) {
  const { messages, model = 'claude' } = await req.json();

  const result = await streamText({
    model: getModel(model),
    messages,
  });

  return result.toDataStreamResponse();
}
```

### 3. Server Actions with Memory Integration

**Memory-Enhanced Server Actions:**

```typescript
// app/actions.ts
'use server';

import { streamUI } from '@ai-sdk/rsc';
import { anthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';
import { ReactNode } from 'react';

// Memory service client (integrate with your FastAPI backend)
class MemoryClient {
  private baseUrl = process.env.FASTAPI_BACKEND_URL || 'http://localhost:8000';
  private authToken = process.env.BACKEND_AUTH_TOKEN;

  async getRelevantMemories(query: string, userId: string, limit: number = 3) {
    try {
      const response = await fetch(
        `${this.baseUrl}/api/memory/context/${encodeURIComponent(query)}`,
        {
          headers: {
            Authorization: `Bearer ${this.authToken}`,
            'X-User-ID': userId,
          },
        }
      );

      if (response.ok) {
        const data = await response.json();
        return data.user || [];
      }
      return [];
    } catch (error) {
      console.error('Error fetching memories:', error);
      return [];
    }
  }

  async saveConversation(userId: string, messages: any[], sessionId?: string) {
    try {
      await fetch(`${this.baseUrl}/api/memory/conversation`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.authToken}`,
        },
        body: JSON.stringify({
          user_id: userId,
          messages,
          session_id: sessionId,
        }),
      });
    } catch (error) {
      console.error('Error saving conversation:', error);
    }
  }
}

const memoryClient = new MemoryClient();

// Enhanced Weather Component with Memory
const WeatherComponent = ({
  location,
  weather,
  context,
}: {
  location: string;
  weather: string;
  context?: string;
}) => (
  <div className="border border-neutral-200 p-4 rounded-lg max-w-fit">
    <div className="font-semibold">Weather in {location}</div>
    <div className="text-lg">{weather}</div>
    {context && (
      <div className="text-sm text-gray-600 mt-2">Context: {context}</div>
    )}
  </div>
);

// Note Component
const NoteComponent = ({
  title,
  content,
  saved,
}: {
  title: string;
  content: string;
  saved: boolean;
}) => (
  <div className="border border-green-200 bg-green-50 p-4 rounded-lg max-w-fit">
    <div className="font-semibold text-green-800">{title}</div>
    <div className="text-green-700 mt-1">{content}</div>
    <div className="text-xs text-green-600 mt-2">
      {saved ? '✅ Saved to memory' : '⏳ Saving...'}
    </div>
  </div>
);

export async function streamComponentWithMemory(
  prompt: string,
  userId: string,
  sessionId?: string
): Promise<ReactNode> {
  // Get relevant memories first
  const memories = await memoryClient.getRelevantMemories(prompt, userId, 3);
  const memoryContext =
    memories.length > 0
      ? `Previous context: ${memories.map((m) => m.memory).join('; ')}`
      : '';

  const result = await streamUI({
    model: anthropic('claude-3-5-sonnet-20241022'),
    prompt: `${prompt}\n\nUser context: ${memoryContext}`,
    text: ({ content }) => <div className="prose">{content}</div>,
    tools: {
      getWeather: {
        description: 'Get weather for a location with user context',
        inputSchema: z.object({
          location: z.string().describe('The location to get weather for'),
        }),
        generate: async function* ({ location }) {
          yield (
            <div className="animate-pulse p-4">
              Getting weather for {location}...
            </div>
          );

          // Simulate weather API call
          await new Promise((resolve) => setTimeout(resolve, 1500));
          const weather = '22°C, Partly cloudy';

          // Save weather request to memory
          await memoryClient.saveConversation(
            userId,
            [
              { role: 'user', content: `Asked for weather in ${location}` },
              { role: 'assistant', content: `Provided weather: ${weather}` },
            ],
            sessionId
          );

          return (
            <WeatherComponent
              location={location}
              weather={weather}
              context={
                memoryContext ? 'Based on your location preferences' : undefined
              }
            />
          );
        },
      },
      saveNote: {
        description: 'Save a note with title and content',
        inputSchema: z.object({
          title: z.string().describe('Note title'),
          content: z.string().describe('Note content'),
        }),
        generate: async function* ({ title, content }) {
          yield <NoteComponent title={title} content={content} saved={false} />;

          // Save to FastAPI backend
          try {
            await fetch(`${process.env.FASTAPI_BACKEND_URL}/api/notes`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${process.env.BACKEND_AUTH_TOKEN}`,
              },
              body: JSON.stringify({
                user_id: userId,
                title,
                content,
                session_id: sessionId,
              }),
            });

            // Also save to memory
            await memoryClient.saveConversation(
              userId,
              [
                { role: 'user', content: `Saved note: ${title}` },
                { role: 'assistant', content: `Note saved: ${content}` },
              ],
              sessionId
            );

            return (
              <NoteComponent title={title} content={content} saved={true} />
            );
          } catch (error) {
            return (
              <div className="border border-red-200 bg-red-50 p-4 rounded-lg text-red-800">
                Failed to save note: {error.message}
              </div>
            );
          }
        },
      },
    },
  });

  return result.value;
}

// Multi-step conversation with memory
export async function continueConversationWithMemory(
  input: string,
  userId: string,
  sessionId?: string
): Promise<{ id: string; role: string; display: ReactNode }> {
  const memories = await memoryClient.getRelevantMemories(input, userId, 5);
  const memoryContext = memories.map((m) => `- ${m.memory}`).join('\n');

  const result = await streamUI({
    model: anthropic('claude-3-5-sonnet-20241022'),
    prompt: `User input: ${input}\n\nRelevant memories:\n${memoryContext}\n\nProvide a helpful response based on the context.`,
    text: ({ content, done }) => {
      if (done) {
        // Save conversation in background
        memoryClient.saveConversation(
          userId,
          [
            { role: 'user', content: input },
            { role: 'assistant', content: content },
          ],
          sessionId
        );
      }
      return <div className="prose">{content}</div>;
    },
    tools: {
      // Include all your tools here
      getWeather: {
        description: 'Get weather information',
        inputSchema: z.object({
          location: z.string(),
        }),
        generate: async function* ({ location }) {
          yield <div>Getting weather...</div>;
          const weather = '25°C, Sunny';
          return <WeatherComponent location={location} weather={weather} />;
        },
      },
    },
  });

  return {
    id: `msg_${Date.now()}`,
    role: 'assistant',
    display: result.value,
  };
}
```

### 4. Tool Calling Integration

```typescript
// lib/tools.ts
import { z } from 'zod';
import { tool } from 'ai';

export const weatherTool = tool({
  description: 'Get current weather for a location',
  parameters: z.object({
    location: z.string().describe('The city and country'),
  }),
  execute: async ({ location }) => {
    // Call weather API
    const response = await fetch(`/api/weather?location=${location}`);
    return await response.json();
  },
});

export const databaseTool = tool({
  description: 'Query the database',
  parameters: z.object({
    query: z.string().describe('SQL query to execute'),
  }),
  execute: async ({ query }) => {
    // Execute database query
    const result = await executeQuery(query);
    return result;
  },
});

// app/api/chat/route.ts
import { weatherTool, databaseTool } from '@/lib/tools';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    model: anthropic('claude-3-5-sonnet-20241022'),
    messages,
    tools: {
      weather: weatherTool,
      database: databaseTool,
    },
  });

  return result.toDataStreamResponse();
}
```

---

## Testing & Quality Assurance

### 1. Playwright Integration

**Setup:**

```typescript
// playwright.config.ts
import { defineConfig } from 'next/experimental/testmode/playwright';

export default defineConfig({
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
  },
  use: {
    baseURL: 'http://localhost:3000',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
```

**AI-Specific Tests:**

```typescript
// tests/chat.spec.ts
import { test, expect } from '@playwright/test';

test('AI chat streaming works', async ({ page }) => {
  await page.goto('/chat');

  // Type message
  await page.fill('[data-testid="chat-input"]', 'Hello AI');
  await page.click('[data-testid="send-button"]');

  // Wait for streaming response
  await expect(page.locator('[data-testid="ai-response"]')).toBeVisible();

  // Check response appears
  await expect(page.locator('[data-testid="ai-response"]')).toContainText(
    'Hello'
  );
});

test('memory persistence works', async ({ page }) => {
  await page.goto('/chat');

  // Send first message
  await page.fill('[data-testid="chat-input"]', 'My name is John');
  await page.click('[data-testid="send-button"]');

  // Wait for response
  await page.waitForSelector('[data-testid="ai-response"]');

  // Send follow-up
  await page.fill('[data-testid="chat-input"]', 'What is my name?');
  await page.click('[data-testid="send-button"]');

  // Check AI remembers
  await expect(
    page.locator('[data-testid="ai-response"]').last()
  ).toContainText('John');
});
```

**MSW Integration:**

```typescript
// tests/api-mocking.spec.ts
import {
  test,
  expect,
  http,
  HttpResponse,
} from 'next/experimental/testmode/playwright/msw';

test.use({
  mswHandlers: [
    [
      http.post('/api/chat', () => {
        return HttpResponse.json({
          content: 'Mocked AI response',
          role: 'assistant',
        });
      }),
    ],
  ],
});

test('mocked AI responses', async ({ page }) => {
  await page.goto('/chat');

  await page.fill('[data-testid="chat-input"]', 'Test message');
  await page.click('[data-testid="send-button"]');

  await expect(page.locator('[data-testid="ai-response"]')).toContainText(
    'Mocked AI response'
  );
});
```

### 2. Component Testing

```typescript
// tests/components/ChatInterface.spec.tsx
import { test, expect } from '@playwright/experimental-ct-react';
import { ChatInterface } from '@/components/chat/ChatInterface';

test('chat interface renders correctly', async ({ mount }) => {
  const component = await mount(
    <ChatInterface
      initialHistory={[
        { id: '1', role: 'user', content: 'Hello' },
        { id: '2', role: 'assistant', content: 'Hi there!' },
      ]}
    />
  );

  await expect(component.getByText('Hello')).toBeVisible();
  await expect(component.getByText('Hi there!')).toBeVisible();
});
```

### 3. Performance Testing

```typescript
// tests/performance.spec.ts
import { test, expect } from '@playwright/test';

test('AI streaming performance', async ({ page }) => {
  await page.goto('/chat');

  // Start performance measurement
  const startTime = Date.now();

  await page.fill('[data-testid="chat-input"]', 'Generate a long response');
  await page.click('[data-testid="send-button"]');

  // Wait for first streaming chunk
  await page.waitForSelector('[data-testid="ai-response"]');
  const firstChunkTime = Date.now() - startTime;

  // Should get first response within 2 seconds
  expect(firstChunkTime).toBeLessThan(2000);
});
```

---

## Deployment Strategies

### 1. Vercel Deployment (Primary)

**Automatic Configuration:**

```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "functions": {
    "app/api/chat/route.ts": {
      "maxDuration": 30
    }
  },
  "env": {
    "ANTHROPIC_API_KEY": "@anthropic-api-key",
    "OPENAI_API_KEY": "@openai-api-key"
  }
}
```

**Environment Variables:**

```bash
# Set via Vercel CLI or dashboard
vercel env add ANTHROPIC_API_KEY production
vercel env add OPENAI_API_KEY production
vercel env add NEXT_PUBLIC_SUPABASE_URL production
```

### 2. Self-Hosted Deployment

**Docker Setup:**

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

**Docker Compose:**

```yaml
# docker-compose.yml
version: '3.8'
services:
  nextjs-app:
    build: .
    ports:
      - '3000:3000'
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - NEXT_PUBLIC_SUPABASE_URL=${SUPABASE_URL}
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=app
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### 3. Edge Deployment

**Edge Functions:**

```typescript
// app/api/chat/route.ts
import { anthropic } from '@ai-sdk/anthropic';
import { streamText } from 'ai';

export const runtime = 'edge';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    model: anthropic('claude-3-5-sonnet-20241022'),
    messages,
  });

  return result.toDataStreamResponse();
}
```

---

## Plugin Development Workflow

### 1. Command Structure

Each command follows this pattern:

````markdown
<!-- commands/new-app.md -->

# Create New Next.js AI Application

## Purpose

Create a new Next.js 15 application optimized for AI features.

## Usage

```bash
/your-plugin:new-app [app-name]
```
````

## Implementation

### Step 1: Create Next.js Project

Create new Next.js project with TypeScript and Tailwind CSS.

### Step 2: Install AI Dependencies

Install Vercel AI SDK and provider packages.

### Step 3: Configure Environment

Set up environment variables and configuration files.

### Step 4: Create Basic Structure

Generate app structure with basic AI integration.

## File Structure Created

```
your-app/
├── app/
│   ├── layout.tsx
│   ├── page.tsx
│   └── api/chat/route.ts
├── components/
│   └── ui/
├── lib/
│   ├── ai.ts
│   └── utils.ts
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── .env.local
```

## Environment Variables

```bash
ANTHROPIC_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
```

## Next Steps

After creation, run:

```bash
cd your-app
npm run dev
```

Visit http://localhost:3000 to see your AI application.

````

### 2. Agent Structure

```markdown
<!-- agents/setup-agent.md -->
# Next.js Setup Agent

## Purpose
Specialized agent for setting up Next.js 15 applications with AI features.

## Capabilities
- Creates optimized Next.js project structure
- Configures TypeScript and Tailwind CSS
- Sets up Vercel AI SDK integration
- Configures environment variables
- Creates basic AI chat interface

## Documentation Sources
Will fetch from:
- https://nextjs.org/docs/app
- https://ai-sdk.dev/docs/getting-started
- https://ui.shadcn.com/docs/installation/next

## Implementation Details

### Project Setup
1. Use `create-next-app` with TypeScript template
2. Install and configure Tailwind CSS
3. Set up shadcn/ui component library
4. Configure absolute imports

### AI Integration
1. Install Vercel AI SDK
2. Configure AI providers (Anthropic, OpenAI)
3. Create streaming API routes
4. Set up chat interface components

### File Generation
Creates all necessary files for a working AI application.

## Error Handling
- Validates Node.js version (>=18)
- Checks for existing project conflicts
- Validates API key format
- Tests AI provider connectivity
````

### 3. Skill Structure

````markdown
<!-- skills/nextjs-setup/README.md -->

# Next.js Setup Skill

## Purpose

Reusable skill for creating Next.js 15 projects with AI optimizations.

## Parameters

- `appName`: Project name
- `framework`: 'nextjs'
- `language`: 'typescript' | 'javascript'
- `styling`: 'tailwind' | 'css-modules'
- `aiProvider`: 'anthropic' | 'openai' | 'google'

## Implementation

1. Creates project directory
2. Initializes package.json
3. Installs dependencies
4. Configures TypeScript/JavaScript
5. Sets up styling solution
6. Configures AI provider

## Dependencies

- Node.js >=18
- npm or yarn or pnpm

## Outputs

- Complete Next.js project
- AI integration configured
- Development server ready

## Usage in Commands

```markdown
Use the nextjs-setup skill to create a new project with these parameters:

- appName: ${appName}
- language: typescript
- styling: tailwind
- aiProvider: anthropic
```
````

````

---

## API Integration Patterns

### 1. Backend Communication

**API Client Setup:**

```typescript
// lib/api-client.ts
class APIClient {
  private baseURL: string

  constructor() {
    this.baseURL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'
  }

  async post<T>(endpoint: string, data: any): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data)
    })

    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`)
    }

    return response.json()
  }

  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseURL}${endpoint}`)

    if (!response.ok) {
      throw new Error(`API Error: ${response.statusText}`)
    }

    return response.json()
  }
}

export const apiClient = new APIClient()
````

### 2. Real-time Integration

**WebSocket Setup:**

```typescript
// lib/websocket.ts
import { useEffect, useState } from 'react';

export function useWebSocket(url: string) {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const ws = new WebSocket(url);

    ws.onopen = () => {
      setIsConnected(true);
      setSocket(ws);
    };

    ws.onclose = () => {
      setIsConnected(false);
      setSocket(null);
    };

    return () => {
      ws.close();
    };
  }, [url]);

  const sendMessage = (message: any) => {
    if (socket && isConnected) {
      socket.send(JSON.stringify(message));
    }
  };

  return { socket, isConnected, sendMessage };
}

// Usage in component
export function RealtimeChat() {
  const { socket, isConnected, sendMessage } = useWebSocket(
    'ws://localhost:8000/ws'
  );

  useEffect(() => {
    if (socket) {
      socket.onmessage = (event) => {
        const message = JSON.parse(event.data);
        // Handle real-time message
      };
    }
  }, [socket]);

  return (
    <div>
      Status: {isConnected ? 'Connected' : 'Disconnected'}
      {/* Chat interface */}
    </div>
  );
}
```

### 3. Server Actions Integration

```typescript
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { apiClient } from '@/lib/api-client';

export async function createChatSession(formData: FormData) {
  const name = formData.get('name') as string;

  try {
    const session = await apiClient.post('/api/chat/sessions', { name });
    revalidatePath('/dashboard');
    return { success: true, session };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Usage in component
import { createChatSession } from '@/app/actions';

export function CreateSessionForm() {
  return (
    <form action={createChatSession}>
      <input name="name" placeholder="Session name" required />
      <button type="submit">Create Session</button>
    </form>
  );
}
```

---

## Best Practices

### 1. Code Organization

```
src/
├── app/                        # App Router pages
├── components/                 # Reusable components
│   ├── ui/                    # shadcn/ui components
│   ├── chat/                  # Chat-specific components
│   ├── forms/                 # Form components
│   └── layout/                # Layout components
├── lib/                       # Utilities and configurations
│   ├── ai/                    # AI-related utilities
│   ├── db/                    # Database utilities
│   ├── auth/                  # Authentication
│   └── utils.ts               # General utilities
├── hooks/                     # Custom React hooks
├── types/                     # TypeScript type definitions
└── styles/                    # Global styles
```

### 2. TypeScript Patterns

```typescript
// types/chat.ts
export interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

export interface ChatSession {
  id: string;
  name: string;
  messages: Message[];
  createdAt: Date;
  updatedAt: Date;
}

export interface AIProvider {
  name: string;
  model: string;
  apiKey: string;
  baseURL?: string;
}

// lib/ai/types.ts
import type { Message } from '@/types/chat';

export interface StreamingResponse {
  content: string;
  isComplete: boolean;
  tokens?: number;
}

export interface AIConfig {
  provider: AIProvider;
  model: string;
  temperature?: number;
  maxTokens?: number;
}
```

### 3. Error Handling

```typescript
// lib/error-handling.ts
export class AIError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500
  ) {
    super(message);
    this.name = 'AIError';
  }
}

export function handleAPIError(error: unknown) {
  if (error instanceof AIError) {
    return {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
    };
  }

  if (error instanceof Error) {
    return {
      message: error.message,
      code: 'UNKNOWN_ERROR',
      statusCode: 500,
    };
  }

  return {
    message: 'An unknown error occurred',
    code: 'UNKNOWN_ERROR',
    statusCode: 500,
  };
}

// app/api/chat/route.ts
import { handleAPIError } from '@/lib/error-handling';

export async function POST(req: Request) {
  try {
    // AI streaming logic
  } catch (error) {
    const { message, statusCode } = handleAPIError(error);
    return new Response(JSON.stringify({ error: message }), {
      status: statusCode,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}
```

### 4. Performance Optimization

```typescript
// components/chat/OptimizedChatList.tsx
import { memo, useMemo } from 'react';
import { Message } from '@/types/chat';

interface ChatListProps {
  messages: Message[];
}

export const OptimizedChatList = memo(function ChatList({
  messages,
}: ChatListProps) {
  const sortedMessages = useMemo(() => {
    return messages.sort(
      (a, b) =>
        new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime()
    );
  }, [messages]);

  return (
    <div className="space-y-4">
      {sortedMessages.map((message) => (
        <MessageItem key={message.id} message={message} />
      ))}
    </div>
  );
});

const MessageItem = memo(function MessageItem({
  message,
}: {
  message: Message;
}) {
  return (
    <div
      className={`flex ${
        message.role === 'user' ? 'justify-end' : 'justify-start'
      }`}
    >
      <div className="max-w-md px-4 py-2 rounded-lg bg-gray-100">
        {message.content}
      </div>
    </div>
  );
});
```

### 5. Security Best Practices

```typescript
// lib/auth/middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { verifyJWT } from '@/lib/auth/jwt';

export async function authMiddleware(req: NextRequest) {
  const token = req.headers.get('authorization')?.replace('Bearer ', '');

  if (!token) {
    return new NextResponse('Unauthorized', { status: 401 });
  }

  try {
    const payload = await verifyJWT(token);
    // Add user to request context
    return NextResponse.next({
      request: {
        headers: new Headers({
          ...req.headers,
          'x-user-id': payload.userId,
        }),
      },
    });
  } catch (error) {
    return new NextResponse('Invalid token', { status: 401 });
  }
}

// middleware.ts
import { authMiddleware } from '@/lib/auth/middleware';

export function middleware(req: NextRequest) {
  if (req.nextUrl.pathname.startsWith('/api/')) {
    return authMiddleware(req);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/api/:path*'],
};
```

---

## Summary

This documentation provides the foundation for building Next.js frontend plugins for the AI Development Marketplace. Key takeaways:

✅ **Use Next.js 15 App Router** for all AI applications  
✅ **Implement progressive context management** to prevent hangs  
✅ **Support dual-mode detection** (interactive + spec-driven)  
✅ **Follow plugin composition patterns** for orchestration  
✅ **Integrate Playwright for testing** with MSW mocking  
✅ **Deploy primarily to Vercel** with edge function support  
✅ **Maintain TypeScript-first development** with strict types  
✅ **Implement proper error handling** and performance optimization

Each plugin should be **self-contained** but **composable**, allowing developers to use individual plugins or orchestrate complete stacks via `ai-tech-stack-1`.

The goal is to enable rapid development of production-ready AI applications with Next.js as the primary frontend framework, supported by comprehensive testing, deployment, and integration patterns.
