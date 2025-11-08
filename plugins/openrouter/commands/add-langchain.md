---
description: Add LangChain integration with OpenRouter for chains, agents, and RAG
argument-hint: [feature]
---
## Available Skills

This commands has access to the following skills from the openrouter plugin:

- **model-routing-patterns**: Model routing configuration templates and strategies for cost optimization, speed optimization, quality optimization, and intelligent fallback chains. Use when building AI applications with OpenRouter, implementing model routing strategies, optimizing API costs, setting up fallback chains, implementing quality-based routing, or when user mentions model routing, cost optimization, fallback strategies, model selection, intelligent routing, or dynamic model switching.
- **openrouter-config-validator**: Configuration validation and testing utilities for OpenRouter API. Use when validating API keys, testing model availability, checking routing configuration, troubleshooting connection issues, analyzing usage costs, or when user mentions OpenRouter validation, config testing, API troubleshooting, model availability, or cost analysis.
- **provider-integration-templates**: OpenRouter framework integration templates for Vercel AI SDK, LangChain, and OpenAI SDK. Use when integrating OpenRouter with frameworks, setting up AI providers, building chat applications, implementing streaming responses, or when user mentions Vercel AI SDK, LangChain, OpenAI SDK, framework integration, or provider setup.

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

Goal: Integrate LangChain with OpenRouter for building chains, agents, and RAG applications with access to 500+ models.

Core Principles:
- Detect project language (Python/TypeScript/JavaScript)
- Install appropriate LangChain packages for OpenRouter
- Create working examples for chains, agents, and RAG
- Provide model routing capabilities

Phase 1: Discovery
Goal: Understand project setup and requirements

Actions:
- Load OpenRouter documentation:
  @plugins/openrouter/docs/OpenRouter_Documentation_Analysis.md
- Detect project language:
  !{bash test -f package.json && echo "Node.js" || test -f requirements.txt -o -f pyproject.toml && echo "Python" || echo "Unknown"}
- Check for existing LangChain installation:
  !{bash npm list langchain 2>/dev/null || pip list | grep langchain 2>/dev/null || echo "Not installed"}
- Parse $ARGUMENTS for specific feature (chains, agents, rag, or all)

Phase 2: Analysis
Goal: Understand existing code patterns

Actions:
- Check if OpenRouter client already exists:
  !{bash find . -name "*.py" -o -name "*.ts" -o -name "*.js" | xargs grep -l "openrouter" 2>/dev/null || echo "No existing config"}
- Identify project structure:
  !{bash ls -d src lib app components 2>/dev/null || echo "Root level"}
- Check environment configuration:
  !{bash test -f .env -o -f .env.local && echo "Env file exists" || echo "No env file"}

Phase 3: Implementation
Goal: Add LangChain integration with OpenRouter

Actions:

Task(description="Integrate LangChain with OpenRouter", subagent_type="openrouter-langchain-agent", prompt="You are the openrouter-langchain-agent. Add LangChain integration with OpenRouter for $ARGUMENTS.

Context from Discovery:
- Project language detected
- Existing LangChain status
- Feature request: $ARGUMENTS (chains/agents/rag/all)

Tasks:
1. Install dependencies based on language:

   **Python:**
   - pip install langchain langchain-openai openai
   - Verify installation successful

   **TypeScript/JavaScript:**
   - npm install langchain @langchain/openai openai
   - Verify installation successful

2. Create OpenRouter client configuration:

   **Python:**
   - File: src/langchain_openrouter.py or lib/langchain_openrouter.py
   - Import ChatOpenAI from langchain_openai
   - Configure with OpenRouter base URL and API key
   - Export configured client

   **TypeScript:**
   - File: src/lib/langchain-openrouter.ts or lib/langchain-openrouter.ts
   - Import ChatOpenAI from @langchain/openai
   - Configure with OpenRouter configuration
   - Export typed client

3. Create feature-specific implementations based on $ARGUMENTS:

   If chains requested:
   - Create chain example with LLMChain or LCEL
   - Show prompt template usage
   - Demonstrate sequential chain operations
   - Include model switching example

   If agents requested:
   - Create agent with tools (calculator, search, etc.)
   - Set up agent executor
   - Show tool calling patterns
   - Include memory/conversation history

   If RAG requested:
   - Set up vector store (Chroma, FAISS, or in-memory)
   - Create embeddings configuration
   - Build retrieval chain
   - Show document loading and querying

4. Update environment configuration:
   - Add OPENROUTER_API_KEY to .env or .env.local
   - Add OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
   - Add to .env.example for reference
   - Ensure .gitignore includes .env files

5. Create usage examples:
   - File: examples/langchain-openrouter.py or examples/langchain-openrouter.ts
   - Show complete working example for requested features
   - Include multiple model usage (Claude, GPT-4, Gemini)
   - Document available patterns and best practices

WebFetch latest documentation:
- https://openrouter.ai/docs/frameworks/langchain
- https://python.langchain.com/docs/integrations/chat/openai
- https://js.langchain.com/docs/integrations/chat/openai
- https://python.langchain.com/docs/use_cases/question_answering/
- https://python.langchain.com/docs/modules/agents/

Deliverable: Working LangChain integration with OpenRouter and examples")

Phase 4: Verification
Goal: Ensure integration works

Actions:
- Verify dependencies installed:
  !{bash pip list | grep -E "langchain|openai" 2>/dev/null || npm list langchain 2>/dev/null || echo "Check installation"}
- Check configuration file created:
  !{bash find . -name "*langchain*openrouter*" -o -name "*openrouter*langchain*" | head -3}
- Verify environment setup:
  !{bash grep -q "OPENROUTER_API_KEY" .env 2>/dev/null || grep -q "OPENROUTER_API_KEY" .env.local 2>/dev/null && echo "✅ Env configured" || echo "⚠️ Add API key to .env"}

Phase 5: Summary
Goal: Provide usage instructions

Actions:
- Display integration summary:
  - ✅ LangChain and OpenRouter packages installed
  - ✅ OpenRouter client configured for LangChain
  - ✅ Example implementations created
  - ✅ Environment variables ready

- Next steps:
  1. Add your OpenRouter API key to .env or .env.local
  2. Test the integration with provided examples
  3. Explore model routing: https://openrouter.ai/models
  4. Build chains, agents, or RAG applications
  5. Customize for your use case

- Available models via OpenRouter:
  - anthropic/claude-3.5-sonnet (recommended for chains)
  - openai/gpt-4-turbo (great for agents)
  - google/gemini-pro-1.5 (cost-effective for RAG)
  - meta-llama/llama-3.1-70b-instruct (open source)
  - 500+ more at https://openrouter.ai/models

- Features enabled:
  - Chain composition with LCEL
  - Agent execution with tools
  - RAG with vector stores
  - Model routing and fallback
  - Cost optimization
  - Multi-provider access

- Example usage patterns:
  - Simple chain: prompt → model → output
  - Agent: tools + reasoning loop
  - RAG: documents → embeddings → retrieval → generation
  - Multi-model: route different tasks to optimal models
