---
description: Initialize Celery in existing project with framework detection
argument-hint: [project-path]
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

Goal: Initialize Celery with automatic framework detection and broker configuration

Core Principles:
- Detect framework before configuring (Django, Flask, FastAPI, standalone)
- Use environment variables for all broker credentials
- Never hardcode API keys or passwords
- Follow framework-specific best practices
- Verify setup before completion

Phase 1: Discovery
Goal: Understand project structure and detect framework

Actions:
- Parse $ARGUMENTS for project path (default to current directory)
- Detect Python project files
- Check for framework indicators:
  - Django: manage.py, settings.py
  - Flask: app.py with Flask imports
  - FastAPI: main.py with FastAPI imports
  - Standalone: generic Python project

!{bash cd "${ARGUMENTS:-.}" && pwd}
!{bash ls -la manage.py settings.py app.py main.py requirements.txt pyproject.toml 2>/dev/null | head -20}

Phase 2: Framework Analysis
Goal: Load project files to confirm framework type

Actions:
- Read requirements or pyproject.toml to identify dependencies
- Confirm framework from imports and structure
- Identify project name and layout

Example checks:
- @requirements.txt (if exists)
- @pyproject.toml (if exists)
- !{bash find . -name "settings.py" -o -name "app.py" -o -name "main.py" | head -5}

Phase 3: Setup Initialization
Goal: Invoke celery-setup-agent with detected context

Actions:

Task(description="Initialize Celery with framework detection", subagent_type="celery:celery-setup-agent", prompt="You are the celery-setup-agent. Initialize Celery for project at: $ARGUMENTS

Framework Detection Results:
- Project path: [detected path]
- Framework type: [Django/Flask/FastAPI/Standalone]
- Python version: [if detected]
- Existing dependencies: [from requirements/pyproject.toml]

Requirements:
1. Load appropriate Celery documentation via WebFetch
2. Ask user for broker choice (Redis/RabbitMQ/SQS)
3. Ask if result backend is needed
4. Install Celery and broker dependencies
5. Create framework-appropriate configuration files
6. Generate .env.example with placeholders (NO real credentials)
7. Update .gitignore to protect .env files
8. Create example task to verify setup
9. Document worker startup commands

Security Requirements:
- NEVER hardcode broker passwords or credentials
- ALWAYS use environment variables for broker URLs
- CREATE .env.example with obvious placeholders
- ENSURE .gitignore protects .env files

Expected deliverable:
- Complete Celery initialization
- Configuration files with security best practices
- Documentation of setup and next steps
- Verification that Celery imports work")

Phase 4: Verification
Goal: Confirm Celery is properly initialized

Actions:
- Verify Celery installation: !{bash cd "${ARGUMENTS:-.}" && python -c "import celery; print(f'Celery {celery.__version__} installed')" 2>&1}
- Check configuration files exist
- Validate .env.example has placeholders only
- Confirm .gitignore protects .env

Phase 5: Summary
Goal: Document what was accomplished and next steps

Actions:
- Display initialization summary:
  - Framework detected and configured
  - Broker type selected
  - Configuration files created
  - Dependencies installed

- Next steps:
  - Copy .env.example to .env and add real broker credentials
  - Create tasks using: /celery:task-generator
  - Configure workers using: /celery:worker-setup
  - Start worker: celery -A [app_name] worker --loglevel=info
  - Set up monitoring: /celery:monitoring-setup

- Security reminder:
  - Never commit .env file with real credentials
  - Keep .env.example with placeholders for reference
  - Use environment-specific credentials for dev/staging/prod
