# BullMQ Plugin

TypeScript-native durable job queue with Redis for background task processing.

## Features

- **Durable Jobs** - Persist jobs in Redis, survive restarts
- **Retries & Backoff** - Automatic retry with exponential backoff
- **Rate Limiting** - Control job processing rate
- **Priorities** - Job prioritization
- **Delayed Jobs** - Schedule jobs for later
- **Repeatable Jobs** - Cron-like scheduling
- **Worker Concurrency** - Process multiple jobs in parallel
- **Stalled Job Detection** - Handle crashed workers

## Quick Start

```bash
# Build complete BullMQ system
/bullmq:build my-workers

# Add specific features
/bullmq:add queue           # Add a new queue
/bullmq:add worker          # Add a worker
/bullmq:add dashboard       # Add Bull Board UI
/bullmq:add scheduler       # Add repeatable jobs
```

## Why BullMQ?

BullMQ is the TypeScript equivalent of Celery for Python:

- Native TypeScript/JavaScript
- Redis-backed durability
- Production-ready at scale
- Active maintenance

## Agents

- `bullmq-architect` - Queue design and architecture
- `worker-specialist` - Worker implementation
- `scheduler-specialist` - Repeatable/delayed jobs

## Documentation

- [BullMQ Docs](https://docs.bullmq.io/)
- [Bull Board](https://github.com/felixmosh/bull-board)
