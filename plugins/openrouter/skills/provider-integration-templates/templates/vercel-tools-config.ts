// vercel-tools-config.ts
// Tool calling configuration for Vercel AI SDK with OpenRouter

import { tool } from 'ai';
import { z } from 'zod';

/**
 * Example tools for Vercel AI SDK
 *
 * Tools allow the AI to call functions to get real-time data,
 * perform calculations, or interact with external systems.
 */

/**
 * Weather tool - Gets weather for a location
 */
export const getWeatherTool = tool({
  description: 'Get the current weather for a location',
  parameters: z.object({
    location: z.string().describe('The city and state, e.g. San Francisco, CA'),
    unit: z.enum(['celsius', 'fahrenheit']).optional().default('fahrenheit'),
  }),
  execute: async ({ location, unit }) => {
    // This is a mock implementation
    // In production, call a real weather API
    return {
      location,
      temperature: unit === 'celsius' ? 22 : 72,
      unit,
      condition: 'sunny',
      humidity: 65,
      windSpeed: 10,
    };
  },
});

/**
 * Calculator tool - Performs mathematical calculations
 */
export const calculatorTool = tool({
  description: 'Perform mathematical calculations',
  parameters: z.object({
    expression: z.string().describe('The mathematical expression to evaluate, e.g. "2 + 2" or "sqrt(16)"'),
  }),
  execute: async ({ expression }) => {
    try {
      // Simple eval for demo - in production use a proper math library
      // eslint-disable-next-line no-eval
      const result = eval(expression);
      return {
        expression,
        result,
        success: true,
      };
    } catch (error) {
      return {
        expression,
        error: error instanceof Error ? error.message : 'Calculation failed',
        success: false,
      };
    }
  },
});

/**
 * Search tool - Searches a knowledge base
 */
export const searchTool = tool({
  description: 'Search a knowledge base for information',
  parameters: z.object({
    query: z.string().describe('The search query'),
    limit: z.number().optional().default(5).describe('Maximum number of results'),
  }),
  execute: async ({ query, limit }) => {
    // Mock implementation
    // In production, search a vector database or search API
    const mockResults = [
      { id: 1, title: 'Result 1', snippet: `Information about ${query}...` },
      { id: 2, title: 'Result 2', snippet: `More details on ${query}...` },
      { id: 3, title: 'Result 3', snippet: `Additional ${query} information...` },
    ];

    return {
      query,
      results: mockResults.slice(0, limit),
      totalFound: mockResults.length,
    };
  },
});

/**
 * Database query tool - Queries a database
 */
export const databaseQueryTool = tool({
  description: 'Query a database to retrieve data',
  parameters: z.object({
    table: z.string().describe('The table name to query'),
    filters: z.record(z.string()).optional().describe('Filters to apply'),
  }),
  execute: async ({ table, filters }) => {
    // Mock implementation
    // In production, connect to your actual database
    return {
      table,
      filters,
      rows: [
        { id: 1, name: 'Example 1', value: 100 },
        { id: 2, name: 'Example 2', value: 200 },
      ],
      count: 2,
    };
  },
});

/**
 * All tools collection
 * Use this in your API route
 */
export const allTools = {
  getWeather: getWeatherTool,
  calculate: calculatorTool,
  search: searchTool,
  queryDatabase: databaseQueryTool,
};

/**
 * Example API route usage:
 *
 * import { streamText } from 'ai';
 * import { model } from '@/lib/ai';
 * import { allTools } from '@/lib/tools';
 *
 * export async function POST(req: Request) {
 *   const { messages } = await req.json();
 *
 *   const result = await streamText({
 *     model,
 *     messages,
 *     tools: allTools,
 *     maxToolRoundtrips: 5, // Allow multiple tool calls
 *   });
 *
 *   return result.toDataStreamResponse();
 * }
 */
