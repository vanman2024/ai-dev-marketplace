---
description: Add another AI provider to existing Vercel AI SDK project
argument-hint: none
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

Goal: Add additional AI provider (OpenAI, Anthropic, Google, etc.) to project

Core Principles:
- Ask which provider to add
- Fetch provider-specific docs (1-2 URLs)
- Install and configure provider
- Simple configuration, no complex logic needed

Phase 1: Discovery
Goal: Determine which provider to add

Actions:
- Check existing providers: @package.json or @requirements.txt
- Ask user: "Which AI provider would you like to add? OpenAI, Anthropic, Google, xAI, or other?"
- Wait for response

Phase 2: Fetch Provider Documentation
Goal: Get provider setup docs

Actions:
Based on user selection, fetch (2 URLs max):

1. WebFetch: https://ai-sdk.dev/providers/ai-sdk-providers/[provider]
2. WebFetch: https://ai-sdk.dev/docs/foundations/providers-and-models

Replace [provider] with: openai, anthropic, google-generative-ai, xai, etc.

Phase 3: Installation
Goal: Install provider package

Actions:
- Check latest version: WebSearch for package on npm/PyPI
- Install provider package:
  - TypeScript/JavaScript: npm install @ai-sdk/[provider]
  - Python: pip install [provider-package]
- Verify installation

Phase 4: Configuration
Goal: Update config and env

Actions:
- Add API key to .env.example: [PROVIDER]_API_KEY=your_key_here
- Update code to import new provider
- Add example showing how to use provider
- Document how to get API key
- Show provider-specific model names

Phase 5: Summary
Goal: Show configuration steps

Actions:
Provide:
- Provider installed
- Environment variable needed
- Where to get API key
- Example usage with new provider
- How to switch between providers

Important Notes:
- Simple configuration task (Pattern 1-style)
- Minimal doc fetching (2 URLs)
- Focused on setup only
- No complex implementation
