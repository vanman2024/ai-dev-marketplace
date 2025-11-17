---
description: Full Celery integration with Django project
argument-hint: [django-project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Integrate Celery with Django project, enabling task autodiscovery, transaction-safe dispatching, and result storage

Core Principles:
- Detect Django structure before integrating
- Configure transaction-safe task patterns
- Enable task autodiscovery from Django apps
- Use environment variables for all credentials

Phase 1: Discovery
Goal: Understand Django project structure

Actions:
- Parse $ARGUMENTS for Django project path
- If path not provided, assume current directory
- Detect Django project structure:
  - !{bash find . -name "manage.py" -type f 2>/dev/null | head -1}
  - !{bash find . -name "settings.py" -type f 2>/dev/null | head -1}
- Identify Django project name from settings.py location
- Check existing INSTALLED_APPS for Celery packages
- Load Django settings for context: @*/settings.py

Phase 2: Requirements Gathering
Goal: Determine integration scope

Actions:
- Ask user about integration requirements:
  - Which Django apps will contain Celery tasks?
  - Do you need periodic task scheduling (django-celery-beat)?
  - Should results be stored in Django database (django-celery-results)?
  - What broker will you use (Redis, RabbitMQ, other)?
- Create todo list tracking integration phases:
  - Core Celery setup
  - Django configuration
  - Task autodiscovery
  - Result backend (if needed)
  - Beat scheduler (if needed)
  - Verification

Phase 3: Django Integration
Goal: Integrate Celery with Django project

Actions:

Task(description="Integrate Celery with Django", subagent_type="celery:django-integrator", prompt="You are the django-integrator agent. Integrate Celery with the Django project at $ARGUMENTS.

Context from discovery:
- Django project name: [detected from settings.py]
- INSTALLED_APPS: [current apps]
- Database backend: [detected from settings]

Requirements:
- Create project_name/celery.py with Django settings autodiscovery
- Update project_name/__init__.py to load Celery app on startup
- Add CELERY_* settings to settings.py with environment variables
- Add django-celery-results to INSTALLED_APPS if result storage needed
- Add django-celery-beat to INSTALLED_APPS if periodic tasks needed
- Create example tasks.py in one Django app showing @shared_task
- Implement transaction-safe task dispatch with transaction.on_commit()
- Create/update .env.example with broker and backend URL placeholders
- Add .env to .gitignore if not present
- Run migrations for celery tables (results/beat)
- Document setup in README or docs/

Expected output:
- Fully integrated Django-Celery setup
- celery.py module in project root
- Updated settings.py with CELERY configuration
- Sample tasks demonstrating transaction safety
- Environment variable setup documented
- Migrations applied
- Verification commands provided")

Wait for agent to complete integration.

Phase 4: Verification
Goal: Verify integration works correctly

Actions:
- Check celery.py was created with correct Django integration
- Verify __init__.py imports Celery app
- Confirm settings.py contains CELERY_* configuration
- Test task discovery: !{bash cd $ARGUMENTS && python manage.py shell -c "from django import setup; setup(); from celery import current_app; print(current_app.tasks.keys())"}
- Verify migrations applied: !{bash cd $ARGUMENTS && python manage.py showmigrations | grep celery}
- Check worker can start: !{bash cd $ARGUMENTS && timeout 5 python manage.py celery worker --loglevel=info 2>&1 | head -20}
- Update todos marking verification complete

Phase 5: Summary
Goal: Document integration and provide next steps

Actions:
- Mark all todos complete
- Summarize what was configured:
  - Celery app location and configuration
  - Django settings added
  - Result backend setup (if used)
  - Beat scheduler setup (if used)
  - Example tasks created
  - Transaction-safe patterns implemented
- Provide startup commands:
  - Worker: `python manage.py celery worker -l info`
  - Beat (if used): `python manage.py celery beat -l info`
  - Combined: `python manage.py celery worker -B -l info`
- Show how to test tasks from Django shell
- Highlight transaction safety patterns to follow
- Note environment variables that need real values
