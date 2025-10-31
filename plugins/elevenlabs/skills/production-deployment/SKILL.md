---
name: production-deployment
description: Production deployment patterns for ElevenLabs API including rate limiting, error handling, monitoring, and testing. Use when deploying to production, implementing rate limiting, setting up monitoring, handling errors, testing concurrency, or when user mentions production deployment, rate limits, error handling, monitoring, ElevenLabs production.
allowed-tools: Bash, Read, Write, Edit
---

# Production Deployment

Complete production deployment guide for ElevenLabs API integration including rate limiting patterns, comprehensive error handling strategies, monitoring setup, and testing frameworks.

## Overview

This skill provides battle-tested patterns for deploying ElevenLabs API integration to production environments with:

- **Rate Limiting**: Concurrency-aware rate limiting respecting plan limits
- **Error Handling**: Comprehensive error recovery and retry strategies
- **Monitoring**: Real-time metrics, logging, and alerting
- **Testing**: Load testing, concurrency validation, and production readiness checks

## Quick Start

### 1. Setup Monitoring Infrastructure

```bash
bash scripts/setup-monitoring.sh --project-name "my-elevenlabs-app" \
  --log-level "info" \
  --metrics-port 9090
```

This script:
- Configures Winston logging with rotation
- Sets up Prometheus metrics endpoints
- Creates health check endpoints
- Initializes error tracking

### 2. Deploy Production Configuration

```bash
bash scripts/deploy-production.sh --environment "production" \
  --api-key "$ELEVENLABS_API_KEY" \
  --concurrency-limit 10 \
  --region "us-east-1"
```

This script:
- Validates environment variables
- Applies rate limiting configuration
- Configures error handling middleware
- Sets up monitoring integrations
- Performs smoke tests

### 3. Test Rate Limiting

```bash
bash scripts/test-rate-limiting.sh --concurrency 20 \
  --duration 60 \
  --plan-tier "pro"
```

This script:
- Simulates concurrent requests
- Validates queue behavior
- Measures latency under load
- Generates performance report

## ElevenLabs Concurrency Limits

### Limits by Plan Tier

| Plan | Multilingual v2 | Turbo/Flash | STT | Music |
|------|-----------------|-------------|-----|-------|
| Free | 2 | 4 | 8 | N/A |
| Starter | 3 | 6 | 12 | 2 |
| Creator | 5 | 10 | 20 | 2 |
| Pro | 10 | 20 | 40 | 2 |
| Scale | 15 | 30 | 60 | 3 |
| Business | 15 | 30 | 60 | 3 |
| Enterprise | Elevated | Elevated | Elevated | Highest |

### Queue Management

When concurrency limits are exceeded:
- Requests are queued alongside lower-priority requests
- Typical latency increase: ~50ms
- Response headers include: `current-concurrent-requests`, `maximum-concurrent-requests`

### Real-World Capacity

A concurrency limit of 5 can typically support ~100 simultaneous audio broadcasts depending on:
- Audio generation speed
- User behavior patterns
- Request distribution

## Rate Limiting Patterns

### 1. Token Bucket Algorithm

Best for: Variable rate limiting with burst capacity

```javascript
// See templates/rate-limiter.js.template for full implementation
const limiter = new TokenBucketRateLimiter({
  capacity: 10,           // Max concurrent requests
  refillRate: 2,          // Tokens per second
  queueSize: 100          // Max queued requests
});
```

### 2. Sliding Window with Priority Queue

Best for: Enforcing strict concurrency limits with prioritization

```python
# See templates/error-handler.py.template for full implementation
limiter = SlidingWindowRateLimiter(
    max_concurrent=10
    window_size=60
    priority_levels=3
)
```

### 3. Adaptive Rate Limiting

Best for: Self-adjusting to API response headers

Monitors `current-concurrent-requests` and `maximum-concurrent-requests` headers to dynamically adjust rate limits.

## Error Handling Strategies

### Error Categories

**1. Rate Limit Errors (429)**
- Implement exponential backoff
- Queue requests for retry
- Monitor queue depth

**2. Service Errors (500-599)**
- Retry with exponential backoff
- Circuit breaker pattern
- Fallback to cached audio

**3. Client Errors (400-499)**
- Log for debugging
- Do not retry
- Return meaningful error to user

**4. Network Errors**
- Retry with linear backoff
- Timeout after 30 seconds
- Circuit breaker after 5 failures

### Circuit Breaker Pattern

```javascript
// Automatically opens circuit after threshold failures
const circuitBreaker = new CircuitBreaker({
  failureThreshold: 5
  resetTimeout: 60000
  monitorInterval: 5000
});
```

## Monitoring Setup

### Key Metrics to Track

**Request Metrics:**
- `elevenlabs_requests_total` - Total requests by status
- `elevenlabs_requests_duration_seconds` - Request latency histogram
- `elevenlabs_concurrent_requests` - Current concurrent requests
- `elevenlabs_queue_depth` - Queued requests waiting

**Error Metrics:**
- `elevenlabs_errors_total` - Total errors by type
- `elevenlabs_retries_total` - Total retry attempts
- `elevenlabs_circuit_breaker_state` - Circuit breaker state

**Business Metrics:**
- `elevenlabs_characters_generated` - Total characters processed
- `elevenlabs_audio_duration_seconds` - Total audio duration
- `elevenlabs_quota_used_percentage` - Quota utilization

### Logging Best Practices

**Structure logs with:**
- Request ID for tracing
- User ID for analysis
- Timestamp in ISO 8601
- Error stack traces
- Performance metrics

**Log Levels:**
- `error` - Failures requiring attention
- `warn` - Degraded performance, retries
- `info` - Request completion, key events
- `debug` - Detailed execution flow

### Alerting Rules

**Critical Alerts:**
- Error rate > 5% over 5 minutes
- Circuit breaker open for > 1 minute
- Queue depth > 500 requests

**Warning Alerts:**
- Latency p95 > 2 seconds
- Quota usage > 90%
- Retry rate > 20%

## Testing Frameworks

### Load Testing

Simulate production traffic patterns:

```bash
# Gradual ramp-up test
bash scripts/test-rate-limiting.sh \
  --pattern "ramp-up" \
  --start-rps 1 \
  --end-rps 10 \
  --duration 300
```

### Concurrency Validation

Verify concurrency limits are enforced:

```bash
# Burst test
bash scripts/test-rate-limiting.sh \
  --pattern "burst" \
  --concurrency 50 \
  --iterations 100
```

### Chaos Testing

Test error handling under adverse conditions:

```bash
# Simulate API failures
bash scripts/test-rate-limiting.sh \
  --pattern "chaos" \
  --failure-rate 0.1 \
  --duration 120
```

## Production Checklist

### Pre-Deployment

- [ ] Environment variables configured
- [ ] Rate limiting configured for plan tier
- [ ] Error handling middleware implemented
- [ ] Monitoring and logging configured
- [ ] Health check endpoints created
- [ ] Load testing completed
- [ ] Chaos testing completed

### Post-Deployment

- [ ] Smoke tests passed
- [ ] Metrics dashboard configured
- [ ] Alerts configured and tested
- [ ] On-call rotation established
- [ ] Runbooks documented
- [ ] Backup/fallback strategy tested

## Scripts

### setup-monitoring.sh

Configures comprehensive monitoring infrastructure:
- Winston logging with daily rotation
- Prometheus metrics exporter
- Health check endpoints
- Error tracking integration
- Custom metric collectors

**Usage:**
```bash
bash scripts/setup-monitoring.sh \
  --project-name "my-app" \
  --log-level "info" \
  --metrics-port 9090 \
  --health-port 8080
```

### deploy-production.sh

Production deployment orchestration:
- Environment validation
- Dependency installation
- Configuration deployment
- Service health checks
- Smoke test execution
- Rollback on failure

**Usage:**
```bash
bash scripts/deploy-production.sh \
  --environment "production" \
  --api-key "$ELEVENLABS_API_KEY" \
  --concurrency-limit 10 \
  --skip-tests false
```

### test-rate-limiting.sh

Comprehensive rate limiting test suite:
- Concurrency limit validation
- Queue behavior testing
- Latency measurement
- Error rate tracking
- Performance reporting

**Usage:**
```bash
bash scripts/test-rate-limiting.sh \
  --concurrency 20 \
  --duration 60 \
  --plan-tier "pro" \
  --pattern "ramp-up"
```

### validate-config.sh

Production configuration validator:
- Environment variable checks
- API key validation
- Rate limit configuration
- Monitoring setup verification
- Security audit

**Usage:**
```bash
bash scripts/validate-config.sh \
  --config-file "config/production.json" \
  --strict true
```

### rollback.sh

Automated rollback script:
- Reverts to previous deployment
- Restores configuration
- Validates health checks
- Notifies team

**Usage:**
```bash
bash scripts/rollback.sh \
  --deployment-id "deploy-123" \
  --reason "High error rate"
```

## Templates

### rate-limiter.js.template

Token bucket rate limiter with priority queue:
- Configurable capacity and refill rate
- Priority-based request queuing
- Automatic backpressure handling
- Prometheus metrics integration

### rate-limiter.py.template

Sliding window rate limiter with async support:
- Strict concurrency enforcement
- Redis-backed for distributed systems
- Circuit breaker integration
- Comprehensive error handling

### error-handler.js.template

Production-grade error handler:
- Error categorization and routing
- Exponential backoff retry logic
- Circuit breaker pattern
- Structured error logging

### error-handler.py.template

Async error handler with context:
- Context-aware error handling
- Retry with jitter
- Error aggregation and reporting
- Integration with monitoring

### monitoring-config.json.template

Complete monitoring configuration:
- Prometheus scrape configs
- Alert rules and thresholds
- Log aggregation settings
- Dashboard definitions

### health-check.js.template

Comprehensive health check endpoint:
- API connectivity verification
- Rate limiter health
- Queue depth monitoring
- Dependency checks

## Examples

### Rate Limiting Example

Complete implementation showing:
- Token bucket rate limiter
- Priority queue management
- Backpressure handling
- Metrics collection

**Location:** `examples/rate-limiting/`

### Error Handling Example

Production error handling patterns:
- Retry with exponential backoff
- Circuit breaker implementation
- Fallback strategies
- Error logging and alerting

**Location:** `examples/error-handling/`

### Monitoring Example

Full monitoring stack setup:
- Prometheus metrics
- Grafana dashboards
- Winston logging
- Alert manager configuration

**Location:** `examples/monitoring/`

## Best Practices

### Rate Limiting

1. **Configure for your plan tier** - Don't exceed concurrency limits
2. **Implement graceful degradation** - Queue requests, don't drop
3. **Monitor queue depth** - Alert on excessive queueing
4. **Use adaptive limiting** - Adjust based on response headers
5. **Test under load** - Validate behavior before production

### Error Handling

1. **Categorize errors** - Different strategies for different error types
2. **Implement retries carefully** - Exponential backoff with jitter
3. **Use circuit breakers** - Prevent cascade failures
4. **Log comprehensively** - Include context for debugging
5. **Provide fallbacks** - Cached audio, degraded experience

### Monitoring

1. **Track key metrics** - Request rate, latency, errors, concurrency
2. **Set meaningful alerts** - Actionable, not noisy
3. **Use structured logging** - JSON format for easy parsing
4. **Create dashboards** - Real-time visibility
5. **Test alerts** - Verify notification channels work

### Testing

1. **Load test gradually** - Ramp up to avoid overwhelming API
2. **Simulate realistic patterns** - User behavior, not raw requests
3. **Test error scenarios** - Chaos engineering
4. **Validate concurrency** - Ensure limits are enforced
5. **Monitor during tests** - Use production monitoring stack

## Troubleshooting

### High Error Rate

**Symptoms:** Error rate > 5%

**Diagnosis:**
1. Check Prometheus metrics: `rate(elevenlabs_errors_total[5m])`
2. Review error logs for patterns
3. Verify API key is valid
4. Check quota remaining

**Resolution:**
1. If rate limiting: Reduce request rate or upgrade plan
2. If service errors: Implement circuit breaker, contact support
3. If client errors: Fix request validation

### High Latency

**Symptoms:** p95 latency > 2 seconds

**Diagnosis:**
1. Check concurrency: `elevenlabs_concurrent_requests`
2. Check queue depth: `elevenlabs_queue_depth`
3. Review response headers: `current-concurrent-requests`

**Resolution:**
1. Increase concurrency limit (upgrade plan if needed)
2. Optimize request payload size
3. Implement request coalescing
4. Use Turbo/Flash models for lower latency

### Circuit Breaker Open

**Symptoms:** Requests failing immediately

**Diagnosis:**
1. Check circuit breaker state metric
2. Review error logs for failure pattern
3. Check ElevenLabs status page

**Resolution:**
1. Wait for automatic reset (default 60s)
2. If persistent: Check API connectivity
3. Manual reset if resolved: Restart service

## Resources

- [ElevenLabs API Docs](https://elevenlabs.io/docs)
- [Concurrency Documentation](https://elevenlabs.io/docs/models#concurrency-and-priority)
- [API Reference](https://elevenlabs.io/docs/api-reference)
- [Status Page](https://status.elevenlabs.io)

## Contributing

When updating this skill:

1. Test scripts thoroughly in production-like environment
2. Update templates with latest best practices
3. Add examples for new patterns
4. Update troubleshooting guide
5. Validate with `validate-skill.sh`

---

**Version:** 1.0.0
**Last Updated:** 2025-10-29
**Maintainer:** ElevenLabs Plugin Team
