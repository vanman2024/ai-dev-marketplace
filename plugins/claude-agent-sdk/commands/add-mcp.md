---
description: Add MCP integration to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion, Skill
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

Goal: Add Model Context Protocol (MCP) integration to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for MCP patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK MCP documentation:
  @claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if MCP is already configured
- Identify query() function configuration
- Determine language (TypeScript or Python)
- Ask user which MCP servers to integrate

Phase 3: Planning
Goal: Design MCP integration

Actions:
- Determine which MCP servers to add
- Plan MCP server configuration
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add MCP integration with agent

Actions:

INVOKE the fastmcp-integration skill to load MCP patterns:

!{skill fastmcp-integration}

This loads:
- Complete FastMCP Cloud HTTP configuration patterns
- Environment variable setup
- Error handling for connection failures
- Real-world examples with status checking
- Common pitfalls (SSE vs HTTP, missing API keys)

Then invoke the claude-agent-features agent to add MCP.

The agent should:
- Use patterns from fastmcp-integration skill
- Configure MCP server connections (HTTP for FastMCP Cloud!)
- Add MCP tool permissions
- Implement createSdkMcpServer() if creating custom MCP servers
- Add proper error handling for MCP connections
- Add FASTMCP_CLOUD_API_KEY to .env and .env.example

Provide the agent with:
- Context: Project language, structure, and desired MCP servers
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with MCP integration

Phase 5: Review
Goal: Verify MCP works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that MCP patterns match SDK documentation
- Verify MCP servers connect properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize MCP capabilities added
- Show example usage
- Link to SDK MCP documentation
- Suggest testing with MCP tool calls
