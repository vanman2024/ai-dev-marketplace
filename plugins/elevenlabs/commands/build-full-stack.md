---
description: Orchestrate complete ElevenLabs integration by chaining all feature commands for production-ready voice application
argument-hint: [app-name]
allowed-tools: SlashCommand, Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, TodoWrite
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

Goal: Build a complete, production-ready voice-enabled application by orchestrating all ElevenLabs feature commands in the optimal sequence.

Core Principles:
- Orchestrate via SlashCommands (not direct agent calls)
- Track progress with TodoWrite
- Get user confirmation before major steps
- Build incrementally: setup → features → production
- Provide comprehensive final summary

Phase 1: Discovery
Goal: Understand application requirements

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for application name
- If no name provided, ask: "What would you like to name your voice application?"
- Detect current project structure:
  !{bash ls package.json pyproject.toml 2>/dev/null}

Phase 2: Requirements Gathering
Goal: Clarify full stack scope

Actions:
- Use AskUserQuestion to gather comprehensive requirements:
  - Application type? (Voice chat, Transcription service, Voice agent, Multi-modal app)
  - Core features needed? (TTS, STT, Voice cloning, Agents, Streaming)
  - Framework? (Auto-detect or confirm: Next.js, Python/FastAPI, etc.)
  - Vercel AI SDK integration? (Recommended for Next.js)
  - MCP integration for agents? (If building voice agents)
  - Advanced features? (Sound effects, dubbing, voice changer, isolator)
  - Deployment target? (Vercel, AWS, self-hosted)
- Confirm selections with user before proceeding

Phase 3: Planning
Goal: Design orchestration sequence

Actions:
- Based on requirements, plan command sequence:
  1. /elevenlabs:init (always first - setup and auth)
  2. Feature commands (based on selections):
     - /elevenlabs:add-text-to-speech (if TTS needed)
     - /elevenlabs:add-speech-to-text (if STT needed)
     - /elevenlabs:add-vercel-ai-sdk (if Next.js + AI workflows)
     - /elevenlabs:add-voice-management (if voice cloning needed)
     - /elevenlabs:add-agents-platform (if voice agents + MCP needed)
     - /elevenlabs:add-streaming (if real-time needed)
     - /elevenlabs:add-advanced-features (if sound effects/dubbing needed)
  3. /elevenlabs:add-production (always last - production hardening)
- Present complete plan with estimated time
- Get user approval before executing

Phase 4: Sequential Execution
Goal: Execute all commands in sequence

Actions:

**DO NOT START WITHOUT USER APPROVAL**

Execute the following SlashCommands sequentially:

**Step 1: Initialize**
SlashCommand: /elevenlabs:init $ARGUMENTS

Wait for completion, verify setup successful.
Update todos: mark init complete

**Step 2: Core Features** (based on user selections)

If TTS selected:
SlashCommand: /elevenlabs:add-text-to-speech

Update todos: mark TTS complete

If STT selected:
SlashCommand: /elevenlabs:add-speech-to-text

Update todos: mark STT complete

If Vercel AI SDK selected:
SlashCommand: /elevenlabs:add-vercel-ai-sdk

Update todos: mark Vercel AI SDK complete

**Step 3: Advanced Features** (based on user selections)

If voice cloning selected:
SlashCommand: /elevenlabs:add-voice-management

Update todos: mark voice management complete

If agents platform selected:
SlashCommand: /elevenlabs:add-agents-platform

Update todos: mark agents platform complete

If streaming selected:
SlashCommand: /elevenlabs:add-streaming

Update todos: mark streaming complete

If advanced features selected:
SlashCommand: /elevenlabs:add-advanced-features

Update todos: mark advanced features complete

**Step 4: Production Hardening** (always execute)
SlashCommand: /elevenlabs:add-production

Update todos: mark production complete

Phase 5: Verification
Goal: Verify complete application

Actions:
- Run comprehensive checks:
  - SDK installed: !{bash npm list @elevenlabs/elevenlabs-js 2>/dev/null || pip show elevenlabs 2>/dev/null}
  - TypeScript/Python checks: !{bash npx tsc --noEmit 2>/dev/null || python -m py_compile *.py 2>/dev/null}
  - Environment variables configured
  - All requested features implemented
- Mark all todos complete
- Report any issues found

Phase 6: Final Summary
Goal: Provide comprehensive application overview

Actions:
- Display complete summary:
  **Application: $ARGUMENTS**
  **Framework: [detected]**
  **Features Implemented:**
  - ✅ Authentication and SDK setup
  - ✅ [List of all implemented features]
  - ✅ Production hardening (rate limiting, monitoring, security)

  **Files Created:** [comprehensive list]

  **Configuration:**
  - API Key: Set in .env file
  - Models: [list of models configured]
  - Features: [summary of capabilities]

  **Getting Started:**
  1. Add your ElevenLabs API key to .env:
     ELEVENLABS_API_KEY=your_key_here
  2. Run the application: [framework-specific command]
  3. Test features: [quick test steps]

  **Next Steps:**
  - Test with real users
  - Monitor usage and costs
  - Scale as needed
  - Deploy to production: [deployment guide]

  **Documentation:**
  - ElevenLabs Docs: https://elevenlabs.io/docs
  - Vercel AI SDK: https://ai-sdk.dev
  - MCP Integration: https://elevenlabs.io/docs/agents-platform/customization/tools/mcp

  **Total Build Time:** [elapsed time]
  **Commands Executed:** [count]

- Congratulate user on complete voice-enabled application!
