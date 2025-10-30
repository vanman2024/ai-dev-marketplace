# Error Handling Implementation Example

Comprehensive error handling patterns for ElevenLabs API with retry logic, circuit breaker, fallback strategies, and structured logging.

## Overview

This example demonstrates:
- Error categorization and routing
- Exponential backoff retry with jitter
- Circuit breaker pattern
- Fallback strategies
- Structured error logging
- User-friendly error messages

## Files

- `basic-error-handling.js` - Simple error handling
- `advanced-retry-logic.js` - Production retry patterns
- `circuit-breaker-example.js` - Circuit breaker integration
- `fallback-strategies.js` - Graceful degradation
- `README.md` - This file

## Quick Start

### 1. Basic Error Handling

```javascript
const { ErrorHandler } = require('../../templates/error-handler.js.template');

const errorHandler = new ErrorHandler({
  logger: require('winston').createLogger(...)
});

// Make API call with automatic retry
try {
  const result = await errorHandler.executeWithRetry(
    async () => {
      return await elevenLabs.textToSpeech({
        text: "Hello world",
        voice_id: "21m00Tcm4TlvDq8ikWAM"
      });
    },
    {
      context: {
        method: 'text-to-speech',
        model: 'eleven_multilingual_v2'
      }
    }
  );
  console.log("Success:", result);
} catch (error) {
  console.error("Failed after retries:", error);
}
```

### 2. Error Categories

```javascript
const { ErrorCategory } = require('../../templates/error-handler.js.template');

// Errors are automatically categorized:
// - RATE_LIMIT: 429 errors -> exponential backoff, 5 retries
// - SERVER_ERROR: 5xx errors -> exponential backoff, 3 retries
// - CLIENT_ERROR: 4xx errors -> no retry
// - NETWORK_ERROR: connection issues -> linear backoff, 3 retries
// - TIMEOUT: timeouts -> fixed delay, 2 retries
```

## Production Patterns

### Custom Retry Configuration

```javascript
const errorHandler = new ErrorHandler({ logger });

// Override default retry config for specific error category
errorHandler.retryConfigs[ErrorCategory.RATE_LIMIT] = {
  maxRetries: 10,              // More retries for rate limits
  strategy: 'exponential',
  initialDelay: 2000,          // Start with 2s
  maxDelay: 60000,             // Cap at 60s
  jitter: true,                // Add randomness
  shouldRetry: true
};

// Use custom config
await errorHandler.executeWithRetry(makeAPICall);
```

### Retry with Context

```javascript
// Add context for better debugging
await errorHandler.executeWithRetry(
  async () => makeAPICall(),
  {
    maxRetries: 5,
    context: {
      method: 'text-to-speech',
      model: 'eleven_turbo_v2',
      userId: 'user-123',
      requestId: 'req-456',
      voice: 'Sarah'
    }
  }
);

// Context appears in all log messages:
// {
//   "level": "error",
//   "message": "Request failed",
//   "method": "text-to-speech",
//   "model": "eleven_turbo_v2",
//   "userId": "user-123",
//   "requestId": "req-456"
// }
```

## Advanced Patterns

### Circuit Breaker Integration

```javascript
const { ErrorHandler } = require('../../templates/error-handler.js.template');
const { CircuitBreaker } = require('../../templates/rate-limiter.js.template');

// Create circuit breaker
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5,        // Open after 5 failures
  resetTimeout: 60000,        // Try reset after 60s
  monitorInterval: 5000       // Check every 5s
});

// Create error handler with circuit breaker
const errorHandler = new ErrorHandler({
  logger,
  circuitBreaker
});

// Circuit breaker automatically prevents requests when open
try {
  await errorHandler.executeWithRetry(makeAPICall);
} catch (error) {
  if (error.message === 'Circuit breaker is OPEN') {
    console.log('Service degraded, circuit breaker open');
    // Use fallback strategy
  }
}
```

### Fallback Strategies

```javascript
// Primary + fallback function
const result = await errorHandler.executeWithFallback(
  // Primary: Generate new audio
  async () => {
    return await elevenLabs.textToSpeech({
      text: "Hello world",
      voice_id: "21m00Tcm4TlvDq8ikWAM"
    });
  },
  // Fallback: Return cached audio
  async () => {
    console.log('Using cached audio');
    return await cache.get('cached-audio-key');
  },
  {
    context: { method: 'text-to-speech' }
  }
);
```

### Multiple Fallback Levels

```javascript
async function makeRequestWithFallbacks(text) {
  // Level 1: Try premium voice
  try {
    return await errorHandler.executeWithRetry(
      async () => elevenLabs.textToSpeech({
        text,
        voice_id: "premium_voice",
        model_id: "eleven_multilingual_v2"
      })
    );
  } catch (error) {
    console.log('Premium voice failed, trying standard');
  }

  // Level 2: Try standard voice
  try {
    return await errorHandler.executeWithRetry(
      async () => elevenLabs.textToSpeech({
        text,
        voice_id: "standard_voice",
        model_id: "eleven_turbo_v2"
      })
    );
  } catch (error) {
    console.log('Standard voice failed, using cache');
  }

  // Level 3: Return cached audio
  return await cache.get(`audio-${text}`);
}
```

## Error Response Formatting

### API Error Responses

```javascript
app.post('/api/text-to-speech', async (req, res) => {
  try {
    const audio = await errorHandler.executeWithRetry(
      async () => makeAPICall(req.body)
    );

    res.json({ success: true, audio });
  } catch (error) {
    // Format error for API response
    const errorResponse = errorHandler.formatError(error);

    res.status(errorResponse.statusCode).json(errorResponse);
    // {
    //   "error": true,
    //   "message": "Request rate limit exceeded. Please try again in a moment.",
    //   "category": "rate_limit",
    //   "statusCode": 429,
    //   "retryable": true,
    //   "timestamp": "2025-10-29T12:00:00.000Z"
    // }
  }
});
```

### User-Friendly Messages

```javascript
const errorResponse = errorHandler.formatError(error);

// Automatically generates user-friendly messages:
// - Rate Limit: "Request rate limit exceeded. Please try again in a moment."
// - Server Error: "Service temporarily unavailable. Please try again later."
// - Client Error: "Invalid request. Please check your input."
// - Network Error: "Network connection error. Please check your internet connection."
// - Timeout: "Request timed out. Please try again."
```

## Logging Patterns

### Structured Logging

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

const errorHandler = new ErrorHandler({ logger });

// All errors are logged with full context:
// {
//   "timestamp": "2025-10-29T12:00:00.000Z",
//   "level": "error",
//   "message": "Request failed",
//   "error": "Rate limit exceeded",
//   "category": "rate_limit",
//   "attempt": 3,
//   "maxRetries": 5,
//   "statusCode": 429,
//   "method": "text-to-speech",
//   "model": "eleven_turbo_v2"
// }
```

### Error Aggregation

```javascript
// Track error patterns
const errorStats = {
  byCategory: {},
  byStatusCode: {},
  total: 0
};

// Intercept error logging
const originalLogError = errorHandler.logger.error;
errorHandler.logger.error = function(message, meta) {
  errorStats.total++;
  errorStats.byCategory[meta.category] = (errorStats.byCategory[meta.category] || 0) + 1;
  errorStats.byStatusCode[meta.statusCode] = (errorStats.byStatusCode[meta.statusCode] || 0) + 1;

  originalLogError.call(this, message, meta);
};

// Periodic reporting
setInterval(() => {
  console.log('Error Statistics:', errorStats);
}, 60000);
```

## Monitoring Integration

### Prometheus Metrics

```javascript
const { metrics } = require('../../monitoring/config/metrics');

const errorHandler = new ErrorHandler({
  logger,
  metrics  // Automatic metric collection
});

// Metrics are automatically updated:
// - elevenlabs_errors_total{type="rate_limit",code="429"}
// - elevenlabs_retries_total{reason="rate_limit"}
// - elevenlabs_requests_total{method="text-to-speech",status="error"}
```

### Alert Triggers

```javascript
// Monitor circuit breaker state
setInterval(() => {
  const cbState = errorHandler.getCircuitBreakerState();

  if (cbState.state === 'OPEN') {
    // Trigger alert
    alertManager.send({
      severity: 'critical',
      message: 'Circuit breaker is OPEN',
      failures: cbState.failures
    });
  }
}, 10000);
```

## Testing

### Simulating Errors

```javascript
// Test retry logic
async function testRetryLogic() {
  let attempts = 0;

  const result = await errorHandler.executeWithRetry(
    async () => {
      attempts++;
      if (attempts < 3) {
        // Simulate rate limit error
        const error = new Error('Rate limit');
        error.response = { status: 429 };
        throw error;
      }
      return { success: true };
    },
    { maxRetries: 5 }
  );

  console.log(`Succeeded after ${attempts} attempts`);
}
```

### Testing Circuit Breaker

```javascript
async function testCircuitBreaker() {
  const cb = new CircuitBreaker({ failureThreshold: 3 });
  const errorHandler = new ErrorHandler({ circuitBreaker: cb });

  // Cause failures
  for (let i = 0; i < 5; i++) {
    try {
      await errorHandler.executeWithRetry(
        async () => {
          throw new Error('Simulated failure');
        }
      );
    } catch (error) {
      console.log(`Attempt ${i + 1} failed`);
    }
  }

  // Circuit should be OPEN now
  console.log('Circuit state:', cb.getState());
}
```

## Best Practices

1. **Categorize errors correctly** - Different error types need different strategies
2. **Use exponential backoff** - Prevents overwhelming the API during issues
3. **Add jitter** - Prevents thundering herd problem
4. **Implement circuit breaker** - Fail fast when service is down
5. **Provide fallbacks** - Graceful degradation is better than total failure
6. **Log with context** - Include request IDs, user IDs for debugging
7. **Use structured logging** - Makes log analysis easier
8. **Monitor error rates** - Alert on elevated error rates
9. **Test error scenarios** - Validate retry and fallback logic
10. **Handle timeouts** - Set appropriate timeout values

## Troubleshooting

### Retry Loops

**Symptoms:** Requests retry forever

**Solution:**
- Set appropriate maxRetries
- Implement timeout for total retry duration
- Check shouldRetry logic

### Circuit Breaker Stuck Open

**Symptoms:** All requests fail immediately

**Solution:**
- Check resetTimeout value
- Verify failure threshold is appropriate
- Review logs for underlying issue

### High Retry Rate

**Symptoms:** Most requests require retries

**Solution:**
- Investigate root cause (rate limiting, service issues)
- Adjust concurrency limits
- Implement request coalescing

## Related Documentation

- [Error Handler Template](../../templates/error-handler.js.template)
- [Rate Limiting Example](../rate-limiting/README.md)
- [Monitoring Example](../monitoring/README.md)
- [Production Deployment Guide](../../README.md)
