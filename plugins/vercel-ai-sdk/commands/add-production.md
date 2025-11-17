---
description: Add production features to Vercel AI SDK app including telemetry, rate limiting, error handling, testing, and middleware
argument-hint: [feature-requests]
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---

## Available Skills

This commands has access to the following skills from the vercel-ai-sdk plugin:

- **SKILLS-OVERVIEW.md**
- **agent-workflow-patterns**: AI agent workflow patterns including ReAct agents, multi-agent systems, loop control, tool orchestration, and autonomous agent architectures. Use when building AI agents, implementing workflows, creating autonomous systems, or when user mentions agents, workflows, ReAct, multi-step reasoning, loop control, agent orchestration, or autonomous AI.
- **generative-ui-patterns**: Generative UI implementation patterns for AI SDK RSC including server-side streaming components, dynamic UI generation, and client-server coordination. Use when implementing generative UI, building AI SDK RSC, creating streaming components, or when user mentions generative UI, React Server Components, dynamic UI, AI-generated interfaces, or server-side streaming.
- **provider-config-validator**: Validate and debug Vercel AI SDK provider configurations including API keys, environment setup, model compatibility, and rate limiting. Use when encountering provider errors, authentication failures, API key issues, missing environment variables, model compatibility problems, rate limiting errors, or when user mentions provider setup, configuration debugging, or SDK connection issues.
- **rag-implementation**: RAG (Retrieval Augmented Generation) implementation patterns including document chunking, embedding generation, vector database integration, semantic search, and RAG pipelines. Use when building RAG systems, implementing semantic search, creating knowledge bases, or when user mentions RAG, embeddings, vector database, retrieval, document chunking, or knowledge retrieval.
- **testing-patterns**: Testing patterns for Vercel AI SDK including mock providers, streaming tests, tool calling tests, snapshot testing, and test coverage strategies. Use when implementing tests, creating test suites, mocking AI providers, or when user mentions testing, mocks, test coverage, AI testing, streaming tests, or tool testing.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

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

Goal: Prepare a Vercel AI SDK application for production deployment with telemetry/observability, rate limiting, comprehensive error handling, testing infrastructure, and middleware.

Core Principles:
- Security and reliability first
- Ask about monitoring platform preferences
- Follow Vercel AI SDK documentation patterns
- Implement comprehensive error handling and testing

Phase 1: Discovery
Goal: Understand what production features are needed

Actions:
- Parse $ARGUMENTS to identify requested features
- If unclear or no arguments provided, use AskUserQuestion to gather:
  - Which production features do you want? (Telemetry, rate limiting, error handling, testing, middleware)
  - What observability platform do you use? (Datadog, New Relic, Vercel Analytics, etc.)
  - Do you have Redis/Upstash for rate limiting?
  - What's your target error rate and latency?
- Load package.json to understand current setup
- Example: @package.json

Phase 2: Analysis
Goal: Understand current project state

Actions:
- Check for existing monitoring/logging setup
- Identify production environment (Vercel, AWS, self-hosted)
- Review current error handling patterns
- Assess existing test coverage
- Example: !{bash ls *.test.ts *.spec.ts 2>/dev/null | wc -l}

Phase 3: Implementation
Goal: Add production features using specialized agent

Actions:

Invoke the vercel-ai-production-agent to implement the requested production features.

The agent should:
- Fetch relevant Vercel AI SDK documentation for the requested features
- Design production-ready architecture
- Install required packages (OpenTelemetry, testing libraries, rate limiting, etc.)
- Implement requested features following SDK best practices:
  - Telemetry with OpenTelemetry or custom providers
  - Rate limiting with Redis/Upstash or edge solutions
  - Comprehensive error handling with retry and circuit breaker patterns
  - Test suites with mocks and snapshots (>80% coverage)
  - Middleware for authentication, validation, logging
- Add proper TypeScript types
- Implement monitoring dashboards and alerts
- Follow security best practices

Provide the agent with:
- Context: Current project structure and deployment platform
- Target: $ARGUMENTS (requested production features)
- Expected output: Production-ready application with monitoring and reliability features

Phase 4: Verification
Goal: Ensure production readiness

Actions:
- Run test suites and check coverage
- Example: !{bash npm test}
- Verify telemetry data flows to monitoring platform
- Test rate limiting under load
- Validate error handling with failure scenarios
- Run TypeScript compilation check
- Example: !{bash npx tsc --noEmit}

Phase 5: Summary
Goal: Document production setup

Actions:
- List all production features implemented
- Show monitoring dashboard configuration
- Note environment variables and secrets needed
- Provide deployment checklist
- Suggest next steps (load testing, security audit, deployment)
