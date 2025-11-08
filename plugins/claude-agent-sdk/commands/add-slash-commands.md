---
description: Add slash commands to Claude Agent SDK application
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

Goal: Add slash command definitions to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for slash command patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK slash commands documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files
- Ask user what slash commands to add

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if slash commands are already defined
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design slash commands

Actions:
- Define slash command names and purposes
- Plan command handlers and logic
- Determine command arguments if needed
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add slash commands with agent

Actions:

Invoke the claude-agent-features agent to add slash commands.

The agent should:
- Fetch slash commands documentation: https://docs.claude.com/en/api/agent-sdk/slash-commands
- Create slash command definitions
- Implement command handler functions
- Add command registration in query() calls
- Add proper error handling for commands

Provide the agent with:
- Context: Project language, structure, and desired commands
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with slash command definitions

Phase 5: Review
Goal: Verify slash commands work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that slash command patterns match SDK documentation
- Verify commands can be invoked properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize slash commands added
- Show example command usage
- Link to SDK slash commands documentation
- Suggest testing with command invocations
