---
description: Add LLM, custom, or workflow agents to Google ADK project
argument-hint: <agent-type> <agent-name>
allowed-tools: Task, Read, Write, Edit, Bash(*), Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Add new agents (LLM-based, custom tool, or workflow) to a Google ADK project with proper configuration and integration.

Core Principles:
- Detect project structure before assuming configuration
- Support all three agent types (LLM, custom, workflow)
- Follow Google ADK best practices and patterns
- Validate agent configuration before finalizing

Phase 1: Discovery
Goal: Understand the target project and agent requirements

Actions:
- Parse $ARGUMENTS for agent type and name
- If $ARGUMENTS is unclear or missing, use AskUserQuestion to gather:
  - What type of agent? (llm/custom/workflow)
  - What is the agent name?
  - What should the agent do?
  - Any specific tools or capabilities needed?
- Verify this is a Google ADK project:
  - Check for agent configuration patterns
  - Example: !{bash ls -la agents/ app/ 2>/dev/null || echo "Not found"}
- Load existing agent configurations for context
- Example: @agents/

Phase 2: Analysis
Goal: Understand existing agent patterns and project structure

Actions:
- Find existing agent implementations:
  - Example: !{bash find agents/ -name "*.py" -o -name "*.ts" 2>/dev/null | head -5}
- Read sample agent files to understand patterns
- Identify agent registry location
- Determine required dependencies and imports
- Check for agent configuration files

Phase 3: Planning
Goal: Design the agent implementation approach

Actions:
- Based on agent type (llm/custom/workflow), plan:
  - Required files and structure
  - Dependencies and imports
  - Configuration format
  - Integration points with existing agents
- Present plan to user:
  - Agent structure to be created
  - Files that will be modified
  - Configuration approach
  - Any trade-offs or considerations

Phase 4: Implementation
Goal: Create the agent with proper configuration

Actions:

Task(description="Add Google ADK agent", subagent_type="google-adk-agent-builder", prompt="You are the google-adk-agent-builder agent. Add a new agent to this Google ADK project for $ARGUMENTS.

Context from discovery:
- Agent type and name parsed from arguments
- Existing project structure analyzed
- Agent patterns identified

Requirements:
- Create agent implementation file
- Configure agent according to type (LLM/custom/workflow)
- Add proper imports and dependencies
- Register agent in agent registry
- Follow Google ADK best practices
- Include appropriate error handling
- Add documentation and comments

Agent Types:
- LLM: Uses language model for reasoning and responses
- Custom: Uses custom tools and functions
- Workflow: Orchestrates multiple steps or sub-agents

Expected output:
- Agent implementation file created
- Agent registered and configured
- Documentation included
- Summary of capabilities and usage")

Phase 5: Verification
Goal: Ensure the agent is properly configured

Actions:
- Verify agent file was created
- Check agent registration
- Validate configuration syntax if applicable
- Example: !{bash python -m py_compile agents/*.py 2>&1 || true}
- Test agent can be imported/loaded
- Confirm no syntax errors

Phase 6: Summary
Goal: Document what was accomplished

Actions:
- Summarize agent creation:
  - Agent type and name
  - Files created or modified
  - Key capabilities added
  - How to use the agent
- Provide next steps:
  - Testing the agent
  - Configuring additional tools if needed
  - Integration with other agents
  - Deployment considerations
