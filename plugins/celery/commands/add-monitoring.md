---
description: Set up Flower web monitoring interface for Celery task tracking
argument-hint: [optional-port]
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

Goal: Set up Flower web monitoring dashboard for real-time Celery task tracking and management

Core Principles:
- Detect existing Celery configuration before adding monitoring
- Install Flower with appropriate dependencies
- Configure secure access with authentication if needed
- Provide clear instructions for accessing the dashboard

Phase 1: Discovery
Goal: Understand project structure and Celery setup

Actions:
- Parse $ARGUMENTS for optional port configuration (default: 5555)
- Detect project type and package manager
- Example: !{bash ls package.json pyproject.toml requirements.txt setup.py 2>/dev/null | head -1}
- Locate existing Celery configuration
- Example: !{bash find . -name "celery.py" -o -name "celery_app.py" -o -name "*celery*.py" 2>/dev/null | grep -v __pycache__ | head -5}

Phase 2: Validation
Goal: Verify Celery is configured

Actions:
- Check if Celery is installed and configured
- Verify broker connection settings exist
- Load Celery configuration file for context
- Confirm project is ready for monitoring integration

Phase 3: Implementation
Goal: Install and configure Flower monitoring

Actions:

Task(description="Set up Flower monitoring", subagent_type="celery:monitoring-integrator", prompt="You are the monitoring-integrator agent. Set up Flower web monitoring interface for this Celery project.

Port configuration: $ARGUMENTS (use 5555 if not specified)

Requirements:
- Install Flower package with appropriate version
- Create Flower configuration file with security settings
- Configure authentication if needed (basic auth recommended)
- Set up systemd service or Docker configuration for production
- Create startup script for development use
- Configure CORS if needed for external access

Deliverables:
- Flower installed and configured
- Configuration file with security settings
- Startup scripts for dev and production
- Access instructions with URL and credentials")

Phase 4: Verification
Goal: Verify Flower monitoring is accessible

Actions:
- Check if Flower package is installed
- Example: !{bash python -c "import flower; print(flower.__version__)" 2>/dev/null || pip list | grep flower}
- Verify configuration files were created
- Test Flower can start (without blocking)
- Provide access URL and instructions

Phase 5: Summary
Goal: Document setup and next steps

Actions:
- Display Flower dashboard URL (http://localhost:5555 or custom port)
- Show authentication credentials if configured
- Explain how to start Flower for monitoring
- List key features available in dashboard
- Provide troubleshooting tips
- Suggest monitoring best practices
