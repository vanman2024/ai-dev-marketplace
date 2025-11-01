# Monitoring and Analytics Example

Complete example of implementing comprehensive monitoring, cost tracking, and analytics for model routing.

## Overview

This example demonstrates:
- Real-time cost tracking and budget alerts
- Performance metrics (latency, success rate, quality)
- Model usage analytics and optimization recommendations
- Dashboard visualization
- Alerting and notifications

## Monitoring Configuration

```json
{
  "monitoring": {
    "enabled": true,
    "metrics": [
      "request_count",
      "success_rate",
      "avg_latency",
      "p95_latency",
      "p99_latency",
      "total_cost",
      "cost_per_request",
      "model_distribution",
      "fallback_usage",
      "error_rate"
    ],
    "retention_days": 30,
    "export": {
      "enabled": true,
      "format": "json",
      "interval_hours": 24
    }
  },

  "cost_tracking": {
    "enabled": true,
    "log_all_requests": true,
    "budget_alerts": {
      "daily_threshold_usd": 5.0,
      "monthly_threshold_usd": 100.0,
      "alert_percentage": 80
    },
    "cost_breakdown": {
      "by_model": true,
      "by_user": true,
      "by_endpoint": true,
      "by_hour": true
    }
  },

  "alerts": {
    "enabled": true,
    "channels": ["console", "webhook", "email"],
    "conditions": {
      "high_cost": {
        "threshold_usd_per_hour": 10.0
      },
      "low_success_rate": {
        "threshold_percentage": 90
      },
      "high_latency": {
        "p95_threshold_ms": 5000
      },
      "excessive_fallback": {
        "threshold_percentage": 20
      }
    }
  }
}
```

## Metrics Collection System

```typescript
interface RequestMetrics {
  timestamp: Date;
  requestId: string;
  model: string;
  fallbackLevel: number;
  latency: number;
  cost: number;
  success: boolean;
  errorType?: string;
  tokenCount: number;
  userId?: string;
  endpoint?: string;
}

class MetricsCollector {
  private metrics: RequestMetrics[] = [];
  private realTimeStats = {
    requestsLast60s: 0,
    errorsLast60s: 0,
    costLast60s: 0
  };

  recordRequest(metric: RequestMetrics) {
    this.metrics.push(metric);

    // Update real-time stats
    this.updateRealTimeStats(metric);

    // Check alerts
    this.checkAlerts(metric);

    // Persist to storage
    this.persistMetric(metric);
  }

  private updateRealTimeStats(metric: RequestMetrics) {
    const now = Date.now();
    const oneMinuteAgo = now - 60000;

    // Clean old entries
    this.metrics = this.metrics.filter(
      m => m.timestamp.getTime() > oneMinuteAgo
    );

    // Calculate real-time stats
    this.realTimeStats = {
      requestsLast60s: this.metrics.length,
      errorsLast60s: this.metrics.filter(m => !m.success).length,
      costLast60s: this.metrics.reduce((sum, m) => sum + m.cost, 0)
    };
  }

  getRealTimeStats() {
    return {
      ...this.realTimeStats,
      requestsPerSecond: this.realTimeStats.requestsLast60s / 60,
      errorRate: this.realTimeStats.requestsLast60s > 0
        ? (this.realTimeStats.errorsLast60s / this.realTimeStats.requestsLast60s) * 100
        : 0,
      costPerHour: this.realTimeStats.costLast60s * 60
    };
  }

  private persistMetric(metric: RequestMetrics) {
    // In production: write to database, time-series DB, or logging service
    // For example: InfluxDB, Prometheus, CloudWatch, Datadog
    console.log(`[METRIC] ${JSON.stringify(metric)}`);
  }

  private checkAlerts(metric: RequestMetrics) {
    // Implement alert checking logic
    const stats = this.getRealTimeStats();

    // High error rate
    if (stats.errorRate > 10) {
      this.sendAlert('high_error_rate', {
        errorRate: stats.errorRate,
        message: `Error rate is ${stats.errorRate.toFixed(1)}%`
      });
    }

    // High cost
    if (stats.costPerHour > 10) {
      this.sendAlert('high_cost', {
        costPerHour: stats.costPerHour,
        message: `Cost is $${stats.costPerHour.toFixed(2)}/hour`
      });
    }
  }

  private sendAlert(type: string, data: any) {
    console.warn(`🚨 ALERT [${type}]:`, data);
    // In production: send to Slack, PagerDuty, email, etc.
  }
}
```

## Cost Tracking System

```typescript
interface CostBreakdown {
  byModel: Map<string, number>;
  byUser: Map<string, number>;
  byEndpoint: Map<string, number>;
  byHour: Map<string, number>;
  total: number;
}

class CostTracker {
  private dailyCost: number = 0;
  private monthlyCost: number = 0;
  private breakdown: CostBreakdown = {
    byModel: new Map(),
    byUser: new Map(),
    byEndpoint: new Map(),
    byHour: new Map(),
    total: 0
  };

  private dailyBudget: number = 5.0;
  private monthlyBudget: number = 100.0;

  trackCost(
    cost: number,
    model: string,
    userId?: string,
    endpoint?: string
  ) {
    this.dailyCost += cost;
    this.monthlyCost += cost;
    this.breakdown.total += cost;

    // Track by model
    const modelCost = this.breakdown.byModel.get(model) || 0;
    this.breakdown.byModel.set(model, modelCost + cost);

    // Track by user
    if (userId) {
      const userCost = this.breakdown.byUser.get(userId) || 0;
      this.breakdown.byUser.set(userId, userCost + cost);
    }

    // Track by endpoint
    if (endpoint) {
      const endpointCost = this.breakdown.byEndpoint.get(endpoint) || 0;
      this.breakdown.byEndpoint.set(endpoint, endpointCost + cost);
    }

    // Track by hour
    const hour = new Date().toISOString().slice(0, 13);
    const hourCost = this.breakdown.byHour.get(hour) || 0;
    this.breakdown.byHour.set(hour, hourCost + cost);

    // Check budget alerts
    this.checkBudgetAlerts();
  }

  private checkBudgetAlerts() {
    const dailyPercent = (this.dailyCost / this.dailyBudget) * 100;
    const monthlyPercent = (this.monthlyCost / this.monthlyBudget) * 100;

    if (dailyPercent >= 80) {
      console.warn(
        `⚠️ Daily budget at ${dailyPercent.toFixed(0)}% ($${this.dailyCost.toFixed(2)}/$${this.dailyBudget})`
      );
    }

    if (monthlyPercent >= 80) {
      console.warn(
        `⚠️ Monthly budget at ${monthlyPercent.toFixed(0)}% ($${this.monthlyCost.toFixed(2)}/$${this.monthlyBudget})`
      );
    }

    if (dailyPercent >= 100) {
      console.error('🚨 DAILY BUDGET EXCEEDED - Consider throttling requests');
    }
  }

  getCostReport(): CostReport {
    return {
      daily: {
        total: this.dailyCost,
        budget: this.dailyBudget,
        remaining: this.dailyBudget - this.dailyCost,
        percentage: (this.dailyCost / this.dailyBudget) * 100
      },
      monthly: {
        total: this.monthlyCost,
        budget: this.monthlyBudget,
        remaining: this.monthlyBudget - this.monthlyCost,
        percentage: (this.monthlyCost / this.monthlyBudget) * 100
      },
      breakdown: {
        byModel: this.topN(this.breakdown.byModel, 5),
        byUser: this.topN(this.breakdown.byUser, 10),
        byEndpoint: this.topN(this.breakdown.byEndpoint, 5)
      }
    };
  }

  private topN(map: Map<string, number>, n: number): Array<[string, number]> {
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, n);
  }

  resetDaily() {
    this.dailyCost = 0;
  }

  resetMonthly() {
    this.monthlyCost = 0;
    this.breakdown = {
      byModel: new Map(),
      byUser: new Map(),
      byEndpoint: new Map(),
      byHour: new Map(),
      total: 0
    };
  }
}

interface CostReport {
  daily: BudgetStatus;
  monthly: BudgetStatus;
  breakdown: {
    byModel: Array<[string, number]>;
    byUser: Array<[string, number]>;
    byEndpoint: Array<[string, number]>;
  };
}

interface BudgetStatus {
  total: number;
  budget: number;
  remaining: number;
  percentage: number;
}
```

## Performance Analytics

```typescript
class PerformanceAnalytics {
  private latencies: number[] = [];
  private successCount: number = 0;
  private failureCount: number = 0;

  recordLatency(latency: number, success: boolean) {
    this.latencies.push(latency);
    if (success) {
      this.successCount++;
    } else {
      this.failureCount++;
    }

    // Keep only last 1000 samples
    if (this.latencies.length > 1000) {
      this.latencies.shift();
    }
  }

  getPerformanceReport(): PerformanceReport {
    const sorted = [...this.latencies].sort((a, b) => a - b);
    const total = this.successCount + this.failureCount;

    return {
      successRate: total > 0 ? (this.successCount / total) * 100 : 0,
      totalRequests: total,
      latency: {
        avg: this.average(this.latencies),
        median: this.percentile(sorted, 50),
        p95: this.percentile(sorted, 95),
        p99: this.percentile(sorted, 99),
        min: Math.min(...this.latencies),
        max: Math.max(...this.latencies)
      }
    };
  }

  private average(arr: number[]): number {
    return arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 0;
  }

  private percentile(sorted: number[], p: number): number {
    if (sorted.length === 0) return 0;
    const index = Math.ceil((p / 100) * sorted.length) - 1;
    return sorted[Math.max(0, index)];
  }
}

interface PerformanceReport {
  successRate: number;
  totalRequests: number;
  latency: {
    avg: number;
    median: number;
    p95: number;
    p99: number;
    min: number;
    max: number;
  };
}
```

## Complete Monitoring System

```typescript
class MonitoringSystem {
  private metricsCollector = new MetricsCollector();
  private costTracker = new CostTracker();
  private performanceAnalytics = new PerformanceAnalytics();

  trackRequest(
    model: string,
    latency: number,
    cost: number,
    success: boolean,
    metadata?: {
      userId?: string;
      endpoint?: string;
      fallbackLevel?: number;
      errorType?: string;
    }
  ) {
    // Record metrics
    this.metricsCollector.recordRequest({
      timestamp: new Date(),
      requestId: this.generateRequestId(),
      model,
      fallbackLevel: metadata?.fallbackLevel || 0,
      latency,
      cost,
      success,
      errorType: metadata?.errorType,
      tokenCount: 0, // Would be actual token count
      userId: metadata?.userId,
      endpoint: metadata?.endpoint
    });

    // Track cost
    this.costTracker.trackCost(cost, model, metadata?.userId, metadata?.endpoint);

    // Record performance
    this.performanceAnalytics.recordLatency(latency, success);
  }

  getDashboard(): Dashboard {
    return {
      realTime: this.metricsCollector.getRealTimeStats(),
      cost: this.costTracker.getCostReport(),
      performance: this.performanceAnalytics.getPerformanceReport(),
      timestamp: new Date()
    };
  }

  printDashboard() {
    const dashboard = this.getDashboard();

    console.log('\n╔════════════════════════════════════════╗');
    console.log('║      MODEL ROUTING DASHBOARD          ║');
    console.log('╚════════════════════════════════════════╝\n');

    // Real-time stats
    console.log('📊 REAL-TIME STATS');
    console.log(`   Requests/sec: ${dashboard.realTime.requestsPerSecond.toFixed(2)}`);
    console.log(`   Error rate: ${dashboard.realTime.errorRate.toFixed(1)}%`);
    console.log(`   Cost/hour: $${dashboard.realTime.costPerHour.toFixed(4)}`);

    // Cost
    console.log('\n💰 COST TRACKING');
    console.log(`   Daily: $${dashboard.cost.daily.total.toFixed(2)} / $${dashboard.cost.daily.budget} (${dashboard.cost.daily.percentage.toFixed(0)}%)`);
    console.log(`   Monthly: $${dashboard.cost.monthly.total.toFixed(2)} / $${dashboard.cost.monthly.budget} (${dashboard.cost.monthly.percentage.toFixed(0)}%)`);

    console.log('\n   Top models by cost:');
    dashboard.cost.breakdown.byModel.forEach(([model, cost]) => {
      console.log(`     ${model}: $${cost.toFixed(4)}`);
    });

    // Performance
    console.log('\n⚡ PERFORMANCE');
    console.log(`   Success rate: ${dashboard.performance.successRate.toFixed(1)}%`);
    console.log(`   Avg latency: ${dashboard.performance.latency.avg.toFixed(0)}ms`);
    console.log(`   P95 latency: ${dashboard.performance.latency.p95.toFixed(0)}ms`);
    console.log(`   P99 latency: ${dashboard.performance.latency.p99.toFixed(0)}ms`);

    console.log('\n════════════════════════════════════════\n');
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

interface Dashboard {
  realTime: ReturnType<MetricsCollector['getRealTimeStats']>;
  cost: CostReport;
  performance: PerformanceReport;
  timestamp: Date;
}
```

## Usage Example

```typescript
// Initialize monitoring
const monitoring = new MonitoringSystem();

// Wrap your router
class MonitoredRouter extends ModelRouter {
  private monitoring: MonitoringSystem;

  constructor(config: RoutingConfig, monitoring: MonitoringSystem) {
    super(config);
    this.monitoring = monitoring;
  }

  async executeWithMonitoring(
    context: RequestContext,
    apiClient: OpenRouterClient
  ): Promise<ModelResponse> {
    const startTime = Date.now();
    let model = '';
    let success = false;
    let errorType: string | undefined;

    try {
      const response = await this.executeWithFallback(context, apiClient);
      model = response.model;
      success = true;

      // Track metrics
      this.monitoring.trackRequest(
        model,
        response.latency,
        response.cost,
        success,
        {
          userId: context.userId,
          endpoint: context.endpoint,
          fallbackLevel: 0 // Would track actual fallback level
        }
      );

      return response;

    } catch (error) {
      errorType = (error as Error).message;
      throw error;

    } finally {
      const latency = Date.now() - startTime;

      if (!success) {
        this.monitoring.trackRequest(
          model || 'unknown',
          latency,
          0,
          false,
          { errorType }
        );
      }
    }
  }
}

// Use monitored router
async function main() {
  const monitoring = new MonitoringSystem();
  const config = loadConfigFromFile('balanced-routing.json');
  const router = new MonitoredRouter(config, monitoring);

  // Execute requests
  for (let i = 0; i < 100; i++) {
    try {
      await router.executeWithMonitoring(
        {
          messages: [{ role: 'user', content: 'Test request' }],
          tokenCount: 100
        },
        apiClient
      );
    } catch (error) {
      console.error('Request failed:', error);
    }

    // Print dashboard every 10 requests
    if (i % 10 === 0) {
      monitoring.printDashboard();
    }
  }

  // Final dashboard
  monitoring.printDashboard();
}
```

## Exporting Metrics

```typescript
class MetricsExporter {
  async exportToJSON(metrics: Dashboard, filepath: string) {
    const data = {
      timestamp: metrics.timestamp,
      metrics: {
        realTime: metrics.realTime,
        cost: metrics.cost,
        performance: metrics.performance
      }
    };

    await fs.promises.writeFile(
      filepath,
      JSON.stringify(data, null, 2)
    );
  }

  async exportToPrometheus(metrics: Dashboard): Promise<string> {
    return `
# HELP model_routing_requests_total Total requests
# TYPE model_routing_requests_total counter
model_routing_requests_total ${metrics.performance.totalRequests}

# HELP model_routing_success_rate Success rate percentage
# TYPE model_routing_success_rate gauge
model_routing_success_rate ${metrics.performance.successRate}

# HELP model_routing_latency_p95 P95 latency in milliseconds
# TYPE model_routing_latency_p95 gauge
model_routing_latency_p95 ${metrics.performance.latency.p95}

# HELP model_routing_cost_total Total cost in USD
# TYPE model_routing_cost_total counter
model_routing_cost_total ${metrics.cost.monthly.total}
    `.trim();
  }
}
```

This comprehensive monitoring system provides full visibility into routing performance, costs, and reliability.
