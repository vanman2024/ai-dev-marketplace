#!/bin/bash
# Analyzes OpenRouter API usage and costs

set -e

DATE_RANGE="${1:-30}"
API_KEY="${2:-$OPENROUTER_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "❌ Error: No API key provided"
    echo "Usage: $0 [days] [api-key]"
    echo "Set OPENROUTER_API_KEY or provide as argument"
    exit 1
fi

echo "🔍 Analyzing OpenRouter Usage"
echo "Date range: Last $DATE_RANGE days"
echo ""

# Note: This is a placeholder implementation
# OpenRouter's actual usage API endpoint may differ
echo "1. Fetching usage data..."

# Try to get key information first
RESPONSE=$(curl -s -w "\n%{http_code}" https://openrouter.ai/api/v1/auth/key \
    -H "Authorization: Bearer $API_KEY" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "   ❌ Failed to fetch usage data (HTTP $HTTP_CODE)"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "   ⚠️  jq not installed - cannot parse response"
    exit 1
fi

echo "   ✅ Data fetched successfully"
echo ""

echo "2. API Key Usage Summary"
echo "$BODY" | jq -r '
    if .data then
        "   Label: \(.data.label // "N/A")",
        "   Total Usage: \(.data.usage // 0) requests",
        "   Rate Limit: \(.data.rate_limit.requests // "N/A") req/min",
        "   Limit: \(.data.limit // "unlimited") requests"
    else
        "   (Detailed usage information not available)"
    end
'

echo ""
echo "3. Cost Estimation Guidelines"
cat << 'EOF'
   To track actual costs, you need to:

   1. Enable monitoring in your requests:
      - Set X-Title header (OPENROUTER_APP_TITLE)
      - Set HTTP-Referer header (OPENROUTER_SITE_URL)

   2. View usage on OpenRouter dashboard:
      - Visit: https://openrouter.ai/settings/usage
      - Filter by application name
      - Export usage data for analysis

   3. Calculate costs:
      - Prompt tokens × model prompt price
      - Completion tokens × model completion price
      - Sum across all requests
EOF

echo ""
echo "4. Cost Optimization Tips"
cat << 'EOF'
   💡 Reduce costs by:

   - Use smaller models for simple tasks
   - Implement caching for repeated queries
   - Set max_tokens limits on responses
   - Use provider preferences for cheaper providers
   - Monitor and analyze actual usage patterns
   - Implement fallback chains (cheaper → expensive)
EOF

echo ""
echo "5. Budget Alert Recommendation"
cat << 'EOF'
   Set up budget alerts:

   1. Configure monitoring (see template: monitoring-config.json)
   2. Set budget thresholds in OpenRouter dashboard
   3. Monitor usage trends regularly
   4. Implement cost tracking in your application
EOF

echo ""
echo "✅ Usage analysis complete"
echo ""
echo "📊 For detailed usage data:"
echo "   Visit: https://openrouter.ai/settings/usage"
