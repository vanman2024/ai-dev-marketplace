# Cost-Optimized Routing Example

Complete example of implementing cost-optimized routing with OpenRouter to minimize API costs while maintaining quality.

## Overview

This example shows how to:
- Route 70-80% of requests to free models
- Use budget models for moderate complexity
- Reserve premium models for critical tasks
- Achieve 85-95% cost savings vs premium-only routing

## Configuration

```json
{
  "strategy": "cost-optimized",
  "primary": "google/gemma-2-9b-it:free",
  "fallback": [
    "anthropic/claude-4.5-sonnet",
    "anthropic/claude-4.5-sonnet"
  ],
  "routing_rules": {
    "simple_tasks": {
      "models": ["google/gemma-2-9b-it:free"],
      "max_tokens": 1000
    },
    "moderate_tasks": {
      "models": ["anthropic/claude-4.5-sonnet"],
      "max_tokens": 4000
    },
    "critical_tasks": {
      "models": ["anthropic/claude-4.5-sonnet"],
      "max_tokens": 8000
    }
  }
}
```

## Implementation (Node.js)

```typescript
import { ModelRouter, RoutingConfig } from './routing-config';

// Load configuration
const config: RoutingConfig = require('./cost-optimized-routing.json');
const router = new ModelRouter(config);

// Create OpenRouter client
const openrouter = new OpenRouter({
  apiKey: process.env.OPENROUTER_API_KEY
});

// Helper function to classify task complexity
function classifyTask(prompt: string): 'simple' | 'moderate' | 'critical' {
  const wordCount = prompt.split(/\s+/).length;

  // Simple: Short prompts, basic operations
  if (wordCount < 50 && !prompt.includes('analyze') && !prompt.includes('explain')) {
    return 'simple';
  }

  // Critical: Customer-facing, legal, financial
  if (prompt.includes('legal') || prompt.includes('financial') ||
      prompt.includes('customer') || prompt.includes('production')) {
    return 'critical';
  }

  // Moderate: Everything else
  return 'moderate';
}

// Execute request with cost-optimized routing
async function executeRequest(prompt: string) {
  const complexity = classifyTask(prompt);

  const context = {
    messages: [{ role: 'user', content: prompt }],
    taskType: complexity,
    tokenCount: prompt.split(/\s+/).length * 1.3 // Rough estimate
  };

  try {
    const response = await router.executeWithFallback(context, openrouter);

    console.log('Response:', response.content);
    console.log('Model used:', response.model);
    console.log('Cost:', `$${response.cost.toFixed(4)}`);

    return response;
  } catch (error) {
    console.error('All models failed:', error);
    throw error;
  }
}

// Example requests
async function main() {
  // Simple task - will use free model
  await executeRequest('Classify this email as spam or not spam');

  // Moderate task - will use Claude Haiku
  await executeRequest('Summarize this article and extract key points');

  // Critical task - will use Claude Sonnet
  await executeRequest('Draft a legal disclaimer for our customer-facing product');

  // Print statistics
  const stats = router.getStats();
  console.log('\nRouting Statistics:');
  console.log('Total requests:', stats.totalRequests);
  console.log('Total cost:', `$${stats.totalCost.toFixed(4)}`);
  console.log('Avg cost per request:', `$${stats.avgCostPerRequest.toFixed(4)}`);
  console.log('Model distribution:', stats.modelDistribution);
}

main();
```

## Implementation (Python)

```python
from routing_config import ModelRouter, load_config_from_file, RequestContext
import openrouter

# Load configuration
config = load_config_from_file('cost-optimized-routing.json')
router = ModelRouter(config)

# Create OpenRouter client
client = openrouter.Client(api_key=os.environ['OPENROUTER_API_KEY'])

def classify_task(prompt: str) -> str:
    """Classify task complexity"""
    word_count = len(prompt.split())

    # Simple: Short prompts, basic operations
    if word_count < 50 and 'analyze' not in prompt and 'explain' not in prompt:
        return 'simple'

    # Critical: Customer-facing, legal, financial
    critical_keywords = ['legal', 'financial', 'customer', 'production']
    if any(keyword in prompt.lower() for keyword in critical_keywords):
        return 'critical'

    # Moderate: Everything else
    return 'moderate'

async def execute_request(prompt: str):
    """Execute request with cost-optimized routing"""
    complexity = classify_task(prompt)

    context = RequestContext(
        messages=[{'role': 'user', 'content': prompt}],
        task_type=complexity,
        token_count=int(len(prompt.split()) * 1.3)  # Rough estimate
    )

    try:
        response = await router.execute_with_fallback(context, client)

        print(f"Response: {response.content}")
        print(f"Model used: {response.model}")
        print(f"Cost: ${response.cost:.4f}")

        return response
    except Exception as error:
        print(f"All models failed: {error}")
        raise

async def main():
    # Simple task - will use free model
    await execute_request('Classify this email as spam or not spam')

    # Moderate task - will use Claude Haiku
    await execute_request('Summarize this article and extract key points')

    # Critical task - will use Claude Sonnet
    await execute_request('Draft a legal disclaimer for our customer-facing product')

    # Print statistics
    stats = router.get_stats()
    print('\nRouting Statistics:')
    print(f"Total requests: {stats['total_requests']}")
    print(f"Total cost: ${stats['total_cost']:.4f}")
    print(f"Avg cost per request: ${stats['avg_cost_per_request']:.4f}")
    print(f"Model distribution: {stats['model_distribution']}")

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())
```

## Cost Analysis

### Before (Premium-Only)
- Model: GPT-4o only
- Cost per 1M tokens: $5.00
- 100k requests/month × 1000 tokens avg = 100M tokens
- **Monthly cost: $500**

### After (Cost-Optimized Routing)
- 70% free models: 70k requests × $0 = $0
- 20% budget models: 20k requests × $0.25/1M = $5
- 10% premium models: 10k requests × $3.00/1M = $30
- **Monthly cost: $35**

### Savings
- **$465/month (93% reduction)**
- **$5,580/year**

## Quality Monitoring

Monitor quality to ensure free models meet requirements:

```typescript
// Add quality verification
const qualityThreshold = 0.90;
let successfulResponses = 0;
let totalResponses = 0;

async function executeWithQualityCheck(prompt: string) {
  const response = await executeRequest(prompt);

  totalResponses++;

  // Check if response meets quality standards
  if (isQualityResponse(response)) {
    successfulResponses++;
  }

  const successRate = successfulResponses / totalResponses;

  if (successRate < qualityThreshold) {
    console.warn(`⚠️ Quality below threshold: ${successRate.toFixed(2)}`);
    // Consider upgrading routing strategy
  }
}
```

## Best Practices

1. **Start conservative**: Begin with 50% free models, gradually increase
2. **Monitor quality**: Track user satisfaction and response quality
3. **A/B test**: Compare free vs premium for same tasks
4. **Set budgets**: Use daily/monthly budget alerts
5. **Classify accurately**: Ensure critical tasks use premium models
6. **Cache responses**: Reduce API calls for repeated queries
7. **Batch requests**: Group similar tasks to optimize routing

## Troubleshooting

**Free models not meeting quality standards:**
- Increase fallback usage
- Tighten classification criteria
- Use budget models for more tasks

**Costs higher than expected:**
- Review actual request distribution
- Check if too many requests classified as 'critical'
- Verify caching is working
- Analyze model usage in router stats

**Fallback chain activated too often:**
- Free models may be rate limited
- Check OpenRouter status
- Consider adding more free model options
- Implement request queuing

## Next Steps

1. Deploy configuration to production
2. Monitor actual cost savings
3. Track quality metrics
4. Adjust routing rules based on data
5. Expand to more free models as available
6. Implement A/B testing framework
