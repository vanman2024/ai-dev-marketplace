---
name: queue-patterns
description: BullMQ queue configuration patterns including connection pooling, job options, rate limiting, and TypeScript types. Use when setting up queues or configuring job behavior.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebFetch
---

# Queue Patterns

Skill for BullMQ queue configuration and management.

## Overview

Configure queues with:

- Redis connection pooling
- Default job options
- Rate limiting
- TypeScript type safety

## Use When

This skill is automatically invoked when:

- Setting up new queues
- Configuring job options
- Adding rate limiting
- Creating typed job definitions

## Available Scripts

| Script                   | Description               |
| ------------------------ | ------------------------- |
| `scripts/init-bullmq.sh` | Initialize BullMQ project |

## Available Templates

| Template                  | Description          |
| ------------------------- | -------------------- |
| `templates/connection.ts` | Redis connection     |
| `templates/queue.ts`      | Queue definition     |
| `templates/types.ts`      | Job type definitions |
