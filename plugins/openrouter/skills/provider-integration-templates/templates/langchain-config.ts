// langchain-config.ts
// OpenRouter configuration for LangChain (TypeScript)

import { ChatOpenAI } from '@langchain/openai';
import 'dotenv/config';

/**
 * Configuration options for OpenRouter chat
 */
interface OpenRouterChatOptions {
  model?: string;
  temperature?: number;
  maxTokens?: number;
  streaming?: boolean;
}

/**
 * Create a ChatOpenAI instance configured for OpenRouter
 *
 * @param options Configuration options
 * @returns ChatOpenAI instance configured for OpenRouter
 *
 * Common models:
 * - anthropic/claude-4.5-sonnet - Best reasoning, long context
 * - anthropic/claude-4.5-sonnet - Most capable, highest quality
 * - meta-llama/llama-3.1-70b-instruct - Fast, cost-effective
 * - openai/gpt-4-turbo - Strong general purpose
 * - google/gemini-pro-1.5 - Long context, multimodal
 */
export function getOpenRouterChat(options: OpenRouterChatOptions = {}) {
  // Get configuration from environment
  const apiKey = process.env.OPENROUTER_API_KEY;
  if (!apiKey) {
    throw new Error('OPENROUTER_API_KEY environment variable not set');
  }

  const model =
    options.model ||
    process.env.OPENROUTER_MODEL ||
    'anthropic/claude-4.5-sonnet';
  const baseURL =
    process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1';

  // Optional: Site info for OpenRouter rankings
  const siteUrl = process.env.OPENROUTER_SITE_URL || 'http://localhost:3000';
  const siteName = process.env.OPENROUTER_SITE_NAME || 'My App';

  // Create ChatOpenAI instance
  return new ChatOpenAI({
    modelName: model,
    openAIApiKey: apiKey,
    configuration: {
      baseURL,
      defaultHeaders: {
        'HTTP-Referer': siteUrl,
        'X-Title': siteName,
      },
    },
    temperature: options.temperature ?? 0.7,
    maxTokens: options.maxTokens ?? 2000,
    streaming: options.streaming ?? false,
  });
}

// Pre-configured instances for common models
export const claude35Sonnet = getOpenRouterChat({
  model: 'anthropic/claude-4.5-sonnet',
});

export const claude3Opus = getOpenRouterChat({
  model: 'anthropic/claude-4.5-sonnet',
});

export const gpt4Turbo = getOpenRouterChat({
  model: 'openai/gpt-4-turbo',
});

export const llama70b = getOpenRouterChat({
  model: 'meta-llama/llama-3.1-70b-instruct',
});

// Example usage:
async function example() {
  // Simple chat
  const llm = getOpenRouterChat();
  const response = await llm.invoke("Say 'Hello from OpenRouter!'");
  console.log(response.content);

  // Streaming chat
  const llmStreaming = getOpenRouterChat({ streaming: true });
  const stream = await llmStreaming.stream('Count from 1 to 5');
  for await (const chunk of stream) {
    process.stdout.write(chunk.content.toString());
  }
  console.log();
}

// Uncomment to run example
// example().catch(console.error);
