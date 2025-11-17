---
description: Configure message broker (Redis, RabbitMQ, SQS) for Celery
argument-hint: [broker-type]
allowed-tools: Task, Read, Write, Edit, Bash, AskUserQuestion, Glob, Grep
---

**Arguments**: $ARGUMENTS

Goal: Configure message broker for Celery with connection settings and security

Core Principles:
- Ask for broker type if not specified
- Detect existing configuration
- Use environment variables for credentials
- Never hardcode secrets

Phase 1: Discovery
Goal: Understand broker requirements and current setup

Actions:
- Parse $ARGUMENTS for broker type (redis, rabbitmq, sqs)
- If broker type not provided, use AskUserQuestion to determine:
  - Which broker to use (Redis, RabbitMQ, AWS SQS)?
  - What environment (development, production)?
  - Any specific connection requirements?
- Check for existing Celery configuration:
  - !{bash find . -name "celery*.py" -o -name "*celery*.py" 2>/dev/null | head -5}
  - !{bash test -f .env && echo ".env exists" || echo "No .env file"}
- Load existing configuration if found

Phase 2: Preparation
Goal: Prepare context for broker configuration

Actions:
- Detect project type:
  - !{bash ls -la | grep -E "requirements.txt|pyproject.toml|setup.py" | head -3}
- Check for existing broker packages:
  - !{bash grep -r "redis\|celery\|kombu\|amqp\|boto3" requirements.txt pyproject.toml setup.py 2>/dev/null | head -10}
- Load relevant files for context:
  - @requirements.txt (if exists)
  - @pyproject.toml (if exists)
  - @.env.example (if exists)

Phase 3: Configuration
Goal: Configure broker with specialist agent

Actions:

Task(description="Configure message broker", subagent_type="celery:broker-specialist", prompt="You are the celery:broker-specialist agent. Configure $ARGUMENTS message broker for Celery.

Context from discovery:
- Existing configuration files found
- Project structure analyzed
- Dependencies identified

Requirements:
- Install required broker packages (redis, kombu, boto3)
- Configure broker URL with environment variables
- Set up connection pooling and retry logic
- Configure SSL/TLS if production environment
- Add health check endpoints
- Update .env.example with broker configuration placeholders
- Create broker initialization module if needed

Security Requirements:
- Use environment variables for credentials
- Never hardcode broker URLs with credentials
- Use placeholders: redis_your_password_here, rabbitmq_your_password_here
- Add .env to .gitignore if not already present
- Document where to obtain credentials

Expected output:
- Broker configuration files created/updated
- Dependencies added to requirements
- Environment variable templates
- Connection verification code
- Documentation for setup")

Phase 4: Verification
Goal: Verify broker configuration

Actions:
- Check that configuration files were created
- Verify environment variables use placeholders only
- Confirm .gitignore protects .env file:
  - !{bash grep "^\.env$" .gitignore 2>/dev/null || echo ".env not in .gitignore"}
- Validate broker connection code exists
- Check for proper error handling

Phase 5: Summary
Goal: Document what was configured

Actions:
- Summarize broker configuration:
  - Broker type configured
  - Files created/modified
  - Dependencies added
  - Environment variables needed
- Provide next steps:
  - Set actual broker credentials in .env
  - Install dependencies: pip install -r requirements.txt
  - Test broker connection
  - Configure result backend if needed
- Display connection string format (with placeholders)
