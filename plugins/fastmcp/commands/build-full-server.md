---
description: Build a complete production-ready FastMCP server by orchestrating all feature commands based on requirements
argument-hint: <server-name>
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), SlashCommand(*), TodoWrite(*)
---

**Arguments**: $ARGUMENTS

Goal: Build a complete, production-ready FastMCP server from scratch by chaining all relevant feature commands based on user requirements.

Core Principles:
- Ask comprehensive questions upfront
- Chain slash commands sequentially
- Track progress with TodoWrite
- Build incrementally, validate at each step

Phase 1: Discovery
Goal: Understand complete server requirements

Actions:
- Create todo list with all phases using TodoWrite
- Parse $ARGUMENTS for server name
- Use AskUserQuestion to gather comprehensive requirements:
  - Server name and purpose
  - MCP components needed (tools, resources, prompts)
  - Authentication method (OAuth/JWT/Bearer/none)
  - Deployment target (STDIO/HTTP/Cloud)
  - Integrations needed (FastAPI/Claude Desktop)
- Load FastMCP documentation:
  @plugins/domain-plugin-builder/docs/sdks/fastmcp-documentation.md
- Present complete build plan to user for confirmation

Phase 2: Create Base Server
Goal: Initialize server project

Actions:
- Use SlashCommand tool to invoke: /fastmcp:new-server $ARGUMENTS
- The /fastmcp:new-server command will:
  - Load FastMCP documentation
  - Ask language preference (Python or TypeScript)
  - Invoke fastmcp-setup or fastmcp-setup-ts agent
  - Create complete project structure
- Wait for server creation to complete
- Verify server directory exists using Bash
- Update todos with TodoWrite

Phase 3: Add MCP Components
Goal: Add tools, resources, prompts, and/or middleware

Actions:
- If any components requested (tools, resources, prompts, middleware):
  - Use SlashCommand tool to invoke: /fastmcp:add-components [component-types]
  - The /fastmcp:add-components command will:
    - Load relevant FastMCP documentation for each component type
    - Read the existing server code
    - Add requested tools, resources, prompts, or middleware
    - Follow FastMCP SDK patterns and best practices
  - Wait for completion
- Update todos with TodoWrite

Phase 4: Add Authentication
Goal: Configure authentication if requested

Actions:
- If authentication requested:
  - Use SlashCommand tool to invoke: /fastmcp:add-auth [auth-type]
  - The /fastmcp:add-auth command will:
    - Load FastMCP authentication documentation
    - Read the existing server code
    - Add authentication provider (OAuth, JWT, Bearer)
    - Update environment configuration
    - Add security best practices
  - Wait for completion
- Update todos with TodoWrite

Phase 5: Configure Deployment
Goal: Set up deployment transport

Actions:
- Use SlashCommand tool to invoke: /fastmcp:add-deployment [deployment-type]
- The /fastmcp:add-deployment command will:
  - Load FastMCP deployment documentation
  - Configure transport (HTTP, STDIO, Cloud)
  - Set up server startup code
  - Add deployment configuration files
  - Update README with deployment instructions
- Wait for completion
- Update todos with TodoWrite

Phase 6: Add Integrations
Goal: Configure integrations if requested

Actions:
- If integrations requested:
  - Use SlashCommand tool to invoke: /fastmcp:add-integration [integration-type]
  - The /fastmcp:add-integration command will:
    - Load integration-specific documentation
    - Configure FastAPI/OpenAPI/LLM platform integration
    - Add necessary middleware or routes
    - Update configuration files
  - Wait for completion
- Update todos with TodoWrite

Phase 7: Final Verification
Goal: Verify complete server works

Actions:
- Invoke the appropriate verifier agent:
  - Python: Task tool with fastmcp:fastmcp-verifier-py
  - TypeScript: Task tool with fastmcp:fastmcp-verifier-ts
- The verifier agent will:
  - Check Python/TypeScript syntax
  - Verify all dependencies are installed
  - Test server starts without errors
  - Validate all tools/resources/prompts are accessible
  - Run basic functionality tests
  - Verify authentication is configured correctly
  - Test deployment configuration
- Update todos based on verification results

Phase 8: Summary
Goal: Present complete build results

Actions:
- Mark all todos complete
- Display comprehensive summary:
  - Server location and structure
  - Components added (tools, resources, prompts)
  - Authentication configured
  - Deployment method
  - Integrations enabled
  - Commands to run server
  - Testing instructions
  - Next steps for development
