#!/bin/bash
#
# Celery Health Check Script
# Standalone health verification for Celery infrastructure
#
# Usage:
#   ./health-check.sh [options]
#
# Options:
#   --timeout=N         Timeout in seconds (default: 10)
#   --json              Output in JSON format
#   --check=TYPE        Specific checks: broker,workers,backend,queues (comma-separated)
#
# Exit codes:
#   0 - All checks passed (healthy)
#   1 - One or more checks failed (unhealthy)

set -euo pipefail

# Configuration
TIMEOUT=10
JSON_OUTPUT=false
SPECIFIC_CHECKS=""
CELERY_APP="${CELERY_APP:-myapp}"

# Health status
HEALTHY=true
ERRORS=()

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --timeout=*) TIMEOUT="${1#*=}" ;;
        --json) JSON_OUTPUT=true ;;
        --check=*) SPECIFIC_CHECKS="${1#*=}" ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Check if specific checks requested
should_run_check() {
    local check_name="$1"
    if [ -z "$SPECIFIC_CHECKS" ]; then
        return 0
    fi
    if echo "$SPECIFIC_CHECKS" | grep -q "$check_name"; then
        return 0
    fi
    return 1
}

# Record error
record_error() {
    HEALTHY=false
    ERRORS+=("$1")
}

# Check broker connectivity
check_broker() {
    if ! should_run_check "broker"; then
        return 0
    fi

    if timeout "$TIMEOUT" celery -A "$CELERY_APP" inspect ping &> /dev/null; then
        return 0
    else
        record_error "Broker connectivity check failed"
        return 1
    fi
}

# Check workers
check_workers() {
    if ! should_run_check "workers"; then
        return 0
    fi

    local worker_output
    if ! worker_output=$(timeout "$TIMEOUT" celery -A "$CELERY_APP" inspect stats 2>&1); then
        record_error "Workers check failed: No workers responding"
        return 1
    fi

    local worker_count
    worker_count=$(echo "$worker_output" | grep -c "OK" || true)

    if [ "$worker_count" -eq 0 ]; then
        record_error "Workers check failed: No active workers"
        return 1
    fi

    return 0
}

# Check result backend
check_backend() {
    if ! should_run_check "backend"; then
        return 0
    fi

    # This is a simple check - tries to inspect registered tasks
    if timeout "$TIMEOUT" celery -A "$CELERY_APP" inspect registered &> /dev/null; then
        return 0
    else
        record_error "Result backend check failed"
        return 1
    fi
}

# Check queue depth
check_queues() {
    if ! should_run_check "queues"; then
        return 0
    fi

    if timeout "$TIMEOUT" celery -A "$CELERY_APP" inspect active_queues &> /dev/null; then
        return 0
    else
        record_error "Queue check failed"
        return 1
    fi
}

# Run all checks
run_checks() {
    check_broker
    check_workers
    check_backend
    check_queues
}

# Output results
output_results() {
    if [ "$JSON_OUTPUT" = true ]; then
        # JSON format
        local errors_json="[]"
        if [ ${#ERRORS[@]} -gt 0 ]; then
            errors_json=$(printf '%s\n' "${ERRORS[@]}" | jq -R . | jq -s .)
        fi

        cat << EOF
{
  "healthy": $($HEALTHY && echo "true" || echo "false"),
  "timestamp": $(date +%s),
  "errors": $errors_json
}
EOF
    else
        # Human-readable format
        if [ "$HEALTHY" = true ]; then
            echo "✓ Health check passed - All systems operational"
            exit 0
        else
            echo "✗ Health check failed"
            for error in "${ERRORS[@]}"; do
                echo "  - $error"
            done
            exit 1
        fi
    fi
}

# Main execution
main() {
    run_checks
    output_results

    if [ "$HEALTHY" = true ]; then
        exit 0
    else
        exit 1
    fi
}

main
