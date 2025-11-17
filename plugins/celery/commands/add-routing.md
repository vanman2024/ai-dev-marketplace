---
description: Configure task routing to specific queues/workers
argument-hint: [routing-config]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Configure Celery task routing to direct specific tasks to designated queues and workers for optimal workload distribution and resource utilization.

Core Principles:
- Detect existing Celery configuration before modifying
- Route by task priority, resource requirements, or business logic
- Follow Celery routing best practices
- Validate routing configuration before applying

Phase 1: Discovery
Goal: Understand current Celery setup and routing requirements

Actions:
- Parse $ARGUMENTS for routing specification
- Detect project structure and framework
- Example: !{bash ls -la | grep -E "(manage.py|main.py|app.py|celery.py)"}
- Identify existing Celery configuration files
- Example: !{bash find . -name "celery.py" -o -name "celeryconfig.py" 2>/dev/null}
- Load current configuration to understand baseline
- Check for existing queue definitions

Phase 2: Analysis
Goal: Understand current architecture and identify routing needs

Actions:
- Read Celery configuration files
- Example: @celery.py or @celeryconfig.py
- Scan for existing task definitions
- Example: !{bash grep -r "@shared_task\|@task\|@app.task" --include="*.py" | head -20}
- Identify current queue setup and worker configuration
- Determine routing requirements from $ARGUMENTS

Phase 3: Planning
Goal: Design routing strategy

Actions:
- Determine routing approach:
  - Task name patterns (default.*, email.*, reports.*)
  - Task priority levels (high, medium, low)
  - Resource requirements (cpu-intensive, io-bound, memory-intensive)
  - Business domain (billing, notifications, analytics)
- Plan queue definitions needed
- Design routing rules and exchange configuration
- Outline worker startup commands for each queue

Phase 4: Implementation
Goal: Configure routing with worker-architect agent

Actions:

Task(description="Configure task routing", subagent_type="celery:worker-architect", prompt="You are the worker-architect agent. Configure Celery task routing for $ARGUMENTS.

Context: Setting up task routing to direct specific tasks to designated queues and workers.

Requirements:
- Define queues with appropriate names and priorities
- Configure task_routes to map tasks to queues
- Set up task_queue_max_priority if using priority queues
- Configure worker_prefetch_multiplier for each queue type
- Add task_default_queue and task_default_exchange settings
- Include routing documentation in comments
- Provide worker startup commands for each queue

Routing Configuration Should Include:
- Queue definitions with exchange and routing key
- Task routing rules (glob patterns or explicit names)
- Priority settings if applicable
- Worker configuration for optimal performance
- Example startup commands for production

Expected Output:
- Updated Celery configuration with routing rules
- Queue definitions
- Worker startup commands
- Documentation on how to test routing")

Phase 5: Verification
Goal: Validate routing configuration

Actions:
- Check that configuration files are syntactically correct
- Example: !{bash python -m py_compile celery.py 2>&1}
- Verify queue definitions are complete
- Ensure task routes are properly configured
- Review worker startup commands for correctness
- Test configuration if Celery is available
- Example: !{bash celery -A myapp inspect active_queues 2>/dev/null || echo "Start workers to verify"}

Phase 6: Summary
Goal: Report routing configuration results

Actions:
- Display configured queues and their purposes
- Show task routing rules that were added
- Present worker startup commands for each queue
- Provide testing instructions:
  - How to start workers for specific queues
  - How to send tasks to specific queues
  - How to verify routing is working
- Suggest monitoring and optimization strategies
