---
description: Build a complete production-ready Vercel AI SDK application from scratch by chaining all feature commands together
argument-hint: <project-name>
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

Goal: Build a complete, production-ready Vercel AI SDK application from scratch with all features including core functionality, UI features, data processing, production readiness, and advanced capabilities.

Core Principles:
- Track progress with TodoWrite throughout the build
- Ask clarifying questions early to understand requirements
- Chain commands sequentially to build incrementally
- Verify each phase before proceeding to the next

Phase 1: Discovery
Goal: Understand what needs to be built

Actions:
- Create todo list with all build phases using TodoWrite
- Parse $ARGUMENTS for project name
- If unclear or no project name provided, use AskUserQuestion to gather:
  - What's the project name?
  - What framework do you prefer? (Next.js, React, Node.js, etc.)
  - Which AI provider? (OpenAI, Anthropic, Google, etc.)
  - What's the main use case? (Chatbot, RAG, agents, etc.)
  - Do you want all features or a subset?

Phase 2: Scaffold Project
Goal: Create minimal project structure

Actions:

Invoke the new-app command to create the initial scaffold.

SlashCommand: /vercel-ai-sdk:new-app $ARGUMENTS

Wait for scaffolding to complete before proceeding.

Phase 3: Add Core Features
Goal: Add streaming, tools, and chat functionality

Actions:

Run these commands sequentially (one after another):

SlashCommand: /vercel-ai-sdk:add-streaming

Wait for completion, then:

SlashCommand: /vercel-ai-sdk:add-tools

Wait for completion, then:

SlashCommand: /vercel-ai-sdk:add-chat

Update TodoWrite to mark these tasks complete.

Phase 4: Add UI Features
Goal: Add advanced UI capabilities

Actions:

SlashCommand: /vercel-ai-sdk:add-ui-features

Features to include:
- Generative UI (if Next.js App Router)
- useObject for structured outputs
- useCompletion for text completion
- Message persistence with database
- File attachments support

Wait for completion before proceeding.

Phase 5: Add Data Features
Goal: Add embeddings, RAG, and structured data

Actions:

SlashCommand: /vercel-ai-sdk:add-data-features

Features to include:
- Embeddings generation
- RAG with vector database
- Structured data generation

Wait for completion before proceeding.

Phase 6: Add Production Features
Goal: Make the application production-ready

Actions:

SlashCommand: /vercel-ai-sdk:add-production

Features to include:
- Telemetry and observability
- Rate limiting
- Error handling patterns
- Testing infrastructure
- Middleware

Wait for completion before proceeding.

Phase 7: Add Advanced Features (Optional)
Goal: Add cutting-edge AI capabilities

Actions:

Ask user if they want advanced features using AskUserQuestion:
- Do you need AI agents with workflows?
- Do you need image generation?
- Do you need audio transcription/speech synthesis?

If yes:

SlashCommand: /vercel-ai-sdk:add-advanced

Features to include based on user's answers:
- AI agents and workflows
- MCP tools integration
- Image generation
- Audio processing

Phase 8: Verification
Goal: Ensure everything works together

Actions:
- Run TypeScript compilation check
- Example: !{bash npx tsc --noEmit}
- Run test suites
- Example: !{bash npm test}
- Check all environment variables are documented
- Verify all dependencies are installed

Phase 9: Summary
Goal: Document the complete build

Actions:
- Mark all todos as complete using TodoWrite
- List all features that were implemented:
  - Core: Streaming, Tools, Chat
  - UI: Generative UI, useObject, useCompletion, Persistence, Attachments
  - Data: Embeddings, RAG, Structured Data
  - Production: Telemetry, Rate Limiting, Error Handling, Testing, Middleware
  - Advanced: Agents, MCP Tools, Image Generation, Audio Processing (if added)
- Show project structure
- List environment variables that need to be set
- Provide deployment checklist
- Suggest next steps (styling, deployment, optimization)
