#!/bin/bash
#
# FastAPI Project Setup Script
#
# Usage: ./setup-project.sh <project-name> <template-type>
# Templates: minimal, standard, mcp-server, full-stack, microservice
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SKILL_DIR/templates"

# Parse arguments
PROJECT_NAME="${1:-my-api-service}"
TEMPLATE_TYPE="${2:-standard}"

# Validate template type
VALID_TEMPLATES=("minimal" "standard" "mcp-server" "full-stack" "microservice")
if [[ ! " ${VALID_TEMPLATES[@]} " =~ " ${TEMPLATE_TYPE} " ]]; then
    echo -e "${RED}Error: Invalid template type '$TEMPLATE_TYPE'${NC}"
    echo "Valid templates: ${VALID_TEMPLATES[*]}"
    exit 1
fi

# Project directory
PROJECT_DIR="$PWD/$PROJECT_NAME"

echo -e "${GREEN}Setting up FastAPI project: $PROJECT_NAME${NC}"
echo -e "Template: ${YELLOW}$TEMPLATE_TYPE${NC}"
echo ""

# Create project directory
if [ -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory $PROJECT_DIR already exists${NC}"
    exit 1
fi

mkdir -p "$PROJECT_DIR"

# Function to create directory structure
create_structure() {
    local template=$1

    case $template in
        minimal)
            mkdir -p "$PROJECT_DIR"/{tests}
            ;;
        standard)
            mkdir -p "$PROJECT_DIR"/{app/{core,api/{routes},models,schemas,services},tests/{test_api,test_services}}
            ;;
        mcp-server)
            mkdir -p "$PROJECT_DIR"/{app/{core,api/{routes},mcp/{tools,resources,prompts},services},tests}
            ;;
        full-stack)
            mkdir -p "$PROJECT_DIR"/{app/{core,api/{routes,dependencies},models,schemas,services,db,workers},tests/{test_api,test_services,test_integration},alembic/versions}
            ;;
        microservice)
            mkdir -p "$PROJECT_DIR"/{app/{core,api/{routes,middleware},models,schemas,services,monitoring},tests,k8s}
            ;;
    esac
}

# Function to create files from templates
create_files() {
    local template=$1

    # Common files
    cat > "$PROJECT_DIR/.env.example" << 'EOF'
# Application Configuration
PROJECT_NAME=FastAPI App
VERSION=1.0.0
DEBUG=false

# Server Configuration
HOST=0.0.0.0
PORT=8000

# Security
SECRET_KEY=your-secret-key-here-change-in-production
ALLOWED_ORIGINS=["http://localhost:3000"]

# Database (if needed)
# DATABASE_URL=postgresql://user:password@localhost/dbname

# Logging
LOG_LEVEL=INFO
EOF

    cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
env/
ENV/

# Environment variables
.env
.env.local
.env.*.local

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/

# Logs
*.log

# OS
.DS_Store
Thumbs.db
EOF

    # Create __init__.py files
    find "$PROJECT_DIR/app" -type d -exec touch {}/__init__.py \; 2>/dev/null || true
    find "$PROJECT_DIR/tests" -type d -exec touch {}/__init__.py \; 2>/dev/null || true

    # Template-specific files
    case $template in
        minimal)
            create_minimal_files
            ;;
        standard)
            create_standard_files
            ;;
        mcp-server)
            create_mcp_files
            ;;
        full-stack)
            create_fullstack_files
            ;;
        microservice)
            create_microservice_files
            ;;
    esac
}

create_minimal_files() {
    cat > "$PROJECT_DIR/main.py" << 'EOF'
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="FastAPI Minimal App", version="1.0.0")

class Item(BaseModel):
    name: str
    description: str | None = None

items: dict[int, Item] = {}
item_counter = 0

@app.get("/")
async def root():
    return {"message": "FastAPI Minimal App"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/items")
async def get_items():
    return list(items.values())

@app.post("/items")
async def create_item(item: Item):
    global item_counter
    item_counter += 1
    items[item_counter] = item
    return {"id": item_counter, **item.model_dump()}

@app.get("/items/{item_id}")
async def get_item(item_id: int):
    if item_id not in items:
        return {"error": "Item not found"}
    return items[item_id]
EOF

    cat > "$PROJECT_DIR/pyproject.toml" << 'EOF'
[project]
name = "fastapi-minimal"
version = "1.0.0"
description = "Minimal FastAPI application"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "httpx>=0.27.0",
]
EOF
}

create_standard_files() {
    cat > "$PROJECT_DIR/app/main.py" << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.routes import health

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    debug=settings.DEBUG,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router, prefix="/health", tags=["health"])

@app.get("/")
async def root():
    return {"message": f"Welcome to {settings.PROJECT_NAME}"}
EOF

    cat > "$PROJECT_DIR/app/core/config.py" << 'EOF'
from typing import Any
from pydantic import field_validator
from pydantic_settings import BaseSettings
import json

class Settings(BaseSettings):
    # Application
    PROJECT_NAME: str = "FastAPI App"
    VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security
    SECRET_KEY: str
    ALLOWED_ORIGINS: list[str] | str = ["*"]

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, v: Any) -> list[str] | str:
        if isinstance(v, str):
            try:
                return json.loads(v)
            except json.JSONDecodeError:
                return [origin.strip() for origin in v.split(",")]
        return v

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
EOF

    cat > "$PROJECT_DIR/app/api/routes/health.py" << 'EOF'
from fastapi import APIRouter

router = APIRouter()

@router.get("")
async def health_check():
    return {"status": "healthy"}

@router.get("/ready")
async def readiness_check():
    # Add checks for database, external services, etc.
    return {"status": "ready"}
EOF

    cat > "$PROJECT_DIR/pyproject.toml" << 'EOF'
[project]
name = "fastapi-standard"
version = "1.0.0"
description = "Standard FastAPI application"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.24.0",
    "httpx>=0.27.0",
    "ruff>=0.6.0",
    "mypy>=1.11.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.mypy]
python_version = "3.11"
strict = true
EOF

    cat > "$PROJECT_DIR/tests/conftest.py" << 'EOF'
import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture
def client():
    return TestClient(app)
EOF
}

create_mcp_files() {
    create_standard_files  # Start with standard structure

    cat > "$PROJECT_DIR/app/mcp/server.py" << 'EOF'
from mcp.server import Server
from mcp.server.stdio import stdio_server

# Create MCP server instance
mcp_server = Server("fastapi-mcp-service")

# Import tools, resources, prompts
# from .tools import register_tools
# from .resources import register_resources
# from .prompts import register_prompts

async def run_mcp_server():
    """Run MCP server in STDIO mode"""
    async with stdio_server() as (read_stream, write_stream):
        await mcp_server.run(
            read_stream,
            write_stream,
            mcp_server.create_initialization_options()
        )
EOF

    cat > "$PROJECT_DIR/.mcp.json" << 'EOF'
{
  "mcpServers": {
    "fastapi-mcp-service": {
      "command": "python",
      "args": ["-m", "app.main", "--mcp"],
      "description": "FastAPI MCP Service"
    }
  }
}
EOF
}

create_fullstack_files() {
    create_standard_files

    # Add additional full-stack specific files here
    # (Authentication, database, migrations, etc.)
    echo "Full-stack template files created"
}

create_microservice_files() {
    create_standard_files

    cat > "$PROJECT_DIR/Dockerfile" << 'EOF'
FROM python:3.11-slim as builder

WORKDIR /app

COPY pyproject.toml .
RUN pip install --no-cache-dir build && \
    python -m build --wheel

FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /app/dist/*.whl .
RUN pip install --no-cache-dir *.whl && rm *.whl

COPY app/ ./app/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF
}

# Create README
create_readme() {
    cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

FastAPI application generated with template: $TEMPLATE_TYPE

## Setup

\`\`\`bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install dependencies
pip install -e ".[dev]"

# Copy environment file
cp .env.example .env
# Edit .env with your configuration

# Run development server
uvicorn app.main:app --reload
\`\`\`

## Development

\`\`\`bash
# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run tests
pytest

# Lint
ruff check .

# Type check
mypy app/
\`\`\`

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

Generated using template: $TEMPLATE_TYPE
EOF
}

# Main execution
echo "Creating directory structure..."
create_structure "$TEMPLATE_TYPE"

echo "Creating project files..."
create_files "$TEMPLATE_TYPE"

echo "Creating README..."
create_readme

echo ""
echo -e "${GREEN}Project setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  python -m venv venv"
echo "  source venv/bin/activate"
echo "  pip install -e '.[dev]'"
echo "  cp .env.example .env"
echo "  uvicorn app.main:app --reload"
echo ""
