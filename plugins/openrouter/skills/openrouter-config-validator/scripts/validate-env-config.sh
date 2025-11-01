#!/bin/bash
# Validates .env file configuration for OpenRouter

set -e

ENV_FILE="${1:-.env}"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Environment file not found: $ENV_FILE"
    echo "Usage: $0 [env-file]"
    exit 1
fi

echo "🔍 Validating OpenRouter Environment Configuration"
echo "File: $ENV_FILE"
echo ""

# Check file is readable
if [ ! -r "$ENV_FILE" ]; then
    echo "❌ Error: Cannot read file: $ENV_FILE"
    exit 1
fi

# Load environment
set -a
source "$ENV_FILE"
set +a

echo "1. Required Variables"
REQUIRED=(
    "OPENROUTER_API_KEY:API key for authentication"
)

ALL_PRESENT=true
for ENTRY in "${REQUIRED[@]}"; do
    VAR="${ENTRY%%:*}"
    DESC="${ENTRY#*:}"

    if [ -z "${!VAR}" ]; then
        echo "   ❌ Missing: $VAR ($DESC)"
        ALL_PRESENT=false
    else
        echo "   ✅ Present: $VAR"
    fi
done

if [ "$ALL_PRESENT" = false ]; then
    echo ""
    echo "❌ Configuration incomplete - missing required variables"
    exit 1
fi
echo ""

echo "2. Optional Variables"
OPTIONAL=(
    "OPENROUTER_MODEL:Primary model to use"
    "OPENROUTER_FALLBACK_MODELS:Comma-separated fallback models"
    "OPENROUTER_APP_TITLE:Application name for monitoring"
    "OPENROUTER_SITE_URL:Site URL for monitoring"
    "OPENROUTER_PROVIDER_PREFERENCES:Provider routing preferences"
)

for ENTRY in "${OPTIONAL[@]}"; do
    VAR="${ENTRY%%:*}"
    DESC="${ENTRY#*:}"

    if [ -z "${!VAR}" ]; then
        echo "   ℹ️  Not set: $VAR ($DESC)"
    else
        echo "   ✅ Set: $VAR"
    fi
done
echo ""

echo "3. API Key Validation"
if [[ $OPENROUTER_API_KEY =~ ^sk-or-v1-[a-f0-9]{64}$ ]]; then
    echo "   ✅ API key format is correct"
else
    echo "   ⚠️  API key format may be incorrect"
    echo "   Expected: sk-or-v1-{64 hex characters}"
fi
echo ""

echo "4. Model Configuration"
if [ -n "$OPENROUTER_MODEL" ]; then
    echo "   ✅ Primary model configured: $OPENROUTER_MODEL"
else
    echo "   ⚠️  No primary model configured"
    echo "   Requests will need to specify model explicitly"
fi

if [ -n "$OPENROUTER_FALLBACK_MODELS" ]; then
    IFS=',' read -ra FALLBACKS <<< "$OPENROUTER_FALLBACK_MODELS"
    echo "   ✅ Fallback models configured: ${#FALLBACKS[@]} model(s)"
else
    echo "   ℹ️  No fallback models configured"
fi
echo ""

echo "5. Monitoring Configuration"
if [ -n "$OPENROUTER_APP_TITLE" ] && [ -n "$OPENROUTER_SITE_URL" ]; then
    echo "   ✅ Full monitoring configured"
    echo "   - App Title: $OPENROUTER_APP_TITLE"
    echo "   - Site URL: $OPENROUTER_SITE_URL"
elif [ -n "$OPENROUTER_APP_TITLE" ] || [ -n "$OPENROUTER_SITE_URL" ]; then
    echo "   ⚠️  Partial monitoring configuration"
    [ -n "$OPENROUTER_APP_TITLE" ] && echo "   - App Title: $OPENROUTER_APP_TITLE"
    [ -n "$OPENROUTER_SITE_URL" ] && echo "   - Site URL: $OPENROUTER_SITE_URL"
else
    echo "   ℹ️  No monitoring configured (optional)"
fi
echo ""

echo "6. Security Check"
# Check file permissions
PERMS=$(stat -c "%a" "$ENV_FILE" 2>/dev/null || stat -f "%A" "$ENV_FILE" 2>/dev/null)
if [ "$PERMS" = "600" ] || [ "$PERMS" = "400" ]; then
    echo "   ✅ File permissions secure ($PERMS)"
else
    echo "   ⚠️  File permissions may be too open ($PERMS)"
    echo "   Recommend: chmod 600 $ENV_FILE"
fi

# Check if file is in .gitignore
if [ -f .gitignore ]; then
    if grep -q "^\.env$" .gitignore; then
        echo "   ✅ .env is in .gitignore"
    else
        echo "   ⚠️  .env not in .gitignore - risk of committing secrets"
    fi
fi
echo ""

echo "✅ Environment validation complete"
