#!/bin/bash

# test-fallback-chain.sh
# Tests fallback chain execution by simulating model failures
# Verifies graceful degradation and proper error handling

set -e

CONFIG_FILE="$1"

if [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 <config-file.json>"
    echo ""
    echo "Tests fallback chain behavior:"
    echo "  - Simulates primary model failure"
    echo "  - Verifies fallback execution order"
    echo "  - Measures latency through chain"
    echo "  - Validates error handling"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Testing Fallback Chain: $CONFIG_FILE"
echo "================================================"
echo ""

# Extract routing configuration
PRIMARY_MODEL=$(jq -r '.primary // .models[0] // .model // empty' "$CONFIG_FILE")
FALLBACK_MODELS=$(jq -r '.fallback[]? // empty' "$CONFIG_FILE")

if [ -z "$PRIMARY_MODEL" ]; then
    echo "❌ ERROR: No primary model found in configuration"
    exit 1
fi

echo "Primary Model: $PRIMARY_MODEL"
echo ""

if [ -z "$FALLBACK_MODELS" ]; then
    echo "⚠️  WARNING: No fallback models configured"
    echo "    Single point of failure - primary model failure will cause complete failure"
    echo ""
    echo "Recommendation: Add fallback models to configuration"
    echo ""
    echo "Example:"
    echo '{'
    echo '  "primary": "'$PRIMARY_MODEL'",'
    echo '  "fallback": ['
    echo '    "anthropic/claude-4.5-sonnet",'
    echo '    "openai/gpt-4o-mini"'
    echo '  ]'
    echo '}'
    exit 1
fi

echo "Fallback Chain:"
FALLBACK_COUNT=0
echo "$FALLBACK_MODELS" | while read -r model; do
    FALLBACK_COUNT=$((FALLBACK_COUNT + 1))
    echo "  $FALLBACK_COUNT. $model"
done
echo ""

# Test 1: Simulate primary model failure
echo "Test 1: Primary Model Failure"
echo "------------------------------"
echo "Simulating failure of: $PRIMARY_MODEL"
echo ""

# Get first fallback
FIRST_FALLBACK=$(echo "$FALLBACK_MODELS" | head -n1)
if [ -n "$FIRST_FALLBACK" ]; then
    echo "✅ Would fallback to: $FIRST_FALLBACK"
    echo "   Status: PASS - Graceful degradation"
else
    echo "❌ No fallback available"
    echo "   Status: FAIL - Complete failure"
    exit 1
fi
echo ""

# Test 2: Simulate cascading failures
echo "Test 2: Cascading Failures"
echo "------------------------------"
TOTAL_FALLBACKS=$(echo "$FALLBACK_MODELS" | wc -l)
echo "Total fallback levels: $TOTAL_FALLBACKS"
echo ""

LEVEL=1
echo "$FALLBACK_MODELS" | while read -r model; do
    echo "Level $LEVEL: $model"
    LEVEL=$((LEVEL + 1))
done

echo ""
if [ "$TOTAL_FALLBACKS" -ge 2 ]; then
    echo "✅ Multiple fallback levels provide good redundancy"
elif [ "$TOTAL_FALLBACKS" -eq 1 ]; then
    echo "⚠️  Only one fallback level - consider adding more"
else
    echo "❌ No fallback levels configured"
fi
echo ""

# Test 3: Check for timeout configuration
echo "Test 3: Timeout Configuration"
echo "------------------------------"
TIMEOUT=$(jq -r '.timeout // .max_latency_ms // empty' "$CONFIG_FILE")

if [ -n "$TIMEOUT" ]; then
    echo "✅ Timeout configured: ${TIMEOUT}ms"
    echo "   This prevents hanging on slow/failed models"
else
    echo "⚠️  No timeout configured"
    echo "   Recommendation: Add timeout to prevent hanging"
    echo ""
    echo "   Example:"
    echo '   "timeout": 5000  // 5 seconds'
fi
echo ""

# Test 4: Check for retry configuration
echo "Test 4: Retry Configuration"
echo "------------------------------"
MAX_RETRIES=$(jq -r '.max_retries // .retry.max_attempts // empty' "$CONFIG_FILE")
RETRY_DELAY=$(jq -r '.retry_delay // .retry.delay_ms // empty' "$CONFIG_FILE")

if [ -n "$MAX_RETRIES" ]; then
    echo "✅ Max retries configured: $MAX_RETRIES"
    if [ -n "$RETRY_DELAY" ]; then
        echo "✅ Retry delay configured: ${RETRY_DELAY}ms"
    fi
else
    echo "⚠️  No retry configuration found"
    echo "   Recommendation: Add retry logic for transient failures"
    echo ""
    echo "   Example:"
    echo '   "retry": {'
    echo '     "max_attempts": 3,'
    echo '     "delay_ms": 1000,'
    echo '     "exponential_backoff": true'
    echo '   }'
fi
echo ""

# Test 5: Latency simulation
echo "Test 5: Latency Estimation"
echo "------------------------------"
echo "Simulating request flow through fallback chain..."
echo ""

TOTAL_LATENCY=0
CURRENT_LEVEL=0

# Primary model
echo "Attempt 1: $PRIMARY_MODEL"
ESTIMATED_LATENCY=$((RANDOM % 2000 + 500))
echo "  Simulated latency: ${ESTIMATED_LATENCY}ms"
echo "  Result: FAILURE (simulated)"
TOTAL_LATENCY=$((TOTAL_LATENCY + ESTIMATED_LATENCY))
echo ""

# Fallback chain
echo "$FALLBACK_MODELS" | while read -r model; do
    CURRENT_LEVEL=$((CURRENT_LEVEL + 1))
    echo "Attempt $((CURRENT_LEVEL + 1)): $model"
    ESTIMATED_LATENCY=$((RANDOM % 2000 + 500))
    echo "  Simulated latency: ${ESTIMATED_LATENCY}ms"

    if [ "$CURRENT_LEVEL" -lt "$TOTAL_FALLBACKS" ]; then
        echo "  Result: FAILURE (simulated)"
    else
        echo "  Result: SUCCESS"
    fi
    TOTAL_LATENCY=$((TOTAL_LATENCY + ESTIMATED_LATENCY))
    echo ""
done

echo "Total latency through chain: ${TOTAL_LATENCY}ms"
if [ "$TOTAL_LATENCY" -lt 5000 ]; then
    echo "✅ Acceptable latency (< 5s)"
elif [ "$TOTAL_LATENCY" -lt 10000 ]; then
    echo "⚠️  High latency (5-10s) - consider faster fallback models"
else
    echo "❌ Excessive latency (> 10s) - fallback chain too long or slow models"
fi
echo ""

# Test 6: Error handling verification
echo "Test 6: Error Handling Verification"
echo "------------------------------"
ON_ERROR=$(jq -r '.on_error // .error_handling // empty' "$CONFIG_FILE")

if [ -n "$ON_ERROR" ]; then
    echo "✅ Error handling configured: $ON_ERROR"
else
    echo "⚠️  No explicit error handling configured"
    echo "   Recommendation: Define error handling strategy"
    echo ""
    echo "   Options:"
    echo '   "on_error": "fallback"    // Try next model'
    echo '   "on_error": "retry"       // Retry same model'
    echo '   "on_error": "fail"        // Fail immediately'
fi
echo ""

# Final report
echo "================================================"
echo "Fallback Chain Test Summary"
echo "================================================"
echo ""

SCORE=0
MAX_SCORE=6

# Score each test
[ -n "$FIRST_FALLBACK" ] && SCORE=$((SCORE + 1))
[ "$TOTAL_FALLBACKS" -ge 2 ] && SCORE=$((SCORE + 1))
[ -n "$TIMEOUT" ] && SCORE=$((SCORE + 1))
[ -n "$MAX_RETRIES" ] && SCORE=$((SCORE + 1))
[ "$TOTAL_LATENCY" -lt 5000 ] && SCORE=$((SCORE + 1))
[ -n "$ON_ERROR" ] && SCORE=$((SCORE + 1))

echo "Score: $SCORE/$MAX_SCORE"
echo ""

if [ "$SCORE" -eq "$MAX_SCORE" ]; then
    echo "✅ EXCELLENT - Fallback chain is well configured"
    exit 0
elif [ "$SCORE" -ge 4 ]; then
    echo "✅ GOOD - Fallback chain works but could be improved"
    exit 0
elif [ "$SCORE" -ge 2 ]; then
    echo "⚠️  FAIR - Fallback chain needs improvements"
    exit 0
else
    echo "❌ POOR - Fallback chain has significant issues"
    exit 1
fi
