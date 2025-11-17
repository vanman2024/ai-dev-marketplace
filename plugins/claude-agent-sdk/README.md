# Claude Agent SDK Plugin

Complete Claude Agent SDK plugin for building AI agents with TypeScript and Python support.

## Overview

This plugin provides comprehensive tooling for building AI agents using the Claude Agent SDK. It includes 15 commands (2 for initialization, 13 for features, 1 orchestrator) plus 4 specialized agents for setup, feature implementation, and validation.

## Commands

### Project Initialization

#### `/claude-agent-sdk:new-app [project-name]`
Create and setup a new Claude Agent SDK application with TypeScript or Python.

**Features:**
- Interactive project setup with language selection
- Latest SDK version installation
- Starter code generation with best practices
- Automatic project validation
- Security defaults (.env.example, .gitignore)

### Feature Addition Commands

#### `/claude-agent-sdk:add-streaming [project-path]`
Add streaming capabilities to handle real-time token generation.

**Adds:**
- Async iteration for streaming responses
- Stream error handling
- Streaming vs single-mode configuration

#### `/claude-agent-sdk:add-sessions [project-path]`
Add session management for multi-turn conversations.

**Adds:**
- Session state management
- Session persistence
- Session configuration options

#### `/claude-agent-sdk:add-mcp [project-path]`
Add Model Context Protocol (MCP) integration for external tools.

**Adds:**
- MCP server connections
- MCP tool permissions
- Custom MCP server creation
- MCP error handling

#### `/claude-agent-sdk:add-custom-tools [project-path]`
Add custom tool definitions for agent capabilities.

**Adds:**
- Tool schema definitions
- Tool implementation functions
- Tool permissions configuration
- Tool execution error handling

#### `/claude-agent-sdk:add-subagents [project-path]`
Add subagent definitions for specialized tasks.

**Adds:**
- Subagent role definitions
- Subagent system prompts
- Subagent tool permissions
- Subagent invocation handling

#### `/claude-agent-sdk:add-permissions [project-path]`
Add permission handling for tool access control.

**Adds:**
- Tool permission levels
- askBeforeToolUse configuration
- Permission callbacks
- Permission error handling

#### `/claude-agent-sdk:add-hosting [project-path]`
Add hosting and deployment configuration.

**Adds:**
- Server framework setup
- Endpoint routing
- Environment variable handling
- CORS and security configurations

#### `/claude-agent-sdk:add-system-prompts [project-path]`
Add system prompts for agent behavior customization.

**Adds:**
- System prompt configuration
- Dynamic prompt generation
- Prompt templating
- Context injection

#### `/claude-agent-sdk:add-slash-commands [project-path]`
Add slash command definitions for agent interactions.

**Adds:**
- Slash command definitions
- Command handler functions
- Command registration
- Command error handling

#### `/claude-agent-sdk:add-skills [project-path]`
Add skill definitions for reusable agent capabilities.

**Adds:**
- Skill definitions
- Skill handler functions
- Skill registration
- Skill error handling

#### `/claude-agent-sdk:add-plugins [project-path]`
Add plugin system for extensibility.

**Adds:**
- Plugin definitions
- Plugin loading system
- Plugin registration
- Plugin error handling

#### `/claude-agent-sdk:add-cost-tracking [project-path]`
Add cost and usage monitoring.

**Adds:**
- Token usage tracking
- Cost calculation logic
- Usage data storage
- Reporting and analytics

#### `/claude-agent-sdk:add-todo-tracking [project-path]`
Add todo list and task management.

**Adds:**
- Todo list management
- Task creation and updates
- Todo persistence
- Todo query and filtering

## Agents

### `claude-agent-setup`
Creates and initializes new Claude Agent SDK projects with proper structure, dependencies, and starter code. Handles both TypeScript and Python project setup.

**Responsibilities:**
- Project directory creation
- Package manager initialization
- SDK installation (latest version)
- Starter code generation
- Security configuration
- Documentation creation

### `claude-agent-features`
Implements SDK features in existing applications following official documentation patterns. Supports all SDK capabilities including streaming, sessions, MCP, tools, subagents, and more.

**Responsibilities:**
- Feature-specific implementation
- Documentation fetching
- Pattern compliance
- Error handling
- Configuration setup

### `claude-agent-verifier-ts`
Validates TypeScript Claude Agent SDK applications for correctness, SDK compliance, and best practices.

**Validates:**
- SDK installation and configuration
- TypeScript compilation
- Type safety
- SDK usage patterns
- Security measures
- Documentation

### `claude-agent-verifier-py`
Validates Python Claude Agent SDK applications for correctness, SDK compliance, and best practices.

**Validates:**
- SDK installation and configuration
- Python dependencies
- Type hints usage
- SDK usage patterns
- Security measures
- Documentation

## Usage Example

```bash
# Create a new agent project
/claude-agent-sdk:new-app my-chatbot

# Add streaming support
/claude-agent-sdk:add-streaming my-chatbot

# Add MCP integration
/claude-agent-sdk:add-mcp my-chatbot

# Add custom tools
/claude-agent-sdk:add-custom-tools my-chatbot

# Add subagents for specialized tasks
/claude-agent-sdk:add-subagents my-chatbot

# Add cost tracking
/claude-agent-sdk:add-cost-tracking my-chatbot
```

## Installation

This plugin is part of the ai-dev-marketplace. It will be automatically available when the marketplace is loaded.

## Documentation

- [Claude Agent SDK Overview](https://docs.claude.com/en/api/agent-sdk/overview)
- [TypeScript SDK Reference](https://docs.claude.com/en/api/agent-sdk/typescript)
- [Python SDK Reference](https://docs.claude.com/en/api/agent-sdk/python)
- [Streaming Mode](https://docs.claude.com/en/api/agent-sdk/streaming-vs-single-mode)
- [Session Management](https://docs.claude.com/en/api/agent-sdk/sessions)
- [MCP Integration](https://docs.claude.com/en/api/agent-sdk/mcp)
- [Custom Tools](https://docs.claude.com/en/api/agent-sdk/custom-tools)
- [Subagents](https://docs.claude.com/en/api/agent-sdk/subagents)
- [Permissions](https://docs.claude.com/en/api/agent-sdk/permissions)
- [Cost Tracking](https://docs.claude.com/en/api/agent-sdk/cost-tracking)

## Architecture

### Command Pattern
All add-* commands follow Pattern 2 (Single Agent) with 6 phases:
1. **Discovery**: Gather context and load documentation
2. **Analysis**: Understand current implementation
3. **Planning**: Design feature integration
4. **Implementation**: Invoke claude-agent-features agent
5. **Review**: Invoke appropriate verifier agent
6. **Summary**: Document changes and usage

### Agent Workflow
1. Commands coordinate the workflow
2. claude-agent-setup creates new projects
3. claude-agent-features implements SDK capabilities
4. Verifiers ensure compliance with SDK best practices

## License

MIT
