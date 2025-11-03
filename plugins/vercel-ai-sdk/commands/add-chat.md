---
description: Add chat UI with message persistence to existing Vercel AI SDK project
argument-hint: none
allowed-tools: WebFetch, Read, Write, Edit, Bash(*), Glob, Grep, Skill
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

Goal: Add chat interface with message persistence to existing Vercel AI SDK project

Core Principles:
- Detect existing framework (React/Next.js/Vue/Svelte)
- Fetch chat-specific docs (2-3 URLs)
- Implement UI components and persistence
- Verify functionality

Phase 1: Discovery
Goal: Understand project and framework

Actions:
- Detect framework: @package.json
- Check for UI library (React, Vue, Svelte)
- Identify where to add chat components
- Check if streaming already exists

Phase 2: Fetch Chat Documentation
Goal: Get chat UI docs only

Actions:
Fetch these docs in parallel (3 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot
2. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-message-persistence
3. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-resume-streams

Phase 3: Implementation
Goal: Add chat UI and persistence

Actions:

Invoke the **general-purpose** agent to implement chat:

The agent should:
- Create chat UI component (useChat hook or equivalent)
- Add message display component
- Implement input handling
- Add message persistence (localStorage or database)
- Create API route/endpoint for chat
- Add loading states and error handling
- Style with existing CSS framework or Tailwind

Provide the agent with:
- Context: Framework and existing code
- Target: Working chat interface with persistence
- Expected output: Chat component, API route, styling

Phase 4: Verification
Goal: Ensure chat works

Actions:
- For TypeScript: Run npx tsc --noEmit
- Verify chat component renders
- Check API route exists
- Test message persistence
- Verify styling applied

Phase 5: Summary
Goal: Show what was added

Actions:
Provide summary:
- Chat components created
- API routes added
- Persistence mechanism used
- How to test chat
- Customization options
- Next steps: Add tools with /vercel-ai-sdk:add-tools

Important Notes:
- Framework-specific implementation
- Fetches minimal docs (3 URLs)
- Includes persistence out of the box
- Adapts styling to project
