/**
 * Error Handler Template for Vercel AI SDK
 * Handles common provider errors with helpful messages and recovery strategies
 */

export class AIProviderError extends Error {
  constructor(
    message: string,
    public provider: string,
    public statusCode?: number,
    public originalError?: Error
  ) {
    super(message);
    this.name = 'AIProviderError';
  }
}

export interface ErrorHandlerOptions {
  provider: string;
  onRetry?: (attempt: number, delay: number) => void;
  onError?: (error: AIProviderError) => void;
  maxRetries?: number;
  baseDelay?: number;
}

/**
 * Handles provider-specific errors with retry logic
 */
export async function handleProviderError<T>(
  fn: () => Promise<T>,
  options: ErrorHandlerOptions
): Promise<T> {
  const { provider, maxRetries = 3, baseDelay = 1000, onRetry, onError } = options;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      const statusCode = error.status || error.statusCode;

      // Authentication errors (401, 403)
      if (statusCode === 401 || statusCode === 403) {
        const providerError = new AIProviderError(
          `Authentication failed for ${provider}. Check your API key.`,
          provider,
          statusCode,
          error
        );

        onError?.(providerError);

        throw new AIProviderError(
          `Invalid API key for ${provider}. Please check your environment variables:\n` +
          `  - Verify ${getEnvVarName(provider)} is set correctly\n` +
          `  - Ensure the key has the correct format\n` +
          `  - Get a new key from the provider dashboard if needed\n\n` +
          `Provider dashboards:\n` +
          getProviderDashboard(provider),
          provider,
          statusCode,
          error
        );
      }

      // Rate limiting (429)
      if (statusCode === 429) {
        if (attempt < maxRetries - 1) {
          const delay = baseDelay * Math.pow(2, attempt);

          console.warn(
            `Rate limited by ${provider}. Retrying in ${delay}ms... ` +
            `(attempt ${attempt + 1}/${maxRetries})`
          );

          onRetry?.(attempt + 1, delay);
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }

        throw new AIProviderError(
          `Rate limit exceeded for ${provider}. Suggestions:\n` +
          `  - Wait a few minutes and try again\n` +
          `  - Upgrade your API tier for higher limits\n` +
          `  - Implement request queuing in your application\n` +
          `  - Consider using multiple API keys with load balancing`,
          provider,
          statusCode,
          error
        );
      }

      // Model not found (404)
      if (statusCode === 404 || error.message?.includes('model_not_found')) {
        throw new AIProviderError(
          `Model not found for ${provider}. Suggestions:\n` +
          `  - Check the model name is correct\n` +
          `  - Verify the model is available in your region\n` +
          `  - See valid models: ${getProviderDocs(provider)}`,
          provider,
          statusCode,
          error
        );
      }

      // Network errors
      if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
        if (attempt < maxRetries - 1) {
          const delay = baseDelay * Math.pow(2, attempt);
          console.warn(`Network error. Retrying in ${delay}ms...`);
          onRetry?.(attempt + 1, delay);
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }

        throw new AIProviderError(
          `Network error connecting to ${provider}:\n` +
          `  - Check your internet connection\n` +
          `  - Verify the provider API is not down\n` +
          `  - Check for any firewall/proxy issues`,
          provider,
          undefined,
          error
        );
      }

      // Generic errors - throw on last attempt
      if (attempt === maxRetries - 1) {
        throw new AIProviderError(
          `${provider} API error: ${error.message}`,
          provider,
          statusCode,
          error
        );
      }

      // Retry on unknown errors
      const delay = baseDelay * Math.pow(2, attempt);
      console.warn(`Error from ${provider}. Retrying in ${delay}ms...`);
      onRetry?.(attempt + 1, delay);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Unreachable code');
}

/**
 * Get environment variable name for provider
 */
function getEnvVarName(provider: string): string {
  const envVars: Record<string, string> = {
    openai: 'OPENAI_API_KEY',
    anthropic: 'ANTHROPIC_API_KEY',
    google: 'GOOGLE_GENERATIVE_AI_API_KEY',
    xai: 'XAI_API_KEY',
    groq: 'GROQ_API_KEY',
    mistral: 'MISTRAL_API_KEY',
    cohere: 'COHERE_API_KEY',
  };

  return envVars[provider.toLowerCase()] || `${provider.toUpperCase()}_API_KEY`;
}

/**
 * Get provider dashboard URL
 */
function getProviderDashboard(provider: string): string {
  const dashboards: Record<string, string> = {
    openai: 'https://platform.openai.com/api-keys',
    anthropic: 'https://console.anthropic.com/',
    google: 'https://makersuite.google.com/app/apikey',
    xai: 'https://console.x.ai/',
    groq: 'https://console.groq.com/',
    mistral: 'https://console.mistral.ai/',
    cohere: 'https://dashboard.cohere.ai/',
  };

  return dashboards[provider.toLowerCase()] || `Check ${provider} documentation`;
}

/**
 * Get provider documentation URL
 */
function getProviderDocs(provider: string): string {
  return `https://ai-sdk.dev/providers/ai-sdk-providers/${provider.toLowerCase()}`;
}

// Usage example:
/*
import { generateText } from 'ai';
import { openai } from '@ai-sdk/openai';
import { handleProviderError } from './error-handler';

const result = await handleProviderError(
  () => generateText({
    model: openai('gpt-4'),
    prompt: 'Hello',
  }),
  {
    provider: 'openai',
    onRetry: (attempt, delay) => {
      console.log(`Retry attempt ${attempt}, waiting ${delay}ms`);
    },
    onError: (error) => {
      console.error('Provider error:', error);
    },
  }
);
*/
