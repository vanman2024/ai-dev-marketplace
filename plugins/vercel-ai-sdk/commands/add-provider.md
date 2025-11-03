---
description: Add another AI provider to existing Vercel AI SDK project
argument-hint: none
allowed-tools: WebFetch, Read, Write, Edit, Bash(*), AskUserQuestion, Skill
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
