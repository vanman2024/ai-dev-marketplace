// openai-functions.ts
// Function calling example with OpenAI SDK and OpenRouter

import OpenAI from 'openai';

/**
 * OpenAI client configured for OpenRouter
 */
export const client = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  defaultHeaders: {
    'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
    'X-Title': process.env.OPENROUTER_SITE_NAME || 'My App',
  },
});

/**
 * Example function definitions
 */
export const tools: OpenAI.Chat.ChatCompletionTool[] = [
  {
    type: 'function',
    function: {
      name: 'get_weather',
      description: 'Get the current weather for a location',
      parameters: {
        type: 'object',
        properties: {
          location: {
            type: 'string',
            description: 'The city and state, e.g. San Francisco, CA',
          },
          unit: {
            type: 'string',
            enum: ['celsius', 'fahrenheit'],
            description: 'The unit of temperature',
          },
        },
        required: ['location'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'calculate',
      description: 'Perform a mathematical calculation',
      parameters: {
        type: 'object',
        properties: {
          expression: {
            type: 'string',
            description: 'The mathematical expression to evaluate, e.g. "2 + 2"',
          },
        },
        required: ['expression'],
      },
    },
  },
  {
    type: 'function',
    function: {
      name: 'search_database',
      description: 'Search a database for information',
      parameters: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'The search query',
          },
          table: {
            type: 'string',
            description: 'The database table to search',
          },
          limit: {
            type: 'number',
            description: 'Maximum number of results to return',
            default: 10,
          },
        },
        required: ['query', 'table'],
      },
    },
  },
];

/**
 * Function implementations
 */
const functionImplementations: Record<string, (args: any) => any> = {
  get_weather: (args: { location: string; unit?: string }) => {
    // Mock implementation - replace with actual API call
    return {
      location: args.location,
      temperature: args.unit === 'celsius' ? 22 : 72,
      unit: args.unit || 'fahrenheit',
      condition: 'sunny',
      humidity: 65,
    };
  },

  calculate: (args: { expression: string }) => {
    try {
      // Simple eval for demo - use a proper math library in production
      // eslint-disable-next-line no-eval
      const result = eval(args.expression);
      return { result, expression: args.expression };
    } catch (error) {
      return { error: 'Invalid expression' };
    }
  },

  search_database: (args: { query: string; table: string; limit?: number }) => {
    // Mock implementation - replace with actual database query
    return {
      results: [
        { id: 1, name: 'Result 1', relevance: 0.95 },
        { id: 2, name: 'Result 2', relevance: 0.87 },
      ],
      total: 2,
      query: args.query,
      table: args.table,
    };
  },
};

/**
 * Execute a function call
 */
function executeFunction(name: string, args: string): string {
  const implementation = functionImplementations[name];
  if (!implementation) {
    return JSON.stringify({ error: `Unknown function: ${name}` });
  }

  try {
    const parsedArgs = JSON.parse(args);
    const result = implementation(parsedArgs);
    return JSON.stringify(result);
  } catch (error) {
    return JSON.stringify({ error: 'Failed to execute function' });
  }
}

/**
 * Chat with function calling support
 *
 * @param messages Initial messages
 * @param model Model to use
 * @param maxIterations Maximum function call iterations
 * @returns Final assistant response
 */
export async function chatWithFunctions(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model: string = process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet',
  maxIterations: number = 5
): Promise<string> {
  const conversationMessages = [...messages];

  for (let i = 0; i < maxIterations; i++) {
    // Make API call
    const response = await client.chat.completions.create({
      model,
      messages: conversationMessages,
      tools,
      tool_choice: 'auto',
    });

    const message = response.choices[0].message;

    // If no tool calls, we're done
    if (!message.tool_calls || message.tool_calls.length === 0) {
      return message.content || '';
    }

    // Add assistant's message to conversation
    conversationMessages.push(message);

    // Execute each tool call
    for (const toolCall of message.tool_calls) {
      const functionName = toolCall.function.name;
      const functionArgs = toolCall.function.arguments;

      console.log(`Calling function: ${functionName}`);
      console.log(`Arguments: ${functionArgs}`);

      // Execute the function
      const functionResult = executeFunction(functionName, functionArgs);

      console.log(`Result: ${functionResult}\n`);

      // Add function result to conversation
      conversationMessages.push({
        role: 'tool',
        tool_call_id: toolCall.id,
        content: functionResult,
      });
    }
  }

  throw new Error(`Max iterations (${maxIterations}) reached`);
}

/**
 * Stream chat with function calling
 */
export async function streamChatWithFunctions(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model: string = process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet',
  onChunk?: (content: string) => void,
  maxIterations: number = 5
): Promise<string> {
  const conversationMessages = [...messages];

  for (let i = 0; i < maxIterations; i++) {
    const response = await client.chat.completions.create({
      model,
      messages: conversationMessages,
      tools,
      tool_choice: 'auto',
      stream: true,
    });

    let currentMessage: OpenAI.Chat.ChatCompletionMessage = {
      role: 'assistant',
      content: '',
    };
    let currentToolCalls: OpenAI.Chat.ChatCompletionMessageToolCall[] = [];

    // Process stream
    for await (const chunk of response) {
      const delta = chunk.choices[0]?.delta;

      if (delta?.content) {
        currentMessage.content += delta.content;
        onChunk?.(delta.content);
      }

      if (delta?.tool_calls) {
        // Handle tool call deltas
        for (const toolCallDelta of delta.tool_calls) {
          const index = toolCallDelta.index;
          if (!currentToolCalls[index]) {
            currentToolCalls[index] = {
              id: toolCallDelta.id || '',
              type: 'function',
              function: { name: '', arguments: '' },
            };
          }
          if (toolCallDelta.function?.name) {
            currentToolCalls[index].function.name = toolCallDelta.function.name;
          }
          if (toolCallDelta.function?.arguments) {
            currentToolCalls[index].function.arguments += toolCallDelta.function.arguments;
          }
        }
      }
    }

    // If no tool calls, return the content
    if (currentToolCalls.length === 0) {
      return currentMessage.content || '';
    }

    // Add tool calls to message
    currentMessage.tool_calls = currentToolCalls;
    conversationMessages.push(currentMessage);

    // Execute tool calls
    for (const toolCall of currentToolCalls) {
      const result = executeFunction(
        toolCall.function.name,
        toolCall.function.arguments
      );

      conversationMessages.push({
        role: 'tool',
        tool_call_id: toolCall.id,
        content: result,
      });
    }
  }

  throw new Error(`Max iterations (${maxIterations}) reached`);
}

// Example usage (uncomment to test)
/*
async function example() {
  console.log('=== Function Calling Example ===\n');

  const response = await chatWithFunctions([
    { role: 'user', content: "What's the weather in San Francisco?" },
  ]);

  console.log('Final response:', response);

  console.log('\n=== Multiple Function Calls ===\n');

  const response2 = await chatWithFunctions([
    {
      role: 'user',
      content: 'What is 15 * 7, and search the users table for "john"',
    },
  ]);

  console.log('Final response:', response2);
}

example().catch(console.error);
*/
