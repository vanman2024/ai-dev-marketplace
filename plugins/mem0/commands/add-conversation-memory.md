---
description: Add conversation memory tracking to existing chat/AI application
argument-hint: none
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, Skill
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

Goal: Integrate conversation memory tracking into existing application, automatically storing and retrieving conversation context.

Core Principles:
- Detect existing AI framework (Vercel AI SDK, LangChain, etc.)
- Add memory middleware/wrapper
- Minimal code changes required
- Automatic context retrieval

Phase 1: Framework Detection
Goal: Identify existing AI framework

Actions:
- Search for AI framework imports and usage:
  - Vercel AI SDK (streamText, generateText, useChat)
  - LangChain (ConversationalChain, ChatOpenAI)
  - CrewAI (Crew, Agent)
  - OpenAI Agents SDK (Agent, query)
- Locate AI route handlers or chat functions
- Check Mem0 is already initialized

Phase 2: Integration Planning
Goal: Determine where to add memory hooks

Actions:
- Identify chat entry points
- Find message handling logic
- Determine user/session identification method
- Plan memory retrieval and storage points

Phase 3: Implementation
Goal: Add conversation memory integration

Actions:

Launch the mem0-integrator agent to add conversation memory.

Provide the agent with:
- Framework: [Detected from Phase 1]
- Integration points: [Identified in Phase 2]
- Requirements:
  - Add memory retrieval before AI generation
  - Add memory storage after AI response
  - Include user_id and session_id tracking
  - Handle conversation context automatically
  - Add error handling for memory operations
  - Generate framework-specific integration code
- Expected output: Complete integration with conversation memory

Phase 4: Verification
Goal: Test conversation memory works

Actions:
- Test memory is stored after conversations
- Test memory is retrieved in next conversation
- Verify context improves AI responses
- Check user isolation works correctly

Phase 5: Summary
Goal: Show what was integrated

Actions:
- Display integration results:
  - Framework: [Name]
  - Files modified: [List]
  - Memory hooks added: [List]
- Show usage:
  - How conversation memory is stored
  - How context is retrieved automatically
  - How to customize memory behavior
- Provide next steps:
  - Test with multi-turn conversations
  - Customize memory filtering if needed
  - Use /mem0:add-user-memory for preferences
  - Use /mem0:configure for advanced settings
