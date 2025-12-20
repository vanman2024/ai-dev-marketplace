---
description: Add enterprise features and production configurations for A2A Protocol
argument-hint: [feature-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add production-ready enterprise features to A2A Protocol implementation including rate limiting, circuit breakers, monitoring, observability, and security hardening.

Core Principles:
- Detect existing project structure before making changes
- Ask for clarification when feature requirements are ambiguous
- Follow A2A Protocol specifications and best practices
- Implement enterprise patterns for reliability and observability

Phase 1: Discovery
Goal: Understand project context and production feature requirements

Actions:
- Parse $ARGUMENTS to determine if specific feature type requested
- Detect project type and existing A2A implementation
- Example: @package.json or @pyproject.toml or @go.mod
- Load existing A2A configuration files
- Example: !{bash find . -name "a2a-config.*" -o -name "a2a.config.*" 2>/dev/null | head -5}

Phase 2: Requirements Gathering
Goal: Clarify which production features to implement

Actions:
- If $ARGUMENTS specifies feature type (rate-limiting, circuit-breaker, monitoring, etc.), use that
- Otherwise, use AskUserQuestion to gather:
  - Which production features are needed? (rate limiting, circuit breakers, monitoring, telemetry, security)
  - What monitoring/observability tools are being used? (Prometheus, Datadog, Sentry, etc.)
  - What scale/throughput requirements exist?
  - Any compliance or security requirements?
- Summarize requirements and confirm with user

Phase 3: Analysis
Goal: Understand current A2A implementation and identify integration points

Actions:
- Read existing A2A agent communication code
- Identify message routing and handler patterns
- Check for existing middleware or interceptor patterns
- Analyze current error handling approach
- Example: !{bash grep -r "A2AMessage\|MessageHandler\|AgentCommunication" src lib --include="*.ts" --include="*.js" --include="*.py" --include="*.go" | head -20}

Phase 4: Implementation Planning
Goal: Design the production feature integration approach

Actions:
- Plan integration approach based on existing architecture
- Identify files to modify and new files to create
- Design how production features integrate with A2A message flow
- Present plan to user for approval

Phase 5: Implementation
Goal: Add production features to A2A Protocol implementation

Actions:

Task(description="Add production features to A2A Protocol", subagent_type="a2a-production", prompt="You are the a2a-production agent. Add enterprise production features to the A2A Protocol implementation for $ARGUMENTS.

Context from Discovery:
- Project type and structure identified in Phase 1
- Feature requirements gathered in Phase 2
- Current A2A implementation analyzed in Phase 3
- Integration plan designed in Phase 4

Production Features to Implement:
- Rate Limiting: Token bucket or sliding window for message throughput control
- Circuit Breakers: Fail-fast patterns for agent communication resilience
- Monitoring: Metrics collection for message volumes, latencies, errors
- Observability: Distributed tracing for multi-agent message flows
- Security: Message authentication, encryption, and authorization

Requirements:
- Follow A2A Protocol specification (RFC format)
- Integrate seamlessly with existing message handlers
- Add minimal performance overhead
- Include comprehensive logging and metrics
- Provide configuration options for tuning
- Add health check endpoints
- Include graceful degradation patterns

Expected output:
- Production feature implementations integrated with A2A message flow
- Configuration files with sensible defaults
- Documentation explaining each feature and how to configure it
- Example usage showing how to enable/disable features
- Health check and monitoring endpoints")

Phase 6: Verification
Goal: Ensure production features work correctly

Actions:
- Verify configuration files are valid
- Check that production features integrate properly
- Run type checking if applicable
- Example: !{bash npm run typecheck 2>/dev/null || python -m mypy . 2>/dev/null || go vet ./... 2>/dev/null || echo "No type checking available"}
- Test that health endpoints respond correctly

Phase 7: Summary
Goal: Document what was accomplished

Actions:
- Summarize production features added
- List configuration options available
- Explain how to monitor and tune each feature
- Provide next steps for production deployment
- Highlight any security or performance considerations
