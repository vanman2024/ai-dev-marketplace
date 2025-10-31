---
description: Add streaming capabilities to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add streaming vs single-mode capabilities to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for streaming patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK streaming documentation:
  @plugins/domain-plugin-builder/docs/sdks/claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- If not provided, use current directory
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if streaming is already implemented
- Identify query() function calls
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design streaming implementation

Actions:
- Determine which streaming mode to add
- Plan code changes needed
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add streaming capability with agent

Actions:

Invoke the claude-agent-features agent to add streaming.

The agent should:
- Fetch streaming documentation: https://docs.claude.com/en/api/agent-sdk/streaming-vs-single-mode
- Update query() calls to support streaming
- Add proper async iteration handling
- Implement streaming response processing
- Add error handling for stream interruptions

Provide the agent with:
- Context: Project language and structure
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with streaming support

Phase 5: Review
Goal: Verify streaming works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that streaming patterns match SDK documentation
- Verify async iteration is properly implemented

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize streaming capabilities added
- Show example usage
- Link to SDK streaming documentation
- Suggest testing with actual prompts
