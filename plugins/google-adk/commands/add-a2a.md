---
description: Set up Agent-to-Agent (A2A) protocol for multi-agent systems using Google ADK
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Configure Agent-to-Agent communication protocol to enable multi-agent coordination, task delegation, and collaborative problem-solving using Google Agent Development Kit.

Core Principles:
- Detect project structure before assuming implementation
- Use Google ADK best practices for A2A protocol setup
- Follow framework-specific patterns (FastAPI, Flask, Django, etc.)
- Validate configuration and provide clear setup verification

Phase 1: Discovery
Goal: Understand project context and current state

Actions:
- Parse $ARGUMENTS for project path (default to current directory if not provided)
- Detect project type and framework using file patterns
- Example: !{bash ls -la package.json pyproject.toml setup.py requirements.txt 2>/dev/null}
- Load existing configuration files to understand current setup
- Check if Google ADK is already installed/configured

Phase 2: Validation
Goal: Verify prerequisites and environment readiness

Actions:
- Check if project directory exists and is valid
- Verify Google ADK installation or requirements
- Identify any existing agent implementations
- Detect conflicts with existing A2A configurations
- Load relevant framework files for context

Phase 3: Planning
Goal: Design A2A protocol implementation approach

Actions:
- Determine A2A protocol architecture based on project type
- Identify which agents need A2A communication
- Plan message schema, routing, and coordination patterns
- Consider security, authentication, and error handling
- Present implementation plan with key decisions

Phase 4: Implementation
Goal: Set up A2A protocol with Google ADK

Actions:

Task(description="Configure A2A protocol", subagent_type="google-adk-a2a-specialist", prompt="You are the google-adk-a2a-specialist agent. Set up Agent-to-Agent (A2A) protocol for $ARGUMENTS.

Context: Project has been analyzed and prerequisites validated.

Your responsibilities:
1. Configure A2A communication infrastructure
2. Implement agent discovery and registration
3. Set up message routing and protocol handlers
4. Configure task delegation and coordination patterns
5. Implement error handling and retry logic
6. Add monitoring and observability for agent interactions
7. Create example agents demonstrating A2A communication
8. Generate documentation for A2A usage

Requirements:
- Follow Google ADK A2A protocol specifications
- Use framework-specific best practices
- Implement secure agent-to-agent communication
- Include comprehensive error handling
- Add logging and debugging capabilities
- Provide clear examples and documentation

Expected output:
- A2A protocol configuration files
- Agent communication infrastructure
- Example multi-agent implementations
- Setup verification tests
- Documentation and usage guides")

Phase 5: Verification
Goal: Validate A2A protocol setup and functionality

Actions:
- Verify all A2A configuration files are created
- Check agent communication infrastructure is working
- Run example agents to test A2A protocol
- Example: !{bash python -m pytest tests/test_a2a_protocol.py 2>/dev/null || echo "No tests found"}
- Validate message routing and task delegation
- Test error handling and recovery mechanisms

Phase 6: Summary
Goal: Document what was accomplished and next steps

Actions:
- Summarize A2A protocol setup completed
- List all files created or modified
- Highlight key configuration decisions made
- Provide examples of using A2A protocol
- Suggest next steps:
  - Create additional agents using A2A
  - Implement specific multi-agent workflows
  - Configure advanced A2A features (security, monitoring)
  - Test agent coordination scenarios
