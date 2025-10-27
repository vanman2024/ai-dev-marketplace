#!/usr/bin/env bash
# Validates Claude Agent SDK TypeScript configuration

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "🔍 Validating Claude Agent SDK TypeScript Configuration"
echo "Project: $PROJECT_DIR"
echo ""

# Check if package.json exists
if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
    echo "❌ ERROR: package.json not found"
    exit 2
fi

# Check for @claude-ai/sdk dependency
if ! grep -q '"@claude-ai/sdk"' "$PROJECT_DIR/package.json" 2>/dev/null; then
    echo "❌ ERROR: @claude-ai/sdk not found in dependencies"
    echo "   Fix: npm install @claude-ai/sdk"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ @claude-ai/sdk dependency found"
fi

# Check tsconfig.json
if [[ ! -f "$PROJECT_DIR/tsconfig.json" ]]; then
    echo "⚠️  WARNING: tsconfig.json not found"
    echo "   Fix: Copy from templates/tsconfig-sdk.json"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ tsconfig.json exists"

    # Check compiler options
    if ! grep -q '"module".*"commonjs"' "$PROJECT_DIR/tsconfig.json" 2>/dev/null && \
       ! grep -q '"module".*"esnext"' "$PROJECT_DIR/tsconfig.json" 2>/dev/null; then
        echo "⚠️  WARNING: module setting may not be optimal for SDK"
        echo "   Recommended: \"module\": \"commonjs\" or \"esnext\""
        WARNINGS=$((WARNINGS + 1))
    fi

    if ! grep -q '"esModuleInterop".*true' "$PROJECT_DIR/tsconfig.json" 2>/dev/null; then
        echo "⚠️  WARNING: esModuleInterop should be true for SDK compatibility"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check for node_modules
if [[ ! -d "$PROJECT_DIR/node_modules" ]]; then
    echo "⚠️  WARNING: node_modules not found - run npm install"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Node version
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ $NODE_VERSION -lt 18 ]]; then
    echo "❌ ERROR: Node.js 18+ required, found v$NODE_VERSION"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Node.js version compatible (v$NODE_VERSION)"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo "✅ All validations passed!"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo "⚠️  Validation completed with $WARNINGS warning(s)"
    exit 0
else
    echo "❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    exit 1
fi
