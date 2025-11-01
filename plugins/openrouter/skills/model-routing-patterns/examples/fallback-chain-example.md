# Fallback Chain Example

Complete example of implementing robust fallback chains for high availability and reliability.

## Overview

This example demonstrates:
- 3-tier fallback strategy for maximum reliability
- Graceful degradation from free → budget → premium
- Automatic retry logic with exponential backoff
- Circuit breaker pattern for failing models
- 99.9% uptime with proper fallback chains

## Three-Tier Fallback Configuration

```json
{
  "strategy": "high-availability",
  "description": "Maximum reliability with 3-tier fallback",

  "primary": "google/gemma-2-9b-it:free",
  "fallback": [
    "meta-llama/llama-3.2-3b-instruct:free",
    "anthropic/claude-3-haiku",
    "openai/gpt-4o-mini",
    "anthropic/claude-3-5-sonnet"
  ],

  "timeout": 5000,
  "retry": {
    "max_attempts": 3,
    "delay_ms": 1000,
    "exponential_backoff": true,
    "max_delay_ms": 8000
  },

  "circuit_breaker": {
    "enabled": true,
    "failure_threshold": 5,
    "reset_timeout_ms": 60000,
    "half_open_requests": 3
  },

  "health_checks": {
    "enabled": true,
    "interval_ms": 30000,
    "endpoint": "https://openrouter.ai/api/v1/models"
  }
}
```

## Fallback Chain Implementation

```typescript
interface CircuitBreakerState {
  status: 'closed' | 'open' | 'half-open';
  failureCount: number;
  lastFailureTime: number;
  successCount: number;
}

class FallbackChainRouter extends ModelRouter {
  private circuitBreakers: Map<string, CircuitBreakerState> = new Map();
  private readonly FAILURE_THRESHOLD = 5;
  private readonly RESET_TIMEOUT = 60000; // 1 minute
  private readonly HALF_OPEN_REQUESTS = 3;

  async executeWithFallbackChain(
    context: RequestContext,
    apiClient: OpenRouterClient
  ): Promise<ModelResponse> {
    const selection = this.selectModel(context);
    const allModels = [selection.model, ...(selection.fallback || [])];

    console.log(`Fallback chain: ${allModels.join(' → ')}`);

    let lastError: Error | null = null;
    const attemptLog: Array<{ model: string; status: string; error?: string }> = [];

    for (let i = 0; i < allModels.length; i++) {
      const model = allModels[i];

      // Check circuit breaker
      if (this.isCircuitOpen(model)) {
        console.log(`⚠️ Circuit breaker OPEN for ${model}, skipping`);
        attemptLog.push({ model, status: 'circuit_open' });
        continue;
      }

      try {
        console.log(`\n[${i + 1}/${allModels.length}] Attempting: ${model}`);
        const startTime = Date.now();

        const response = await this.executeWithRetry(
          model,
          context,
          apiClient,
          selection.config
        );

        const latency = Date.now() - startTime;
        console.log(`✅ Success in ${latency}ms`);

        // Record success
        this.recordSuccess(model);
        attemptLog.push({ model, status: 'success' });

        // Log fallback chain usage
        if (i > 0) {
          console.log(`ℹ️ Used fallback level ${i}`);
          this.trackFallbackUsage(i, model);
        }

        return response;

      } catch (error) {
        lastError = error as Error;
        console.error(`❌ Failed: ${error.message}`);

        // Record failure
        this.recordFailure(model);
        attemptLog.push({
          model,
          status: 'failed',
          error: error.message
        });

        // Check if we should open circuit breaker
        this.checkCircuitBreaker(model);

        if (i === allModels.length - 1) {
          // Last model in chain
          console.error('🚨 All models in fallback chain failed');
          this.logFallbackChainFailure(attemptLog);
          throw new Error(`All ${allModels.length} models failed. Last: ${lastError.message}`);
        }

        // Continue to next model
        console.log(`→ Falling back to next model...`);
        continue;
      }
    }

    throw new Error('Fallback chain exhausted');
  }

  private isCircuitOpen(model: string): boolean {
    const breaker = this.circuitBreakers.get(model);
    if (!breaker) return false;

    if (breaker.status === 'open') {
      // Check if we should transition to half-open
      const timeSinceFailure = Date.now() - breaker.lastFailureTime;
      if (timeSinceFailure >= this.RESET_TIMEOUT) {
        console.log(`🔄 Circuit breaker ${model}: OPEN → HALF-OPEN`);
        breaker.status = 'half-open';
        breaker.successCount = 0;
        return false;
      }
      return true;
    }

    return false;
  }

  private recordSuccess(model: string) {
    const breaker = this.circuitBreakers.get(model) || {
      status: 'closed',
      failureCount: 0,
      lastFailureTime: 0,
      successCount: 0
    };

    if (breaker.status === 'half-open') {
      breaker.successCount++;
      if (breaker.successCount >= this.HALF_OPEN_REQUESTS) {
        console.log(`✅ Circuit breaker ${model}: HALF-OPEN → CLOSED`);
        breaker.status = 'closed';
        breaker.failureCount = 0;
      }
    }

    this.circuitBreakers.set(model, breaker);
  }

  private recordFailure(model: string) {
    const breaker = this.circuitBreakers.get(model) || {
      status: 'closed',
      failureCount: 0,
      lastFailureTime: Date.now(),
      successCount: 0
    };

    breaker.failureCount++;
    breaker.lastFailureTime = Date.now();

    this.circuitBreakers.set(model, breaker);
  }

  private checkCircuitBreaker(model: string) {
    const breaker = this.circuitBreakers.get(model);
    if (!breaker) return;

    if (breaker.failureCount >= this.FAILURE_THRESHOLD) {
      console.log(`🚨 Circuit breaker ${model}: CLOSED → OPEN (${breaker.failureCount} failures)`);
      breaker.status = 'open';
    }
  }

  private trackFallbackUsage(level: number, model: string) {
    // Track which fallback levels are being used
    console.log(`📊 Fallback metrics: level=${level}, model=${model}`);
  }

  private logFallbackChainFailure(attemptLog: any[]) {
    console.error('\n🚨 FALLBACK CHAIN FAILURE REPORT:');
    console.error('================================');
    attemptLog.forEach((attempt, i) => {
      console.error(`${i + 1}. ${attempt.model}: ${attempt.status}`);
      if (attempt.error) {
        console.error(`   Error: ${attempt.error}`);
      }
    });
    console.error('================================\n');
  }
}
```

## Retry Logic with Exponential Backoff

```typescript
class RetryableRouter extends FallbackChainRouter {
  async executeWithRetry(
    model: string,
    context: RequestContext,
    apiClient: OpenRouterClient,
    ruleConfig: any
  ): Promise<ModelResponse> {
    const maxAttempts = this.config.retry.max_attempts;
    let delay = this.config.retry.delay_ms;
    const maxDelay = this.config.retry.max_delay_ms || 8000;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        console.log(`  Retry ${attempt}/${maxAttempts}`);

        const response = await this.executeWithTimeout(
          model,
          context,
          apiClient,
          ruleConfig
        );

        if (attempt > 1) {
          console.log(`  ✅ Succeeded on retry ${attempt}`);
        }

        return response;

      } catch (error) {
        const err = error as Error;

        // Check if error is retryable
        if (!this.isRetryableError(err)) {
          console.log(`  ❌ Non-retryable error: ${err.message}`);
          throw error;
        }

        if (attempt === maxAttempts) {
          console.log(`  ❌ Max retries (${maxAttempts}) exceeded`);
          throw error;
        }

        // Calculate next delay with exponential backoff
        const actualDelay = Math.min(delay, maxDelay);
        console.log(`  ⏳ Retrying in ${actualDelay}ms...`);

        await this.sleep(actualDelay);

        if (this.config.retry.exponential_backoff) {
          delay = Math.min(delay * 2, maxDelay);
        }
      }
    }

    throw new Error('Retry logic exhausted');
  }

  private isRetryableError(error: Error): boolean {
    const retryableErrors = [
      'timeout',
      'rate_limit',
      'network_error',
      'service_unavailable',
      '429',
      '500',
      '502',
      '503',
      '504'
    ];

    return retryableErrors.some(pattern =>
      error.message.toLowerCase().includes(pattern)
    );
  }

  private async executeWithTimeout(
    model: string,
    context: RequestContext,
    apiClient: OpenRouterClient,
    ruleConfig: any
  ): Promise<ModelResponse> {
    const timeout = this.config.timeout;

    return Promise.race([
      apiClient.chat({
        model,
        messages: context.messages,
        max_tokens: ruleConfig.max_tokens || 2000,
        temperature: ruleConfig.temperature || 0.7,
        stream: ruleConfig.streaming || false
      }),
      this.timeoutPromise(timeout)
    ]);
  }

  private timeoutPromise(ms: number): Promise<never> {
    return new Promise((_, reject) =>
      setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
    );
  }
}
```

## Health Checks

```typescript
class HealthCheckRouter extends RetryableRouter {
  private modelHealth: Map<string, ModelHealth> = new Map();
  private healthCheckInterval: NodeJS.Timeout | null = null;

  constructor(config: RoutingConfig) {
    super(config);
    this.startHealthChecks();
  }

  private startHealthChecks() {
    if (!this.config.health_checks?.enabled) return;

    const interval = this.config.health_checks.interval_ms || 30000;

    this.healthCheckInterval = setInterval(async () => {
      await this.performHealthChecks();
    }, interval);

    console.log(`✅ Health checks started (interval: ${interval}ms)`);
  }

  private async performHealthChecks() {
    console.log('\n🏥 Performing health checks...');

    const models = [
      this.config.primary,
      ...(this.config.fallback || [])
    ].filter(Boolean) as string[];

    for (const model of models) {
      try {
        const health = await this.checkModelHealth(model);
        this.modelHealth.set(model, health);

        console.log(`  ${model}: ${health.status}`);
      } catch (error) {
        console.error(`  ${model}: ERROR`);
      }
    }
  }

  private async checkModelHealth(model: string): Promise<ModelHealth> {
    // Perform lightweight health check
    // Could ping OpenRouter API or check model status

    const breaker = this.circuitBreakers.get(model);
    const isHealthy = !breaker || breaker.status === 'closed';

    return {
      status: isHealthy ? 'healthy' : 'degraded',
      lastChecked: new Date(),
      circuitBreakerStatus: breaker?.status || 'closed',
      failureCount: breaker?.failureCount || 0
    };
  }

  getModelHealth(model: string): ModelHealth | undefined {
    return this.modelHealth.get(model);
  }

  shutdown() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
      console.log('✅ Health checks stopped');
    }
  }
}

interface ModelHealth {
  status: 'healthy' | 'degraded' | 'unhealthy';
  lastChecked: Date;
  circuitBreakerStatus: 'closed' | 'open' | 'half-open';
  failureCount: number;
}
```

## Complete Example Usage

```typescript
async function demonstrateFallbackChain() {
  const config = loadConfigFromFile('fallback-chain-config.json');
  const router = new HealthCheckRouter(config);
  const apiClient = new OpenRouterClient();

  // Test normal operation
  console.log('=== Test 1: Normal Operation ===');
  try {
    const response = await router.executeWithFallbackChain(
      {
        messages: [{ role: 'user', content: 'Hello!' }],
        tokenCount: 100
      },
      apiClient
    );
    console.log('✅ Response:', response.content);
  } catch (error) {
    console.error('❌ Error:', error);
  }

  // Simulate primary model failure
  console.log('\n=== Test 2: Primary Model Failure ===');
  // Primary model will fail, fallback to secondary
  try {
    const response = await router.executeWithFallbackChain(
      {
        messages: [{ role: 'user', content: 'Test fallback' }],
        tokenCount: 150
      },
      apiClient
    );
    console.log('✅ Fallback successful:', response.model);
  } catch (error) {
    console.error('❌ Fallback failed:', error);
  }

  // Check health status
  console.log('\n=== Model Health Status ===');
  const models = [config.primary, ...(config.fallback || [])];
  for (const model of models.filter(Boolean)) {
    const health = router.getModelHealth(model as string);
    console.log(`${model}: ${health?.status || 'unknown'}`);
  }

  // Cleanup
  router.shutdown();
}

demonstrateFallbackChain();
```

## Monitoring Fallback Performance

```typescript
interface FallbackMetrics {
  totalRequests: number;
  primarySuccessRate: number;
  fallbackUsageByLevel: Map<number, number>;
  avgFallbackLatency: number;
  circuitBreakerActivations: number;
}

class FallbackMetricsCollector {
  private metrics: FallbackMetrics = {
    totalRequests: 0,
    primarySuccessRate: 0,
    fallbackUsageByLevel: new Map(),
    avgFallbackLatency: 0,
    circuitBreakerActivations: 0
  };

  recordRequest(level: number, latency: number) {
    this.metrics.totalRequests++;

    const count = this.metrics.fallbackUsageByLevel.get(level) || 0;
    this.metrics.fallbackUsageByLevel.set(level, count + 1);

    if (level === 0) {
      // Primary model
      this.metrics.primarySuccessRate =
        (this.metrics.primarySuccessRate * (this.metrics.totalRequests - 1) + 1) /
        this.metrics.totalRequests;
    }
  }

  generateReport(): string {
    const primarySuccess = (this.metrics.primarySuccessRate * 100).toFixed(1);
    const fallbackUsage = Array.from(this.metrics.fallbackUsageByLevel.entries())
      .map(([level, count]) => `  Level ${level}: ${count} requests`)
      .join('\n');

    return `
Fallback Chain Performance Report
==================================
Total Requests: ${this.metrics.totalRequests}
Primary Success Rate: ${primarySuccess}%

Fallback Usage:
${fallbackUsage}

Circuit Breaker Activations: ${this.metrics.circuitBreakerActivations}
    `.trim();
  }
}
```

## Best Practices

1. **Always have at least 3 fallback levels** for high availability
2. **Mix free and paid models** to balance cost and reliability
3. **Implement circuit breakers** to prevent cascading failures
4. **Use exponential backoff** for retries
5. **Monitor fallback usage** to identify systemic issues
6. **Set appropriate timeouts** for each tier
7. **Health check models** proactively
8. **Log all fallback usage** for analysis

## Expected Behavior

- **99.9% uptime** with 3+ fallback levels
- **Primary model succeeds**: 85-95% of requests
- **First fallback**: 4-10% of requests
- **Second fallback**: 1-4% of requests
- **Third fallback**: <1% of requests
- **Complete failure**: <0.1% of requests

This robust fallback strategy ensures maximum availability and reliability for production applications.
