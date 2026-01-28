---
description: Add a specific feature to an existing Claude Agent SDK application. Use arguments like streaming, tools, mcp, sessions, subagents, hooks, skills, commands, plugins, production, checkpointing, structured-outputs, thinking, caching, batch, vision, web-search, code-execution, computer-use, memory.
argument-hint: <feature> [options]
---

## Add Feature to Claude Agent SDK Application

**Feature**: $ARGUMENTS

Add a specific capability to your existing Claude Agent SDK project.

---

## Available Features

| Feature | Agent | Description |
|---------|-------|-------------|
| `streaming` | setup | Streaming input/output with real-time responses |
| `tools` | tools | Custom tools with Zod schemas and createSdkMcpServer() |
| `mcp` | mcp | MCP server integration (STDIO, HTTP, SSE) |
| `sessions` | persistence | Session management with resume capability |
| `subagents` | subagents | Multi-agent architecture with Task tool |
| `hooks` | production | Pre/Post tool use hooks for security and logging |
| `skills` | tools | Agent Skills (.claude/skills/) |
| `commands` | tools | Slash commands (.claude/commands/) |
| `plugins` | tools | Plugin architecture for distribution |
| `production` | production | Full production setup (permissions, security, hosting) |
| `checkpointing` | persistence | File checkpointing with restore capability |
| `structured-outputs` | batch-vision | JSON schema validated outputs |
| `thinking` | thinking-optimization | Extended thinking for deep reasoning |
| `caching` | thinking-optimization | Prompt caching for 90% cost reduction |
| `batch` | batch-vision | Batch processing for 50% cost reduction |
| `vision` | batch-vision | Image understanding capabilities |
| `web-search` | builtin-tools | Real-time web search |
| `code-execution` | builtin-tools | Sandboxed Python execution |
| `computer-use` | builtin-tools | UI automation with screenshots |
| `memory` | builtin-tools | Persistent knowledge across sessions |
| `cost-tracking` | production | Usage monitoring and budget limits |
| `todo-tracking` | persistence | Task management with TodoRead/TodoWrite |

---

## Feature: streaming

```
Task(agent-sdk-setup-agent) Add streaming capabilities:
- Convert single prompt to AsyncIterable<UserInput>
- Handle real-time message processing
- Implement progress indicators
- Add cancellation with AbortController
```

**Code Pattern:**
```typescript
async function* streamingInput(): AsyncIterable<UserInput> {
  yield { type: 'user', content: 'Initial prompt' };
  // Can yield more messages based on user interaction
}

for await (const message of query({
  prompt: streamingInput(),
  options: { /* ... */ }
})) {
  if (message.type === 'assistant') {
    // Real-time response handling
  }
}
```

---

## Feature: tools

```
Task(agent-sdk-tools-agent) Add custom tools:
- Create tool schemas with Zod
- Implement tool handlers with createSdkMcpServer()
- Configure allowedTools
- Add tool input validation
```

**Code Pattern:**
```typescript
import { tool, createSdkMcpServer } from '@anthropic-ai/claude-agent-sdk';
import { z } from 'zod';

const customServer = createSdkMcpServer({
  name: 'my-tools',
  tools: [
    tool({
      name: 'my_tool',
      description: 'What this tool does',
      schema: z.object({
        param: z.string().describe('Parameter description')
      }),
      handler: async ({ param }) => {
        return { result: `Processed: ${param}` };
      }
    })
  ]
});
```

---

## Feature: mcp

```
Task(agent-sdk-mcp-agent) Add MCP server integration:
- Choose transport type (STDIO, HTTP, SSE, or SDK)
- Configure server connection
- Set up tool allowlists
- Create .mcp.json configuration
```

**STDIO Server (Local Process):**
```typescript
mcpServers: {
  'github': {
    command: 'npx',
    args: ['-y', '@modelcontextprotocol/server-github'],
    env: { GITHUB_TOKEN: process.env.GITHUB_TOKEN }
  }
}
```

**HTTP Server (Remote):**
```typescript
mcpServers: {
  'remote-api': {
    type: 'http',
    url: 'https://api.example.com/mcp',
    headers: { 'Authorization': `Bearer ${process.env.API_KEY}` }
  }
}
```

---

## Feature: sessions

```
Task(agent-sdk-persistence-agent) Add session management:
- Capture session ID from init message
- Store session IDs for later resumption
- Implement resume with forkSession option
- Handle multi-turn conversations
```

**Code Pattern:**
```typescript
let sessionId: string;

for await (const message of query({ prompt, options })) {
  if (message.type === 'system' && message.subtype === 'init') {
    sessionId = message.session_id;
  }
}

// Resume later
for await (const message of query({
  prompt: 'Continue...',
  options: { resume: sessionId }
})) { /* ... */ }
```

---

## Feature: subagents

```
Task(agent-sdk-subagents-agent) Add subagent architecture:
- Define agent roles with descriptions and prompts
- Choose pattern (orchestrator, pipeline, hierarchical)
- Configure Task tool
- Set up inter-agent communication
```

**Code Pattern:**
```typescript
options: {
  allowedTools: ['Read', 'Write', 'Task'],
  subagents: {
    'researcher': {
      description: 'Research topics using web search',
      prompt: 'You are a research specialist...',
      tools: ['Read', 'WebSearch', 'WebFetch']
    },
    'coder': {
      description: 'Implement code solutions',
      prompt: 'You are a coding specialist...',
      tools: ['Read', 'Write', 'Edit', 'Bash']
    }
  }
}
```

---

## Feature: hooks

```
Task(agent-sdk-production-agent) Add execution hooks:
- PreToolUse: Block dangerous commands, validate inputs
- PostToolUse: Log operations, audit trail
- Stop: Save state on completion
- Notification: External alerts
```

**Code Pattern:**
```typescript
hooks: {
  PreToolUse: async (input) => {
    const cmd = input.tool_input?.command || '';
    if (cmd.includes('rm -rf')) {
      return { decision: 'block', reason: 'Dangerous command blocked' };
    }
    return {};
  },
  PostToolUse: async (input) => {
    console.log(`Tool ${input.tool_name} completed`);
    return {};
  }
}
```

---

## Feature: skills

```
Task(agent-sdk-tools-agent) Add Agent Skills:
- Create .claude/skills/ directory
- Define SKILL.md with description and instructions
- Add templates and examples
- Configure settingSources to load skills
```

**Skill Structure:**
```
.claude/skills/
└── data-analysis/
    ├── SKILL.md
    ├── templates/
    │   └── analysis-report.md
    └── examples/
        └── sample-analysis.py
```

---

## Feature: commands

```
Task(agent-sdk-tools-agent) Add slash commands:
- Create .claude/commands/ directory
- Define command with description and allowed-tools
- Support arguments with $1, $2, etc.
- Configure settingSources to load commands
```

**Command Example (.claude/commands/analyze.md):**
```markdown
---
allowed-tools: Read, Grep, Glob
argument-hint: <file-path>
description: Analyze a file for issues
---

Analyze $1 for potential issues, bugs, and improvements.
```

---

## Feature: plugins

```
Task(agent-sdk-tools-agent) Create plugin structure:
- Set up .claude-plugin/plugin.json manifest
- Organize commands/, agents/, skills/
- Add hooks/ for event handlers
- Configure .mcp.json for bundled MCP servers
```

---

## Feature: production

```
Task(agent-sdk-production-agent) Full production setup:
- Configure permissionMode (acceptEdits or bypassPermissions)
- Implement security hooks
- Set up cost tracking with limits
- Create Dockerfile with hardening
- Add monitoring and logging
```

---

## Feature: checkpointing

```
Task(agent-sdk-persistence-agent) Add file checkpointing:
- Enable with enable_file_checkpointing option
- Capture checkpoint UUIDs from messages
- Implement rewind functionality
- Handle checkpoint storage
```

---

## Feature: structured-outputs

```
Task(sdk-batch-vision-agent) Add structured outputs:
- Define JSON schema for output
- Configure outputFormat in options
- Parse and validate responses
- Handle schema validation errors
```

---

## Feature: thinking

```
Task(sdk-thinking-optimization-agent) Add extended thinking:
- Configure thinking budget tokens
- Handle thinking blocks in responses
- Implement thinking summaries
- Balance cost vs reasoning depth
```

---

## Feature: caching

```
Task(sdk-thinking-optimization-agent) Add prompt caching:
- Structure prompts for cache efficiency
- Monitor cache_read_input_tokens
- Implement cache warmup strategies
- Track cost savings
```

---

## Feature: batch

```
Task(sdk-batch-vision-agent) Add batch processing:
- Prepare batch request files
- Submit to Batch API
- Poll for completion
- Process results with 50% cost savings
```

---

## Feature: vision

```
Task(sdk-batch-vision-agent) Add vision capabilities:
- Handle image inputs (base64 or URL)
- Process multiple images
- Extract structured data from images
- Implement image analysis workflows
```

---

## Feature: web-search

```
Task(sdk-builtin-tools-agent) Add web search:
- Enable WebSearch in allowedTools
- Handle search results
- Implement fact-checking workflows
- Process real-time information
```

---

## Feature: code-execution

```
Task(sdk-builtin-tools-agent) Add code execution:
- Configure sandboxed Python environment
- Handle execution results
- Implement data analysis workflows
- Process generated outputs
```

---

## Feature: computer-use

```
Task(sdk-builtin-tools-agent) Add computer use:
- Configure UI automation
- Handle screenshot responses
- Implement interaction workflows
- Set up coordinate-based actions
```

---

## Feature: memory

```
Task(sdk-builtin-tools-agent) Add memory tool:
- Configure persistent memory
- Implement save/retrieve patterns
- Build knowledge accumulation
- Handle memory context
```

---

## Feature: cost-tracking

```
Task(agent-sdk-production-agent) Add cost tracking:
- Monitor token usage per message
- Track total_cost_usd from results
- Implement budget limits
- Set up usage alerts
```

---

## Feature: todo-tracking

```
Task(agent-sdk-persistence-agent) Add todo tracking:
- Enable TodoRead/TodoWrite tools
- Implement task state management
- Track progress across sessions
- Build task workflows
```

---

## Usage Examples

```bash
# Add MCP integration
/claude-agent-sdk:add mcp

# Add subagents
/claude-agent-sdk:add subagents

# Add production features
/claude-agent-sdk:add production

# Add extended thinking
/claude-agent-sdk:add thinking

# Add multiple features
/claude-agent-sdk:add streaming
/claude-agent-sdk:add tools
/claude-agent-sdk:add sessions
```
