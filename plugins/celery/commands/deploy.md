---
description: Production deployment configuration (Docker, K8s, systemd)
argument-hint: [platform]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, TodoWrite
---

**Arguments**: $ARGUMENTS

Goal: Generate production-ready deployment configurations for Celery workers, beat scheduler, and flower monitoring

Core Principles:
- Ask clarifying questions about deployment platform and requirements
- Detect existing Celery configuration before generating deployment files
- Use environment variables with placeholders (never hardcode secrets)
- Follow platform-specific best practices for scaling and reliability

Phase 1: Discovery
Goal: Understand deployment requirements and existing setup

Actions:
- Parse $ARGUMENTS for target platform (systemd/docker/kubernetes)
- If platform unclear, use AskUserQuestion to gather:
  - Which deployment platform? (systemd, Docker Compose, Kubernetes)
  - How many worker processes needed?
  - Will you deploy beat scheduler and flower monitoring?
  - What are your scaling requirements?
- Detect project structure and package manager
- Example: !{bash ls requirements.txt pyproject.toml setup.py docker-compose.yml Dockerfile 2>/dev/null}
- Locate existing Celery configuration
- Example: !{bash find . -name "celery.py" -o -name "celery_app.py" 2>/dev/null | grep -v __pycache__ | head -5}

Phase 2: Analysis
Goal: Understand current Celery setup

Actions:
- Read Celery configuration file for broker and backend settings
- Check for existing deployment configurations
- Identify task modules and queue configuration
- Verify broker type (Redis/RabbitMQ/SQS)
- Load application entry point

Phase 3: Planning
Goal: Design deployment architecture

Actions:
- Outline deployment architecture based on platform:
  - systemd: Service units for worker, beat, flower
  - Docker: Multi-container compose with health checks
  - Kubernetes: Deployments, ConfigMaps, Secrets, HPA
- Plan scaling strategy (manual vs autoscaling)
- Design health check approach
- Determine resource limits
- Present deployment plan to user

Phase 4: Implementation
Goal: Generate deployment configurations

Actions:

Task(description="Generate deployment configs", subagent_type="celery:deployment-architect", prompt="You are the deployment-architect agent. Generate production deployment configurations for this Celery application.

Platform: $ARGUMENTS
Detected configuration: [broker type, task modules, queues]

Requirements:
- Create platform-specific deployment files (systemd/Docker/K8s)
- Configure celery worker with appropriate concurrency
- Set up beat scheduler as singleton service
- Include flower monitoring dashboard
- Use environment variables with placeholders only
- Add graceful shutdown handling (SIGTERM)
- Configure health checks for all services
- Set reasonable resource limits
- Include security best practices

Deliverables:
- Complete deployment configuration files
- .env.example with placeholder values only
- Deployment documentation with setup steps
- Scaling and troubleshooting guide")

Phase 5: Verification
Goal: Validate generated configurations

Actions:
- Verify all configuration files were created
- Check for hardcoded secrets (should be none)
- Confirm .env.example uses placeholders only
- Validate syntax based on platform:
  - Docker: !{bash docker-compose config 2>&1 || echo "Validation pending"}
  - Kubernetes: !{bash kubectl apply --dry-run=client -f . 2>&1 || echo "Validation pending"}
- Ensure documentation is complete

Phase 6: Summary
Goal: Document deployment setup

Actions:
- List all generated configuration files
- Highlight key configuration parameters
- Explain deployment workflow
- Provide platform-specific commands:
  - systemd: sudo systemctl start celery-worker@1
  - Docker: docker-compose up -d
  - Kubernetes: kubectl apply -f .
- Show monitoring access (Flower URL)
- Note scaling procedures
- List next steps for production readiness
