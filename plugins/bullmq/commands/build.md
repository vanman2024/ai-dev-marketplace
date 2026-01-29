---
description: Build complete BullMQ job queue system with workers, queues, and dashboard
argument-hint: [project-name] [--existing]
---

# Build BullMQ System

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Setup

**Goal:** Initialize BullMQ project

**Actions:**

```
Task(bullmq-architect) Set up BullMQ project.

Requirements:
- Install bullmq, ioredis
- Configure Redis connection
- Create queue directory structure
- Set up environment variables
```

---

## Phase 2: Queue Creation

**Goal:** Create job queues

**Actions:**

```
Task(bullmq-architect) Create queues.

Requirements:
- Define queue configurations
- Set up connection pooling
- Configure job options (retries, backoff)
- Add TypeScript types
```

---

## Phase 3: Worker Setup

**Goal:** Create workers to process jobs

**Actions:**

```
Task(worker-specialist) Create workers.

Requirements:
- Implement job processors
- Configure concurrency
- Add error handling
- Set up graceful shutdown
- Add logging
```

---

## Phase 4: Dashboard

**Goal:** Add Bull Board monitoring

**Actions:**

```
Task(bullmq-architect) Set up Bull Board.

Requirements:
- Install @bull-board packages
- Configure Express adapter
- Add authentication
- Create dashboard route
```

---

## Phase 5: Scheduler

**Goal:** Add repeatable jobs

**Actions:**

```
Task(scheduler-specialist) Configure scheduling.

Requirements:
- Set up repeatable jobs
- Add cron patterns
- Configure delayed jobs
- Add job cleanup
```

---

## Summary

**Output:**

```
✅ BullMQ System Complete

Structure:
  workers/
  ├── lib/
  │   ├── connection.ts
  │   └── queues.ts
  ├── workers/
  │   └── example.worker.ts
  ├── jobs/
  │   └── example.job.ts
  └── dashboard/
      └── server.ts

Start workers:
  npx tsx workers/workers/example.worker.ts

View dashboard:
  npx tsx workers/dashboard/server.ts
  Open http://localhost:3001/admin/queues
```
