#!/bin/bash
# Run complete RLS test suite

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

DB_URL=""; REPORT_FILE=""; VERBOSE=false; CI_MODE=false; FAIL_FAST=false; TOTAL_PASSED=0; TOTAL_FAILED=0

[ -f .env ] && source .env

while [[ $# -gt 0 ]]; do
    case $1 in
        --db-url) DB_URL="$2"; shift 2 ;;
        --report) REPORT_FILE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        --ci) CI_MODE=true; shift ;;
        --fail-fast) FAIL_FAST=true; shift ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --db-url URL     Database connection URL"
            echo "  --report FILE    Generate JSON report"
            echo "  --verbose        Show detailed output"
            echo "  --ci             CI mode (exit 1 on failure)"
            echo "  --fail-fast      Stop on first failure"
            exit 0
            ;;
        *) shift ;;
    esac
done

[ -n "$DB_URL" ] && export SUPABASE_DB_URL="$DB_URL"
[ -z "${SUPABASE_DB_URL:-}" ] && echo -e "${RED}Error: SUPABASE_DB_URL not set${NC}" && exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_test() {
    local test_name=$1
    local test_script=$2
    shift 2
    local test_args=("$@")

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Running: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    local start_time=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        bash "$SCRIPT_DIR/$test_script" "${test_args[@]}"
        local exit_code=$?
    else
        bash "$SCRIPT_DIR/$test_script" "${test_args[@]}" > /tmp/rls-test-output.log 2>&1
        local exit_code=$?
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $test_name completed successfully (${duration}s)${NC}"
        ((TOTAL_PASSED++))
    else
        echo -e "${RED}✗ $test_name failed (${duration}s)${NC}"
        ((TOTAL_FAILED++))

        if [ "$VERBOSE" = false ]; then
            echo -e "${YELLOW}Last 20 lines of output:${NC}"
            tail -n 20 /tmp/rls-test-output.log
        fi

        if [ "$FAIL_FAST" = true ]; then
            echo -e "${RED}Stopping due to --fail-fast${NC}"
            exit 1
        fi
    fi

    echo ""
    return $exit_code
}

# Get all tables with user_id or organization_id
get_test_tables() {
    psql "$SUPABASE_DB_URL" -t -A -c "
        SELECT DISTINCT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND (column_name = 'user_id' OR column_name = 'organization_id')
        ORDER BY table_name
        LIMIT 5;
    " | tr '\n' ' '
}

echo -e "${BLUE}🔒 RLS Test Suite v1.0.0${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Database: ${SUPABASE_DB_URL%@*}@***"
echo -e "  Verbose: $VERBOSE"
echo -e "  CI Mode: $CI_MODE"
echo -e "  Fail Fast: $FAIL_FAST"
echo ""

TEST_TABLES=($(get_test_tables))

if [ ${#TEST_TABLES[@]} -eq 0 ]; then
    echo -e "${YELLOW}Warning: No tables found with user_id or organization_id columns${NC}"
    echo -e "${YELLOW}Creating minimal test coverage...${NC}"
    TEST_TABLES=()
fi

echo -e "${BLUE}Test tables: ${TEST_TABLES[*]}${NC}"
echo ""

START_TIME=$(date +%s)

# 1. Audit RLS coverage
run_test "RLS Coverage Audit" "audit-rls-coverage.sh" --format json --report /tmp/rls-audit.json

# 2. Test anonymous access
run_test "Anonymous Access Tests" "test-anonymous-access.sh" "${TEST_TABLES[@]}"

# 3. Test user isolation (if tables with user_id exist)
if [ ${#TEST_TABLES[@]} -gt 0 ]; then
    run_test "User Isolation Tests" "test-user-isolation.sh" "${TEST_TABLES[@]}"
fi

# 4. Test multi-tenant isolation (if tables with organization_id exist)
MULTI_TENANT_TABLES=($(psql "$SUPABASE_DB_URL" -t -A -c "
    SELECT table_name
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND column_name = 'organization_id'
    LIMIT 3;
" | tr '\n' ' '))

if [ ${#MULTI_TENANT_TABLES[@]} -gt 0 ]; then
    run_test "Multi-Tenant Isolation Tests" "test-multi-tenant-isolation.sh" "${MULTI_TENANT_TABLES[@]}"
fi

# 5. Test role permissions (if supported)
RBAC_TABLES=($(psql "$SUPABASE_DB_URL" -t -A -c "
    SELECT DISTINCT tablename
    FROM pg_policies
    WHERE schemaname = 'public'
    AND (qual::text LIKE '%app_metadata%' OR qual::text LIKE '%role%')
    LIMIT 3;
" | tr '\n' ' '))

if [ ${#RBAC_TABLES[@]} -gt 0 ]; then
    run_test "Role Permission Tests" "test-role-permissions.sh" "${RBAC_TABLES[@]}"
fi

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

# Generate report
if [ -n "$REPORT_FILE" ]; then
    cat > "$REPORT_FILE" <<EOF
{
  "suite": "RLS Test Suite",
  "version": "1.0.0",
  "timestamp": "$(date -Iseconds)",
  "duration_seconds": $TOTAL_DURATION,
  "results": {
    "passed": $TOTAL_PASSED,
    "failed": $TOTAL_FAILED,
    "total": $((TOTAL_PASSED + TOTAL_FAILED))
  },
  "tables_tested": $(printf '"%s",' "${TEST_TABLES[@]}" | sed 's/,$//' | sed 's/^/[/' | sed 's/$/]/'),
  "status": "$([ $TOTAL_FAILED -eq 0 ] && echo "PASSED" || echo "FAILED")"
}
EOF
    echo -e "${BLUE}Report written to: $REPORT_FILE${NC}"
fi

# Print summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Test Suite Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Tables tested: ${#TEST_TABLES[@]}"
echo -e "  Total tests: $((TOTAL_PASSED + TOTAL_FAILED))"
echo -e "  ${GREEN}Passed: $TOTAL_PASSED ✓${NC}"
[ $TOTAL_FAILED -gt 0 ] && echo -e "  ${RED}Failed: $TOTAL_FAILED ✗${NC}" || echo -e "  Failed: $TOTAL_FAILED"
echo -e "  Duration: ${TOTAL_DURATION}s"
echo ""

if [ $TOTAL_FAILED -gt 0 ]; then
    echo -e "${RED}❌ Critical security issues found. Do not deploy.${NC}"
    [ "$CI_MODE" = true ] && exit 1 || exit 0
else
    echo -e "${GREEN}✅ All RLS policies working correctly!${NC}"
    exit 0
fi
