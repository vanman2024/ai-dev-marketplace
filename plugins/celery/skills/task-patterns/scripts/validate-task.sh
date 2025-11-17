#!/bin/bash
# Validate Celery Task Structure
#
# Usage: ./validate-task.sh <task_file.py>
#
# Validates that a Celery task follows best practices

set -euo pipefail

TASK_FILE="${1:-}"

if [[ -z "$TASK_FILE" ]]; then
    echo "❌ Error: Task file required"
    echo "Usage: $0 <task_file.py>"
    exit 1
fi

if [[ ! -f "$TASK_FILE" ]]; then
    echo "❌ Error: File not found: $TASK_FILE"
    exit 1
fi

echo "🔍 Validating Celery Task: $TASK_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ERRORS=0
WARNINGS=0

# Required Elements
echo ""
echo "📋 Required Elements:"

# Check for Celery import
if grep -q "from celery import Celery" "$TASK_FILE"; then
    echo "✅ Celery import present"
else
    echo "❌ Missing: from celery import Celery"
    ERRORS=$((ERRORS + 1))
fi

# Check for logger
if grep -q "from celery.utils.log import get_task_logger" "$TASK_FILE"; then
    echo "✅ Task logger import present"
else
    echo "⚠️  Missing: from celery.utils.log import get_task_logger"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for Celery app initialization
if grep -q "app = Celery(" "$TASK_FILE"; then
    echo "✅ Celery app initialized"
else
    echo "❌ Missing: app = Celery(...)"
    ERRORS=$((ERRORS + 1))
fi

# Check for broker configuration
if grep -q "broker=" "$TASK_FILE"; then
    echo "✅ Broker configured"
else
    echo "⚠️  No broker configuration (may be in config file)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for task decorator
if grep -q "@app\.task" "$TASK_FILE"; then
    echo "✅ Task decorator present"
else
    echo "❌ Missing: @app.task decorator"
    ERRORS=$((ERRORS + 1))
fi

# Task Best Practices
echo ""
echo "🎯 Best Practices:"

# Check for docstrings
TASK_FUNCTIONS=$(grep -n "^def " "$TASK_FILE" | wc -l)
DOCSTRINGS=$(grep -n '^\s*"""' "$TASK_FILE" | wc -l)

if [[ $DOCSTRINGS -ge $TASK_FUNCTIONS ]]; then
    echo "✅ All tasks have docstrings"
else
    echo "⚠️  Some tasks missing docstrings ($DOCSTRINGS/$TASK_FUNCTIONS)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for type hints
if grep -q ") ->" "$TASK_FILE"; then
    echo "✅ Type hints present"
else
    echo "⚠️  No return type hints found"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for error handling
if grep -q "try:" "$TASK_FILE" && grep -q "except" "$TASK_FILE"; then
    echo "✅ Error handling implemented"
else
    echo "⚠️  No error handling (recommended for production)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for logging
if grep -q "logger\." "$TASK_FILE"; then
    echo "✅ Logging statements present"
else
    echo "⚠️  No logging statements (recommended)"
    WARNINGS=$((WARNINGS + 1))
fi

# Retry Configuration
echo ""
echo "🔄 Retry Configuration:"

if grep -qE "autoretry_for|retry_backoff|max_retries" "$TASK_FILE"; then
    echo "✅ Retry configuration present"

    if grep -q "autoretry_for" "$TASK_FILE"; then
        echo "  ✓ autoretry_for configured"
    fi

    if grep -q "retry_backoff=True" "$TASK_FILE"; then
        echo "  ✓ Exponential backoff enabled"
    fi

    if grep -q "retry_jitter=True" "$TASK_FILE"; then
        echo "  ✓ Jitter enabled"
    fi

    if grep -q "max_retries" "$TASK_FILE"; then
        echo "  ✓ Max retries set"
    fi
else
    echo "ℹ️  No retry configuration (okay for simple tasks)"
fi

# Security Checks
echo ""
echo "🔒 Security Checks:"

SECURITY_ISSUES=0

# Check for hardcoded credentials
if grep -iE "(password|secret|api_key|token).*=.*['\"][^your_]" "$TASK_FILE"; then
    echo "⚠️  Potential hardcoded credentials:"
    grep -n -iE "(password|secret|api_key|token).*=.*['\"]" "$TASK_FILE" | head -5
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for SQL injection vulnerability
if grep -q "f\".*SELECT\|f\".*INSERT\|f\".*UPDATE\|f\".*DELETE" "$TASK_FILE"; then
    echo "⚠️  Potential SQL injection (use parameterized queries)"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

# Check for os.system or eval
if grep -qE "os\.system|eval\(" "$TASK_FILE"; then
    echo "⚠️  Unsafe function detected (os.system or eval)"
    SECURITY_ISSUES=$((SECURITY_ISSUES + 1))
fi

if [[ $SECURITY_ISSUES -eq 0 ]]; then
    echo "✅ No security issues detected"
else
    echo "❌ $SECURITY_ISSUES security issue(s) found"
    ERRORS=$((ERRORS + SECURITY_ISSUES))
fi

# Performance Checks
echo ""
echo "⚡ Performance Checks:"

# Check for rate limiting
if grep -q "rate_limit=" "$TASK_FILE"; then
    echo "✅ Rate limiting configured"
else
    echo "ℹ️  No rate limiting (consider for API tasks)"
fi

# Check for time limits
if grep -qE "soft_time_limit|time_limit" "$TASK_FILE"; then
    echo "✅ Time limits set"
else
    echo "ℹ️  No time limits (consider for long tasks)"
fi

# Check for task binding
if grep -q "bind=True" "$TASK_FILE"; then
    echo "✅ Task binding enabled (can access self)"
else
    echo "ℹ️  Task not bound (okay if not needed)"
fi

# Code Quality
echo ""
echo "✨ Code Quality:"

# Check for example usage
if grep -q "if __name__ == '__main__':" "$TASK_FILE"; then
    echo "✅ Example usage provided"
else
    echo "⚠️  No example usage (helpful for testing)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check for configuration examples
if grep -qE "Config|CONFIG|CELERY_" "$TASK_FILE"; then
    echo "✅ Configuration examples present"
else
    echo "ℹ️  No configuration examples"
fi

# Pattern Detection
echo ""
echo "🎨 Detected Patterns:"

if grep -q "autoretry_for" "$TASK_FILE"; then
    echo "  • Retry pattern"
fi

if grep -q "rate_limit=" "$TASK_FILE"; then
    echo "  • Rate limiting pattern"
fi

if grep -q "soft_time_limit\|time_limit" "$TASK_FILE"; then
    echo "  • Time limiting pattern"
fi

if grep -q "class.*Task.*:" "$TASK_FILE"; then
    echo "  • Custom task class pattern"
fi

if grep -q "BaseModel" "$TASK_FILE"; then
    echo "  • Pydantic validation pattern"
fi

if grep -q "requests\." "$TASK_FILE"; then
    echo "  • API call pattern"
fi

if grep -q "DatabaseTask\|\.db\|\.execute" "$TASK_FILE"; then
    echo "  • Database pattern"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary:"
echo ""
echo "  Errors:   $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    if [[ $WARNINGS -eq 0 ]]; then
        echo "✅ Perfect! Task follows all best practices."
    else
        echo "✅ Task is valid with $WARNINGS recommendation(s)."
    fi
    exit 0
else
    echo "❌ Task has $ERRORS error(s) that must be fixed."
    exit 1
fi
