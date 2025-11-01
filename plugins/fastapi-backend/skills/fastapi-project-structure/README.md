# FastAPI Project Structure Skill

Production-ready FastAPI project scaffolding with templates, scripts, and best practices for building scalable backend applications.

## Overview

This skill provides comprehensive FastAPI project templates and automation scripts for quickly scaffolding production-ready backend applications. It includes support for standard REST APIs, MCP server integration, microservices, and full-stack backends.

## Quick Start

```bash
# Generate a new FastAPI project
cd /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/fastapi-backend/skills/fastapi-project-structure
./scripts/setup-project.sh my-api-service standard

# Navigate to project
cd my-api-service

# Setup and run
python -m venv venv
source venv/bin/activate
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

## Project Templates

### 1. Minimal Template
Single-file FastAPI application for quick prototypes and simple APIs.

**Use when:**
- Building proof-of-concept APIs
- Creating simple microservices
- Quick testing and experimentation

**Includes:**
- Single `main.py` file
- Basic dependencies
- Simple configuration

### 2. Standard Template
Production-ready structure with proper separation of concerns.

**Use when:**
- Building REST APIs
- Creating CRUD applications
- Standard backend services

**Includes:**
- Structured directory layout
- Settings management
- Route organization
- Service layer pattern
- Testing setup

### 3. MCP Server Template
FastAPI application with integrated MCP server support.

**Use when:**
- Building MCP-enabled backends
- Creating tools/resources for AI agents
- Dual-mode operation (HTTP + STDIO)

**Includes:**
- FastAPI HTTP server
- MCP server integration
- Tools, resources, prompts structure
- Configuration for both modes

### 4. Full-Stack Template
Complete backend with authentication, database, and background tasks.

**Use when:**
- Building complete applications
- Need user authentication
- Require database integration
- Background job processing

**Includes:**
- JWT authentication
- Database integration (SQLAlchemy)
- Migration system (Alembic)
- Background task queue
- Email/notification system

### 5. Microservice Template
Microservice-ready structure with health checks, metrics, and observability.

**Use when:**
- Building microservices architecture
- Need service mesh integration
- Require monitoring and tracing

**Includes:**
- Health check endpoints
- Prometheus metrics
- Distributed tracing
- Service discovery ready
- Docker and Kubernetes configs

## Scripts

### setup-project.sh
Scaffolds a new FastAPI project from templates.

```bash
./scripts/setup-project.sh <project-name> <template-type>
```

**Templates:** minimal, standard, mcp-server, full-stack, microservice

### validate-structure.sh
Validates project structure and configuration.

```bash
./scripts/validate-structure.sh <project-directory>
```

**Checks:**
- Directory structure
- Required files
- Python syntax
- Dependencies
- Configuration files

### generate-component.sh
Generates new API components (routes, services, models).

```bash
./scripts/generate-component.sh <project-dir> <component-type> <name>
```

**Components:** route, service, model, schema

## Templates Directory

### Core Application Templates
- `main.py`: Application entry points for different architectures
- `config.py`: Settings management with Pydantic Settings
- `dependencies.py`: Dependency injection patterns

### Configuration Templates
- `pyproject.toml`: Modern Python project configuration
- `.env.example`: Environment variables template
- `logging-config.yaml`: Structured logging setup

### MCP Integration
- `mcp-server.py`: MCP server initialization
- `mcp-tool-template.py`: MCP tool implementation
- `mcp-config.json`: MCP configuration

### Deployment
- `Dockerfile`: Multi-stage production builds
- `docker-compose.yml`: Local development setup
- `nginx.conf`: Reverse proxy configuration

### API Components
- `route-template.py`: API route handler template
- `service-template.py`: Service layer template
- `schema-template.py`: Pydantic schemas
- `model-template.py`: Database models

## Examples

### Example 1: Simple CRUD API
Complete working example in `examples/minimal-api/`

**Features:**
- In-memory data storage
- CRUD operations
- Input validation
- Error handling

### Example 2: MCP-Integrated API
FastAPI + MCP server example in `examples/mcp-integrated-api/`

**Features:**
- Dual-mode operation
- MCP tools for data operations
- HTTP API endpoints
- Shared business logic

### Example 3: Microservice with Database
Production microservice in `examples/microservice-template/`

**Features:**
- PostgreSQL integration
- Authentication
- Health checks
- Prometheus metrics
- Docker setup

## Best Practices

### Project Organization
```
app/
├── main.py              # Application entry
├── core/                # Core configuration
│   ├── config.py        # Settings
│   └── dependencies.py  # DI
├── api/                 # API layer
│   ├── routes/          # Route handlers
│   └── deps.py          # Route dependencies
├── models/              # Database models
├── schemas/             # Pydantic schemas
└── services/            # Business logic
```

### Configuration Management
- Use Pydantic Settings for type safety
- Separate dev/staging/prod configs
- Never commit secrets
- Validate all environment variables
- Document required variables

### Code Quality
- Type-hint all functions
- Use async/await for I/O
- Keep route handlers thin
- Business logic in services
- Comprehensive error handling

### Testing
- Unit tests for services
- Integration tests for routes
- Use dependency overrides
- Mock external services
- Test error cases

## Requirements

- Python 3.11+
- FastAPI 0.115.0+
- Pydantic 2.0+
- Uvicorn 0.32.0+

## Use Cases

**This skill is useful when:**
- Starting a new FastAPI project
- Need production-ready structure
- Building MCP-enabled backends
- Creating microservices
- Setting up API scaffolding
- Implementing best practices

**Triggers:**
- "Create a FastAPI project"
- "Setup FastAPI application structure"
- "Build REST API with FastAPI"
- "Initialize MCP server with FastAPI"
- "Generate FastAPI microservice"

## Related Skills

- **api-versioning**: API versioning strategies
- **database-integration**: Database setup patterns
- **auth-patterns**: Authentication implementation
- **testing-patterns**: Testing strategies

## Support

For issues or questions:
- Check examples directory for working code
- Review SKILL.md for detailed instructions
- Validate structure with validation script
- Check FastAPI documentation: https://fastapi.tiangolo.com

---

**Skill Location:** /home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins/fastapi-backend/skills/fastapi-project-structure/
**Plugin:** fastapi-backend
**Version:** 1.0.0
