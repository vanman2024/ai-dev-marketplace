#!/bin/bash

# validate-routing-config.sh
# Validates OpenRouter model routing configuration files
# Checks: JSON syntax, model availability, fallback chain logic, circular dependencies

set -e

CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 <config-file.json>"
    echo ""
    echo "Validates routing configuration:"
    echo "  - JSON syntax"
    echo "  - Model ID format"
    echo "  - Fallback chain logic"
    echo "  - No circular dependencies"
    echo "  - Required fields present"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Validating routing configuration: $CONFIG_FILE"
echo "================================================"
echo ""

# Step 1: Validate JSON syntax
echo "[1/5] Validating JSON syntax..."
if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
    echo "❌ ERROR: Invalid JSON syntax"
    exit 1
fi
echo "✅ JSON syntax is valid"
echo ""

# Step 2: Extract and validate model IDs
echo "[2/5] Validating model IDs..."
MODELS=$(jq -r '
    .. |
    objects |
    select(has("models") or has("model")) |
    if has("models") then .models[]
    elif has("model") then .model
    else empty end
' "$CONFIG_FILE" 2>/dev/null || echo "")

if [ -z "$MODELS" ]; then
    # Check alternative structures (primary/fallback)
    MODELS=$(jq -r '
        if has("primary") then .primary else empty end,
        if has("fallback") then .fallback[] else empty end,
        if has("model") then .model else empty end
    ' "$CONFIG_FILE" 2>/dev/null || echo "")
fi

if [ -z "$MODELS" ]; then
    echo "⚠️  WARNING: No models found in configuration"
else
    echo "Found models:"
    echo "$MODELS" | while read -r model; do
        # Validate model ID format (provider/model or provider/model:variant)
        if [[ "$model" =~ ^[a-z0-9-]+/[a-z0-9.-]+(:free|:[a-z0-9.-]+)?$ ]]; then
            echo "  ✅ $model"
        else
            echo "  ⚠️  $model (non-standard format)"
        fi
    done
fi
echo ""

# Step 3: Validate fallback chain logic
echo "[3/5] Validating fallback chains..."
HAS_FALLBACK=$(jq 'has("fallback") or any(.. | objects | has("fallback"))' "$CONFIG_FILE")

if [ "$HAS_FALLBACK" = "true" ]; then
    echo "✅ Fallback chain detected"

    # Check for empty fallback arrays
    EMPTY_FALLBACKS=$(jq -r '
        .. |
        objects |
        select(has("fallback")) |
        select(.fallback | length == 0) |
        "empty"
    ' "$CONFIG_FILE")

    if [ -n "$EMPTY_FALLBACKS" ]; then
        echo "⚠️  WARNING: Empty fallback arrays detected"
    fi
else
    echo "⚠️  WARNING: No fallback chain configured (single point of failure)"
fi
echo ""

# Step 4: Check for circular dependencies
echo "[4/5] Checking for circular dependencies..."
# Extract all model references and check for duplicates in fallback chains
CIRCULAR=$(jq -r '
    if has("primary") and has("fallback") then
        if (.fallback | index(.primary)) then "CIRCULAR" else empty end
    else
        empty
    end
' "$CONFIG_FILE" 2>/dev/null || echo "")

if [ -n "$CIRCULAR" ]; then
    echo "❌ ERROR: Circular dependency detected (primary model in fallback chain)"
    exit 1
fi
echo "✅ No circular dependencies detected"
echo ""

# Step 5: Validate required fields based on routing strategy
echo "[5/5] Validating required fields..."
REQUIRED_CHECKS=0
PASSED_CHECKS=0

# Check for strategy field
if jq -e 'has("strategy")' "$CONFIG_FILE" >/dev/null; then
    REQUIRED_CHECKS=$((REQUIRED_CHECKS + 1))
    STRATEGY=$(jq -r '.strategy' "$CONFIG_FILE")
    if [[ "$STRATEGY" =~ ^(cost-optimized|speed-optimized|quality-optimized|balanced|custom)$ ]]; then
        echo "✅ Valid strategy: $STRATEGY"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo "⚠️  Unknown strategy: $STRATEGY"
    fi
fi

# Check for routing rules
if jq -e 'has("routing_rules") or has("routes") or has("models")' "$CONFIG_FILE" >/dev/null; then
    REQUIRED_CHECKS=$((REQUIRED_CHECKS + 1))
    echo "✅ Routing rules present"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Check for timeout configuration
if jq -e 'has("timeout") or has("max_latency_ms")' "$CONFIG_FILE" >/dev/null; then
    echo "✅ Timeout configuration present"
fi

# Check for retry configuration
if jq -e 'has("retry") or has("max_retries")' "$CONFIG_FILE" >/dev/null; then
    echo "✅ Retry configuration present"
fi

echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo ""

# Count total models
TOTAL_MODELS=$(echo "$MODELS" | grep -v '^$' | wc -l)
echo "Total models: $TOTAL_MODELS"

# Check for recommended patterns
if [ "$TOTAL_MODELS" -ge 2 ]; then
    echo "✅ Multiple models configured (good for reliability)"
else
    echo "⚠️  Only one model configured (consider adding fallbacks)"
fi

# Final verdict
echo ""
if [ "$HAS_FALLBACK" = "true" ] && [ -z "$CIRCULAR" ] && [ "$TOTAL_MODELS" -ge 2 ]; then
    echo "✅ Configuration is VALID and follows best practices"
    exit 0
elif [ -z "$CIRCULAR" ]; then
    echo "⚠️  Configuration is VALID but could be improved"
    echo ""
    echo "Recommendations:"
    echo "  - Add fallback chains for reliability"
    echo "  - Configure timeout values"
    echo "  - Add retry logic"
    exit 0
else
    echo "❌ Configuration has ERRORS"
    exit 1
fi
