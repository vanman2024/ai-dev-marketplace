---
description: Build complete Google ADK (Agent Development Kit) project for new or existing projects with agent creation, tools, streaming, and A2A protocol
argument-hint: [project-name] [--existing]
---

# Build Google ADK Project

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(google-adk-setup-agent) Analyze project for Google ADK setup.

Detect: Python version, existing dependencies
Check: pyproject.toml, requirements.txt
Output: Setup strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up Google ADK environment

**Actions:**

```
Task(google-adk-setup-agent) Set up ADK core.

Requirements:
- Install google-adk
- Configure API credentials
- Set up project structure
- Create agent template
- Test basic functionality
```

---

## Phase 3: Agent Creation

**Goal:** Create base agent

**Actions:**

```
Task(google-adk-agent-builder) Create base agent.

Requirements:
- Define agent configuration
- Set up system instructions
- Configure model (Gemini)
- Add basic capabilities
- Create agent file structure
```

---

## Phase 4: Tools Integration

**Goal:** Add tools to agent

**Actions:**

```
Task(google-adk-tools-integrator) Set up agent tools.

Requirements:
- Create custom tools
- Add built-in tools
- Configure tool schemas
- Set up tool handlers
- Test tool execution
```

---

## Phase 5: Interactions

**Goal:** Set up agent interactions

**Actions:**

```
Task(google-adk-interactions-specialist) Configure interactions.

Requirements:
- Set up Runner
- Configure session handling
- Add context management
- Implement callbacks
- Handle multi-turn conversations
```

---

## Phase 6: Streaming

**Goal:** Add streaming support

**Actions:**

```
Task(google-adk-streaming-specialist) Configure streaming.

Requirements:
- Set up streaming runner
- Handle partial responses
- Configure event handlers
- Add real-time output
```

---

## Phase 7: Observability

**Goal:** Add monitoring

**Actions:**

```
Task(google-adk-observability-integrator) Set up observability.

Requirements:
- Configure tracing
- Add logging
- Set up metrics
- Create dashboards
```

---

## Phase 8: Deployment

**Goal:** Prepare for production

**Actions:**

```
Task(google-adk-deployment-specialist) Configure deployment.

Requirements:
- Create deployment config
- Set up Cloud Run/Vertex AI
- Configure scaling
- Add health checks
```

---

## Summary

**Output:**

```
✅ Google ADK Project Complete

To add features:
  /google-adk:add agent <name>          # Add new agent
  /google-adk:add tool <name>           # Add custom tool
  /google-adk:add streaming             # Add streaming
  /google-adk:add a2a                   # A2A protocol
  /google-adk:add eval                  # Evaluation
  /google-adk:add deploy <platform>     # Deployment

To run:
  python -m agent_name
```
