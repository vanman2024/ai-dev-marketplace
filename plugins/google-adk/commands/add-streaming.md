---
description: Add bidirectional streaming and real-time features to Google ADK agents
argument-hint: agent-name or feature-description
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add bidirectional streaming, real-time updates, and streaming capabilities to Google ADK agents for interactive, low-latency applications.

Core Principles:
- Understand existing agent structure before adding streaming
- Follow Google ADK streaming patterns and best practices
- Implement proper error handling and connection management
- Provide real-time feedback during implementation

Phase 1: Discovery
Goal: Understand the target agent and streaming requirements

Actions:
- Parse $ARGUMENTS to identify target agent or feature
- If $ARGUMENTS is unclear, use AskUserQuestion to gather:
  - Which agent needs streaming capabilities?
  - What type of streaming is needed (bidi, server-to-client, client-to-server)?
  - What real-time features are required?
  - Any specific performance or latency requirements?
- Detect project structure and Google ADK version
- Example: !{bash find . -name "package.json" -o -name "pyproject.toml" | head -5}

Phase 2: Analysis
Goal: Understand existing agent implementation and identify integration points

Actions:
- Locate target agent files using Glob
- Example: !{bash find . -type f -name "*agent*.py" -o -name "*agent*.ts" | head -10}
- Read agent configuration and implementation files
- Identify current communication patterns
- Check for existing streaming infrastructure
- Understand dependencies and requirements

Phase 3: Planning
Goal: Design the streaming implementation approach

Actions:
- Determine streaming architecture based on use case:
  - Bidirectional streaming for interactive conversations
  - Server-to-client for real-time updates
  - Client-to-server for continuous input processing
- Identify required dependencies (grpc, websockets, etc.)
- Plan error handling and reconnection logic
- Present implementation plan to user for confirmation

Phase 4: Implementation
Goal: Add streaming capabilities to the agent

Actions:

Task(description="Add streaming capabilities", subagent_type="google-adk-streaming-specialist", prompt="You are the google-adk-streaming-specialist agent. Add bidirectional streaming and real-time features to $ARGUMENTS.

Context: Google ADK agent requiring streaming capabilities

Requirements:
- Implement bidirectional streaming using Google ADK patterns
- Add proper connection lifecycle management (connect, disconnect, reconnect)
- Implement error handling and retry logic
- Add real-time event handling and callbacks
- Follow Google ADK best practices for streaming
- Include code comments explaining streaming flow
- Handle backpressure and flow control
- Implement graceful degradation on connection issues

Streaming Patterns to Consider:
- gRPC bidirectional streaming for agent-to-agent communication
- WebSocket connections for browser-based real-time updates
- Server-Sent Events (SSE) for one-way server-to-client streaming
- Streaming response handling with chunked data processing

Expected output:
- Updated agent files with streaming capabilities
- Connection management implementation
- Error handling and recovery logic
- Example usage showing streaming in action
- Documentation of streaming API")

Phase 5: Verification
Goal: Verify streaming implementation works correctly

Actions:
- Check that streaming code follows Google ADK patterns
- Verify error handling and connection management
- Review example usage and documentation
- If tests exist, run them: !{bash npm test || python -m pytest || echo "No tests configured"}
- Validate code quality: !{bash npm run lint || python -m pylint . || echo "No linter configured"}

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize streaming features added:
  - Type of streaming implemented
  - Connection management approach
  - Error handling strategy
  - Key files modified
- Highlight streaming API usage
- Suggest next steps:
  - Test with real-time data
  - Monitor connection stability
  - Optimize for latency
  - Add metrics and monitoring
