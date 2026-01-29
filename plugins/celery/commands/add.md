---
description: Add a specific feature to an existing Celery project. Features include task, beat, workflow, monitoring, deploy.
argument-hint: <feature> [options]
---

# Add Celery Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Task Features

**If `$0` = "task":**

```
Task(task-generator-agent) Add new CELERY TASK to this project.

Requirements:
- Task name: $1 (required)
- Task type: $2 (async, sync, bound - default: async)
- Create task function
- Add retry logic
- Configure task routing
- Add error handling
```

### Scheduler Features

**If `$0` = "beat":**

```
Task(beat-scheduler-agent) Add BEAT scheduled task.

Requirements:
- Task name: $1 (required)
- Schedule: $2 (crontab expression or interval)
- Configure periodic task
- Add to beat schedule
- Set up task arguments
```

### Workflow Features

**If `$0` = "workflow":**

```
Task(workflow-specialist) Add task WORKFLOW.

Requirements:
- Workflow type: $1 (chain, group, chord, canvas - default: chain)
- Create workflow tasks
- Configure task chaining
- Add error handling
- Set up result aggregation
```

### Monitoring Features

**If `$0` = "monitoring":**

```
Task(monitoring-integrator) Add MONITORING capabilities.

Requirements:
- Monitor type: $1 (flower, prometheus, custom - default: flower)
- Set up monitoring tool
- Configure metrics
- Add alerting
- Create dashboards
```

### Deployment Features

**If `$0` = "deploy":**

```
Task(deployment-architect) Add DEPLOYMENT configuration.

Requirements:
- Platform: $1 (docker, kubernetes, systemd - default: docker)
- Create deployment configs
- Set up scaling
- Configure health checks
- Add logging
```

---

## Usage Examples

```bash
# Add tasks
/celery:add task send-email
/celery:add task process-data async

# Add scheduled tasks
/celery:add beat cleanup-old-data "0 2 * * *"
/celery:add beat sync-data "*/15 * * * *"

# Add workflows
/celery:add workflow chain
/celery:add workflow chord

# Add monitoring
/celery:add monitoring flower
/celery:add monitoring prometheus

# Add deployment
/celery:add deploy docker
/celery:add deploy kubernetes
```

---

## Feature Reference

| Feature      | Agent               | $1 Options                | Description       |
| ------------ | ------------------- | ------------------------- | ----------------- |
| `task`       | task-generator      | task-name (required)      | Add Celery task   |
| `beat`       | beat-scheduler      | task-name, schedule       | Periodic task     |
| `workflow`   | workflow-specialist | chain/group/chord/canvas  | Task workflows    |
| `monitoring` | monitoring          | flower/prometheus/custom  | Monitoring setup  |
| `deploy`     | deployment          | docker/kubernetes/systemd | Deployment config |
