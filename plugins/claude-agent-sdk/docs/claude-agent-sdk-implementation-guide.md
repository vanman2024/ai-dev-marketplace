# Claude Agent SDK Implementation Guide

> **Purpose**: Step-by-step guide for building production multi-agent systems. Use alongside `claude-agent-sdk-reference.md` for API details.

---

## Quick Navigation

| Building...                 | Jump To                                                 |
| --------------------------- | ------------------------------------------------------- |
| Single agent with tools     | [Basic Agent Setup](#1-basic-agent-setup)               |
| Multi-agent orchestration   | [Multi-Agent Architecture](#3-multi-agent-architecture) |
| Agent with memory/sessions  | [Stateful Agents](#4-stateful-agents-with-sessions)     |
| Human-in-the-loop workflows | [Approval Workflows](#5-human-in-the-loop-workflows)    |
| Production deployment       | [Production Checklist](#7-production-deployment)        |
| Extended thinking/caching   | [API Features](#10-claude-api-features-beyond-the-sdk)  |

---

## 1. Basic Agent Setup

### Minimum Viable Agent (TypeScript)

```typescript
// agent.ts - Complete working example
import Anthropic from '@anthropic-ai/sdk';
import { Agent, AgentConfig } from '@anthropic-ai/agent-sdk';

const client = new Anthropic(); // Uses ANTHROPIC_API_KEY env var

const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You are a helpful assistant that...`, // Define role clearly
  tools: [], // Add tools below
});

// Run the agent
async function main() {
  const result = await agent.run('Your task here');
  console.log(result.content);
}

main();
```

### Adding Your First Tool

```typescript
// Tools follow this pattern: name, description, input_schema, handler
const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  tools: [
    {
      name: 'search_database',
      description:
        'Search the company database for records. Use when user asks about employees, projects, or resources.',
      input_schema: {
        type: 'object',
        properties: {
          query: { type: 'string', description: 'Search query' },
          table: {
            type: 'string',
            enum: ['employees', 'projects', 'resources'],
            description: 'Which table to search',
          },
          limit: { type: 'number', description: 'Max results (default 10)' },
        },
        required: ['query', 'table'],
      },
      // Handler receives validated input, returns string result
      handler: async (input) => {
        const results = await db.search(
          input.table,
          input.query,
          input.limit || 10
        );
        return JSON.stringify(results, null, 2);
      },
    },
  ],
});
```

### Tool Design Best Practices

```typescript
// ✅ GOOD: Specific, actionable tool
{
  name: "create_calendar_event",
  description: "Creates a calendar event. Returns event ID on success.",
  input_schema: {
    type: "object",
    properties: {
      title: { type: "string" },
      start_time: { type: "string", description: "ISO 8601 format" },
      duration_minutes: { type: "number" },
      attendees: { type: "array", items: { type: "string" } }
    },
    required: ["title", "start_time", "duration_minutes"]
  }
}

// ❌ BAD: Vague tool that agent won't know when to use
{
  name: "do_thing",
  description: "Does a thing",
  input_schema: { type: "object", properties: { data: { type: "string" } } }
}
```

---

## 2. Real-World Single Agent Examples

### Example: Code Review Agent

```typescript
import { Agent } from '@anthropic-ai/agent-sdk';
import { execSync } from 'child_process';
import * as fs from 'fs';

const codeReviewAgent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You are a senior code reviewer. When reviewing code:
1. Check for bugs and security issues first
2. Then assess code quality and patterns
3. Suggest specific improvements with examples
4. Be constructive, not harsh

Always use the available tools to read files and run checks.`,

  tools: [
    {
      name: 'read_file',
      description: 'Read contents of a source file',
      input_schema: {
        type: 'object',
        properties: {
          path: {
            type: 'string',
            description: 'File path relative to repo root',
          },
        },
        required: ['path'],
      },
      handler: async ({ path }) => {
        try {
          return fs.readFileSync(path, 'utf-8');
        } catch (e) {
          return `Error: File not found - ${path}`;
        }
      },
    },
    {
      name: 'run_linter',
      description: 'Run ESLint on a file and return issues',
      input_schema: {
        type: 'object',
        properties: {
          path: { type: 'string' },
        },
        required: ['path'],
      },
      handler: async ({ path }) => {
        try {
          return execSync(`npx eslint ${path} --format json`, {
            encoding: 'utf-8',
          });
        } catch (e: any) {
          return e.stdout || 'Linting failed';
        }
      },
    },
    {
      name: 'run_tests',
      description: 'Run tests for a specific file',
      input_schema: {
        type: 'object',
        properties: {
          test_path: { type: 'string', description: 'Path to test file' },
        },
        required: ['test_path'],
      },
      handler: async ({ test_path }) => {
        try {
          return execSync(`npm test -- ${test_path}`, { encoding: 'utf-8' });
        } catch (e: any) {
          return `Tests failed:\n${e.stdout}\n${e.stderr}`;
        }
      },
    },
    {
      name: 'submit_review',
      description: 'Submit the final code review',
      input_schema: {
        type: 'object',
        properties: {
          summary: { type: 'string', description: 'Overall assessment' },
          issues: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                severity: {
                  type: 'string',
                  enum: ['critical', 'major', 'minor', 'suggestion'],
                },
                file: { type: 'string' },
                line: { type: 'number' },
                description: { type: 'string' },
                suggested_fix: { type: 'string' },
              },
            },
          },
          approved: { type: 'boolean' },
        },
        required: ['summary', 'issues', 'approved'],
      },
      handler: async (review) => {
        // Save or post review to your system
        await saveReview(review);
        return `Review submitted: ${review.approved ? 'APPROVED' : 'CHANGES REQUESTED'}`;
      },
    },
  ],
});

// Usage
const result = await codeReviewAgent.run(
  'Review the changes in src/auth/login.ts - check for security issues'
);
```

### Example: Customer Support Agent

```typescript
const supportAgent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You are a customer support agent for Acme Corp.

GUIDELINES:
- Always verify customer identity before sharing account details
- Be empathetic and solution-oriented
- If you can't resolve, escalate to human agent
- Never share internal notes or debugging info with customer

ESCALATION TRIGGERS:
- Refund requests over $500
- Legal threats
- Technical issues you can't diagnose
- Customer asks to speak to human`,

  tools: [
    {
      name: 'lookup_customer',
      description: 'Find customer by email or order ID',
      input_schema: {
        type: 'object',
        properties: {
          email: { type: 'string' },
          order_id: { type: 'string' },
        },
      },
      handler: async ({ email, order_id }) => {
        const customer = await db.customers.find({ email, order_id });
        return JSON.stringify(customer);
      },
    },
    {
      name: 'check_order_status',
      description: 'Get current status and tracking for an order',
      input_schema: {
        type: 'object',
        properties: { order_id: { type: 'string' } },
        required: ['order_id'],
      },
      handler: async ({ order_id }) => {
        const order = await db.orders.get(order_id);
        return JSON.stringify({
          status: order.status,
          tracking: order.tracking_number,
          estimated_delivery: order.eta,
        });
      },
    },
    {
      name: 'process_refund',
      description:
        'Process a refund for an order. Requires approval for amounts over $100.',
      input_schema: {
        type: 'object',
        properties: {
          order_id: { type: 'string' },
          amount: { type: 'number' },
          reason: { type: 'string' },
        },
        required: ['order_id', 'amount', 'reason'],
      },
      handler: async ({ order_id, amount, reason }) => {
        if (amount > 500) {
          return 'ESCALATE: Refund over $500 requires manager approval';
        }
        await payments.refund(order_id, amount, reason);
        return `Refund of $${amount} processed for order ${order_id}`;
      },
    },
    {
      name: 'escalate_to_human',
      description: 'Transfer conversation to human agent',
      input_schema: {
        type: 'object',
        properties: {
          reason: { type: 'string' },
          priority: {
            type: 'string',
            enum: ['low', 'medium', 'high', 'urgent'],
          },
          summary: {
            type: 'string',
            description: 'Brief summary for the human agent',
          },
        },
        required: ['reason', 'priority', 'summary'],
      },
      handler: async ({ reason, priority, summary }) => {
        await ticketing.escalate({ reason, priority, summary });
        return 'Transferring to human agent. Please hold.';
      },
    },
  ],
});
```

---

## 3. Multi-Agent Architecture

### Pattern 1: Orchestrator + Specialists

Use this when you have distinct domains that require specialized knowledge.

```typescript
// Orchestrator manages workflow, specialists handle domains
import { Agent, Subagent } from '@anthropic-ai/agent-sdk';

// Define specialist agents
const researchAgent = new Subagent({
  name: 'researcher',
  description:
    'Expert at finding and synthesizing information from multiple sources',
  tools: [webSearchTool, documentReaderTool, summarizerTool],
});

const writerAgent = new Subagent({
  name: 'writer',
  description: 'Creates polished content from research and outlines',
  tools: [draftTool, formatTool, grammarCheckTool],
});

const reviewerAgent = new Subagent({
  name: 'reviewer',
  description: 'Reviews content for accuracy, clarity, and completeness',
  tools: [factCheckTool, readabilityTool, feedbackTool],
});

// Orchestrator coordinates the specialists
const orchestrator = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You are a content production orchestrator. Your job is to:
1. Understand the content request
2. Delegate to specialist agents in the right order
3. Coordinate handoffs between agents
4. Ensure quality standards are met

WORKFLOW:
1. Use 'researcher' to gather information
2. Use 'writer' to create draft from research
3. Use 'reviewer' to check quality
4. Iterate if reviewer finds issues

Always explain your delegation decisions.`,

  subagents: [researchAgent, writerAgent, reviewerAgent],
});

// Usage
const result = await orchestrator.run(
  'Create a 2000-word blog post about sustainable AI practices'
);
```

### Pattern 2: Pipeline (Sequential Processing)

Use when tasks must flow through stages in order.

```typescript
// Each agent processes and passes to next
const stages = {
  intake: new Agent({
    client,
    model: 'claude-sonnet-4-20250514',
    systemPrompt: 'Extract and structure requirements from user input',
    tools: [parseRequirementsTool, clarifyTool],
  }),

  design: new Agent({
    client,
    model: 'claude-sonnet-4-20250514',
    systemPrompt: 'Create technical design from requirements',
    tools: [architectTool, diagramTool],
  }),

  implement: new Agent({
    client,
    model: 'claude-sonnet-4-20250514',
    systemPrompt: 'Implement code based on design',
    tools: [codeGenTool, fileWriteTool],
  }),

  test: new Agent({
    client,
    model: 'claude-sonnet-4-20250514',
    systemPrompt: 'Write and run tests for implementation',
    tools: [testGenTool, testRunnerTool],
  }),
};

async function runPipeline(userRequest: string) {
  // Stage 1: Intake
  const requirements = await stages.intake.run(userRequest);

  // Stage 2: Design
  const design = await stages.design.run(
    `Requirements:\n${requirements.content}\n\nCreate technical design.`
  );

  // Stage 3: Implement
  const implementation = await stages.implement.run(
    `Design:\n${design.content}\n\nImplement this design.`
  );

  // Stage 4: Test
  const tested = await stages.test.run(
    `Implementation:\n${implementation.content}\n\nWrite and run tests.`
  );

  return tested;
}
```

### Pattern 3: Hierarchical (Manager → Workers)

Use when you need dynamic task decomposition and parallel execution.

```typescript
import { Agent, Subagent } from '@anthropic-ai/agent-sdk';

// Worker agents - specialized but simple
const workers = {
  dataFetcher: new Subagent({
    name: 'data_fetcher',
    description: 'Fetches data from APIs and databases',
    tools: [apiTool, dbQueryTool],
  }),
  dataAnalyzer: new Subagent({
    name: 'data_analyzer',
    description: 'Analyzes datasets and finds patterns',
    tools: [statsTool, chartTool],
  }),
  reportWriter: new Subagent({
    name: 'report_writer',
    description: 'Writes formatted reports from analysis',
    tools: [formatTool, exportTool],
  }),
};

// Manager decomposes tasks and coordinates workers
const manager = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You are a project manager agent. Given a goal:

1. Break it into subtasks
2. Assign subtasks to appropriate workers
3. Collect and synthesize results
4. Handle failures by reassigning or adjusting approach

Available workers:
- data_fetcher: Gets raw data
- data_analyzer: Analyzes data
- report_writer: Creates reports

You can run multiple workers in parallel when tasks are independent.`,

  subagents: Object.values(workers),
});
```

### Pattern 4: Debate/Consensus (Multi-Perspective)

Use for decisions requiring diverse viewpoints.

```typescript
const perspectives = {
  optimist: new Subagent({
    name: 'optimist',
    description: 'Identifies opportunities and potential benefits',
    systemPrompt: 'Focus on upside potential and opportunities',
  }),
  pessimist: new Subagent({
    name: 'pessimist',
    description: 'Identifies risks and potential problems',
    systemPrompt: 'Focus on risks, downsides, and what could go wrong',
  }),
  pragmatist: new Subagent({
    name: 'pragmatist',
    description: 'Focuses on practical feasibility and implementation',
    systemPrompt: 'Focus on practical concerns and realistic timelines',
  }),
};

const moderator = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  systemPrompt: `You moderate a decision-making process:

1. Present the decision to all perspectives
2. Collect each viewpoint
3. Identify areas of agreement and disagreement
4. Synthesize into a balanced recommendation

Never let one perspective dominate. Ensure all views are heard.`,

  subagents: Object.values(perspectives),
});

// Usage
const decision = await moderator.run(
  'Should we migrate our monolith to microservices this quarter?'
);
```

---

## 4. Stateful Agents with Sessions

### Why Sessions?

- **Continuity**: Agent remembers previous interactions
- **Checkpointing**: Can pause and resume long tasks
- **Debugging**: Can inspect agent state at any point
- **Recovery**: Restart from checkpoint on failure

### Basic Session Setup

```typescript
import { Agent, Session } from '@anthropic-ai/agent-sdk';

// Create session-enabled agent
const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  sessionConfig: {
    // Where to store session data
    storage: 'filesystem', // or "memory", "redis", "custom"
    storagePath: './sessions',

    // Checkpoint frequency
    checkpointFrequency: 'turn', // after each turn
    // or: "tool_call", "manual"

    // Session limits
    maxTurns: 100,
    maxIdleTime: '30m',
  },
});

// Start a new session
const session = await agent.startSession({
  sessionId: 'user-123-task-456', // Your tracking ID
  metadata: {
    userId: 'user-123',
    taskType: 'code-review',
  },
});

// Run with session
const result = await session.run('Review the auth module');

// Later: Resume session
const resumedSession = await agent.resumeSession('user-123-task-456');
const moreResults = await resumedSession.run('Now check the tests');

// Explicit checkpoint
await session.checkpoint('before-dangerous-operation');

// Restore from checkpoint
await session.restoreCheckpoint('before-dangerous-operation');
```

### Session Events and Hooks

```typescript
const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',
  sessionConfig: { storage: 'filesystem', storagePath: './sessions' },

  hooks: {
    onSessionStart: async (session) => {
      console.log(`Session started: ${session.id}`);
      await analytics.track('session_start', { sessionId: session.id });
    },

    onSessionEnd: async (session, reason) => {
      console.log(`Session ended: ${reason}`);
      await analytics.track('session_end', {
        sessionId: session.id,
        reason,
        turns: session.turnCount,
      });
    },

    onCheckpoint: async (session, checkpointId) => {
      console.log(`Checkpoint saved: ${checkpointId}`);
    },

    onSessionRestore: async (session, fromCheckpoint) => {
      console.log(`Restored from: ${fromCheckpoint}`);
    },
  },
});
```

---

## 5. Human-in-the-Loop Workflows

### Permission Modes

```typescript
// Mode 1: Auto-approve everything (development only!)
const devAgent = new Agent({
  permissionMode: 'auto',
});

// Mode 2: Approve specific tools automatically
const semiAutoAgent = new Agent({
  permissionMode: {
    type: 'selective',
    autoApprove: ['read_file', 'search', 'analyze'], // Safe tools
    requireApproval: ['write_file', 'delete', 'execute', 'send_email'], // Dangerous tools
  },
});

// Mode 3: Require approval for everything
const strictAgent = new Agent({
  permissionMode: 'manual',
});
```

### Building Approval UI

```typescript
const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',

  // Custom approval handler
  onPermissionRequest: async (request) => {
    // request contains: tool name, arguments, context

    // Option 1: CLI approval
    const answer = await prompt(
      `Agent wants to ${request.tool}(${JSON.stringify(request.args)})\nApprove? (y/n): `
    );
    return answer.toLowerCase() === 'y';

    // Option 2: Web UI approval
    const approval = await showApprovalModal({
      title: `Approve: ${request.tool}`,
      description: request.context,
      args: request.args,
      timeout: 60000, // 1 minute timeout
    });
    return approval.approved;

    // Option 3: Slack/Teams approval
    const slackApproval = await sendSlackApproval({
      channel: '#agent-approvals',
      request: request,
    });
    return slackApproval;
  },
});
```

### Approval with Modification

```typescript
const agent = new Agent({
  onPermissionRequest: async (request) => {
    // User can modify the request before approving
    const result = await showApprovalDialog(request);

    if (result.action === 'approve') {
      return { approved: true };
    } else if (result.action === 'modify') {
      return {
        approved: true,
        modifiedArgs: result.newArgs, // Agent uses modified args
      };
    } else {
      return {
        approved: false,
        reason: result.reason, // Tell agent why denied
      };
    }
  },
});
```

---

## 6. MCP (Model Context Protocol) Integration

### What is MCP?

MCP lets your agent connect to external tool providers without custom integration code.

### Using MCP Servers

```typescript
import { Agent, MCPClient } from '@anthropic-ai/agent-sdk';

const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',

  mcpServers: [
    // Connect to filesystem MCP server
    {
      name: 'filesystem',
      transport: {
        type: 'stdio',
        command: 'npx',
        args: ['-y', '@anthropic/mcp-server-filesystem', './workspace'],
      },
    },

    // Connect to GitHub MCP server
    {
      name: 'github',
      transport: {
        type: 'stdio',
        command: 'npx',
        args: ['-y', '@anthropic/mcp-server-github'],
        env: {
          GITHUB_TOKEN: process.env.GITHUB_TOKEN,
        },
      },
    },

    // Connect to custom MCP server via SSE
    {
      name: 'custom-tools',
      transport: {
        type: 'sse',
        url: 'https://your-mcp-server.com/sse',
      },
    },
  ],
});

// Agent now has access to all tools from MCP servers
// Tools are namespaced: filesystem.read_file, github.create_issue, etc.
```

### Building Your Own MCP Server

```typescript
// mcp-server.ts
import { MCPServer, Tool } from '@anthropic-ai/mcp';

const server = new MCPServer({
  name: 'my-company-tools',
  version: '1.0.0',
});

// Define tools
server.addTool({
  name: 'query_crm',
  description: 'Query the company CRM for customer data',
  inputSchema: {
    type: 'object',
    properties: {
      customerId: { type: 'string' },
    },
    required: ['customerId'],
  },
  handler: async ({ customerId }) => {
    const customer = await crm.getCustomer(customerId);
    return JSON.stringify(customer);
  },
});

server.addTool({
  name: 'create_ticket',
  description: 'Create a support ticket',
  inputSchema: {
    type: 'object',
    properties: {
      title: { type: 'string' },
      description: { type: 'string' },
      priority: { type: 'string', enum: ['low', 'medium', 'high'] },
    },
    required: ['title', 'description'],
  },
  handler: async (input) => {
    const ticket = await ticketing.create(input);
    return `Created ticket: ${ticket.id}`;
  },
});

// Start server
server.listen({ transport: 'stdio' });
```

---

## 7. Production Deployment

### Pre-Deployment Checklist

```markdown
## Security

- [ ] API keys in environment variables, not code
- [ ] Permission mode set to "selective" or "manual"
- [ ] Dangerous tools require human approval
- [ ] Input validation on all tool handlers
- [ ] Rate limiting implemented
- [ ] Audit logging enabled

## Reliability

- [ ] Session storage configured (not in-memory for production)
- [ ] Checkpoint strategy defined
- [ ] Error handling in all tool handlers
- [ ] Timeout limits set
- [ ] Retry logic for transient failures

## Monitoring

- [ ] Cost tracking hooks enabled
- [ ] Performance metrics collected
- [ ] Error alerting configured
- [ ] Usage analytics in place

## Testing

- [ ] Unit tests for all tools
- [ ] Integration tests for agent workflows
- [ ] Load testing completed
- [ ] Failure scenario testing done
```

### Production Configuration

```typescript
const productionAgent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',

  // Security
  permissionMode: {
    type: 'selective',
    autoApprove: ['read_*', 'search_*', 'analyze_*'],
    requireApproval: ['write_*', 'delete_*', 'execute_*', 'send_*'],
  },

  // Reliability
  sessionConfig: {
    storage: 'redis',
    connectionString: process.env.REDIS_URL,
    checkpointFrequency: 'turn',
  },

  // Limits
  maxTurns: 50,
  maxTokens: 100000,
  timeoutMs: 300000, // 5 minutes

  // Monitoring hooks
  hooks: {
    onTurnStart: async (turn) => {
      metrics.increment('agent.turns.started');
    },

    onTurnEnd: async (turn, result) => {
      metrics.increment('agent.turns.completed');
      metrics.histogram('agent.turn.duration_ms', result.durationMs);
    },

    onToolCall: async (tool, args) => {
      metrics.increment(`agent.tools.${tool}`);
      audit.log('tool_call', { tool, args, timestamp: Date.now() });
    },

    onError: async (error) => {
      metrics.increment('agent.errors');
      alerting.notify('agent_error', error);
    },

    onTokenUsage: async (usage) => {
      metrics.gauge('agent.tokens.input', usage.inputTokens);
      metrics.gauge('agent.tokens.output', usage.outputTokens);
      await billing.track(usage);
    },
  },
});
```

### Cost Control

```typescript
const agent = new Agent({
  client,
  model: 'claude-sonnet-4-20250514',

  // Hard limits
  maxTokens: 50000, // Per session
  maxTurns: 20,

  // Cost tracking
  hooks: {
    onTokenUsage: async (usage) => {
      const cost = calculateCost(usage);

      if (cost > COST_THRESHOLD) {
        throw new Error(`Cost limit exceeded: $${cost}`);
      }

      await db.trackCost({
        sessionId: usage.sessionId,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        cost: cost,
      });
    },
  },
});

function calculateCost(usage) {
  // Claude Sonnet pricing (check current rates)
  const inputCostPer1k = 0.003;
  const outputCostPer1k = 0.015;

  return (
    (usage.inputTokens / 1000) * inputCostPer1k +
    (usage.outputTokens / 1000) * outputCostPer1k
  );
}
```

---

## 8. Complete Example: Recruitment System

Here's a full multi-agent recruitment system you could build:

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    RECRUITMENT ORCHESTRATOR                  │
│  - Receives job requisitions                                │
│  - Coordinates specialist agents                            │
│  - Tracks pipeline status                                   │
└─────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
    ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐
    │ SOURCER │   │SCREENER │   │SCHEDULER│   │ASSESSOR │
    │         │   │         │   │         │   │         │
    │ Finds   │   │ Reviews │   │ Books   │   │ Scores  │
    │ talent  │   │ resumes │   │ calls   │   │ skills  │
    └─────────┘   └─────────┘   └─────────┘   └─────────┘
```

### Implementation

```typescript
// recruitment-system.ts
import { Agent, Subagent } from '@anthropic-ai/agent-sdk';

// ============ SPECIALIST AGENTS ============

const sourcerAgent = new Subagent({
  name: 'sourcer',
  description: 'Finds and reaches out to potential candidates',
  systemPrompt: `You are a talent sourcer. Given a job description:
1. Identify key skills and qualifications
2. Search for matching candidates
3. Draft personalized outreach messages
4. Track response rates`,

  tools: [
    {
      name: 'search_linkedin',
      description: 'Search LinkedIn for candidates matching criteria',
      input_schema: {
        type: 'object',
        properties: {
          keywords: { type: 'array', items: { type: 'string' } },
          location: { type: 'string' },
          experience_years: { type: 'number' },
          limit: { type: 'number' },
        },
        required: ['keywords'],
      },
      handler: async (input) => {
        // Integration with LinkedIn API or scraping service
        const candidates = await linkedIn.search(input);
        return JSON.stringify(candidates);
      },
    },
    {
      name: 'send_outreach',
      description: 'Send outreach message to a candidate',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          subject: { type: 'string' },
          message: { type: 'string' },
          channel: { type: 'string', enum: ['email', 'linkedin', 'inmail'] },
        },
        required: ['candidate_id', 'subject', 'message', 'channel'],
      },
      handler: async (input) => {
        await outreach.send(input);
        return `Outreach sent to ${input.candidate_id} via ${input.channel}`;
      },
    },
  ],
});

const screenerAgent = new Subagent({
  name: 'screener',
  description: 'Reviews resumes and applications against job requirements',
  systemPrompt: `You are a resume screener. For each candidate:
1. Extract key qualifications
2. Match against job requirements
3. Score fit (1-10) with justification
4. Flag any concerns
5. Recommend: advance, reject, or hold`,

  tools: [
    {
      name: 'parse_resume',
      description: 'Extract structured data from a resume',
      input_schema: {
        type: 'object',
        properties: {
          resume_url: { type: 'string' },
        },
        required: ['resume_url'],
      },
      handler: async ({ resume_url }) => {
        const parsed = await resumeParser.parse(resume_url);
        return JSON.stringify(parsed);
      },
    },
    {
      name: 'get_job_requirements',
      description: 'Get the requirements for a job',
      input_schema: {
        type: 'object',
        properties: {
          job_id: { type: 'string' },
        },
        required: ['job_id'],
      },
      handler: async ({ job_id }) => {
        const job = await db.jobs.get(job_id);
        return JSON.stringify(job.requirements);
      },
    },
    {
      name: 'submit_screening',
      description: 'Submit screening decision',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          job_id: { type: 'string' },
          score: { type: 'number', minimum: 1, maximum: 10 },
          decision: { type: 'string', enum: ['advance', 'reject', 'hold'] },
          justification: { type: 'string' },
          concerns: { type: 'array', items: { type: 'string' } },
        },
        required: [
          'candidate_id',
          'job_id',
          'score',
          'decision',
          'justification',
        ],
      },
      handler: async (screening) => {
        await db.screenings.create(screening);
        return `Screening submitted: ${screening.decision}`;
      },
    },
  ],
});

const schedulerAgent = new Subagent({
  name: 'scheduler',
  description:
    'Coordinates interview scheduling between candidates and interviewers',
  systemPrompt: `You are an interview scheduler. Your job:
1. Find available time slots
2. Match with interviewer availability  
3. Send calendar invites
4. Handle rescheduling requests
5. Send reminders`,

  tools: [
    {
      name: 'get_availability',
      description: 'Get available time slots for a person',
      input_schema: {
        type: 'object',
        properties: {
          person_id: { type: 'string' },
          date_range: {
            type: 'object',
            properties: {
              start: { type: 'string' },
              end: { type: 'string' },
            },
          },
          duration_minutes: { type: 'number' },
        },
        required: ['person_id', 'date_range', 'duration_minutes'],
      },
      handler: async (input) => {
        const slots = await calendar.getAvailability(input);
        return JSON.stringify(slots);
      },
    },
    {
      name: 'schedule_interview',
      description: 'Book an interview slot',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          interviewer_ids: { type: 'array', items: { type: 'string' } },
          datetime: { type: 'string' },
          duration_minutes: { type: 'number' },
          interview_type: {
            type: 'string',
            enum: ['phone', 'video', 'onsite'],
          },
          meeting_link: { type: 'string' },
        },
        required: [
          'candidate_id',
          'interviewer_ids',
          'datetime',
          'duration_minutes',
          'interview_type',
        ],
      },
      handler: async (input) => {
        const event = await calendar.createInterview(input);
        return `Interview scheduled: ${event.id}`;
      },
    },
  ],
});

const assessorAgent = new Subagent({
  name: 'assessor',
  description:
    'Evaluates candidates through assessments and interview feedback',
  systemPrompt: `You are a candidate assessor. Your responsibilities:
1. Design role-appropriate assessments
2. Analyze assessment results
3. Aggregate interview feedback
4. Generate hiring recommendations`,

  tools: [
    {
      name: 'send_assessment',
      description: 'Send a skills assessment to a candidate',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          assessment_type: {
            type: 'string',
            enum: ['coding', 'writing', 'case_study', 'personality'],
          },
          deadline_hours: { type: 'number' },
        },
        required: ['candidate_id', 'assessment_type'],
      },
      handler: async (input) => {
        await assessments.send(input);
        return `Assessment sent to candidate`;
      },
    },
    {
      name: 'get_interview_feedback',
      description: 'Get all interview feedback for a candidate',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
        },
        required: ['candidate_id'],
      },
      handler: async ({ candidate_id }) => {
        const feedback = await db.feedback.findByCandidate(candidate_id);
        return JSON.stringify(feedback);
      },
    },
    {
      name: 'submit_recommendation',
      description: 'Submit final hiring recommendation',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          job_id: { type: 'string' },
          recommendation: {
            type: 'string',
            enum: ['strong_hire', 'hire', 'no_hire', 'strong_no_hire'],
          },
          summary: { type: 'string' },
          strengths: { type: 'array', items: { type: 'string' } },
          concerns: { type: 'array', items: { type: 'string' } },
          suggested_level: { type: 'string' },
          suggested_compensation: { type: 'string' },
        },
        required: ['candidate_id', 'job_id', 'recommendation', 'summary'],
      },
      handler: async (rec) => {
        await db.recommendations.create(rec);
        return `Recommendation submitted: ${rec.recommendation}`;
      },
    },
  ],
});

// ============ ORCHESTRATOR ============

const recruitmentOrchestrator = new Agent({
  client: new Anthropic(),
  model: 'claude-sonnet-4-20250514',

  systemPrompt: `You are the recruitment pipeline orchestrator for Acme Corp.

YOUR RESPONSIBILITIES:
1. Receive job requisitions and understand hiring needs
2. Coordinate the recruitment pipeline
3. Track candidates through stages
4. Ensure SLAs are met (time-to-fill, response times)
5. Report status to stakeholders

PIPELINE STAGES:
1. SOURCING: Use 'sourcer' to find candidates
2. SCREENING: Use 'screener' to review applications  
3. SCHEDULING: Use 'scheduler' to book interviews
4. ASSESSMENT: Use 'assessor' to evaluate and recommend

RULES:
- Never skip stages without explicit approval
- Candidates must score 7+ in screening to advance
- Always get human approval before rejecting candidates
- Escalate if pipeline is stuck > 48 hours`,

  subagents: [sourcerAgent, screenerAgent, schedulerAgent, assessorAgent],

  // Additional orchestrator tools
  tools: [
    {
      name: 'get_pipeline_status',
      description: 'Get current status of all candidates in pipeline',
      input_schema: {
        type: 'object',
        properties: {
          job_id: { type: 'string' },
          stage: {
            type: 'string',
            enum: ['sourcing', 'screening', 'interview', 'assessment', 'offer'],
          },
        },
      },
      handler: async ({ job_id, stage }) => {
        const candidates = await db.pipeline.getByJob(job_id, stage);
        return JSON.stringify(candidates);
      },
    },
    {
      name: 'update_candidate_stage',
      description: 'Move candidate to next pipeline stage',
      input_schema: {
        type: 'object',
        properties: {
          candidate_id: { type: 'string' },
          new_stage: { type: 'string' },
          notes: { type: 'string' },
        },
        required: ['candidate_id', 'new_stage'],
      },
      handler: async (input) => {
        await db.pipeline.updateStage(input);
        return `Candidate moved to ${input.new_stage}`;
      },
    },
    {
      name: 'notify_stakeholder',
      description: 'Send update to hiring manager or recruiter',
      input_schema: {
        type: 'object',
        properties: {
          stakeholder_id: { type: 'string' },
          message: { type: 'string' },
          urgency: { type: 'string', enum: ['low', 'normal', 'high'] },
        },
        required: ['stakeholder_id', 'message'],
      },
      handler: async (input) => {
        await notifications.send(input);
        return 'Notification sent';
      },
    },
  ],

  // Human approval for key decisions
  permissionMode: {
    type: 'selective',
    autoApprove: [
      'get_pipeline_status',
      'search_linkedin',
      'parse_resume',
      'get_availability',
      'get_interview_feedback',
    ],
    requireApproval: [
      'send_outreach',
      'submit_screening',
      'schedule_interview',
      'submit_recommendation',
    ],
  },

  // Session for continuity
  sessionConfig: {
    storage: 'redis',
    connectionString: process.env.REDIS_URL,
    checkpointFrequency: 'turn',
  },
});

// ============ USAGE ============

async function processRequisition(jobId: string) {
  const session = await recruitmentOrchestrator.startSession({
    sessionId: `recruitment-${jobId}`,
    metadata: { jobId },
  });

  const result = await session.run(`
    New job requisition: ${jobId}
    
    1. First, understand the job requirements
    2. Source 20 potential candidates
    3. Screen all applications received
    4. Schedule interviews for qualified candidates
    5. Report pipeline status
  `);

  return result;
}

// Run daily pipeline check
async function dailyPipelineCheck() {
  const activeJobs = await db.jobs.findActive();

  for (const job of activeJobs) {
    const session = await recruitmentOrchestrator.resumeSession(
      `recruitment-${job.id}`
    );
    await session.run(`
      Daily check for job ${job.id}:
      - Review pipeline status
      - Follow up on pending actions
      - Escalate any blockers
      - Update stakeholders
    `);
  }
}
```

---

## 9. Troubleshooting Guide

### Agent Not Using Tools

**Symptom**: Agent responds with text instead of using available tools

**Solutions**:

```typescript
// 1. Improve tool descriptions
{
  name: "search",
  description: "ALWAYS use this tool when user asks to find or look up information. Returns results as JSON array.",
  // Be explicit about WHEN to use the tool
}

// 2. Strengthen system prompt
systemPrompt: `You have access to tools and MUST use them.
Do not make up information - always use tools to get real data.
If you're unsure, use a tool to verify.`

// 3. Add explicit instructions in user message
await agent.run(`
  Find information about X.

  IMPORTANT: Use the search tool to find this information.
  Do not respond until you have used the tool.
`);
```

### Agent Loops or Gets Stuck

**Symptom**: Agent keeps calling same tool or can't complete

**Solutions**:

```typescript
// 1. Add turn limits
const agent = new Agent({
  maxTurns: 10,
  // ...
});

// 2. Add progress tracking tool
{
  name: "report_progress",
  description: "Report what you've accomplished and what's next",
  handler: async ({ completed, next_steps, blockers }) => {
    if (blockers.length > 0) {
      // Alert human
    }
    return "Progress recorded";
  }
}

// 3. Better error messages from tools
handler: async (input) => {
  const result = await search(input);
  if (result.length === 0) {
    return "No results found. Try different keywords or broaden your search.";
    // DON'T just return empty array - give guidance
  }
  return JSON.stringify(result);
}
```

### High Token Usage

**Solutions**:

```typescript
// 1. Summarize tool outputs
handler: async (input) => {
  const data = await fetchLargeData(input);
  // Don't return raw data
  return summarize(data, {
    maxItems: 10,
    includeFields: ['name', 'id', 'status'],
  });
};

// 2. Use streaming for long operations
const agent = new Agent({
  streaming: true,
  // User sees progress, can stop early
});

// 3. Break into smaller tasks
// Instead of one mega-task, run multiple focused sessions
```

---

---

## 10. Claude API Features (Beyond the SDK)

These powerful API features complement the Agent SDK and can dramatically improve your agent's capabilities, cost efficiency, and reasoning quality.

### Extended Thinking (Deep Reasoning)

Enable Claude to "think out loud" before responding - dramatically improves complex reasoning tasks.

```typescript
// Direct API call with extended thinking
const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 16000,
  thinking: {
    type: 'enabled',
    budget_tokens: 10000, // How much "thinking" to allow
  },
  messages: [
    { role: 'user', content: 'Solve this complex problem step by step...' },
  ],
});

// Response includes thinking blocks
// response.content = [
//   { type: "thinking", thinking: "Let me analyze...", signature: "..." },
//   { type: "text", text: "Based on my analysis..." }
// ]
```

**When to use:**

- Complex math, logic, or coding problems
- Multi-step analysis requiring careful reasoning
- Tasks where you need to verify Claude's thought process

**Budget guidance:**

- Start at 1,024 tokens minimum
- 16k+ for complex tasks
- 32k+ consider batch processing (long requests)

**With tool use (interleaved thinking):**

```typescript
// Enable thinking between tool calls
const response = await client.messages.create({
  model: "claude-opus-4-5-20251101",
  max_tokens: 16000,
  thinking: { type: "enabled", budget_tokens: 10000 },
  tools: myTools,
  messages: [...],
}, {
  headers: {
    "anthropic-beta": "interleaved-thinking-2025-05-14"  // Required for interleaved
  }
});
```

### Prompt Caching (Cost Optimization)

Cache large prompts to reduce costs by 90% on repeated content.

```typescript
const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 1024,
  system: [
    {
      type: 'text',
      text: 'You are an expert assistant...',
    },
    {
      type: 'text',
      text: '<entire_codebase_or_documentation_here>', // Large static content
      cache_control: { type: 'ephemeral' }, // Cache this!
    },
  ],
  messages: [
    { role: 'user', content: 'Analyze the auth module' }, // Only this changes
  ],
});

// Check cache performance in response.usage:
// cache_creation_input_tokens: 188086  (first call - writes cache)
// cache_read_input_tokens: 188086      (subsequent - reads cache, 90% cheaper)
// input_tokens: 21                      (only new tokens after cache)
```

**Pricing impact:**
| Operation | Cost vs Base |
|-----------|-------------|
| Cache write (5min) | 1.25x |
| Cache write (1hr) | 2x |
| Cache read | 0.1x (90% savings!) |

**Best for:**

- System prompts with large context (docs, codebases)
- Multi-turn conversations with shared history
- RAG with large document chunks

**1-hour cache for long workflows:**

```typescript
cache_control: {
  type: "ephemeral",
  ttl: "1h"  // Keeps cache for 1 hour instead of 5 minutes
}
```

### Batch Processing (50% Cost Reduction)

Process many requests asynchronously at half the cost.

```typescript
// Create a batch of requests
const batch = await client.messages.batches.create({
  requests: [
    {
      custom_id: 'review-1',
      params: {
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 1024,
        messages: [{ role: 'user', content: 'Review code: ...' }],
      },
    },
    {
      custom_id: 'review-2',
      params: {
        model: 'claude-sonnet-4-5-20250929',
        max_tokens: 1024,
        messages: [{ role: 'user', content: 'Review code: ...' }],
      },
    },
    // Up to 100,000 requests per batch!
  ],
});

// Poll for completion
while (true) {
  const status = await client.messages.batches.retrieve(batch.id);
  if (status.processing_status === 'ended') break;
  await sleep(60000); // Check every minute
}

// Get results
const results = await client.messages.batches.results(batch.id);
// Results are in .jsonl format, streamed back
```

**Best for:**

- Large-scale evaluations
- Bulk content generation
- Data analysis pipelines
- Non-time-sensitive processing

**Limitations:**

- Max 100,000 requests or 256MB per batch
- Results available within 24 hours
- Results expire after 29 days

### Vision (Image Understanding)

Claude can analyze images in your agent workflows.

```typescript
const response = await client.messages.create({
  model: "claude-sonnet-4-5-20250929",
  max_tokens: 1024,
  messages: [
    {
      role: "user",
      content: [
        {
          type: "image",
          source: {
            type: "base64",
            media_type: "image/png",
            data: base64ImageData
          }
        },
        {
          type: "text",
          text: "What's in this image? Identify any issues."
        }
      ]
    }
  ]
});

// Or use URL (if publicly accessible)
{
  type: "image",
  source: {
    type: "url",
    url: "https://example.com/image.png"
  }
}
```

**Use in agents:**

```typescript
const screenshotAnalyzerTool = {
  name: 'analyze_screenshot',
  description: 'Analyze a UI screenshot for issues',
  input_schema: {
    type: 'object',
    properties: {
      screenshot_path: { type: 'string' },
    },
    required: ['screenshot_path'],
  },
  handler: async ({ screenshot_path }) => {
    const imageData = fs.readFileSync(screenshot_path).toString('base64');

    const analysis = await client.messages.create({
      model: 'claude-sonnet-4-5-20250929',
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              source: {
                type: 'base64',
                media_type: 'image/png',
                data: imageData,
              },
            },
            {
              type: 'text',
              text: 'Analyze this UI. List any UX issues, accessibility problems, or visual bugs.',
            },
          ],
        },
      ],
    });

    return analysis.content[0].text;
  },
};
```

### Structured Outputs (Guaranteed JSON Schema)

Force Claude to return data matching an exact schema.

```typescript
// Using tool_choice to force structured output
const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 1024,
  tools: [
    {
      name: 'extract_data',
      description: 'Extract structured data from text',
      input_schema: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          email: { type: 'string', format: 'email' },
          priority: { type: 'string', enum: ['low', 'medium', 'high'] },
          tags: { type: 'array', items: { type: 'string' } },
        },
        required: ['name', 'email', 'priority'],
      },
    },
  ],
  tool_choice: { type: 'tool', name: 'extract_data' }, // Force this tool
  messages: [
    {
      role: 'user',
      content:
        'Extract info from: John Doe (john@email.com) - urgent request about billing',
    },
  ],
});

// response.content[0].input guaranteed to match schema
const extracted = response.content[0].input;
// { name: "John Doe", email: "john@email.com", priority: "high", tags: ["billing"] }
```

### Token Counting (Pre-flight Check)

Count tokens before sending to manage costs and limits.

```typescript
const tokenCount = await client.messages.count_tokens({
  model: 'claude-sonnet-4-5-20250929',
  messages: [{ role: 'user', content: yourLongPrompt }],
  system: yourSystemPrompt,
});

console.log(`This request will use ${tokenCount.input_tokens} input tokens`);

// Use this to:
// 1. Estimate costs before expensive operations
// 2. Truncate content to fit context window
// 3. Make decisions about caching strategy
```

### Web Search Tool (Real-time Information)

Give Claude access to current web information.

```typescript
const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 1024,
  tools: [
    {
      type: 'web_search_20250305',
      name: 'web_search',
      // No additional config needed - it's a built-in tool
    },
  ],
  messages: [
    {
      role: 'user',
      content: 'What are the latest developments in AI agents this week?',
    },
  ],
});
```

### Code Execution Tool (Sandboxed Python)

Let Claude run Python code in a secure sandbox.

```typescript
const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 4096,
  tools: [
    {
      type: 'code_execution_20250522',
      name: 'code_execution',
      // Runs in secure sandbox with data analysis libraries
    },
  ],
  messages: [
    {
      role: 'user',
      content: 'Analyze this CSV data and create a visualization: ...',
    },
  ],
});
```

### Computer Use Tool (Beta - UI Automation)

Enable Claude to control computer interfaces.

```typescript
const response = await client.messages.create(
  {
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 4096,
    tools: [
      {
        type: 'computer_20250124',
        name: 'computer',
        display_width_px: 1920,
        display_height_px: 1080,
      },
    ],
    messages: [
      { role: 'user', content: 'Open the browser and navigate to example.com' },
    ],
  },
  {
    headers: { 'anthropic-beta': 'computer-use-2025-01-24' },
  }
);

// Claude returns actions like:
// { type: "computer_20250124", action: "screenshot" }
// { type: "computer_20250124", action: "click", coordinate: [500, 300] }
// { type: "computer_20250124", action: "type", text: "hello" }
```

### Memory Tool (Persistent Knowledge)

Enable Claude to store and retrieve information across conversations.

```typescript
const response = await client.messages.create(
  {
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 1024,
    tools: [
      {
        type: 'memory_20250501',
        name: 'memory',
      },
    ],
    messages: [
      {
        role: 'user',
        content: 'Remember that my project deadline is March 15th',
      },
    ],
  },
  {
    headers: { 'anthropic-beta': 'memory-2025-05-01' },
  }
);

// Later conversations can retrieve this memory
```

### Combining Features for Maximum Effect

```typescript
// Production agent with all optimizations
const response = await client.messages.create(
  {
    model: 'claude-sonnet-4-5-20250929',
    max_tokens: 16000,

    // Extended thinking for complex reasoning
    thinking: {
      type: 'enabled',
      budget_tokens: 8000,
    },

    // Cached system context
    system: [
      { type: 'text', text: 'You are a senior code reviewer...' },
      {
        type: 'text',
        text: entireCodebaseContext, // Large context
        cache_control: { type: 'ephemeral', ttl: '1h' }, // 1-hour cache
      },
    ],

    // Tools including built-ins
    tools: [
      ...customTools,
      { type: 'web_search_20250305', name: 'web_search' },
      { type: 'code_execution_20250522', name: 'code_execution' },
    ],

    messages: conversationHistory,
  },
  {
    headers: {
      'anthropic-beta': 'interleaved-thinking-2025-05-14',
    },
  }
);
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│                 CLAUDE AGENT SDK CHEATSHEET                 │
├─────────────────────────────────────────────────────────────┤
│ BASIC AGENT:                                                │
│   new Agent({ client, model, systemPrompt, tools })         │
│   await agent.run("task")                                   │
│                                                             │
│ TOOL STRUCTURE:                                             │
│   { name, description, input_schema, handler }              │
│                                                             │
│ SUBAGENTS:                                                  │
│   new Subagent({ name, description, tools })                │
│   Pass to parent: { subagents: [agent1, agent2] }           │
│                                                             │
│ SESSIONS:                                                   │
│   await agent.startSession({ sessionId })                   │
│   await agent.resumeSession(sessionId)                      │
│   await session.checkpoint(id)                              │
│                                                             │
│ HOOKS:                                                      │
│   onTurnStart, onTurnEnd, onToolCall, onError              │
│   onTokenUsage, onSessionStart, onSessionEnd               │
│                                                             │
│ PERMISSION MODES:                                           │
│   "auto" | "manual" | { autoApprove, requireApproval }     │
│                                                             │
│ MCP SERVERS:                                                │
│   mcpServers: [{ name, transport: { type, command } }]     │
└─────────────────────────────────────────────────────────────┘
```

---

## See Also

- [claude-agent-sdk-reference.md](./claude-agent-sdk-reference.md) - Full API reference
- [Anthropic Documentation](https://platform.claude.com/docs) - Official docs
- [MCP Specification](https://spec.modelcontextprotocol.io/) - Protocol details
