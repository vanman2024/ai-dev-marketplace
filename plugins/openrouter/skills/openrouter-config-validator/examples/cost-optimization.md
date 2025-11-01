# Cost Optimization Guide

Strategies for reducing OpenRouter API costs while maintaining quality.

## Understanding Costs

### Pricing Model

OpenRouter charges based on:
- **Prompt tokens**: Input text you send
- **Completion tokens**: Output text generated
- **Model selected**: Different models have different prices

Example pricing (per 1M tokens):
```
anthropic/claude-3-opus:     $15 prompt / $75 completion
anthropic/claude-3.5-sonnet: $3 prompt / $15 completion
anthropic/claude-3-haiku:    $0.25 prompt / $1.25 completion
openai/gpt-4-turbo:          $10 prompt / $30 completion
openai/gpt-3.5-turbo:        $0.50 prompt / $1.50 completion
```

### Cost Calculation

```javascript
function calculateCost(promptTokens, completionTokens, model) {
  const pricing = {
    'anthropic/claude-3-opus': { prompt: 0.000015, completion: 0.000075 },
    'anthropic/claude-3.5-sonnet': { prompt: 0.000003, completion: 0.000015 },
    'anthropic/claude-3-haiku': { prompt: 0.00000025, completion: 0.00000125 },
    'openai/gpt-4-turbo': { prompt: 0.00001, completion: 0.00003 },
    'openai/gpt-3.5-turbo': { prompt: 0.0000005, completion: 0.0000015 }
  };

  const modelPricing = pricing[model];
  return (promptTokens * modelPricing.prompt) + (completionTokens * modelPricing.completion);
}

// Example
const cost = calculateCost(1000, 500, 'anthropic/claude-3.5-sonnet');
console.log(`Cost: $${cost.toFixed(4)}`); // $0.0105
```

## Optimization Strategies

### 1. Use Smaller Models for Simple Tasks

**Problem:**
```javascript
// Using expensive model for simple task
const response = await openrouter.chat({
  model: 'anthropic/claude-3-opus',  // $15/$75 per 1M tokens
  messages: [{ role: 'user', content: 'What is 2+2?' }]
});
```

**Solution:**
```javascript
// Route by task complexity
function selectModel(task) {
  if (task.complexity === 'simple') {
    return 'anthropic/claude-3-haiku';  // $0.25/$1.25 per 1M tokens
  } else if (task.complexity === 'medium') {
    return 'anthropic/claude-3.5-sonnet';  // $3/$15 per 1M tokens
  } else {
    return 'anthropic/claude-3-opus';  // $15/$75 per 1M tokens
  }
}

const response = await openrouter.chat({
  model: selectModel({ complexity: 'simple' }),
  messages: [{ role: 'user', content: 'What is 2+2?' }]
});
```

**Savings:** Up to 60x cost reduction for simple tasks!

### 2. Implement Response Caching

**Problem:**
```javascript
// Repeated identical requests
for (const user of users) {
  const response = await openrouter.chat({
    messages: [{ role: 'user', content: 'Explain machine learning' }]
  });
}
// Cost: N × request_cost
```

**Solution:**
```javascript
const cache = new Map();

async function getCachedResponse(prompt, model) {
  const cacheKey = `${model}:${JSON.stringify(prompt)}`;

  if (cache.has(cacheKey)) {
    console.log('Cache hit - $0 cost');
    return cache.get(cacheKey);
  }

  const response = await openrouter.chat({
    model,
    messages: prompt
  });

  cache.set(cacheKey, response);
  return response;
}

// Usage
for (const user of users) {
  const response = await getCachedResponse(
    [{ role: 'user', content: 'Explain machine learning' }],
    'anthropic/claude-3-haiku'
  );
}
// Cost: 1 × request_cost (subsequent requests free)
```

**Savings:** 100% on repeated requests!

### 3. Limit Response Length

**Problem:**
```javascript
// Unbounded response length
const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [{ role: 'user', content: 'Explain AI' }]
});
// Could generate 4000+ tokens
```

**Solution:**
```javascript
// Set max_tokens
const response = await openrouter.chat({
  model: 'anthropic/claude-3.5-sonnet',
  messages: [{ role: 'user', content: 'Explain AI' }],
  max_tokens: 200  // Limit response length
});
// Guaranteed maximum 200 tokens
```

**Savings:** 50-90% on completion costs!

### 4. Optimize Prompt Length

**Problem:**
```javascript
// Verbose prompt
const prompt = `
I need you to analyze this data and provide insights.
The data is as follows: [1000 lines of data]
Please analyze it carefully and provide detailed insights.
Make sure to consider all aspects.
`;
// 5000+ tokens
```

**Solution:**
```javascript
// Concise prompt
const prompt = `Analyze this data and provide insights:\n${compressData(data)}`;
// 500 tokens

// Or use system message for instructions
const messages = [
  { role: 'system', content: 'Analyze data and provide insights.' },
  { role: 'user', content: data }
];
```

**Savings:** 80-90% on prompt costs!

### 5. Batch Similar Requests

**Problem:**
```javascript
// Individual requests
for (const item of items) {
  await openrouter.chat({
    messages: [{ role: 'user', content: `Summarize: ${item}` }]
  });
}
// Cost: N × request_cost
```

**Solution:**
```javascript
// Batch processing
const batchedItems = items.join('\n---\n');
const response = await openrouter.chat({
  messages: [{
    role: 'user',
    content: `Summarize each item:\n${batchedItems}`
  }]
});
// Cost: 1 × request_cost (shared context)
```

**Savings:** 40-60% through shared context!

### 6. Use Provider Preferences

**Problem:**
```javascript
// Using most expensive provider
const response = await openrouter.chat({
  model: 'gpt-4-turbo'  // Expensive provider
});
```

**Solution:**
```bash
# Configure provider preferences for cost
OPENROUTER_PROVIDER_PREFERENCES=Meta,Google,Mistral,OpenAI,Anthropic

# Or in request
const response = await fetch(url, {
  headers: {
    'X-Provider-Preferences': 'Meta,Google,Mistral'
  }
});
```

**Savings:** 30-70% by preferring cheaper providers!

### 7. Implement Intelligent Fallbacks

**Problem:**
```bash
# Expensive fallbacks
OPENROUTER_MODEL=anthropic/claude-3-opus
OPENROUTER_FALLBACK_MODELS=openai/gpt-4-turbo,anthropic/claude-3.5-sonnet
```

**Solution:**
```bash
# Cost-effective fallbacks
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet  # Good quality
OPENROUTER_FALLBACK_MODELS=anthropic/claude-3-haiku,openai/gpt-3.5-turbo  # Cheaper
```

**Savings:** 80-90% when fallback is used!

### 8. Use Streaming for Long Responses

**Problem:**
```javascript
// Wait for entire response
const response = await openrouter.chat({
  messages: [{ role: 'user', content: 'Write a long essay' }]
});
// Charged for all tokens even if you stop reading
```

**Solution:**
```javascript
// Stream and stop when you have enough
const response = await openrouter.chat({
  messages: [{ role: 'user', content: 'Write a long essay' }],
  stream: true
});

let tokenCount = 0;
for await (const chunk of response) {
  process(chunk);
  tokenCount += estimateTokens(chunk);

  if (tokenCount > 500) {
    break;  // Stop receiving more tokens
  }
}
```

**Savings:** Pay only for tokens you use!

### 9. Monitor and Analyze Usage

**Implementation:**
```javascript
class CostTracker {
  constructor() {
    this.costs = [];
  }

  trackRequest(model, promptTokens, completionTokens) {
    const cost = calculateCost(promptTokens, completionTokens, model);

    this.costs.push({
      timestamp: new Date(),
      model,
      promptTokens,
      completionTokens,
      cost
    });

    return cost;
  }

  getDailyCost() {
    const today = new Date().toDateString();
    return this.costs
      .filter(c => c.timestamp.toDateString() === today)
      .reduce((sum, c) => sum + c.cost, 0);
  }

  getCostByModel() {
    const byModel = {};
    for (const cost of this.costs) {
      byModel[cost.model] = (byModel[cost.model] || 0) + cost.cost;
    }
    return byModel;
  }

  getExpensiveRequests(threshold = 0.10) {
    return this.costs.filter(c => c.cost > threshold);
  }
}

// Usage
const tracker = new CostTracker();

const response = await openrouter.chat({...});
tracker.trackRequest(
  model,
  response.usage.prompt_tokens,
  response.usage.completion_tokens
);

console.log('Daily cost:', tracker.getDailyCost());
console.log('Cost by model:', tracker.getCostByModel());
```

### 10. Set Budget Alerts

**Configuration:**
```bash
# In .env
OPENROUTER_BUDGET_DAILY=10.00
OPENROUTER_BUDGET_MONTHLY=200.00
OPENROUTER_ALERT_THRESHOLD=0.80  # Alert at 80%
```

**Implementation:**
```javascript
async function checkBudget() {
  const currentSpend = await getCurrentMonthlySpend();
  const budget = parseFloat(process.env.OPENROUTER_BUDGET_MONTHLY);
  const percentage = (currentSpend / budget) * 100;

  if (percentage >= 80) {
    await sendAlert('WARNING', `Budget 80% used: $${currentSpend}/$${budget}`);
  }

  if (percentage >= 100) {
    throw new Error('Monthly budget exceeded!');
  }
}

// Check before expensive operations
await checkBudget();
const response = await openrouter.chat({...});
```

## Cost Comparison Examples

### Example 1: Simple Classification

**Task:** Classify 1000 support tickets

**Expensive approach:**
```javascript
// Using Claude Opus: $15 prompt / $75 completion
for (const ticket of tickets) {
  await classify(ticket, 'anthropic/claude-3-opus');
}
// Estimated cost: $5-10
```

**Optimized approach:**
```javascript
// Using Claude Haiku: $0.25 prompt / $1.25 completion
const batched = tickets.slice(0, 100).join('\n---\n');
await classify(batched, 'anthropic/claude-3-haiku');
// Estimated cost: $0.10-0.20
```

**Savings:** 95%+

### Example 2: Content Summarization

**Task:** Summarize 100 articles

**Expensive approach:**
```javascript
// GPT-4 Turbo with full context
for (const article of articles) {
  await summarize(article, 'openai/gpt-4-turbo', { max_tokens: 1000 });
}
// Estimated cost: $15-25
```

**Optimized approach:**
```javascript
// Claude Haiku with limited output
for (const article of articles) {
  await summarize(article, 'anthropic/claude-3-haiku', { max_tokens: 200 });
}
// Estimated cost: $0.50-1.00
```

**Savings:** 95%+

### Example 3: Code Generation

**Task:** Generate 50 code snippets

**Expensive approach:**
```javascript
// Claude Opus for all snippets
for (const spec of specs) {
  await generateCode(spec, 'anthropic/claude-3-opus');
}
// Estimated cost: $8-12
```

**Optimized approach:**
```javascript
// Use appropriate model for complexity
for (const spec of specs) {
  const model = spec.complexity === 'high'
    ? 'anthropic/claude-3.5-sonnet'
    : 'anthropic/claude-3-haiku';
  await generateCode(spec, model);
}
// Estimated cost: $1-2
```

**Savings:** 80-90%

## Model Selection Guide

Choose the right model for your task:

### Simple Tasks (Use Haiku or GPT-3.5)
- Classification
- Simple Q&A
- Data extraction
- Basic summarization
- Simple code completion

### Medium Tasks (Use Sonnet or GPT-4 Turbo)
- Complex analysis
- Detailed summarization
- Code generation
- Technical writing
- Multi-step reasoning

### Complex Tasks (Use Opus)
- Advanced reasoning
- Creative writing
- Complex code architecture
- Research analysis
- Strategic planning

## Cost Monitoring Script

```bash
#!/bin/bash
# Monitor daily costs

echo "OpenRouter Cost Analysis"
echo "======================="

# Get usage data (placeholder - use actual API)
echo "Daily costs:"
echo "  Today:     \$5.42"
echo "  Yesterday: \$8.21"
echo "  This week: \$34.19"
echo "  This month: \$127.53"

echo ""
echo "By model:"
echo "  claude-3.5-sonnet: \$85.20 (67%)"
echo "  claude-3-haiku:    \$32.10 (25%)"
echo "  gpt-4-turbo:       \$10.23 (8%)"

echo ""
echo "Budget status:"
BUDGET=200
CURRENT=127.53
PERCENTAGE=$(echo "scale=1; $CURRENT / $BUDGET * 100" | bc)
echo "  Budget: \$$BUDGET"
echo "  Spent:  \$$CURRENT ($PERCENTAGE%)"
echo "  Remaining: \$$(echo "$BUDGET - $CURRENT" | bc)"
```

## Validation Checklist

- [ ] Using smallest model necessary for each task
- [ ] Response length limited with max_tokens
- [ ] Caching implemented for repeated requests
- [ ] Prompts optimized for brevity
- [ ] Similar requests batched together
- [ ] Provider preferences set for cost
- [ ] Fallback chain uses cheaper models
- [ ] Cost tracking implemented
- [ ] Budget alerts configured
- [ ] Regular cost analysis performed

## Quick Cost Analysis

```bash
# Analyze current usage
bash scripts/analyze-usage.sh

# Review configuration for cost optimization
bash scripts/validate-env-config.sh
```

## Getting Help

For cost optimization assistance:

```bash
# Run cost analysis
bash scripts/analyze-usage.sh

# Check current configuration
bash scripts/troubleshoot.sh
```

Or contact support:
- Email: support@openrouter.ai
- Ask about: Volume discounts, cost optimization strategies
- Share: Usage patterns, budget requirements
