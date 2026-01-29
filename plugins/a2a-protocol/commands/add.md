---
description: Add a specific feature to an existing A2A Protocol project. Features include agent, client, discovery, streaming, production, test.
argument-hint: <feature> [options]
---

# Add A2A Protocol Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Agent Features

**If `$0` = "agent":**

```
Task(a2a-agent-builder) Add new A2A AGENT to this project.

Requirements:
- Agent name: $1 (required)
- Agent description: $2 (optional)
- Create agent card (JSON-LD format)
- Implement agent executor
- Register in agent registry
- Add capability definitions
- Generate sample tasks
```

### Client Features

**If `$0` = "client":**

```
Task(a2a-client-builder) Add A2A CLIENT integration to this project.

Requirements:
- Client name: $1 (optional, defaults to "a2a-client")
- Target agent URL: $2 (optional)
- Implement sendTask(), getTask(), cancelTask()
- Add authentication handling
- Configure retry logic
- Set up response parsing
```

### Discovery Features

**If `$0` = "discovery":**

```
Task(a2a-discovery) Add DISCOVERY features to this project.

Requirements:
- Discovery type: $1 (registry, wellknown, search - default: wellknown)
- Implement /.well-known/agent.json endpoint
- Create agent registry
- Add capability-based search
- Configure metadata indexing
```

### Streaming Features

**If `$0` = "streaming":**

```
Task(a2a-streaming) Add STREAMING support to this project.

Requirements:
- Stream type: $1 (sse, websocket - default: sse)
- Implement streaming task responses
- Add partial result handling
- Configure heartbeat
- Handle stream cancellation
- Support artifact streaming
```

### Production Features

**If `$0` = "production":**

```
Task(a2a-production) Add PRODUCTION features to this project.

Requirements:
- Feature type: $1 (auth, ratelimit, logging, security, health, all - default: all)
- Add authentication middleware
- Implement rate limiting
- Set up logging/monitoring
- Configure security headers
- Create health endpoints
```

### Testing Features

**If `$0` = "test":**

```
Task(a2a-verifier) Add TEST suite for A2A compliance.

Requirements:
- Test type: $1 (unit, integration, conformance, all - default: all)
- Create agent card validation tests
- Add discovery endpoint tests
- Implement streaming tests
- Add authentication tests
- Generate conformance report
```

---

## Usage Examples

```bash
# Add agents
/a2a-protocol:add agent code-reviewer "Reviews pull requests"
/a2a-protocol:add agent data-analyst "Analyzes datasets"

# Add client
/a2a-protocol:add client
/a2a-protocol:add client main-client https://api.example.com

# Add discovery
/a2a-protocol:add discovery
/a2a-protocol:add discovery registry

# Add streaming
/a2a-protocol:add streaming
/a2a-protocol:add streaming websocket

# Add production
/a2a-protocol:add production auth
/a2a-protocol:add production all

# Add tests
/a2a-protocol:add test
/a2a-protocol:add test conformance
```

---

## Feature Reference

| Feature      | Agent          | $1 Options                                 | Description         |
| ------------ | -------------- | ------------------------------------------ | ------------------- |
| `agent`      | agent-builder  | agent-name (required)                      | Add new agent       |
| `client`     | client-builder | client-name                                | A2A client          |
| `discovery`  | discovery      | registry/wellknown/search                  | Agent discovery     |
| `streaming`  | streaming      | sse/websocket                              | Real-time streaming |
| `production` | production     | auth/ratelimit/logging/security/health/all | Production features |
| `test`       | verifier       | unit/integration/conformance/all           | Test suite          |
