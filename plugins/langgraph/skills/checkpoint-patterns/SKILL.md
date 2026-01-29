---
name: checkpoint-patterns
description: LangGraph checkpointing patterns for state persistence with memory, SQLite, and Postgres backends. Use when implementing state recovery or human-in-the-loop workflows.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Checkpoint Patterns

Skill for LangGraph state persistence and checkpointing.

## Overview

Persist state with:

- Memory checkpointer (dev)
- SQLite checkpointer
- Postgres checkpointer

## Use When

This skill is automatically invoked when:

- Adding state persistence
- Implementing human-in-the-loop
- Recovering from failures
- Managing thread state

## Available Templates

| Template                           | Description           |
| ---------------------------------- | --------------------- |
| `templates/memory_checkpoint.py`   | In-memory persistence |
| `templates/postgres_checkpoint.py` | Postgres persistence  |
