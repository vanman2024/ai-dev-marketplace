---
description: Add permission handling to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion
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

Goal: Add permission handling capabilities to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for permission patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK permissions documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if permissions are already configured
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design permission implementation

Actions:
- Determine which tools need permission controls
- Plan permission configuration strategy
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add permissions with agent

Actions:

Invoke the claude-agent-features agent to add permissions.

The agent should:
- Fetch permissions documentation: https://docs.claude.com/en/api/agent-sdk/permissions
- Configure tool permission levels
- Add askBeforeToolUse configuration
- Implement permission callbacks if needed
- Add proper permission error handling

Provide the agent with:
- Context: Project language and structure
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with permission handling

Phase 5: Review
Goal: Verify permissions work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that permission patterns match SDK documentation
- Verify permission controls are properly enforced

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize permission capabilities added
- Show example usage
- Link to SDK permissions documentation
- Suggest testing with restricted tool access
