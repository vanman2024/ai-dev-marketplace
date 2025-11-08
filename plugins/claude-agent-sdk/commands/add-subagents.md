---
description: Add subagents to Claude Agent SDK application
argument-hint: [project-path]
---
## Available Skills

This commands has access to the following skills from the claude-agent-sdk plugin:

- **fastmcp-integration**: Examples and patterns for integrating FastMCP Cloud servers with Claude Agent SDK using HTTP transport
- **sdk-config-validator**: Validates Claude Agent SDK configuration files, environment setup, dependencies, and project structure

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

Goal: Add subagent definitions to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for subagent patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK subagents documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files
- Ask user what subagents to add

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if subagents are already defined
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design subagents

Actions:
- Define subagent roles and responsibilities
- Plan subagent system prompts
- Determine subagent tool permissions
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add subagents with agent

Actions:

Invoke the claude-agent-features agent to add subagents.

The agent should:
- Fetch subagents documentation: https://docs.claude.com/en/api/agent-sdk/subagents
- Create subagent definitions with names and descriptions
- Configure subagent system prompts
- Set subagent tool permissions
- Add subagent invocation handling

Provide the agent with:
- Context: Project language, structure, and desired subagents
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with subagent definitions

Phase 5: Review
Goal: Verify subagents work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that subagent definitions are valid
- Verify subagents can be invoked properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize subagents added
- Show example subagent usage
- Link to SDK subagents documentation
- Suggest testing with subagent delegation
