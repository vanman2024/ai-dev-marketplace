#!/bin/bash
# setup-framework.sh - Quick setup for Celery framework integration
# Usage: ./setup-framework.sh <framework> <project-path>
# Frameworks: django, flask, fastapi

set -e

FRAMEWORK=$1
PROJECT_PATH=${2:-.}

if [[ -z "$FRAMEWORK" ]]; then
    echo "Usage: $0 <framework> [project-path]"
    echo "Frameworks: django, flask, fastapi"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🚀 Setting up Celery integration for $FRAMEWORK"
echo "📁 Project path: $PROJECT_PATH"
echo ""

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$(dirname "$SCRIPT_DIR")/templates"

# Function to copy template
copy_template() {
    local src=$1
    local dest=$2
    local description=$3

    if [[ -f "$dest" ]]; then
        echo -e "${YELLOW}⚠${NC} $description already exists: $dest"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "  Skipped"
            return
        fi
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo -e "${GREEN}✓${NC} Created $description: $dest"
}

# Function to install packages
install_packages() {
    local packages=$1
    echo -e "${BLUE}▶${NC} Installing packages: $packages"

    if command -v pip &>/dev/null; then
        pip install $packages
        echo -e "${GREEN}✓${NC} Packages installed"
    else
        echo -e "${RED}✗${NC} pip not found. Please install manually: pip install $packages"
    fi
}

# Change to project directory
cd "$PROJECT_PATH" || {
    echo -e "${RED}✗${NC} Project path not found: $PROJECT_PATH"
    exit 1
}

case "$FRAMEWORK" in
django)
    echo "🔷 Setting up Django + Celery integration..."
    echo ""

    # Install packages
    install_packages "celery redis django-celery-results django-celery-beat"
    echo ""

    # Find Django project directory
    PROJECT_DIR=$(find . -maxdepth 2 -name "settings.py" -exec dirname {} \; | head -1)

    if [[ -z "$PROJECT_DIR" ]]; then
        echo -e "${RED}✗${NC} Django project (settings.py) not found"
        echo "Please run this from your Django project root directory"
        exit 1
    fi

    echo "Found Django project: $PROJECT_DIR"
    echo ""

    # Copy celery.py
    copy_template \
        "$TEMPLATES_DIR/django-integration/celery.py" \
        "$PROJECT_DIR/celery.py" \
        "Celery configuration"

    # Update __init__.py
    INIT_FILE="$PROJECT_DIR/__init__.py"
    if ! grep -q "from .celery import app as celery_app" "$INIT_FILE" 2>/dev/null; then
        cat >>"$INIT_FILE" <<'EOF'

# Import Celery app
from .celery import app as celery_app

__all__ = ('celery_app',)
EOF
        echo -e "${GREEN}✓${NC} Updated $INIT_FILE"
    else
        echo -e "${YELLOW}⚠${NC} $INIT_FILE already imports Celery"
    fi

    # Create example tasks.py in current directory
    if [[ ! -f "tasks.py" ]]; then
        copy_template \
            "$TEMPLATES_DIR/django-integration/tasks.py" \
            "tasks.py" \
            "Example tasks"
    fi

    echo ""
    echo -e "${GREEN}✓ Django setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Add Celery config to settings.py (see templates/django-integration/settings.py)"
    echo "  2. Run migrations: python manage.py migrate django_celery_results"
    echo "  3. Start worker: celery -A ${PROJECT_DIR##*/} worker -l info"
    echo "  4. See: examples/django-complete-setup.md for full guide"
    ;;

flask)
    echo "🔷 Setting up Flask + Celery integration..."
    echo ""

    # Install packages
    install_packages "celery flask flask-sqlalchemy flask-mail redis"
    echo ""

    # Create structure
    mkdir -p myapp

    # Copy templates
    copy_template \
        "$TEMPLATES_DIR/flask-integration/celery_app.py" \
        "myapp/celery_app.py" \
        "Celery factory"

    copy_template \
        "$TEMPLATES_DIR/flask-integration/tasks.py" \
        "myapp/tasks.py" \
        "Example tasks"

    # Create __init__.py if not exists
    if [[ ! -f "myapp/__init__.py" ]]; then
        cat >"myapp/__init__.py" <<'EOF'
from flask import Flask

def create_app():
    app = Flask(__name__)
    app.config['CELERY_BROKER_URL'] = 'redis://localhost:6379/0'
    app.config['CELERY_RESULT_BACKEND'] = 'redis://localhost:6379/0'
    return app
EOF
        echo -e "${GREEN}✓${NC} Created myapp/__init__.py"
    fi

    echo ""
    echo -e "${GREEN}✓ Flask setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Update myapp/__init__.py with your Flask config"
    echo "  2. Create worker.py: from myapp import create_app; from myapp.celery_app import create_celery_app; flask_app = create_app(); celery = create_celery_app(flask_app)"
    echo "  3. Start worker: celery -A worker.celery worker -l info"
    echo "  4. See: examples/flask-factory-pattern.md for full guide"
    ;;

fastapi)
    echo "🔷 Setting up FastAPI + Celery integration..."
    echo ""

    # Install packages
    install_packages "celery fastapi uvicorn redis pydantic[email]"
    echo ""

    # Create structure
    mkdir -p app

    # Copy templates
    copy_template \
        "$TEMPLATES_DIR/fastapi-integration/celery_app.py" \
        "app/celery_app.py" \
        "Celery configuration"

    copy_template \
        "$TEMPLATES_DIR/fastapi-integration/tasks.py" \
        "app/tasks.py" \
        "Example tasks"

    copy_template \
        "$TEMPLATES_DIR/fastapi-integration/main.py" \
        "app/main.py" \
        "FastAPI application"

    # Create __init__.py
    touch "app/__init__.py"
    echo -e "${GREEN}✓${NC} Created app/__init__.py"

    # Create config.py
    if [[ ! -f "app/config.py" ]]; then
        cat >"app/config.py" <<'EOF'
from pydantic import BaseSettings

class Settings(BaseSettings):
    celery_broker_url: str = "redis://localhost:6379/0"
    celery_result_backend: str = "redis://localhost:6379/0"

    class Config:
        env_file = ".env"

settings = Settings()
EOF
        echo -e "${GREEN}✓${NC} Created app/config.py"
    fi

    # Create .env.example
    if [[ ! -f ".env.example" ]]; then
        cat >".env.example" <<'EOF'
CELERY_BROKER_URL=redis://your_redis_url_here
CELERY_RESULT_BACKEND=redis://your_redis_url_here
EOF
        echo -e "${GREEN}✓${NC} Created .env.example"
    fi

    echo ""
    echo -e "${GREEN}✓ FastAPI setup complete!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Copy .env.example to .env and add your Redis URL"
    echo "  2. Start FastAPI: uvicorn app.main:app --reload"
    echo "  3. Start worker: celery -A app.celery_app.celery worker -l info"
    echo "  4. See: examples/fastapi-async.md for full guide"
    ;;

*)
    echo -e "${RED}✗${NC} Unknown framework: $FRAMEWORK"
    echo "Supported frameworks: django, flask, fastapi"
    exit 1
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Additional resources:"
echo "   Templates: $(dirname "$SCRIPT_DIR")/templates/${FRAMEWORK}-integration/"
echo "   Examples: $(dirname "$SCRIPT_DIR")/examples/${FRAMEWORK}-*"
echo "   Validation: ./scripts/validate-framework.sh $FRAMEWORK"
echo "   Testing: ./scripts/test-integration.sh $FRAMEWORK"
