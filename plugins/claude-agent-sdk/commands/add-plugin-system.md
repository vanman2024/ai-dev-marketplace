---
description: Add plugin development and management capabilities to Claude Agent SDK project
argument-hint: [plugin-name]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), Task(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add plugin development and management capabilities to your Claude Agent SDK project.

## Step 1: Verify SDK Project

Check for Agent SDK installation. Direct to `/claude-agent-sdk:new-app` if needed.

## Step 2: Gather Plugin Requirements

Ask user:
1. "What functionality should this plugin provide?"
2. "Will this plugin be shared or used privately?"
3. "What commands should the plugin include?"
4. "Does it need specialized agents or skills?"

## Step 3: Invoke Plugin Agent

Invoke the claude-agent-plugin-agent to build the plugin structure and components.

The agent will:
- Fetch SDK plugin documentation
- Create plugin directory structure
- Generate plugin.json manifest
- Implement commands and agents
- Add skills and hooks if needed
- Create documentation
- Set up distribution configuration

## Step 4: Test Plugin

After plugin agent completes:
- Test plugin loading
- Verify all commands work
- Validate agents execute correctly
- Check skills trigger appropriately
- Review documentation

Inform user that plugin has been created successfully with installation and usage instructions.
