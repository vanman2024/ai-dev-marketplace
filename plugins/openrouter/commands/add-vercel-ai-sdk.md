---
description: Add Vercel AI SDK integration with OpenRouter provider for streaming, chat, and tool calling
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

Goal: Integrate Vercel AI SDK with OpenRouter provider for Next.js applications, enabling streaming responses, chat interfaces, and tool calling with 500+ models.

Core Principles:
- Detect Next.js project structure and version
- Install @openrouter/ai-sdk-provider package
- Configure OpenRouter provider with proper types
- Create working examples for streaming, chat, and tools

Phase 1: Discovery
Goal: Understand project setup and requirements

Actions:
- Load OpenRouter documentation:
  @plugins/openrouter/docs/OpenRouter_Documentation_Analysis.md
- Detect Next.js project:
  !{bash test -f next.config.js -o -f next.config.ts && echo "Next.js found" || echo "No Next.js config"}
- Check package.json for existing AI SDK:
  @package.json
- Parse $ARGUMENTS for specific feature (streaming, chat, tools, or all)

Phase 2: Analysis
Goal: Understand existing code patterns

Actions:
- Check if Vercel AI SDK already installed:
  !{bash npm list ai 2>/dev/null | grep "ai@" || echo "Not installed"}
- Check for existing OpenRouter config:
  !{bash find . -name "*.ts" -o -name "*.tsx" | xargs grep -l "openrouter" 2>/dev/null || echo "No existing config"}
- Identify app structure (pages vs app router):
  !{bash test -d app && echo "App Router" || test -d pages && echo "Pages Router" || echo "Unknown"}

Phase 3: Implementation
Goal: Add Vercel AI SDK with OpenRouter integration

Actions:

Task(description="Integrate Vercel AI SDK with OpenRouter", subagent_type="openrouter-vercel-integration-agent", prompt="You are the openrouter-vercel-integration-agent. Add Vercel AI SDK integration with OpenRouter provider for $ARGUMENTS.

Context from Discovery:
- Next.js project structure detected
- Existing AI SDK status
- App Router vs Pages Router
- Feature request: $ARGUMENTS (streaming/chat/tools/all)

Tasks:
1. Install dependencies:
   - npm install ai @openrouter/ai-sdk-provider
   - Verify installation successful

2. Create OpenRouter provider configuration:
   - File: src/lib/openrouter.ts or lib/openrouter.ts
   - Import openrouter from '@openrouter/ai-sdk-provider'
   - Configure with API key from environment
   - Export typed client for app usage

3. Create feature-specific implementations based on $ARGUMENTS:

   If streaming requested:
   - Create API route: app/api/chat/route.ts (App Router) or pages/api/chat.ts (Pages Router)
   - Use streamText() from 'ai' package
   - Configure OpenRouter model (e.g., 'anthropic/claude-3.5-sonnet')
   - Return proper streaming response

   If chat requested:
   - Create chat component: components/Chat.tsx
   - Use useChat() hook from 'ai/react'
   - Connect to API route
   - Add message display and input

   If tools requested:
   - Create tool definition with Zod schema
   - Example: weather tool or calculator
   - Configure in streamText() call
   - Handle tool results in response

4. Update .env.local:
   - Add OPENROUTER_API_KEY if not present
   - Add to .env.example for reference
   - Ensure .gitignore includes .env.local

5. Create usage example:
   - File: examples/openrouter-chat.tsx or README section
   - Show complete working example
   - Include model switching example
   - Document available features

WebFetch latest documentation:
- https://openrouter.ai/docs/community/vercel-ai-sdk
- https://sdk.vercel.ai/docs/introduction
- https://sdk.vercel.ai/docs/ai-sdk-core/streaming
- https://sdk.vercel.ai/docs/ai-sdk-ui/chatbot

Deliverable: Working Vercel AI SDK integration with OpenRouter provider and examples")

Phase 4: Verification
Goal: Ensure integration works

Actions:
- Verify dependencies installed:
  !{bash npm list @openrouter/ai-sdk-provider 2>/dev/null && echo "✅ Provider installed" || echo "❌ Installation failed"}
- Check configuration file created:
  !{bash test -f src/lib/openrouter.ts -o -f lib/openrouter.ts && echo "✅ Config created" || echo "❌ Config missing"}
- Verify API route exists:
  !{bash find . -path "*/api/chat/route.ts" -o -path "*/api/chat.ts" | head -1}
- Check environment setup:
  !{bash grep -q "OPENROUTER_API_KEY" .env.local 2>/dev/null && echo "✅ Env configured" || echo "⚠️ Add API key to .env.local"}

Phase 5: Summary
Goal: Provide usage instructions

Actions:
- Display integration summary:
  - ✅ @openrouter/ai-sdk-provider installed
  - ✅ OpenRouter provider configured
  - ✅ API routes created
  - ✅ Example components ready

- Next steps:
  1. Add your OpenRouter API key to .env.local
  2. Start dev server: npm run dev
  3. Test chat interface at /chat (if created)
  4. Explore model routing: https://openrouter.ai/models
  5. Customize for your use case

- Available models via OpenRouter:
  - anthropic/claude-3.5-sonnet (recommended)
  - openai/gpt-4-turbo
  - google/gemini-pro-1.5
  - meta-llama/llama-3.1-70b-instruct
  - 500+ more at https://openrouter.ai/models

- Features enabled:
  - Streaming text responses
  - Chat UI with useChat hook
  - Tool calling (if requested)
  - Model switching
  - Cost optimization via routing
