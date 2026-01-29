---
name: worker-patterns
description: BullMQ worker implementation patterns including job processors, concurrency, error handling, and graceful shutdown. Use when creating workers or handling job processing.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Worker Patterns

Skill for implementing BullMQ workers.

## Overview

Implement workers with:

- Job processor functions
- Concurrency control
- Error handling
- Graceful shutdown

## Use When

This skill is automatically invoked when:

- Creating job workers
- Implementing processors
- Handling worker errors
- Managing worker lifecycle

## Available Templates

| Template                | Description           |
| ----------------------- | --------------------- |
| `templates/worker.ts`   | Basic worker template |
| `templates/producer.ts` | Job producer template |
