// openai-sdk-config.ts
// OpenAI SDK configuration for OpenRouter (TypeScript)

import OpenAI from 'openai';

/**
 * OpenAI client configured for OpenRouter
 *
 * This is a drop-in replacement for the standard OpenAI client.
 * All OpenAI SDK features work: chat, streaming, function calling, etc.
 *
 * Just change:
 * 1. baseURL to OpenRouter endpoint
 * 2. apiKey to OpenRouter key
 * 3. Add HTTP-Referer and X-Title headers
 */
export const openai = new OpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  defaultHeaders: {
    // Optional: For OpenRouter rankings and analytics
    'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
    'X-Title': process.env.OPENROUTER_SITE_NAME || 'My App',
  },
});

/**
 * Helper function to create chat completion
 *
 * @param messages Chat messages array
 * @param model Model ID (defaults to env var or Claude 3.5 Sonnet)
 * @param options Additional options
 */
export async function createChatCompletion(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model?: string,
  options?: Partial<OpenAI.Chat.ChatCompletionCreateParams>
) {
  return openai.chat.completions.create({
    model: model || process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet',
    messages,
    ...options,
  });
}

/**
 * Helper function to create streaming chat completion
 *
 * @param messages Chat messages array
 * @param model Model ID (defaults to env var or Claude 3.5 Sonnet)
 * @param options Additional options
 */
export async function createStreamingChatCompletion(
  messages: OpenAI.Chat.ChatCompletionMessageParam[],
  model?: string,
  options?: Partial<OpenAI.Chat.ChatCompletionCreateParams>
) {
  return openai.chat.completions.create({
    model: model || process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet',
    messages,
    stream: true,
    ...options,
  });
}

// Example usage:
async function example() {
  // Simple chat completion
  const completion = await createChatCompletion([
    { role: 'user', content: 'Say "Hello from OpenRouter!"' },
  ]);
  console.log(completion.choices[0].message.content);

  // Streaming chat completion
  const stream = await createStreamingChatCompletion([
    { role: 'user', content: 'Count from 1 to 5' },
  ]);

  for await (const chunk of stream) {
    process.stdout.write(chunk.choices[0]?.delta?.content || '');
  }
  console.log();
}

// Uncomment to run example
// example().catch(console.error);
