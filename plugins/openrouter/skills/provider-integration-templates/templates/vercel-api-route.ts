// vercel-api-route.ts
// API route template with streaming support for Vercel AI SDK + OpenRouter

import { streamText } from 'ai';
import { openrouter } from '@/lib/ai'; // Import from your config file

// Force dynamic rendering (disable static optimization)
export const dynamic = 'force-dynamic';

/**
 * POST /api/chat
 *
 * Streaming chat endpoint using Vercel AI SDK with OpenRouter
 */
export async function POST(req: Request) {
  try {
    // Parse request body
    const { messages } = await req.json();

    // Validate messages
    if (!messages || !Array.isArray(messages)) {
      return new Response('Invalid request: messages array required', {
        status: 400,
      });
    }

    // Get model from environment or use default
    const model = openrouter(
      process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet'
    );

    // Stream the response
    const result = await streamText({
      model,
      messages,
      // Optional: Add system prompt
      system: 'You are a helpful assistant.',
      // Optional: Configure parameters
      temperature: 0.7,
      maxTokens: 2000,
      // Optional: Add tools (see vercel-tools-config.ts)
      // tools: { ... },
    });

    // Return streaming response
    return result.toDataStreamResponse();
  } catch (error) {
    console.error('Chat API error:', error);

    // Handle specific errors
    if (error instanceof Error) {
      // Rate limit errors
      if (error.message.includes('rate limit')) {
        return new Response('Rate limit exceeded. Please try again later.', {
          status: 429,
        });
      }

      // Authentication errors
      if (error.message.includes('401') || error.message.includes('Unauthorized')) {
        return new Response('Invalid API key', { status: 401 });
      }

      // Model not found
      if (error.message.includes('404') || error.message.includes('not found')) {
        return new Response('Model not found', { status: 404 });
      }
    }

    // Generic error
    return new Response('Internal server error', { status: 500 });
  }
}
