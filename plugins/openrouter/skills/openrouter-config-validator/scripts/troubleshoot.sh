#!/bin/bash
# Comprehensive troubleshooting script for OpenRouter configuration

set -e

CONFIG_FILE="${1:-.env}"

echo "🔧 OpenRouter Comprehensive Troubleshooting"
echo ""

# Check if config file exists
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ Configuration file found: $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "⚠️  Configuration file not found: $CONFIG_FILE"
    echo "   Creating from template..."

    if [ -f "$(dirname "$0")/../templates/.env.template" ]; then
        cp "$(dirname "$0")/../templates/.env.template" "$CONFIG_FILE"
        echo "   ✅ Template copied to $CONFIG_FILE"
        echo "   📝 Edit this file and add your API key"
    else
        echo "   ❌ Template not found"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Environment Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$CONFIG_FILE" ]; then
    bash "$(dirname "$0")/validate-env-config.sh" "$CONFIG_FILE"
else
    echo "❌ Cannot validate - config file missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. API Key Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$OPENROUTER_API_KEY" ]; then
    bash "$(dirname "$0")/validate-api-key.sh" "$OPENROUTER_API_KEY"
else
    echo "❌ OPENROUTER_API_KEY not set"
    echo "   Set in $CONFIG_FILE or environment"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Model Availability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$OPENROUTER_MODEL" ] && [ -n "$OPENROUTER_API_KEY" ]; then
    bash "$(dirname "$0")/check-model-availability.sh" "$OPENROUTER_MODEL" "$OPENROUTER_API_KEY"
elif [ -z "$OPENROUTER_MODEL" ]; then
    echo "ℹ️  No primary model configured"
else
    echo "❌ Cannot check - API key missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Routing Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$CONFIG_FILE" ]; then
    bash "$(dirname "$0")/test-routing.sh" "$CONFIG_FILE"
else
    echo "❌ Cannot test - config file missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Fallback Chain"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$CONFIG_FILE" ]; then
    bash "$(dirname "$0")/test-fallback.sh" "$CONFIG_FILE"
else
    echo "❌ Cannot test - config file missing"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Common Issues Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for common issues
ISSUES_FOUND=false

# Check 1: API key in .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo "⚠️  Issue: .env not in .gitignore"
        echo "   Fix: echo '.env' >> .gitignore"
        ISSUES_FOUND=true
    fi
fi

# Check 2: Required tools
if ! command -v curl &> /dev/null; then
    echo "⚠️  Issue: curl not installed"
    echo "   Fix: Install curl for API testing"
    ISSUES_FOUND=true
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️  Issue: jq not installed"
    echo "   Fix: Install jq for JSON parsing"
    ISSUES_FOUND=true
fi

# Check 3: File permissions
if [ -f "$CONFIG_FILE" ]; then
    PERMS=$(stat -c "%a" "$CONFIG_FILE" 2>/dev/null || stat -f "%A" "$CONFIG_FILE" 2>/dev/null)
    if [ "$PERMS" != "600" ] && [ "$PERMS" != "400" ]; then
        echo "⚠️  Issue: Insecure file permissions on $CONFIG_FILE ($PERMS)"
        echo "   Fix: chmod 600 $CONFIG_FILE"
        ISSUES_FOUND=true
    fi
fi

if [ "$ISSUES_FOUND" = false ]; then
    echo "✅ No common issues detected"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Next Steps"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "📖 Additional Resources:"
echo "   - API Key troubleshooting: examples/api-key-troubleshooting.md"
echo "   - Model issues: examples/model-not-found.md"
echo "   - Rate limiting: examples/rate-limiting.md"
echo "   - Fallback debugging: examples/fallback-issues.md"
echo "   - Cost optimization: examples/cost-optimization.md"
echo ""
echo "🌐 OpenRouter Resources:"
echo "   - Documentation: https://openrouter.ai/docs"
echo "   - Model list: https://openrouter.ai/models"
echo "   - Usage dashboard: https://openrouter.ai/settings/usage"
echo ""

echo "✅ Troubleshooting complete"
