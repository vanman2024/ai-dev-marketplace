---
description: Add logging, tracing, and analytics to Google ADK agents
argument-hint: [logging|tracing|analytics|all]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add comprehensive observability capabilities (logging, tracing, analytics) to Google ADK agents for monitoring and debugging.

Core Principles:
- Detect existing agent configurations before modifying
- Understand observability requirements and scope
- Follow Google ADK best practices for instrumentation
- Integrate seamlessly with existing agent workflows

Phase 1: Discovery
Goal: Understand project context and observability requirements

Actions:
- Parse $ARGUMENTS to determine observability type (logging, tracing, analytics, or all)
- Detect Google ADK agents in the project
- Example: !{bash find . -name "*.py" -type f | xargs grep -l "from google.adk"}
- Check for existing observability configurations
- Load package.json or pyproject.toml to understand dependencies

Phase 2: Analysis
Goal: Understand existing agent structure and identify integration points

Actions:
- Read Google ADK agent files to understand current implementation
- Identify where observability hooks should be added
- Check for existing logging, tracing, or analytics libraries
- Determine which observability tools to use based on project setup

Phase 3: Requirements Clarification
Goal: Gather specific observability needs from user

Actions:
- If $ARGUMENTS is unclear or incomplete, use AskUserQuestion to gather:
  - Which observability features are needed? (logging, tracing, analytics, or all)
  - What logging level should be configured? (DEBUG, INFO, WARNING, ERROR)
  - Should tracing include LLM call metadata?
  - What analytics platform to integrate with? (Google Cloud Logging, OpenTelemetry, custom)
  - Do you need real-time monitoring or batch analytics?

Phase 4: Implementation
Goal: Integrate observability using specialized agent

Actions:

Task(description="Add observability to Google ADK agents", subagent_type="google-adk-observability-integrator", prompt="You are the google-adk-observability-integrator agent. Add observability capabilities to Google ADK agents based on $ARGUMENTS.

Context from Discovery:
- Observability type requested: $ARGUMENTS
- Detected Google ADK agents and configurations
- Existing project dependencies and structure

Requirements:
- Add appropriate logging instrumentation to agent lifecycle events
- Configure tracing for LLM calls and tool executions if requested
- Integrate analytics for performance metrics and usage tracking if requested
- Follow Google ADK patterns for middleware and hooks
- Ensure backward compatibility with existing agent code
- Add necessary dependencies to project configuration
- Create or update observability configuration files
- Document observability setup and usage

Expected output:
- Modified agent files with observability hooks
- Configuration files for logging/tracing/analytics
- Updated dependency files (package.json, pyproject.toml)
- Documentation on how to use and customize observability features")

Phase 5: Verification
Goal: Ensure observability integration works correctly

Actions:
- Check that all required dependencies are installed
- Verify configuration files are properly formatted
- Example: !{bash python -m py_compile $(find . -name "*.py" -type f) 2>&1 | head -20}
- Review agent code for proper instrumentation
- Confirm logging/tracing/analytics outputs are being generated

Phase 6: Summary
Goal: Report what was accomplished and next steps

Actions:
- Summarize observability features added
- List files modified and created
- Provide examples of how to view logs, traces, or analytics
- Suggest next steps:
  - Test observability in development environment
  - Configure production observability settings
  - Set up dashboards for monitoring
  - Review and adjust logging levels as needed
