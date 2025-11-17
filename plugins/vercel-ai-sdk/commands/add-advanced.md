---
description: Add advanced features to Vercel AI SDK app including AI agents with workflows, MCP tools, image generation, transcription, and speech synthesis
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

Goal: Add cutting-edge AI capabilities to a Vercel AI SDK application including autonomous agents with workflows, MCP tools integration, image generation, audio transcription, speech synthesis, and multi-step reasoning.

Core Principles:
- Understand use case complexity before designing agent workflows
- Ask about tool requirements and MCP server availability
- Follow Vercel AI SDK documentation patterns
- Implement safeguards for autonomous agents (loop control, cost limits)

Phase 1: Discovery
Goal: Understand what advanced features are needed

Actions:
- Parse $ARGUMENTS to identify requested features
- If unclear or no arguments provided, use AskUserQuestion to gather:
  - Which advanced features do you want? (AI agents, MCP tools, image generation, transcription, speech)
  - What problem should the agent solve?
  - Do you have MCP servers configured?
  - What's your expected volume for image/audio generation?
- Load package.json to understand current setup
- Example: @package.json

Phase 2: Analysis
Goal: Understand current project state

Actions:
- Check for existing AI SDK installation and tools
- Identify infrastructure needs (storage for images/audio)
- Review MCP server configuration if applicable
- Assess security requirements for agent autonomy
- Example: !{bash ls .mcp.json 2>/dev/null && echo "MCP configured" || echo "No MCP config"}

Phase 3: Implementation
Goal: Add advanced features using specialized agent

Actions:

Invoke the vercel-ai-advanced-agent to implement the requested advanced features.

The agent should:
- Fetch relevant Vercel AI SDK documentation for the requested features
- Design agent architecture and workflow
- Install required packages (MCP clients, image providers, audio libraries)
- Implement requested features following SDK best practices:
  - AI agents with multi-step reasoning and tool calling
  - Workflow orchestration with loop control
  - MCP tools integration (if applicable)
  - Image generation using OpenAI DALL-E or Fal AI
  - Audio transcription using Whisper
  - Text-to-speech synthesis
- Add proper TypeScript types
- Implement loop controls and cost safeguards
- Set up storage for generated content

Provide the agent with:
- Context: Current project structure and infrastructure
- Target: $ARGUMENTS (requested advanced features)
- Expected output: Production-ready advanced AI features with safeguards

Phase 4: Verification
Goal: Ensure features work correctly

Actions:
- Run TypeScript compilation check
- Example: !{bash npx tsc --noEmit}
- Test agent workflows with various scenarios
- Verify tool calling and MCP integration (if applicable)
- Test image/audio generation
- Check loop controls and cost limits

Phase 5: Summary
Goal: Document advanced features

Actions:
- List all advanced features implemented
- Show agent workflows and tool definitions
- Note API keys and environment variables needed
- Provide cost estimates for generation operations
- Suggest next steps (workflow optimization, monitoring, scaling)
