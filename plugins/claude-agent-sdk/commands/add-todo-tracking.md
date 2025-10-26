---
description: Add todo list tracking to Claude Agent SDK application
argument-hint: [project-path]
allowed-tools: Task(*), Read(*), Write(*), Bash(*), Glob(*), Grep(*), AskUserQuestion(*)
---

**Arguments**: $ARGUMENTS

Goal: Add todo list tracking and task management to an existing Claude Agent SDK application

Core Principles:
- Understand existing code before modifying
- Load SDK documentation for todo tracking patterns
- Follow official SDK examples

Phase 1: Discovery
Goal: Gather context about the project

Actions:
- Load SDK todo tracking documentation:
  @plugins/domain-plugin-builder/docs/sdks/claude-agent-sdk-documentation.md
- Check if project path provided in $ARGUMENTS
- Read package.json or requirements.txt to confirm SDK is installed
- Identify main application files

Phase 2: Analysis
Goal: Understand current implementation

Actions:
- Read main application files
- Check if todo tracking is already implemented
- Identify query() function configuration
- Determine language (TypeScript or Python)

Phase 3: Planning
Goal: Design todo tracking implementation

Actions:
- Determine todo list structure and schema
- Plan task management functions
- Plan persistence strategy
- Identify files to modify
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Add todo tracking with agent

Actions:

Invoke the claude-agent-features agent to add todo tracking.

The agent should:
- Fetch todo tracking documentation: https://docs.claude.com/en/api/agent-sdk/todo-tracking
- Implement todo list management
- Add task creation and update functions
- Configure todo persistence
- Add todo query and filtering capabilities

Provide the agent with:
- Context: Project language and structure
- Target: $ARGUMENTS (project path)
- Expected output: Updated files with todo tracking

Phase 5: Review
Goal: Verify todo tracking works correctly

Actions:
- Invoke appropriate verifier agent:
  - TypeScript: claude-agent-verifier-ts
  - Python: claude-agent-verifier-py
- Check that todo tracking patterns match SDK documentation
- Verify todo operations work properly

Phase 6: Summary
Goal: Document what was added

Actions:
- Summarize todo tracking capabilities added
- Show example todo list usage
- Link to SDK todo tracking documentation
- Suggest testing with task management operations
