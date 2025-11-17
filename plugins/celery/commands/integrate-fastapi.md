---
description: Integrate Celery with FastAPI with async support
argument-hint: [options]
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

Goal: Integrate Celery task queues with FastAPI applications for async background processing

Core Principles:
- Detect existing FastAPI and Celery setup before acting
- Configure async-compatible task submission and tracking
- Implement complete task lifecycle with status endpoints
- Ensure production-ready error handling and monitoring

Phase 1: Discovery
Goal: Understand existing FastAPI and Celery configuration

Actions:
- Parse $ARGUMENTS for integration options and requirements
- Detect FastAPI application structure:
  - !{bash find . -name "main.py" -o -name "app.py" | grep -v "__pycache__" | head -5}
- Check for existing Celery configuration:
  - !{bash find . -name "celery*.py" -o -name "tasks.py" | grep -v "__pycache__" | head -5}
- Load package configuration to understand dependencies:
  - @requirements.txt (if exists)
  - @pyproject.toml (if exists)
  - @package.json (if exists)
- Check current FastAPI routes and structure

Phase 2: Analysis
Goal: Assess integration requirements and current state

Actions:
- Analyze FastAPI application architecture:
  - Current routing structure
  - Middleware configuration
  - Dependency injection patterns in use
- Review existing Celery setup (if any):
  - Broker configuration
  - Task definitions
  - Result backend setup
- Identify integration points:
  - Where to add task submission endpoints
  - Status tracking endpoint design
  - Health check integration
- Check for async/await compatibility requirements

Phase 3: Planning
Goal: Design FastAPI-Celery integration approach

Actions:
- Plan directory structure for integration:
  - app/celery_app.py (Celery instance)
  - app/tasks.py (task definitions)
  - app/routers/tasks.py (FastAPI endpoints)
  - app/dependencies.py (dependency injection)
- Design endpoint architecture:
  - POST /tasks/{task_name} (submit task)
  - GET /tasks/{task_id}/status (check status)
  - GET /tasks/{task_id}/result (retrieve result)
  - GET /health/celery (health check)
- Plan environment configuration:
  - CELERY_BROKER_URL
  - CELERY_RESULT_BACKEND
  - Connection settings
- Outline monitoring and error handling strategy

Phase 4: Implementation
Goal: Execute integration with fastapi-integrator agent

Actions:

Task(description="Integrate Celery with FastAPI", subagent_type="celery:fastapi-integrator", prompt="You are the fastapi-integrator agent. Integrate Celery with FastAPI for $ARGUMENTS.

Context:
- FastAPI application structure detected
- Existing Celery configuration reviewed
- Integration points identified

Requirements:
- Create Celery app instance with broker configuration
- Implement FastAPI dependency injection for Celery
- Build task submission endpoints (POST /tasks/*)
- Build status tracking endpoints (GET /tasks/{task_id}/status)
- Build result retrieval endpoints (GET /tasks/{task_id}/result)
- Add health check endpoint (GET /health/celery)
- Configure environment variables with placeholders
- Add startup/shutdown lifecycle events
- Create example tasks with progress tracking
- Implement error handling for broker failures
- Generate OpenAPI documentation for endpoints
- Add type hints throughout

Deliverable:
- Complete FastAPI-Celery integration
- Task submission and tracking endpoints
- Environment configuration with placeholders
- Health check and monitoring endpoints
- Example tasks demonstrating patterns
- Type-safe, production-ready code")

Phase 5: Verification
Goal: Verify integration works correctly

Actions:
- Run type checking if mypy available:
  - !{bash which mypy > /dev/null && mypy app/ || echo "mypy not installed, skipping type check"}
- Check generated files exist:
  - !{bash ls -la app/celery_app.py app/tasks.py app/routers/tasks.py 2>/dev/null || echo "Checking file structure"}
- Verify environment configuration:
  - @.env.example
- Display FastAPI OpenAPI endpoint:
  - FastAPI docs will be available at /docs endpoint
  - Task endpoints will appear in OpenAPI schema

Phase 6: Summary
Goal: Document integration and next steps

Actions:
- Summarize integration completed:
  - Celery app instance with broker configuration
  - FastAPI task submission and tracking endpoints
  - Health check and monitoring setup
  - Example tasks with progress tracking
- Key files created: app/celery_app.py, app/tasks.py, app/routers/tasks.py, .env.example
- Environment variables: CELERY_BROKER_URL and CELERY_RESULT_BACKEND (placeholders added)
- Testing: Start Redis (docker run -d -p 6379:6379 redis), start worker (celery -A app.celery_app worker), start FastAPI (uvicorn app.main:app)
- Next steps: Configure broker, add custom tasks, set up production workers, enable Flower monitoring
