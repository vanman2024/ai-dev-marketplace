# Claude Agent SDK Documentation
*Pure Agent SDK documentation for building AI agents with Claude*

Generated on: December 26, 2024

## 🧠 Claude Agent SDK - Pure SDK Documentation

The Claude Agent SDK is a framework specifically for building AI agents. This document covers ONLY the Agent SDK itself - for general Claude API documentation, see [Claude API Documentation](./claude-api-documentation.md).

### Core SDK Documentation
- **[Overview](https://docs.claude.com/en/api/agent-sdk/overview)** - Getting started with the Claude Agent SDK
- **[TypeScript SDK](https://docs.claude.com/en/api/agent-sdk/typescript)** - Complete TypeScript API reference with installation, functions (query(), tool(), createSdkMcpServer()), type definitions, message types, tool types, and permission types
- **[Python SDK](https://docs.claude.com/en/api/agent-sdk/python)** - Complete Python API reference with ClaudeSDKClient, query() function, hook types, tool schemas, and error handling
- **[Migration Guide](https://docs.claude.com/en/docs/claude-code/sdk/migration-guide)** - Migrate to Claude Agent SDK from previous versions

### SDK-Specific Guides
- **[Streaming Input](https://docs.claude.com/en/api/agent-sdk/streaming-vs-single-mode)** - Handle streaming vs single mode operations in the SDK
- **[Handling Permissions](https://docs.claude.com/en/api/agent-sdk/permissions)** - Manage tool permissions and authorization in SDK
- **[Session Management](https://docs.claude.com/en/api/agent-sdk/sessions)** - Handle user sessions and state management in SDK
- **[Hosting the Agent SDK](https://docs.claude.com/en/api/agent-sdk/hosting)** - Deploy and host your SDK applications
- **[Modifying System Prompts](https://docs.claude.com/en/api/agent-sdk/modifying-system-prompts)** - Customize system behavior and prompts in SDK
- **[MCP in the SDK](https://docs.claude.com/en/api/agent-sdk/mcp)** - Model Context Protocol integration with SDK
- **[Custom Tools](https://docs.claude.com/en/api/agent-sdk/custom-tools)** - Create and integrate custom tools in SDK
- **[Subagents in the SDK](https://docs.claude.com/en/api/agent-sdk/subagents)** - Work with specialized sub-agents
- **[Slash Commands in the SDK](https://docs.claude.com/en/api/agent-sdk/slash-commands)** - Implement user-invoked commands
- **[Agent Skills in the SDK](https://docs.claude.com/en/api/agent-sdk/skills)** - Extend Claude with specialized capabilities using Agent Skills
- **[Plugins in the SDK](https://docs.claude.com/en/api/agent-sdk/plugins)** - Load custom plugins to extend Claude Code with commands, agents, skills, and hooks
- **[Tracking Costs and Usage](https://docs.claude.com/en/api/agent-sdk/cost-tracking)** - Monitor token usage and billing in SDK
- **[Todo Lists](https://docs.claude.com/en/api/agent-sdk/todo-tracking)** - Track and display todos for organized task management

### Agent Skills (SDK Feature)
- **[Agent Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)** - Learn about extending Claude's capabilities with Agent Skills
- **[Agent Skills Quickstart](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart)** - Get started quickly with Agent Skills
- **[Agent Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)** - Authoring guidelines and naming conventions for effective Skills

## 🚀 SDK Quick Start

### Installation
```bash
# TypeScript/JavaScript
npm install @anthropic-ai/claude-agent-sdk

# Python
pip install claude-agent-sdk
```

### Basic SDK Usage
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

// Simple agent query
for await (const message of query({
  prompt: "Build a web scraper for product prices",
  options: {
    allowedTools: ["Bash", "Web", "Code"],
    maxTurns: 10
  }
})) {
  console.log(message);
}
```

### Using Agent Skills
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

// Query with Skills enabled
for await (const message of query({
  prompt: "Process this PDF and extract key information",
  options: {
    settingSources: ["user", "project"], // Required to load Skills
    allowedTools: ["Skill", "Read", "Write"],
    cwd: "/path/to/project" // Must contain .claude/skills/
  }
})) {
  console.log(message);
}
```

### Creating Custom Subagents
```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const options = {
  subagents: [{
    name: "data-analyst",
    description: "Analyze data and generate insights",
    systemPrompt: "You are an expert data analyst..."
  }]
};

for await (const message of query({
  prompt: "Analyze this sales data",
  options
})) {
  console.log(message);
}
```

## 🤖 Key SDK Concepts

### Agent SDK vs Claude API
| Feature | Claude API | Agent SDK |
|---------|-----------|-----------|
| **Purpose** | Direct language model access | Building AI agents |
| **Abstraction** | Low-level | High-level |
| **Tools** | Custom implementation required | Built-in tools included |
| **Skills** | Not available | Agent Skills supported |
| **Subagents** | Not available | Built-in support |
| **Sessions** | Manual management | Managed by SDK |

### Core SDK Features

**🔧 Built-in Tools**
- Bash execution
- Web browsing
- Code execution
- File operations

**⚡ Agent Skills**
- Autonomous capabilities
- Claude invokes when relevant
- Filesystem-based definitions

**👥 Subagents**
- Specialized agents for domains
- Can be defined programmatically
- Custom system prompts

**🔌 Plugins**
- Extend with custom commands
- Bundle skills and tools
- Share across projects

**📊 Session Management**
- Persistent conversations
- State management
- Cost tracking

### Architecture
```
Your Application
       ↓
Claude Agent SDK (query(), tool(), etc.)
       ↓
Claude API (messages.create())
       ↓
Claude Models
```

## 📚 Related Resources

- **[Claude API Documentation](./claude-api-documentation.md)** - Core API reference
- **[GitHub Repository](https://github.com/anthropics/claude-agent-sdk)** - Source code and examples
- **[Claude Console](https://console.anthropic.com/dashboard)** - Web interface and tools
- **[Community Discord](https://www.anthropic.com/discord)** - Developer community