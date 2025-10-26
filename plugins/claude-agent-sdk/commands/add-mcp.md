---
description: Integrate MCP server capabilities into Claude Agent SDK project
argument-hint: [mcp-server-name]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Integrate Model Context Protocol (MCP) server capabilities into your Claude Agent SDK application.

## Step 1: Verify SDK Project

Check for Agent SDK installation. Direct to `/claude-agent-sdk:new-app` if needed.

## Step 2: Fetch MCP Documentation

Use Context7 to fetch "mcp" topic documentation from Agent SDK.

## Step 3: Determine MCP Integration Type

Ask user:
1. "Do you want to use an existing MCP server or create a custom one?"
2. "Which MCP server(s) do you want to integrate?" (filesystem, github, database, custom)
3. "What resources/tools should the MCP server provide?"

## Step 4: Configure MCP Server

**For Existing MCP Server:**
- Add MCP server to .mcp.json configuration
- Install MCP server package if needed
- Configure server parameters

**For Custom MCP Server:**
- Use createSdkMcpServer() to build custom server
- Define resources and tools
- Implement server logic
- Register server with SDK

## Step 5: Integrate MCP with Agent

- Update agent configuration to use MCP tools
- Add MCP resource providers
- Configure prompt templates if applicable
- Test MCP integration

## Step 6: Add Examples and Documentation

Create examples showing:
- MCP server configuration
- Using MCP tools in agent
- Accessing MCP resources
- Custom MCP server creation

Update README with MCP integration guide.
