/**
 * OpenRouter Model Routing Configuration (TypeScript)
 *
 * This module provides type-safe routing configuration for OpenRouter
 * with support for multiple routing strategies, fallback chains, and monitoring.
 */

export interface RoutingConfig {
  strategy: 'cost-optimized' | 'speed-optimized' | 'quality-optimized' | 'balanced' | 'custom';
  description: string;
  version: string;
  primary?: string;
  fallback?: string[];
  timeout: number;
  retry: RetryConfig;
  on_error: 'fallback' | 'retry' | 'fail';
  routing_rules?: Record<string, RoutingRule>;
  cost_tracking?: CostTrackingConfig;
  monitoring?: MonitoringConfig;
}

export interface RoutingRule {
  description: string;
  models: string[];
  fallback?: string[];
  classifier?: ClassifierConfig;
  max_tokens?: number;
  temperature?: number;
  streaming?: boolean;
  max_latency_ms?: number;
  timeout?: number;
}

export interface ClassifierConfig {
  conditions: string[];
}

export interface RetryConfig {
  max_attempts: number;
  delay_ms: number;
  exponential_backoff: boolean;
}

export interface CostTrackingConfig {
  enabled: boolean;
  log_requests?: boolean;
  alert_threshold_usd?: number;
  daily_budget_usd?: number;
}

export interface MonitoringConfig {
  enabled: boolean;
  metrics?: string[];
  alert_thresholds?: Record<string, number>;
}

/**
 * Model Router
 * Handles model selection based on routing configuration
 */
export class ModelRouter {
  private config: RoutingConfig;
  private requestCount: Map<string, number> = new Map();
  private totalCost: number = 0;

  constructor(config: RoutingConfig) {
    this.config = config;
  }

  /**
   * Select best model based on request context
   */
  selectModel(context: RequestContext): ModelSelection {
    // Apply routing rules
    if (this.config.routing_rules) {
      for (const [ruleName, rule] of Object.entries(this.config.routing_rules)) {
        if (this.matchesRule(context, rule)) {
          return {
            model: rule.models[0],
            fallback: rule.fallback || rule.models.slice(1),
            rule: ruleName,
            config: rule
          };
        }
      }
    }

    // Default to primary/fallback
    return {
      model: this.config.primary || 'anthropic/claude-4.5-sonnet',
      fallback: this.config.fallback || [],
      rule: 'default',
      config: {}
    };
  }

  /**
   * Check if request matches routing rule
   */
  private matchesRule(context: RequestContext, rule: RoutingRule): boolean {
    if (!rule.classifier) return false;

    for (const condition of rule.classifier.conditions) {
      // Simple condition evaluation (extend as needed)
      if (condition.includes('token_count <') && context.tokenCount) {
        const threshold = parseInt(condition.match(/\d+/)?.[0] || '0');
        if (context.tokenCount >= threshold) return false;
      }
      if (condition.includes('token_count >=') && context.tokenCount) {
        const threshold = parseInt(condition.match(/\d+/)?.[0] || '0');
        if (context.tokenCount < threshold) return false;
      }
    }

    return true;
  }

  /**
   * Execute request with fallback chain
   */
  async executeWithFallback(
    context: RequestContext,
    apiClient: OpenRouterClient
  ): Promise<ModelResponse> {
    const selection = this.selectModel(context);
    const models = [selection.model, ...(selection.fallback || [])];

    let lastError: Error | null = null;

    for (let i = 0; i < models.length; i++) {
      const model = models[i];

      try {
        console.log(`Attempting model ${i + 1}/${models.length}: ${model}`);

        const response = await this.executeWithRetry(
          model,
          context,
          apiClient,
          selection.config
        );

        // Track metrics
        this.trackRequest(model, response.cost);

        return response;

      } catch (error) {
        lastError = error as Error;
        console.error(`Model ${model} failed:`, error);

        if (i === models.length - 1) {
          // Last model in chain, throw error
          throw new Error(`All models failed. Last error: ${lastError.message}`);
        }

        // Continue to next model in fallback chain
        continue;
      }
    }

    throw new Error('Fallback chain exhausted');
  }

  /**
   * Execute request with retry logic
   */
  private async executeWithRetry(
    model: string,
    context: RequestContext,
    apiClient: OpenRouterClient,
    ruleConfig: Partial<RoutingRule>
  ): Promise<ModelResponse> {
    const maxAttempts = this.config.retry.max_attempts;
    let delay = this.config.retry.delay_ms;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        const response = await apiClient.chat({
          model,
          messages: context.messages,
          max_tokens: ruleConfig.max_tokens || 2000,
          temperature: ruleConfig.temperature || 0.7,
          stream: ruleConfig.streaming || false
        });

        return response;

      } catch (error) {
        if (attempt === maxAttempts) throw error;

        console.log(`Retry attempt ${attempt}/${maxAttempts} after ${delay}ms`);
        await this.sleep(delay);

        if (this.config.retry.exponential_backoff) {
          delay *= 2;
        }
      }
    }

    throw new Error('Max retries exceeded');
  }

  /**
   * Track request metrics
   */
  private trackRequest(model: string, cost: number) {
    const count = this.requestCount.get(model) || 0;
    this.requestCount.set(model, count + 1);
    this.totalCost += cost;

    // Check budget alerts
    if (this.config.cost_tracking?.alert_threshold_usd) {
      if (this.totalCost >= this.config.cost_tracking.alert_threshold_usd) {
        console.warn(`⚠️ Cost alert: $${this.totalCost.toFixed(2)} >= $${this.config.cost_tracking.alert_threshold_usd}`);
      }
    }
  }

  /**
   * Get routing statistics
   */
  getStats(): RoutingStats {
    return {
      totalRequests: Array.from(this.requestCount.values()).reduce((a, b) => a + b, 0),
      totalCost: this.totalCost,
      modelDistribution: Object.fromEntries(this.requestCount),
      avgCostPerRequest: this.totalCost / Array.from(this.requestCount.values()).reduce((a, b) => a + b, 0)
    };
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Types
 */
export interface RequestContext {
  messages: any[];
  tokenCount?: number;
  taskType?: string;
  complexityScore?: number;
  streamingRequired?: boolean;
  latencyRequirement?: number;
}

export interface ModelSelection {
  model: string;
  fallback: string[];
  rule: string;
  config: Partial<RoutingRule>;
}

export interface ModelResponse {
  content: string;
  model: string;
  cost: number;
  latency: number;
}

export interface RoutingStats {
  totalRequests: number;
  totalCost: number;
  modelDistribution: Record<string, number>;
  avgCostPerRequest: number;
}

export interface OpenRouterClient {
  chat(params: {
    model: string;
    messages: any[];
    max_tokens: number;
    temperature: number;
    stream: boolean;
  }): Promise<ModelResponse>;
}

/**
 * Example Usage
 */
export function exampleUsage() {
  // Load configuration
  const config: RoutingConfig = require('./balanced-routing.json');

  // Create router
  const router = new ModelRouter(config);

  // Mock API client
  const apiClient: OpenRouterClient = {
    async chat(params) {
      return {
        content: 'Response from ' + params.model,
        model: params.model,
        cost: 0.001,
        latency: 500
      };
    }
  };

  // Execute request
  const context: RequestContext = {
    messages: [{ role: 'user', content: 'Hello!' }],
    tokenCount: 100,
    taskType: 'classification'
  };

  router.executeWithFallback(context, apiClient)
    .then(response => {
      console.log('Response:', response);
      console.log('Stats:', router.getStats());
    })
    .catch(error => {
      console.error('Error:', error);
    });
}
