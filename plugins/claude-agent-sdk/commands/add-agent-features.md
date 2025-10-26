---
description: Add advanced agent capabilities bundle (subagents, slash commands, skills, system prompts)
argument-hint: [none]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), Task(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add advanced agent capabilities to your Claude Agent SDK project including subagents, slash commands, agent skills, and custom system prompts.

## Step 1: Verify SDK Project

Ensure Agent SDK is installed. Direct to `/claude-agent-sdk:new-app` if not found.

## Step 2: Gather Requirements

Ask user which features they need:
1. "Do you need specialized subagents for different tasks?"
2. "Should users be able to invoke custom slash commands?"
3. "Do you want autonomous agent skills?"
4. "Do you need to customize the system prompt for specific behaviors?"

## Step 3: Invoke Features Agent

Based on user's answers, invoke the claude-agent-features-agent to implement the requested capabilities.

The agent will:
- Fetch latest SDK documentation for each feature
- Implement subagent configurations
- Create slash command handlers
- Build agent skill definitions
- Customize system prompts
- Integrate all features with existing setup
- Add tests and documentation

## Step 4: Review Implementation

After the features agent completes:
- Review added functionality
- Test each new capability
- Verify integration with existing code
- Confirm documentation is complete

Inform user that advanced agent features have been successfully added with examples and usage documentation.
