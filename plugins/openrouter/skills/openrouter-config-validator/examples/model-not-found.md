# Model Not Found Troubleshooting

Solutions for when requested models are unavailable or not found.

## Issue 1: Model ID Not Found

**Symptoms:**
- Error: "Model not found"
- HTTP 404 response
- Model appears in docs but not available

**Common Causes:**

1. **Typo in model ID**
   ```bash
   # ❌ Wrong
   anthropic/claude-3-sonnet

   # ✅ Correct
   anthropic/claude-4.5-sonnet
   ```

2. **Wrong provider prefix**
   ```bash
   # ❌ Wrong
   claude-4.5-sonnet

   # ✅ Correct
   anthropic/claude-4.5-sonnet
   ```

3. **Model version changed**
   ```bash
   # Old version (may be deprecated)
   openai/gpt-4

   # New version
   openai/gpt-4-turbo
   ```

**Solution:**

**Check model availability:**
```bash
bash scripts/check-model-availability.sh "anthropic/claude-4.5-sonnet"
```

**List all available models:**
```bash
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | jq '.data[] | .id'
```

**Search for similar models:**
```bash
# Find Claude models
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | select(.id | contains("claude")) | .id'
```

## Issue 2: Model Requires Higher Tier

**Symptoms:**
- Model exists but you can't access it
- Error: "Insufficient permissions"
- Model shows in list but fails on use

**Solution:**

1. Check your account tier at https://openrouter.ai/settings
2. Some models require:
   - Verified account
   - Minimum credit balance
   - Special access approval

3. **Alternative**: Use similar models that are available:
   ```bash
   # Instead of restricted model
   anthropic/claude-4.5-sonnet

   # Try available alternative
   anthropic/claude-4.5-sonnet
   ```

## Issue 3: Model Temporarily Unavailable

**Symptoms:**
- Model worked before
- Now returns 503 or timeout
- Other models work fine

**Possible Causes:**
- Provider outage
- High demand
- Maintenance
- Regional unavailability

**Solutions:**

**Check provider status:**
```bash
bash scripts/check-provider-status.sh anthropic
```

**Use fallback models:**
```bash
# In .env, configure fallbacks
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
OPENROUTER_FALLBACK_MODELS=anthropic/claude-4.5-sonnet,openai/gpt-4-turbo
```

**Test fallback chain:**
```bash
bash scripts/test-fallback.sh
```

## Issue 4: Model Deprecated

**Symptoms:**
- Model ID from old documentation
- Error says model is deprecated
- Suggestion to use newer version

**Solution:**

**Check model status:**
```bash
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | select(.id == "old/model-id")'
```

**Migration guide:**

| Deprecated Model | Current Alternative |
|-----------------|---------------------|
| `openai/gpt-3.5-turbo-16k` | `openai/gpt-3.5-turbo` (now has 16k by default) |
| `anthropic/claude-2` | `anthropic/claude-4.5-sonnet` |
| `anthropic/claude-instant-v1` | `anthropic/claude-4.5-sonnet` |
| `openai/gpt-4-32k` | `openai/gpt-4-turbo` (128k context) |

**Update configuration:**
```bash
# Old
OPENROUTER_MODEL=anthropic/claude-2

# New
OPENROUTER_MODEL=anthropic/claude-4.5-sonnet
```

## Issue 5: Regional Restrictions

**Symptoms:**
- Model available in docs
- Works for some users
- Fails for you with geographic error

**Solution:**

Some models have geographic restrictions:
- GDPR compliance
- Export controls
- Provider policies

**Check available models for your region:**
```bash
bash scripts/check-model-availability.sh "provider/model"
```

**Use alternative providers:**
```bash
# If US-based model restricted
openai/gpt-4-turbo  # May be restricted

# Try European alternative
mistral/mistral-large  # Often available globally
```

## Issue 6: Model Name Case Sensitivity

**Symptoms:**
- Error on valid-looking model ID
- Works when case changes

**Solution:**

Model IDs are **case-sensitive**:

```bash
# ❌ Wrong
Anthropic/Claude-3.5-Sonnet
ANTHROPIC/CLAUDE-3.5-SONNET

# ✅ Correct
anthropic/claude-4.5-sonnet
```

**Always use lowercase** for provider and model names.

## Finding the Right Model

### Step 1: Browse Available Models

Visit https://openrouter.ai/models or:

```bash
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | {id, name, pricing}'
```

### Step 2: Filter by Criteria

**By provider:**
```bash
# List all Anthropic models
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | select(.id | startswith("anthropic/")) | .id'
```

**By price:**
```bash
# Find models under $0.01 per 1K tokens
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | select(.pricing.prompt < 0.00001) | {id, pricing}'
```

**By context length:**
```bash
# Find models with 100k+ context
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" | \
  jq '.data[] | select(.context_length >= 100000) | {id, context_length}'
```

### Step 3: Test Model Availability

```bash
bash scripts/check-model-availability.sh "provider/model-name"
```

### Step 4: Update Configuration

```bash
# Update .env
OPENROUTER_MODEL=provider/model-name
```

## Model Recommendations by Use Case

### General Purpose
```bash
# Best quality
anthropic/claude-4.5-sonnet

# Best value
anthropic/claude-4.5-sonnet
openai/gpt-3.5-turbo
```

### Long Context
```bash
# 200k context
anthropic/claude-4.5-sonnet
anthropic/claude-4.5-sonnet

# 128k context
openai/gpt-4-turbo
```

### Cost-Optimized
```bash
# Very cheap
meta-llama/llama-3-8b-instruct
mistral/mistral-7b-instruct

# Good value
anthropic/claude-4.5-sonnet
google/gemini-1.5-flash
```

### Specialized Tasks

**Code generation:**
```bash
openai/gpt-4-turbo
anthropic/claude-4.5-sonnet
```

**Creative writing:**
```bash
anthropic/claude-4.5-sonnet
openai/gpt-4-turbo
```

**Analysis:**
```bash
anthropic/claude-4.5-sonnet
openai/gpt-4-turbo
```

**Simple tasks:**
```bash
anthropic/claude-4.5-sonnet
openai/gpt-3.5-turbo
meta-llama/llama-3-8b-instruct
```

## Validation Checklist

- [ ] Model ID is spelled correctly
- [ ] Model ID is lowercase
- [ ] Provider prefix is included (provider/model)
- [ ] Model is in available models list
- [ ] Account has access to model
- [ ] Model is not deprecated
- [ ] Model available in your region
- [ ] Fallback models configured
- [ ] Fallback models tested

## Quick Validation

```bash
# Validate your primary model
bash scripts/check-model-availability.sh "$OPENROUTER_MODEL"

# Test entire routing configuration
bash scripts/test-routing.sh

# Run comprehensive troubleshooting
bash scripts/troubleshoot.sh
```

## Getting Help

If model issues persist:

1. **Check model documentation:**
   - https://openrouter.ai/models
   - Provider's official docs

2. **Verify with script:**
   ```bash
   bash scripts/check-model-availability.sh "model-id"
   ```

3. **Contact support:**
   - Email: support@openrouter.ai
   - Include: Model ID, error message, validation output
   - Ask about model availability in your region
