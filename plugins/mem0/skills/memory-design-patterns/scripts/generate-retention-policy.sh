#!/bin/bash
# Generate retention policy configuration for Mem0 memory systems
# Usage: ./generate-retention-policy.sh <memory-type> <retention-days>

set -e

MEMORY_TYPE="${1}"
RETENTION_DAYS="${2}"

if [ -z "$MEMORY_TYPE" ] || [ -z "$RETENTION_DAYS" ]; then
    echo "Usage: $0 <memory-type> <retention-days>"
    echo ""
    echo "Memory Types:"
    echo "  user    - User-level memories (persistent preferences)"
    echo "  agent   - Agent-level memories (agent capabilities)"
    echo "  session - Session-level memories (temporary context)"
    echo ""
    echo "Examples:"
    echo "  $0 user 365      # User memories kept for 1 year"
    echo "  $0 agent 90      # Agent memories kept for 90 days"
    echo "  $0 session 1     # Session memories kept for 1 day"
    exit 1
fi

# Validate memory type
case "$MEMORY_TYPE" in
    user|agent|session)
        ;;
    *)
        echo "Error: Invalid memory type. Must be one of: user, agent, session"
        exit 1
        ;;
esac

# Validate retention days
if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
    echo "Error: Retention days must be a positive integer"
    exit 1
fi

# Set recommended values based on memory type
case "$MEMORY_TYPE" in
    user)
        if [ "$RETENTION_DAYS" -lt 365 ]; then
            echo "Warning: User memories typically retained indefinitely or at least 365 days"
            echo "You specified $RETENTION_DAYS days. Continue? (y/n)"
            read -r response
            if [ "$response" != "y" ]; then
                exit 0
            fi
        fi
        CLEANUP_STRATEGY="user_initiated"
        ARCHIVAL_DAYS=$((RETENTION_DAYS * 2))
        ;;
    agent)
        if [ "$RETENTION_DAYS" -lt 30 ] || [ "$RETENTION_DAYS" -gt 180 ]; then
            echo "Warning: Agent memories typically retained for 30-180 days"
            echo "You specified $RETENTION_DAYS days. Continue? (y/n)"
            read -r response
            if [ "$response" != "y" ]; then
                exit 0
            fi
        fi
        CLEANUP_STRATEGY="automatic_score_based"
        ARCHIVAL_DAYS=$((RETENTION_DAYS + 30))
        ;;
    session)
        if [ "$RETENTION_DAYS" -gt 7 ]; then
            echo "Warning: Session memories typically retained for 1-7 days"
            echo "You specified $RETENTION_DAYS days. Continue? (y/n)"
            read -r response
            if [ "$response" != "y" ]; then
                exit 0
            fi
        fi
        CLEANUP_STRATEGY="automatic_immediate"
        ARCHIVAL_DAYS=0
        ;;
esac

OUTPUT_FILE="retention-policy-${MEMORY_TYPE}.yaml"

cat > "$OUTPUT_FILE" <<EOF
# Mem0 Retention Policy - ${MEMORY_TYPE} Memory
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

memory_type: ${MEMORY_TYPE}

retention:
  active_days: ${RETENTION_DAYS}
  archival_days: ${ARCHIVAL_DAYS}
  cleanup_strategy: ${CLEANUP_STRATEGY}

  # Cleanup triggers
  triggers:
    age_based: true
    score_based: $([ "$MEMORY_TYPE" = "agent" ] && echo "true" || echo "false")
    access_based: $([ "$MEMORY_TYPE" = "user" ] && echo "true" || echo "false")
    session_end: $([ "$MEMORY_TYPE" = "session" ] && echo "true" || echo "false")

cleanup_rules:
  # Age-based cleanup
  age_threshold_days: ${RETENTION_DAYS}

  # Score-based cleanup (for agent memories)
  min_relevance_score: 0.3

  # Access-based cleanup (for user memories)
  inactive_days_threshold: $((RETENTION_DAYS / 2))

  # Archival rules
  archive_after_days: ${ARCHIVAL_DAYS}
  archive_compression: true

  # Batch processing
  batch_size: 100
  check_interval_hours: 24

# Security and compliance
compliance:
  gdpr_deletion: $([ "$MEMORY_TYPE" = "user" ] && echo "true" || echo "false")
  audit_logging: true
  encryption_at_rest: true

# Performance settings
performance:
  async_cleanup: true
  cleanup_window_start: "02:00"  # 2 AM UTC
  cleanup_window_end: "04:00"    # 4 AM UTC
  max_cleanup_duration_minutes: 60

# Notifications
notifications:
  cleanup_summary: true
  error_alerts: true
  threshold_warnings: true

# Metrics
metrics:
  track_cleanup_count: true
  track_storage_savings: true
  track_cleanup_duration: true

EOF

echo "✓ Retention policy generated: $OUTPUT_FILE"
echo ""
echo "Summary:"
echo "  Memory Type: $MEMORY_TYPE"
echo "  Active Retention: $RETENTION_DAYS days"
echo "  Archival Period: $ARCHIVAL_DAYS days"
echo "  Cleanup Strategy: $CLEANUP_STRATEGY"
echo ""
echo "Next steps:"
echo "  1. Review the generated policy file"
echo "  2. Customize settings as needed"
echo "  3. Apply policy to your Mem0 configuration"
echo "  4. Test with sample data before production"
