#!/bin/bash
#
# FastAPI Project Structure Validator
#
# Usage: ./validate-structure.sh <project-directory>
#

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: Directory $PROJECT_DIR does not exist${NC}"
    exit 1
fi

echo -e "${GREEN}Validating FastAPI project structure: $PROJECT_DIR${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check function
check_file() {
    local file=$1
    local required=${2:-true}

    if [ -f "$PROJECT_DIR/$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
        return 0
    elif [ "$required" = "true" ]; then
        echo -e "  ${RED}✗${NC} $file (missing)"
        ((ERRORS++))
        return 1
    else
        echo -e "  ${YELLOW}○${NC} $file (optional, not found)"
        ((WARNINGS++))
        return 2
    fi
}

check_dir() {
    local dir=$1
    local required=${2:-true}

    if [ -d "$PROJECT_DIR/$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir/"
        return 0
    elif [ "$required" = "true" ]; then
        echo -e "  ${RED}✗${NC} $dir/ (missing)"
        ((ERRORS++))
        return 1
    else
        echo -e "  ${YELLOW}○${NC} $dir/ (optional, not found)"
        ((WARNINGS++))
        return 2
    fi
}

# 1. Check required files
echo "Checking required files..."
check_file "pyproject.toml"
check_file ".gitignore"
check_file ".env.example" false
check_file "README.md" false

# 2. Check for main entry point
echo ""
echo "Checking application entry point..."
if [ -f "$PROJECT_DIR/main.py" ]; then
    check_file "main.py"
elif [ -f "$PROJECT_DIR/app/main.py" ]; then
    check_file "app/main.py"
else
    echo -e "  ${RED}✗${NC} No main.py found (checked main.py and app/main.py)"
    ((ERRORS++))
fi

# 3. Check directory structure
echo ""
echo "Checking directory structure..."

if [ -d "$PROJECT_DIR/app" ]; then
    check_dir "app"
    check_dir "app/core" false
    check_dir "app/api" false
    check_dir "app/api/routes" false
    check_dir "app/models" false
    check_dir "app/schemas" false
    check_dir "app/services" false
fi

check_dir "tests" false

# 4. Validate Python syntax
echo ""
echo "Validating Python syntax..."

if command -v python3 &> /dev/null; then
    SYNTAX_ERRORS=0

    while IFS= read -r -d '' file; do
        if ! python3 -m py_compile "$file" 2>/dev/null; then
            echo -e "  ${RED}✗${NC} Syntax error in: $file"
            ((SYNTAX_ERRORS++))
        fi
    done < <(find "$PROJECT_DIR" -name "*.py" -print0 2>/dev/null)

    if [ $SYNTAX_ERRORS -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} All Python files have valid syntax"
    else
        echo -e "  ${RED}✗${NC} Found $SYNTAX_ERRORS file(s) with syntax errors"
        ((ERRORS+=SYNTAX_ERRORS))
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Python3 not found, skipping syntax validation"
    ((WARNINGS++))
fi

# 5. Check dependencies in pyproject.toml
echo ""
echo "Checking dependencies..."

if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    REQUIRED_DEPS=("fastapi" "uvicorn" "pydantic")

    for dep in "${REQUIRED_DEPS[@]}"; do
        if grep -q "$dep" "$PROJECT_DIR/pyproject.toml"; then
            echo -e "  ${GREEN}✓${NC} $dep declared"
        else
            echo -e "  ${YELLOW}⚠${NC} $dep not found in dependencies"
            ((WARNINGS++))
        fi
    done
fi

# 6. Check for environment variable configuration
echo ""
echo "Checking environment configuration..."

if [ -f "$PROJECT_DIR/.env.example" ]; then
    if grep -q "SECRET_KEY" "$PROJECT_DIR/.env.example"; then
        echo -e "  ${GREEN}✓${NC} SECRET_KEY defined in .env.example"
    else
        echo -e "  ${YELLOW}⚠${NC} SECRET_KEY not found in .env.example"
        ((WARNINGS++))
    fi
fi

if [ -f "$PROJECT_DIR/.env" ]; then
    echo -e "  ${YELLOW}⚠${NC} .env file exists (ensure it's in .gitignore)"

    if [ -f "$PROJECT_DIR/.gitignore" ] && ! grep -q "^\.env$" "$PROJECT_DIR/.gitignore"; then
        echo -e "  ${RED}✗${NC} .env is NOT in .gitignore - SECURITY RISK!"
        ((ERRORS++))
    else
        echo -e "  ${GREEN}✓${NC} .env is properly gitignored"
    fi
fi

# 7. Check for config.py with settings
echo ""
echo "Checking settings configuration..."

CONFIG_FILES=("app/core/config.py" "app/config.py" "config.py")
CONFIG_FOUND=false

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$config_file" ]; then
        echo -e "  ${GREEN}✓${NC} Found settings at: $config_file"
        CONFIG_FOUND=true

        # Check for Pydantic Settings usage
        if grep -q "BaseSettings\|Settings" "$PROJECT_DIR/$config_file"; then
            echo -e "  ${GREEN}✓${NC} Using Pydantic Settings"
        else
            echo -e "  ${YELLOW}⚠${NC} Not using Pydantic Settings (recommended)"
            ((WARNINGS++))
        fi
        break
    fi
done

if [ "$CONFIG_FOUND" = false ]; then
    echo -e "  ${YELLOW}⚠${NC} No config.py found (recommended for settings management)"
    ((WARNINGS++))
fi

# 8. Check for __init__.py files in packages
echo ""
echo "Checking Python package structure..."

if [ -d "$PROJECT_DIR/app" ]; then
    MISSING_INIT=0

    while IFS= read -r -d '' dir; do
        if [ ! -f "$dir/__init__.py" ]; then
            echo -e "  ${YELLOW}⚠${NC} Missing __init__.py in: ${dir#$PROJECT_DIR/}"
            ((MISSING_INIT++))
        fi
    done < <(find "$PROJECT_DIR/app" -type d -print0 2>/dev/null)

    if [ $MISSING_INIT -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} All packages have __init__.py"
    else
        echo -e "  ${YELLOW}⚠${NC} $MISSING_INIT director(ies) missing __init__.py"
        ((WARNINGS+=MISSING_INIT))
    fi
fi

# 9. Check for MCP integration (if .mcp.json exists)
echo ""
echo "Checking MCP integration..."

if [ -f "$PROJECT_DIR/.mcp.json" ]; then
    echo -e "  ${GREEN}✓${NC} .mcp.json found"

    if [ -d "$PROJECT_DIR/app/mcp" ]; then
        echo -e "  ${GREEN}✓${NC} MCP directory structure exists"
    else
        echo -e "  ${YELLOW}⚠${NC} .mcp.json exists but no app/mcp directory"
        ((WARNINGS++))
    fi
else
    echo -e "  ${YELLOW}○${NC} No MCP integration detected"
fi

# 10. Check for test configuration
echo ""
echo "Checking test setup..."

if [ -d "$PROJECT_DIR/tests" ]; then
    if [ -f "$PROJECT_DIR/tests/conftest.py" ]; then
        echo -e "  ${GREEN}✓${NC} pytest conftest.py found"
    else
        echo -e "  ${YELLOW}⚠${NC} No conftest.py (recommended for pytest fixtures)"
        ((WARNINGS++))
    fi

    # Check for test files
    TEST_COUNT=$(find "$PROJECT_DIR/tests" -name "test_*.py" | wc -l)
    if [ $TEST_COUNT -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Found $TEST_COUNT test file(s)"
    else
        echo -e "  ${YELLOW}⚠${NC} No test files found (test_*.py)"
        ((WARNINGS++))
    fi
fi

# Summary
echo ""
echo "=========================================="
echo "Validation Summary"
echo "=========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Perfect! No errors or warnings found.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation passed with $WARNINGS warning(s).${NC}"
    echo "  Consider addressing warnings for best practices."
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s).${NC}"
    echo "  Please fix errors before proceeding."
    exit 1
fi
