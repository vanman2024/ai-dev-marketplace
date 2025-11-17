---
description: Configure worker pools and concurrency
argument-hint: [pool-type] [options]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Configure Celery workers with optimal pool types and concurrency settings based on project requirements

Core Principles:
- Detect existing Celery configuration before modifying
- Choose pool type based on workload characteristics
- Set concurrency based on CPU cores and task types
- Provide clear worker configuration documentation

Phase 1: Discovery
Goal: Understand project structure and current worker configuration

Actions:
- Parse $ARGUMENTS for pool type preference (prefork, gevent, eventlet, solo, threads)
- Detect project type and existing Celery setup
- Example: !{bash ls celery.py celeryconfig.py worker.py tasks.py 2>/dev/null || echo "No Celery files found"}
- Find existing worker configuration:
  - @celery.py
  - @celeryconfig.py
  - @worker.py
- Check for existing pool and concurrency settings

Phase 2: Analysis
Goal: Determine optimal worker configuration

Actions:
- Analyze task types if tasks.py exists
- Count CPU cores for concurrency defaults
- Example: !{bash nproc || python3 -c "import os; print(os.cpu_count())"}
- Review task characteristics:
  - CPU-bound vs I/O-bound
  - Long-running vs short tasks
  - Memory requirements
- Identify appropriate pool type:
  - **prefork**: CPU-bound tasks (default)
  - **gevent**: I/O-bound, many concurrent tasks
  - **eventlet**: Similar to gevent, alternative greenlet implementation
  - **threads**: Thread-based concurrency
  - **solo**: Single worker, debugging

Phase 3: Implementation
Goal: Configure workers with architect agent

Actions:

Task(description="Configure Celery workers", subagent_type="celery:worker-architect", prompt="You are the celery:worker-architect agent. Configure Celery workers for $ARGUMENTS.

Current project context:
- Detected pool type preference: [from $ARGUMENTS or auto-detect]
- CPU cores available: [from nproc]
- Existing configuration: [from celeryconfig.py or celery.py]

Requirements:
- Set appropriate pool type (prefork/gevent/eventlet/threads/solo)
- Configure concurrency based on pool type and CPU cores
- Set worker autoscaling if applicable
- Configure worker prefetch settings
- Set time limits (soft/hard)
- Configure memory management (max-tasks-per-child)
- Add worker monitoring hooks if needed
- Create worker startup script

Deliverable:
- Updated worker configuration files
- Worker startup script with proper arguments
- Documentation of worker settings and rationale")

Phase 4: Verification
Goal: Validate worker configuration

Actions:
- Check generated configuration files exist
- Verify pool type is set correctly
- Confirm concurrency settings are appropriate
- Review worker startup script
- Example: !{bash cat worker.py 2>/dev/null | grep -E "pool|concurrency|autoscale"}
- Test worker configuration syntax (dry run if possible)

Phase 5: Summary
Goal: Document worker configuration

Actions:
- Display configured settings:
  - Pool type and rationale
  - Concurrency settings
  - Autoscaling configuration
  - Memory limits
  - Time limits
- Show worker startup command
- Provide next steps:
  - Test worker: `celery -A app worker --loglevel=info`
  - Monitor workers: `celery -A app inspect stats`
  - Scale workers: `celery -A app control pool_grow N`
- Document performance tuning considerations
