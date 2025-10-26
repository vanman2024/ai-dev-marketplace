# Claude Agent SDK Plugin

Modular Claude Agent SDK development plugin with feature bundles and specialized agents. Build AI agents incrementally or all-at-once with support for TypeScript and Python.

## Overview

This plugin provides a comprehensive toolkit for building sophisticated AI agents using the Claude Agent SDK. Whether you're creating a simple chatbot or a complex multi-agent system, this plugin helps you implement best practices and leverage all SDK capabilities.

## Installation

```bash
# Add ai-dev-marketplace if not already added
claude marketplace add ai-dev-marketplace \
  --source github:vanman2024/ai-dev-marketplace

# The claude-agent-sdk plugin is included in the marketplace
```

## Commands

### Core Commands

#### `/claude-agent-sdk:new-app [project-name]`
Initialize a new Claude Agent SDK project with TypeScript or Python setup.

**Usage:**
```bash
/claude-agent-sdk:new-app my-agent
```

#### `/claude-agent-sdk:add-streaming`
Add streaming input/output capabilities for real-time responses.

#### `/claude-agent-sdk:add-tools [tool-name]`
Add custom tool integration and permission management.

#### `/claude-agent-sdk:add-sessions [storage-type]`
Implement session management and state persistence.

#### `/claude-agent-sdk:add-mcp [mcp-server-name]`
Integrate MCP server capabilities (Model Context Protocol).

### Feature Bundle Commands

#### `/claude-agent-sdk:add-agent-features`
Add advanced agent capabilities bundle:
- Subagents for specialized tasks
- Slash commands for user-invoked actions
- Agent skills for autonomous capabilities
- System prompt customization

#### `/claude-agent-sdk:add-plugin-system [plugin-name]`
Add plugin development and management capabilities.

#### `/claude-agent-sdk:add-production`
Add production-ready features:
- Cost tracking and usage monitoring
- Error handling and logging
- Performance optimization
- Hosting and deployment setup

#### `/claude-agent-sdk:add-migration [migration-type]`
Migrate existing application to Agent SDK or upgrade SDK versions.

### Full Stack Command

#### `/claude-agent-sdk:build-complete [project-name]`
Build a complete Agent SDK application with all features at once.

**Usage:**
```bash
/claude-agent-sdk:build-complete my-complete-agent
```

## Specialized Agents

### Verifier Agents

**claude-agent-verifier-ts**
Validates TypeScript Agent SDK applications for proper configuration, SDK best practices, and production readiness.

**claude-agent-verifier-py**
Validates Python Agent SDK applications for proper configuration, SDK best practices, and production readiness.

### Feature Implementation Agents

**claude-agent-features-agent**
Implements advanced agent capabilities including subagents, slash commands, agent skills, and system prompt customization.

**claude-agent-plugin-agent**
Builds and manages Claude Agent SDK plugins with proper structure, commands, agents, and distribution setup.

**claude-agent-production-agent**
Adds production-ready features including cost tracking, monitoring, error handling, and deployment configuration.

**claude-agent-migration-agent**
Handles migrations from direct API usage, other frameworks, or SDK version upgrades.

## Usage Examples

### Create a Simple Agent

```bash
# Initialize new project
/claude-agent-sdk:new-app my-agent

# Add streaming for real-time responses
/claude-agent-sdk:add-streaming

# Add custom tools
/claude-agent-sdk:add-tools
```

### Build a Complete Agent System

```bash
# One command to build everything
/claude-agent-sdk:build-complete my-complete-agent
```

### Add Advanced Features to Existing Project

```bash
# Add subagents and skills
/claude-agent-sdk:add-agent-features

# Add production features
/claude-agent-sdk:add-production
```

### Migrate from Direct API Usage

```bash
# Migrate existing code to SDK
/claude-agent-sdk:add-migration
```

## Features

- **Incremental Development**: Add features one at a time as needed
- **Complete Stack**: Build fully-featured agents with one command
- **TypeScript & Python**: Full support for both languages
- **Latest Documentation**: Uses Context7 MCP to fetch up-to-date SDK docs
- **Best Practices**: Follows official SDK patterns and recommendations
- **Production Ready**: Includes cost tracking, monitoring, and deployment tools
- **Migration Support**: Upgrade existing applications to use Agent SDK

## Documentation

### Official SDK Documentation
- [Overview](https://docs.claude.com/en/api/agent-sdk/overview)
- [TypeScript SDK](https://docs.claude.com/en/api/agent-sdk/typescript)
- [Python SDK](https://docs.claude.com/en/api/agent-sdk/python)
- [Streaming](https://docs.claude.com/en/api/agent-sdk/streaming-vs-single-mode)
- [Custom Tools](https://docs.claude.com/en/api/agent-sdk/custom-tools)
- [Subagents](https://docs.claude.com/en/api/agent-sdk/subagents)
- [MCP Integration](https://docs.claude.com/en/api/agent-sdk/mcp)
- [Cost Tracking](https://docs.claude.com/en/api/agent-sdk/cost-tracking)

### Plugin Documentation
- See `docs/` directory for comprehensive guides
- Each command includes inline documentation
- Agents provide detailed verification reports

## Development Workflow

1. **Initialize**: Start with `/claude-agent-sdk:new-app`
2. **Add Core Features**: Use `add-streaming`, `add-tools`, `add-sessions`, `add-mcp`
3. **Add Advanced Features**: Use `add-agent-features` or `add-plugin-system`
4. **Prepare for Production**: Use `add-production`
5. **Verify**: Agents automatically validate your setup

## Contributing

This plugin is part of the ai-dev-marketplace. Contributions welcome!

## License

MIT

## Author

vanman2024 (ai-dev-marketplace team)

## Version

1.0.0
