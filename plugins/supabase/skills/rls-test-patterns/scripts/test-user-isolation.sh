#!/bin/bash
# Test user isolation in RLS policies
# Verifies that users can only access their own data

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPORT_FILE=""
TEST_ALL=false
USER1_ID=""
USER2_ID=""
PASSED=0
FAILED=0
TABLES=()

# Load environment
if [ -f .env ]; then
    source .env
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --report)
            REPORT_FILE="$2"
            shift 2
            ;;
        --all)
            TEST_ALL=true
            shift
            ;;
        --user1)
            USER1_ID="$2"
            shift 2
            ;;
        --user2)
            USER2_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [table1] [table2] ... [options]"
            echo ""
            echo "Options:"
            echo "  --report FILE    Generate report to FILE"
            echo "  --all            Test all tables with user_id column"
            echo "  --user1 UUID     Use specific UUID for user 1"
            echo "  --user2 UUID     Use specific UUID for user 2"
            echo "  --help           Show this help"
            exit 0
            ;;
        *)
            TABLES+=("$1")
            shift
            ;;
    esac
done

# Check required environment variables
if [ -z "${SUPABASE_DB_URL:-}" ]; then
    echo -e "${RED}Error: SUPABASE_DB_URL not set${NC}"
    exit 1
fi

# Function to execute SQL
execute_sql() {
    local sql="$1"
    psql "$SUPABASE_DB_URL" -t -A -c "$sql" 2>&1
}

# Function to create test users if not provided
create_test_users() {
    if [ -z "$USER1_ID" ]; then
        USER1_ID=$(execute_sql "SELECT id FROM auth.users WHERE email = 'test-isolation-user1@example.com' LIMIT 1")
        if [ -z "$USER1_ID" ]; then
            echo -e "${YELLOW}Creating test user 1...${NC}"
            # Note: In production, use Supabase Auth API
            USER1_ID=$(uuidgen)
            execute_sql "INSERT INTO auth.users (id, email) VALUES ('$USER1_ID', 'test-isolation-user1@example.com') ON CONFLICT DO NOTHING" > /dev/null
        fi
    fi

    if [ -z "$USER2_ID" ]; then
        USER2_ID=$(execute_sql "SELECT id FROM auth.users WHERE email = 'test-isolation-user2@example.com' LIMIT 1")
        if [ -z "$USER2_ID" ]; then
            echo -e "${YELLOW}Creating test user 2...${NC}"
            USER2_ID=$(uuidgen)
            execute_sql "INSERT INTO auth.users (id, email) VALUES ('$USER2_ID', 'test-isolation-user2@example.com') ON CONFLICT DO NOTHING" > /dev/null
        fi
    fi

    echo -e "${BLUE}Test User 1: $USER1_ID${NC}"
    echo -e "${BLUE}Test User 2: $USER2_ID${NC}"
    echo ""
}

# Function to get all tables with user_id column
get_tables_with_user_id() {
    execute_sql "
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND column_name = 'user_id'
        ORDER BY table_name
    " | tr '\n' ' '
}

# Function to check if table has RLS enabled
check_rls_enabled() {
    local table=$1
    local enabled=$(execute_sql "
        SELECT relrowsecurity::int
        FROM pg_class
        WHERE oid = 'public.$table'::regclass
    ")
    echo "$enabled"
}

# Function to test SELECT isolation
test_select_isolation() {
    local table=$1
    local test_name="$table: SELECT isolation"

    # Create test data for user 1
    local insert_result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (user_id) VALUES ('$USER1_ID') RETURNING id;
    " 2>&1)

    if [[ "$insert_result" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot insert test data, skipping${NC}"
        return
    fi

    # Try to read as user 2
    local count=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        SELECT COUNT(*) FROM public.$table WHERE user_id = '$USER1_ID';
    " 2>&1)

    if [ "$count" = "0" ]; then
        echo -e "${GREEN}✓ $test_name: User 2 cannot read User 1's data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: User 2 can read User 1's data (found $count rows)${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - User 2 accessed $count of User 1's rows" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE user_id = '$USER1_ID'" > /dev/null 2>&1 || true
}

# Function to test INSERT isolation
test_insert_isolation() {
    local table=$1
    local test_name="$table: INSERT isolation"

    # Try to insert as user 2 with user 1's ID
    local result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        INSERT INTO public.$table (user_id) VALUES ('$USER1_ID');
    " 2>&1)

    if [[ "$result" == *"ERROR"* ]] || [[ "$result" == *"violates"* ]]; then
        echo -e "${GREEN}✓ $test_name: User 2 cannot insert data for User 1${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: User 2 can insert data claiming to be User 1${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - User 2 inserted data with User 1's ID" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE user_id = '$USER1_ID'" > /dev/null 2>&1 || true
}

# Function to test UPDATE isolation
test_update_isolation() {
    local table=$1
    local test_name="$table: UPDATE isolation"

    # Create data as user 1
    local id=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (user_id) VALUES ('$USER1_ID') RETURNING id;
    " 2>&1)

    if [[ "$id" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot create test data, skipping${NC}"
        return
    fi

    # Try to update as user 2
    local result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        UPDATE public.$table SET user_id = '$USER2_ID' WHERE id = '$id';
    " 2>&1)

    # Check if update was blocked
    local updated_user=$(execute_sql "SELECT user_id FROM public.$table WHERE id = '$id'" 2>&1)

    if [ "$updated_user" = "$USER1_ID" ]; then
        echo -e "${GREEN}✓ $test_name: User 2 cannot update User 1's data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: User 2 modified User 1's data${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - User 2 updated User 1's data" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE id = '$id'" > /dev/null 2>&1 || true
}

# Function to test DELETE isolation
test_delete_isolation() {
    local table=$1
    local test_name="$table: DELETE isolation"

    # Create data as user 1
    local id=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (user_id) VALUES ('$USER1_ID') RETURNING id;
    " 2>&1)

    if [[ "$id" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot create test data, skipping${NC}"
        return
    fi

    # Try to delete as user 2
    execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        DELETE FROM public.$table WHERE id = '$id';
    " > /dev/null 2>&1

    # Check if data still exists
    local exists=$(execute_sql "SELECT COUNT(*) FROM public.$table WHERE id = '$id'" 2>&1)

    if [ "$exists" = "1" ]; then
        echo -e "${GREEN}✓ $test_name: User 2 cannot delete User 1's data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: User 2 deleted User 1's data${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - User 2 deleted User 1's data" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE id = '$id'" > /dev/null 2>&1 || true
}

# Function to test a table
test_table() {
    local table=$1

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing table: $table${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if RLS is enabled
    local rls_enabled=$(check_rls_enabled "$table")
    if [ "$rls_enabled" != "1" ]; then
        echo -e "${RED}✗ RLS not enabled on $table${NC}"
        ((FAILED++))
        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $table - RLS not enabled" >> "$REPORT_FILE"
        fi
        return
    fi

    test_select_isolation "$table"
    test_insert_isolation "$table"
    test_update_isolation "$table"
    test_delete_isolation "$table"
    echo ""
}

# Main execution
echo -e "${BLUE}🔒 RLS User Isolation Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Initialize report file
if [ -n "$REPORT_FILE" ]; then
    echo "# RLS User Isolation Test Report" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Create test users
create_test_users

# Determine which tables to test
if [ "$TEST_ALL" = true ]; then
    TABLES=($(get_tables_with_user_id))
    echo -e "${BLUE}Testing all tables with user_id column: ${TABLES[*]}${NC}"
    echo ""
fi

if [ ${#TABLES[@]} -eq 0 ]; then
    echo -e "${RED}No tables specified. Use table names as arguments or --all flag.${NC}"
    exit 1
fi

# Run tests on each table
for table in "${TABLES[@]}"; do
    test_table "$table"
done

# Print summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Tables tested: ${#TABLES[@]}"
echo -e "  Total tests: $((PASSED + FAILED))"
echo -e "  ${GREEN}Passed: $PASSED ✓${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "  ${RED}Failed: $FAILED ✗${NC}"
else
    echo -e "  Failed: $FAILED"
fi
echo ""

if [ -n "$REPORT_FILE" ]; then
    echo "" >> "$REPORT_FILE"
    echo "## Summary" >> "$REPORT_FILE"
    echo "- Tables tested: ${#TABLES[@]}" >> "$REPORT_FILE"
    echo "- Passed: $PASSED" >> "$REPORT_FILE"
    echo "- Failed: $FAILED" >> "$REPORT_FILE"
    echo -e "${BLUE}Report written to: $REPORT_FILE${NC}"
fi

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ User isolation tests failed. Security issues detected.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All user isolation tests passed!${NC}"
    exit 0
fi
