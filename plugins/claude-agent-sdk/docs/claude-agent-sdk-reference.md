# Claude Agent SDK Documentation Reference

> **For LLM Context**: This document contains comprehensive reference material for the Anthropic Claude Agent SDK, organized for quick retrieval of key concepts, code patterns, and API details.

## Table of Contents

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
- [TypeScript SDK Reference](#typescript-sdk-reference)
- [TypeScript V2 Preview](#typescript-v2-preview)
- [Python SDK Reference](#python-sdk-reference)
- [Hooks System](#hooks-system)
- [MCP Integration](#mcp-integration)
- [Custom Tools](#custom-tools)
- [Subagents](#subagents)
- [Permissions](#permissions)
- [Sessions](#sessions)
- [Built-in Tools](#built-in-tools)

---

## Overview

The Claude Agent SDK provides programmatic access to Claude Code's agentic capabilities, enabling autonomous coding tasks with file operations, shell commands, and multi-turn conversations.

**Key capabilities:**

- Execute autonomous coding tasks with file operations and shell commands
- Integrate custom tools via MCP (Model Context Protocol)
- Control agent behavior with hooks for security, logging, and customization
- Spawn subagents for parallel task execution with isolated contexts
- Stream responses for real-time updates

---

## Quick Links

| Page                     | URL                                                                    |
| ------------------------ | ---------------------------------------------------------------------- |
| Overview                 | https://platform.claude.com/docs/en/agent-sdk/overview                 |
| Quickstart               | https://platform.claude.com/docs/en/agent-sdk/quickstart               |
| TypeScript SDK           | https://platform.claude.com/docs/en/agent-sdk/typescript               |
| TypeScript V2 Preview    | https://platform.claude.com/docs/en/agent-sdk/typescript-v2-preview    |
| Python SDK               | https://platform.claude.com/docs/en/agent-sdk/python                   |
| Migration Guide          | https://platform.claude.com/docs/en/agent-sdk/migration-guide          |
| **Guides**               |                                                                        |
| Streaming Input          | https://platform.claude.com/docs/en/agent-sdk/streaming-vs-single-mode |
| Permissions              | https://platform.claude.com/docs/en/agent-sdk/permissions              |
| User Input               | https://platform.claude.com/docs/en/agent-sdk/user-input               |
| Hooks                    | https://platform.claude.com/docs/en/agent-sdk/hooks                    |
| Sessions                 | https://platform.claude.com/docs/en/agent-sdk/sessions                 |
| File Checkpointing       | https://platform.claude.com/docs/en/agent-sdk/file-checkpointing       |
| Structured Outputs       | https://platform.claude.com/docs/en/agent-sdk/structured-outputs       |
| Hosting                  | https://platform.claude.com/docs/en/agent-sdk/hosting                  |
| Secure Deployment        | https://platform.claude.com/docs/en/agent-sdk/secure-deployment        |
| Modifying System Prompts | https://platform.claude.com/docs/en/agent-sdk/modifying-system-prompts |
| MCP                      | https://platform.claude.com/docs/en/agent-sdk/mcp                      |
| Custom Tools             | https://platform.claude.com/docs/en/agent-sdk/custom-tools             |
| Subagents                | https://platform.claude.com/docs/en/agent-sdk/subagents                |
| Slash Commands           | https://platform.claude.com/docs/en/agent-sdk/slash-commands           |
| Skills                   | https://platform.claude.com/docs/en/agent-sdk/skills                   |
| Cost Tracking            | https://platform.claude.com/docs/en/agent-sdk/cost-tracking            |
| Todo Tracking            | https://platform.claude.com/docs/en/agent-sdk/todo-tracking            |
| Plugins                  | https://platform.claude.com/docs/en/agent-sdk/plugins                  |

---

## Installation

### TypeScript/JavaScript

```bash
npm install @anthropic-ai/claude-agent-sdk
```

### Python

```bash
pip install claude-agent-sdk
```

---

## Core Concepts

### Basic Query Pattern (TypeScript)

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

for await (const message of query({
  prompt: 'Find and fix the bug in auth.ts',
  options: {
    allowedTools: ['Read', 'Edit', 'Bash'],
    permissionMode: 'acceptEdits',
  },
})) {
  if (message.type === 'result' && message.subtype === 'success') {
    console.log(message.result);
  }
}
```

### Basic Query Pattern (Python)

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Find and fix the bug in auth.ts",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Edit", "Bash"],
            permission_mode="acceptEdits"
        )
    ):
        if hasattr(message, "result"):
            print(message.result)

asyncio.run(main())
```

---

## TypeScript SDK Reference

### Main Exports

```typescript
import {
  query, // Main function for executing prompts
  tool, // Helper for creating custom MCP tools
  createSdkMcpServer, // Create in-process MCP servers
} from '@anthropic-ai/claude-agent-sdk';
```

### `query()` Function

```typescript
function query(params: Query): AsyncIterable<SDKMessage>;
```

**Parameters:**

| Name      | Type                                 | Required | Description                      |
| --------- | ------------------------------------ | -------- | -------------------------------- |
| `prompt`  | `string \| AsyncIterable<UserInput>` | Yes      | Single prompt or streaming input |
| `options` | `Options`                            | No       | Configuration options            |
| `context` | `Context`                            | No       | Context object with AbortSignal  |

### Options Interface

```typescript
interface Options {
  // Core settings
  model?: 'claude-sonnet-4-20250514' | 'claude-opus-4-20250514' | string;
  maxTurns?: number; // Default: no limit
  cwd?: string; // Working directory

  // Tool permissions
  allowedTools?: string[]; // Tools Claude can use
  disallowedTools?: string[]; // Tools Claude cannot use
  permissionMode?: 'default' | 'acceptEdits' | 'bypassPermissions';

  // MCP servers
  mcpServers?: Record<string, McpServerConfig>;

  // Hooks
  hooks?: HookConfig;

  // Subagents
  agents?: Record<string, AgentDefinition>;

  // Session management
  resume?: string; // Session ID to resume

  // Environment
  env?: Record<string, string>;
}
```

### SDKMessage Types

```typescript
type SDKMessage =
  | SDKSystemMessage // System init/status messages
  | SDKAssistantMessage // Claude's responses
  | SDKUserMessage // User inputs
  | SDKResultMessage; // Final result or error

// Check message types
if (message.type === 'system' && message.subtype === 'init') {
  // Initial system setup
}
if (message.type === 'assistant') {
  // Claude's response with content blocks
  for (const block of message.message.content) {
    if (block.type === 'text') console.log(block.text);
    if (block.type === 'tool_use') console.log(block.name, block.input);
  }
}
if (message.type === 'result') {
  if (message.subtype === 'success') console.log(message.result);
  if (message.subtype === 'error_during_execution')
    console.error(message.error);
}
```

### Tool Input/Output Types

```typescript
// Bash Tool
interface BashInput {
  command: string;
  timeout?: number;
}
interface BashOutput {
  stdout: string;
  stderr: string;
  exitCode: number;
  interrupted: boolean;
}

// Read Tool
interface ReadInput {
  file_path: string;
  offset?: number;
  limit?: number;
}
interface ReadOutput {
  content: string;
  truncated: boolean;
  truncated_characters: number;
}

// Write Tool
interface WriteInput {
  file_path: string;
  content: string;
}
interface WriteOutput {
  file_path: string;
  success: boolean;
}

// Edit Tool
interface EditInput {
  file_path: string;
  old_string: string;
  new_string: string;
  expected_replacements?: number;
}
interface EditOutput {
  file_path: string;
  success: boolean;
  replacement_count: number;
}

// Grep Tool
interface GrepInput {
  pattern: string;
  path?: string;
  include?: string;
}
interface GrepOutput {
  files_searched: number;
  file_matches: FileMatch[];
}

// Glob Tool
interface GlobInput {
  pattern: string;
  path?: string;
}
interface GlobOutput {
  files: string[];
  truncated: boolean;
}

// Task Tool (for subagents)
interface TaskInput {
  description: string;
  subagent_type?: string;
}
interface TaskOutput {
  result: string;
}
```

---

## TypeScript V2 Preview

> **Note:** V2 is an unstable preview API. Use `unstable_v2_*` prefixed functions.

### Session-Based API

```typescript
import {
  unstable_v2_createSession,
  unstable_v2_resumeSession,
  unstable_v2_prompt,
} from '@anthropic-ai/claude-agent-sdk';

// One-shot prompt (simplest usage)
for await (const msg of unstable_v2_prompt('Hello!')) {
  // handle messages
}

// Create a session for multi-turn conversations
await using session = unstable_v2_createSession({
  model: 'claude-sonnet-4-5-20250929',
  allowedTools: ['Read', 'Edit', 'Bash'],
  permissionMode: 'acceptEdits',
});

// Send messages and stream responses
await session.send('Hello!');
for await (const msg of session.stream()) {
  if (msg.type === 'text') console.log(msg.text);
}

// Resume a session later
const sessionId = session.id;
await using resumedSession = unstable_v2_resumeSession(sessionId);
```

### V2 Session Interface

```typescript
interface Session {
  id: string;
  send(message: string): Promise<void>;
  stream(): AsyncIterable<SessionMessage>;
  close(): Promise<void>;
}

type SessionMessage =
  | { type: 'text'; text: string }
  | { type: 'tool_use'; name: string; input: unknown }
  | { type: 'result'; result: string }
  | { type: 'error'; error: string };
```

---

## Python SDK Reference

### Basic Usage

```python
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions

async def main():
    async for message in query(
        prompt="Refactor the database module",
        options=ClaudeAgentOptions(
            model="claude-sonnet-4-20250514",
            max_turns=10,
            allowed_tools=["Read", "Edit", "Write", "Bash"],
            permission_mode="acceptEdits",
            cwd="/path/to/project"
        )
    ):
        print(message)

asyncio.run(main())
```

### ClaudeAgentOptions

```python
class ClaudeAgentOptions:
    model: str | None = None
    max_turns: int | None = None
    cwd: str | None = None
    allowed_tools: list[str] | None = None
    disallowed_tools: list[str] | None = None
    permission_mode: str | None = None  # "default" | "acceptEdits" | "bypassPermissions"
    mcp_servers: dict[str, McpServerConfig] | None = None
    hooks: dict[str, list[HookMatcher]] | None = None
    agents: dict[str, AgentDefinition] | None = None
    resume: str | None = None
    env: dict[str, str] | None = None
```

---

## Hooks System

Hooks intercept agent execution at key points for validation, logging, security, and customization.

### Available Hooks

| Hook                 | Python | TypeScript | Trigger               | Use Case                 |
| -------------------- | ------ | ---------- | --------------------- | ------------------------ |
| `PreToolUse`         | ✓      | ✓          | Before tool execution | Block dangerous commands |
| `PostToolUse`        | ✓      | ✓          | After tool execution  | Audit/log tool calls     |
| `PostToolUseFailure` | ✗      | ✓          | Tool execution failed | Error handling           |
| `UserPromptSubmit`   | ✓      | ✓          | User prompt submitted | Inject context           |
| `Stop`               | ✓      | ✓          | Agent execution stops | Save state               |
| `SubagentStart`      | ✗      | ✓          | Subagent initialized  | Track spawning           |
| `SubagentStop`       | ✓      | ✓          | Subagent completed    | Aggregate results        |
| `PreCompact`         | ✓      | ✓          | Before compaction     | Archive transcript       |
| `PermissionRequest`  | ✗      | ✓          | Permission prompt     | Custom approval          |
| `SessionStart`       | ✗      | ✓          | Session initialized   | Setup logging            |
| `SessionEnd`         | ✗      | ✓          | Session terminated    | Cleanup                  |
| `Notification`       | ✗      | ✓          | Agent status messages | External notifications   |

### Hook Callback Structure

```typescript
// TypeScript
const myHook: HookCallback = async (
  input: HookInput, // Event details
  toolUseId: string | null, // Correlate PreToolUse/PostToolUse
  context: { signal: AbortSignal } // For cancellation
) => {
  // Return empty to allow
  return {};

  // Or return with hookSpecificOutput to control
  return {
    hookSpecificOutput: {
      hookEventName: input.hook_event_name,
      permissionDecision: 'deny', // 'allow' | 'deny' | 'ask'
      permissionDecisionReason: 'Blocked for security',
    },
  };
};
```

```python
# Python
async def my_hook(input_data, tool_use_id, context):
    # Allow operation
    return {}

    # Block operation
    return {
        'hookSpecificOutput': {
            'hookEventName': input_data['hook_event_name'],
            'permissionDecision': 'deny',
            'permissionDecisionReason': 'Blocked for security'
        }
    }
```

### Hook Configuration

```typescript
// TypeScript
const options = {
  hooks: {
    PreToolUse: [
      { matcher: 'Bash', hooks: [blockDangerousCommands] },
      { matcher: 'Write|Edit', hooks: [validateFilePaths] },
    ],
    PostToolUse: [
      { hooks: [auditLogger] }, // No matcher = runs for all tools
    ],
  },
};
```

```python
# Python
options = ClaudeAgentOptions(
    hooks={
        'PreToolUse': [
            HookMatcher(matcher='Bash', hooks=[block_dangerous]),
            HookMatcher(matcher='Write|Edit', hooks=[validate_files])
        ]
    }
)
```

### Common Hook Patterns

#### Block Dangerous Commands

```typescript
const blockDangerous: HookCallback = async (input) => {
  const command = (input as PreToolUseHookInput).tool_input?.command || '';
  if (command.includes('rm -rf /')) {
    return {
      hookSpecificOutput: {
        hookEventName: input.hook_event_name,
        permissionDecision: 'deny',
        permissionDecisionReason: 'Dangerous command blocked',
      },
    };
  }
  return {};
};
```

#### Auto-Approve Read-Only Tools

```typescript
const autoApproveReadOnly: HookCallback = async (input) => {
  const readOnlyTools = ['Read', 'Glob', 'Grep', 'LS'];
  if (readOnlyTools.includes((input as PreToolUseHookInput).tool_name)) {
    return {
      hookSpecificOutput: {
        hookEventName: input.hook_event_name,
        permissionDecision: 'allow',
      },
    };
  }
  return {};
};
```

#### Modify Tool Input

```typescript
const redirectToSandbox: HookCallback = async (input) => {
  const preInput = input as PreToolUseHookInput;
  if (preInput.tool_name === 'Write') {
    const originalPath = preInput.tool_input?.file_path || '';
    return {
      hookSpecificOutput: {
        hookEventName: input.hook_event_name,
        permissionDecision: 'allow',
        updatedInput: {
          ...preInput.tool_input,
          file_path: `/sandbox${originalPath}`,
        },
      },
    };
  }
  return {};
};
```

---

## MCP Integration

Connect to external tools via Model Context Protocol (MCP).

### MCP Transport Types

| Type       | Use Case            | Configuration                    |
| ---------- | ------------------- | -------------------------------- |
| `stdio`    | Local processes     | `command`, `args`, `env`         |
| `http`     | HTTP endpoints      | `type: "http"`, `url`, `headers` |
| `sse`      | Streaming endpoints | `type: "sse"`, `url`, `headers`  |
| SDK Server | In-process tools    | `createSdkMcpServer()`           |

### stdio Server (Local Process)

```typescript
const options = {
  mcpServers: {
    github: {
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-github'],
      env: { GITHUB_TOKEN: process.env.GITHUB_TOKEN },
    },
  },
  allowedTools: ['mcp__github__list_issues', 'mcp__github__search_issues'],
};
```

### HTTP/SSE Server (Remote)

```typescript
const options = {
  mcpServers: {
    'remote-api': {
      type: 'sse', // or "http" for non-streaming
      url: 'https://api.example.com/mcp/sse',
      headers: {
        Authorization: `Bearer ${process.env.API_TOKEN}`,
      },
    },
  },
  allowedTools: ['mcp__remote-api__*'], // Wildcard allows all tools
};
```

### Config File (`.mcp.json`)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/me/projects"
      ]
    }
  }
}
```

### MCP Tool Naming

Tools follow pattern: `mcp__<server-name>__<tool-name>`

Example: Server `github` with tool `list_issues` → `mcp__github__list_issues`

### Tool Search (Auto-Load)

For many tools, use `ENABLE_TOOL_SEARCH` to load on-demand:

```typescript
const options = {
  mcpServers: {
    /* many servers */
  },
  env: {
    ENABLE_TOOL_SEARCH: 'auto:5', // Enable at 5% context threshold
  },
};
```

---

## Custom Tools

Create in-process MCP tools with `createSdkMcpServer()` and `tool()`.

```typescript
import {
  query,
  tool,
  createSdkMcpServer,
} from '@anthropic-ai/claude-agent-sdk';
import { z } from 'zod';

const customServer = createSdkMcpServer({
  name: 'my-tools',
  version: '1.0.0',
  tools: [
    tool(
      'get_weather',
      'Get current temperature for a location',
      {
        latitude: z.number().describe('Latitude coordinate'),
        longitude: z.number().describe('Longitude coordinate'),
      },
      async (args) => {
        const response = await fetch(
          `https://api.open-meteo.com/v1/forecast?latitude=${args.latitude}&longitude=${args.longitude}&current=temperature_2m`
        );
        const data = await response.json();
        return {
          content: [
            {
              type: 'text',
              text: `Temperature: ${data.current.temperature_2m}°C`,
            },
          ],
        };
      }
    ),
  ],
});

// Use with streaming input (required for MCP servers)
async function* generateMessages() {
  yield {
    type: 'user' as const,
    message: { role: 'user' as const, content: "What's the weather in SF?" },
  };
}

for await (const message of query({
  prompt: generateMessages(),
  options: {
    mcpServers: { 'my-tools': customServer },
    allowedTools: ['mcp__my-tools__get_weather'],
  },
})) {
  if (message.type === 'result' && message.subtype === 'success') {
    console.log(message.result);
  }
}
```

---

## Subagents

Spawn separate agent instances for isolated, parallel task execution.

### Creating Subagents

```typescript
// TypeScript
const options = {
  allowedTools: ['Read', 'Grep', 'Glob', 'Task'], // Task required for subagents
  agents: {
    'code-reviewer': {
      description: 'Expert code reviewer for security and quality',
      prompt: `You are a code review specialist. Focus on:
        - Security vulnerabilities
        - Performance issues
        - Code quality`,
      tools: ['Read', 'Grep', 'Glob'], // Read-only access
      model: 'sonnet', // Optional: "sonnet" | "opus" | "haiku" | "inherit"
    },
  },
};
```

```python
# Python
options = ClaudeAgentOptions(
    allowed_tools=["Read", "Grep", "Glob", "Task"],
    agents={
        "code-reviewer": AgentDefinition(
            description="Expert code reviewer",
            prompt="You are a code review specialist...",
            tools=["Read", "Grep", "Glob"],
            model="sonnet"
        )
    }
)
```

### AgentDefinition

| Field         | Type     | Required | Description                             |
| ------------- | -------- | -------- | --------------------------------------- |
| `description` | string   | Yes      | When to use this agent                  |
| `prompt`      | string   | Yes      | System prompt for the agent             |
| `tools`       | string[] | No       | Allowed tools (inherits all if omitted) |
| `model`       | string   | No       | Model override                          |

### Invoking Subagents

**Automatic:** Claude decides based on `description`

**Explicit:** Include agent name in prompt:

```
"Use the code-reviewer agent to analyze the authentication module"
```

### Detecting Subagent Invocation

```typescript
for await (const message of query({ prompt, options })) {
  if (message.type === 'assistant') {
    for (const block of message.message.content) {
      if (block.type === 'tool_use' && block.name === 'Task') {
        console.log('Subagent invoked:', block.input.subagent_type);
      }
    }
  }
  // Messages from within subagent have parent_tool_use_id
  if ('parent_tool_use_id' in message && message.parent_tool_use_id) {
    console.log('Message from subagent');
  }
}
```

### Resuming Subagents

```typescript
let sessionId: string;
let agentId: string;

// First query - capture IDs
for await (const message of query({
  prompt: 'Use Explore agent...',
  options,
})) {
  if ('session_id' in message) sessionId = message.session_id;
  // Extract agentId from message content
}

// Resume session with follow-up
for await (const message of query({
  prompt: `Resume agent ${agentId} and analyze further`,
  options: { ...options, resume: sessionId },
})) {
  // Continue with subagent context
}
```

---

## Permissions

### Permission Modes

| Mode                  | Description                                       |
| --------------------- | ------------------------------------------------- |
| `"default"`           | Prompts for confirmation on tool use              |
| `"acceptEdits"`       | Auto-approves most tools, prompts for destructive |
| `"bypassPermissions"` | Skips all prompts (use with caution!)             |

### allowedTools & disallowedTools

```typescript
const options = {
  // Only allow specific tools
  allowedTools: ['Read', 'Edit', 'Bash', 'mcp__github__*'],

  // Block specific tools (takes precedence)
  disallowedTools: ['Bash'],
};
```

### Wildcards

- `mcp__github__*` - All tools from github server
- `*` - All tools (when used alone in allowedTools)

---

## Sessions

### Resume a Session

```typescript
// First query
let sessionId: string;
for await (const message of query({ prompt: 'Start task' })) {
  if ('session_id' in message) sessionId = message.session_id;
}

// Resume later
for await (const message of query({
  prompt: 'Continue the task',
  options: { resume: sessionId },
})) {
  // Continues with full context
}
```

### Session Storage

Sessions are stored in:

- Linux/macOS: `~/.config/claude-agent/sessions/`
- Windows: `%LOCALAPPDATA%\claude-agent\sessions\`

---

## Built-in Tools

| Tool        | Description             | Input Types                             |
| ----------- | ----------------------- | --------------------------------------- |
| `Bash`      | Execute shell commands  | `command`, `timeout`                    |
| `Read`      | Read file contents      | `file_path`, `offset`, `limit`          |
| `Write`     | Write file contents     | `file_path`, `content`                  |
| `Edit`      | Replace text in files   | `file_path`, `old_string`, `new_string` |
| `Glob`      | Find files by pattern   | `pattern`, `path`                       |
| `Grep`      | Search file contents    | `pattern`, `path`, `include`            |
| `LS`        | List directory contents | `path`                                  |
| `Task`      | Spawn subagent          | `description`, `subagent_type`          |
| `WebSearch` | Search the web          | `query`                                 |
| `WebFetch`  | Fetch URL content       | `url`                                   |
| `TodoRead`  | Read todo list          | -                                       |
| `TodoWrite` | Update todo list        | `todos`                                 |

---

## Error Handling

```typescript
for await (const message of query({ prompt, options })) {
  if (message.type === 'result') {
    switch (message.subtype) {
      case 'success':
        console.log('Success:', message.result);
        break;
      case 'error_during_execution':
        console.error('Execution error:', message.error);
        break;
      case 'error_max_turns_reached':
        console.warn('Max turns reached');
        break;
      case 'error_during_hook':
        console.error('Hook error:', message.error);
        break;
    }
  }
}
```

---

## Environment Variables

| Variable                                   | Description                       |
| ------------------------------------------ | --------------------------------- |
| `ANTHROPIC_API_KEY`                        | API key for Anthropic             |
| `ENABLE_TOOL_SEARCH`                       | `auto`, `auto:N`, `true`, `false` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS`            | Override max output tokens        |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Disable telemetry                 |

---

## Streaming Input Mode

For real-time user interaction or when using MCP servers:

```typescript
async function* streamingInput(): AsyncIterable<UserInput> {
  // Initial prompt
  yield {
    type: 'user',
    message: { role: 'user', content: 'Start analyzing the codebase' },
  };

  // Wait for user input (implement your own logic)
  const userResponse = await getUserInput();
  yield {
    type: 'user',
    message: { role: 'user', content: userResponse },
  };
}

for await (const message of query({
  prompt: streamingInput(),
  options: {
    /* ... */
  },
})) {
  // Handle messages
}
```

---

## Best Practices

1. **Use specific allowedTools** - Don't grant more access than needed
2. **Implement hooks for security** - Block dangerous commands before execution
3. **Set maxTurns** - Prevent runaway agents in production
4. **Use subagents for isolation** - Keep focused contexts, run tasks in parallel
5. **Handle errors gracefully** - Check result subtypes for different error states
6. **Use streaming for real-time updates** - Better UX and resource management
7. **Resume sessions** - Maintain context across interactions
8. **Test with `acceptEdits` first** - Before using `bypassPermissions`

---

## Session Management

Sessions allow you to continue conversations across multiple interactions while maintaining full context.

### Getting Session ID

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

let sessionId: string | undefined;

const response = query({
  prompt: 'Help me build a web application',
  options: { model: 'claude-sonnet-4-5' },
});

for await (const message of response) {
  // First message is system init with session ID
  if (message.type === 'system' && message.subtype === 'init') {
    sessionId = message.session_id;
    console.log(`Session started with ID: ${sessionId}`);
  }
}
```

### Resuming Sessions

```typescript
const response = query({
  prompt:
    'Continue implementing the authentication system from where we left off',
  options: {
    resume: 'session-xyz', // Session ID from previous conversation
    model: 'claude-sonnet-4-5',
  },
});
```

### Forking Sessions

Use `forkSession: true` to create a new branch from a resume point:

| Behavior         | forkSession: false (default) | forkSession: true              |
| ---------------- | ---------------------------- | ------------------------------ |
| Session ID       | Same as original             | New ID generated               |
| History          | Appends to original          | Creates new branch             |
| Original Session | Modified                     | Preserved unchanged            |
| Use Case         | Continue linear conversation | Branch to explore alternatives |

```typescript
// Fork to try a different approach
const forkedResponse = query({
  prompt: "Now let's redesign this as a GraphQL API instead",
  options: {
    resume: sessionId,
    forkSession: true, // Creates new session ID
    model: 'claude-sonnet-4-5',
  },
});
```

---

## File Checkpointing

Track file modifications and rewind to any previous state. Works with Write, Edit, and NotebookEdit tools.

### Setup

```python
import os
from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions

options = ClaudeAgentOptions(
    enable_file_checkpointing=True,
    permission_mode="acceptEdits",
    extra_args={"replay-user-messages": None},  # Required for checkpoint UUIDs
    env={**os.environ, "CLAUDE_CODE_ENABLE_SDK_FILE_CHECKPOINTING": "1"}
)
```

### Capture Checkpoint UUID

```python
checkpoint_id = None
session_id = None

async for message in client.receive_response():
    # First user message UUID is your restore point
    if isinstance(message, UserMessage) and message.uuid:
        checkpoint_id = message.uuid
    if isinstance(message, ResultMessage):
        session_id = message.session_id
```

### Rewind Files

```python
# Resume session with empty prompt, then rewind
async with ClaudeSDKClient(ClaudeAgentOptions(
    enable_file_checkpointing=True,
    resume=session_id
)) as client:
    await client.query("")  # Empty prompt opens connection
    async for message in client.receive_response():
        await client.rewind_files(checkpoint_id)
        break
```

**Limitations:**

- Only Write/Edit/NotebookEdit tools tracked (not Bash commands)
- Checkpoints tied to session that created them
- Directory operations not undone by rewinding

---

## Structured Outputs

Return validated JSON from agent workflows using JSON Schema, Zod, or Pydantic.

### Basic Usage

```typescript
import { query } from '@anthropic-ai/claude-agent-sdk';

const schema = {
  type: 'object',
  properties: {
    company_name: { type: 'string' },
    founded_year: { type: 'number' },
    headquarters: { type: 'string' },
  },
  required: ['company_name'],
};

for await (const message of query({
  prompt: 'Research Anthropic and provide key company information',
  options: {
    outputFormat: {
      type: 'json_schema',
      schema: schema,
    },
  },
})) {
  if (message.type === 'result' && message.structured_output) {
    console.log(message.structured_output);
    // { company_name: "Anthropic", founded_year: 2021, headquarters: "San Francisco, CA" }
  }
}
```

### With Zod (Type-Safe)

```typescript
import { z } from 'zod'

const FeaturePlan = z.object({
  feature_name: z.string(),
  summary: z.string(),
  steps: z.array(z.object({
    step_number: z.number(),
    description: z.string(),
    estimated_complexity: z.enum(['low', 'medium', 'high'])
  })),
  risks: z.array(z.string())
})

const schema = z.toJSONSchema(FeaturePlan)

// In query options:
outputFormat: { type: 'json_schema', schema: schema }

// Parse response:
const parsed = FeaturePlan.safeParse(message.structured_output)
if (parsed.success) {
  const plan: FeaturePlan = parsed.data
}
```

### Error Handling

```typescript
if (msg.type === 'result') {
  if (msg.subtype === 'success' && msg.structured_output) {
    console.log(msg.structured_output);
  } else if (msg.subtype === 'error_max_structured_output_retries') {
    console.error('Could not produce valid output');
  }
}
```

---

## Hosting Patterns

The SDK maintains conversational state and executes commands in a persistent environment.

### System Requirements

- **Runtime**: Python 3.10+ or Node.js 18+
- **CLI**: `npm install -g @anthropic-ai/claude-code`
- **Resources**: 1GiB RAM, 5GiB disk, 1 CPU (recommended)
- **Network**: Outbound HTTPS to `api.anthropic.com`

### Deployment Patterns

| Pattern               | Description                                            | Use Case                                |
| --------------------- | ------------------------------------------------------ | --------------------------------------- |
| Ephemeral Sessions    | New container per task, destroyed when complete        | Bug fixes, invoice processing           |
| Long-Running Sessions | Persistent container instances with multiple processes | Email agents, site builders             |
| Hybrid Sessions       | Ephemeral containers hydrated with history             | Personal project manager, deep research |
| Single Containers     | Multiple SDK processes in one container                | Agent simulations                       |

### Sandbox Providers

- [Modal Sandbox](https://modal.com/docs/guide/sandbox)
- [Cloudflare Sandboxes](https://github.com/cloudflare/sandbox-sdk)
- [Daytona](https://www.daytona.io/)
- [E2B](https://e2b.dev/)
- [Fly Machines](https://fly.io/docs/machines/)
- [Vercel Sandbox](https://vercel.com/docs/functions/sandbox)

---

## Secure Deployment

### Isolation Technologies

| Technology          | Isolation Strength     | Performance | Complexity  |
| ------------------- | ---------------------- | ----------- | ----------- |
| Sandbox runtime     | Good (secure defaults) | Very low    | Low         |
| Containers (Docker) | Setup dependent        | Low         | Medium      |
| gVisor              | Excellent              | Medium/High | Medium      |
| VMs (Firecracker)   | Excellent              | High        | Medium/High |

### Hardened Docker Configuration

```bash
docker run \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --security-opt seccomp=/path/to/seccomp-profile.json \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=100m \
  --network none \
  --memory 2g \
  --pids-limit 100 \
  --user 1000:1000 \
  -v /path/to/code:/workspace:ro \
  -v /var/run/proxy.sock:/var/run/proxy.sock:ro \
  agent-image
```

### Credential Management via Proxy

```bash
# Route sampling requests through proxy
export ANTHROPIC_BASE_URL="http://localhost:8080"

# Or system-wide
export HTTP_PROXY="http://localhost:8080"
export HTTPS_PROXY="http://localhost:8080"
```

### Files to Exclude from Mounts

| File                 | Risk                   |
| -------------------- | ---------------------- |
| `.env`, `.env.local` | API keys, secrets      |
| `~/.git-credentials` | Git passwords          |
| `~/.aws/credentials` | AWS access keys        |
| `~/.kube/config`     | Kubernetes credentials |
| `*.pem`, `*.key`     | Private keys           |

---

## System Prompts

### Methods of Modification

1. **CLAUDE.md files** - Project-level instructions in `.claude/CLAUDE.md`
2. **Output styles** - Saved configurations in `~/.claude/output-styles/`
3. **systemPrompt with append** - Add to default prompt
4. **Custom systemPrompt** - Complete control

### Using CLAUDE.md

```typescript
// Must specify settingSources to load CLAUDE.md
const response = query({
  prompt: 'Add a new React component',
  options: {
    systemPrompt: { type: 'preset', preset: 'claude_code' },
    settingSources: ['project'], // Required to load CLAUDE.md
  },
});
```

### systemPrompt with Append

```typescript
options: {
  systemPrompt: {
    type: "preset",
    preset: "claude_code",
    append: "Always include detailed docstrings and type hints in Python code."
  }
}
```

### Custom System Prompt

```typescript
options: {
  systemPrompt: `You are a Python coding specialist.
Follow these guidelines:
- Write clean, well-documented code
- Use type hints for all functions
- Include comprehensive docstrings`;
}
```

---

## Cost Tracking

### Usage Fields

| Field                         | Description                         |
| ----------------------------- | ----------------------------------- |
| `input_tokens`                | Base input tokens processed         |
| `output_tokens`               | Tokens generated in response        |
| `cache_creation_input_tokens` | Tokens used to create cache         |
| `cache_read_input_tokens`     | Tokens read from cache              |
| `total_cost_usd`              | Total cost (only in result message) |

### Important Rules

1. **Same ID = Same Usage** - All messages with same `id` report identical usage
2. **Charge Once Per Step** - Don't charge for each individual message
3. **Result Message Has Cumulative Usage** - `total_cost_usd` is authoritative

### Per-Model Usage

```typescript
// result.modelUsage is a map of model name to ModelUsage
for (const [modelName, usage] of Object.entries(result.modelUsage)) {
  console.log(`${modelName}: $${usage.costUSD.toFixed(4)}`);
  console.log(`  Input tokens: ${usage.inputTokens}`);
  console.log(`  Output tokens: ${usage.outputTokens}`);
}
```

---

## Agent Skills

Skills are specialized capabilities Claude autonomously invokes when relevant. Packaged as `SKILL.md` files.

### Skill Locations

- **Project**: `.claude/skills/` (shared via git)
- **User**: `~/.claude/skills/` (personal)
- **Plugin**: Bundled with installed plugins

### Using Skills in SDK

```python
options = ClaudeAgentOptions(
    cwd="/path/to/project",  # Project with .claude/skills/
    setting_sources=["user", "project"],  # Required to load Skills
    allowed_tools=["Skill", "Read", "Write", "Bash"]  # Enable Skill tool
)
```

**Important**: By default, SDK does not load filesystem settings. Must explicitly configure `settingSources`.

---

## Slash Commands

Commands starting with `/` for controlling Claude Code sessions.

### Discovering Commands

```typescript
for await (const message of query({
  prompt: 'Hello Claude',
  options: { maxTurns: 1 },
})) {
  if (message.type === 'system' && message.subtype === 'init') {
    console.log('Available slash commands:', message.slash_commands);
    // Example: ["/compact", "/clear", "/help"]
  }
}
```

### Common Commands

- `/compact` - Compact conversation history
- `/clear` - Clear conversation and start fresh

### Creating Custom Commands

Create `.claude/commands/refactor.md`:

```markdown
---
allowed-tools: Read, Grep, Glob
description: Refactor code for readability
---

Refactor the selected code to improve readability and maintainability.
Focus on clean code principles and best practices.
```

### With Arguments

```markdown
---
argument-hint: [issue-number] [priority]
description: Fix a GitHub issue
---

Fix issue #$1 with priority $2.
Check the issue description and implement the necessary changes.
```

Usage: `/fix-issue 123 high`

---

## Plugins

Extend Claude with commands, agents, skills, hooks, and MCP servers.

### Loading Plugins

```typescript
for await (const message of query({
  prompt: 'Hello',
  options: {
    plugins: [
      { type: 'local', path: './my-plugin' },
      { type: 'local', path: '/absolute/path/to/another-plugin' },
    ],
  },
})) {
  // Plugin features now available
}
```

### Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json     # Required: plugin manifest
├── commands/           # Custom slash commands
├── agents/             # Custom agents
├── skills/             # Agent Skills
├── hooks/              # Event handlers
└── .mcp.json           # MCP server definitions
```

### Using Plugin Commands

Commands are namespaced: `plugin-name:command-name`

```typescript
prompt: '/my-plugin:greet'; // Use plugin command with namespace
```

---

## User Input & Approvals

### canUseTool Callback

Fires when Claude needs permission or asks clarifying questions.

```python
async def can_use_tool(tool_name: str, input_data: dict, context: ToolPermissionContext):
    if tool_name == "AskUserQuestion":
        return await handle_clarifying_questions(input_data)

    # Auto-approve read operations
    if tool_name in ["Read", "Grep", "Glob"]:
        return PermissionResultAllow(updated_input=input_data)

    # Prompt for write operations
    user_input = input(f"Allow {tool_name}? (y/n): ")
    if user_input.lower() == 'y':
        return PermissionResultAllow(updated_input=input_data)
    return PermissionResultDeny(message="User denied")
```

### AskUserQuestion Tool Format

**Input:**

```json
{
  "questions": [
    {
      "question": "How should I format?",
      "header": "Format",
      "options": [
        { "label": "Summary", "description": "Brief overview" },
        { "label": "Detailed", "description": "Full explanation" }
      ],
      "multiSelect": false
    }
  ]
}
```

**Response:**

```python
return PermissionResultAllow(updated_input={
    "questions": input_data.get("questions", []),
    "answers": {"How should I format?": "Summary"}
})
```

---

## Permission Modes Reference

| Mode                | Behavior                                        |
| ------------------- | ----------------------------------------------- |
| `default`           | Prompts for confirmation on file edits          |
| `acceptEdits`       | Auto-approves file edits + mkdir/touch/rm/mv/cp |
| `bypassPermissions` | All tools auto-approved (CAUTION!)              |
| `plan`              | No tool execution, planning only                |

**Permission Evaluation Order:**

1. Hooks (can allow/deny/modify)
2. Permission rules (settings.json)
3. Permission mode
4. canUseTool callback

---

_Last updated from documentation at platform.claude.com/docs/en/agent-sdk/_
