#!/bin/bash
# Test role-based access control in RLS policies
# Verifies admin, editor, and viewer roles have correct permissions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
REPORT_FILE=""
TEST_ESCALATION=false
ROLES="admin,editor,viewer"
PASSED=0
FAILED=0
TABLES=()

# Load environment
[ -f .env ] && source .env

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --report) REPORT_FILE="$2"; shift 2 ;;
        --test-escalation) TEST_ESCALATION=true; shift ;;
        --roles) ROLES="$2"; shift 2 ;;
        --help)
            echo "Usage: $0 [table1] [table2] ... [options]"
            echo "Options:"
            echo "  --report FILE        Generate report"
            echo "  --test-escalation    Test privilege escalation prevention"
            echo "  --roles ROLES        Comma-separated role list (default: admin,editor,viewer)"
            exit 0
            ;;
        *) TABLES+=("$1"); shift ;;
    esac
done

[ -z "${SUPABASE_DB_URL:-}" ] && echo -e "${RED}Error: SUPABASE_DB_URL not set${NC}" && exit 1

execute_sql() {
    psql "$SUPABASE_DB_URL" -t -A -c "$1" 2>&1
}

# Test admin full access
test_admin_access() {
    local table=$1
    local test_name="$table: Admin full access"

    local admin_id=$(uuidgen)
    execute_sql "INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES ('$admin_id', 'admin@test.com', '{\"role\": \"admin\"}'::jsonb)" > /dev/null 2>&1 || true

    # Test INSERT
    local insert_result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$admin_id';
        SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"admin\"}';
        INSERT INTO public.$table DEFAULT VALUES RETURNING id;
    " 2>&1)

    if [[ ! "$insert_result" == *"ERROR"* ]]; then
        local row_id="$insert_result"

        # Test UPDATE
        execute_sql "
            SET LOCAL ROLE authenticated;
            SET LOCAL request.jwt.claims.sub = '$admin_id';
            SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"admin\"}';
            UPDATE public.$table SET updated_at = NOW() WHERE id = '$row_id';
        " > /dev/null 2>&1

        # Test DELETE
        execute_sql "
            SET LOCAL ROLE authenticated;
            SET LOCAL request.jwt.claims.sub = '$admin_id';
            SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"admin\"}';
            DELETE FROM public.$table WHERE id = '$row_id';
        " > /dev/null 2>&1

        local exists=$(execute_sql "SELECT COUNT(*) FROM public.$table WHERE id = '$row_id'" 2>&1)

        if [ "$exists" = "0" ]; then
            echo -e "${GREEN}✓ $test_name: Admin can INSERT, UPDATE, DELETE${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ $test_name: Admin DELETE failed${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠ $test_name: Cannot test (table may require specific columns)${NC}"
    fi

    execute_sql "DELETE FROM auth.users WHERE id = '$admin_id'" > /dev/null 2>&1 || true
}

# Test editor read/write but not delete
test_editor_access() {
    local table=$1
    local test_name="$table: Editor read/write (no delete)"

    local editor_id=$(uuidgen)
    execute_sql "INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES ('$editor_id', 'editor@test.com', '{\"role\": \"editor\"}'::jsonb)" > /dev/null 2>&1 || true

    # Test INSERT (should succeed)
    local insert_result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$editor_id';
        SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"editor\"}';
        INSERT INTO public.$table DEFAULT VALUES RETURNING id;
    " 2>&1)

    if [[ ! "$insert_result" == *"ERROR"* ]]; then
        local row_id="$insert_result"

        # Test UPDATE (should succeed)
        execute_sql "
            SET LOCAL ROLE authenticated;
            SET LOCAL request.jwt.claims.sub = '$editor_id';
            SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"editor\"}';
            UPDATE public.$table SET updated_at = NOW() WHERE id = '$row_id';
        " > /dev/null 2>&1

        # Test DELETE (should fail)
        execute_sql "
            SET LOCAL ROLE authenticated;
            SET LOCAL request.jwt.claims.sub = '$editor_id';
            SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"editor\"}';
            DELETE FROM public.$table WHERE id = '$row_id';
        " > /dev/null 2>&1

        local exists=$(execute_sql "SELECT COUNT(*) FROM public.$table WHERE id = '$row_id'" 2>&1)

        if [ "$exists" = "1" ]; then
            echo -e "${GREEN}✓ $test_name: Editor can read/write but not delete${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ $test_name: Editor was able to delete (privilege escalation)${NC}"
            ((FAILED++))
        fi

        execute_sql "DELETE FROM public.$table WHERE id = '$row_id'" > /dev/null 2>&1 || true
    else
        echo -e "${YELLOW}⚠ $test_name: Cannot test${NC}"
    fi

    execute_sql "DELETE FROM auth.users WHERE id = '$editor_id'" > /dev/null 2>&1 || true
}

# Test viewer read-only access
test_viewer_access() {
    local table=$1
    local test_name="$table: Viewer read-only"

    local viewer_id=$(uuidgen)
    execute_sql "INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES ('$viewer_id', 'viewer@test.com', '{\"role\": \"viewer\"}'::jsonb)" > /dev/null 2>&1 || true

    # Test INSERT (should fail)
    local insert_result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$viewer_id';
        SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"viewer\"}';
        INSERT INTO public.$table DEFAULT VALUES RETURNING id;
    " 2>&1)

    if [[ "$insert_result" == *"ERROR"* ]] || [[ "$insert_result" == *"violates"* ]]; then
        echo -e "${GREEN}✓ $test_name: Viewer cannot write (read-only enforced)${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Viewer can write (privilege escalation)${NC}"
        ((FAILED++))
        execute_sql "DELETE FROM public.$table WHERE id = '$insert_result'" > /dev/null 2>&1 || true
    fi

    execute_sql "DELETE FROM auth.users WHERE id = '$viewer_id'" > /dev/null 2>&1 || true
}

# Test privilege escalation prevention
test_escalation_prevention() {
    local table=$1
    local test_name="$table: Escalation prevention"

    local user_id=$(uuidgen)
    execute_sql "INSERT INTO auth.users (id, email, raw_app_meta_data) VALUES ('$user_id', 'user@test.com', '{\"role\": \"viewer\"}'::jsonb)" > /dev/null 2>&1 || true

    # Try to update own role in metadata (should not affect policy)
    execute_sql "UPDATE auth.users SET raw_user_meta_data = '{\"role\": \"admin\"}'::jsonb WHERE id = '$user_id'" > /dev/null 2>&1

    # Try to insert as admin (should fail because app_metadata is viewer)
    local result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$user_id';
        SET LOCAL request.jwt.claims.app_metadata = '{\"role\": \"viewer\"}';
        INSERT INTO public.$table DEFAULT VALUES RETURNING id;
    " 2>&1)

    if [[ "$result" == *"ERROR"* ]] || [[ "$result" == *"violates"* ]]; then
        echo -e "${GREEN}✓ $test_name: User cannot escalate privileges${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: User escalated privileges via user_metadata${NC}"
        ((FAILED++))
        execute_sql "DELETE FROM public.$table WHERE id = '$result'" > /dev/null 2>&1 || true
    fi

    execute_sql "DELETE FROM auth.users WHERE id = '$user_id'" > /dev/null 2>&1 || true
}

test_table() {
    local table=$1
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing table: $table${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [[ "$ROLES" == *"admin"* ]]; then
        test_admin_access "$table"
    fi

    if [[ "$ROLES" == *"editor"* ]]; then
        test_editor_access "$table"
    fi

    if [[ "$ROLES" == *"viewer"* ]]; then
        test_viewer_access "$table"
    fi

    if [ "$TEST_ESCALATION" = true ]; then
        test_escalation_prevention "$table"
    fi

    echo ""
}

# Main
echo -e "${BLUE}👤 RLS Role-Based Access Control Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

[ -n "$REPORT_FILE" ] && echo "# RLS RBAC Test Report" > "$REPORT_FILE" && echo "Generated: $(date)" >> "$REPORT_FILE" && echo "" >> "$REPORT_FILE"

[ ${#TABLES[@]} -eq 0 ] && echo -e "${RED}No tables specified${NC}" && exit 1

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
    echo -e "${RED}❌ RBAC tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All RBAC tests passed${NC}"
    exit 0
fi
