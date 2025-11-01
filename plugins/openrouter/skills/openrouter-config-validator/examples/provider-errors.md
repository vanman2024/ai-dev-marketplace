# Provider-Specific Error Handling

Solutions for common errors from different AI providers via OpenRouter.

## Overview

OpenRouter routes requests to multiple providers (OpenAI, Anthropic, Google, etc.). Each provider may return different errors.

## OpenAI Provider Errors

### Error: Invalid Request

**Message:** "Invalid request: ..."

**Common Causes:**
1. Invalid model parameters
2. Unsupported features
3. Malformed request

**Solution:**
```javascript
// Check OpenAI-specific requirements
const response = await openrouter.chat({
  model: 'openai/gpt-4-turbo',
  messages: [...],
  // OpenAI-specific parameters
  temperature: 0.7,      // 0-2
  top_p: 1,              // 0-1
  frequency_penalty: 0,  // -2 to 2
  presence_penalty: 0    // -2 to 2
});
```

### Error: Context Length Exceeded

**Message:** "This model's maximum context length is X tokens"

**Solution:**
```javascript
// Check context limits
const LIMITS = {
  'openai/gpt-4-turbo': 128000,
  'openai/gpt-4': 8192,
  'openai/gpt-3.5-turbo': 16385
};

function truncateToLimit(messages, model) {
  const limit = LIMITS[model];
  const tokenCount = estimateTokens(messages);

  if (tokenCount > limit * 0.8) {  // Use 80% of limit for safety
    // Truncate or summarize older messages
    return messages.slice(-5);
  }

  return messages;
}
```

### Error: Rate Limit (OpenAI)

**Message:** "Rate limit reached for requests"

**Solution:**
```javascript
// Implement OpenAI-specific backoff
async function requestWithOpenAIBackoff(params) {
  const maxRetries = 5;

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await openrouter.chat(params);
    } catch (error) {
      if (error.message.includes('Rate limit') && i < maxRetries - 1) {
        const delay = Math.min(1000 * Math.pow(2, i), 32000);
        console.log(`OpenAI rate limit, waiting ${delay}ms...`);
        await sleep(delay);
        continue;
      }
      throw error;
    }
  }
}
```

## Anthropic Provider Errors

### Error: Invalid API Request

**Message:** "messages.0.content: expected a string, got..."

**Solution:**
```javascript
// Anthropic requires specific message format
const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [
    {
      role: 'user',
      content: 'Hello'  // Must be string for simple messages
    }
  ]
});

// For complex content (images, etc.)
const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [
    {
      role: 'user',
      content: [
        { type: 'text', text: 'What is in this image?' },
        { type: 'image_url', image_url: { url: '...' } }
      ]
    }
  ]
});
```

### Error: Output Limit Exceeded

**Message:** "Output exceeded maximum length"

**Solution:**
```javascript
// Anthropic has output limits
const ANTHROPIC_OUTPUT_LIMITS = {
  'claude-3-opus': 4096,
  'claude-3.5-sonnet': 4096,
  'claude-3-haiku': 4096
};

const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [...],
  max_tokens: 4096  // Respect limit
});
```

### Error: Unsupported Feature (Anthropic)

**Message:** "Feature not supported: function_calling"

**Solution:**
```javascript
// Check Anthropic capabilities
const ANTHROPIC_CAPABILITIES = {
  'function_calling': false,  // Not supported
  'vision': true,             // Supported
  'streaming': true,          // Supported
  'system_messages': true     // Supported
};

// Don't use function calling with Anthropic
const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [...],
  // ❌ functions: [...]  // Not supported
});
```

## Google Provider Errors

### Error: Blocked by Safety

**Message:** "Content blocked by safety filters"

**Solution:**
```javascript
// Adjust safety settings for Gemini
const response = await openrouter.chat({
  model: 'google/gemini-1.5-pro',
  messages: [...],
  // Google-specific safety settings
  safety_settings: [
    {
      category: 'HARM_CATEGORY_HARASSMENT',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE'
    },
    {
      category: 'HARM_CATEGORY_HATE_SPEECH',
      threshold: 'BLOCK_MEDIUM_AND_ABOVE'
    }
  ]
});
```

### Error: Invalid Response Format

**Message:** "Response format not supported"

**Solution:**
```javascript
// Google expects specific format
const response = await openrouter.chat({
  model: 'google/gemini-1.5-pro',
  messages: [
    { role: 'user', content: 'Hello' }  // Simple format
  ],
  // Gemini-specific parameters
  temperature: 1,     // 0-2
  top_p: 0.95,       // 0-1
  top_k: 40          // Google-specific
});
```

## Meta/Llama Provider Errors

### Error: Token Limit Exceeded

**Message:** "Token limit exceeded for Llama model"

**Solution:**
```javascript
// Llama models have smaller context windows
const LLAMA_LIMITS = {
  'meta-llama/llama-3-70b-instruct': 8192,
  'meta-llama/llama-3-8b-instruct': 8192
};

// Keep prompts shorter
const response = await openrouter.chat({
  model: 'meta-llama/llama-3-70b-instruct',
  messages: truncateMessages(messages, 6000)  // Leave room for response
});
```

### Error: Unsupported System Message

**Message:** "System messages not supported"

**Solution:**
```javascript
// Some Llama variants don't support system messages
// Convert system message to user message
function convertSystemMessage(messages) {
  return messages.map(msg => {
    if (msg.role === 'system') {
      return {
        role: 'user',
        content: `Instructions: ${msg.content}`
      };
    }
    return msg;
  });
}

const response = await openrouter.chat({
  model: 'meta-llama/llama-3-8b-instruct',
  messages: convertSystemMessage(messages)
});
```

## Mistral Provider Errors

### Error: Invalid Parameter

**Message:** "Parameter not supported: ..."

**Solution:**
```javascript
// Mistral has limited parameter support
const response = await openrouter.chat({
  model: 'mistral/mistral-large',
  messages: [...],
  temperature: 0.7,  // Supported
  max_tokens: 1000,  // Supported
  // ❌ top_k: 40     // Not supported
  // ❌ frequency_penalty  // Not supported
});
```

## Generic Error Handling

### Universal Error Handler

```javascript
async function handleProviderErrors(requestFn) {
  try {
    return await requestFn();
  } catch (error) {
    const message = error.message || error.toString();

    // OpenAI errors
    if (message.includes('context length')) {
      console.error('Context too long - truncate messages');
      throw new Error('CONTEXT_TOO_LONG');
    }

    // Anthropic errors
    if (message.includes('content: expected a string')) {
      console.error('Invalid Anthropic message format');
      throw new Error('INVALID_MESSAGE_FORMAT');
    }

    // Google errors
    if (message.includes('blocked by safety')) {
      console.error('Content blocked by Google safety filters');
      throw new Error('SAFETY_BLOCKED');
    }

    // Rate limiting
    if (message.includes('rate limit') || error.status === 429) {
      console.error('Rate limited - implement backoff');
      throw new Error('RATE_LIMITED');
    }

    // Provider unavailable
    if (error.status === 503) {
      console.error('Provider temporarily unavailable');
      throw new Error('PROVIDER_UNAVAILABLE');
    }

    // Re-throw unknown errors
    throw error;
  }
}

// Usage
try {
  const response = await handleProviderErrors(() =>
    openrouter.chat({ model, messages })
  );
} catch (error) {
  if (error.message === 'CONTEXT_TOO_LONG') {
    // Retry with truncated messages
  } else if (error.message === 'RATE_LIMITED') {
    // Implement backoff
  }
}
```

### Provider-Aware Fallback

```javascript
function getProviderFromModel(model) {
  return model.split('/')[0];
}

async function requestWithProviderFallback(model, messages) {
  const provider = getProviderFromModel(model);

  try {
    return await openrouter.chat({ model, messages });
  } catch (error) {
    // If provider-specific error, try different provider
    if (isProviderError(error, provider)) {
      console.log(`${provider} failed, trying alternative...`);

      // Map to alternative provider
      const alternatives = {
        'openai': 'anthropic/claude-3-haiku',
        'anthropic': 'openai/gpt-3.5-turbo',
        'google': 'openai/gpt-3.5-turbo'
      };

      const fallbackModel = alternatives[provider];
      if (fallbackModel) {
        return await openrouter.chat({
          model: fallbackModel,
          messages
        });
      }
    }

    throw error;
  }
}
```

## Provider Compatibility Matrix

| Feature | OpenAI | Anthropic | Google | Meta | Mistral |
|---------|--------|-----------|--------|------|---------|
| System Messages | ✅ | ✅ | ✅ | ⚠️ | ✅ |
| Function Calling | ✅ | ❌ | ✅ | ❌ | ✅ |
| Vision | ✅ | ✅ | ✅ | ❌ | ❌ |
| Streaming | ✅ | ✅ | ✅ | ✅ | ✅ |
| JSON Mode | ✅ | ✅ | ✅ | ❌ | ✅ |
| Max Context | 128k | 200k | 2M | 8k | 32k |

## Validation Checklist

- [ ] Check provider capabilities before using features
- [ ] Respect context length limits
- [ ] Use provider-specific parameter formats
- [ ] Handle provider-specific errors gracefully
- [ ] Implement fallback to alternative providers
- [ ] Test with actual provider responses
- [ ] Monitor provider-specific error rates

## Quick Diagnostics

```bash
# Check provider status
bash scripts/check-provider-status.sh openai
bash scripts/check-provider-status.sh anthropic
bash scripts/check-provider-status.sh google

# Test model availability
bash scripts/check-model-availability.sh "openai/gpt-4-turbo"
bash scripts/check-model-availability.sh "anthropic/claude-3.5-sonnet"
```

## Getting Help

For provider-specific issues:

```bash
# Run comprehensive troubleshooting
bash scripts/troubleshoot.sh

# Check specific provider
bash scripts/check-provider-status.sh <provider-name>
```

Or contact support:
- Email: support@openrouter.ai
- Include: Provider name, model, error message, request details
- Ask about: Provider-specific requirements, compatibility issues
