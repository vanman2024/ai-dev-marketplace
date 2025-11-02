#!/usr/bin/env bash
# Validates Claude Agent SDK Python configuration

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

echo "🔍 Validating Claude Agent SDK Python Configuration"
echo "Project: $PROJECT_DIR"
echo ""

# Check for pyproject.toml or requirements.txt
if [[ ! -f "$PROJECT_DIR/pyproject.toml" ]] && [[ ! -f "$PROJECT_DIR/requirements.txt" ]]; then
    echo "❌ ERROR: Neither pyproject.toml nor requirements.txt found"
    exit 2
fi

# Check for claude-agent-sdk dependency (CORRECT package name)
SDK_FOUND=false
WRONG_PACKAGE=false

# Check for WRONG package name
if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    if grep -q 'anthropic-agent-sdk' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
        echo "❌ ERROR: Wrong package 'anthropic-agent-sdk' found in pyproject.toml"
        echo "   Fix: Use 'claude-agent-sdk' instead"
        WRONG_PACKAGE=true
        ERRORS=$((ERRORS + 1))
    fi
fi

if [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
    if grep -q 'anthropic-agent-sdk' "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
        echo "❌ ERROR: Wrong package 'anthropic-agent-sdk' found in requirements.txt"
        echo "   Fix: Use 'claude-agent-sdk' instead"
        WRONG_PACKAGE=true
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check for CORRECT package name
if [[ -f "$PROJECT_DIR/pyproject.toml" ]]; then
    if grep -q 'claude-agent-sdk' "$PROJECT_DIR/pyproject.toml" 2>/dev/null; then
        echo "✅ claude-agent-sdk found in pyproject.toml"
        SDK_FOUND=true
    fi
fi

if [[ -f "$PROJECT_DIR/requirements.txt" ]]; then
    if grep -q 'claude-agent-sdk' "$PROJECT_DIR/requirements.txt" 2>/dev/null; then
        echo "✅ claude-agent-sdk found in requirements.txt"
        SDK_FOUND=true
    fi
fi

if [[ "$SDK_FOUND" == "false" ]] && [[ "$WRONG_PACKAGE" == "false" ]]; then
    echo "❌ ERROR: claude-agent-sdk not found in dependencies"
    echo "   Fix: pip install claude-agent-sdk"
    ERRORS=$((ERRORS + 1))
fi

# Check for wrong import pattern
if [[ -f "$PROJECT_DIR/main.py" ]]; then
    if grep -q 'from anthropic_agent_sdk import' "$PROJECT_DIR/main.py" 2>/dev/null; then
        echo "⚠️  WARNING: Wrong import 'anthropic_agent_sdk' in main.py"
        echo "   Fix: Use 'from claude_agent_sdk import query'"
        WARNINGS=$((WARNINGS + 1))
    fi

    if grep -q 'from claude_agent_sdk import' "$PROJECT_DIR/main.py" 2>/dev/null; then
        echo "✅ Correct import 'claude_agent_sdk' found"
    fi
fi

# Check for FastMCP Cloud SSE mistake
if find "$PROJECT_DIR" -name "*.py" -exec grep -l '"type".*:.*"sse"' {} \; 2>/dev/null | head -1 | grep -q .; then
    echo "⚠️  WARNING: Found 'type': 'sse' in Python code"
    echo "   FastMCP Cloud requires 'type': 'http' not 'sse'"
    echo "   Fix: Change to '\"type\": \"http\"' for FastMCP Cloud servers"
    WARNINGS=$((WARNINGS + 1))
fi

# Check Python version
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d. -f1,2)
    PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
    PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

    if [[ $PYTHON_MAJOR -lt 3 ]] || [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -lt 8 ]]; then
        echo "❌ ERROR: Python 3.8+ required, found $PYTHON_VERSION"
        ERRORS=$((ERRORS + 1))
    else
        echo "✅ Python version compatible ($PYTHON_VERSION)"
    fi
else
    echo "❌ ERROR: python3 not found in PATH"
    ERRORS=$((ERRORS + 1))
fi

# Check for virtual environment
if [[ ! -d "$PROJECT_DIR/venv" ]] && [[ ! -d "$PROJECT_DIR/.venv" ]]; then
    echo "⚠️  WARNING: No virtual environment found"
    echo "   Recommended: python3 -m venv venv"
    WARNINGS=$((WARNINGS + 1))
else
    echo "✅ Virtual environment found"
fi

# Check if SDK is installed
if command -v python3 &> /dev/null; then
    if python3 -c "import claude_sdk" 2>/dev/null; then
        echo "✅ claude-ai-sdk is importable"
    else
        echo "⚠️  WARNING: claude-ai-sdk not installed or not in PYTHONPATH"
        echo "   Fix: pip install -e . or pip install -r requirements.txt"
        WARNINGS=$((WARNINGS + 1))
    fi
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
