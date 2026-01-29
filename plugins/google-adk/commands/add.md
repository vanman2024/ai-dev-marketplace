---
description: Add a specific feature to an existing Google ADK project. Features include agent, tool, streaming, a2a, eval, observability, deploy.
argument-hint: <feature> [options]
---

# Add Google ADK Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Agent Features

**If `$0` = "agent":**

```
Task(google-adk-agent-builder) Add new AGENT.

Requirements:
- Agent name: $1 (required)
- Agent type: $2 (basic, multi-modal, orchestrator - default: basic)
- Create agent configuration
- Set up system instructions
- Configure model settings
- Add to agent registry
```

**If `$0` = "subagent":**

```
Task(google-adk-agent-builder) Add SUB-AGENT.

Requirements:
- Subagent name: $1 (required)
- Parent agent: $2 (optional)
- Create subagent config
- Configure delegation
- Set up communication
```

### Tool Features

**If `$0` = "tool":**

```
Task(google-adk-tools-integrator) Add TOOL.

Requirements:
- Tool name: $1 (required)
- Tool type: $2 (function, api, code-exec - default: function)
- Create tool definition
- Add schema
- Implement handler
- Register with agent
```

### Streaming Features

**If `$0` = "streaming":**

```
Task(google-adk-streaming-specialist) Add STREAMING support.

Requirements:
- Stream type: $1 (text, events, audio - default: text)
- Set up streaming runner
- Configure event handlers
- Add partial response handling
- Implement real-time output
```

### A2A Features

**If `$0` = "a2a":**

```
Task(google-adk-a2a-specialist) Add A2A PROTOCOL support.

Requirements:
- Role: $1 (server, client, both - default: both)
- Set up A2A endpoints
- Configure agent card
- Add discovery
- Implement message passing
```

### Interaction Features

**If `$0` = "interactions":**

```
Task(google-adk-interactions-specialist) Add INTERACTIONS.

Requirements:
- Interaction type: $1 (session, multi-turn, callbacks - default: session)
- Configure Runner
- Set up session management
- Add context handling
```

### Evaluation Features

**If `$0` = "eval":**

```
Task(google-adk-evaluation-specialist) Add EVALUATION.

Requirements:
- Eval type: $1 (accuracy, latency, quality, all - default: all)
- Set up evaluation framework
- Create test cases
- Add metrics collection
- Generate reports
```

### Observability Features

**If `$0` = "observability":**

```
Task(google-adk-observability-integrator) Add OBSERVABILITY.

Requirements:
- Feature: $1 (tracing, logging, metrics, all - default: all)
- Configure observability backend
- Add instrumentation
- Set up dashboards
```

### Deployment Features

**If `$0` = "deploy":**

```
Task(google-adk-deployment-specialist) Add DEPLOYMENT config.

Requirements:
- Platform: $1 (cloud-run, vertex-ai, docker - default: cloud-run)
- Create deployment config
- Set up scaling
- Configure authentication
- Add health checks
```

---

## Usage Examples

```bash
# Agents
/google-adk:add agent research-agent basic
/google-adk:add agent coordinator orchestrator
/google-adk:add subagent analyzer parent-agent

# Tools
/google-adk:add tool search-web function
/google-adk:add tool code-runner code-exec

# Streaming & A2A
/google-adk:add streaming text
/google-adk:add a2a both

# Monitoring
/google-adk:add eval all
/google-adk:add observability tracing

# Deployment
/google-adk:add deploy cloud-run
/google-adk:add deploy vertex-ai
```

---

## Feature Reference

| Feature         | Agent                    | $1 Options                   | Description       |
| --------------- | ------------------------ | ---------------------------- | ----------------- |
| `agent`         | agent-builder            | agent-name (required)        | New agent         |
| `subagent`      | agent-builder            | subagent-name (required)     | Sub-agent         |
| `tool`          | tools-integrator         | tool-name (required)         | Custom tool       |
| `streaming`     | streaming-specialist     | text/events/audio            | Streaming support |
| `a2a`           | a2a-specialist           | server/client/both           | A2A protocol      |
| `interactions`  | interactions-specialist  | session/multi-turn/callbacks | Interactions      |
| `eval`          | evaluation-specialist    | accuracy/latency/quality/all | Evaluation        |
| `observability` | observability-integrator | tracing/logging/metrics/all  | Observability     |
| `deploy`        | deployment-specialist    | cloud-run/vertex-ai/docker   | Deployment        |
