---
description: Add LangGraph feature to existing workflow. Features include node, conditional, checkpoint, human-loop.
argument-hint: <feature> [options]
---

# Add LangGraph Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

### Node

**If `$0` = "node":**

```
Task(node-specialist) Add node.

Requirements:
- Node name: $1 (required)
- Node type: $2 (llm, tool, router - default: llm)
- Implement node function
- Add to graph
```

### Conditional

**If `$0` = "conditional":**

```
Task(graph-architect) Add conditional edge.

Requirements:
- From node: $1 (required)
- Create routing function
- Define target nodes
```

### Checkpoint

**If `$0` = "checkpoint":**

```
Task(state-specialist) Add checkpointing.

Requirements:
- Backend: $1 (memory, sqlite, postgres - default: memory)
- Configure checkpointer
- Add thread support
```

### Human-in-the-Loop

**If `$0` = "human-loop":**

```
Task(state-specialist) Add human interrupt.

Requirements:
- Interrupt point: $1 (node name)
- Configure interrupt_before/after
- Add approval handling
```

---

## Usage Examples

```bash
/langgraph:add node research llm
/langgraph:add node classifier router
/langgraph:add conditional research
/langgraph:add checkpoint postgres
/langgraph:add human-loop approval
```
