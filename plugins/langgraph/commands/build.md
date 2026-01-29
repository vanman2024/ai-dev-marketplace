---
description: Build complete LangGraph workflow with state management, nodes, and persistence
argument-hint: [project-name] [--existing]
---

# Build LangGraph Workflow

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Setup

**Goal:** Initialize LangGraph project

**Actions:**

```
Task(graph-architect) Set up LangGraph project.

Requirements:
- Install langgraph (Python) or @langchain/langgraph (JS)
- Create workflow directory structure
- Configure environment variables
- Set up state schema
```

---

## Phase 2: State Definition

**Goal:** Define workflow state

**Actions:**

```
Task(state-specialist) Define state schema.

Requirements:
- Create TypedDict/Interface for state
- Define state channels
- Configure reducers
- Add state validation
```

---

## Phase 3: Node Implementation

**Goal:** Create workflow nodes

**Actions:**

```
Task(node-specialist) Implement nodes.

Requirements:
- Create node functions
- Handle state input/output
- Add error handling
- Implement retry logic
```

---

## Phase 4: Graph Assembly

**Goal:** Wire nodes into graph

**Actions:**

```
Task(graph-architect) Assemble graph.

Requirements:
- Add nodes to graph
- Configure edges
- Add conditional routing
- Set entry/exit points
```

---

## Phase 5: Persistence

**Goal:** Add state checkpointing

**Actions:**

```
Task(state-specialist) Configure persistence.

Requirements:
- Set up checkpointer (memory/sqlite/postgres)
- Configure thread management
- Add state recovery
- Handle interrupts
```

---

## Summary

**Output:**

```
✅ LangGraph Workflow Complete

Structure:
  workflows/
  ├── state.py           # State definition
  ├── nodes/
  │   ├── __init__.py
  │   └── research.py
  ├── graph.py           # Graph assembly
  └── run.py             # Execution

Run workflow:
  python workflows/run.py
```
