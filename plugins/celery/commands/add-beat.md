---
description: Configure Celery Beat periodic task scheduling with crontab, interval, and custom schedules
argument-hint: [schedule-description]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

---
🚨 **EXECUTION NOTICE FOR CLAUDE**

When you invoke this command via SlashCommand, the system returns THESE INSTRUCTIONS below.

**YOU are the executor. This is NOT an autonomous subprocess.**

- ✅ The phases below are YOUR execution checklist
- ✅ YOU must run each phase immediately using tools (Bash, Read, Write, Edit, TodoWrite)
- ✅ Complete ALL phases before considering this command done
- ❌ DON't wait for "the command to complete" - YOU complete it by executing the phases
- ❌ DON't treat this as status output - it IS your instruction set

**Immediately after SlashCommand returns, start executing Phase 0, then Phase 1, etc.**

See `@CLAUDE.md` section "SlashCommand Execution - YOU Are The Executor" for detailed explanation.

---


**Arguments**: $ARGUMENTS

Goal: Configure Celery Beat periodic task scheduling for automated background jobs

Core Principles:
- Detect existing Celery configuration before adding Beat
- Support multiple schedule types (crontab, interval, solar)
- Configure scheduler backend appropriately
- Integrate with project framework (Django/Flask/FastAPI)
- Validate Beat configuration before deployment

Phase 1: Discovery
Goal: Understand project structure and existing Celery setup

Actions:
- Parse $ARGUMENTS for schedule requirements and task names
- Detect project framework and Celery configuration
- Example: !{bash find . -name "celery.py" -o -name "celeryconfig.py" -o -name "celery_app.py" 2>/dev/null | head -5}
- Check for existing Beat configuration
- Example: !{bash grep -r "beat_schedule" --include="*.py" . 2>/dev/null | head -3}
- Identify tasks directory structure
- Load Celery configuration files for context

Phase 2: Analysis
Goal: Understand current Celery setup and requirements

Actions:
- Read identified Celery configuration files
- Check if Beat is already configured
- Determine scheduler backend (default, DatabaseScheduler, Redis)
- Identify existing tasks that need scheduling
- Verify broker configuration supports Beat

Phase 3: Planning
Goal: Design Beat configuration approach

Actions:
- Determine schedule types needed from $ARGUMENTS:
  - Crontab: for time-based schedules (daily, weekly, monthly)
  - Interval: for fixed intervals (every N seconds/minutes/hours)
  - Solar: for sunrise/sunset-based schedules
  - Custom: for complex scheduling logic
- Choose appropriate scheduler backend:
  - Default: In-memory (development)
  - DatabaseScheduler: Persistent (Django/Flask)
  - Redis: Distributed (production)
- Plan integration with existing tasks
- Outline configuration structure

Phase 4: Implementation
Goal: Configure Celery Beat with scheduled tasks

Actions:

Task(description="Configure Celery Beat scheduling", subagent_type="celery:beat-scheduler-agent", prompt="You are the beat-scheduler-agent. Configure Celery Beat periodic task scheduling for $ARGUMENTS.

Project context: Framework and current Celery setup identified in discovery phase

Requirements:
- Configure beat_schedule in Celery configuration
- Add schedule definitions for specified tasks
- Set up appropriate scheduler backend
- Configure Beat service for framework (Django/Flask/FastAPI)
- Add timezone configuration if needed
- Create example scheduled tasks
- Document schedule format and options
- Add Beat process to deployment configuration

Schedule types to support:
- Crontab: Time-based (minute, hour, day_of_week, day_of_month, month_of_year)
- Interval: Fixed intervals (timedelta or seconds)
- Solar: Sunrise/sunset-based (for applicable use cases)
- Custom: User-defined schedule classes

Expected output:
- Updated Celery configuration with beat_schedule
- Scheduler backend configuration
- Example scheduled tasks
- Beat startup command
- Documentation for adding new schedules")

Phase 5: Verification
Goal: Validate Beat configuration and test scheduled tasks

Actions:
- Check Celery configuration syntax
- Example: !{bash python -c "from celery_app import app; print(app.conf.beat_schedule)" 2>&1 | head -10}
- Verify scheduled tasks are defined correctly
- Test Beat scheduler can start
- Example: !{bash timeout 5 celery -A celery_app beat --loglevel=info 2>&1 || echo "Beat validation check"}
- Review timezone configuration
- Confirm integration with existing tasks

Phase 6: Summary
Goal: Document Beat configuration and usage

Actions:
- Summarize configured schedules:
  - Task names and descriptions
  - Schedule types and timing
  - Scheduler backend used
- Provide Beat startup commands:
  - Development: celery -A app beat
  - Production: supervisord/systemd configuration
- Document how to add new scheduled tasks
- Highlight important configuration options:
  - Timezone settings
  - Max interval for Beat
  - Scheduler backend persistence
- Suggest monitoring and testing steps
