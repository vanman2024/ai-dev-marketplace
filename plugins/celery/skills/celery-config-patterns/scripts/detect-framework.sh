#!/bin/bash
# Detect Python Web Framework
#
# Automatically detects which Python web framework is used in the current project.
# Supports: Django, Flask, FastAPI, Standalone
#
# Usage:
#   bash detect-framework.sh
#   bash detect-framework.sh /path/to/project

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=================================================="
echo "Python Framework Detector"
echo "=================================================="
echo ""
echo "Scanning directory: $(pwd)"
echo ""

# ============================================================================
# Detection Functions
# ============================================================================

detect_django() {
    local confidence=0
    local details=()

    # Check for manage.py
    if [ -f "manage.py" ]; then
        ((confidence+=30))
        details+=("manage.py found")
    fi

    # Check for settings.py
    if find . -name "settings.py" -type f | head -n 1 | grep -q .; then
        ((confidence+=30))
        details+=("settings.py found")
        SETTINGS_FILE=$(find . -name "settings.py" -type f | head -n 1)
    fi

    # Check for Django imports
    if grep -r "from django" . --include="*.py" | head -n 1 | grep -q .; then
        ((confidence+=20))
        details+=("Django imports found")
    fi

    # Check for wsgi.py or asgi.py
    if find . -name "wsgi.py" -o -name "asgi.py" | head -n 1 | grep -q .; then
        ((confidence+=10))
        details+=("WSGI/ASGI file found")
    fi

    # Check for Django in requirements
    if [ -f "requirements.txt" ] && grep -qi "django" requirements.txt; then
        ((confidence+=10))
        details+=("Django in requirements.txt")
    fi

    echo "$confidence|${details[*]}"
}

detect_flask() {
    local confidence=0
    local details=()

    # Check for Flask imports
    if grep -r "from flask import\|import flask" . --include="*.py" | head -n 1 | grep -q .; then
        ((confidence+=40))
        details+=("Flask imports found")
    fi

    # Check for app.py
    if [ -f "app.py" ]; then
        ((confidence+=20))
        details+=("app.py found")
    fi

    # Check for Flask patterns
    if grep -r "@app.route\|Flask(__name__)" . --include="*.py" | head -n 1 | grep -q .; then
        ((confidence+=20))
        details+=("Flask patterns found")
    fi

    # Check for Flask in requirements
    if [ -f "requirements.txt" ] && grep -qi "flask" requirements.txt; then
        ((confidence+=10))
        details+=("Flask in requirements.txt")
    fi

    # Check for templates directory
    if [ -d "templates" ]; then
        ((confidence+=10))
        details+=("templates/ directory found")
    fi

    echo "$confidence|${details[*]}"
}

detect_fastapi() {
    local confidence=0
    local details=()

    # Check for FastAPI imports
    if grep -r "from fastapi import\|import fastapi" . --include="*.py" | head -n 1 | grep -q .; then
        ((confidence+=40))
        details+=("FastAPI imports found")
    fi

    # Check for main.py
    if [ -f "main.py" ]; then
        ((confidence+=20))
        details+=("main.py found")
    fi

    # Check for FastAPI patterns
    if grep -r "FastAPI()\|@app.get\|@app.post" . --include="*.py" | head -n 1 | grep -q .; then
        ((confidence+=20))
        details+=("FastAPI patterns found")
    fi

    # Check for FastAPI in requirements
    if [ -f "requirements.txt" ] && grep -qi "fastapi" requirements.txt; then
        ((confidence+=10))
        details+=("FastAPI in requirements.txt")
    fi

    # Check for uvicorn
    if [ -f "requirements.txt" ] && grep -qi "uvicorn" requirements.txt; then
        ((confidence+=10))
        details+=("Uvicorn in requirements.txt")
    fi

    echo "$confidence|${details[*]}"
}

# ============================================================================
# Run Detection
# ============================================================================

echo "Running framework detection..."
echo ""

# Detect each framework
DJANGO_RESULT=$(detect_django)
FLASK_RESULT=$(detect_flask)
FASTAPI_RESULT=$(detect_fastapi)

# Parse results
DJANGO_CONF=$(echo "$DJANGO_RESULT" | cut -d'|' -f1)
DJANGO_DETAILS=$(echo "$DJANGO_RESULT" | cut -d'|' -f2)

FLASK_CONF=$(echo "$FLASK_RESULT" | cut -d'|' -f1)
FLASK_DETAILS=$(echo "$FLASK_RESULT" | cut -d'|' -f2)

FASTAPI_CONF=$(echo "$FASTAPI_RESULT" | cut -d'|' -f1)
FASTAPI_DETAILS=$(echo "$FASTAPI_RESULT" | cut -d'|' -f2)

# Display results
echo "Detection Results:"
echo ""
echo "Django:  ${DJANGO_CONF}% confidence"
if [ -n "$DJANGO_DETAILS" ]; then
    echo "         $DJANGO_DETAILS"
fi
echo ""
echo "Flask:   ${FLASK_CONF}% confidence"
if [ -n "$FLASK_DETAILS" ]; then
    echo "         $FLASK_DETAILS"
fi
echo ""
echo "FastAPI: ${FASTAPI_CONF}% confidence"
if [ -n "$FASTAPI_DETAILS" ]; then
    echo "         $FASTAPI_DETAILS"
fi
echo ""

# ============================================================================
# Determine Winner
# ============================================================================

FRAMEWORK="standalone"
MAX_CONF=0

if [ "$DJANGO_CONF" -gt "$MAX_CONF" ]; then
    FRAMEWORK="django"
    MAX_CONF=$DJANGO_CONF
fi

if [ "$FLASK_CONF" -gt "$MAX_CONF" ]; then
    FRAMEWORK="flask"
    MAX_CONF=$FLASK_CONF
fi

if [ "$FASTAPI_CONF" -gt "$MAX_CONF" ]; then
    FRAMEWORK="fastapi"
    MAX_CONF=$FASTAPI_CONF
fi

# ============================================================================
# Get Framework Version
# ============================================================================

VERSION=""
case $FRAMEWORK in
    django)
        VERSION=$(python3 -c "import django; print(django.__version__)" 2>/dev/null || echo "unknown")
        ;;
    flask)
        VERSION=$(python3 -c "import flask; print(flask.__version__)" 2>/dev/null || echo "unknown")
        ;;
    fastapi)
        VERSION=$(python3 -c "import fastapi; print(fastapi.__version__)" 2>/dev/null || echo "unknown")
        ;;
esac

# ============================================================================
# Determine Celery Location
# ============================================================================

CELERY_LOCATION=""
case $FRAMEWORK in
    django)
        # Django: projectname/celery.py
        if [ -f "manage.py" ]; then
            PROJECT_NAME=$(python3 -c "import os; import sys; sys.path.insert(0, '.'); os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings'); from django.conf import settings; print(settings.SETTINGS_MODULE.split('.')[0])" 2>/dev/null || echo "myproject")
            CELERY_LOCATION="${PROJECT_NAME}/celery.py"
        fi
        SETTINGS_LOCATION=$(find . -name "settings.py" -type f | head -n 1 || echo "")
        ;;
    flask)
        # Flask: app/celery.py or celery.py
        if [ -d "app" ]; then
            CELERY_LOCATION="app/celery.py"
        else
            CELERY_LOCATION="celery.py"
        fi
        ;;
    fastapi)
        # FastAPI: app/celery.py or celery.py
        if [ -d "app" ]; then
            CELERY_LOCATION="app/celery.py"
        else
            CELERY_LOCATION="celery_app.py"
        fi
        ;;
    standalone)
        CELERY_LOCATION="celery_app.py"
        ;;
esac

# ============================================================================
# Output Results
# ============================================================================

echo "=================================================="
echo "Detection Result"
echo "=================================================="
echo ""

if [ "$FRAMEWORK" = "standalone" ]; then
    echo -e "${YELLOW}Framework:${NC} Standalone Python (no web framework detected)"
else
    echo -e "${GREEN}Framework:${NC} $FRAMEWORK"
fi

if [ -n "$VERSION" ] && [ "$VERSION" != "unknown" ]; then
    echo -e "${GREEN}Version:${NC} $VERSION"
fi

echo -e "${BLUE}Celery Location:${NC} $CELERY_LOCATION"

if [ -n "$SETTINGS_LOCATION" ]; then
    echo -e "${BLUE}Settings File:${NC} $SETTINGS_LOCATION"
fi

echo ""

# ============================================================================
# JSON Output
# ============================================================================

cat << EOF
{
  "framework": "$FRAMEWORK",
  "version": "$VERSION",
  "celery_location": "$CELERY_LOCATION",
  "settings_location": "${SETTINGS_LOCATION:-}",
  "confidence": $MAX_CONF,
  "project_dir": "$(pwd)"
}
EOF

echo ""

# ============================================================================
# Recommendations
# ============================================================================

echo "=================================================="
echo "Recommendations"
echo "=================================================="
echo ""

case $FRAMEWORK in
    django)
        echo "Django detected. Recommended setup:"
        echo "  1. Create $CELERY_LOCATION"
        echo "  2. Add Celery config to settings.py"
        echo "  3. Update ${PROJECT_NAME}/__init__.py"
        echo "  4. Create tasks.py in each app"
        echo ""
        echo "Next steps:"
        echo "  bash scripts/generate-config.sh --framework=django --broker=redis"
        ;;
    flask)
        echo "Flask detected. Recommended setup:"
        echo "  1. Create $CELERY_LOCATION with factory pattern"
        echo "  2. Create celeryconfig.py"
        echo "  3. Initialize Celery with Flask app"
        echo "  4. Create tasks.py"
        echo ""
        echo "Next steps:"
        echo "  bash scripts/generate-config.sh --framework=flask --broker=redis"
        ;;
    fastapi)
        echo "FastAPI detected. Recommended setup:"
        echo "  1. Create $CELERY_LOCATION"
        echo "  2. Create celeryconfig.py"
        echo "  3. Integrate with FastAPI lifespan"
        echo "  4. Create tasks.py"
        echo ""
        echo "Next steps:"
        echo "  bash scripts/generate-config.sh --framework=fastapi --broker=redis"
        ;;
    standalone)
        echo "No web framework detected. Recommended setup:"
        echo "  1. Create celery_app.py"
        echo "  2. Create celeryconfig.py"
        echo "  3. Create tasks.py"
        echo ""
        echo "Next steps:"
        echo "  bash scripts/generate-config.sh --framework=standalone --broker=redis"
        ;;
esac

echo ""
echo "For manual setup, see:"
echo "  examples/${FRAMEWORK}-setup.md"
echo ""

exit 0
