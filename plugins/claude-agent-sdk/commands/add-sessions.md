---
description: Add session management to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add session management capabilities to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for session patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK session documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if sessions are already implemented
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design session implementation

Actions:
- Determine session storage approach
- Plan state management strategy
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add session management with agent

Actions:

Invoke the claude-agent-features agent to add sessions.

The agent should:
- Fetch session documentation: https://docs.claude.com/en/api/agent-sdk/sessions
- Implement session state management
- Add session persistence if needed
- Configure session options in query() calls
- Add session cleanup handling

Provide the agent with:
- Context: Project language and structure
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with session support

Phase 5: Review
Goal: Verify sessions work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that session patterns match SDK documentation
- Verify state persistence works

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize session capabilities added
- Show example usage
- Link to SDK session documentation
- Suggest testing with multi-turn conversations
