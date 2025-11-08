---
description: Add tool/function calling capability to existing Vercel AI SDK project
argument-hint: none
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

Goal: Add tool/function calling to existing Vercel AI SDK project with focused implementation

Core Principles:
- Detect existing project structure
- Fetch only tools-specific docs (2-3 URLs)
- Implement tool definitions with proper schemas
- Verify functionality

Phase 1: Discovery
Goal: Understand existing project setup

Actions:
- Detect project type: Check for package.json, requirements.txt
- Load existing configuration: @package.json or @requirements.txt
- Identify framework and AI SDK usage
- Find where tools should be integrated

Phase 2: Fetch Tools Documentation
Goal: Get tools-specific docs only

Actions:
Fetch these docs in parallel (3 URLs max):

1. WebFetch: https://ai-sdk.dev/docs/foundations/tools
2. WebFetch: https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling
3. WebFetch: https://ai-sdk.dev/docs/ai-sdk-ui/chatbot-tool-usage (if frontend)

Phase 3: Implementation
Goal: Add tool calling capability

Actions:

Invoke the **general-purpose** agent to implement tools: The agent should:
- Define tool schemas with zod or similar validation
- Create tool handler functions
- Integrate tools with existing AI calls
- Add example tools (e.g., getWeather, calculator)
- Include proper error handling and validation
- Add comments explaining tool structure

Provide the agent with:
- Context: Existing project files
- Target: Add 1-2 example tools with proper schemas
- Expected output: Working tool implementation

Phase 4: Verification
Goal: Ensure tools work

Actions:
- For TypeScript: Run npx tsc --noEmit
- For JavaScript: Verify syntax
- For Python: Check imports and schemas
- Verify tool schemas are valid
- Check tool handlers exist

Phase 5: Summary
Goal: Show what was added

Actions:
Provide summary:
- Tool definitions created
- Handler functions implemented
- How to test tool calling
- Example tool usage
- How to add more custom tools
- Next steps: Consider /vercel-ai-sdk:add-chat for UI

Important Notes:
- Adapts to existing framework
- Fetches minimal docs (3 URLs)
- Creates 1-2 example tools
- Uses proper schema validation
- Focused on tools only
