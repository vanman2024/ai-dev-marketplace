---
description: Add A2A agent to project with agent card and executor
argument-hint: <agent-name> [description]
allowed-tools: Task, Read, Write, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add a new A2A-compliant agent to the project with proper agent card, executor implementation, and registration.

Core Principles:
- Understand project structure before acting
- Follow A2A Protocol specification exactly
- Generate compliant agent cards with all required fields
- Create executable agent implementations
- Register agents properly in project configuration

Phase 1: Discovery
Goal: Gather requirements and understand project context

Actions:
- Parse $ARGUMENTS to extract agent name and optional description
- If description is unclear, use AskUserQuestion to gather:
  - What is the agent's primary purpose?
  - What tasks should it perform?
  - What tools or capabilities does it need?
  - Any specific A2A protocol version requirements?
- Load project configuration to understand existing structure
- Example: @package.json or @pyproject.toml

Phase 2: Analysis
Goal: Understand existing agents and project patterns

Actions:
- Search for existing agent cards: !{bash find . -name "*agent-card.json" -o -name "agents/*.json" 2>/dev/null | head -5}
- Read existing agent implementations to understand patterns
- Identify agent registry or configuration files
- Check for A2A protocol version in use

Phase 3: Planning
Goal: Design the agent implementation approach

Actions:
- Confirm agent card structure based on A2A spec version
- Determine where agent files should be created
- Identify required fields for agent card
- Plan executor implementation approach
- Present plan to user for confirmation

Phase 4: Implementation
Goal: Create agent with a2a-agent-builder

Actions:

Task(description="Build A2A agent", subagent_type="a2a-agent-builder", prompt="You are the a2a-agent-builder agent. Create a complete A2A-compliant agent for $ARGUMENTS.

Context:
- Project structure and existing patterns identified in Phase 2
- Agent requirements and capabilities from Phase 1
- A2A protocol version and compliance requirements

Requirements:
- Generate valid agent card JSON with all required fields
- Create executor implementation following project patterns
- Include proper capability declarations
- Add communication interface definitions
- Implement error handling and logging
- Follow A2A Protocol specification exactly

Expected output:
- Agent card JSON file
- Executor implementation file
- Registration in project configuration
- Usage documentation")

Phase 5: Review
Goal: Verify agent implementation

Actions:
- Check that agent card is valid JSON
- Example: !{bash cat agents/*/agent-card.json | python3 -m json.tool > /dev/null 2>&1 && echo "Valid JSON" || echo "Invalid JSON"}
- Verify all required A2A fields are present
- Confirm executor implementation is complete
- Run project validation if available

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize changes made:
  - Agent card location and key capabilities
  - Executor implementation details
  - Registration status
- Provide usage instructions:
  - How to invoke the agent
  - Configuration options
  - Testing recommendations
- Suggest next steps:
  - Test agent with sample tasks
  - Integrate with existing agents
  - Add to agent directory or catalog
