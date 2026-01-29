---
description: Build complete Celery task queue system for new or existing projects with workers, beat scheduler, monitoring, and deployment
argument-hint: [project-name] [--existing]
---

# Build Celery Queue System

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

1. Check if existing project and framework:

   ```
   Task(celery-setup-agent) Analyze project for Celery integration.

   Detect: Django, FastAPI, Flask, or standalone
   Check: Existing broker (Redis, RabbitMQ)
   Output: Integration strategy
   ```

2. If new, ask requirements:
   - "Framework? (Django, FastAPI, Flask, standalone)"
   - "Broker? (Redis, RabbitMQ)"
   - "Use Celery Beat scheduler? (yes/no)"

---

## Phase 2: Core Setup

**Goal:** Set up Celery infrastructure

**Actions:**

```
Task(celery-setup-agent) Set up Celery core infrastructure.

Requirements:
- Install celery and broker client
- Create celery.py configuration
- Configure broker connection
- Set up result backend
- Create base task class
```

---

## Phase 3: Framework Integration

**Goal:** Integrate with web framework

**Actions:**

**If Django:**

```
Task(django-integrator) Integrate Celery with Django.
```

**If FastAPI:**

```
Task(fastapi-integrator) Integrate Celery with FastAPI.
```

**If Flask:**

```
Task(flask-integrator) Integrate Celery with Flask.
```

---

## Phase 4: Worker Setup

**Goal:** Configure Celery workers

**Actions:**

```
Task(worker-architect) Set up Celery workers.

Requirements:
- Create worker configuration
- Set up concurrency settings
- Configure task routing
- Add worker health checks
```

---

## Phase 5: Beat Scheduler

**Goal:** Add periodic task scheduling

**Actions:**

```
Task(beat-scheduler-agent) Set up Celery Beat.

Requirements:
- Configure beat scheduler
- Set up periodic task registry
- Add schedule persistence
- Create example periodic tasks
```

---

## Phase 6: Monitoring

**Goal:** Add monitoring capabilities

**Actions:**

```
Task(monitoring-integrator) Set up Celery monitoring.

Requirements:
- Install Flower for web UI
- Configure task tracking
- Add error reporting
- Set up metrics collection
```

---

## Phase 7: Deployment

**Goal:** Prepare for production

**Actions:**

```
Task(deployment-architect) Configure deployment.

Requirements:
- Create Dockerfile for workers
- Set up docker-compose
- Configure environment variables
- Add health checks
- Create deployment scripts
```

---

## Phase 8: Summary

**Output:**

```
✅ Celery Queue System Complete

To add features:
  /celery:add task <name>           # Add new task
  /celery:add beat <schedule>       # Add periodic task
  /celery:add workflow              # Add task workflow
  /celery:add monitoring            # Enhanced monitoring
  /celery:add deploy                # Deployment configs

To run:
  celery -A app worker --loglevel=info
  celery -A app beat --loglevel=info
```
