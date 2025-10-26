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
- SlashCommand: /fastmcp:new-server $ARGUMENTS
- Wait for server creation to complete
- Verify server directory exists
- Update todos

Phase 3: Add MCP Components
Goal: Add tools, resources, prompts, and/or middleware

Actions:
- If any components requested (tools, resources, prompts, middleware):
  - SlashCommand: /fastmcp:add-components
  - Wait for completion (command handles multiple component types)
- Update todos

Phase 4: Add Authentication
Goal: Configure authentication if requested

Actions:
- If authentication requested:
  - SlashCommand: /fastmcp:add-auth
  - Wait for completion (command handles all auth types: OAuth providers, JWT, Bearer)
- Update todos

Phase 5: Configure Deployment
Goal: Set up deployment transport

Actions:
- SlashCommand: /fastmcp:add-deployment
- Wait for completion (command handles HTTP, STDIO, and Cloud)
- Update todos

Phase 6: Add Integrations
Goal: Configure integrations if requested

Actions:
- If integrations requested:
  - SlashCommand: /fastmcp:add-integration
  - Wait for completion (command handles FastAPI, OpenAPI, LLM platforms, IDEs, authorization)
- Update todos

Phase 7: Final Verification
Goal: Verify complete server works

Actions:
- Run Python syntax check on server
- Verify all dependencies installed
- Test server starts without errors
- Run basic functionality tests
- Update todos

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
