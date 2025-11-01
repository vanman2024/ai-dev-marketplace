#!/bin/bash
# Tests OpenRouter fallback chain execution

set -e

CONFIG_FILE="${1:-.env}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Configuration file not found: $CONFIG_FILE"
    echo "Usage: $0 [config-file]"
    exit 1
fi

echo "🔍 Testing OpenRouter Fallback Chain"
echo ""

# Load configuration
source "$CONFIG_FILE"

if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "❌ Error: OPENROUTER_API_KEY not set in $CONFIG_FILE"
    exit 1
fi

# Parse fallback models
if [ -z "$OPENROUTER_FALLBACK_MODELS" ]; then
    echo "ℹ️  No fallback models configured"
    echo "Set OPENROUTER_FALLBACK_MODELS in $CONFIG_FILE"
    exit 0
fi

IFS=',' read -ra FALLBACKS <<< "$OPENROUTER_FALLBACK_MODELS"

echo "1. Fallback Chain Configuration"
echo "   Primary model: ${OPENROUTER_MODEL:-not set}"
echo "   Fallback models: ${#FALLBACKS[@]}"
for i in "${!FALLBACKS[@]}"; do
    MODEL=$(echo "${FALLBACKS[$i]}" | xargs)
    echo "   $((i+1)). $MODEL"
done
echo ""

echo "2. Testing Each Fallback Model"
AVAILABLE_COUNT=0
UNAVAILABLE=()

for MODEL in "${FALLBACKS[@]}"; do
    MODEL=$(echo "$MODEL" | xargs)
    echo "   Testing: $MODEL"

    if bash "$(dirname "$0")/check-model-availability.sh" "$MODEL" "$OPENROUTER_API_KEY" > /dev/null 2>&1; then
        echo "     ✅ Available"
        ((AVAILABLE_COUNT++))
    else
        echo "     ❌ Not available"
        UNAVAILABLE+=("$MODEL")
    fi
done
echo ""

echo "3. Fallback Chain Health"
if [ $AVAILABLE_COUNT -eq ${#FALLBACKS[@]} ]; then
    echo "   ✅ All fallback models available (${AVAILABLE_COUNT}/${#FALLBACKS[@]})"
elif [ $AVAILABLE_COUNT -gt 0 ]; then
    echo "   ⚠️  Partial availability (${AVAILABLE_COUNT}/${#FALLBACKS[@]} available)"
    echo "   Unavailable models:"
    for MODEL in "${UNAVAILABLE[@]}"; do
        echo "   - $MODEL"
    done
else
    echo "   ❌ No fallback models available"
    echo "   Fallback chain will not work"
fi
echo ""

echo "4. Recommendations"
if [ $AVAILABLE_COUNT -eq 0 ]; then
    echo "   🔧 Update fallback models to currently available models"
    echo "   📖 Check OpenRouter docs for model availability"
elif [ ${#UNAVAILABLE[@]} -gt 0 ]; then
    echo "   🔧 Remove unavailable models from fallback chain"
    echo "   📖 Consider adding more fallback models for redundancy"
else
    echo "   ✅ Fallback chain is properly configured"
    echo "   💡 Consider testing with actual API calls to verify behavior"
fi
echo ""

echo "✅ Fallback testing complete"
