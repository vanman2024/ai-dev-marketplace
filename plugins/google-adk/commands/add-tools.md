---
description: Add Gemini API, Google Cloud, or custom tools to agents
argument-hint: <tool-type> [tool-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Integrate tools (Gemini API, Google Cloud services, or custom functions) into Google ADK agents for enhanced capabilities

Core Principles:
- Detect project context before suggesting tools
- Validate Google Cloud credentials and API access
- Follow Google ADK best practices for tool configuration
- Test tool integration after implementation

Phase 1: Discovery
Goal: Understand project context and tool requirements

Actions:
- Parse $ARGUMENTS to identify:
  - Tool type (gemini-api, google-cloud, custom)
  - Specific tool name if provided
  - Target agent or application
- Detect project structure and framework
- Example: @pyproject.toml or @package.json
- Check for existing Google ADK configuration
- Example: !{bash find . -name "agent.py" -o -name "*.ts" | grep -E "(agent|adk)" | head -5}

Phase 2: Validation
Goal: Verify prerequisites and access

Actions:
- Check if Google Cloud SDK is installed
- Example: !{bash gcloud --version 2>/dev/null || echo "Not installed"}
- Verify API credentials are configured
- Check for required environment variables (GOOGLE_API_KEY, PROJECT_ID)
- Validate tool compatibility with current ADK version
- Load existing agent configurations to understand current tools
- Example: @src/agent.py

Phase 3: Planning
Goal: Design tool integration approach

Actions:
- Identify which tools to add based on requirements
- Determine configuration approach (API keys, service accounts, OAuth)
- Plan code changes needed in agent definitions
- Outline testing strategy for new tools
- If tool type is unclear, present options to user:
  - Gemini API tools (code generation, multimodal processing)
  - Google Cloud tools (Cloud Storage, BigQuery, Vertex AI)
  - Custom tools (user-defined functions)

Phase 4: Implementation
Goal: Integrate tools using google-adk-tools-integrator agent

Actions:

Task(description="Integrate tools into Google ADK agents", subagent_type="google-adk-tools-integrator", prompt="You are the google-adk-tools-integrator agent. Add tools to Google ADK agents for $ARGUMENTS.

Project Context:
- Framework detected in Phase 1
- Existing agent configuration from Phase 2
- Tool requirements from Phase 3

Requirements:
- Add tool definitions to agent configuration
- Configure authentication and credentials
- Implement error handling for tool failures
- Follow Google ADK tool integration patterns
- Create environment variable templates
- Add usage examples and documentation

Deliverable: Complete tool integration with configuration files, updated agent code, and usage examples")

Phase 5: Verification
Goal: Validate tool integration works correctly

Actions:
- Check that all configuration files are created
- Verify environment variable templates exist
- Example: @.env.example
- Run syntax validation if applicable
- Example: !{bash python -m py_compile src/agent.py 2>&1 || npm run typecheck 2>&1}
- Test tool invocation if test suite exists
- Confirm no hardcoded API keys in committed files

Phase 6: Summary
Goal: Document integration and next steps

Actions:
- List tools that were integrated
- Show configuration files created/modified
- Highlight environment variables that need to be set
- Provide next steps:
  - Set up real API keys in .env file
  - Test tool functionality with example queries
  - Review security best practices for API key management
- Display relevant file paths and code snippets
