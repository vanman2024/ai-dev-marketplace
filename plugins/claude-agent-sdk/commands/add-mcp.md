---
description: Add MCP integration to Claude Agent SDK application
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

Supports:
- Local STDIO MCP servers (e.g., Google Workspace MCPs running locally)
- Remote HTTP MCP servers (e.g., FastMCP Cloud hosted servers)

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for MCP patterns
- Follow official SDK examples
- Configure appropriate transport (STDIO for local, HTTP for remote)

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK MCP documentation:
  Read SDK documentation: ~/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/claude-agent-sdk/docs/sdk-documentation.md
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
- Ask user:
  1. Which MCP servers to integrate (name/purpose)
  2. Server type: Local STDIO or Remote HTTP/FastMCP Cloud
  3. If local: Path to MCP server directory
  4. If remote: FastMCP Cloud URL and whether API key is needed

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

FOR LOCAL STDIO MCP SERVERS:
Configure with STDIO transport (e.g., Google Workspace MCPs):

```typescript
// TypeScript example
mcp_servers: {
  "google-tasks": {
    type: "stdio",
    command: "node",
    args: ["/path/to/google-tasks/build/index.js"],
    env: {
      GOOGLE_APPLICATION_CREDENTIALS: process.env.GOOGLE_APPLICATION_CREDENTIALS
    }
  }
}
```

```python
# Python example
mcp_servers={
    "google-tasks": {
        "type": "stdio",
        "command": "node",
        "args": ["/path/to/google-tasks/build/index.js"],
        "env": {
            "GOOGLE_APPLICATION_CREDENTIALS": os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        }
    }
}
```

FOR REMOTE HTTP/FASTMCP CLOUD SERVERS:
INVOKE the fastmcp-integration skill to load HTTP patterns:

!{skill fastmcp-integration}

This loads:
- Complete FastMCP Cloud HTTP configuration patterns
- Environment variable setup
- Error handling for connection failures
- Real-world examples with status checking
- Common pitfalls (SSE vs HTTP, missing API keys)

Configure with HTTP transport:

```typescript
// TypeScript example
mcp_servers: {
  "your-server": {
    type: "http",
    url: "https://your-server.fastmcp.app/mcp",
    headers: {
      Authorization: `Bearer ${process.env.FASTMCP_CLOUD_API_KEY}`
    }
  }
}
```

Then invoke the claude-agent-features agent to add MCP.

The agent should:
- For LOCAL: Configure STDIO transport with command/args/env
- For REMOTE: Use patterns from fastmcp-integration skill with HTTP transport
- Add MCP tool permissions (allowed_tools)
- Implement createSdkMcpServer() if creating custom MCP servers
- Add proper error handling for MCP connections
- For STDIO: Add any required env vars to .env/.env.example
- For HTTP: Add FASTMCP_CLOUD_API_KEY to .env/.env.example

Provide the agent with:
- Context: Project language, structure, MCP server type (STDIO/HTTP), and paths/URLs
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with appropriate MCP transport configuration

Phase 5: Review
Goal: Verify MCP works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that MCP patterns match SDK documentation
- Verify MCP servers connect properly:
  - For STDIO: Verify command paths exist and are executable
  - For HTTP: Verify URL is accessible and API key is configured
- Test MCP tool calls work (list available tools from server)
- Check error handling for connection failures

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize MCP capabilities added:
  - Server name and type (STDIO/HTTP)
  - Available tools from the MCP server
  - Configuration location in code
- Show example usage for calling MCP tools
- Provide configuration details:
  - For STDIO: Command path, args, required env vars
  - For HTTP: URL, API key setup, headers
- Link to SDK MCP documentation
- Suggest testing with MCP tool calls
- Document any troubleshooting steps for connection issues
