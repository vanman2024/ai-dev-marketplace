---
description: Integrate Celery with Flask application
argument-hint: [project-path]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Integrate Celery task queue with Flask web application, handling app context, factory patterns, and background task execution.

Core Principles:
- Detect Flask patterns (factory vs direct instantiation)
- Preserve Flask application context in tasks
- Share configuration between Flask and Celery
- Follow Flask-Celery best practices

Phase 1: Discovery
Goal: Understand Flask application structure and requirements

Actions:
- Parse $ARGUMENTS for project path (default to current directory)
- Detect Flask application structure:
  - !{bash find . -name "app.py" -o -name "__init__.py" -o -name "wsgi.py" 2>/dev/null | head -5}
- Check for application factory pattern:
  - !{bash grep -r "def create_app" . --include="*.py" 2>/dev/null}
- Identify configuration files:
  - @config.py (if exists)
  - @.env.example (if exists)
- Check for existing Celery setup:
  - !{bash grep -r "from celery import" . --include="*.py" 2>/dev/null}
- Determine Flask version and dependencies:
  - @requirements.txt (if exists)

Phase 2: Planning
Goal: Design Flask-Celery integration approach

Actions:
- Create todo list for integration steps using TodoWrite
- Determine integration pattern based on discovery:
  - Factory pattern if create_app() found
  - Direct instantiation for simple apps
- Identify broker and backend (Redis/RabbitMQ from config or ask)
- Plan task module organization
- Check database requirements (SQLAlchemy sessions in tasks)
- Outline configuration sharing strategy

Phase 3: Implementation
Goal: Execute Flask-Celery integration with agent

Actions:

Task(description="Integrate Celery with Flask", subagent_type="celery:flask-integrator", prompt="You are the flask-integrator agent. Integrate Celery with the Flask application at $ARGUMENTS.

Context from Discovery:
- Flask application structure detected
- Application factory pattern usage identified
- Configuration files analyzed
- Database ORM requirements determined

Requirements:
- Create celery_app.py with Flask-aware Task class
- Implement proper app context handling
- Configure Celery to share Flask configuration
- Create example tasks with context access
- Handle database session management if SQLAlchemy used
- Install required dependencies (celery[redis] or celery[amqp])
- Create .env.example with placeholder broker URLs
- Update .gitignore for environment files
- Provide worker startup commands

Integration Patterns:
- Use FlaskTask base class for app context preservation
- Implement celery_init_app() for factory pattern
- Configure broker_url and result_backend from Flask config
- Register tasks properly for discovery
- Handle proper cleanup and error handling

Expected Output:
- Complete Flask-Celery integration
- Sample tasks demonstrating context usage
- Configuration files with placeholders
- Documentation for running workers
- Verification commands for testing setup")

Phase 4: Verification
Goal: Verify Flask-Celery integration works correctly

Actions:
- Check created files exist:
  - !{bash ls celery_app.py tasks.py .env.example 2>/dev/null}
- Verify Flask app initializes:
  - !{bash python -c "from app import create_app; app=create_app(); print('Flask app created')" 2>&1 || echo "Check import paths"}
- Check Celery configuration:
  - !{bash grep -E "(broker_url|result_backend)" celery_app.py config.py 2>/dev/null}
- Verify no hardcoded credentials:
  - !{bash grep -rE "(redis://.*password|amqp://.*:.+@)" . --include="*.py" && echo "WARNING: Found credentials" || echo "No credentials found"}
- Update TodoWrite with verification results

Phase 5: Summary
Goal: Document integration completion and next steps

Actions:
- Mark all todos complete using TodoWrite
- Display integration summary:
  - Files created (celery_app.py, tasks.py, config updates)
  - Configuration approach used
  - Context handling strategy implemented
  - Sample tasks provided
- Show next steps:
  - Start worker: celery -A app.celery_app worker --loglevel=info
  - Start Flask app: flask run
  - Test task execution from Flask shell or API
  - Monitor tasks with flower (if monitoring added)
- Highlight key files to review:
  - celery_app.py: Celery initialization and Flask context
  - tasks.py: Example background tasks
  - .env.example: Configuration placeholders
  - config.py: Shared Flask-Celery configuration
