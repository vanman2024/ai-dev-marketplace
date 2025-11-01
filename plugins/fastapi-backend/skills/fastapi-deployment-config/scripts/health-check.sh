#!/bin/bash

# health-check.sh - Application health verification for FastAPI
# Usage: ./health-check.sh <URL> [OPTIONS]

set -euo pipefail

# Default values
TIMEOUT=10
INTERVAL=0
RETRIES=3
DEBUG=false
EXPECTED_STATUS=200

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
FastAPI Health Check Script

Usage: ./health-check.sh <URL> [OPTIONS]

Arguments:
  URL                  Health check endpoint URL (required)
                       Examples: http://localhost:8000/health
                                https://api.example.com/health

Options:
  --timeout=SECONDS    Request timeout in seconds (default: 10)
  --interval=SECONDS   Check interval for continuous monitoring (default: 0 = single check)
  --retries=N          Number of retry attempts (default: 3)
  --expected=STATUS    Expected HTTP status code (default: 200)
  --debug              Show detailed request/response information
  --help               Display this help message

Examples:
  # Single health check
  ./health-check.sh http://localhost:8000/health

  # Continuous monitoring (every 30 seconds)
  ./health-check.sh https://api.example.com/health --interval=30

  # With custom timeout and retries
  ./health-check.sh http://localhost:8000/health --timeout=5 --retries=5

  # Debug mode (show full response)
  ./health-check.sh http://localhost:8000/health --debug

Exit Codes:
  0 - Health check passed
  1 - Health check failed
  2 - Invalid arguments or configuration

Health Check Criteria:
  ✓ HTTP status code matches expected (default: 200)
  ✓ Response time under timeout
  ✓ Valid JSON response (if applicable)
  ✓ Database connectivity (if included in response)
  ✓ Service dependencies (if included in response)

EOF
}

# Check if URL is provided
if [ $# -eq 0 ]; then
    print_error "No URL provided"
    echo "Use --help for usage information"
    exit 2
fi

URL="$1"
shift

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --timeout=*)
            TIMEOUT="${arg#*=}"
            shift
            ;;
        --interval=*)
            INTERVAL="${arg#*=}"
            shift
            ;;
        --retries=*)
            RETRIES="${arg#*=}"
            shift
            ;;
        --expected=*)
            EXPECTED_STATUS="${arg#*=}"
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 2
            ;;
    esac
done

# Validate URL format
if ! [[ "$URL" =~ ^https?:// ]]; then
    print_error "Invalid URL format: $URL"
    print_info "URL must start with http:// or https://"
    exit 2
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed"
    print_info "Install curl: sudo apt-get install curl"
    exit 2
fi

# Function to perform health check
perform_health_check() {
    local attempt=$1
    local start_time=$(date +%s.%N)

    print_debug "Attempt $attempt/$RETRIES"
    print_debug "URL: $URL"
    print_debug "Timeout: ${TIMEOUT}s"

    # Perform request
    local http_code
    local response
    local response_time

    if [ "$DEBUG" = true ]; then
        # In debug mode, show full output
        response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
            --max-time "$TIMEOUT" \
            --fail-with-body \
            "$URL" 2>&1 || echo "000")
        http_code=$(echo "$response" | tail -n 2 | head -n 1)
        response_time=$(echo "$response" | tail -n 1)
        response_body=$(echo "$response" | head -n -2)
    else
        # Normal mode
        response=$(curl -s -w "%{http_code}" \
            --max-time "$TIMEOUT" \
            -o /tmp/health_check_response_$$.json \
            "$URL" 2>&1 || echo "000")
        http_code="$response"
        response_body=$(cat /tmp/health_check_response_$$.json 2>/dev/null || echo "")
        rm -f /tmp/health_check_response_$$.json
    fi

    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    print_debug "HTTP Status: $http_code"
    print_debug "Response Time: ${duration}s"

    # Check HTTP status code
    if [ "$http_code" = "$EXPECTED_STATUS" ]; then
        print_success "Health check passed (HTTP $http_code)"
        echo "  Response Time: ${duration}s"

        # Parse JSON response if applicable
        if echo "$response_body" | python3 -m json.tool > /dev/null 2>&1; then
            print_success "Valid JSON response"

            if [ "$DEBUG" = true ]; then
                echo "Response body:"
                echo "$response_body" | python3 -m json.tool
            fi

            # Check for status field
            if echo "$response_body" | grep -q '"status"'; then
                local status=$(echo "$response_body" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))" 2>/dev/null)
                print_info "Status: $status"
            fi

            # Check for database field
            if echo "$response_body" | grep -q '"database"'; then
                local db_status=$(echo "$response_body" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database', 'unknown'))" 2>/dev/null)
                if [ "$db_status" = "healthy" ] || [ "$db_status" = "connected" ] || [ "$db_status" = "True" ] || [ "$db_status" = "true" ]; then
                    print_success "Database: $db_status"
                else
                    print_warning "Database: $db_status"
                fi
            fi

            # Check for cache/redis field
            if echo "$response_body" | grep -q '"cache"\|"redis"'; then
                local cache_status=$(echo "$response_body" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('cache', d.get('redis', 'unknown')))" 2>/dev/null)
                if [ "$cache_status" = "healthy" ] || [ "$cache_status" = "connected" ] || [ "$cache_status" = "True" ] || [ "$cache_status" = "true" ]; then
                    print_success "Cache: $cache_status"
                else
                    print_warning "Cache: $cache_status"
                fi
            fi
        else
            if [ -n "$response_body" ]; then
                print_info "Non-JSON response received"
                if [ "$DEBUG" = true ]; then
                    echo "Response: $response_body"
                fi
            fi
        fi

        return 0
    else
        print_error "Health check failed (HTTP $http_code, expected $EXPECTED_STATUS)"

        if [ "$DEBUG" = true ] && [ -n "$response_body" ]; then
            echo "Response body:"
            echo "$response_body"
        fi

        return 1
    fi
}

# Main execution
print_info "Starting health check for: $URL"
print_info "Expected status: $EXPECTED_STATUS"

if [ "$INTERVAL" -gt 0 ]; then
    print_info "Continuous monitoring enabled (interval: ${INTERVAL}s)"
    print_info "Press Ctrl+C to stop"
    echo ""
fi

# Retry loop
success=false
for ((i=1; i<=RETRIES; i++)); do
    if perform_health_check "$i"; then
        success=true
        break
    else
        if [ $i -lt $RETRIES ]; then
            print_warning "Retrying in 2 seconds... ($i/$RETRIES)"
            sleep 2
        fi
    fi
done

if [ "$success" = false ]; then
    echo ""
    print_error "Health check failed after $RETRIES attempts"
    echo ""
    print_info "Troubleshooting steps:"
    echo "  1. Verify the application is running"
    echo "  2. Check the health endpoint URL is correct"
    echo "  3. Ensure network connectivity"
    echo "  4. Review application logs for errors"
    echo "  5. Verify database/cache connections if applicable"
    echo ""
    exit 1
fi

# Continuous monitoring mode
if [ "$INTERVAL" -gt 0 ]; then
    echo ""
    print_info "Starting continuous monitoring..."

    while true; do
        sleep "$INTERVAL"
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Running health check..."
        perform_health_check "continuous" || print_error "Health check failed at $(date '+%H:%M:%S')"
    done
fi

echo ""
print_success "Health check completed successfully"
exit 0
