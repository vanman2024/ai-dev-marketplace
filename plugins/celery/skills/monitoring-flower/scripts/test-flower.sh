#!/bin/bash

# test-flower.sh - Validate Flower setup and connectivity
#
# Usage:
#   ./test-flower.sh [flower-url]
#
# Examples:
#   ./test-flower.sh http://localhost:5555
#   ./test-flower.sh http://user:password@localhost:5555
#   ./test-flower.sh https://flower.example.com
#
# Exit Codes:
#   0 - All checks passed
#   1 - Flower not accessible
#   2 - No workers detected
#   3 - Authentication issues
#   4 - Configuration warnings

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default Flower URL
FLOWER_URL="${1:-http://localhost:5555}"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}           Flower Configuration Validation                  ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${YELLOW}Testing Flower at: ${FLOWER_URL}${NC}\n"

# ============================================================================
# Helper Functions
# ============================================================================

pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ============================================================================
# Test 1: Flower Accessibility
# ============================================================================

echo -e "${YELLOW}[1/7] Testing Flower Accessibility...${NC}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWER_URL" --max-time 10 || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    pass "Flower is accessible (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "401" ]; then
    pass "Flower is accessible (requires authentication)"
elif [ "$HTTP_CODE" = "000" ]; then
    fail "Cannot connect to Flower (connection timeout)"
    echo -e "${YELLOW}  Make sure Flower is running at $FLOWER_URL${NC}"
    exit 1
else
    fail "Unexpected HTTP response: $HTTP_CODE"
    exit 1
fi

# ============================================================================
# Test 2: API Endpoints
# ============================================================================

echo -e "\n${YELLOW}[2/7] Testing API Endpoints...${NC}"

# Test /api/workers endpoint
WORKERS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWER_URL/api/workers" --max-time 10 || echo "000")

if [ "$WORKERS_CODE" = "200" ] || [ "$WORKERS_CODE" = "401" ]; then
    pass "API endpoint /api/workers is available"
else
    fail "API endpoint /api/workers returned $WORKERS_CODE"
fi

# Test /api/tasks endpoint
TASKS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWER_URL/api/tasks" --max-time 10 || echo "000")

if [ "$TASKS_CODE" = "200" ] || [ "$TASKS_CODE" = "401" ]; then
    pass "API endpoint /api/tasks is available"
else
    fail "API endpoint /api/tasks returned $TASKS_CODE"
fi

# ============================================================================
# Test 3: Worker Detection
# ============================================================================

echo -e "\n${YELLOW}[3/7] Checking for Active Workers...${NC}"

# Fetch workers data
WORKERS_DATA=$(curl -s "$FLOWER_URL/api/workers" --max-time 10 2>/dev/null || echo "{}")

# Count workers
WORKER_COUNT=$(echo "$WORKERS_DATA" | grep -o '"celery@' | wc -l || echo "0")

if [ "$WORKER_COUNT" -gt 0 ]; then
    pass "Found $WORKER_COUNT active worker(s)"

    # List workers
    echo "$WORKERS_DATA" | grep -o 'celery@[^"]*' | while read -r worker; do
        info "  - $worker"
    done
else
    fail "No active workers detected"
    warn "Start Celery workers with: celery -A yourapp worker"
    exit 2
fi

# ============================================================================
# Test 4: Task History
# ============================================================================

echo -e "\n${YELLOW}[4/7] Checking Task History...${NC}"

TASKS_DATA=$(curl -s "$FLOWER_URL/api/tasks" --max-time 10 2>/dev/null || echo "{}")

TASK_COUNT=$(echo "$TASKS_DATA" | grep -o '"uuid"' | wc -l || echo "0")

if [ "$TASK_COUNT" -gt 0 ]; then
    pass "Found $TASK_COUNT task(s) in history"
else
    warn "No task history available yet"
    info "Task history will appear as workers process tasks"
fi

# ============================================================================
# Test 5: Authentication Configuration
# ============================================================================

echo -e "\n${YELLOW}[5/7] Checking Authentication...${NC}"

# Check if authentication is required
AUTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWER_URL" --max-time 10)

if [ "$AUTH_CHECK" = "401" ]; then
    pass "Authentication is enabled (HTTP 401)"

    # Test if credentials work (if provided in URL)
    if [[ $FLOWER_URL == *"@"* ]]; then
        AUTHED_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FLOWER_URL" --max-time 10)
        if [ "$AUTHED_CODE" = "200" ]; then
            pass "Authentication credentials are valid"
        else
            fail "Authentication credentials are invalid"
            exit 3
        fi
    fi
else
    warn "No authentication configured (publicly accessible)"
    warn "Set FLOWER_BASIC_AUTH or configure OAuth2 for production"
fi

# ============================================================================
# Test 6: Metrics Endpoint
# ============================================================================

echo -e "\n${YELLOW}[6/7] Checking Metrics Export...${NC}"

# Check for Prometheus metrics (if prometheus-metrics.py is running)
METRICS_PORT="${PROMETHEUS_PORT:-8000}"
METRICS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$METRICS_PORT/metrics" --max-time 5 2>/dev/null || echo "000")

if [ "$METRICS_CODE" = "200" ]; then
    pass "Prometheus metrics available at port $METRICS_PORT"
else
    info "Prometheus metrics not configured (optional)"
fi

# ============================================================================
# Test 7: Configuration Best Practices
# ============================================================================

echo -e "\n${YELLOW}[7/7] Checking Configuration Best Practices...${NC}"

# Check if using HTTPS
if [[ $FLOWER_URL == https://* ]]; then
    pass "Using HTTPS (secure)"
else
    warn "Using HTTP (not secure for production)"
    warn "Configure SSL/TLS or use reverse proxy with HTTPS"
fi

# Check if using default port
if [[ $FLOWER_URL == *:5555* ]]; then
    info "Using default Flower port (5555)"
else
    pass "Using custom port"
fi

# Check for localhost
if [[ $FLOWER_URL == *localhost* ]] || [[ $FLOWER_URL == *127.0.0.1* ]]; then
    info "Testing local Flower instance"
else
    pass "Testing remote Flower instance"
fi

# ============================================================================
# Database Persistence Check
# ============================================================================

echo -e "\n${YELLOW}Checking Database Persistence...${NC}"

if [ -f "flower.db" ]; then
    DB_SIZE=$(du -h flower.db | cut -f1)
    pass "Database persistence enabled (flower.db: $DB_SIZE)"
else
    info "No flower.db found (in-memory mode or different path)"
fi

# ============================================================================
# Summary
# ============================================================================

echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}                    Test Summary                            ${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${GREEN}Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"

# Overall status
if [ $TESTS_FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "\n${GREEN}✓ All checks passed!${NC}"
        echo -e "${GREEN}Flower is properly configured and operational.${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}✓ All checks passed with warnings${NC}"
        echo -e "${YELLOW}Review warnings above for production deployment.${NC}"
        exit 4
    fi
else
    echo -e "\n${RED}✗ Some checks failed${NC}"
    echo -e "${RED}Review errors above and fix configuration.${NC}"
    exit 1
fi

# ============================================================================
# Additional Diagnostic Information
# ============================================================================

# Uncomment for detailed diagnostic output:
#
# echo -e "\n${BLUE}Diagnostic Information:${NC}"
# echo -e "\nWorkers Response:"
# echo "$WORKERS_DATA" | python3 -m json.tool 2>/dev/null || echo "$WORKERS_DATA"
#
# echo -e "\nTasks Response:"
# echo "$TASKS_DATA" | python3 -m json.tool 2>/dev/null | head -20 || echo "$TASKS_DATA"
