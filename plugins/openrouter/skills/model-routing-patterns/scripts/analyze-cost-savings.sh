#!/bin/bash

# analyze-cost-savings.sh
# Analyzes potential cost savings from routing strategies
# Compares routing configurations and projects monthly costs

set -e

CONFIG_FILE="$1"
BASELINE_FILE="$2"
MONTHLY_REQUESTS="${3:-100000}"

show_usage() {
    echo "Usage: $0 <routing-config.json> [baseline-config.json] [monthly-requests]"
    echo ""
    echo "Analyzes cost savings from routing strategies"
    echo ""
    echo "Arguments:"
    echo "  routing-config.json  - Your routing configuration"
    echo "  baseline-config.json - Optional baseline for comparison (default: gpt-4o only)"
    echo "  monthly-requests     - Estimated monthly requests (default: 100,000)"
    echo ""
    echo "Examples:"
    echo "  $0 my-routing.json"
    echo "  $0 cost-optimized.json baseline.json 500000"
    exit 1
}

if [ -z "$CONFIG_FILE" ]; then
    show_usage
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "Cost Analysis for Routing Configuration"
echo "================================================"
echo ""
echo "Configuration: $CONFIG_FILE"
echo "Monthly Requests: $(printf "%'d" $MONTHLY_REQUESTS)"
echo ""

# Model pricing (per 1M tokens, approximate)
declare -A MODEL_COSTS=(
    # Free models
    ["google/gemma-2-9b-it:free"]=0.0
    ["meta-llama/llama-3.2-3b-instruct:free"]=0.0
    ["meta-llama/llama-3.2-1b-instruct:free"]=0.0
    ["microsoft/phi-3-mini-128k-instruct:free"]=0.0

    # Budget models
    ["anthropic/claude-4.5-sonnet"]=0.25
    ["openai/gpt-4o-mini"]=0.15
    ["google/gemini-flash-1.5"]=0.075

    # Mid-tier models
    ["openai/gpt-4o"]=5.0
    ["anthropic/claude-4.5-sonnet"]=3.0
    ["google/gemini-pro-1.5"]=3.5

    # Premium models
    ["openai/gpt-4"]=30.0
    ["anthropic/claude-4.5-sonnet"]=15.0
)

# Default baseline (GPT-4o only)
BASELINE_MODEL="openai/gpt-4o"
BASELINE_COST=5.0

if [ -n "$BASELINE_FILE" ] && [ -f "$BASELINE_FILE" ]; then
    echo "Baseline: $BASELINE_FILE"
    BASELINE_MODEL=$(jq -r '.primary // .model // "openai/gpt-4o"' "$BASELINE_FILE")
    BASELINE_COST=${MODEL_COSTS[$BASELINE_MODEL]:-5.0}
else
    echo "Baseline: GPT-4o only (no routing)"
fi
echo ""

# Extract routing configuration
STRATEGY=$(jq -r '.strategy // "unknown"' "$CONFIG_FILE")
PRIMARY_MODEL=$(jq -r '.primary // .model // empty' "$CONFIG_FILE")

echo "Strategy: $STRATEGY"
echo "Primary Model: $PRIMARY_MODEL"
echo ""

# Estimate distribution based on strategy
calculate_distribution() {
    local strategy="$1"

    case "$strategy" in
        cost-optimized)
            # 70% free, 20% budget, 10% premium
            FREE_PCT=70
            BUDGET_PCT=20
            PREMIUM_PCT=10
            ;;
        speed-optimized)
            # 80% budget, 20% premium
            FREE_PCT=0
            BUDGET_PCT=80
            PREMIUM_PCT=20
            ;;
        quality-optimized)
            # 90% premium, 10% fallback
            FREE_PCT=0
            BUDGET_PCT=10
            PREMIUM_PCT=90
            ;;
        balanced)
            # 30% free, 50% budget, 20% premium
            FREE_PCT=30
            BUDGET_PCT=50
            PREMIUM_PCT=20
            ;;
        *)
            # Conservative estimate: 20% free, 50% budget, 30% premium
            FREE_PCT=20
            BUDGET_PCT=50
            PREMIUM_PCT=30
            ;;
    esac

    echo "$FREE_PCT:$BUDGET_PCT:$PREMIUM_PCT"
}

DISTRIBUTION=$(calculate_distribution "$STRATEGY")
FREE_PCT=$(echo "$DISTRIBUTION" | cut -d: -f1)
BUDGET_PCT=$(echo "$DISTRIBUTION" | cut -d: -f2)
PREMIUM_PCT=$(echo "$DISTRIBUTION" | cut -d: -f3)

echo "Estimated Request Distribution:"
echo "  Free models:    $FREE_PCT%"
echo "  Budget models:  $BUDGET_PCT%"
echo "  Premium models: $PREMIUM_PCT%"
echo ""

# Calculate costs (assuming average 1000 tokens per request)
TOKENS_PER_REQUEST=1000
TOTAL_TOKENS=$((MONTHLY_REQUESTS * TOKENS_PER_REQUEST))
TOTAL_TOKENS_M=$(echo "scale=2; $TOTAL_TOKENS / 1000000" | bc)

# Routing strategy cost
FREE_REQUESTS=$((MONTHLY_REQUESTS * FREE_PCT / 100))
BUDGET_REQUESTS=$((MONTHLY_REQUESTS * BUDGET_PCT / 100))
PREMIUM_REQUESTS=$((MONTHLY_REQUESTS * PREMIUM_PCT / 100))

# Costs by tier (using representative models)
FREE_COST=0.0
BUDGET_COST_PER_M=0.25  # Claude Haiku
PREMIUM_COST_PER_M=3.0  # Claude Sonnet

BUDGET_TOKENS_M=$(echo "scale=2; $BUDGET_REQUESTS * $TOKENS_PER_REQUEST / 1000000" | bc)
PREMIUM_TOKENS_M=$(echo "scale=2; $PREMIUM_REQUESTS * $TOKENS_PER_REQUEST / 1000000" | bc)

ROUTING_BUDGET_COST=$(echo "scale=2; $BUDGET_TOKENS_M * $BUDGET_COST_PER_M" | bc)
ROUTING_PREMIUM_COST=$(echo "scale=2; $PREMIUM_TOKENS_M * $PREMIUM_COST_PER_M" | bc)
ROUTING_TOTAL_COST=$(echo "scale=2; $ROUTING_BUDGET_COST + $ROUTING_PREMIUM_COST" | bc)

# Baseline cost
BASELINE_TOTAL_COST=$(echo "scale=2; $TOTAL_TOKENS_M * $BASELINE_COST" | bc)

echo "Cost Breakdown"
echo "================================================"
echo ""
echo "Baseline ($BASELINE_MODEL only):"
echo "  Total tokens: ${TOTAL_TOKENS_M}M"
echo "  Cost per 1M:  \$${BASELINE_COST}"
echo "  Total cost:   \$${BASELINE_TOTAL_COST}"
echo ""
echo "With Routing ($STRATEGY):"
echo "  Free tier:    $FREE_REQUESTS requests × \$0.00 = \$0.00"
echo "  Budget tier:  $BUDGET_REQUESTS requests × \$${BUDGET_COST_PER_M}/1M = \$${ROUTING_BUDGET_COST}"
echo "  Premium tier: $PREMIUM_REQUESTS requests × \$${PREMIUM_COST_PER_M}/1M = \$${ROUTING_PREMIUM_COST}"
echo "  ---------------------------------------------"
echo "  Total cost:   \$${ROUTING_TOTAL_COST}"
echo ""

# Calculate savings
SAVINGS=$(echo "scale=2; $BASELINE_TOTAL_COST - $ROUTING_TOTAL_COST" | bc)
SAVINGS_PCT=$(echo "scale=1; ($SAVINGS / $BASELINE_TOTAL_COST) * 100" | bc)

echo "Cost Savings"
echo "================================================"
echo ""
if (( $(echo "$SAVINGS > 0" | bc -l) )); then
    echo "✅ Monthly savings: \$${SAVINGS} (${SAVINGS_PCT}%)"
    echo "   Annual savings:  \$$(echo "scale=2; $SAVINGS * 12" | bc)"
else
    EXTRA=$(echo "scale=2; $ROUTING_TOTAL_COST - $BASELINE_TOTAL_COST" | bc)
    echo "⚠️  Additional cost: \$${EXTRA}"
    echo "   (Higher quality/speed may justify additional cost)"
fi
echo ""

# ROI calculation
echo "Return on Investment"
echo "================================================"
echo ""
echo "Assumptions:"
echo "  - Average ${TOKENS_PER_REQUEST} tokens per request"
echo "  - ${MONTHLY_REQUESTS} monthly requests"
echo "  - Distribution: ${FREE_PCT}% free, ${BUDGET_PCT}% budget, ${PREMIUM_PCT}% premium"
echo ""

# Additional metrics
echo "Additional Metrics"
echo "================================================"
echo ""

# Cost per request
BASELINE_PER_REQUEST=$(echo "scale=4; $BASELINE_TOTAL_COST / $MONTHLY_REQUESTS" | bc)
ROUTING_PER_REQUEST=$(echo "scale=4; $ROUTING_TOTAL_COST / $MONTHLY_REQUESTS" | bc)

echo "Cost per request:"
echo "  Baseline: \$${BASELINE_PER_REQUEST}"
echo "  Routing:  \$${ROUTING_PER_REQUEST}"
echo ""

# Break-even analysis
if (( $(echo "$SAVINGS > 0" | bc -l) )); then
    # Assuming $500 setup cost
    SETUP_COST=500
    BREAKEVEN_MONTHS=$(echo "scale=1; $SETUP_COST / $SAVINGS" | bc)
    echo "Break-even analysis:"
    echo "  Setup cost:       \$${SETUP_COST}"
    echo "  Monthly savings:  \$${SAVINGS}"
    echo "  Break-even:       ${BREAKEVEN_MONTHS} months"
    echo ""
fi

# Recommendations
echo "Recommendations"
echo "================================================"
echo ""

if [ "$STRATEGY" = "cost-optimized" ]; then
    echo "✅ Cost-optimized strategy selected"
    echo "   - Maximizes use of free models"
    echo "   - Consider A/B testing quality vs baseline"
    echo "   - Monitor user satisfaction metrics"
elif [ "$STRATEGY" = "quality-optimized" ]; then
    echo "✅ Quality-optimized strategy selected"
    echo "   - Highest quality responses"
    echo "   - Higher costs justified for critical use cases"
    echo "   - Consider balanced strategy for non-critical tasks"
elif [ "$STRATEGY" = "balanced" ]; then
    echo "✅ Balanced strategy selected"
    echo "   - Good cost/quality tradeoff"
    echo "   - Dynamic routing based on complexity"
    echo "   - Monitor distribution to optimize further"
else
    echo "💡 Strategy: $STRATEGY"
    echo "   - Review distribution assumptions"
    echo "   - Monitor actual usage patterns"
    echo "   - Adjust routing rules based on data"
fi

echo ""
echo "Next Steps:"
echo "  1. Deploy routing configuration"
echo "  2. Monitor actual request distribution"
echo "  3. Track real costs vs projections"
echo "  4. Adjust routing rules based on data"
echo "  5. Re-run analysis monthly"
