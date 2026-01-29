---
description: Add BullMQ feature to existing project. Features include queue, worker, dashboard, scheduler.
argument-hint: <feature> [options]
---

# Add BullMQ Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

### Queue

**If `$0` = "queue":**

```
Task(bullmq-architect) Add queue.

Requirements:
- Queue name: $1 (required)
- Configure job options
- Add TypeScript types
- Create producer functions
```

### Worker

**If `$0` = "worker":**

```
Task(worker-specialist) Add worker.

Requirements:
- Queue name: $1 (required)
- Concurrency: $2 (default: 5)
- Implement processor
- Add error handling
- Configure graceful shutdown
```

### Dashboard

**If `$0` = "dashboard":**

```
Task(bullmq-architect) Add Bull Board dashboard.

Requirements:
- Port: $1 (default: 3001)
- Install @bull-board packages
- Configure Express adapter
- Add all queues
```

### Scheduler

**If `$0` = "scheduler":**

```
Task(scheduler-specialist) Add scheduler.

Requirements:
- Job type: $1 (cron, delayed, repeatable)
- Configure patterns
- Add cleanup rules
```

---

## Usage Examples

```bash
/bullmq:add queue email-notifications
/bullmq:add worker email-notifications 10
/bullmq:add dashboard 3001
/bullmq:add scheduler cron
```
