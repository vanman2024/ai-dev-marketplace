---
description: Initialize FastAPI project with modern async/await setup, dependencies, and configuration
argument-hint: [project-name]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, Skill
---

## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

**Arguments**: $ARGUMENTS

Goal: Bootstrap a production-ready FastAPI project with async/await patterns, dependency injection, configuration management, and essential integrations.

Core Principles:
- Detect existing structure before creating new files
- Use modern FastAPI patterns (async/await, dependency injection)
- Follow official FastAPI documentation conventions
- Ask user for preferences when multiple approaches are valid
- Create comprehensive configuration and project structure

Phase 1: Discovery
Goal: Understand the target directory and gather project requirements

Actions:
- Parse $ARGUMENTS for project name (default to "fastapi-app" if not provided)
- Check current directory structure: !{bash pwd && ls -la}
- Detect if FastAPI project already exists: !{bash test -f main.py -o -f app/main.py && echo "EXISTS" || echo "NEW"}
- If unclear about scope, use AskUserQuestion to gather:
  - What features should be included? (Auth, Database, Memory/Mem0, AI integration)
  - What deployment target? (Uvicorn, Docker, Serverless)
  - Which AI providers? (OpenAI, Anthropic, both)
  - Memory layer needed? (Mem0 platform, self-hosted, none)

Phase 2: Template Loading
Goal: Load FastAPI documentation and best practices

Actions:

Load project documentation:
@plugins/fastapi-backend/docs/FASTAPI-VERCEL-AI-MEM0-STACK.md

Load FastAPI references from documentation:
- Installation guide: https://fastapi.tiangolo.com/#installation
- First steps: https://fastapi.tiangolo.com/tutorial/first-steps/
- Async & Concurrency: https://fastapi.tiangolo.com/async/
- Dependencies: https://fastapi.tiangolo.com/tutorial/dependencies/
- Settings & Environment: https://fastapi.tiangolo.com/advanced/settings/
- Deployment: https://fastapi.tiangolo.com/deployment/

Phase 3: Planning
Goal: Design the project structure based on requirements

Actions:
- Determine project structure based on user input
- Identify required dependencies (fastapi, uvicorn, pydantic, etc.)
- Plan directory layout (app/, config/, services/, models/, api/routes/)
- Confirm approach with user if significant
- Present clear implementation plan

Phase 4: Implementation
Goal: Create FastAPI project with modern setup

Actions:

Task(description="Initialize FastAPI project", subagent_type="fastapi-setup-agent", prompt="You are the fastapi-setup-agent. Initialize a production-ready FastAPI project for $ARGUMENTS.

Project Requirements:
- Modern async/await patterns throughout
- Pydantic Settings for configuration management
- Dependency injection for services
- Proper CORS configuration
- Health check endpoint
- Structured directory layout (app/, config/, services/, models/, api/routes/)
- Environment variable management (.env, .env.example)
- Requirements.txt with pinned versions
- README.md with setup instructions

Reference Documentation:
- FastAPI main docs: https://fastapi.tiangolo.com
- Async patterns: https://fastapi.tiangolo.com/async/
- Settings: https://fastapi.tiangolo.com/advanced/settings/
- Dependencies: https://fastapi.tiangolo.com/tutorial/dependencies/
- Deployment: https://fastapi.tiangolo.com/deployment/

Create the following structure:
1. Project root configuration (requirements.txt, .env.example, README.md)
2. app/main.py - FastAPI application with lifespan, CORS, health check
3. app/config/settings.py - Pydantic Settings configuration
4. app/api/deps.py - Dependency injection setup
5. app/api/routes/ - API route modules
6. app/services/ - Service layer implementations
7. app/models/ - Pydantic models

Follow patterns from the loaded documentation. Use modern FastAPI conventions.

Expected output: Complete project structure with all files created and configured.")

Phase 5: Dependency Installation
Goal: Set up Python environment and install dependencies

Actions:
- Check if virtual environment exists: !{bash test -d venv && echo "EXISTS" || echo "NONE"}
- If no venv, create one: !{bash python -m venv venv}
- Install dependencies: !{bash source venv/bin/activate && pip install -r requirements.txt}
- Verify installation: !{bash source venv/bin/activate && python -c "import fastapi; print(f'FastAPI {fastapi.__version__} installed')"}

Phase 6: Validation
Goal: Verify the project is properly configured

Actions:
- Check all required files exist
- Validate Python syntax: !{bash source venv/bin/activate && python -m py_compile app/main.py}
- Test FastAPI imports: !{bash source venv/bin/activate && python -c "from app.main import app; print('FastAPI app loads successfully')"}
- Verify .env.example has all required variables
- Check README.md has setup instructions

Phase 7: Summary
Goal: Present results and next steps

Actions:
- Display project structure created
- Show installed dependencies and versions
- Highlight configuration files to customize (.env)
- Provide development server command: `uvicorn app.main:app --reload`
- Suggest next steps:
  - Copy .env.example to .env and configure
  - Add authentication if needed
  - Integrate AI providers (OpenAI, Anthropic)
  - Add Mem0 memory layer
  - Set up database connections
  - Review FastAPI docs for advanced features
