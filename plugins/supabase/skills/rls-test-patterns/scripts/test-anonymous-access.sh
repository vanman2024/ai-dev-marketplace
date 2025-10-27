#!/bin/bash
# Test anonymous access restrictions in RLS policies

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

REPORT_FILE=""; TEST_NULL_UID=false; PASSED=0; FAILED=0; TABLES=()

[ -f .env ] && source .env

while [[ $# -gt 0 ]]; do
    case $1 in
        --report) REPORT_FILE="$2"; shift 2 ;;
        --test-null-uid) TEST_NULL_UID=true; shift ;;
        --help) echo "Usage: $0 [tables...] [--report FILE] [--test-null-uid]"; exit 0 ;;
        *) TABLES+=("$1"); shift ;;
    esac
done

[ -z "${SUPABASE_DB_URL:-}" ] && echo -e "${RED}Error: SUPABASE_DB_URL not set${NC}" && exit 1

execute_sql() { psql "$SUPABASE_DB_URL" -t -A -c "$1" 2>&1; }

test_anon_select() {
    local table=$1
    local test_name="$table: Anonymous SELECT blocked"

    # Try to SELECT as anon role
    local count=$(execute_sql "
        SET LOCAL ROLE anon;
        SELECT COUNT(*) FROM public.$table;
    " 2>&1)

    if [[ "$count" == *"ERROR"* ]] || [ "$count" = "0" ]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Anonymous can read $count rows${NC}"
        ((FAILED++))
        [ -n "$REPORT_FILE" ] && echo "FAIL: $test_name - Anonymous read access" >> "$REPORT_FILE"
    fi
}

test_anon_insert() {
    local table=$1
    local test_name="$table: Anonymous INSERT blocked"

    local result=$(execute_sql "
        SET LOCAL ROLE anon;
        INSERT INTO public.$table DEFAULT VALUES;
    " 2>&1)

    if [[ "$result" == *"ERROR"* ]] || [[ "$result" == *"violates"* ]]; then
        echo -e "${GREEN}✓ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Anonymous can insert${NC}"
        ((FAILED++))
        [ -n "$REPORT_FILE" ] && echo "FAIL: $test_name - Anonymous insert access" >> "$REPORT_FILE"
    fi
}

test_null_uid_handling() {
    local table=$1
    local test_name="$table: Null auth.uid() handling"

    # Check if policies handle null uid safely
    local policy_check=$(execute_sql "
        SELECT COUNT(*)
        FROM pg_policies
        WHERE schemaname = 'public'
        AND tablename = '$table'
        AND (
            qual::text LIKE '%IS NOT NULL%' OR
            qual::text LIKE '%COALESCE%'
        );
    ")

    if [ "$policy_check" != "0" ]; then
        echo -e "${GREEN}✓ $test_name: Policies handle null uid${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠ $test_name: No null uid checks found in policies${NC}"
        [ -n "$REPORT_FILE" ] && echo "WARNING: $test_name - Missing null checks" >> "$REPORT_FILE"
    fi
}

test_table() {
    local table=$1
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing: $table${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    test_anon_select "$table"
    test_anon_insert "$table"
    [ "$TEST_NULL_UID" = true ] && test_null_uid_handling "$table"
    echo ""
}

echo -e "${BLUE}🚫 RLS Anonymous Access Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

[ -n "$REPORT_FILE" ] && echo "# RLS Anonymous Access Test Report" > "$REPORT_FILE" && echo "Generated: $(date)" >> "$REPORT_FILE" && echo "" >> "$REPORT_FILE"

if [ ${#TABLES[@]} -eq 0 ]; then
    TABLES=($(execute_sql "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename" | tr '\n' ' '))
    echo -e "${BLUE}Testing all public tables: ${TABLES[*]}${NC}"
    echo ""
fi

for table in "${TABLES[@]}"; do
    test_table "$table"
done

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Tables: ${#TABLES[@]}"
echo -e "  Total: $((PASSED + FAILED))"
echo -e "  ${GREEN}Passed: $PASSED ✓${NC}"
[ $FAILED -gt 0 ] && echo -e "  ${RED}Failed: $FAILED ✗${NC}" || echo -e "  Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Anonymous access tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All anonymous access tests passed${NC}"
    exit 0
fi
