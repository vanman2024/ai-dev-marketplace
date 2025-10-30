# Monitoring and Observability Example

Complete monitoring stack for ElevenLabs API integration with Prometheus metrics, Grafana dashboards, structured logging, and alerting.

## Overview

This example demonstrates:
- Prometheus metrics collection
- Grafana dashboard setup
- Structured logging with Winston
- Alert manager configuration
- Health check endpoints
- Distributed tracing

## Files

- `prometheus-setup.md` - Prometheus configuration
- `grafana-dashboards.json` - Dashboard definitions
- `logging-configuration.js` - Winston setup
- `alert-rules.yml` - Alert definitions
- `README.md` - This file

## Quick Start

### 1. Setup Monitoring Infrastructure

```bash
# Run setup script
bash ../../scripts/setup-monitoring.sh \
  --project-name "my-elevenlabs-app" \
  --log-level "info" \
  --metrics-port 9090
```

This creates:
- Winston logger configuration
- Prometheus metrics endpoints
- Health check endpoints
- Alert rules
- Grafana dashboard templates

### 2. Start Health Check Server

```javascript
const HealthCheck = require('../../templates/health-check.js.template');
const { metrics } = require('../../monitoring/config/metrics');

const healthCheck = new HealthCheck({
  rateLimiter: rateLimiterInstance,
  circuitBreaker: circuitBreakerInstance,
  apiKey: process.env.ELEVENLABS_API_KEY
});

const app = require('express')();

// Health endpoints
app.get('/health', healthCheck.liveness());
app.get('/ready', healthCheck.readiness());
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', metrics.register.contentType);
  res.end(await metrics.register.metrics());
});

app.listen(8080, () => {
  console.log('Health check server running on port 8080');
});
```

### 3. Configure Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'elevenlabs-api'
    scrape_interval: 15s
    static_configs:
      - targets: ['localhost:8080']
```

## Metrics Collection

### Request Metrics

```javascript
const { metrics } = require('../../monitoring/config/metrics');

// Track request
async function makeTrackedRequest(method, model) {
  const start = Date.now();

  try {
    const result = await makeAPICall();

    // Record success
    metrics.requestsTotal.inc({
      method,
      status: 'success',
      model
    });

    metrics.requestDuration.observe(
      { method, model },
      (Date.now() - start) / 1000
    );

    return result;
  } catch (error) {
    // Record error
    metrics.errorsTotal.inc({
      type: categorizeError(error),
      code: error.response?.status || 'unknown'
    });

    throw error;
  }
}
```

### Available Metrics

**Request Metrics:**
- `elevenlabs_requests_total` - Total requests (labels: method, status, model)
- `elevenlabs_request_duration_seconds` - Request latency histogram
- `elevenlabs_concurrent_requests` - Current concurrent requests
- `elevenlabs_queue_depth` - Requests waiting in queue

**Error Metrics:**
- `elevenlabs_errors_total` - Total errors (labels: type, code)
- `elevenlabs_retries_total` - Retry attempts (labels: reason)
- `elevenlabs_circuit_breaker_state` - Circuit breaker state (0=closed, 1=open, 2=half-open)

**Business Metrics:**
- `elevenlabs_characters_generated_total` - Total characters processed
- `elevenlabs_audio_duration_seconds_total` - Total audio duration
- `elevenlabs_quota_used_percentage` - Quota utilization

### Custom Metrics

```javascript
// Add custom metric
const customMetric = new metrics.Counter({
  name: 'elevenlabs_custom_events_total',
  help: 'Custom event counter',
  labelNames: ['event_type'],
  registers: [metrics.register]
});

// Use it
customMetric.inc({ event_type: 'voice_cloned' });
```

## Logging

### Structured Logging Setup

```javascript
const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'elevenlabs-api',
    environment: process.env.NODE_ENV
  },
  transports: [
    new DailyRotateFile({
      filename: 'logs/app-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '14d'
    }),
    new DailyRotateFile({
      filename: 'logs/error-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d',
      level: 'error'
    })
  ]
});
```

### Log Levels

- **error** - Failures requiring immediate attention
- **warn** - Degraded performance, approaching limits
- **info** - Request completions, important events
- **debug** - Detailed execution flow
- **trace** - Very detailed debugging

### Logging Best Practices

```javascript
// Good: Include context
logger.info('Request completed', {
  method: 'text-to-speech',
  model: 'eleven_turbo_v2',
  duration: 150,
  statusCode: 200,
  userId: 'user-123',
  requestId: 'req-456'
});

// Bad: Unstructured message
logger.info('Request to text-to-speech completed in 150ms');
```

### Request Logging Middleware

```javascript
app.use((req, res, next) => {
  const start = Date.now();
  const requestId = req.headers['x-request-id'] || uuid();

  req.log = logger.child({ requestId });

  res.on('finish', () => {
    req.log.info('HTTP Request', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration: Date.now() - start,
      ip: req.ip,
      userAgent: req.get('user-agent')
    });
  });

  next();
});
```

## Grafana Dashboards

### Key Panels

**1. Request Rate**
```
Query: rate(elevenlabs_requests_total[5m])
Type: Graph
Legend: {{method}} - {{status}}
```

**2. Error Rate**
```
Query: rate(elevenlabs_errors_total[5m])
Type: Graph
Legend: {{type}}
Threshold: > 0.05 (5%)
```

**3. Latency (P95)**
```
Query: histogram_quantile(0.95, rate(elevenlabs_request_duration_seconds_bucket[5m]))
Type: Graph
Legend: {{method}}
Threshold: > 2s
```

**4. Concurrent Requests**
```
Query: elevenlabs_concurrent_requests
Type: Graph with Plan Limit Line
```

**5. Queue Depth**
```
Query: elevenlabs_queue_depth
Type: Graph
Threshold: > 500
```

**6. Circuit Breaker State**
```
Query: elevenlabs_circuit_breaker_state
Type: Stat
Mappings: 0=CLOSED, 1=OPEN, 2=HALF_OPEN
```

### Dashboard Import

```bash
# Import dashboard
curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @../../monitoring/dashboards/elevenlabs-overview.json
```

## Alerting

### Alert Rules

```yaml
# High Error Rate
- alert: HighErrorRate
  expr: rate(elevenlabs_errors_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: High error rate detected
    description: Error rate is {{ $value }} (threshold: 5%)

# Circuit Breaker Open
- alert: CircuitBreakerOpen
  expr: elevenlabs_circuit_breaker_state > 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: Circuit breaker is open
    description: Circuit is in {{ $value }} state

# High Latency
- alert: HighLatency
  expr: histogram_quantile(0.95, rate(elevenlabs_request_duration_seconds_bucket[5m])) > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: High latency detected
    description: P95 latency is {{ $value }}s
```

### Alert Channels

**Slack:**
```yaml
receivers:
  - name: slack-alerts
    slack_configs:
      - api_url: ${SLACK_WEBHOOK_URL}
        channel: '#alerts'
        title: 'ElevenLabs API Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

**Email:**
```yaml
receivers:
  - name: email-alerts
    email_configs:
      - to: alerts@example.com
        from: monitoring@example.com
        smarthost: smtp.gmail.com:587
        auth_username: ${SMTP_USERNAME}
        auth_password: ${SMTP_PASSWORD}
```

**PagerDuty:**
```yaml
receivers:
  - name: pagerduty-critical
    pagerduty_configs:
      - service_key: ${PAGERDUTY_SERVICE_KEY}
        severity: critical
```

## Health Checks

### Liveness Check

```bash
curl http://localhost:8080/health

{
  "status": "healthy",
  "timestamp": "2025-10-29T12:00:00.000Z",
  "uptime": "2d 5h 30m",
  "service": "elevenlabs-api",
  "version": "1.0.0"
}
```

### Readiness Check

```bash
curl http://localhost:8080/ready

{
  "status": "ready",
  "timestamp": "2025-10-29T12:00:00.000Z",
  "checks": {
    "api": {
      "healthy": true,
      "status": 200,
      "message": "API connectivity OK"
    },
    "rateLimiter": {
      "healthy": true,
      "tokens": 8,
      "capacity": 10,
      "concurrent": 2,
      "queueDepth": 0,
      "utilization": "20.0%",
      "message": "Rate limiter OK"
    },
    "circuitBreaker": {
      "healthy": true,
      "state": "CLOSED",
      "failures": 0,
      "message": "Circuit breaker OK"
    },
    "memory": {
      "healthy": true,
      "heapUsed": "45MB",
      "heapTotal": "100MB",
      "heapUsedPercent": "45.0%",
      "message": "Memory usage OK"
    }
  }
}
```

## Distributed Tracing

### OpenTelemetry Setup

```javascript
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

const provider = new NodeTracerProvider();
const exporter = new JaegerExporter({
  serviceName: 'elevenlabs-api',
  agentHost: 'localhost',
  agentPort: 6831
});

provider.addSpanProcessor(new SimpleSpanProcessor(exporter));
provider.register();
```

### Tracing API Calls

```javascript
const tracer = opentelemetry.trace.getTracer('elevenlabs-api');

async function makeTracedRequest(text) {
  const span = tracer.startSpan('elevenlabs.text-to-speech');

  span.setAttributes({
    'elevenlabs.text_length': text.length,
    'elevenlabs.model': 'eleven_turbo_v2'
  });

  try {
    const result = await makeAPICall(text);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error) {
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message
    });
    throw error;
  } finally {
    span.end();
  }
}
```

## Performance Monitoring

### Key Metrics to Track

**Latency:**
- P50 (median)
- P95 (95th percentile)
- P99 (99th percentile)
- Max

**Throughput:**
- Requests per second
- Characters per second
- Audio minutes per hour

**Reliability:**
- Success rate
- Error rate by type
- Retry rate
- Circuit breaker state

**Resource Usage:**
- Memory usage
- CPU usage
- Queue depth
- Concurrent requests

### SLI/SLO Definitions

**Service Level Indicators (SLI):**
- Request success rate
- Request latency (P95)
- Service availability

**Service Level Objectives (SLO):**
- 99.5% of requests succeed
- 95% of requests complete within 2s
- 99.9% uptime

## Runbooks

### High Error Rate

**Detection:** Error rate > 5% for 5 minutes

**Investigation:**
1. Check error distribution by type
2. Review recent deployments
3. Check ElevenLabs status page
4. Review quota limits

**Resolution:**
- If rate limiting: Reduce request rate or upgrade plan
- If service errors: Contact ElevenLabs support
- If client errors: Review request validation

### Circuit Breaker Open

**Detection:** Circuit breaker state = OPEN

**Investigation:**
1. Check failure count and types
2. Review error logs
3. Test API connectivity manually

**Resolution:**
- Wait for automatic reset (60s)
- If persistent: Investigate root cause
- Manual reset if issue resolved

## Best Practices

1. **Use structured logging** - Makes log analysis easier
2. **Include request IDs** - Track requests across systems
3. **Monitor key metrics** - Request rate, errors, latency
4. **Set meaningful alerts** - Actionable, not noisy
5. **Create dashboards** - Real-time visibility
6. **Define SLOs** - Measurable reliability targets
7. **Test alerts** - Verify notification channels work
8. **Document runbooks** - Clear resolution steps
9. **Review metrics regularly** - Identify trends
10. **Correlate logs and metrics** - Faster debugging

## Related Documentation

- [Monitoring Config Template](../../templates/monitoring-config.json.template)
- [Health Check Template](../../templates/health-check.js.template)
- [Rate Limiting Example](../rate-limiting/README.md)
- [Error Handling Example](../error-handling/README.md)
- [Production Deployment Guide](../../README.md)
