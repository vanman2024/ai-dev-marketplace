---
description: Initialize OpenRouter SDK with API key configuration, model selection, and framework integration setup
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
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

Goal: Set up OpenRouter SDK in a new or existing project with intelligent framework detection, API key configuration, and provider/model selection.

Core Principles:
- Detect existing frameworks (Next.js, Python, TypeScript) - never assume
- Ask user for preferences when multiple options exist
- Create proper environment configuration with secure API key storage
- Provide framework-specific integration examples

Phase 1: Discovery
Goal: Understand project structure and user requirements

Actions:
- Load OpenRouter documentation for reference:
  @plugins/openrouter/docs/OpenRouter_Documentation_Analysis.md
- Parse $ARGUMENTS for project path (default to current directory if not provided)
- Detect project type and framework:
  !{bash test -f package.json && echo "Node.js project" || echo "No package.json"}
  !{bash test -f requirements.txt && echo "Python project" || echo "No requirements.txt"}
  !{bash test -f pyproject.toml && echo "Python project (Poetry)" || echo "No pyproject.toml"}
- Check if OpenRouter is already configured:
  !{bash grep -q "OPENROUTER_API_KEY" .env 2>/dev/null && echo "Found existing config" || echo "No config found"}

Phase 2: Gather Requirements
Goal: Ask user for configuration preferences

Actions:
- Use AskUserQuestion to gather:
  1. Which language/framework integration?
     - TypeScript (Vercel AI SDK, OpenAI SDK)
     - Python (OpenAI SDK, LangChain, PydanticAI)
     - JavaScript (OpenAI SDK)
  2. Primary use case?
     - Chat/streaming applications
     - Model routing and cost optimization
     - Framework integration (which one?)
     - MCP server development
  3. Do you have an OpenRouter API key?
     - Yes (I'll provide it)
     - No (guide me to get one)
  4. Which models do you plan to use?
     - OpenAI models (GPT-4, GPT-3.5)
     - Anthropic models (Claude 3.5 Sonnet, etc.)
     - Google models (Gemini)
     - All/Multiple providers (intelligent routing)

Phase 3: Implementation
Goal: Configure OpenRouter SDK with proper setup

Actions:

Task(description="Setup OpenRouter SDK", subagent_type="openrouter-setup-agent", prompt="You are the openrouter-setup-agent. Initialize OpenRouter SDK for $ARGUMENTS.

Context from Phase 1:
- Project type detected (Node.js/Python/etc.)
- Existing configuration status
- OpenRouter documentation loaded

User Requirements from Phase 2:
- Language/framework choice
- Primary use case
- API key availability
- Model preferences

Tasks:
1. Install appropriate dependencies:
   - TypeScript: npm install openai @openrouter/ai-sdk-provider (if using Vercel AI SDK)
   - Python: pip install openai (for OpenAI SDK compatibility)
   - Additional: langchain, pydantic-ai if selected

2. Create/update .env file with:
   - OPENROUTER_API_KEY=your-api-key-here
   - OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
   - Add to .gitignore if not already there

3. Create framework-specific setup file:
   - TypeScript: src/lib/openrouter.ts with client configuration
   - Python: src/openrouter_client.py with client setup
   - Include examples for chosen use case

4. Generate example usage file:
   - Chat streaming example if selected
   - Model routing example if selected
   - Framework integration example (Vercel AI SDK, LangChain, etc.)

5. Create README section with:
   - Getting API key instructions (https://openrouter.ai/keys)
   - Configuration guide
   - Example usage
   - Links to OpenRouter docs

WebFetch URLs for latest documentation:
- https://openrouter.ai/docs/quickstart
- https://openrouter.ai/docs/api-reference/overview
- Framework-specific docs based on user selection

Deliverable: Fully configured OpenRouter SDK with working examples and documentation")

Phase 4: Verification
Goal: Ensure setup is working

Actions:
- Check that .env file was created:
  !{bash test -f .env && echo "✅ .env created" || echo "❌ .env missing"}
- Verify dependencies installed:
  !{bash test -f package.json && npm list openai 2>/dev/null || echo "TypeScript check skipped"}
  !{bash test -f requirements.txt && pip list | grep openai || echo "Python check skipped"}
- Check if .gitignore includes .env:
  !{bash grep -q "^\.env$" .gitignore 2>/dev/null && echo "✅ .env in .gitignore" || echo "⚠️ Add .env to .gitignore"}

Phase 5: Summary
Goal: Provide user with next steps

Actions:
- Display setup summary:
  - ✅ Dependencies installed
  - ✅ Environment configured
  - ✅ Example files created
  - ✅ Documentation added

- Next steps:
  1. Add your OpenRouter API key to .env file
  2. Get API key at: https://openrouter.ai/keys
  3. Test the setup with provided examples
  4. Explore model routing and cost optimization features
  5. Run example: [provide specific command based on framework]

- Useful resources:
  - OpenRouter Documentation: https://openrouter.ai/docs
  - Model Browser: https://openrouter.ai/models
  - Request Builder: https://openrouter.ai/request-builder
  - Pricing: https://openrouter.ai/pricing
