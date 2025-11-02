# Fallback Chain Troubleshooting

Debugging and optimizing OpenRouter fallback configurations.

## Understanding Fallback Chains

Fallback chains allow OpenRouter to automatically try alternative models when the primary model is unavailable.

### How Fallback Works

```
Request → Primary Model
            ↓ (if unavailable)
          Fallback 1
            ↓ (if unavailable)
          Fallback 2
            ↓ (if unavailable)
          Error
```

### Configuration

```bash
# In .env
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-3.5-turbo
```

## Common Issues

### Issue 1: Fallback Not Triggering

**Symptoms:**
- Request fails immediately
- No attempt to use fallback models
- Error says primary model unavailable

**Causes:**

1. **Fallback not configured**
   ```bash
   # Check configuration
   echo $OPENROUTER_FALLBACK_MODELS
   # Should output: model1,model2,model3
   ```

2. **Wrong environment variable name**
   ```bash
   # ❌ Wrong
   OPENROUTER_FALLBACKS=...
   OPENROUTER_FALLBACK=...

   # ✅ Correct
   OPENROUTER_FALLBACK_MODELS=...
   ```

3. **Not loaded in code**
   ```javascript
   // ❌ Missing fallback configuration
   const response = await fetch(url, {
     body: JSON.stringify({
       model: primaryModel,
       // Missing: route: 'fallback'
     })
   });

   // ✅ With fallback enabled
   const response = await fetch(url, {
     body: JSON.stringify({
       model: primaryModel,
       route: 'fallback',
       models: fallbackModels  // from OPENROUTER_FALLBACK_MODELS
     })
   });
   ```

**Solution:**

1. Verify configuration:
   ```bash
   bash scripts/validate-env-config.sh
   ```

2. Test fallback chain:
   ```bash
   bash scripts/test-fallback.sh
   ```

3. Update code to use fallback:
   ```javascript
   const models = [
     process.env.OPENROUTER_MODEL,
     ...process.env.OPENROUTER_FALLBACK_MODELS.split(',')
   ].map(m => m.trim());

   const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
     headers: {
       'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       model: models[0],
       route: 'fallback',
       models: models,
       messages: [...]
     })
   });
   ```

### Issue 2: All Fallback Models Unavailable

**Symptoms:**
- Primary model fails
- All fallbacks also fail
- Final error after trying all models

**Causes:**

1. **All models from same provider**
   ```bash
   # ❌ Bad: All Anthropic
   OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
   OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,anthropic/claude-4.5-sonnet
   # If Anthropic is down, all fail
   ```

2. **Models not available in your region**
3. **Account doesn't have access to any fallback models**

**Solution:**

**Use models from different providers:**
```bash
# ✅ Good: Diverse providers
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=openai/gpt-4-turbo,google/gemini-1.5-pro,meta-llama/llama-3-70b-instruct
```

**Test each fallback model:**
```bash
# Test availability of each model
for model in $(echo $OPENROUTER_FALLBACK_MODELS | tr ',' ' '); do
  echo "Testing $model..."
  bash scripts/check-model-availability.sh "$model"
done
```

**Choose highly available models:**
```bash
# Models typically with high availability
OPENROUTER_FALLBACK_MODELS=openai/gpt-3.5-turbo,anthropic/claude-4.5-sonnet,meta-llama/llama-3-8b-instruct
```

### Issue 3: Fallback Order Not Optimal

**Symptoms:**
- Falling back to expensive models first
- Poor performance from fallback models
- High costs from fallback usage

**Problem:**

```bash
# ❌ Bad order: Most expensive first
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-4-turbo,openai/gpt-3.5-turbo
```

**Solution:**

**Order by preference:**

**Option 1: Quality priority**
```bash
# Best quality models first
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-4-turbo,anthropic/claude-4.5-sonnet
```

**Option 2: Cost priority**
```bash
# Cheapest models first
OPENROUTER_FALLBACK_MODELS=meta-llama/llama-3-8b-instruct,openai/gpt-3.5-turbo,anthropic/claude-4.5-sonnet
```

**Option 3: Balanced**
```bash
# Balance quality and cost
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-3.5-turbo,meta-llama/llama-3-70b-instruct
```

### Issue 4: Fallback Latency

**Symptoms:**
- Long delays when fallback triggers
- Multiple timeout errors
- Slow response times

**Causes:**

1. **Too many fallback attempts**
2. **Slow fallback models**
3. **Network timeouts not configured**

**Solution:**

**Limit fallback depth:**
```bash
# Instead of 5 fallbacks
OPENROUTER_FALLBACK_MODELS=model1,model2,model3,model4,model5

# Use 2-3 fallbacks
OPENROUTER_FALLBACK_MODELS=model1,model2,model3
```

**Configure timeouts:**
```javascript
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 30000); // 30s

try {
  const response = await fetch(url, {
    signal: controller.signal,
    // ... other options
  });
} finally {
  clearTimeout(timeout);
}
```

**Use fast fallback models:**
```bash
# Prefer models known for speed
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-3.5-turbo,google/gemini-1.5-flash
```

### Issue 5: Fallback Cost Explosion

**Symptoms:**
- Costs higher than expected
- Falling back to expensive models frequently
- Budget alerts triggering

**Causes:**

1. **Primary model frequently unavailable**
2. **Expensive models in fallback chain**
3. **No cost monitoring**

**Solution:**

**Monitor fallback usage:**
```javascript
let fallbackCount = 0;
let primarySuccessCount = 0;

async function makeRequest(model, fallbackModels) {
  try {
    const response = await requestWithModel(model);
    primarySuccessCount++;
    return response;
  } catch (error) {
    if (error.status === 503) {
      fallbackCount++;
      console.warn(`Fallback triggered (${fallbackCount} times)`);

      // Alert if fallback rate is high
      const fallbackRate = fallbackCount / (fallbackCount + primarySuccessCount);
      if (fallbackRate > 0.3) {
        console.error('High fallback rate! Consider changing primary model.');
      }
    }
    throw error;
  }
}
```

**Use cost-effective fallbacks:**
```bash
# Ensure fallbacks are cheaper than primary
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet  # $3/1M tokens
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-3.5-turbo  # $0.25-$0.50/1M tokens
```

**Set budget alerts:**
```bash
# See templates/budget-alerts.json
OPENROUTER_BUDGET_MONTHLY=100
```

## Best Practices

### 1. Diverse Provider Mix

```bash
# ✅ Good: Different providers
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet        # Anthropic
OPENROUTER_FALLBACK_MODELS=openai/gpt-4-turbo,google/gemini-1.5-pro  # OpenAI, Google
```

### 2. Quality Degradation

Order from best to acceptable:

```bash
# Best → Good → Acceptable
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet           # Best
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,anthropic/claude-4.5-sonnet
```

### 3. Cost Control

Order from expensive to cheap (for fallback scenarios):

```bash
# If primary fails, use cheaper alternatives
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet           # Expensive primary
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-3.5-turbo  # Cheaper fallbacks
```

### 4. Geographic Diversity

Use models available in different regions:

```bash
# Models with global availability
OPENROUTER_MODEL=openai/gpt-4-turbo               # Global
OPENROUTER_FALLBACK_MODELS=mistral/mistral-large,meta-llama/llama-3-70b-instruct  # EU/Global
```

### 5. Monitor and Adjust

Track which fallbacks are actually used:

```javascript
const fallbackStats = {};

async function makeRequestWithTracking(model, fallbacks) {
  const models = [model, ...fallbacks];

  for (let i = 0; i < models.length; i++) {
    try {
      const response = await requestWithModel(models[i]);

      // Track which model was used
      fallbackStats[models[i]] = (fallbackStats[models[i]] || 0) + 1;

      if (i > 0) {
        console.log(`Used fallback ${i}: ${models[i]}`);
      }

      return response;
    } catch (error) {
      if (i === models.length - 1) throw error;
      continue;
    }
  }
}

// Periodically log stats
setInterval(() => {
  console.log('Model usage stats:', fallbackStats);
}, 3600000); // Every hour
```

## Testing Fallback Chains

### Automated Testing

```bash
#!/bin/bash
# Test fallback chain behavior

echo "Testing fallback chain..."

# Load configuration
source .env

# Test each model in chain
echo "Primary: $OPENROUTER_MODEL"
bash scripts/check-model-availability.sh "$OPENROUTER_MODEL"

IFS=',' read -ra FALLBACKS <<< "$OPENROUTER_FALLBACK_MODELS"
for i in "${!FALLBACKS[@]}"; do
  MODEL=$(echo "${FALLBACKS[$i]}" | xargs)
  echo "Fallback $((i+1)): $MODEL"
  bash scripts/check-model-availability.sh "$MODEL"
done

echo "Fallback chain test complete"
```

### Manual Testing

```javascript
// Simulate primary model failure
async function testFallback() {
  const models = [
    process.env.OPENROUTER_MODEL,
    ...process.env.OPENROUTER_FALLBACK_MODELS.split(',').map(m => m.trim())
  ];

  console.log('Testing fallback chain...');
  console.log('Models:', models);

  // Try each model
  for (let i = 0; i < models.length; i++) {
    try {
      console.log(`\nAttempting model ${i + 1}/${models.length}: ${models[i]}`);

      const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: models[i],
          messages: [{ role: 'user', content: 'Test fallback' }],
          max_tokens: 10
        })
      });

      if (response.ok) {
        console.log(`✅ Success with ${models[i]}`);
        const data = await response.json();
        console.log('Response:', data.choices[0].message.content);
      } else {
        console.log(`❌ Failed: ${response.status}`);
      }
    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
    }
  }
}

testFallback();
```

## Validation Checklist

- [ ] Fallback models configured in .env
- [ ] Fallback models from different providers
- [ ] All fallback models tested for availability
- [ ] Fallback order optimized (quality or cost)
- [ ] Fallback depth reasonable (2-3 models)
- [ ] Timeouts configured
- [ ] Fallback usage monitored
- [ ] Cost impact analyzed
- [ ] High fallback rate alerts configured

## Quick Validation

```bash
# Test your fallback configuration
bash scripts/test-fallback.sh

# Validate environment
bash scripts/validate-env-config.sh

# Full troubleshooting
bash scripts/troubleshoot.sh
```

## Recommended Fallback Configurations

### For Production

```bash
# Reliability focused
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=openai/gpt-4-turbo,google/gemini-1.5-pro
```

### For Development

```bash
# Cost focused
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=openai/gpt-3.5-turbo,meta-llama/llama-3-8b-instruct
```

### For Enterprise

```bash
# Balanced
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-4-turbo,google/gemini-1.5-pro
```

## Getting Help

If fallback issues persist:

```bash
# Run comprehensive diagnostics
bash scripts/troubleshoot.sh

# Test specific configuration
bash scripts/test-fallback.sh .env
```

Or contact support:
- Email: support@openrouter.ai
- Include: Configuration, error messages, validation output
- Ask about: Fallback best practices, model recommendations
