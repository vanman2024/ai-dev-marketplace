#!/bin/bash
# Analyze memory retention patterns and suggest cleanup actions
# Usage: ./analyze-retention.sh <user_id_or_agent_id>

set -e

IDENTIFIER="${1}"

if [ -z "$IDENTIFIER" ]; then
    echo "Usage: $0 <user_id_or_agent_id>"
    echo ""
    echo "Examples:"
    echo "  $0 user123        # Analyze user memories"
    echo "  $0 agent_support  # Analyze agent memories"
    exit 1
fi

# Check if required tools are available
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. Install with: sudo apt-get install jq"; exit 1; }

echo "Analyzing retention patterns for: $IDENTIFIER"
echo "================================================"
echo ""

# Simulated memory data (in production, this would query Mem0 API)
# For demonstration, we'll create a sample analysis

CURRENT_DATE=$(date +%s)
THIRTY_DAYS_AGO=$((CURRENT_DATE - 2592000))
NINETY_DAYS_AGO=$((CURRENT_DATE - 7776000))

# Create temporary analysis file
ANALYSIS_FILE="/tmp/mem0_retention_analysis_${IDENTIFIER}_$(date +%s).json"

cat > "$ANALYSIS_FILE" <<EOF
{
  "identifier": "${IDENTIFIER}",
  "analysis_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "memory_counts": {
    "total": 150,
    "last_7_days": 25,
    "last_30_days": 60,
    "last_90_days": 110,
    "older_than_90_days": 40
  },
  "access_patterns": {
    "frequently_accessed": 45,
    "occasionally_accessed": 65,
    "never_accessed": 40
  },
  "storage_metrics": {
    "total_size_mb": 12.5,
    "avg_memory_size_kb": 85,
    "estimated_monthly_cost_usd": 0.75
  },
  "quality_metrics": {
    "avg_relevance_score": 0.68,
    "low_quality_count": 30,
    "duplicate_candidates": 8
  }
}
EOF

# Display analysis results
echo "Memory Statistics:"
echo "-------------------"
jq -r '.memory_counts | to_entries | .[] | "  \(.key | gsub("_"; " ") | ascii_upcase): \(.value)"' "$ANALYSIS_FILE"
echo ""

echo "Access Patterns:"
echo "-------------------"
jq -r '.access_patterns | to_entries | .[] | "  \(.key | gsub("_"; " ") | ascii_upcase): \(.value)"' "$ANALYSIS_FILE"
echo ""

echo "Storage Metrics:"
echo "-------------------"
jq -r '.storage_metrics | to_entries | .[] | "  \(.key | gsub("_"; " ") | ascii_upcase): \(.value)"' "$ANALYSIS_FILE"
echo ""

echo "Quality Metrics:"
echo "-------------------"
jq -r '.quality_metrics | to_entries | .[] | "  \(.key | gsub("_"; " ") | ascii_upcase): \(.value)"' "$ANALYSIS_FILE"
echo ""

# Generate recommendations
echo "Recommendations:"
echo "-------------------"

NEVER_ACCESSED=$(jq -r '.access_patterns.never_accessed' "$ANALYSIS_FILE")
OLDER_THAN_90=$(jq -r '.memory_counts.older_than_90_days' "$ANALYSIS_FILE")
LOW_QUALITY=$(jq -r '.quality_metrics.low_quality_count' "$ANALYSIS_FILE")
DUPLICATES=$(jq -r '.quality_metrics.duplicate_candidates' "$ANALYSIS_FILE")

if [ "$NEVER_ACCESSED" -gt 20 ]; then
    echo "  ⚠️  $NEVER_ACCESSED never-accessed memories found"
    echo "     Action: Consider archiving or deleting never-accessed memories > 90 days"
    echo "     Command: mem0 delete --filter 'accessed=never AND age>90d'"
    echo ""
fi

if [ "$OLDER_THAN_90" -gt 30 ]; then
    echo "  📦 $OLDER_THAN_90 memories older than 90 days"
    echo "     Action: Archive to cold storage for cost savings"
    echo "     Estimated savings: \$$(echo "scale=2; $OLDER_THAN_90 * 0.005" | bc)/month"
    echo ""
fi

if [ "$LOW_QUALITY" -gt 20 ]; then
    echo "  📉 $LOW_QUALITY low-quality memories (relevance < 0.5)"
    echo "     Action: Review and prune low-relevance memories"
    echo "     Command: mem0 delete --filter 'score<0.5 AND age>30d'"
    echo ""
fi

if [ "$DUPLICATES" -gt 0 ]; then
    echo "  🔄 $DUPLICATES potential duplicate memories"
    echo "     Action: Run deduplication script"
    echo "     Command: ./deduplicate-memories.sh $IDENTIFIER"
    echo ""
fi

# Calculate potential savings
TOTAL_MEMORIES=$(jq -r '.memory_counts.total' "$ANALYSIS_FILE")
CLEANUP_CANDIDATES=$((NEVER_ACCESSED + LOW_QUALITY + DUPLICATES))
SAVINGS_PERCENT=$((CLEANUP_CANDIDATES * 100 / TOTAL_MEMORIES))

echo "Cleanup Summary:"
echo "-------------------"
echo "  Total Memories: $TOTAL_MEMORIES"
echo "  Cleanup Candidates: $CLEANUP_CANDIDATES"
echo "  Potential Reduction: $SAVINGS_PERCENT%"
echo "  Estimated Cost Savings: \$$(echo "scale=2; $CLEANUP_CANDIDATES * 0.005" | bc)/month"
echo ""

# Create retention action plan
ACTION_PLAN="/tmp/mem0_action_plan_${IDENTIFIER}_$(date +%Y%m%d).txt"

cat > "$ACTION_PLAN" <<EOF
Memory Retention Action Plan
Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
Identifier: ${IDENTIFIER}
====================================

IMMEDIATE ACTIONS:
1. Archive $OLDER_THAN_90 memories older than 90 days
2. Delete $NEVER_ACCESSED never-accessed memories
3. Deduplicate $DUPLICATES duplicate memories

WEEKLY ACTIONS:
1. Review low-quality memories (score < 0.5)
2. Monitor access patterns
3. Update retention policies

MONTHLY ACTIONS:
1. Full retention audit
2. Cost optimization review
3. Policy adjustment based on usage

CLEANUP COMMANDS:
# Archive old memories
mem0 archive --filter 'age>90d' --identifier '$IDENTIFIER'

# Delete never-accessed low-quality
mem0 delete --filter 'accessed=never AND score<0.5 AND age>60d' --identifier '$IDENTIFIER'

# Deduplicate
./deduplicate-memories.sh $IDENTIFIER

MONITORING:
- Set up alerts for memory growth > 200 memories
- Track monthly costs
- Review access patterns quarterly

EOF

echo "Action plan saved to: $ACTION_PLAN"
echo ""
echo "Analysis complete!"
echo "Full report: $ANALYSIS_FILE"

# Cleanup
# Uncomment in production to remove temp files
# rm -f "$ANALYSIS_FILE"
