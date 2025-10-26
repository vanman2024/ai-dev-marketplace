---
description: Add MCP integration to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

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
  @plugins/domain-plugin-builder/docs/sdks/claude-agent-sdk-documentation.md
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

Invoke the claude-agent-features agent to add MCP.

The agent should:
- Fetch MCP documentation: https://docs.claude.com/en/api/agent-sdk/mcp
- Configure MCP server connections
- Add MCP tool permissions
- Implement createSdkMcpServer() if creating custom MCP servers
- Add proper error handling for MCP connections

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
