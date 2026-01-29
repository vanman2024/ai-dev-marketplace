---
description: Build complete A2A Protocol integration for new or existing projects with agent cards, executors, discovery, streaming, and production deployment
argument-hint: [project-name] [--existing]
---

# Build A2A Protocol Stack

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Argument Routing

**If `$1` = "--existing" or project files detected:**

- Skip project scaffold
- Analyze existing codebase
- Add A2A integration to current structure

**If new project (no `$1`):**

- Create project scaffold
- Set up A2A from scratch
- Generate all configuration files

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

1. Check if existing project:

   ```bash
   test -f package.json || test -f pyproject.toml || test -f go.mod
   ```

2. If existing, analyze structure:

   ```
   Task(a2a-setup) Analyze project structure for A2A integration.

   Read: package.json, pyproject.toml, existing agent files
   Identify: Language, framework, existing agents
   Output: Integration strategy
   ```

3. If new, ask requirements:
   - "What language? (TypeScript, Python, Go)"
   - "What framework? (Express, FastAPI, Gin)"
   - "Project name?" (use `$0` if provided)

---

## Phase 2: Core Setup

**Goal:** Establish A2A Protocol foundation

**Actions:**

```
Task(a2a-setup) Set up A2A Protocol core infrastructure.

Requirements:
- Initialize project structure (if new)
- Install A2A dependencies
- Create base configuration
- Set up agent registry
- Configure A2A Protocol version (latest)
```

---

## Phase 3: Agent Infrastructure

**Goal:** Create agent card and executor patterns

**Actions:**

```
Task(a2a-agent-builder) Create base agent infrastructure.

Requirements:
- Generate agent card template (JSON-LD format)
- Create agent executor base class
- Implement AgentCard interface
- Set up agent registration system
- Add sample agent for reference
```

---

## Phase 4: Client Integration

**Goal:** Add A2A client capabilities

**Actions:**

```
Task(a2a-client-builder) Implement A2A client infrastructure.

Requirements:
- Create A2A client class
- Implement sendTask(), getTask(), cancelTask()
- Add authentication handling
- Configure request/response types
- Set up error handling
```

---

## Phase 5: Discovery Service

**Goal:** Implement agent discovery

**Actions:**

```
Task(a2a-discovery) Set up agent discovery service.

Requirements:
- Implement /.well-known/agent.json endpoint
- Create agent registry with search
- Add capability-based discovery
- Configure agent metadata indexing
- Enable dynamic agent registration
```

---

## Phase 6: Streaming Support

**Goal:** Add real-time streaming

**Actions:**

```
Task(a2a-streaming) Implement A2A streaming.

Requirements:
- Set up Server-Sent Events (SSE)
- Implement streaming task responses
- Add partial result handling
- Configure heartbeat/keepalive
- Handle stream cancellation
```

---

## Phase 7: Production Hardening

**Goal:** Prepare for production deployment

**Actions:**

```
Task(a2a-production) Configure production settings.

Requirements:
- Add authentication middleware
- Implement rate limiting
- Set up logging and monitoring
- Configure CORS and security headers
- Create health check endpoints
- Add graceful shutdown handling
```

---

## Phase 8: Verification

**Goal:** Validate A2A compliance

**Actions:**

```
Task(a2a-verifier) Verify A2A Protocol compliance.

Requirements:
- Validate agent card schema
- Test discovery endpoints
- Verify streaming functionality
- Check authentication flow
- Run A2A conformance tests
```

---

## Phase 9: Summary

**Goal:** Provide next steps

**Output:**

```
✅ A2A Protocol Stack Complete

Created:
- Agent card infrastructure
- A2A client implementation
- Discovery service
- Streaming support
- Production configuration

To add features:
  /a2a-protocol:add agent <name>        # Add new agent
  /a2a-protocol:add client <name>       # Add client integration
  /a2a-protocol:add discovery           # Enhanced discovery
  /a2a-protocol:add streaming           # Additional streaming
  /a2a-protocol:add production          # More production features
  /a2a-protocol:add test                # Test suite

To run:
  npm run dev  # or python main.py, go run .

Resources:
  📖 A2A Spec: https://google.github.io/A2A/
```
