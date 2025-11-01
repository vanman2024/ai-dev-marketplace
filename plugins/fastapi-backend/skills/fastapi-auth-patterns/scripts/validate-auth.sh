#!/bin/bash

# validate-auth.sh
# Validate FastAPI authentication configuration
# Usage: ./validate-auth.sh [project_dir]

set -e

PROJECT_DIR="${1:-.}"
cd "$PROJECT_DIR"

echo "🔍 Validating FastAPI Authentication Configuration..."
echo ""

ERRORS=0
WARNINGS=0

# Check Python packages
echo "📦 Checking required packages..."
REQUIRED_PACKAGES=("fastapi" "python-jose" "pwdlib")

for package in "${REQUIRED_PACKAGES[@]}"; do
    if pip show "$package" &> /dev/null; then
        echo "  ✅ $package installed"
    else
        echo "  ❌ $package NOT installed"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check .env file
echo ""
echo "🔐 Checking environment configuration..."
if [ -f ".env" ]; then
    echo "  ✅ .env file exists"

    # Check SECRET_KEY
    if grep -q "^SECRET_KEY=" .env; then
        SECRET_KEY=$(grep "^SECRET_KEY=" .env | cut -d '=' -f2)
        if [ ${#SECRET_KEY} -ge 32 ]; then
            echo "  ✅ SECRET_KEY is set (length: ${#SECRET_KEY})"
        else
            echo "  ⚠️  SECRET_KEY is too short (should be >= 32 characters)"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "  ❌ SECRET_KEY not found in .env"
        ERRORS=$((ERRORS + 1))
    fi

    # Check ALGORITHM
    if grep -q "^ALGORITHM=" .env; then
        ALGORITHM=$(grep "^ALGORITHM=" .env | cut -d '=' -f2)
        echo "  ✅ ALGORITHM is set ($ALGORITHM)"
    else
        echo "  ⚠️  ALGORITHM not set (will default to HS256)"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check ACCESS_TOKEN_EXPIRE_MINUTES
    if grep -q "^ACCESS_TOKEN_EXPIRE_MINUTES=" .env; then
        EXPIRE=$(grep "^ACCESS_TOKEN_EXPIRE_MINUTES=" .env | cut -d '=' -f2)
        echo "  ✅ ACCESS_TOKEN_EXPIRE_MINUTES is set ($EXPIRE)"
    else
        echo "  ⚠️  ACCESS_TOKEN_EXPIRE_MINUTES not set (will default to 30)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "  ❌ .env file not found"
    ERRORS=$((ERRORS + 1))
fi

# Check .gitignore
echo ""
echo "🔒 Checking security configuration..."
if [ -f ".gitignore" ]; then
    if grep -q "^\.env$" .gitignore; then
        echo "  ✅ .env is in .gitignore"
    else
        echo "  ⚠️  .env is NOT in .gitignore (security risk!)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo "  ⚠️  .gitignore not found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check authentication files
echo ""
echo "📁 Checking authentication files..."

AUTH_FILES=(
    "app/auth/models.py"
    "app/auth/dependencies.py"
    "app/auth/utils.py"
)

for file in "${AUTH_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file exists"

        # Additional checks based on file
        case "$file" in
            "app/auth/models.py")
                if grep -q "class Token" "$file" && grep -q "class User" "$file"; then
                    echo "     ✅ Required models defined"
                else
                    echo "     ⚠️  Missing required models (Token, User)"
                    WARNINGS=$((WARNINGS + 1))
                fi
                ;;
            "app/auth/dependencies.py")
                if grep -q "OAuth2PasswordBearer" "$file"; then
                    echo "     ✅ OAuth2 scheme configured"
                else
                    echo "     ❌ OAuth2 scheme not found"
                    ERRORS=$((ERRORS + 1))
                fi
                ;;
            "app/auth/utils.py")
                if grep -q "create_access_token" "$file" && grep -q "verify_password" "$file"; then
                    echo "     ✅ Token and password utilities present"
                else
                    echo "     ❌ Missing required utility functions"
                    ERRORS=$((ERRORS + 1))
                fi
                ;;
        esac
    else
        echo "  ⚠️  $file not found"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# Check for common issues in code
echo ""
echo "🐛 Checking for common issues..."

if [ -f "app/auth/dependencies.py" ]; then
    if grep -q "fake_users_db" "app/auth/dependencies.py"; then
        echo "  ⚠️  Using fake_users_db (replace with real database for production)"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All validation checks passed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Validation passed with $WARNINGS warning(s)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "💡 Review warnings above and fix before production deployment"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🔧 Fix the errors above before proceeding"
    echo ""
    echo "Quick fixes:"
    echo "  - Install packages: pip install fastapi python-jose[cryptography] pwdlib[argon2]"
    echo "  - Setup JWT: ./scripts/setup-jwt.sh"
    echo "  - Add .env to .gitignore"
    exit 1
fi
