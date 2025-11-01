# Dynamic Routing Example

Complete example of implementing dynamic routing that automatically selects models based on task complexity, user tier, and real-time conditions.

## Overview

This example demonstrates:
- Automatic task complexity detection
- Dynamic model selection based on multiple factors
- Real-time adaptation to API conditions
- Cost/quality/speed optimization

## Advanced Configuration

```json
{
  "strategy": "balanced",
  "routing_rules": {
    "simple_tasks": {
      "classifier": {
        "conditions": [
          "token_count < 500",
          "complexity_score < 0.3"
        ]
      },
      "models": ["google/gemma-2-9b-it:free"]
    },
    "complex_tasks": {
      "classifier": {
        "conditions": [
          "token_count >= 2000",
          "complexity_score >= 0.7"
        ]
      },
      "models": ["anthropic/claude-3-5-sonnet"]
    }
  },
  "adaptive_routing": {
    "enabled": true,
    "learning_rate": 0.1
  }
}
```

## Complexity Detection

```typescript
interface ComplexityFactors {
  tokenCount: number;
  hasCodeBlocks: boolean;
  requiresReasoning: boolean;
  domainExpertise: string[];
  multiStep: boolean;
}

function calculateComplexity(prompt: string): number {
  let score = 0;

  // Token count factor (0-0.3)
  const tokens = prompt.split(/\s+/).length;
  score += Math.min(tokens / 1000, 0.3);

  // Code blocks (+0.2)
  if (prompt.includes('```') || prompt.includes('def ') || prompt.includes('function ')) {
    score += 0.2;
  }

  // Reasoning keywords (+0.3)
  const reasoningKeywords = ['analyze', 'explain', 'compare', 'evaluate', 'design'];
  if (reasoningKeywords.some(kw => prompt.toLowerCase().includes(kw))) {
    score += 0.3;
  }

  // Domain expertise (+0.2)
  const expertDomains = ['legal', 'medical', 'financial', 'scientific'];
  if (expertDomains.some(domain => prompt.toLowerCase().includes(domain))) {
    score += 0.2;
  }

  // Multi-step tasks (+0.2)
  if (prompt.includes('first') && prompt.includes('then') ||
      prompt.split(/\d+\./).length > 2) {
    score += 0.2;
  }

  return Math.min(score, 1.0);
}
```

## Dynamic Router Implementation

```typescript
class DynamicRouter extends ModelRouter {
  private performanceHistory: Map<string, ModelPerformance> = new Map();
  private currentConditions: SystemConditions = {};

  async selectModelDynamically(context: RequestContext): Promise<ModelSelection> {
    // Calculate complexity score
    const complexity = this.calculateComplexity(context);

    // Check user tier
    const userTier = context.userTier || 'free';

    // Get current API conditions
    const conditions = await this.checkAPIConditions();

    // Select based on multiple factors
    if (userTier === 'premium' && complexity > 0.7) {
      return this.selectPremiumModel(context);
    }

    if (conditions.highTraffic && context.latencyRequirement < 1000) {
      return this.selectFastModel(context);
    }

    if (complexity < 0.3) {
      return this.selectCheapModel(context);
    }

    // Default to balanced selection
    return this.selectBalancedModel(context, complexity);
  }

  private selectPremiumModel(context: RequestContext): ModelSelection {
    return {
      model: 'anthropic/claude-3-5-sonnet',
      fallback: ['openai/gpt-4o', 'google/gemini-pro-1.5'],
      rule: 'premium',
      config: { temperature: 0.7, max_tokens: 8000 }
    };
  }

  private selectFastModel(context: RequestContext): ModelSelection {
    return {
      model: 'anthropic/claude-3-haiku',
      fallback: ['openai/gpt-4o-mini'],
      rule: 'fast',
      config: { temperature: 0.5, max_tokens: 2000, streaming: true }
    };
  }

  private selectCheapModel(context: RequestContext): ModelSelection {
    return {
      model: 'google/gemma-2-9b-it:free',
      fallback: ['meta-llama/llama-3.2-3b-instruct:free', 'anthropic/claude-3-haiku'],
      rule: 'cheap',
      config: { temperature: 0.3, max_tokens: 1000 }
    };
  }

  private selectBalancedModel(
    context: RequestContext,
    complexity: number
  ): ModelSelection {
    if (complexity < 0.4) {
      return this.selectCheapModel(context);
    } else if (complexity < 0.7) {
      return {
        model: 'anthropic/claude-3-haiku',
        fallback: ['openai/gpt-4o-mini', 'anthropic/claude-3-5-sonnet'],
        rule: 'balanced',
        config: { temperature: 0.5, max_tokens: 4000 }
      };
    } else {
      return this.selectPremiumModel(context);
    }
  }

  private async checkAPIConditions(): Promise<SystemConditions> {
    // Check OpenRouter status, rate limits, pricing
    // This would call actual OpenRouter API
    return {
      highTraffic: false,
      rateLimitNear: false,
      pricingChanges: {}
    };
  }
}
```

## User Tier Routing

```typescript
interface UserContext extends RequestContext {
  userId: string;
  userTier: 'free' | 'basic' | 'premium';
  monthlyUsage: number;
  budgetRemaining: number;
}

class TierBasedRouter extends DynamicRouter {
  private tierConfigs = {
    free: {
      modelsAllowed: ['google/gemma-2-9b-it:free', 'meta-llama/llama-3.2-3b-instruct:free'],
      maxTokensPerRequest: 1000,
      maxRequestsPerDay: 100,
      monthlyBudget: 0
    },
    basic: {
      modelsAllowed: ['anthropic/claude-3-haiku', 'openai/gpt-4o-mini'],
      maxTokensPerRequest: 4000,
      maxRequestsPerDay: 1000,
      monthlyBudget: 10
    },
    premium: {
      modelsAllowed: ['anthropic/claude-3-5-sonnet', 'openai/gpt-4o'],
      maxTokensPerRequest: 8000,
      maxRequestsPerDay: 10000,
      monthlyBudget: 100
    }
  };

  async selectModelForUser(context: UserContext): Promise<ModelSelection> {
    const tierConfig = this.tierConfigs[context.userTier];

    // Check budget
    if (context.budgetRemaining <= 0) {
      // Downgrade to free models
      return this.selectCheapModel(context);
    }

    // Filter models by tier
    const complexity = this.calculateComplexity(context);
    let selection = await this.selectModelDynamically(context);

    // Ensure model is allowed for tier
    if (!tierConfig.modelsAllowed.includes(selection.model)) {
      selection.model = tierConfig.modelsAllowed[0];
    }

    // Enforce token limits
    selection.config.max_tokens = Math.min(
      selection.config.max_tokens || 2000,
      tierConfig.maxTokensPerRequest
    );

    return selection;
  }
}
```

## Adaptive Learning

```typescript
interface ModelPerformance {
  successRate: number;
  avgLatency: number;
  avgCost: number;
  qualityScore: number;
  sampleSize: number;
}

class AdaptiveRouter extends TierBasedRouter {
  private readonly LEARNING_RATE = 0.1;
  private readonly MIN_SAMPLES = 100;

  updatePerformance(
    model: string,
    success: boolean,
    latency: number,
    cost: number,
    quality: number
  ) {
    const perf = this.performanceHistory.get(model) || {
      successRate: 0.95,
      avgLatency: 1000,
      avgCost: 0.001,
      qualityScore: 0.8,
      sampleSize: 0
    };

    // Update with exponential moving average
    perf.successRate = perf.successRate * (1 - this.LEARNING_RATE) +
                       (success ? 1 : 0) * this.LEARNING_RATE;
    perf.avgLatency = perf.avgLatency * (1 - this.LEARNING_RATE) +
                      latency * this.LEARNING_RATE;
    perf.avgCost = perf.avgCost * (1 - this.LEARNING_RATE) +
                   cost * this.LEARNING_RATE;
    perf.qualityScore = perf.qualityScore * (1 - this.LEARNING_RATE) +
                        quality * this.LEARNING_RATE;
    perf.sampleSize++;

    this.performanceHistory.set(model, perf);

    // Adjust routing if performance degrades
    if (perf.sampleSize > this.MIN_SAMPLES && perf.successRate < 0.85) {
      console.warn(`⚠️ Model ${model} success rate low: ${perf.successRate.toFixed(2)}`);
      // Consider removing from rotation
    }
  }

  getBestModelForContext(context: RequestContext): string {
    // Select model with best performance for given context
    let bestModel = 'anthropic/claude-3-haiku';
    let bestScore = 0;

    for (const [model, perf] of this.performanceHistory.entries()) {
      if (perf.sampleSize < this.MIN_SAMPLES) continue;

      // Calculate composite score based on requirements
      const score = this.calculateModelScore(perf, context);

      if (score > bestScore) {
        bestScore = score;
        bestModel = model;
      }
    }

    return bestModel;
  }

  private calculateModelScore(
    perf: ModelPerformance,
    context: RequestContext
  ): number {
    const weights = {
      success: 0.4,
      latency: context.latencyRequirement ? 0.3 : 0.1,
      cost: 0.2,
      quality: 0.3
    };

    // Normalize and weight each factor
    const normalizedLatency = 1 - Math.min(perf.avgLatency / 5000, 1);
    const normalizedCost = 1 - Math.min(perf.avgCost / 0.01, 1);

    return (
      perf.successRate * weights.success +
      normalizedLatency * weights.latency +
      normalizedCost * weights.cost +
      perf.qualityScore * weights.quality
    );
  }
}
```

## Complete Example

```typescript
async function main() {
  const router = new AdaptiveRouter(config);

  // Example 1: Free tier user with simple task
  const context1: UserContext = {
    messages: [{ role: 'user', content: 'Is this spam?' }],
    userId: 'user123',
    userTier: 'free',
    monthlyUsage: 50,
    budgetRemaining: 0,
    tokenCount: 10,
    complexity: 0.1
  };

  const response1 = await router.selectModelForUser(context1);
  console.log('Free tier, simple:', response1.model); // gemma-2-9b-it:free

  // Example 2: Premium tier user with complex task
  const context2: UserContext = {
    messages: [{ role: 'user', content: 'Analyze this legal contract...' }],
    userId: 'user456',
    userTier: 'premium',
    monthlyUsage: 500,
    budgetRemaining: 80,
    tokenCount: 5000,
    complexity: 0.9
  };

  const response2 = await router.selectModelForUser(context2);
  console.log('Premium tier, complex:', response2.model); // claude-3-5-sonnet

  // Example 3: Adaptive selection based on performance
  const bestModel = router.getBestModelForContext({
    messages: [],
    latencyRequirement: 1000,
    tokenCount: 1000
  });
  console.log('Best model for low latency:', bestModel);
}
```

## Monitoring Dashboard

Track routing decisions in real-time:

```typescript
interface RoutingMetrics {
  timestamp: Date;
  modelUsed: string;
  complexity: number;
  userTier: string;
  cost: number;
  latency: number;
  success: boolean;
}

class MetricsCollector {
  private metrics: RoutingMetrics[] = [];

  track(metric: RoutingMetrics) {
    this.metrics.push(metric);
  }

  generateReport(timeRange: string = '24h') {
    const cutoff = Date.now() - this.parseTimeRange(timeRange);
    const recent = this.metrics.filter(m => m.timestamp.getTime() > cutoff);

    return {
      totalRequests: recent.length,
      modelDistribution: this.groupBy(recent, 'modelUsed'),
      avgComplexity: this.avg(recent, 'complexity'),
      totalCost: this.sum(recent, 'cost'),
      avgLatency: this.avg(recent, 'latency'),
      successRate: recent.filter(m => m.success).length / recent.length
    };
  }
}
```

This dynamic routing approach optimizes in real-time based on actual performance data and user requirements.
