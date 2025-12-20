---
description: Add A2A client to communicate with agents
argument-hint: <client-name> [target-agent-url]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Configure and add an A2A protocol client to enable communication with remote agents

Core Principles:
- Detect project structure before generating client code
- Ask for missing configuration details
- Follow A2A protocol specification standards
- Generate type-safe client implementations

Phase 1: Discovery
Goal: Understand project context and gather requirements

Actions:
- Parse $ARGUMENTS to extract client name and optional target agent URL
- Detect project type and language
- Example: !{bash ls package.json pyproject.toml go.mod 2>/dev/null | head -1}
- Load existing A2A configuration if present
- Example: @a2a-config.json or @.a2a/config.json

Phase 2: Requirements Gathering
Goal: Collect necessary configuration details

Actions:
- If target agent URL not provided in $ARGUMENTS, use AskUserQuestion to gather:
  - What is the target agent's URL or endpoint?
  - What authentication method should be used? (bearer token, API key, OAuth)
  - Which A2A protocol version? (default: latest)
  - Any specific capabilities required?
- Validate URL format if provided
- Confirm configuration with user before proceeding

Phase 3: Planning
Goal: Design the client implementation approach

Actions:
- Determine language-specific client structure
- Identify configuration files that need creation/update
- Plan authentication setup
- Outline integration points in existing codebase

Phase 4: Implementation
Goal: Generate A2A client code and configuration

Actions:

Task(description="Build A2A protocol client", subagent_type="a2a-client-builder", prompt="You are the a2a-client-builder agent. Create an A2A protocol client for $ARGUMENTS.

Context: Building client to communicate with remote agents following A2A protocol specification

Requirements:
- Generate type-safe client code for detected language
- Implement proper authentication handling
- Include error handling and retry logic
- Add configuration file for client settings
- Follow A2A protocol standards for message formatting
- Include usage examples and documentation

Configuration Details:
- Client name: [from $ARGUMENTS]
- Target agent URL: [from Phase 2]
- Authentication: [from Phase 2]
- Protocol version: [from Phase 2]
- Project type: [from Phase 1]

Expected output: Complete client implementation with config files and usage documentation")

Phase 5: Verification
Goal: Validate the generated client

Actions:
- Check that all client files were created
- Verify configuration file syntax
- Run type checking if applicable
- Example: !{bash npm run typecheck 2>/dev/null || python -m mypy . 2>/dev/null || go vet ./... 2>/dev/null}
- Test client connection if possible

Phase 6: Summary
Goal: Report implementation results and next steps

Actions:
- Summarize files created:
  - Client implementation file(s)
  - Configuration file
  - Type definitions (if applicable)
  - Documentation/examples
- Show sample usage code
- Provide next steps:
  - How to configure authentication credentials
  - How to test the client connection
  - Where to find usage examples
  - Link to A2A protocol documentation
