# Model Routing Patterns Skill

Production-ready model routing configurations and strategies for OpenRouter that optimize for cost, speed, quality, or balanced performance with intelligent fallback chains.

## Overview

This skill provides comprehensive templates, scripts, and strategies for implementing sophisticated model routing in OpenRouter-powered applications. It helps agents autonomously design and implement optimal routing strategies without manual configuration.

## When Claude Uses This Skill

Claude automatically loads this skill when:
- Building AI applications with OpenRouter
- Implementing model routing strategies
- Optimizing API costs
- Setting up fallback chains
- Implementing quality-based routing
- User mentions: model routing, cost optimization, fallback strategies, model selection, intelligent routing, or dynamic model switching

## What's Included

### Scripts (All Executable)

1. **validate-routing-config.sh** - Validates routing configuration
   - Checks JSON syntax
   - Validates model IDs and availability
   - Verifies fallback chain logic
   - Detects circular dependencies
   - Ensures required fields present

2. **test-fallback-chain.sh** - Tests fallback chains
   - Simulates model failures
   - Verifies graceful degradation
   - Measures latency through chain
   - Validates error handling
   - Provides fallback recommendations

3. **generate-routing-config.sh** - Generates routing configs
   - Interactive configuration builder
   - Supports all routing strategies
   - Validates and optimizes settings
   - Exports to JSON format

4. **analyze-cost-savings.sh** - Analyzes cost savings
   - Compares routing strategies
   - Projects monthly costs
   - Generates cost reports
   - Identifies optimization opportunities
   - Shows ROI calculations

### Templates

#### Configuration Templates (JSON)
- **cost-optimized-routing.json** - Minimize costs (85-95% savings)
- **speed-optimized-routing.json** - Minimize latency (sub-second)
- **quality-optimized-routing.json** - Maximize quality (premium models)
- **balanced-routing.json** - Dynamic task-based routing
- **custom-routing-template.json** - Template for custom strategies

#### Code Templates
- **routing-config.ts** - TypeScript routing implementation
- **routing-config.py** - Python routing implementation

Both include:
- Type-safe configuration loading
- Fallback chain execution
- Retry logic with exponential backoff
- Circuit breaker pattern
- Metrics tracking
- Full examples

### Examples

1. **cost-routing-example.md** - Complete cost-optimized setup
   - 85-95% cost reduction
   - Task classification
   - Quality monitoring
   - A/B testing strategies

2. **dynamic-routing-example.md** - Task complexity-based routing
   - Automatic complexity detection
   - User tier routing
   - Adaptive learning
   - Real-time optimization

3. **fallback-chain-example.md** - 3-tier fallback strategy
   - Circuit breaker implementation
   - Health checks
   - Retry logic
   - 99.9% uptime

4. **monitoring-example.md** - Cost tracking and analytics
   - Real-time metrics
   - Budget alerts
   - Performance analytics
   - Dashboard visualization

## Quick Start

### 1. Generate Configuration

```bash
# Interactive mode
cd skills/model-routing-patterns
./scripts/generate-routing-config.sh cost-optimized routing.json

# Or copy template
cp templates/cost-optimized-routing.json my-config.json
```

### 2. Validate Configuration

```bash
./scripts/validate-routing-config.sh my-config.json
```

### 3. Test Fallback Chain

```bash
./scripts/test-fallback-chain.sh my-config.json
```

### 4. Analyze Cost Savings

```bash
./scripts/analyze-cost-savings.sh my-config.json
```

### 5. Implement in Code

**TypeScript:**
```typescript
import { ModelRouter, loadConfigFromFile } from './templates/routing-config';

const config = loadConfigFromFile('my-config.json');
const router = new ModelRouter(config);

const response = await router.executeWithFallback(context, apiClient);
```

**Python:**
```python
from routing_config import ModelRouter, load_config_from_file

config = load_config_from_file('my-config.json')
router = ModelRouter(config)

response = await router.execute_with_fallback(context, api_client)
```

## Routing Strategies

### Cost-Optimized
**Goal:** Minimize API costs while maintaining quality

**Strategy:**
- 70-80% free models (google/gemma, meta-llama)
- 20% budget models (claude-haiku, gpt-4o-mini)
- 10% premium models (claude-sonnet) for critical tasks

**Savings:** 85-95% vs GPT-4o only

**Best for:** High-volume apps, development, budget-constrained projects

### Speed-Optimized
**Goal:** Minimize latency and response time

**Strategy:**
- Fast models (claude-haiku ~500ms, gpt-4o-mini ~600ms)
- Streaming enabled for immediate feedback
- Geographic routing to nearest endpoints

**Performance:** Sub-second response times

**Best for:** Real-time chat, interactive UI, low-latency requirements

### Quality-Optimized
**Goal:** Maximize output quality

**Strategy:**
- Premium models only (claude-sonnet, gpt-4o, gemini-pro)
- Multi-model voting for critical decisions
- Quality verification layers

**Cost:** $3-15 per 1M tokens

**Best for:** Customer-facing, legal, critical business decisions

### Balanced
**Goal:** Dynamic routing based on task complexity

**Strategy:**
- Simple tasks → free models
- Medium tasks → budget models
- Complex tasks → premium models
- Adaptive based on success metrics

**Distribution:** 30% free, 50% budget, 20% premium

**Savings:** 60-75% with quality maintained

**Best for:** Production apps, mixed workloads, general-purpose

## Model Categories

### Free Models ($0)
- `google/gemma-2-9b-it:free`
- `meta-llama/llama-3.2-3b-instruct:free`
- `meta-llama/llama-3.2-1b-instruct:free`
- `microsoft/phi-3-mini-128k-instruct:free`

### Budget Models ($0.10-0.50/1M tokens)
- `anthropic/claude-4.5-sonnet` - $0.25/1M
- `openai/gpt-4o-mini` - $0.15/1M
- `google/gemini-flash-1.5` - $0.075/1M

### Premium Models ($3-15/1M tokens)
- `anthropic/claude-4.5-sonnet` - $3/1M
- `openai/gpt-4o` - $5/1M
- `google/gemini-pro-1.5` - $3.50/1M

## Best Practices

1. **Always implement fallback chains** - Prevents single points of failure
2. **Monitor actual costs** - Theoretical ≠ real usage
3. **Test quality degradation** - Ensure cheaper models meet thresholds
4. **Set timeout limits** - Prevent slow models from blocking
5. **Track model availability** - Handle rate limits and downtime
6. **Use task classification** - Route based on complexity
7. **Implement retry logic** - Handle transient failures
8. **Cache responses** - Reduce redundant API calls
9. **A/B test strategies** - Validate with data
10. **Budget alerting** - Get notified before limits

## Validation

Run validation before deploying:

```bash
# Validate configuration
./scripts/validate-routing-config.sh config.json

# Test fallback behavior
./scripts/test-fallback-chain.sh config.json

# Analyze costs
./scripts/analyze-cost-savings.sh config.json baseline.json 100000
```

## File Structure

```
model-routing-patterns/
├── SKILL.md                          # Main skill definition
├── README.md                         # This file
├── scripts/                          # Functional bash scripts
│   ├── validate-routing-config.sh    # Config validation
│   ├── test-fallback-chain.sh        # Fallback testing
│   ├── generate-routing-config.sh    # Config generation
│   └── analyze-cost-savings.sh       # Cost analysis
├── templates/                        # Configuration templates
│   ├── cost-optimized-routing.json   # Cost strategy
│   ├── speed-optimized-routing.json  # Speed strategy
│   ├── quality-optimized-routing.json # Quality strategy
│   ├── balanced-routing.json         # Balanced strategy
│   ├── custom-routing-template.json  # Custom template
│   ├── routing-config.ts             # TypeScript impl
│   └── routing-config.py             # Python impl
└── examples/                         # Working examples
    ├── cost-routing-example.md       # Cost optimization
    ├── dynamic-routing-example.md    # Dynamic routing
    ├── fallback-chain-example.md     # Fallback chains
    └── monitoring-example.md         # Monitoring setup
```

## Troubleshooting

**All models failing:**
- Check OpenRouter status page
- Verify API key has credits
- Test with known-working model
- Review rate limit status

**Higher costs than expected:**
- Analyze actual request distribution
- Verify task classification accuracy
- Check if caching is working
- Review retry/fallback patterns

**Quality degradation:**
- Review which models are actually used
- Test free models against benchmarks
- Consider upgrading routing strategy
- Implement quality verification

**High latency:**
- Check if using slow models
- Enable streaming
- Use geographic routing
- Implement parallel requests

## Version

- **Version:** 1.0.0
- **Last Updated:** 2024-10-31
- **Compatibility:** Node.js, Python, TypeScript, any OpenRouter client

## Support

For issues or questions:
1. Review examples directory for complete implementations
2. Run validation scripts to identify configuration issues
3. Check model pricing at openrouter.ai/docs
4. Test with simple configuration first, then optimize

## Related Skills

- `openrouter-config-validator` - Validates OpenRouter API configuration
- `provider-integration-templates` - Provider-specific integration patterns

---

**Skill Location:** `plugins/openrouter/skills/model-routing-patterns/`
