---
description: Add Claude Memory Tool integration to Claude Agent SDK application for persistent memory across sessions and query caching
argument-hint: [project-path]
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

Goal: Add Claude Memory Tool integration to enable persistent memory storage across agent sessions

The Memory Tool enables Claude to:
- Store and retrieve information in `/memories` directory
- Remember user preferences, patterns, and context
- Build knowledge over time without keeping everything in context
- Cache search queries and generated code patterns
- Maintain session state across restarts

Core Principles:
- Memory operations are file-based (client-controlled)
- Claude automatically checks memory before tasks
- Memory survives context window resets
- You control storage location and security

## Phase 1: Discovery

Goal: Gather context about the project

Actions:
- Check if project path provided in $ARGUMENTS
- Read package.json (TypeScript) or requirements.txt (Python) to confirm SDK is installed
- Identify main application files
- Check current model version (Memory Tool requires Claude Sonnet 4.5+)
- Verify if `/memories` directory already exists

## Phase 2: Analysis

Goal: Understand current implementation

Actions:
- Read main application files
- Check if Memory Tool is already configured
- Identify query() function configuration
- Determine language (TypeScript or Python)
- Check if beta features are enabled
- Ask user:
  1. What type of memory to store (user preferences, search patterns, learned context)?
  2. Memory directory location (default: ./memories)
  3. What information should persist across sessions?
  4. Any sensitive data to exclude from memory?

## Phase 3: Planning

Goal: Design Memory Tool integration

Actions:
- Plan memory directory structure
- Identify memory operations needed (view, create, update, delete)
- Determine what types of information to store:
  - User preferences
  - Search query patterns
  - Generated code caching
  - Session context
  - Learned patterns
- Plan files to modify
- Present plan to user for confirmation

## Phase 4: Implementation

Goal: Add Memory Tool with agent

Actions:

Invoke the claude-agent-features agent to add Memory Tool integration.

Provide the agent with:
- Project path from $ARGUMENTS
- Language detected (TypeScript or Python)
- Memory directory location
- Types of information to persist
- User answers from Phase 2

The agent should:
- Enable Memory Tool beta feature (`context-management-2025-06-27`)
- Configure memory directory (default: ./memories)
- Implement memory handlers (view, create, update, delete)
- Add system prompt explaining memory usage to Claude
- Create initial memory structure:
  - user_preferences.json
  - search_patterns.json
  - session_context.json
- Add security (.gitignore for memories/, path validation)
- Upgrade to Sonnet 4.5+ if needed
- Configure appropriate betaMemoryTool (TypeScript) or BetaAbstractMemoryTool (Python)

## Phase 5: Review

Goal: Verify Memory Tool works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Verify beta header is enabled
- Check model is Sonnet 4.5+
- Test memory operations:
  - Create a memory file
  - Read memory file
  - Update memory file
  - Delete memory file
- Verify memory persists across sessions (restart and check)
- Check security (memories/ in .gitignore, path validation)
- Test with query caching use case

## Phase 6: Summary

Goal: Document what was added

Actions:
- Summarize Memory Tool capabilities:
  - Persistent storage location (./memories)
  - Memory operations available (view, create, update, delete)
  - Default memory files created
  - Security measures implemented
- Show example: Claude automatically checks /memories/search_patterns.json before generating code, reuses cached patterns if available, updates usage stats
- Explain memory structure:
  - `user_preferences.json` - User settings
  - `search_patterns.json` - Cached queries
  - `session_context.json` - Session state
  - `learned_patterns/` - Learning over time
- Document benefits:
  - Persistent memory across sessions
  - Automatic query caching
  - Context survives restarts
  - Reduced token costs
- Provide testing steps:
  1. Run agent with a search query
  2. Check memories/ directory for created files
  3. Run same query again - verify cache hit
  4. Restart application - verify memory persists
- Link to Memory Tool documentation:
  https://docs.claude.com/en/docs/agents-and-tools/tool-use/memory-tool
