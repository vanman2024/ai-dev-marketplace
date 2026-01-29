---
name: agentic-platform-schema
description: Agentic Platform Contract tables for AI agent applications - runs, events, artifacts, and tool calls tracking. Use when building AI agent backends that need structured run/event storage.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Agentic Platform Schema

Supabase schema for the "Agentic Platform Contract" - standardized tables for AI agent runs, events, and artifacts.

## Overview

Standard tables for agentic applications:

- `agent_runs` - Track agent execution runs
- `agent_events` - Stream of events within runs
- `agent_artifacts` - Files/outputs from runs
- `agent_tool_calls` - Tool/function call tracking

## Use When

This skill is automatically invoked when:

- Building AI agent backends
- Tracking agent runs and events
- Storing agent artifacts
- Implementing run history/replay

## Available Scripts

| Script                            | Description            |
| --------------------------------- | ---------------------- |
| `scripts/setup-agentic-schema.sh` | Run Supabase migration |

## Available Templates

| Template                       | Description           |
| ------------------------------ | --------------------- |
| `templates/agentic-schema.sql` | Full schema with RLS  |
| `templates/queries.sql`        | Common query patterns |

## Schema Overview

```
agent_runs (1) ─────< agent_events (many)
     │
     └─────< agent_artifacts (many)
     │
     └─────< agent_tool_calls (many)
```

## Best Practices

1. Use `run_id` to group related events
2. Store structured data in JSONB columns
3. Enable RLS for multi-tenant apps
4. Index `status` and `created_at` for queries
