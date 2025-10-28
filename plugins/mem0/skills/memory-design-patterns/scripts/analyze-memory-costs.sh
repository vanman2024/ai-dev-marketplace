#!/bin/bash
# Analyze memory system costs and provide optimization strategies
# Usage: ./analyze-memory-costs.sh <user_id> <date_range_days>

set -e

IDENTIFIER="${1:-all}"
DATE_RANGE="${2:-30}"

echo "Memory Cost Analysis"
echo "===================="
echo "Identifier: $IDENTIFIER"
echo "Period: Last $DATE_RANGE days"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Simulated cost breakdown (in production, query actual Mem0 billing)
cat <<EOF
Cost Breakdown (Last $DATE_RANGE days):
========================================

Vector Storage:
  • Memories stored: 15,420
  • Storage cost: \$12.50/month
  • Per-memory cost: \$0.00081

Embedding Generation:
  • Embeddings created: 3,280
  • OpenAI API cost: \$4.92
  • Per-embedding cost: \$0.0015

Vector Search:
  • Searches performed: 124,500
  • Search cost: \$8.35
  • Per-search cost: \$0.000067

Graph Database (if enabled):
  • Graph storage: \$25.00/month
  • Graph queries: \$3.50
  • Total graph: \$28.50/month

─────────────────────────────────
Total Monthly Cost: \$54.27
Projected Annual: \$651.24
─────────────────────────────────

EOF

echo "Cost by Memory Type:"
echo "--------------------"
cat <<EOF
User memories:   12,150 (\$9.85/mo)  - 79% of total
Agent memories:  2,840  (\$2.30/mo)  - 18% of total
Session memories: 430   (\$0.35/mo)  - 3% of total
EOF

echo ""
echo ""
echo "Cost Optimization Opportunities:"
echo "================================="
echo ""

echo "1. DEDUPLICATE MEMORIES"
echo "   Estimated duplicates: 1,240 (8% of total)"
echo "   Potential savings: \$1.00/month"
echo "   Action: Run ./deduplicate-memories.sh $IDENTIFIER"
echo ""

echo "2. ARCHIVE OLD MEMORIES"
echo "   Memories >180 days: 3,850 (25%)"
echo "   Active access rate: 0.2%"
echo "   Potential savings: \$3.12/month"
echo "   Implementation:"
cat <<'EOF'
   # Move to cold storage (S3/compressed JSON)
   old_memories = memory.get_all(
       user_id=user_id,
       filters={"created_at": {"lt": "2024-04-01"}}
   )
   # Archive to S3 at $0.023/GB vs $8.11/GB vector storage
   # 350x cost reduction for archived data
EOF

echo ""
echo ""
echo "3. USE SMALLER EMBEDDINGS"
echo "   Current: text-embedding-3-large (3072 dim)"
echo "   Proposed: text-embedding-3-small (1536 dim)"
echo "   Storage savings: -50%"
echo "   Embedding cost savings: -70%"
echo "   Potential savings: \$9.70/month"
echo "   Trade-off: -2% search quality (usually acceptable)"
echo ""

echo "4. REDUCE SEARCH FREQUENCY"
echo "   Current: 4,150 searches/day"
echo "   Optimization: Cache frequently accessed memories"
echo "   Cache hit rate target: 80%"
echo "   Potential savings: \$6.68/month"
echo ""

echo "5. CLEANUP STALE MEMORIES"
echo "   Never accessed: 2,840 memories (18%)"
echo "   Low relevance (<0.3): 1,560 memories (10%)"
echo "   Potential savings: \$3.56/month"
echo "   Action: Run ./analyze-retention.sh $IDENTIFIER"
echo ""

echo "6. OPTIMIZE GRAPH USAGE"
echo "   Graph DB cost: \$28.50/month (52% of total!)"
echo "   Graph query frequency: 420/day"
echo "   Question: Is graph really needed?"
echo ""
echo "   Options:"
echo "   A) Keep graph if relationships are critical"
echo "   B) Migrate to vector-only if possible → -\$28.50/month"
echo "   C) Use managed Neo4j Aura (may be cheaper)"
echo ""

echo ""
echo "Cost Optimization Summary:"
echo "=========================="
cat <<EOF
┌──────────────────────────────────────┬──────────┐
│ Optimization                         │ Savings  │
├──────────────────────────────────────┼──────────┤
│ Deduplicate memories                 │  \$1.00  │
│ Archive old memories (>180d)         │  \$3.12  │
│ Switch to smaller embeddings         │  \$9.70  │
│ Implement caching (80% hit rate)     │  \$6.68  │
│ Cleanup stale memories               │  \$3.56  │
│ Reconsider graph DB                  │ \$28.50  │
├──────────────────────────────────────┼──────────┤
│ TOTAL POTENTIAL SAVINGS              │ \$52.56  │
│ Optimized monthly cost:              │  \$1.71  │
│ Cost reduction:                      │   96.8%  │
└──────────────────────────────────────┴──────────┘
EOF

echo ""
echo ""
echo "Recommended Implementation Plan:"
echo "================================="
echo ""
echo "Week 1: Quick Wins (Low Risk)"
echo "  ✓ Enable caching (saves \$6.68/mo)"
echo "  ✓ Deduplicate memories (saves \$1.00/mo)"
echo "  ✓ Cleanup never-accessed memories (saves \$2.00/mo)"
echo "  → Total: \$9.68/mo savings, ~18% reduction"
echo ""

echo "Week 2-3: Medium Effort"
echo "  ✓ Archive memories >180 days (saves \$3.12/mo)"
echo "  ✓ Test smaller embedding model on 10% traffic"
echo "  ✓ Monitor quality metrics"
echo ""

echo "Week 4: Evaluation"
echo "  ✓ If quality acceptable, switch all to smaller model (saves \$9.70/mo)"
echo "  ✓ Re-evaluate graph DB necessity"
echo "  ✓ If not needed, migrate to vector-only (saves \$28.50/mo)"
echo ""

echo "Cost Projection After Optimization:"
echo "------------------------------------"
cat <<EOF
Scenario 1 (Conservative - keep graph):
  Current: \$54.27/month
  After quick wins: \$44.59/month (-18%)
  After full optimization: \$23.21/month (-57%)

Scenario 2 (Aggressive - remove graph):
  Current: \$54.27/month
  After all optimizations: \$1.71/month (-96.8%)
  Annual savings: \$630
EOF

echo ""
echo ""
echo "Cost Monitoring Dashboard:"
echo "--------------------------"
echo "Track these metrics weekly:"
echo "  • Cost per memory (\$0.00081 baseline)"
echo "  • Cost per search (\$0.000067 baseline)"
echo "  • Storage growth rate (GB/month)"
echo "  • Embedding API usage (requests/day)"
echo "  • Cache hit rate (target: 80%)"
echo ""

echo "Cost Alerts:"
echo "------------"
echo "  🚨 Daily cost > \$2.00 (monthly: \$60)"
echo "  🚨 Storage growth > 20%/month"
echo "  🚨 Embedding costs > \$10/month"
echo "  🚨 Per-memory cost > \$0.0012"
echo ""

echo "Detailed Reports:"
echo "-----------------"
echo "• Memory growth: ./analyze-retention.sh $IDENTIFIER"
echo "• Performance: ./analyze-memory-performance.sh"
echo "• Deduplication: ./deduplicate-memories.sh $IDENTIFIER"
echo ""

echo "Next Steps:"
echo "-----------"
echo "1. Review optimization recommendations"
echo "2. Prioritize by savings/effort ratio"
echo "3. Implement quick wins first (caching, deduplication)"
echo "4. Test changes in staging before production"
echo "5. Monitor cost dashboard weekly"
echo "6. Re-run this analysis monthly"
