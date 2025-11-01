#!/bin/bash

# validate-deployment.sh - Pre-deployment validation for FastAPI applications
# Usage: ./validate-deployment.sh [OPTIONS]

set -euo pipefail

# Default values
APP_DIR="."
STRICT_MODE=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNINGS++))
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
    ((CHECKS++))
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
FastAPI Deployment Validation Script

Usage: ./validate-deployment.sh [OPTIONS]

Options:
  --app-dir=DIR    FastAPI application directory (default: .)
  --strict         Fail on warnings (treat warnings as errors)
  --verbose        Show detailed validation output
  --help           Display this help message

Validation Checks:
  ✓ requirements.txt exists and is valid
  ✓ Environment variable configuration (.env.example)
  ✓ FastAPI application structure (main.py or app/main.py)
  ✓ Database configuration (if applicable)
  ✓ CORS settings
  ✓ Security configurations (secret keys, allowed hosts)
  ✓ Dockerfile presence (for containerized deployment)
  ✓ Git ignore configuration (.gitignore)
  ✓ Health check endpoint
  ✓ Logging configuration

Exit Codes:
  0 - All checks passed
  1 - Errors found (or warnings in strict mode)

Examples:
  ./validate-deployment.sh
  ./validate-deployment.sh --app-dir=/path/to/app
  ./validate-deployment.sh --strict --verbose

EOF
}

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --app-dir=*)
            APP_DIR="${arg#*=}"
            shift
            ;;
        --strict)
            STRICT_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Change to app directory
cd "$APP_DIR"

print_info "Starting FastAPI deployment validation..."
print_info "Application Directory: $(pwd)"
if [ "$STRICT_MODE" = true ]; then
    print_info "Running in STRICT mode (warnings will fail validation)"
fi
echo ""

# ============================================
# Check 1: requirements.txt
# ============================================
print_check "Checking requirements.txt..."

if [ ! -f "requirements.txt" ]; then
    print_error "requirements.txt not found"
else
    print_success "requirements.txt exists"

    # Check for FastAPI
    if ! grep -q "fastapi" requirements.txt; then
        print_warning "fastapi not found in requirements.txt"
    else
        print_success "FastAPI dependency found"
    fi

    # Check for ASGI server
    if ! grep -E -q "(uvicorn|gunicorn|hypercorn)" requirements.txt; then
        print_warning "No ASGI server found (uvicorn, gunicorn, or hypercorn recommended)"
    else
        print_success "ASGI server dependency found"
    fi

    # Check for common production dependencies
    if ! grep -q "python-dotenv" requirements.txt; then
        print_warning "python-dotenv not found (recommended for environment variables)"
    fi

    # Validate requirements.txt format
    if python3 -m pip install --dry-run -r requirements.txt > /dev/null 2>&1; then
        print_success "requirements.txt format is valid"
    else
        print_error "requirements.txt has invalid format or dependencies"
    fi
fi

echo ""

# ============================================
# Check 2: Environment variables
# ============================================
print_check "Checking environment variable configuration..."

if [ ! -f ".env.example" ]; then
    print_warning ".env.example not found (recommended for deployment)"
else
    print_success ".env.example exists"

    # Check for critical environment variables
    if grep -q "SECRET_KEY" .env.example || grep -q "API_KEY" .env.example; then
        print_success "Secret key configuration found"
    else
        print_warning "No SECRET_KEY or API_KEY in .env.example"
    fi

    if grep -q "DATABASE_URL" .env.example; then
        print_success "Database URL configuration found"
    fi

    if grep -q "ENVIRONMENT" .env.example || grep -q "ENV" .env.example; then
        print_success "Environment variable (prod/dev) found"
    else
        print_warning "No ENVIRONMENT variable in .env.example"
    fi
fi

# Check for actual .env file
if [ -f ".env" ]; then
    print_success ".env file exists"

    # Warn about default values
    if grep -q "changeme\|your-secret\|example" .env; then
        print_warning ".env contains placeholder values (update before deployment)"
    fi
else
    print_warning ".env file not found (will need to be created for deployment)"
fi

echo ""

# ============================================
# Check 3: FastAPI application structure
# ============================================
print_check "Checking FastAPI application structure..."

MAIN_FILE=""
if [ -f "main.py" ]; then
    MAIN_FILE="main.py"
    print_success "main.py found"
elif [ -f "app/main.py" ]; then
    MAIN_FILE="app/main.py"
    print_success "app/main.py found"
elif [ -f "src/main.py" ]; then
    MAIN_FILE="src/main.py"
    print_success "src/main.py found"
else
    print_error "No main.py found (checked: main.py, app/main.py, src/main.py)"
fi

# Check FastAPI app instance
if [ -n "$MAIN_FILE" ]; then
    if grep -q "FastAPI()" "$MAIN_FILE" || grep -q "app = FastAPI" "$MAIN_FILE"; then
        print_success "FastAPI app instance found in $MAIN_FILE"
    else
        print_error "No FastAPI app instance found in $MAIN_FILE"
    fi

    # Check for health check endpoint
    if grep -q "/health" "$MAIN_FILE" || grep -q "healthcheck" "$MAIN_FILE"; then
        print_success "Health check endpoint found"
    else
        print_warning "No health check endpoint found (recommended: GET /health)"
    fi

    # Check CORS configuration
    if grep -q "CORSMiddleware" "$MAIN_FILE"; then
        print_success "CORS middleware configured"

        # Check if CORS origins are hardcoded
        if grep -q "allow_origins.*\[.*http" "$MAIN_FILE"; then
            print_warning "CORS origins appear to be hardcoded (use environment variables)"
        fi
    else
        print_warning "No CORS middleware found (may be needed for frontend integration)"
    fi
fi

echo ""

# ============================================
# Check 4: Database configuration
# ============================================
print_check "Checking database configuration..."

# Check for SQLAlchemy or other ORMs
if grep -r -q "sqlalchemy\|tortoise\|peewee" --include="*.py" .; then
    print_success "Database ORM detected"

    # Check for Alembic migrations
    if [ -d "alembic" ]; then
        print_success "Alembic migrations directory found"

        if [ -f "alembic.ini" ]; then
            print_success "alembic.ini found"
        else
            print_warning "alembic.ini not found"
        fi
    else
        print_warning "No Alembic migrations found (recommended for database versioning)"
    fi

    # Check for database URL in config
    if grep -r -q "DATABASE_URL" --include="*.py" .; then
        print_success "DATABASE_URL configuration found in code"
    else
        print_warning "No DATABASE_URL reference found in code"
    fi
else
    print_info "No database ORM detected (skipping database checks)"
fi

echo ""

# ============================================
# Check 5: Dockerfile
# ============================================
print_check "Checking Dockerfile for containerized deployment..."

if [ ! -f "Dockerfile" ]; then
    print_warning "Dockerfile not found (required for container deployment)"
else
    print_success "Dockerfile exists"

    # Check for multi-stage build
    if grep -q "FROM.*AS builder" Dockerfile || grep -q "FROM.*AS build" Dockerfile; then
        print_success "Multi-stage build detected (optimized)"
    else
        print_warning "Single-stage build (consider multi-stage for smaller images)"
    fi

    # Check for non-root user
    if grep -q "USER" Dockerfile; then
        print_success "Non-root user configured (security best practice)"
    else
        print_warning "Running as root user (security concern)"
    fi

    # Check for HEALTHCHECK
    if grep -q "HEALTHCHECK" Dockerfile; then
        print_success "HEALTHCHECK instruction found"
    else
        print_warning "No HEALTHCHECK in Dockerfile (recommended for orchestration)"
    fi
fi

echo ""

# ============================================
# Check 6: .gitignore
# ============================================
print_check "Checking .gitignore configuration..."

if [ ! -f ".gitignore" ]; then
    print_warning ".gitignore not found (recommended)"
else
    print_success ".gitignore exists"

    # Check for common patterns
    if grep -q ".env" .gitignore; then
        print_success ".env in .gitignore (prevents secret exposure)"
    else
        print_error ".env NOT in .gitignore (SECURITY RISK!)"
    fi

    if grep -q "__pycache__" .gitignore; then
        print_success "__pycache__ in .gitignore"
    else
        print_warning "__pycache__ not in .gitignore"
    fi

    if grep -q "*.pyc" .gitignore; then
        print_success "*.pyc in .gitignore"
    else
        print_warning "*.pyc not in .gitignore"
    fi
fi

echo ""

# ============================================
# Check 7: Security configurations
# ============================================
print_check "Checking security configurations..."

# Check for hardcoded secrets (basic check)
if grep -r -E "(password|secret|api_key).*=.*['\"]" --include="*.py" . 2>/dev/null | grep -v ".env" | grep -v "example" | head -1 > /dev/null; then
    print_error "Potential hardcoded secrets found in code (use environment variables)"
    if [ "$VERBOSE" = true ]; then
        echo "Found in:"
        grep -r -E "(password|secret|api_key).*=.*['\"]" --include="*.py" . 2>/dev/null | grep -v ".env" | grep -v "example" | head -3
    fi
else
    print_success "No obvious hardcoded secrets detected"
fi

# Check for HTTPS enforcement
if grep -r -q "redirect_https\|https_only" --include="*.py" .; then
    print_success "HTTPS enforcement detected"
else
    print_warning "No HTTPS enforcement found (recommended for production)"
fi

echo ""

# ============================================
# Check 8: Logging configuration
# ============================================
print_check "Checking logging configuration..."

if grep -r -q "logging\|logger" --include="*.py" .; then
    print_success "Logging configuration detected"

    # Check for structured logging
    if grep -r -q "structlog\|python-json-logger" --include="*.py" .; then
        print_success "Structured logging library detected"
    else
        print_info "Consider structured logging for production (structlog, python-json-logger)"
    fi
else
    print_warning "No logging configuration found (recommended for debugging)"
fi

echo ""

# ============================================
# Summary
# ============================================
print_info "============================================"
print_info "Validation Summary"
print_info "============================================"
echo ""
echo "Total Checks:   $CHECKS"
echo -e "Errors:         ${RED}$ERRORS${NC}"
echo -e "Warnings:       ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        print_success "All validation checks passed!"
        echo ""
        print_info "Your application is ready for deployment."
        exit 0
    else
        if [ "$STRICT_MODE" = true ]; then
            print_error "Validation failed in strict mode ($WARNINGS warnings)"
            exit 1
        else
            print_warning "$WARNINGS warning(s) found, but validation passed"
            echo ""
            print_info "Your application can be deployed, but consider addressing warnings."
            exit 0
        fi
    fi
else
    print_error "Validation failed with $ERRORS error(s)"
    echo ""
    print_info "Fix the errors above before deploying."
    exit 1
fi
