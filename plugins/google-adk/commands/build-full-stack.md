---
description: Complete Google ADK project setup - initializes project, adds agents/tools/streaming/A2A/observability/evaluation, validates, and deploys everything in one command
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Complete end-to-end Google ADK project setup from initialization through deployment

Core Principles:
- Execute sequentially - wait for each command to complete before proceeding
- Track progress with TodoWrite
- Validate at checkpoints
- Each phase builds on previous output

Phase 1: Initialize Progress Tracking
Goal: Create todo list for all workflow phases

Actions:

TodoWrite with todos:
1. "Initialize Google ADK project" (pending)
2. "Add agents (LLM/custom/workflow)" (pending)
3. "Integrate Gemini API and Google Cloud tools" (pending)
4. "Configure bidirectional streaming" (pending)
5. "Set up A2A protocol" (pending)
6. "Add observability (logging/tracing/analytics)" (pending)
7. "Configure evaluation and testing" (pending)
8. "Deploy to cloud (Vertex AI/Cloud Run/GKE)" (pending)

Phase 2: Sequential Command Execution
Goal: Execute all setup commands in order

Actions:

Mark todo #1 as in_progress.
Run /google-adk:init $ARGUMENTS
WAIT for completion.
!{bash test -f pyproject.toml || test -f package.json}
Mark todo #1 as completed.

Mark todo #2 as in_progress.
Run /google-adk:add-agent
WAIT for completion.
Mark todo #2 as completed.

Mark todo #3 as in_progress.
Run /google-adk:add-tools
WAIT for completion.
Mark todo #3 as completed.

Mark todo #4 as in_progress.
Run /google-adk:add-streaming
WAIT for completion.
Mark todo #4 as completed.

Mark todo #5 as in_progress.
Run /google-adk:add-a2a
WAIT for completion.
Mark todo #5 as completed.

Mark todo #6 as in_progress.
Run /google-adk:add-observability
WAIT for completion.
Mark todo #6 as completed.

Mark todo #7 as in_progress.
Run /google-adk:add-evaluation
WAIT for completion.
Mark todo #7 as completed.

Mark todo #8 as in_progress.
Run /google-adk:deploy
WAIT for completion.
Mark todo #8 as completed.

Phase 3: Summary
Goal: Display comprehensive setup summary

Actions:

Display summary:

**Google ADK Full Stack Setup Complete**

Components Configured:
- Project initialized with Google ADK SDK
- Agents: LLM agents, custom agents, workflow agents
- Tools: Gemini API, Google Cloud tools integrated
- Streaming: Bidirectional streaming configured
- A2A Protocol: Agent-to-Agent communication enabled
- Observability: Logging, tracing, analytics active
- Evaluation: Testing and metrics configured
- Deployment: Live on Vertex AI/Cloud Run/GKE

Next Steps:
1. Test agent interactions
2. Monitor observability dashboards
3. Run evaluation test suite
4. Access deployment endpoints

Mark all todos as completed.
