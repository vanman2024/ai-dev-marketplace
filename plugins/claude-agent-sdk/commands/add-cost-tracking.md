---
description: Add cost and usage tracking to Claude Agent SDK application
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

Goal: Add cost tracking and usage monitoring to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for cost tracking patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK cost tracking documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if cost tracking is already implemented
- Identify query() function calls
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design cost tracking implementation

Actions:
- Determine what metrics to track (tokens, costs, requests)
- Plan storage strategy for usage data
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add cost tracking with agent

Actions:

Invoke the claude-agent-features agent to add cost tracking.

The agent should:
- Fetch cost tracking documentation: https://docs.claude.com/en/api/agent-sdk/cost-tracking
- Implement usage tracking in query() calls
- Add cost calculation logic
- Implement usage data storage
- Add reporting and analytics functions

Provide the agent with:
- Context: Project language and structure
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with cost tracking

Phase 5: Review
Goal: Verify cost tracking works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that cost tracking patterns match SDK documentation
- Verify usage data is captured properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize cost tracking capabilities added
- Show example usage data access
- Link to SDK cost tracking documentation
- Suggest testing with usage monitoring
