---
description: Add conversational AI agents with MCP integration, tool calling, and real-time voice conversations
argument-hint: [options]
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion, Skill
---
## Available Skills

This commands has access to the following skills from the elevenlabs plugin:

- **api-authentication**: API authentication patterns, SDK installation scripts, environment variable management, and connection testing for ElevenLabs. Use when setting up ElevenLabs authentication, installing ElevenLabs SDK, configuring API keys, testing ElevenLabs connection, or when user mentions ElevenLabs authentication, xi-api-key, ELEVENLABS_API_KEY, or ElevenLabs setup.\n- **mcp-integration**\n- **production-deployment**: Production deployment patterns for ElevenLabs API including rate limiting, error handling, monitoring, and testing. Use when deploying to production, implementing rate limiting, setting up monitoring, handling errors, testing concurrency, or when user mentions production deployment, rate limits, error handling, monitoring, ElevenLabs production.\n- **stt-integration**: ElevenLabs Speech-to-Text transcription workflows with Scribe v1 supporting 99 languages, speaker diarization, and Vercel AI SDK integration. Use when implementing audio transcription, building STT features, integrating speech-to-text, setting up Vercel AI SDK with ElevenLabs, or when user mentions transcription, STT, Scribe v1, audio-to-text, speaker diarization, or multi-language transcription.\n- **tts-integration**\n- **vercel-ai-patterns**\n- **voice-processing**: Voice cloning workflows, voice library management, audio format conversion, and voice settings. Use when cloning voices, managing voice libraries, processing audio for voice creation, configuring voice settings, or when user mentions voice cloning, instant cloning, professional cloning, voice library, audio processing, voice settings, or ElevenLabs voices.\n
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

Goal: Add ElevenLabs Agents Platform with full MCP integration, enabling conversational voice agents that can access external tools via Model Context Protocol.

Core Principles:
- Build conversational voice agents with natural dialogue
- Integrate MCP servers (Zapier, custom servers)
- Configure fine-grained security controls for tool access
- Support real-time WebSocket conversations
- Enable multi-turn voice dialogues

Phase 1: Discovery
Goal: Understand agents and MCP requirements

Actions:
- Load SDK documentation:
  @elevenlabs-documentation.md
- Load MCP examples:
  @docs/elevenlabs/docs/mcp-integration-examples.md
- Check setup: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || pip show elevenlabs 2>/dev/null}
- Detect framework: @package.json or @pyproject.toml
- Parse $ARGUMENTS for agent and MCP needs

Phase 2: Requirements Gathering
Goal: Clarify agent capabilities

Actions:
- Use AskUserQuestion if needed:
  - Agent purpose? (customer service, personal assistant, sales, etc.)
  - MCP servers? (Zapier, custom, none)
  - Tool approval mode? (always ask, fine-grained, auto-approve)
  - Real-time conversations? (WebSocket streaming)
  - Multi-agent system? (specialized agents for different tasks)

Phase 3: Planning
Goal: Design agents platform integration

Actions:
- Plan implementation:
  - Agent configuration: name, description, voice, model
  - MCP server setup: URLs, auth tokens, approval modes
  - Tool definitions: allowed, approval-required, disabled
  - WebSocket connection for real-time conversations
  - Conversation management: sessions, state, history
  - Security: tool approval workflow, user confirmation
- Present plan

Phase 4: Implementation
Goal: Build agents platform with MCP

Actions:

Launch the elevenlabs-agents-builder agent to implement conversational agents with MCP.

Provide detailed requirements:
- Context: Framework, SDK status, MCP needs
- Target: $ARGUMENTS
- Requirements:
  - Agent Configuration:
    * Create agent with voice_id and model selection
    * Set agent personality and instructions
    * Configure conversation parameters
  - MCP Integration (MAJOR FEATURE):
    * Configure MCP server URLs
    * Set authentication tokens (from environment)
    * Define tool approval modes:
      - always_ask: request permission for each tool
      - fine_grained: custom rules per tool
      - auto_approve: allow without asking (read-only tools)
      - disabled: block specific tools
    * Implement approval request handling
    * Examples: Zapier MCP (hundreds of tools), custom MCP servers
  - Real-time Conversations:
    * WebSocket connection setup
    * Multi-turn dialogue handling
    * Conversation state management
    * Voice streaming for agent responses
  - Tool Calling:
    * Define available tools from MCP
    * Handle tool execution requests
    * Process tool responses
    * Integrate results into conversation
  - Security:
    * Tool approval workflow UI
    * User confirmation for sensitive operations
    * Rate limiting for tool calls
    * Audit logging
  - Use progressive docs: fetch agents platform and MCP docs
- Expected output:
  - Agent configuration files/code
  - MCP server integration
  - WebSocket conversation client
  - Tool approval interface
  - Example conversations

Phase 5: Verification
Goal: Ensure agents work correctly

Actions:
- Verify files created
- Check syntax: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
- Verify MCP configuration
- Test WebSocket connection setup

Phase 6: Summary
Goal: Guide on using agents platform

Actions:
- Display summary:
  - Agent created: [name and purpose]
  - MCP servers configured: [list]
  - Tools available: [count]
  - Security mode: [approval configuration]
- Usage instructions:
  - Start conversation with agent
  - Agent can use MCP tools (with approval)
  - Multi-turn dialogue examples
  - Tool approval workflow
- Configuration:
  - MCP dashboard: https://elevenlabs.io/app/agents/integrations
  - Zapier MCP: https://zapier.com/mcp
  - Custom MCP servers
- Show code examples
- Next steps:
  - Add more MCP servers
  - Customize tool permissions
  - Build multi-agent systems
  - Production deploy: /elevenlabs:add-production
