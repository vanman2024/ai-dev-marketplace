---
description: Add plugin system to Claude Agent SDK application
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

Goal: Add plugin system and plugin definitions to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for plugin patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK plugins documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files
- Ask user what plugins to add

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if plugins are already configured
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design plugin system

Actions:
- Define plugin structure and capabilities
- Plan plugin loading mechanism
- Determine plugin registration patterns
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add plugins with agent

Actions:

Invoke the claude-agent-features agent to add plugins.

The agent should:
- Fetch plugins documentation: https://docs.claude.com/en/api/agent-sdk/plugins
- Create plugin definitions
- Implement plugin loading system
- Add plugin registration in query() calls
- Add proper error handling for plugins

Provide the agent with:
- Context: Project language, structure, and desired plugins
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with plugin system

Phase 5: Review
Goal: Verify plugins work correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that plugin patterns match SDK documentation
- Verify plugins can be loaded and used properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize plugin capabilities added
- Show example plugin usage
- Link to SDK plugins documentation
- Suggest testing with plugin loading
