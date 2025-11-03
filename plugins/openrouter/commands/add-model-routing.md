---
description: Configure intelligent model routing and cost optimization with fallback strategies
argument-hint: [routing-strategy]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Configure intelligent model routing in OpenRouter to optimize cost, performance, and reliability with automatic fallback strategies.

Core Principles:
- Detect project language and existing OpenRouter setup
- Configure provider preferences and fallback chains
- Set up cost-aware routing strategies
- Enable monitoring and analytics

Phase 1: Discovery
Goal: Understand project setup and routing requirements

Actions:
- Load OpenRouter documentation:
  @plugins/openrouter/docs/OpenRouter_Documentation_Analysis.md
- Detect project language:
  !{bash test -f package.json && echo "Node.js" || test -f requirements.txt -o -f pyproject.toml && echo "Python" || echo "Unknown"}
- Check for existing OpenRouter configuration:
  !{bash find . -name "*.py" -o -name "*.ts" -o -name "*.js" | xargs grep -l "openrouter" 2>/dev/null | head -5}
- Parse $ARGUMENTS for routing strategy (cost, speed, quality, balanced, custom)

Phase 2: Analysis
Goal: Understand current configuration and requirements

Actions:
- Check existing API configuration:
  !{bash grep -r "OPENROUTER" .env .env.local 2>/dev/null || echo "No config found"}
- Identify use cases from codebase:
  !{bash find . -name "*.py" -o -name "*.ts" -o -name "*.js" | xargs grep -l "ChatOpenAI\|openai\|anthropic" 2>/dev/null | wc -l}
- Check if monitoring is enabled:
  !{bash grep -r "X-Title\|HTTP-Referer" . 2>/dev/null || echo "No monitoring"}

Phase 3: Implementation
Goal: Configure model routing and optimization

Actions:

Task(description="Configure model routing", subagent_type="openrouter-routing-agent", prompt="You are the openrouter-routing-agent. Configure intelligent model routing for $ARGUMENTS.

Context from Discovery:
- Project language detected
- Existing OpenRouter setup status
- Routing strategy: $ARGUMENTS (cost/speed/quality/balanced/custom)

Tasks:
1. Create routing configuration file:

   **Python:**
   - File: src/openrouter_config.py or config/openrouter.py
   - Define model routing strategies
   - Set up fallback chains
   - Configure provider preferences

   **TypeScript:**
   - File: src/config/openrouter.ts or lib/openrouter-config.ts
   - Define typed routing configurations
   - Set up fallback chains
   - Configure provider preferences

2. Implement routing strategies based on $ARGUMENTS:
   - Cost: Free/low-cost models with premium fallback
   - Speed: Fastest models with streaming
   - Quality: Premium models with high-quality fallbacks
   - Balanced: Task-based routing with cost/quality tradeoffs
   - Custom: User-defined preferences and rules

3. Set up fallback strategies:
   - Primary model configuration
   - Secondary fallback options
   - Tertiary emergency fallbacks
   - Error handling and retries
   - Circuit breaker patterns

4. Configure monitoring and analytics:
   - Add X-Title header for request tracking
   - Add HTTP-Referer for attribution
   - Set up cost tracking
   - Enable usage analytics
   - Configure alerts for cost thresholds

5. Update environment configuration:
   - OPENROUTER_API_KEY (if not present)
   - OPENROUTER_APP_NAME for tracking
   - OPENROUTER_SITE_URL for attribution
   - Cost limits and budgets
   - Preferred providers list

6. Create helper utilities:
   - Model selector function
   - Cost calculator
   - Performance tracker
   - Fallback handler
   - Provider availability checker

7. Generate usage examples:
   - Basic routing usage
   - Dynamic model selection
   - Cost-aware prompting
   - Fallback handling
   - Monitoring integration

WebFetch latest documentation:
- https://openrouter.ai/docs/quick-start
- https://openrouter.ai/docs/provider-routing
- https://openrouter.ai/docs/models
- https://openrouter.ai/docs/requests

Deliverable: Complete routing configuration with examples and monitoring")

Phase 4: Verification
Goal: Ensure routing configuration works

Actions:
- Verify configuration file created:
  !{bash find . -name "*routing*" -o -name "*openrouter*config*" | grep -v node_modules | head -3}
- Check environment variables:
  !{bash grep -E "OPENROUTER_(API_KEY|APP_NAME|SITE_URL)" .env .env.local 2>/dev/null || echo "⚠️ Configure environment"}
- Test routing logic exists:
  !{bash find . -name "*.py" -o -name "*.ts" -o -name "*.js" | xargs grep -l "fallback\|routing" 2>/dev/null | wc -l}

Phase 5: Summary
Goal: Provide configuration overview

Actions:
- Display configuration summary:
  - ✅ Model routing strategy configured
  - ✅ Fallback chains established
  - ✅ Monitoring and analytics enabled
  - ✅ Cost optimization rules set

- Next steps:
  1. Add OpenRouter credentials to environment
  2. Test routing with sample requests
  3. Monitor costs at https://openrouter.ai/activity
  4. Adjust routing rules based on usage

- Features enabled:
  - Provider preferences and fallback chains
  - Auto-routing by task complexity
  - Cost controls and budget alerts
  - Performance tracking and analytics
