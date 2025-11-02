# Rate Limiting Guide

Understanding and handling OpenRouter rate limits.

## Understanding Rate Limits

OpenRouter implements rate limiting to ensure fair usage and system stability.

### Rate Limit Types

1. **Requests per minute (RPM)**
   - Limits total requests in 60-second window
   - Varies by account tier and model

2. **Tokens per minute (TPM)**
   - Limits total tokens processed
   - Includes both prompt and completion tokens

3. **Concurrent requests**
   - Maximum simultaneous active requests
   - Usually 3-10 depending on tier

## Rate Limit Response

When you hit a rate limit, OpenRouter returns:

**HTTP Status:** 429 Too Many Requests

**Response Headers:**
```
X-RateLimit-Limit-Requests: 60
X-RateLimit-Remaining-Requests: 0
X-RateLimit-Reset-Requests: 2025-10-31T12:34:56Z
```

**Response Body:**
```json
{
  "error": {
    "message": "Rate limit exceeded. Please retry after...",
    "type": "rate_limit_exceeded",
    "code": 429
  }
}
```

## Checking Rate Limits

### Via API Response Headers

```bash
curl -i https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-4.5-sonnet",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

Look for headers:
- `X-RateLimit-Limit-Requests`
- `X-RateLimit-Remaining-Requests`
- `X-RateLimit-Reset-Requests`

### Via Account Dashboard

1. Visit https://openrouter.ai/settings/limits
2. View current limits for your tier
3. See current usage

## Handling Rate Limits

### Strategy 1: Exponential Backoff

Retry with increasing delays:

```javascript
async function makeRequestWithBackoff(options, maxRetries = 5) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch('https://openrouter.ai/api/v1/chat/completions', options);

      if (response.status === 429) {
        // Get retry-after time
        const retryAfter = response.headers.get('Retry-After') || Math.pow(2, i);
        console.log(`Rate limited. Retrying after ${retryAfter}s...`);
        await sleep(retryAfter * 1000);
        continue;
      }

      return response;
    } catch (error) {
      if (i === maxRetries - 1) throw error;
    }
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

```python
import time
import requests

def make_request_with_backoff(url, headers, data, max_retries=5):
    for i in range(max_retries):
        response = requests.post(url, headers=headers, json=data)

        if response.status_code == 429:
            retry_after = int(response.headers.get('Retry-After', 2 ** i))
            print(f'Rate limited. Retrying after {retry_after}s...')
            time.sleep(retry_after)
            continue

        return response

    raise Exception('Max retries exceeded')
```

### Strategy 2: Request Queuing

Queue requests and process at controlled rate:

```javascript
class RateLimitedQueue {
  constructor(requestsPerMinute) {
    this.queue = [];
    this.processing = false;
    this.requestsPerMinute = requestsPerMinute;
    this.delayBetweenRequests = (60 * 1000) / requestsPerMinute;
  }

  async add(requestFn) {
    return new Promise((resolve, reject) => {
      this.queue.push({ requestFn, resolve, reject });
      if (!this.processing) {
        this.process();
      }
    });
  }

  async process() {
    this.processing = true;

    while (this.queue.length > 0) {
      const { requestFn, resolve, reject } = this.queue.shift();

      try {
        const result = await requestFn();
        resolve(result);
      } catch (error) {
        reject(error);
      }

      // Wait before next request
      if (this.queue.length > 0) {
        await new Promise(r => setTimeout(r, this.delayBetweenRequests));
      }
    }

    this.processing = false;
  }
}

// Usage
const queue = new RateLimitedQueue(60); // 60 req/min

const result = await queue.add(() =>
  fetch('https://openrouter.ai/api/v1/chat/completions', options)
);
```

### Strategy 3: Token Bucket Algorithm

More sophisticated rate limiting:

```python
import time
import threading

class TokenBucket:
    def __init__(self, rate, capacity):
        self.rate = rate  # tokens per second
        self.capacity = capacity
        self.tokens = capacity
        self.last_update = time.time()
        self.lock = threading.Lock()

    def consume(self, tokens=1):
        with self.lock:
            now = time.time()
            # Add tokens based on time elapsed
            elapsed = now - self.last_update
            self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
            self.last_update = now

            # Try to consume tokens
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True
            return False

    def wait_for_token(self, tokens=1):
        while not self.consume(tokens):
            time.sleep(0.1)

# Usage
bucket = TokenBucket(rate=1, capacity=60)  # 60 req/min

def make_request():
    bucket.wait_for_token()
    # Make API request
```

### Strategy 4: Respect Retry-After Header

Always check and respect the `Retry-After` header:

```javascript
async function makeRequest(options) {
  const response = await fetch(url, options);

  if (response.status === 429) {
    const retryAfter = response.headers.get('Retry-After');

    if (retryAfter) {
      // Retry-After can be seconds or HTTP date
      const delay = isNaN(retryAfter)
        ? new Date(retryAfter) - new Date()
        : retryAfter * 1000;

      console.log(`Waiting ${delay}ms before retry...`);
      await sleep(delay);
      return makeRequest(options);
    }
  }

  return response;
}
```

## Optimizing for Rate Limits

### 1. Batch Requests

Instead of many small requests, batch them:

```javascript
// ❌ Bad: Many separate requests
for (const item of items) {
  await processItem(item);
}

// ✅ Good: Batch processing
const batchSize = 10;
for (let i = 0; i < items.length; i += batchSize) {
  const batch = items.slice(i, i + batchSize);
  await Promise.all(batch.map(processItem));
  await sleep(1000); // Respect rate limits
}
```

### 2. Cache Responses

Avoid redundant requests:

```javascript
const cache = new Map();

async function getCachedResponse(prompt) {
  const cacheKey = JSON.stringify(prompt);

  if (cache.has(cacheKey)) {
    console.log('Cache hit');
    return cache.get(cacheKey);
  }

  const response = await makeRequest(prompt);
  cache.set(cacheKey, response);
  return response;
}
```

### 3. Use Streaming

For long responses, use streaming to reduce token count:

```javascript
const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: 'anthropic/claude-4.5-sonnet',
    messages: [{ role: 'user', content: prompt }],
    stream: true  // Enable streaming
  })
});

// Process stream
for await (const chunk of response.body) {
  // Handle chunk
}
```

### 4. Set max_tokens

Limit response size to stay within token limits:

```javascript
{
  model: 'anthropic/claude-4.5-sonnet',
  messages: [...],
  max_tokens: 1000  // Limit response length
}
```

### 5. Monitor Usage

Track your request patterns:

```javascript
class RateLimitMonitor {
  constructor() {
    this.requests = [];
  }

  recordRequest() {
    const now = Date.now();
    this.requests.push(now);

    // Remove requests older than 1 minute
    this.requests = this.requests.filter(t => now - t < 60000);
  }

  getRequestsPerMinute() {
    return this.requests.length;
  }

  isNearLimit(limit) {
    return this.getRequestsPerMinute() >= limit * 0.9;  // 90% of limit
  }
}
```

## Rate Limit Tiers

Different account tiers have different limits:

| Tier | Requests/Min | Tokens/Min | Concurrent |
|------|--------------|------------|------------|
| Free | 10 | 20,000 | 1 |
| Basic | 60 | 200,000 | 3 |
| Pro | 300 | 1,000,000 | 10 |
| Enterprise | Custom | Custom | Custom |

**Note:** Actual limits may vary. Check https://openrouter.ai/settings/limits

## Model-Specific Limits

Some models have additional limits:

- **GPT-4**: Lower RPM due to high demand
- **Claude Opus**: May have stricter limits
- **Free models**: Often have tighter restrictions

**Check model-specific limits:**
```bash
bash scripts/check-model-availability.sh "model-name"
```

## Best Practices

### 1. Implement Retry Logic

Always include retry logic with exponential backoff:

```javascript
const maxRetries = 5;
const baseDelay = 1000;

for (let i = 0; i < maxRetries; i++) {
  try {
    return await makeRequest();
  } catch (error) {
    if (error.status === 429 && i < maxRetries - 1) {
      const delay = baseDelay * Math.pow(2, i);
      await sleep(delay);
      continue;
    }
    throw error;
  }
}
```

### 2. Monitor Rate Limit Headers

Track remaining requests:

```javascript
function checkRateLimits(response) {
  const remaining = response.headers.get('X-RateLimit-Remaining-Requests');
  const reset = response.headers.get('X-RateLimit-Reset-Requests');

  if (parseInt(remaining) < 5) {
    console.warn(`Low rate limit: ${remaining} requests remaining`);
    console.warn(`Resets at: ${reset}`);
  }
}
```

### 3. Distribute Load

If possible, use multiple API keys:

```javascript
const keys = [key1, key2, key3];
let currentKeyIndex = 0;

function getNextKey() {
  const key = keys[currentKeyIndex];
  currentKeyIndex = (currentKeyIndex + 1) % keys.length;
  return key;
}
```

### 4. Fallback to Cheaper Models

When rate limited, fall back to models with higher limits:

```javascript
const modelPriority = [
  'anthropic/claude-4.5-sonnet',  // Primary
  'anthropic/claude-4.5-sonnet',     // Fallback 1 (cheaper, higher limits)
  'openai/gpt-3.5-turbo'          // Fallback 2
];

async function makeRequestWithFallback(messages) {
  for (const model of modelPriority) {
    try {
      return await makeRequest(model, messages);
    } catch (error) {
      if (error.status === 429) {
        console.log(`${model} rate limited, trying next...`);
        continue;
      }
      throw error;
    }
  }
}
```

## Testing Rate Limits

### Simulate Rate Limiting

```bash
#!/bin/bash
# Test rate limiting behavior

echo "Sending rapid requests to test rate limits..."

for i in {1..100}; do
  curl -s -w "\nHTTP %{http_code}\n" \
    https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "anthropic/claude-4.5-sonnet",
      "messages": [{"role": "user", "content": "Test"}],
      "max_tokens": 10
    }' | grep "HTTP"

  sleep 0.1
done
```

### Monitor Rate Limit Status

```bash
# Check current rate limit status
bash scripts/analyze-usage.sh
```

## Troubleshooting

### Issue: Constant 429 Errors

**Solution:**
1. Check your current tier limits
2. Implement exponential backoff
3. Reduce request rate
4. Consider upgrading tier

### Issue: Intermittent Rate Limiting

**Solution:**
1. Monitor request patterns
2. Implement request queuing
3. Add caching layer
4. Spread requests over time

### Issue: Rate Limits Vary by Model

**Solution:**
1. Check model-specific limits
2. Use fallback models
3. Distribute load across models
4. Monitor per-model usage

## Getting Help

If rate limiting issues persist:

```bash
# Run comprehensive troubleshooting
bash scripts/troubleshoot.sh

# Analyze usage patterns
bash scripts/analyze-usage.sh
```

Or contact support:
- Email: support@openrouter.ai
- Include: Account tier, model used, request frequency
- Ask about: Limit increases, custom tiers
