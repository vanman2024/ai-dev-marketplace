# LangGraph Plugin

LLM-native graph orchestration for complex stateful workflows.

## Features

- **State Machine Workflows** - Define complex flows as graphs
- **Durable Execution** - Persist state across runs
- **Human-in-the-Loop** - Interrupt for approval/input
- **Conditional Branching** - Dynamic flow control
- **Checkpointing** - Save and restore state
- **Streaming** - Real-time node outputs

## Quick Start

```bash
# Build complete LangGraph workflow
/langgraph:build my-workflow

# Add specific features
/langgraph:add node           # Add a graph node
/langgraph:add conditional    # Add conditional edge
/langgraph:add checkpoint     # Add state persistence
/langgraph:add human-loop     # Add human interruption
```

## When to Use LangGraph

Use LangGraph when you need:

- Multi-step reasoning with state
- Human approval in AI workflows
- Retry/branching logic
- Persistent conversation state
- Complex agent orchestration

## Agents

- `graph-architect` - Workflow design and structure
- `node-specialist` - Node implementation
- `state-specialist` - State management and persistence

## Documentation

- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [LangGraph JS](https://langchain-ai.github.io/langgraphjs/)
