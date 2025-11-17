#!/bin/bash
# validate-framework.sh - Validate Celery framework integration setup
# Usage: ./validate-framework.sh <framework>
# Frameworks: django, flask, fastapi

set -e

FRAMEWORK=$1
if [[ -z "$FRAMEWORK" ]]; then
    echo "Usage: $0 <framework>"
    echo "Frameworks: django, flask, fastapi"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Celery + $FRAMEWORK integration..."
echo ""

# Function to check if package is installed
check_package() {
    local package=$1
    if pip show "$package" &>/dev/null; then
        echo -e "${GREEN}✓${NC} Package '$package' is installed"
        return 0
    else
        echo -e "${RED}✗${NC} Package '$package' is NOT installed"
        echo "  Install with: pip install $package"
        return 1
    fi
}

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $description exists: $file"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} $description not found: $file"
        return 1
    fi
}

# Function to check file content
check_content() {
    local file=$1
    local pattern=$2
    local description=$3
    if [[ -f "$file" ]] && grep -q "$pattern" "$file"; then
        echo -e "${GREEN}✓${NC} $description found in $file"
        return 0
    else
        echo -e "${RED}✗${NC} $description NOT found in $file"
        return 1
    fi
}

ERRORS=0

# Validate common requirements
echo "📦 Checking common packages..."
check_package "celery" || ((ERRORS++))
echo ""

# Framework-specific validation
case "$FRAMEWORK" in
    django)
        echo "🔷 Validating Django integration..."
        echo ""

        # Check packages
        echo "📦 Checking Django packages..."
        check_package "django" || ((ERRORS++))
        check_package "django-celery-beat" || echo "  (Optional for periodic tasks)"
        check_package "django-celery-results" || echo "  (Optional for DB result backend)"
        echo ""

        # Check files
        echo "📁 Checking Django files..."
        check_file "manage.py" "Django project" || ((ERRORS++))

        # Look for celery.py in common locations
        CELERY_FILE=""
        if [[ -f "celery.py" ]]; then
            CELERY_FILE="celery.py"
        else
            # Find project directory (contains settings.py)
            PROJECT_DIR=$(find . -maxdepth 2 -name "settings.py" -exec dirname {} \; | head -1)
            if [[ -n "$PROJECT_DIR" ]]; then
                CELERY_FILE="$PROJECT_DIR/celery.py"
            fi
        fi

        if [[ -n "$CELERY_FILE" ]] && [[ -f "$CELERY_FILE" ]]; then
            check_file "$CELERY_FILE" "Celery configuration" || ((ERRORS++))
            check_content "$CELERY_FILE" "from celery import Celery" "Celery import" || ((ERRORS++))
            check_content "$CELERY_FILE" "django.setup()" "Django setup" || ((ERRORS++))
        else
            echo -e "${RED}✗${NC} Celery configuration (celery.py) not found"
            echo "  Expected in project root or alongside settings.py"
            ((ERRORS++))
        fi

        # Check settings
        SETTINGS_FILE=$(find . -maxdepth 2 -name "settings.py" | head -1)
        if [[ -f "$SETTINGS_FILE" ]]; then
            check_content "$SETTINGS_FILE" "CELERY_BROKER_URL" "Celery broker config" || ((ERRORS++))
        fi
        echo ""

        # Check for transaction safety
        echo "⚠️  Django-specific checks:"
        echo "   Make sure to use transaction.on_commit() for tasks that depend on DB state"
        echo "   See: templates/transaction-safe-django.py"
        ;;

    flask)
        echo "🔷 Validating Flask integration..."
        echo ""

        # Check packages
        echo "📦 Checking Flask packages..."
        check_package "flask" || ((ERRORS++))
        echo ""

        # Check files
        echo "📁 Checking Flask files..."
        FLASK_APP=$(find . -maxdepth 2 -name "__init__.py" -o -name "app.py" | head -1)
        if [[ -f "$FLASK_APP" ]]; then
            check_file "$FLASK_APP" "Flask app" || ((ERRORS++))
        else
            echo -e "${RED}✗${NC} Flask app (__init__.py or app.py) not found"
            ((ERRORS++))
        fi

        CELERY_FILE=$(find . -maxdepth 2 -name "celery.py" -o -name "celery_app.py" | head -1)
        if [[ -f "$CELERY_FILE" ]]; then
            check_file "$CELERY_FILE" "Celery configuration" || ((ERRORS++))
            check_content "$CELERY_FILE" "from celery import Celery" "Celery import" || ((ERRORS++))
        else
            echo -e "${RED}✗${NC} Celery configuration not found"
            echo "  Expected: celery.py or celery_app.py"
            ((ERRORS++))
        fi
        echo ""

        # Check for app context handling
        echo "⚠️  Flask-specific checks:"
        echo "   Make sure tasks use app.app_context() for DB/config access"
        echo "   See: templates/flask-context.py"
        ;;

    fastapi)
        echo "🔷 Validating FastAPI integration..."
        echo ""

        # Check packages
        echo "📦 Checking FastAPI packages..."
        check_package "fastapi" || ((ERRORS++))
        check_package "uvicorn" || echo "  (Recommended for running FastAPI)"
        echo ""

        # Check files
        echo "📁 Checking FastAPI files..."
        FASTAPI_MAIN=$(find . -maxdepth 2 -name "main.py" | head -1)
        if [[ -f "$FASTAPI_MAIN" ]]; then
            check_file "$FASTAPI_MAIN" "FastAPI app" || ((ERRORS++))
            check_content "$FASTAPI_MAIN" "from fastapi import FastAPI" "FastAPI import" || ((ERRORS++))
        else
            echo -e "${YELLOW}⚠${NC} FastAPI main.py not found (may use different name)"
        fi

        CELERY_FILE=$(find . -maxdepth 2 -name "celery_app.py" -o -name "celery.py" | head -1)
        if [[ -f "$CELERY_FILE" ]]; then
            check_file "$CELERY_FILE" "Celery configuration" || ((ERRORS++))
            check_content "$CELERY_FILE" "from celery import Celery" "Celery import" || ((ERRORS++))
        else
            echo -e "${RED}✗${NC} Celery configuration not found"
            echo "  Expected: celery_app.py or celery.py"
            ((ERRORS++))
        fi
        echo ""

        # Check for async patterns
        echo "⚠️  FastAPI-specific checks:"
        echo "   Consider FastAPI BackgroundTasks for short tasks (<30s)"
        echo "   Use Celery for long-running, distributed tasks"
        echo "   See: templates/fastapi-background.py"
        ;;

    *)
        echo -e "${RED}✗${NC} Unknown framework: $FRAMEWORK"
        echo "Supported frameworks: django, flask, fastapi"
        exit 1
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}✓ All validation checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run test: ./scripts/test-integration.sh $FRAMEWORK"
    echo "  2. Start Celery worker: celery -A your_app worker -l info"
    echo "  3. Check examples: examples/${FRAMEWORK}-complete-setup.md"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s)${NC}"
    echo ""
    echo "Fix the errors above and run validation again."
    echo "See templates/${FRAMEWORK}-integration/ for setup guidance."
    exit 1
fi
