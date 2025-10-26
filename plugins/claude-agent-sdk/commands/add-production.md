---
description: Add production-ready features (cost tracking, monitoring, error handling, hosting setup)
argument-hint: [none]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), Task(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Add production-ready features to your Claude Agent SDK application including cost tracking, monitoring, error handling, and hosting setup.

## Step 1: Verify SDK Project

Ensure Agent SDK is installed. Direct to `/claude-agent-sdk:new-app` if not found.

## Step 2: Gather Production Requirements

Ask user:
1. "What's your expected usage volume and budget?"
2. "Where will you host this application?" (AWS, GCP, Azure, Vercel, local server)
3. "Do you need real-time cost tracking or periodic reports?"
4. "What level of logging and monitoring do you need?"

## Step 3: Invoke Production Agent

Invoke the claude-agent-production-agent to implement production features.

The agent will:
- Fetch SDK documentation on cost tracking and hosting
- Implement token usage tracking
- Add cost calculation and reporting
- Set up structured logging
- Implement error handling and tracking
- Add performance monitoring
- Configure hosting environment
- Create deployment scripts
- Add health checks

## Step 4: Verify Production Setup

After production agent completes:
- Test cost tracking accuracy
- Verify logging captures all events
- Check error handling coverage
- Validate deployment process
- Review monitoring setup

Inform user that production features have been added with deployment documentation and monitoring guides.
