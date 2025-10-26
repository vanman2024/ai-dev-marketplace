---
description: Migrate existing application to Claude Agent SDK or upgrade SDK versions
argument-hint: [migration-type]
allowed-tools: Read(*), Write(*), Edit(*), Bash(*), Glob(*), Grep(*), Task(*), AskUserQuestion(*), mcp__context7__resolve-library-id(*), mcp__context7__get-library-docs(*)
---

Migrate your existing application to Claude Agent SDK or upgrade between SDK versions.

## Step 1: Analyze Current State

Detect what exists:
- Check for direct Claude API usage
- Look for other agent framework dependencies
- Identify current SDK version if applicable

## Step 2: Determine Migration Type

Ask user:
1. "What are you migrating from?" (Direct Claude API, other framework, old SDK version)
2. "Do you need gradual migration or complete rewrite?"
3. "What's your timeline and risk tolerance?"
4. "Are there specific SDK features you want to adopt?"

## Step 3: Invoke Migration Agent

Invoke the claude-agent-migration-agent to handle the migration.

The agent will:
- Fetch SDK migration documentation
- Analyze existing codebase
- Create detailed migration plan
- Update dependencies
- Transform code to SDK patterns
- Refactor to use SDK features
- Run tests and validation
- Document changes
- Provide rollback procedures

## Step 4: Validate Migration

After migration agent completes:
- Run comprehensive tests
- Verify functionality parity
- Check for performance regressions
- Review migration documentation
- Confirm rollback capability

Inform user that migration is complete with detailed changelog and updated documentation.
