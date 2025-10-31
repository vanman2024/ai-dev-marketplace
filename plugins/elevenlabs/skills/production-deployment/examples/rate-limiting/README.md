# Rate Limiting Implementation Example

Complete example of implementing rate limiting for ElevenLabs API with token bucket algorithm, priority queuing, and production-grade monitoring.

## Overview

This example demonstrates:
- Token bucket rate limiter with automatic refill
- Priority-based request queuing
- Circuit breaker integration
- Prometheus metrics collection
- Comprehensive error handling

## Files

- `basic-usage.js` - Simple rate limiting setup
- `advanced-usage.js` - Full production implementation
- `with-express.js` - Express middleware integration
- `load-test.js` - Load testing script
- `README.md` - This file

## Quick Start

### 1. Install Dependencies

```bash
npm install prom-client express
```

### 2. Basic Usage

```javascript
const { TokenBucketRateLimiter } = require('../../templates/rate-limiter.js.template');

// Create rate limiter for Pro plan (10 concurrent)
const limiter = new TokenBucketRateLimiter({
  capacity: 10
  refillRate: 2
  queueSize: 100
});

// Wrap your API call
const makeTextToSpeech = limiter.wrap(async (text) => {
  // Your ElevenLabs API call here
  return await elevenLabs.textToSpeech(text);
}, 5); // priority = 5

// Use it
try {
  const audio = await makeTextToSpeech("Hello world");
  console.log("Audio generated successfully");
} catch (error) {
  console.error("Failed:", error.message);
}
```

### 3. With Priority Handling

```javascript
// High priority for real-time requests
const realtimeRequest = limiter.wrap(
  async () => makeAPICall()
  10  // highest priority
);

// Normal priority for batch processing
const batchRequest = limiter.wrap(
  async () => makeAPICall()
  3   // lower priority
);

// High priority requests are processed first when queue builds up
await Promise.all([
  realtimeRequest()
  batchRequest()
]);
```

## Production Configuration

### Plan Tier Configurations

**Free Plan:**
```javascript
const limiter = new TokenBucketRateLimiter({
  capacity: 2,      // 2 concurrent for Multilingual v2
  refillRate: 0.5,  // Conservative refill
  queueSize: 50
});
```

**Pro Plan:**
```javascript
const limiter = new TokenBucketRateLimiter({
  capacity: 10,     // 10 concurrent for Multilingual v2
  refillRate: 2,    // 2 tokens per second
  queueSize: 200
});
```

**Scale Plan:**
```javascript
const limiter = new TokenBucketRateLimiter({
  capacity: 15,     // 15 concurrent for Multilingual v2
  refillRate: 3,    // 3 tokens per second
  queueSize: 500
});
```

### With Metrics

```javascript
const promClient = require('prom-client');
const { metrics } = require('../../monitoring/config/metrics');

const limiter = new TokenBucketRateLimiter({
  capacity: 10
  refillRate: 2
  queueSize: 100
  metrics: metrics  // Pass Prometheus metrics
});

// Metrics are automatically updated
limiter.on('acquired', ({ tokens, concurrent }) => {
  console.log(`Token acquired. Remaining: ${tokens}, Concurrent: ${concurrent}`);
});

limiter.on('queued', ({ queueDepth, priority }) => {
  console.log(`Request queued. Depth: ${queueDepth}, Priority: ${priority}`);
});
```

## Advanced Patterns

### Adaptive Rate Limiting

Monitor response headers and adjust limits dynamically:

```javascript
async function makeRequestWithAdaptiveLimiting(fn) {
  await limiter.acquire();

  try {
    const response = await fn();

    // Extract headers
    const currentConcurrent = response.headers['current-concurrent-requests'];
    const maxConcurrent = response.headers['maximum-concurrent-requests'];

    // Adjust limiter capacity if needed
    if (maxConcurrent && maxConcurrent != limiter.capacity) {
      console.log(`Adjusting capacity: ${limiter.capacity} -> ${maxConcurrent}`);
      limiter.capacity = maxConcurrent;
    }

    return response;
  } finally {
    limiter.release();
  }
}
```

### Circuit Breaker Integration

```javascript
const { CircuitBreaker } = require('../../templates/rate-limiter.js.template');

const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5
  resetTimeout: 60000
});

async function makeProtectedRequest(fn) {
  await limiter.acquire();

  try {
    return await circuitBreaker.execute(fn);
  } finally {
    limiter.release();
  }
}
```

### Multiple Priority Levels

```javascript
const PRIORITIES = {
  CRITICAL: 10,   // Real-time user-facing
  HIGH: 7,        // Important background jobs
  NORMAL: 5,      // Regular requests
  LOW: 3,         // Batch processing
  BACKGROUND: 1   // Lowest priority tasks
};

// Use in your code
await limiter.acquire(PRIORITIES.CRITICAL);
```

## Monitoring

### Event Listeners

```javascript
limiter.on('initialized', ({ capacity, refillRate }) => {
  console.log(`Rate limiter initialized: ${capacity} capacity, ${refillRate}/s refill`);
});

limiter.on('refill', ({ tokens, added }) => {
  console.log(`Refilled ${added} tokens, now at ${tokens}`);
});

limiter.on('acquired', ({ tokens, concurrent }) => {
  console.log(`Token acquired: ${tokens} remaining, ${concurrent} concurrent`);
});

limiter.on('released', ({ tokens, concurrent }) => {
  console.log(`Token released: ${tokens} available, ${concurrent} concurrent`);
});

limiter.on('queued', ({ queueDepth, priority }) => {
  console.log(`Request queued: depth=${queueDepth}, priority=${priority}`);
});

limiter.on('dequeued', ({ queueDepth, waitTime }) => {
  console.log(`Request dequeued: depth=${queueDepth}, waited ${waitTime}ms`);
});

limiter.on('queue-full', ({ queueSize }) => {
  console.error(`Queue full! Size: ${queueSize}`);
});
```

### State Monitoring

```javascript
setInterval(() => {
  const state = limiter.getState();
  console.log('Rate Limiter State:', {
    tokens: state.tokens
    concurrent: state.concurrent
    queueDepth: state.queueDepth
    utilization: state.utilization
  });
}, 5000);
```

## Testing

### Load Testing

```bash
# Run load test
node load-test.js --concurrency 20 --duration 60

# Expected output:
# Completed: 1500 requests
# Success rate: 98%
# Average latency: 150ms
# P95 latency: 500ms
# Queue max depth: 5
```

### Validation

```javascript
// Test concurrency limit enforcement
async function testConcurrencyLimit() {
  const limiter = new TokenBucketRateLimiter({ capacity: 5 });
  const activeRequests = [];

  // Try to acquire 10 tokens immediately
  for (let i = 0; i < 10; i++) {
    activeRequests.push(
      limiter.acquire().then(() => {
        console.log(`Request ${i} acquired at ${Date.now()}`);
        return new Promise(resolve => setTimeout(resolve, 1000));
      }).then(() => limiter.release())
    );
  }

  await Promise.all(activeRequests);
  // Should see first 5 acquire immediately, next 5 queue
}
```

## Best Practices

1. **Set capacity based on plan tier** - Don't exceed your plan's concurrency limit
2. **Use priority levels** - Prioritize user-facing requests over background jobs
3. **Monitor queue depth** - Alert if queue consistently > 50% full
4. **Implement circuit breaker** - Prevent cascade failures
5. **Handle queue-full errors** - Gracefully reject or wait when queue is full
6. **Log rate limiting events** - Track queuing patterns for optimization
7. **Test under load** - Validate behavior before production

## Troubleshooting

### High Queue Depth

**Symptoms:** Queue depth consistently > 100

**Solutions:**
- Upgrade plan for higher concurrency
- Reduce request rate
- Implement request coalescing
- Add more workers

### Frequent Queue Full Errors

**Symptoms:** Many requests rejected with "queue is full"

**Solutions:**
- Increase queue size
- Implement backpressure to upstream systems
- Add request buffering
- Scale horizontally

### Low Throughput

**Symptoms:** Lower request throughput than expected

**Solutions:**
- Increase refill rate
- Check if capacity matches plan tier
- Verify no bottlenecks in request processing
- Monitor latency metrics

## Related Documentation

- [Rate Limiter Template](../../templates/rate-limiter.js.template)
- [Error Handling Example](../error-handling/README.md)
- [Monitoring Example](../monitoring/README.md)
- [Production Deployment Guide](../../README.md)
