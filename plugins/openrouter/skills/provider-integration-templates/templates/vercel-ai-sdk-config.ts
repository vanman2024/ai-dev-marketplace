// vercel-ai-sdk-config.ts
// OpenRouter provider configuration for Vercel AI SDK

import { createOpenAI } from '@ai-sdk/openai';

/**
 * OpenRouter provider instance
 *
 * Use this as a drop-in replacement for OpenAI provider with any OpenRouter model.
 * Supports all Vercel AI SDK features: streaming, tool calling, embeddings.
 */
export const openrouter = createOpenAI({
  apiKey: process.env.OPENROUTER_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  headers: {
    // Optional: For OpenRouter rankings and analytics
    'HTTP-Referer': process.env.OPENROUTER_SITE_URL || 'http://localhost:3000',
    'X-Title': process.env.OPENROUTER_SITE_NAME || 'My App',
  },
});

/**
 * Default model configuration
 *
 * Common OpenRouter models:
 * - anthropic/claude-4.5-sonnet - Best reasoning, long context
 * - anthropic/claude-4.5-sonnet - Most capable, highest quality
 * - meta-llama/llama-3.1-70b-instruct - Fast, cost-effective
 * - openai/gpt-4-turbo - Strong general purpose
 * - google/gemini-pro-1.5 - Long context, multimodal
 */
export const defaultModel = openrouter(
  process.env.OPENROUTER_MODEL || 'anthropic/claude-4.5-sonnet'
);

/**
 * Example: Create a specific model instance
 */
export const claude35Sonnet = openrouter('anthropic/claude-4.5-sonnet');
export const gpt4Turbo = openrouter('openai/gpt-4-turbo');
export const llama70b = openrouter('meta-llama/llama-3.1-70b-instruct');
