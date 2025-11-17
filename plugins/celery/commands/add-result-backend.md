---
description: Configure result backend (Redis, Database, RPC)
argument-hint: [backend-type]
allowed-tools: Task, Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
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

Goal: Configure Celery result backend for task result storage with Redis, Database, or RPC backend.

Core Principles:
- Ask about backend type and requirements upfront
- Detect existing configuration before modifying
- Use environment variables for sensitive values (NEVER hardcode credentials)
- Validate configuration after setup

Phase 1: Discovery
Goal: Understand current setup and requirements

Actions:
- Parse $ARGUMENTS for backend type if provided
- Check for existing Celery configuration:
  - !{bash find . -name "celery*.py" -o -name "celeryconfig.py" 2>/dev/null | head -5}
  - @celeryconfig.py (if exists)
  - @celery.py (if exists)
- Check for existing result backend configuration
- If backend type unclear from $ARGUMENTS, use AskUserQuestion to gather:
  - Which result backend to use? (Redis, Database, RPC)
  - Result persistence requirements (temporary/permanent)?
  - Performance and availability needs?
  - Existing infrastructure (Redis/Database already available)?

Phase 2: Requirements Validation
Goal: Confirm backend selection and requirements

Actions:
- Validate backend type selection from $ARGUMENTS or user response
- Check project dependencies:
  - @requirements.txt (if Python)
  - @pyproject.toml (if Poetry)
  - @setup.py (if exists)
- Verify required packages:
  - Redis backend: needs `celery[redis]` or `redis>=4.5.0`
  - Database backend: needs `celery[sqlalchemy]` or `sqlalchemy>=1.4.0`
  - RPC backend: included with RabbitMQ broker
- Confirm configuration approach with user if significant changes needed

Phase 3: Implementation
Goal: Configure result backend with specialist agent

Actions:

Task(description="Configure result backend", subagent_type="celery:backend-specialist", prompt="You are the Celery backend-specialist agent. Configure $ARGUMENTS result backend for this project.

Context:
- Backend type: [from discovery phase]
- Existing config: [summary from discovery]
- Requirements: [from user responses]

Requirements:
- Configure result_backend URL with environment variables (NO hardcoded credentials)
- Install required backend packages
- Set up result serialization and expiration
- Configure connection pooling and retry logic
- Implement monitoring and health checks
- Create .env.example with clear placeholders

Security Critical:
- NEVER hardcode Redis passwords or database credentials
- ALWAYS use environment variables for sensitive values
- ALWAYS use placeholders like 'your_redis_password_here' in examples

Expected output:
- Updated Celery configuration with result backend
- Environment variable template (.env.example)
- Verification steps and testing instructions
- Documentation on backend usage")

Phase 4: Verification
Goal: Validate result backend configuration

Actions:
- Check configuration files were updated correctly
- Verify environment variable placeholders used (not hardcoded secrets)
- Test backend connectivity if possible:
  - !{bash python -c "from celery import Celery; app = Celery(); print('Config loaded')" 2>&1 || echo "Check configuration"}
- Verify .env.example created with placeholders
- Check .gitignore protects .env files

Phase 5: Summary
Goal: Document configuration and next steps

Actions:
- Summarize result backend configuration:
  - Backend type configured
  - Configuration files modified
  - Required packages to install
  - Environment variables to set
- Highlight security reminders:
  - Set actual credentials in .env (not committed to git)
  - Never use hardcoded passwords
  - Refer to .env.example for required variables
- Suggest next steps:
  - Install required packages
  - Set environment variables with actual credentials
  - Test result backend with simple task
  - Run /celery:validate to verify configuration
