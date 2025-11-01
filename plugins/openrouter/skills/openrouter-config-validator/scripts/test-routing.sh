#!/bin/bash
# Tests OpenRouter model routing configuration

set -e

CONFIG_FILE="${1:-.env}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Configuration file not found: $CONFIG_FILE"
    echo "Usage: $0 [config-file]"
    exit 1
fi

echo "🔍 Testing OpenRouter Routing Configuration"
echo "Config file: $CONFIG_FILE"
echo ""

# Load configuration
source "$CONFIG_FILE"

# Validate required variables
echo "1. Configuration Validation"
REQUIRED_VARS=("OPENROUTER_API_KEY")
MISSING=()

for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING+=("$VAR")
    fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "   ❌ Missing required variables:"
    for VAR in "${MISSING[@]}"; do
        echo "   - $VAR"
    done
    exit 1
fi

echo "   ✅ Required variables present"
echo ""

# Test basic routing
echo "2. Testing Basic Model Routing"
if [ -n "$OPENROUTER_MODEL" ]; then
    echo "   Primary model: $OPENROUTER_MODEL"

    # Test model availability
    if bash "$(dirname "$0")/check-model-availability.sh" "$OPENROUTER_MODEL" "$OPENROUTER_API_KEY" > /dev/null 2>&1; then
        echo "   ✅ Primary model is available"
    else
        echo "   ❌ Primary model not available"
    fi
else
    echo "   ⚠️  No primary model configured (OPENROUTER_MODEL not set)"
fi
echo ""

# Test fallback configuration
echo "3. Testing Fallback Configuration"
if [ -n "$OPENROUTER_FALLBACK_MODELS" ]; then
    echo "   Fallback models configured: $OPENROUTER_FALLBACK_MODELS"

    IFS=',' read -ra FALLBACKS <<< "$OPENROUTER_FALLBACK_MODELS"
    for MODEL in "${FALLBACKS[@]}"; do
        MODEL=$(echo "$MODEL" | xargs) # Trim whitespace
        echo "   Testing: $MODEL"

        if bash "$(dirname "$0")/check-model-availability.sh" "$MODEL" "$OPENROUTER_API_KEY" > /dev/null 2>&1; then
            echo "     ✅ Available"
        else
            echo "     ❌ Not available"
        fi
    done
else
    echo "   ⚠️  No fallback models configured"
fi
echo ""

# Test provider preferences
echo "4. Testing Provider Preferences"
if [ -n "$OPENROUTER_PROVIDER_PREFERENCES" ]; then
    echo "   Provider preferences: $OPENROUTER_PROVIDER_PREFERENCES"
    echo "   ✅ Configured"
else
    echo "   ℹ️  No provider preferences set (using default routing)"
fi
echo ""

# Test monitoring configuration
echo "5. Testing Monitoring Configuration"
MONITORING_OK=true

if [ -z "$OPENROUTER_APP_TITLE" ]; then
    echo "   ⚠️  X-Title not set (optional but recommended)"
    MONITORING_OK=false
fi

if [ -z "$OPENROUTER_SITE_URL" ]; then
    echo "   ⚠️  HTTP-Referer not set (optional but recommended)"
    MONITORING_OK=false
fi

if [ "$MONITORING_OK" = true ]; then
    echo "   ✅ Monitoring configured"
    echo "   - X-Title: $OPENROUTER_APP_TITLE"
    echo "   - HTTP-Referer: $OPENROUTER_SITE_URL"
fi
echo ""

echo "✅ Routing configuration test complete"
