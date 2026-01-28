---
description: Build complete Celery task queue - initializes if needed, then runs specialized agents for workers, scheduling, monitoring, and framework integration
argument-hint: <project-name> [--framework <fastapi|django|flask>]
---

# Build Complete Celery Task Queue

**Goal:** Create a production-ready Celery task queue by orchestrating all specialized agents.

**This command handles everything** - from setup to full integration with workers, beat scheduling, monitoring, and framework integration.

## Stack (Always Use Latest Versions)

- **Celery** - Latest with async support
- **Redis/RabbitMQ** - Latest message broker
- **Flower** - Latest for monitoring
- **celery-beat** - Latest for scheduling

**IMPORTANT:** Always use the latest Celery versions. Check `pip index versions celery` for current version.

## Arguments

- `$ARGUMENTS` - Project name and optional framework
- `--framework <name>` - Target framework (fastapi, django, flask)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and framework
2. Auto-detect framework if not specified
3. Discover architecture documentation for task requirements
4. Plan task queue structure based on use cases

### Phase 2: Celery Setup

```
Task("Initialize Celery", @celery-setup-agent, {
  prompt: "Initialize Celery task queue:
    - Install celery and dependencies (latest)
    - Configure broker (Redis by default)
    - Create celery app configuration
    - Set up task discovery
    Detect framework and configure appropriately."
})
```

### Phase 3: Parallel Agent Execution

```
// Agent 1: Worker Architecture
Task("Design worker architecture", @worker-architect, {
  prompt: "Design worker deployment:
    - Configure worker concurrency
    - Set up task routing and queues
    - Define prefetch and rate limits
    - Plan worker scaling strategy
    Follow requirements from architecture docs."
})

// Agent 2: Task Generation
Task("Generate tasks", @task-generator-agent, {
  prompt: "Generate task definitions:
    - Create task modules from architecture
    - Implement retry policies
    - Add error handling
    - Set up result backends
    Generate all tasks specified in docs."
})

// Agent 3: Beat Scheduling
Task("Setup scheduling", @beat-scheduler-agent, {
  prompt: "Configure periodic tasks:
    - Set up celery-beat
    - Define scheduled tasks from architecture
    - Configure crontab schedules
    - Add dynamic scheduling if needed
    Follow schedule requirements from docs."
})

// Agent 4: Broker Configuration
Task("Configure broker", @broker-specialist, {
  prompt: "Optimize message broker:
    - Configure Redis/RabbitMQ connection
    - Set up connection pooling
    - Configure message serialization
    - Add broker failover if needed
    Optimize for reliability."
})

// Agent 5: Framework Integration
Task("Integrate framework", @fastapi-integrator, {
  prompt: "Integrate with detected framework:
    - Add celery to app initialization
    - Create task trigger endpoints
    - Implement task status checking
    - Add async task execution
    Use appropriate framework patterns."
})

// Agent 6: Monitoring
Task("Setup monitoring", @monitoring-integrator, {
  prompt: "Configure monitoring:
    - Set up Flower dashboard
    - Add Prometheus metrics
    - Configure alerting
    - Add health checks
    Enable production observability."
})
```

### Phase 4: Deployment Configuration

```
Task("Configure deployment", @deployment-architect, {
  prompt: "Prepare deployment:
    - Docker Compose with workers
    - Supervisor/systemd configs
    - Worker scaling scripts
    - Production environment setup
    Output deployment documentation."
})
```

### Phase 5: Final Output

**Provide summary:**
- List all tasks created
- Show worker configuration
- Provide run commands:
  ```bash
  # Start worker
  celery -A app worker -l INFO
  
  # Start beat
  celery -A app beat -l INFO
  
  # Start Flower
  celery -A app flower
  ```

## Utility Commands

- `/celery:add-task` - Add single task
- `/celery:add-beat` - Add periodic scheduling
- `/celery:add-monitoring` - Add Flower/metrics
- `/celery:integrate-fastapi` - FastAPI integration
- `/celery:integrate-django` - Django integration
