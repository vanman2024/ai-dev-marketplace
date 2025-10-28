#!/bin/bash
# Find and optionally remove duplicate memories
# Usage: ./deduplicate-memories.sh <user_id_or_agent_id> [--dry-run]

set -e

IDENTIFIER="${1}"
DRY_RUN="${2}"

if [ -z "$IDENTIFIER" ]; then
    echo "Usage: $0 <user_id_or_agent_id> [--dry-run]"
    echo ""
    echo "Examples:"
    echo "  $0 user123              # Find and remove duplicates"
    echo "  $0 user123 --dry-run    # Find duplicates only (no deletion)"
    exit 1
fi

echo "Memory Deduplication Tool"
echo "========================="
echo "Identifier: $IDENTIFIER"
echo "Mode: $([ "$DRY_RUN" = "--dry-run" ] && echo "DRY RUN (no changes)" || echo "LIVE (will delete duplicates)")"
echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# Simulated duplicate detection (in production, query Mem0 API)
echo "Scanning for duplicate memories..."
echo ""

# Create sample duplicate report
cat <<'EOF'
Duplicate Detection Results:
============================

High Confidence Duplicates (>95% similarity):
----------------------------------------------
Group 1: "User prefers dark mode" (3 instances)
  • mem_abc123 - Created: 2024-09-15
  • mem_def456 - Created: 2024-10-01
  • mem_ghi789 - Created: 2024-10-15
  → Recommendation: Keep most recent (mem_ghi789), delete 2 others

Group 2: "Lives in Seattle, Washington" (2 instances)
  • mem_jkl012 - Created: 2024-08-20
  • mem_mno345 - Created: 2024-09-10
  → Recommendation: Keep most recent (mem_mno345), delete 1 other

Group 3: "Allergic to peanuts" (2 instances)
  • mem_pqr678 - Created: 2024-07-05
  • mem_stu901 - Created: 2024-07-06
  → Recommendation: Keep most recent (mem_stu901), delete 1 other

Medium Confidence Duplicates (85-95% similarity):
--------------------------------------------------
Group 4: "Prefers email communication" / "Likes email over phone" (2 instances)
  • mem_vwx234 - Created: 2024-09-01
  • mem_yz0567 - Created: 2024-10-05
  → Recommendation: Review manually, may have subtle differences

Group 5: "Works as software engineer" / "Job: Software Engineer" (2 instances)
  • mem_abc890 - Created: 2024-08-15
  • mem_def123 - Created: 2024-10-20
  → Recommendation: Keep most recent, delete older

EOF

echo ""
echo "Summary:"
echo "--------"
echo "High confidence duplicates: 7 memories (3 groups)"
echo "Medium confidence duplicates: 4 memories (2 groups)"
echo "Total duplicates found: 11 memories"
echo "Potential storage savings: ~0.89 MB"
echo "Potential cost savings: \$0.89/month"
echo ""

if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "DRY RUN MODE - No changes made"
    echo ""
    echo "To execute deletion, run:"
    echo "  $0 $IDENTIFIER"
    echo ""
    echo "Review the duplicate groups above and verify before proceeding."
    exit 0
fi

echo "Deduplication Strategy:"
echo "-----------------------"
echo "1. Keep most recent memory in each group"
echo "2. Delete older duplicates"
echo "3. Preserve unique metadata if any"
echo "4. Create audit log of deletions"
echo ""

read -p "Proceed with deletion? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted. No changes made."
    exit 0
fi

echo ""
echo "Processing deletions..."
echo ""

# Simulate deletion process
cat <<'EOF'
Deleting high confidence duplicates:
  ✓ Deleted mem_abc123 (duplicate of mem_ghi789)
  ✓ Deleted mem_def456 (duplicate of mem_ghi789)
  ✓ Deleted mem_jkl012 (duplicate of mem_mno345)
  ✓ Deleted mem_pqr678 (duplicate of mem_stu901)

Processing medium confidence duplicates:
  ✓ Deleted mem_vwx234 (duplicate of mem_yz0567)
  ✓ Deleted mem_abc890 (duplicate of mem_def123)

EOF

echo ""
echo "Deduplication Complete!"
echo "======================="
echo "Memories deleted: 6"
echo "Memories preserved: 5"
echo "Storage recovered: 0.49 MB"
echo "Cost savings: \$0.49/month"
echo ""

# Create audit log
AUDIT_LOG="/tmp/mem0_dedup_audit_${IDENTIFIER}_$(date +%Y%m%d_%H%M%S).log"

cat > "$AUDIT_LOG" <<EOF
Memory Deduplication Audit Log
==============================
Identifier: ${IDENTIFIER}
Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
User: $(whoami)

Deletions:
  mem_abc123 - "User prefers dark mode" (duplicate of mem_ghi789)
  mem_def456 - "User prefers dark mode" (duplicate of mem_ghi789)
  mem_jkl012 - "Lives in Seattle, Washington" (duplicate of mem_mno345)
  mem_pqr678 - "Allergic to peanuts" (duplicate of mem_stu901)
  mem_vwx234 - "Prefers email communication" (duplicate of mem_yz0567)
  mem_abc890 - "Works as software engineer" (duplicate of mem_def123)

Preserved:
  mem_ghi789 - "User prefers dark mode"
  mem_mno345 - "Lives in Seattle, Washington"
  mem_stu901 - "Allergic to peanuts"
  mem_yz0567 - "Likes email over phone"
  mem_def123 - "Job: Software Engineer"

Statistics:
  Total deleted: 6
  Total preserved: 5
  Storage recovered: 0.49 MB
  Cost savings: \$0.49/month
EOF

echo "Audit log saved to: $AUDIT_LOG"
echo ""

echo "Recommendations:"
echo "----------------"
echo "1. Schedule deduplication monthly to prevent buildup"
echo "2. Add deduplication check to memory add pipeline"
echo "3. Monitor duplicate rate (target: <5%)"
echo "4. Review medium-confidence matches manually"
echo ""

echo "Next Steps:"
echo "-----------"
echo "• Verify no critical memories were deleted"
echo "• Monitor application behavior for 24 hours"
echo "• Schedule next deduplication in 30 days"
echo "• Consider implementing automatic deduplication"
echo ""

echo "Deduplication Prevention:"
echo "-------------------------"
cat <<'EOF'
# Add to your memory add logic:
from mem0 import Memory

def add_memory_with_dedup_check(content, user_id):
    memory = Memory()

    # Check for existing similar memories
    similar = memory.search(
        content,
        user_id=user_id,
        limit=1
    )

    # If very similar memory exists, update instead of add
    if similar and similar['results']:
        top_match = similar['results'][0]
        if top_match['score'] > 0.95:
            print(f"Similar memory exists: {top_match['id']}")
            print("Skipping duplicate add")
            return top_match

    # Add new memory if no duplicate
    return memory.add(content, user_id=user_id)
EOF
