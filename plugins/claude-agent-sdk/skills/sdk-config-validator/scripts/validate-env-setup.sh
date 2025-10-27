#!/usr/bin/env bash
# Validates environment variable setup for Claude Agent SDK

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "🔍 Validating Environment Setup"
echo "Project: $PROJECT_DIR"
echo ""

# Check for .env file
if [[ ! -f "$PROJECT_DIR/.env" ]]; then
    echo "⚠️  WARNING: .env file not found"
    echo "   Recommended: Copy from templates/.env.example.template"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ .env file exists"

    # Check for required variables
    REQUIRED_VARS=("ANTHROPIC_API_KEY")

    for VAR in "${REQUIRED_VARS[@]}"; do
        if grep -q "^${VAR}=" "$PROJECT_DIR/.env" 2>/dev/null; then
            # Check if value is not empty
            VALUE=$(grep "^${VAR}=" "$PROJECT_DIR/.env" | cut -d= -f2- | tr -d ' "'"'"'')
            if [[ -z "$VALUE" ]] || [[ "$VALUE" == "your_api_key_here" ]]; then
                echo "❌ ERROR: $VAR is not set or has placeholder value"
                ERRORS=$((ERRORS + 1))
            else
                echo "✅ $VAR is configured"
            fi
        else
            echo "❌ ERROR: $VAR not found in .env"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check for optional but recommended variables
    OPTIONAL_VARS=("CLAUDE_MODEL" "MAX_TOKENS" "TEMPERATURE")

    for VAR in "${OPTIONAL_VARS[@]}"; do
        if grep -q "^${VAR}=" "$PROJECT_DIR/.env" 2>/dev/null; then
            echo "✅ $VAR is configured (optional)"
        else
            echo "ℹ️  INFO: $VAR not set (optional)"
        fi
    done
fi

# Check .env.example
if [[ ! -f "$PROJECT_DIR/.env.example" ]]; then
    echo "⚠️  WARNING: .env.example not found"
    echo "   Recommended for documentation and onboarding"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ .env.example exists"
fi

# Check .gitignore
if [[ -f "$PROJECT_DIR/.gitignore" ]]; then
    if ! grep -q "^\.env$" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
        echo "❌ ERROR: .env not in .gitignore - SECURITY RISK!"
        echo "   Fix: echo '.env' >> .gitignore"
        ((ERRORS++))
    else
        echo "✅ .env is in .gitignore (secure)"
    fi
else
    echo "⚠️  WARNING: .gitignore not found"
    WARNINGS=$((WARNINGS + 1))
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo "✅ All environment validations passed!"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo "⚠️  Validation completed with $WARNINGS warning(s)"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    exit 1
fi
