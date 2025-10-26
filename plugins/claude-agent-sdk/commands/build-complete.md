---
description: Build complete Claude Agent SDK application with all features
argument-hint: [project-name]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), SlashCommand(*), AskUserQuestion(*)
---

Build a complete Claude Agent SDK application with all features in one command.

## Overview

This command orchestrates all other claude-agent-sdk commands to create a fully-featured Agent SDK application with streaming, tools, sessions, MCP integration, advanced agent capabilities, and production-ready features.

## Step 1: Gather Overall Requirements

Ask user:
1. "What would you like to name your project?"
2. "Which language?" (TypeScript or Python)
3. "What type of agent are you building?" (coding, business, custom)
4. "Do you want all features or would you like to select specific ones?"

## Step 2: Create Base Application

Invoke slash command: `/claude-agent-sdk:new-app` with project name

Wait for completion before proceeding.

## Step 3: Add Core Features

Sequentially invoke:
1. `/claude-agent-sdk:add-streaming` - Add streaming capabilities
2. `/claude-agent-sdk:add-tools` - Add custom tools
3. `/claude-agent-sdk:add-sessions` - Add session management
4. `/claude-agent-sdk:add-mcp` - Add MCP integration

Wait for each to complete before next.

## Step 4: Add Advanced Features

Invoke:
1. `/claude-agent-sdk:add-agent-features` - Add subagents, skills, commands

Wait for completion.

## Step 5: Add Production Features

Invoke:
1. `/claude-agent-sdk:add-production` - Add cost tracking, monitoring, deployment setup

Wait for completion.

## Step 6: Final Summary

Provide user with complete summary:
- All features implemented
- Project structure overview
- How to run the application
- Next steps for customization
- Links to documentation

Congratulate user on building a complete Agent SDK application with all capabilities!
