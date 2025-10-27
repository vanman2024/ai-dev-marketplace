#!/bin/bash
# Test multi-tenant isolation in RLS policies
# Verifies that organizations cannot access each other's data

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
REPORT_FILE=""
TEST_MEMBERS=false
ORG1_ID=""
ORG2_ID=""
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
        --test-members)
            TEST_MEMBERS=true
            shift
            ;;
        --org1)
            ORG1_ID="$2"
            shift 2
            ;;
        --org2)
            ORG2_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [table1] [table2] ... [options]"
            echo ""
            echo "Options:"
            echo "  --report FILE      Generate report to FILE"
            echo "  --test-members     Test member access patterns"
            echo "  --org1 UUID        Use specific UUID for org 1"
            echo "  --org2 UUID        Use specific UUID for org 2"
            echo "  --help             Show this help"
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

# Function to create test organizations and users
create_test_data() {
    echo -e "${YELLOW}Setting up test data...${NC}"

    # Create test users
    if [ -z "$USER1_ID" ]; then
        USER1_ID=$(uuidgen)
        execute_sql "INSERT INTO auth.users (id, email) VALUES ('$USER1_ID', 'org1-user@example.com') ON CONFLICT DO NOTHING" > /dev/null 2>&1 || true
    fi

    if [ -z "$USER2_ID" ]; then
        USER2_ID=$(uuidgen)
        execute_sql "INSERT INTO auth.users (id, email) VALUES ('$USER2_ID', 'org2-user@example.com') ON CONFLICT DO NOTHING" > /dev/null 2>&1 || true
    fi

    # Create test organizations
    if [ -z "$ORG1_ID" ]; then
        ORG1_ID=$(uuidgen)
        execute_sql "INSERT INTO public.organizations (id, name) VALUES ('$ORG1_ID', 'Test Org 1') ON CONFLICT DO NOTHING" > /dev/null 2>&1 || true
    fi

    if [ -z "$ORG2_ID" ]; then
        ORG2_ID=$(uuidgen)
        execute_sql "INSERT INTO public.organizations (id, name) VALUES ('$ORG2_ID', 'Test Org 2') ON CONFLICT DO NOTHING" > /dev/null 2>&1 || true
    fi

    # Add users to their organizations
    execute_sql "
        INSERT INTO public.organization_members (organization_id, user_id, role)
        VALUES ('$ORG1_ID', '$USER1_ID', 'owner')
        ON CONFLICT DO NOTHING
    " > /dev/null 2>&1 || true

    execute_sql "
        INSERT INTO public.organization_members (organization_id, user_id, role)
        VALUES ('$ORG2_ID', '$USER2_ID', 'owner')
        ON CONFLICT DO NOTHING
    " > /dev/null 2>&1 || true

    echo -e "${BLUE}Org 1: $ORG1_ID (User: $USER1_ID)${NC}"
    echo -e "${BLUE}Org 2: $ORG2_ID (User: $USER2_ID)${NC}"
    echo ""
}

# Function to check if table has organization_id column
check_org_column() {
    local table=$1
    local has_org=$(execute_sql "
        SELECT COUNT(*)
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = '$table'
        AND column_name = 'organization_id'
    ")
    echo "$has_org"
}

# Function to test SELECT isolation between orgs
test_org_select_isolation() {
    local table=$1
    local test_name="$table: Org SELECT isolation"

    # Check if table has organization_id
    local has_org=$(check_org_column "$table")
    if [ "$has_org" = "0" ]; then
        echo -e "${YELLOW}⚠ $test_name: No organization_id column, skipping${NC}"
        return
    fi

    # Create test data for org 1
    local insert_result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (organization_id) VALUES ('$ORG1_ID') RETURNING id;
    " 2>&1)

    if [[ "$insert_result" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot insert test data, skipping${NC}"
        return
    fi

    # Try to read as org 2 user
    local count=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        SELECT COUNT(*) FROM public.$table WHERE organization_id = '$ORG1_ID';
    " 2>&1)

    if [ "$count" = "0" ]; then
        echo -e "${GREEN}✓ $test_name: Org 2 user cannot read Org 1 data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Org 2 user can read Org 1 data (found $count rows)${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - Cross-org data leak detected" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE organization_id = '$ORG1_ID'" > /dev/null 2>&1 || true
}

# Function to test INSERT with wrong org_id
test_org_insert_isolation() {
    local table=$1
    local test_name="$table: Org INSERT isolation"

    local has_org=$(check_org_column "$table")
    if [ "$has_org" = "0" ]; then
        echo -e "${YELLOW}⚠ $test_name: No organization_id column, skipping${NC}"
        return
    fi

    # Try to insert as org 2 user with org 1's ID
    local result=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        INSERT INTO public.$table (organization_id) VALUES ('$ORG1_ID');
    " 2>&1)

    if [[ "$result" == *"ERROR"* ]] || [[ "$result" == *"violates"* ]]; then
        echo -e "${GREEN}✓ $test_name: Org 2 user cannot insert data for Org 1${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Org 2 user can insert data claiming Org 1${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - Cross-org data insertion allowed" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE organization_id = '$ORG1_ID'" > /dev/null 2>&1 || true
}

# Function to test UPDATE isolation between orgs
test_org_update_isolation() {
    local table=$1
    local test_name="$table: Org UPDATE isolation"

    local has_org=$(check_org_column "$table")
    if [ "$has_org" = "0" ]; then
        echo -e "${YELLOW}⚠ $test_name: No organization_id column, skipping${NC}"
        return
    fi

    # Create data as org 1 user
    local id=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (organization_id) VALUES ('$ORG1_ID') RETURNING id;
    " 2>&1)

    if [[ "$id" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot create test data, skipping${NC}"
        return
    fi

    # Try to update as org 2 user
    execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        UPDATE public.$table SET organization_id = '$ORG2_ID' WHERE id = '$id';
    " > /dev/null 2>&1

    # Check if update was blocked
    local org_id=$(execute_sql "SELECT organization_id FROM public.$table WHERE id = '$id'" 2>&1)

    if [ "$org_id" = "$ORG1_ID" ]; then
        echo -e "${GREEN}✓ $test_name: Org 2 user cannot update Org 1 data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Org 2 user modified Org 1 data${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - Cross-org data modification allowed" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE id = '$id'" > /dev/null 2>&1 || true
}

# Function to test DELETE isolation between orgs
test_org_delete_isolation() {
    local table=$1
    local test_name="$table: Org DELETE isolation"

    local has_org=$(check_org_column "$table")
    if [ "$has_org" = "0" ]; then
        echo -e "${YELLOW}⚠ $test_name: No organization_id column, skipping${NC}"
        return
    fi

    # Create data as org 1 user
    local id=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (organization_id) VALUES ('$ORG1_ID') RETURNING id;
    " 2>&1)

    if [[ "$id" == *"ERROR"* ]]; then
        echo -e "${YELLOW}⚠ $test_name: Cannot create test data, skipping${NC}"
        return
    fi

    # Try to delete as org 2 user
    execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER2_ID';
        DELETE FROM public.$table WHERE id = '$id';
    " > /dev/null 2>&1

    # Check if data still exists
    local exists=$(execute_sql "SELECT COUNT(*) FROM public.$table WHERE id = '$id'" 2>&1)

    if [ "$exists" = "1" ]; then
        echo -e "${GREEN}✓ $test_name: Org 2 user cannot delete Org 1 data${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Org 2 user deleted Org 1 data${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - Cross-org data deletion allowed" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE id = '$id'" > /dev/null 2>&1 || true
}

# Function to test member access (user removed from org loses access)
test_member_removal() {
    local table=$1
    local test_name="$table: Member removal access revocation"

    local has_org=$(check_org_column "$table")
    if [ "$has_org" = "0" ]; then
        return
    fi

    # Create temporary user and add to org 1
    local temp_user=$(uuidgen)
    execute_sql "INSERT INTO auth.users (id, email) VALUES ('$temp_user', 'temp@example.com')" > /dev/null 2>&1 || true
    execute_sql "INSERT INTO public.organization_members (organization_id, user_id, role) VALUES ('$ORG1_ID', '$temp_user', 'member')" > /dev/null 2>&1 || true

    # Create data as org 1 owner
    local id=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$USER1_ID';
        INSERT INTO public.$table (organization_id) VALUES ('$ORG1_ID') RETURNING id;
    " 2>&1)

    if [[ "$id" == *"ERROR"* ]]; then
        return
    fi

    # Verify temp user can access (should succeed)
    local count_before=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$temp_user';
        SELECT COUNT(*) FROM public.$table WHERE organization_id = '$ORG1_ID';
    " 2>&1)

    # Remove user from org
    execute_sql "DELETE FROM public.organization_members WHERE user_id = '$temp_user'" > /dev/null 2>&1

    # Verify temp user cannot access after removal
    local count_after=$(execute_sql "
        SET LOCAL ROLE authenticated;
        SET LOCAL request.jwt.claims.sub = '$temp_user';
        SELECT COUNT(*) FROM public.$table WHERE organization_id = '$ORG1_ID';
    " 2>&1)

    if [ "$count_before" != "0" ] && [ "$count_after" = "0" ]; then
        echo -e "${GREEN}✓ $test_name: Removed member loses access immediately${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ $test_name: Removed member still has access (before: $count_before, after: $count_after)${NC}"
        ((FAILED++))

        if [ -n "$REPORT_FILE" ]; then
            echo "FAIL: $test_name - Removed members retain access" >> "$REPORT_FILE"
        fi
    fi

    # Cleanup
    execute_sql "DELETE FROM public.$table WHERE id = '$id'" > /dev/null 2>&1 || true
    execute_sql "DELETE FROM auth.users WHERE id = '$temp_user'" > /dev/null 2>&1 || true
}

# Function to test a table
test_table() {
    local table=$1

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Testing table: $table${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    test_org_select_isolation "$table"
    test_org_insert_isolation "$table"
    test_org_update_isolation "$table"
    test_org_delete_isolation "$table"

    if [ "$TEST_MEMBERS" = true ]; then
        test_member_removal "$table"
    fi

    echo ""
}

# Main execution
echo -e "${BLUE}🏢 RLS Multi-Tenant Isolation Test Suite${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Initialize report
if [ -n "$REPORT_FILE" ]; then
    echo "# RLS Multi-Tenant Isolation Test Report" > "$REPORT_FILE"
    echo "Generated: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
fi

# Create test data
create_test_data

# Check tables specified
if [ ${#TABLES[@]} -eq 0 ]; then
    echo -e "${RED}No tables specified. Provide table names as arguments.${NC}"
    exit 1
fi

# Run tests
for table in "${TABLES[@]}"; do
    test_table "$table"
done

# Cleanup test data
echo -e "${YELLOW}Cleaning up test data...${NC}"
execute_sql "DELETE FROM public.organization_members WHERE organization_id IN ('$ORG1_ID', '$ORG2_ID')" > /dev/null 2>&1 || true
execute_sql "DELETE FROM public.organizations WHERE id IN ('$ORG1_ID', '$ORG2_ID')" > /dev/null 2>&1 || true
execute_sql "DELETE FROM auth.users WHERE id IN ('$USER1_ID', '$USER2_ID')" > /dev/null 2>&1 || true
echo ""

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
fi

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Multi-tenant isolation tests failed. Security issues detected.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All multi-tenant isolation tests passed!${NC}"
    exit 0
fi
