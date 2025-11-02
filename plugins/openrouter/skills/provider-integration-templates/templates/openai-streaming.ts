// openai-streaming.ts
// Streaming chat example with OpenAI SDK and OpenRouter

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
 * Stream a chat completion
 *
 * @param messages Chat messages array
 * @param model Model ID
 * @param onChunk Callback for each streamed chunk
 * @param onComplete Callback when stream completes
 * @param onError Callback for errors
 */
export async function streamChat(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model: string = process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet',
  onChunk?: (content: string) => void,
  onComplete?: (fullContent: string) => void,
  onError?: (error: Error) => void
): Promise<string> {
  let fullContent = '';

  try {
    const stream = await client.chat.completions.create({
      model,
      messages,
      stream: true,
    });

    for await (const chunk of stream) {
      const content = chunk.choices[0]?.delta?.content || '';
      if (content) {
        fullContent += content;
        onChunk?.(content);
      }
    }

    onComplete?.(fullContent);
    return fullContent;
  } catch (error) {
    const err = error instanceof Error ? error : new Error(String(error));
    onError?.(err);
    throw err;
  }
}

/**
 * Stream a chat completion with Server-Sent Events (SSE)
 * Useful for API routes in Next.js, Express, etc.
 *
 * @param messages Chat messages array
 * @param model Model ID
 * @returns ReadableStream for SSE
 */
export async function streamChatSSE(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model: string = process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet'
): Promise<ReadableStream> {
  const stream = await client.chat.completions.create({
    model,
    messages,
    stream: true,
  });

  const encoder = new TextEncoder();

  return new ReadableStream({
    async start(controller) {
      try {
        for await (const chunk of stream) {
          const content = chunk.choices[0]?.delta?.content || '';
          if (content) {
            // Send as Server-Sent Event
            const data = `data: ${JSON.stringify({ content })}\n\n`;
            controller.enqueue(encoder.encode(data));
          }
        }

        // Send completion signal
        controller.enqueue(encoder.encode('data: [DONE]\n\n'));
        controller.close();
      } catch (error) {
        controller.error(error);
      }
    },
  });
}

/**
 * Stream a chat completion to console
 * Useful for CLI applications
 *
 * @param messages Chat messages array
 * @param model Model ID
 */
export async function streamToConsole(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model: string = process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet'
): Promise<string> {
  return streamChat(
    messages,
    model,
    (chunk) => process.stdout.write(chunk), // Write each chunk to console
    (fullContent) => {
      process.stdout.write('\n');
      console.log(`\nTotal characters: ${fullContent.length}`);
    },
    (error) => console.error('Error:', error)
  );
}

/**
 * Example: Next.js API route with streaming
 *
 * app/api/chat/route.ts:
 *
 * import { streamChatSSE } from '@/lib/streaming';
 *
 * export async function POST(req: Request) {
 *   const { messages } = await req.json();
 *
 *   const stream = await streamChatSSE(messages);
 *
 *   return new Response(stream, {
 *     headers: {
 *       'Content-Type': 'text/event-stream',
 *       'Cache-Control': 'no-cache',
 *       'Connection': 'keep-alive',
 *     },
 *   });
 * }
 */

/**
 * Example: React component consuming SSE stream
 *
 * 'use client';
 *
 * import { useState } from 'react';
 *
 * export default function Chat() {
 *   const [response, setResponse] = useState('');
 *   const [isLoading, setIsLoading] = useState(false);
 *
 *   async function sendMessage(message: string) {
 *     setIsLoading(true);
 *     setResponse('');
 *
 *     const res = await fetch('/api/chat', {
 *       method: 'POST',
 *       headers: { 'Content-Type': 'application/json' },
 *       body: JSON.stringify({
 *         messages: [{ role: 'user', content: message }],
 *       }),
 *     });
 *
 *     const reader = res.body?.getReader();
 *     const decoder = new TextDecoder();
 *
 *     while (true) {
 *       const { done, value } = await reader.read();
 *       if (done) break;
 *
 *       const chunk = decoder.decode(value);
 *       const lines = chunk.split('\n');
 *
 *       for (const line of lines) {
 *         if (line.startsWith('data: ')) {
 *           const data = line.slice(6);
 *           if (data === '[DONE]') {
 *             setIsLoading(false);
 *             continue;
 *           }
 *           const { content } = JSON.parse(data);
 *           setResponse((prev) => prev + content);
 *         }
 *       }
 *     }
 *   }
 *
 *   return (
 *     <div>
 *       <button onClick={() => sendMessage('Hello!')}>Send</button>
 *       <div>{response}</div>
 *     </div>
 *   );
 * }
 */

// Example usage (uncomment to test)
/*
async function example() {
  console.log('Streaming example:\n');

  await streamToConsole([
    { role: 'user', content: 'Count from 1 to 10' },
  ]);
}

example().catch(console.error);
*/
