# Integration Templates Skill

Templates and scripts for integrating Claude Agent SDK into existing projects.

## Purpose

This skill provides ready-to-use templates for adding Claude Agent SDK as a service
within existing TypeScript and Python projects. Unlike standalone app templates,
these are designed to be dropped into existing codebases.

## Contents

### Templates

**TypeScript Templates** (`templates/typescript/`):
- `agent-service-functional.ts.template` - Functional style service
- `agent-service-class.ts.template` - Class-based service
- `agent-types.ts.template` - Request/Response types
- `agent-routes-bun.ts.template` - Routes for Bun/Hono
- `agent-routes-express.ts.template` - Routes for Express
- `barrel-export.ts.template` - Export statement for barrel files

**Python Templates** (`templates/python/`):
- `agent_service.py.template` - Agent service module
- `agent_schemas.py.template` - Pydantic models
- `agent_routes_fastapi.py.template` - FastAPI router
- `__init__.py.template` - Package init

### Scripts

**Detection Script** (`scripts/detect-project.sh`):
Analyzes current project and outputs:
- LANGUAGE (typescript/python)
- FRAMEWORK (bun/express/nextjs/fastapi/python)
- SERVICES_DIR (detected path)
- ROUTES_DIR (detected path)
- CODE_STYLE (functional/class-based)
- HAS_BARREL (true/false)

### Examples

- `integration-summary.md` - Example integration summary output

## Usage

### From Agent/Command

```markdown
# Load skill to get templates
!{skill claude-agent-sdk:integration-templates}

# Run detection script
!{bash bash plugins/claude-agent-sdk/skills/integration-templates/scripts/detect-project.sh}
```

### Template Variables

Templates use these placeholders:
- `{{SERVICE_NAME}}` - Name of the service (default: claude-agent)
- `{{PROJECT_ROOT}}` - Project root path
- `{{SERVICES_DIR}}` - Detected services directory
- `{{ROUTES_DIR}}` - Detected routes directory

## Security Compliance

This skill follows strict security rules:
- All templates use placeholder values only
- No real API keys, passwords, or secrets
- Environment variable references in all code
- `.gitignore` protection documented
