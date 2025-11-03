---
description: Add rate limiting, monitoring, error handling, security best practices, and cost optimization
argument-hint: [options]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add production-ready features including rate limiting, monitoring/telemetry, comprehensive error handling, security best practices, and cost optimization for ElevenLabs integration.

Core Principles:
- Implement client-side rate limiting
- Add monitoring and usage tracking
- Comprehensive error handling for all scenarios
- Secure API key management
- Optimize costs through model selection and caching
- Production deployment best practices

Phase 1: Discovery
Goal: Understand production requirements

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Check current implementation:
  !{bash find . -name "*.ts" -o -name "*.py" | grep -E "(eleven|voice|audio)" | head -10}
- Detect framework: @package.json or @pyproject.toml
- Parse $ARGUMENTS for specific needs

Phase 2: Requirements Gathering
Goal: Clarify production features

Actions:
- Use AskUserQuestion if needed:
  - Which features? (Rate limiting, Monitoring, Error handling, Security, Cost optimization)
  - Monitoring platform? (Built-in logging, external service)
  - Error strategy? (Retry logic, fallbacks, user notifications)
  - Rate limits? (Based on tier: Free, Starter, Pro, etc.)
  - Caching? (Audio caching for repeated text)

Phase 3: Planning
Goal: Design production architecture

Actions:
- Plan implementation:
  - Rate Limiting: concurrent request limits, queue management
  - Monitoring: usage tracking, latency metrics, error rates
  - Error Handling: retry with exponential backoff, fallbacks
  - Security: API key rotation, environment variables, HTTPS
  - Cost Optimization: model selection, caching, batch processing
- Present plan

Phase 4: Implementation
Goal: Build production features

Actions:

Launch the elevenlabs-production-agent to implement production features.

Provide detailed requirements:
- Context: Framework, current implementation, deployment target
- Target: $ARGUMENTS
- Requirements:
  - Rate Limiting & Concurrency:
    * Concurrent request limits (based on pricing tier)
    * Request queue with priority
    * Backpressure handling
    * Rate limit error handling (429 responses)
    * Per-user/per-IP rate limiting
  - Monitoring & Telemetry:
    * Usage tracking: characters (TTS), hours (STT)
    * Latency monitoring per model
    * Error rate tracking
    * Cost estimation dashboards
    * Alert thresholds for quota limits
  - Error Handling:
    * Retry logic with exponential backoff
    * Circuit breaker pattern
    * Graceful degradation
    * User-friendly error messages
    * Error logging and reporting
  - Security Best Practices:
    * API key in environment variables (never hardcoded)
    * HTTPS for all requests
    * Input validation and sanitization
    * File upload security (type/size validation)
    * Rate limiting per IP
    * CORS configuration (if web app)
  - Cost Optimization:
    * Model selection guide:
      - Flash v2.5: lowest cost, real-time
      - Turbo v2.5: balanced
      - Multilingual v2: quality for long-form
      - v3 Alpha: highest quality when needed
    * Audio caching for repeated text
    * Batch processing when possible
    * Character/hour usage tracking
    * Cost alerts and limits
  - Production Configuration:
    * Environment-based config (dev/staging/prod)
    * Feature flags
    * Health check endpoints
    * Graceful shutdown handling
  - Use progressive docs: fetch production best practices
- Expected output:
  - Rate limiting middleware/utilities
  - Monitoring dashboard/logging
  - Error handling framework
  - Security configuration
  - Cost optimization utilities
  - Production deployment guide

Phase 5: Verification
Goal: Ensure production readiness

Actions:
- Verify files created
- Check syntax: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
- Verify environment variables referenced
- Test error handling logic

Phase 6: Summary
Goal: Guide on production deployment

Actions:
- Display summary:
  - Rate limiting: [concurrent limits]
  - Monitoring: usage tracking, latency, errors
  - Error handling: retries, fallbacks, logging
  - Security: API keys secured, HTTPS, validation
  - Cost optimization: model selection, caching
- Configuration checklist:
  - [ ] ELEVENLABS_API_KEY in environment
  - [ ] Rate limits configured for tier
  - [ ] Monitoring/logging enabled
  - [ ] Error handling tested
  - [ ] HTTPS enforced
  - [ ] Cost tracking active
- Deployment steps
- Show configuration examples
- Next steps:
  - Test with production data
  - Monitor usage and costs
  - Scale as needed
  - Full app: /elevenlabs:build-full-stack
