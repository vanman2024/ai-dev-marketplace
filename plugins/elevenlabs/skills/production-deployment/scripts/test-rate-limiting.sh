#!/usr/bin/env bash

# test-rate-limiting.sh
# Comprehensive rate limiting test suite for ElevenLabs API integration
# Usage: bash test-rate-limiting.sh --concurrency 20 --duration 60 --plan-tier pro

set -e

# Default configuration
CONCURRENCY=10
DURATION=60
PLAN_TIER="pro"
PATTERN="steady"
API_KEY="${ELEVENLABS_API_KEY}"
ENDPOINT="https://api.elevenlabs.io/v1/voices"
OUTPUT_DIR="./test-results"
START_RPS=1
END_RPS=10
FAILURE_RATE=0
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --concurrency)
            CONCURRENCY="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --plan-tier)
            PLAN_TIER="$2"
            shift 2
            ;;
        --pattern)
            PATTERN="$2"
            shift 2
            ;;
        --api-key)
            API_KEY="$2"
            shift 2
            ;;
        --endpoint)
            ENDPOINT="$2"
            shift 2
            ;;
        --start-rps)
            START_RPS="$2"
            shift 2
            ;;
        --end-rps)
            END_RPS="$2"
            shift 2
            ;;
        --failure-rate)
            FAILURE_RATE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Plan tier concurrency limits
declare -A PLAN_LIMITS=(
    ["free"]="2"
    ["starter"]="3"
    ["creator"]="5"
    ["pro"]="10"
    ["scale"]="15"
    ["business"]="15"
    ["enterprise"]="20"
)

# Validate inputs
validate_inputs() {
    log_step "Validating test configuration..."

    # Check API key
    if [ -z "$API_KEY" ]; then
        log_error "API key not provided. Use --api-key or set ELEVENLABS_API_KEY"
        exit 1
    fi

    # Validate plan tier
    if [ -z "${PLAN_LIMITS[$PLAN_TIER]}" ]; then
        log_error "Invalid plan tier: $PLAN_TIER"
        log_info "Valid tiers: free, starter, creator, pro, scale, business, enterprise"
        exit 1
    fi

    # Validate pattern
    if [[ ! "$PATTERN" =~ ^(steady|ramp-up|burst|chaos)$ ]]; then
        log_error "Invalid pattern: $PATTERN"
        log_info "Valid patterns: steady, ramp-up, burst, chaos"
        exit 1
    fi

    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_warn "jq is not installed. JSON parsing will be limited."
    fi

    log_info "Configuration validated ✓"
    log_info "  - Concurrency: $CONCURRENCY"
    log_info "  - Duration: ${DURATION}s"
    log_info "  - Plan tier: $PLAN_TIER (limit: ${PLAN_LIMITS[$PLAN_TIER]})"
    log_info "  - Test pattern: $PATTERN"
}

# Setup test environment
setup_test() {
    log_step "Setting up test environment..."

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Generate test ID
    TEST_ID="test-$(date +%Y%m%d-%H%M%S)"
    TEST_DIR="$OUTPUT_DIR/$TEST_ID"
    mkdir -p "$TEST_DIR"

    log_info "Test ID: $TEST_ID"
    log_info "Results will be saved to: $TEST_DIR"
}

# Make API request
make_request() {
    local request_id=$1
    local start_time=$(date +%s%N)

    # Make request with timing
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" -X GET "$ENDPOINT" \
        -H "xi-api-key: $API_KEY" \
        -H "User-Agent: ElevenLabs-Load-Test/$TEST_ID" \
        2>&1)

    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

    # Parse response
    local http_code=$(echo "$response" | tail -n 2 | head -n 1)
    local time_total=$(echo "$response" | tail -n 1)
    local body=$(echo "$response" | head -n -2)

    # Extract concurrent request headers if available
    local current_concurrent=$(echo "$body" | grep -i "current-concurrent-requests" | cut -d':' -f2 | tr -d ' ' || echo "N/A")
    local max_concurrent=$(echo "$body" | grep -i "maximum-concurrent-requests" | cut -d':' -f2 | tr -d ' ' || echo "N/A")

    # Log result
    echo "$request_id,$http_code,$duration,$time_total,$current_concurrent,$max_concurrent" >> "$TEST_DIR/requests.csv"

    log_debug "Request $request_id: HTTP $http_code, ${duration}ms"

    # Return status
    if [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Run steady load test
run_steady_test() {
    log_step "Running steady load test..."
    log_info "Sending $CONCURRENCY concurrent requests for ${DURATION}s"

    # Initialize CSV
    echo "request_id,http_code,duration_ms,time_total,current_concurrent,max_concurrent" > "$TEST_DIR/requests.csv"

    local request_count=0
    local success_count=0
    local error_count=0
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))

    # Track concurrent requests
    local active_requests=0
    local max_active=0

    while [ $(date +%s) -lt $end_time ]; do
        # Launch requests up to concurrency limit
        while [ $active_requests -lt $CONCURRENCY ]; do
            request_count=$((request_count + 1))
            active_requests=$((active_requests + 1))

            # Track max active
            if [ $active_requests -gt $max_active ]; then
                max_active=$active_requests
            fi

            # Make request in background
            (
                if make_request "$request_count"; then
                    echo "success" > "$TEST_DIR/result_${request_count}.tmp"
                else
                    echo "error" > "$TEST_DIR/result_${request_count}.tmp"
                fi
            ) &

            # Small delay to avoid overwhelming the system
            sleep 0.1
        done

        # Wait for some requests to complete
        sleep 0.5

        # Count completed requests
        for result_file in "$TEST_DIR"/result_*.tmp; do
            if [ -f "$result_file" ]; then
                if grep -q "success" "$result_file"; then
                    success_count=$((success_count + 1))
                else
                    error_count=$((error_count + 1))
                fi
                rm "$result_file"
                active_requests=$((active_requests - 1))
            fi
        done

        # Progress update
        local elapsed=$(($(date +%s) - start_time))
        log_info "Progress: ${elapsed}s/${DURATION}s | Requests: $request_count | Success: $success_count | Errors: $error_count"
    done

    # Wait for remaining requests
    wait

    log_info "Steady test complete ✓"
    log_info "  - Total requests: $request_count"
    log_info "  - Successful: $success_count"
    log_info "  - Errors: $error_count"
    log_info "  - Max concurrent: $max_active"
}

# Run ramp-up test
run_ramp_up_test() {
    log_step "Running ramp-up load test..."
    log_info "Ramping from ${START_RPS} to ${END_RPS} RPS over ${DURATION}s"

    echo "request_id,http_code,duration_ms,time_total,current_concurrent,max_concurrent" > "$TEST_DIR/requests.csv"

    local request_count=0
    local success_count=0
    local error_count=0
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))

    local current_rps=$START_RPS
    local rps_increment=$(echo "scale=2; ($END_RPS - $START_RPS) / $DURATION" | bc)

    while [ $(date +%s) -lt $end_time ]; do
        local elapsed=$(($(date +%s) - start_time))
        current_rps=$(echo "scale=0; $START_RPS + ($rps_increment * $elapsed)" | bc)

        # Send requests for current RPS
        for ((i=0; i<current_rps; i++)); do
            request_count=$((request_count + 1))

            (
                if make_request "$request_count"; then
                    success_count=$((success_count + 1))
                else
                    error_count=$((error_count + 1))
                fi
            ) &
        done

        log_info "Elapsed: ${elapsed}s | Current RPS: $current_rps | Total: $request_count"
        sleep 1
    done

    wait

    log_info "Ramp-up test complete ✓"
    log_info "  - Total requests: $request_count"
    log_info "  - Successful: $success_count"
    log_info "  - Errors: $error_count"
}

# Run burst test
run_burst_test() {
    log_step "Running burst load test..."
    log_info "Sending burst of $CONCURRENCY concurrent requests"

    echo "request_id,http_code,duration_ms,time_total,current_concurrent,max_concurrent" > "$TEST_DIR/requests.csv"

    local success_count=0
    local error_count=0

    # Send burst of concurrent requests
    for ((i=1; i<=CONCURRENCY; i++)); do
        (
            if make_request "$i"; then
                echo "success" > "$TEST_DIR/burst_result_${i}.tmp"
            else
                echo "error" > "$TEST_DIR/burst_result_${i}.tmp"
            fi
        ) &
    done

    # Wait for all to complete
    wait

    # Count results
    for result_file in "$TEST_DIR"/burst_result_*.tmp; do
        if [ -f "$result_file" ]; then
            if grep -q "success" "$result_file"; then
                success_count=$((success_count + 1))
            else
                error_count=$((error_count + 1))
            fi
            rm "$result_file"
        fi
    done

    log_info "Burst test complete ✓"
    log_info "  - Total requests: $CONCURRENCY"
    log_info "  - Successful: $success_count"
    log_info "  - Errors: $error_count"
}

# Run chaos test
run_chaos_test() {
    log_step "Running chaos test..."
    log_info "Duration: ${DURATION}s | Failure injection rate: ${FAILURE_RATE}"

    echo "request_id,http_code,duration_ms,time_total,current_concurrent,max_concurrent" > "$TEST_DIR/requests.csv"

    local request_count=0
    local success_count=0
    local error_count=0
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))

    while [ $(date +%s) -lt $end_time ]; do
        request_count=$((request_count + 1))

        # Randomly inject failures
        local should_fail=$(echo "$RANDOM % 100 < $FAILURE_RATE * 100" | bc)

        if [ "$should_fail" = "1" ]; then
            log_debug "Injecting failure for request $request_count"
            error_count=$((error_count + 1))
        else
            (
                if make_request "$request_count"; then
                    success_count=$((success_count + 1))
                else
                    error_count=$((error_count + 1))
                fi
            ) &
        fi

        # Random delay between requests (0-2 seconds)
        sleep $(echo "scale=2; $RANDOM / 16384" | bc)

        if [ $((request_count % 10)) -eq 0 ]; then
            log_info "Requests: $request_count | Success: $success_count | Errors: $error_count"
        fi
    done

    wait

    log_info "Chaos test complete ✓"
    log_info "  - Total requests: $request_count"
    log_info "  - Successful: $success_count"
    log_info "  - Errors: $error_count"
}

# Analyze results
analyze_results() {
    log_step "Analyzing test results..."

    if [ ! -f "$TEST_DIR/requests.csv" ]; then
        log_error "No results file found"
        return 1
    fi

    # Count requests by status code
    local total=$(tail -n +2 "$TEST_DIR/requests.csv" | wc -l)
    local success=$(tail -n +2 "$TEST_DIR/requests.csv" | grep -c "^[^,]*,200," || echo 0)
    local rate_limited=$(tail -n +2 "$TEST_DIR/requests.csv" | grep -c "^[^,]*,429," || echo 0)
    local errors=$(tail -n +2 "$TEST_DIR/requests.csv" | grep -c "^[^,]*,5[0-9][0-9]," || echo 0)

    # Calculate latency statistics
    local avg_latency=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | \
        awk '{sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')

    local min_latency=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | sort -n | head -n1)
    local max_latency=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | sort -n | tail -n1)

    # Calculate percentiles
    local p50=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | sort -n | \
        awk -v p=0.50 '{a[NR]=$1} END{print a[int(NR*p)+1]}')
    local p95=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | sort -n | \
        awk -v p=0.95 '{a[NR]=$1} END{print a[int(NR*p)+1]}')
    local p99=$(tail -n +2 "$TEST_DIR/requests.csv" | cut -d',' -f3 | sort -n | \
        awk -v p=0.99 '{a[NR]=$1} END{print a[int(NR*p)+1]}')

    # Calculate error rate
    local error_rate=$(echo "scale=2; ($rate_limited + $errors) * 100 / $total" | bc)

    # Generate report
    cat > "$TEST_DIR/report.json" << EOF
{
  "testId": "$TEST_ID",
  "configuration": {
    "pattern": "$PATTERN",
    "concurrency": $CONCURRENCY,
    "duration": $DURATION,
    "planTier": "$PLAN_TIER",
    "planLimit": ${PLAN_LIMITS[$PLAN_TIER]}
  },
  "results": {
    "totalRequests": $total,
    "successful": $success,
    "rateLimited": $rate_limited,
    "errors": $errors,
    "errorRate": $error_rate
  },
  "latency": {
    "min": ${min_latency:-0},
    "max": ${max_latency:-0},
    "average": ${avg_latency:-0},
    "p50": ${p50:-0},
    "p95": ${p95:-0},
    "p99": ${p99:-0}
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    log_info "Analysis complete ✓"
    echo ""
    log_info "=========================================="
    log_info "  Test Results Summary"
    log_info "=========================================="
    echo ""
    log_info "Requests:"
    log_info "  - Total: $total"
    log_info "  - Successful: $success ($(echo "scale=1; $success * 100 / $total" | bc)%)"
    log_info "  - Rate Limited (429): $rate_limited"
    log_info "  - Errors (5xx): $errors"
    log_info "  - Error Rate: ${error_rate}%"
    echo ""
    log_info "Latency (milliseconds):"
    log_info "  - Min: ${min_latency:-0}ms"
    log_info "  - Average: $(printf "%.0f" ${avg_latency:-0})ms"
    log_info "  - P50: ${p50:-0}ms"
    log_info "  - P95: ${p95:-0}ms"
    log_info "  - P99: ${p99:-0}ms"
    log_info "  - Max: ${max_latency:-0}ms"
    echo ""

    # Validation against plan limits
    log_info "Plan Limit Validation:"
    if [ $rate_limited -gt 0 ]; then
        log_warn "  ⚠ Rate limiting occurred ($rate_limited requests)"
        log_info "  Consider upgrading plan or reducing concurrency"
    else
        log_info "  ✓ No rate limiting detected"
    fi

    if (( $(echo "$error_rate > 5" | bc -l) )); then
        log_warn "  ⚠ Error rate (${error_rate}%) exceeds 5% threshold"
    else
        log_info "  ✓ Error rate within acceptable range"
    fi

    echo ""
    log_info "Results saved to: $TEST_DIR/report.json"
}

# Main execution
main() {
    log_info "Starting rate limiting tests..."
    echo ""

    validate_inputs
    setup_test

    # Run test based on pattern
    case $PATTERN in
        steady)
            run_steady_test
            ;;
        ramp-up)
            run_ramp_up_test
            ;;
        burst)
            run_burst_test
            ;;
        chaos)
            run_chaos_test
            ;;
    esac

    analyze_results

    log_info "Test complete! 🎉"
}

# Run main function
main
