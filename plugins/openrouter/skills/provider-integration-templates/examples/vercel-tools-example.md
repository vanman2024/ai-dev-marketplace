# Vercel AI SDK Tools Example

Complete example of implementing tool calling with Vercel AI SDK and OpenRouter.

## What is Tool Calling?

Tool calling (also called function calling) allows AI models to call external functions to:
- Get real-time data (weather, stock prices, etc.)
- Perform calculations
- Search databases
- Interact with APIs
- Execute custom logic

## Setup

Install dependencies:

```bash
npm install ai @ai-sdk/openai zod
```

## Environment Variables

Create `.env.local`:

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
```

## Step 1: Define Tools

Create `lib/tools.ts`:

```typescript
import { tool } from 'ai';
import { z } from 'zod';

// Weather tool
export const getWeather = tool({
  description: 'Get the current weather for a location',
  parameters: z.object({
    location: z.string().describe('The city and state, e.g. San Francisco, CA'),
    unit: z.enum(['celsius', 'fahrenheit']).default('fahrenheit'),
  }),
  execute: async ({ location, unit }) => {
    // In production, call a real weather API
    const mockData = {
      location,
      temperature: unit === 'celsius' ? 22 : 72,
      condition: 'sunny',
      humidity: 65,
    };
    return mockData;
  },
});

// Calculator tool
export const calculate = tool({
  description: 'Perform mathematical calculations',
  parameters: z.object({
    expression: z.string().describe('Mathematical expression like "2 + 2"'),
  }),
  execute: async ({ expression }) => {
    try {
      // Use a proper math library in production
      const result = eval(expression);
      return { result, expression };
    } catch {
      return { error: 'Invalid expression' };
    }
  },
});

// Search tool
export const search = tool({
  description: 'Search for information',
  parameters: z.object({
    query: z.string().describe('Search query'),
    category: z.enum(['web', 'news', 'images']).default('web'),
  }),
  execute: async ({ query, category }) => {
    // Mock search results
    return {
      query,
      category,
      results: [
        { title: 'Result 1', url: 'https://example.com/1' },
        { title: 'Result 2', url: 'https://example.com/2' },
      ],
    };
  },
});

export const tools = {
  getWeather,
  calculate,
  search,
};
```

## Step 2: API Route with Tools

Create `app/api/chat/route.ts`:

```typescript
import { streamText } from 'ai';
import { openrouter } from '@/lib/ai';
import { tools } from '@/lib/tools';

export const runtime = 'edge';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = await streamText({
    model: openrouter('anthropic/claude-4.5-sonnet'),
    messages,
    tools,
    maxToolRoundtrips: 5, // Allow multiple tool calls
  });

  return result.toDataStreamResponse();
}
```

## Step 3: Frontend Component

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
          <div key={m.id}>
            <div className="font-bold">
              {m.role === 'user' ? 'You' : 'Assistant'}
            </div>

            {/* Show message content */}
            <div className="whitespace-pre-wrap">{m.content}</div>

            {/* Show tool invocations */}
            {m.toolInvocations?.map((tool) => (
              <div key={tool.toolCallId} className="bg-gray-100 p-2 mt-2 rounded">
                <div className="text-sm font-semibold">
                  🔧 Tool: {tool.toolName}
                </div>
                <div className="text-xs">
                  Args: {JSON.stringify(tool.args)}
                </div>
                {tool.state === 'result' && (
                  <div className="text-xs mt-1">
                    Result: {JSON.stringify(tool.result)}
                  </div>
                )}
              </div>
            ))}
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit} className="flex gap-2 mt-4">
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Try: What's the weather in NYC?"
          disabled={isLoading}
          className="flex-1 px-4 py-2 border rounded"
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

## Advanced: Tools with External APIs

### Weather API Tool

```typescript
export const getWeatherReal = tool({
  description: 'Get real weather data',
  parameters: z.object({
    location: z.string(),
  }),
  execute: async ({ location }) => {
    const apiKey = process.env.WEATHER_API_KEY;
    const response = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${location}&appid=${apiKey}`
    );
    const data = await response.json();

    return {
      temperature: Math.round(data.main.temp - 273.15), // Kelvin to Celsius
      condition: data.weather[0].description,
      humidity: data.main.humidity,
    };
  },
});
```

### Database Query Tool

```typescript
import { db } from '@/lib/db';

export const queryDatabase = tool({
  description: 'Query user database',
  parameters: z.object({
    table: z.enum(['users', 'products', 'orders']),
    filter: z.string().optional(),
  }),
  execute: async ({ table, filter }) => {
    // Use your actual database
    const results = await db[table].findMany({
      where: filter ? JSON.parse(filter) : {},
      take: 10,
    });

    return {
      count: results.length,
      data: results,
    };
  },
});
```

### API Request Tool

```typescript
export const makeApiRequest = tool({
  description: 'Make HTTP request to external API',
  parameters: z.object({
    url: z.string().url(),
    method: z.enum(['GET', 'POST']).default('GET'),
    body: z.string().optional(),
  }),
  execute: async ({ url, method, body }) => {
    const response = await fetch(url, {
      method,
      body: body ? JSON.stringify(JSON.parse(body)) : undefined,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    const data = await response.json();
    return data;
  },
});
```

## Tool Execution Flow

1. User sends message: "What's the weather in SF?"
2. Model decides to call `getWeather` tool
3. Tool executes with arguments: `{ location: "San Francisco, CA" }`
4. Tool returns result: `{ temperature: 72, condition: "sunny" }`
5. Model uses result to generate response: "It's currently 72°F and sunny in San Francisco"

## Best Practices

### 1. Clear Descriptions

```typescript
// ❌ Bad
description: 'Gets data'

// ✅ Good
description: 'Get current weather data including temperature, condition, and humidity'
```

### 2. Use Zod for Validation

```typescript
parameters: z.object({
  email: z.string().email(),
  age: z.number().min(0).max(150),
  country: z.enum(['US', 'UK', 'CA']),
})
```

### 3. Handle Errors Gracefully

```typescript
execute: async ({ query }) => {
  try {
    const result = await api.search(query);
    return result;
  } catch (error) {
    return {
      error: 'Search failed',
      message: error.message,
    };
  }
}
```

### 4. Limit Tool Roundtrips

```typescript
const result = await streamText({
  model,
  messages,
  tools,
  maxToolRoundtrips: 3, // Prevent infinite loops
});
```

### 5. Log Tool Calls

```typescript
execute: async (args) => {
  console.log('Tool called:', toolName, args);
  const result = await performAction(args);
  console.log('Tool result:', result);
  return result;
}
```

## Security Considerations

1. **Validate Tool Parameters**: Use Zod schemas
2. **Sanitize Inputs**: Prevent injection attacks
3. **Rate Limit**: Prevent abuse
4. **Authenticate**: Verify user has permission
5. **Audit**: Log all tool calls

```typescript
export const sensitiveOperation = tool({
  description: 'Perform sensitive operation',
  parameters: z.object({
    userId: z.string(),
    action: z.string(),
  }),
  execute: async ({ userId, action }, context) => {
    // Check authentication
    if (!context.user?.isAuthenticated) {
      throw new Error('Unauthorized');
    }

    // Check authorization
    if (context.user.id !== userId) {
      throw new Error('Forbidden');
    }

    // Audit log
    await auditLog.create({
      userId,
      action,
      timestamp: new Date(),
    });

    // Perform action
    return await performAction(action);
  },
});
```

## Testing Tools

```typescript
import { getWeather } from '@/lib/tools';

describe('getWeather tool', () => {
  it('returns weather data', async () => {
    const result = await getWeather.execute({
      location: 'San Francisco, CA',
      unit: 'fahrenheit',
    });

    expect(result).toHaveProperty('temperature');
    expect(result).toHaveProperty('condition');
  });
});
```

## Example Prompts

Try these with your chat interface:

- "What's the weather in New York?"
- "Calculate 15 * 7"
- "Search for information about AI"
- "What's 2+2 and what's the weather in LA?"
- "Convert 100 USD to EUR and check weather in London"

## Next Steps

- Add authentication to tools
- Implement tool middleware
- Create custom tool UI components
- Add tool execution analytics
- Build multi-step tool workflows
