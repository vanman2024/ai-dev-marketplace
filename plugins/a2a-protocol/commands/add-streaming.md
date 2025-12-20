---
description: Add streaming and async operations support to A2A Protocol implementation
argument-hint: [feature-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Implement streaming capabilities and async operations for A2A Protocol, enabling real-time message streaming, async task handling, and progressive response delivery.

Core Principles:
- Detect existing A2A Protocol implementation before modifying
- Follow A2A Protocol specification for streaming operations
- Implement both Server-Sent Events (SSE) and WebSocket streaming
- Ensure backward compatibility with non-streaming operations
- Provide comprehensive examples and testing utilities

Phase 1: Discovery
Goal: Understand the current A2A Protocol implementation and streaming requirements

Actions:
- Parse $ARGUMENTS to identify which streaming features to add
- If unclear, use AskUserQuestion to gather:
  - What streaming features are needed? (SSE, WebSocket, or both)
  - Are there existing async operations to enhance?
  - What use cases require streaming? (chat, progress updates, file transfers)
  - Should we add async task queue support?
- Detect project type and framework
- Example: !{bash ls package.json pyproject.toml go.mod 2>/dev/null}
- Load existing A2A Protocol configuration if present
- Example: @a2a-protocol.config.json

Phase 2: Analysis
Goal: Understand current codebase structure and identify integration points

Actions:
- Find existing A2A Protocol implementation files
- Example: !{bash find . -name "*a2a*" -o -name "*agent*" 2>/dev/null | grep -v node_modules | head -20}
- Identify framework-specific patterns (Express, FastAPI, Next.js, etc.)
- Read relevant configuration and implementation files
- Understand current message handling architecture
- Check for existing streaming or async infrastructure

Phase 3: Planning
Goal: Design the streaming implementation approach

Actions:
- Outline implementation strategy based on detected framework
- Identify files that need creation or modification
- Plan streaming architecture:
  - SSE endpoint configuration
  - WebSocket connection handling
  - Async task queue setup
  - Message buffering and flow control
- Determine testing approach
- Present plan to user and confirm before proceeding

Phase 4: Implementation
Goal: Add streaming and async capabilities via specialized agent

Actions:

Task(description="Implement A2A Protocol streaming and async operations", subagent_type="a2a-streaming", prompt="You are the a2a-streaming agent. Implement streaming and async operations support for A2A Protocol based on $ARGUMENTS.

Context: A2A Protocol requires streaming capabilities for real-time agent communication, progress updates, and async task handling.

Requirements:
- Implement Server-Sent Events (SSE) for unidirectional streaming
- Add WebSocket support for bidirectional real-time communication
- Create async task queue for long-running operations
- Add message chunking and buffering mechanisms
- Implement flow control and backpressure handling
- Ensure A2A Protocol compliance for streaming messages
- Add comprehensive error handling for stream failures
- Create TypeScript/Python types for streaming operations
- Follow framework-specific best practices detected in Phase 2

Deliverables:
- Streaming endpoint implementations (SSE and/or WebSocket)
- Async task queue infrastructure
- Message serialization for streaming
- Client-side streaming utilities
- Example implementations showing streaming usage
- Tests validating streaming operations
- Documentation with integration examples

Expected output: Complete streaming implementation with working examples and tests")

Phase 5: Verification
Goal: Validate streaming implementation works correctly

Actions:
- Check that streaming endpoints are properly configured
- Verify async operations integrate with existing A2A Protocol code
- Run tests if available
- Example: !{bash npm test 2>/dev/null || python -m pytest 2>/dev/null || go test ./... 2>/dev/null}
- Verify framework-specific integration (Next.js API routes, FastAPI endpoints, etc.)
- Check for proper error handling in stream scenarios
- Validate A2A Protocol message format compliance

Phase 6: Summary
Goal: Document what was accomplished and provide next steps

Actions:
- Summarize streaming features added:
  - SSE endpoint locations and usage
  - WebSocket configuration and connection handling
  - Async task queue implementation details
  - Message buffering and flow control mechanisms
- List files created or modified
- Highlight key implementation decisions:
  - Framework-specific patterns used
  - Streaming protocol choices (SSE vs WebSocket)
  - Error handling strategies
  - Performance optimizations applied
- Provide usage examples for developers
- Suggest next steps:
  - Testing streaming with real agents
  - Performance tuning and load testing
  - Adding monitoring and observability
  - Implementing stream reconnection logic
  - Scaling considerations for production
