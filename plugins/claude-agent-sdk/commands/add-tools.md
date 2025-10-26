---
description: Add custom tool integration and permission management to Claude Agent SDK project
argument-hint: [tool-name]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add custom tools and permission management to your Claude Agent SDK application.

## Step 1: Verify SDK Project

Check for Agent SDK installation. If not found, direct user to run `/claude-agent-sdk:new-app` first.

## Step 2: Fetch Tools Documentation

Use Context7 MCP:
1. Resolve library ID for Claude Agent SDK
2. Fetch documentation for topics: "custom-tools" and "permissions"

## Step 3: Gather Requirements

Ask user:
1. "What type of tool do you want to add?" (filesystem, API calls, database, custom)
2. "What permissions should this tool have?" (read-only, read-write, admin)
3. "Will this tool use an MCP server or be custom code?"

## Step 4: Implement Tool

**If MCP Server:**
- Add MCP server to project configuration
- Configure tool permissions
- Add tool integration code

**If Custom Tool:**
- Create tool definition with schema
- Implement tool logic
- Add permission checks
- Register tool with SDK

## Step 5: Add Permission Management

Implement:
- Tool permission configuration
- Permission validation
- User consent handling (if needed)
- Permission documentation

## Step 6: Create Examples

Add example showing:
- Tool definition
- Tool usage in agent
- Permission handling
- Error scenarios

Update README with tool documentation and usage examples.
