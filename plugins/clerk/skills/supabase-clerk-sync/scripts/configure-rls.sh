#!/bin/bash
# Configure Row Level Security policies for Clerk authentication
# Usage: ./configure-rls.sh [table-name]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Clerk RLS Policy Generator${NC}"
echo "======================================"

# Get table name
if [ -z "$1" ]; then
  echo "Usage: ./configure-rls.sh <table-name>"
  echo ""
  echo "Examples:"
  echo "  ./configure-rls.sh users"
  echo "  ./configure-rls.sh posts"
  echo "  ./configure-rls.sh organizations"
  exit 1
fi

TABLE_NAME="$1"

echo "Generating RLS policies for table: $TABLE_NAME"
echo ""

# Ask for policy type
echo "Select RLS policy type:"
echo "  1) User-owned resources (user can only access their own data)"
echo "  2) Organization-based access (user can access org data)"
echo "  3) Role-based access (admin, editor, viewer)"
echo "  4) Public read, authenticated write"
echo "  5) Custom policy"
echo ""
read -p "Choose policy type (1-5): " POLICY_TYPE

OUTPUT_FILE="rls-${TABLE_NAME}.sql"

# Generate policy based on type
case $POLICY_TYPE in
  1)
    echo -e "\n${GREEN}Generating user-owned resource policies${NC}"
    cat > "$OUTPUT_FILE" <<EOF
-- RLS Policies for $TABLE_NAME (User-Owned Resources)
-- Users can only access their own data

-- Enable RLS
ALTER TABLE $TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "${TABLE_NAME}_select_own" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_insert_own" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_update_own" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_delete_own" ON $TABLE_NAME;

-- SELECT: Users can view their own records
CREATE POLICY "${TABLE_NAME}_select_own"
  ON $TABLE_NAME
  FOR SELECT
  USING (clerk_id = auth.clerk_user_id());

-- INSERT: Users can create records for themselves
CREATE POLICY "${TABLE_NAME}_insert_own"
  ON $TABLE_NAME
  FOR INSERT
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- UPDATE: Users can update their own records
CREATE POLICY "${TABLE_NAME}_update_own"
  ON $TABLE_NAME
  FOR UPDATE
  USING (clerk_id = auth.clerk_user_id())
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- DELETE: Users can delete their own records
CREATE POLICY "${TABLE_NAME}_delete_own"
  ON $TABLE_NAME
  FOR DELETE
  USING (clerk_id = auth.clerk_user_id());

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON $TABLE_NAME TO authenticated;
GRANT SELECT ON $TABLE_NAME TO anon;
EOF
    ;;

  2)
    echo -e "\n${GREEN}Generating organization-based policies${NC}"
    cat > "$OUTPUT_FILE" <<EOF
-- RLS Policies for $TABLE_NAME (Organization-Based Access)
-- Users can access data from their organization

-- Enable RLS
ALTER TABLE $TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "${TABLE_NAME}_org_select" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_org_insert" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_org_update" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_org_delete" ON $TABLE_NAME;

-- SELECT: Users can view org data
CREATE POLICY "${TABLE_NAME}_org_select"
  ON $TABLE_NAME
  FOR SELECT
  USING (clerk_org_id = auth.clerk_org_id());

-- INSERT: Users can create org data
CREATE POLICY "${TABLE_NAME}_org_insert"
  ON $TABLE_NAME
  FOR INSERT
  WITH CHECK (clerk_org_id = auth.clerk_org_id());

-- UPDATE: Org members can update (consider adding role check)
CREATE POLICY "${TABLE_NAME}_org_update"
  ON $TABLE_NAME
  FOR UPDATE
  USING (
    clerk_org_id = auth.clerk_org_id() AND
    auth.clerk_role() IN ('admin', 'editor')
  )
  WITH CHECK (clerk_org_id = auth.clerk_org_id());

-- DELETE: Only admins can delete
CREATE POLICY "${TABLE_NAME}_org_delete"
  ON $TABLE_NAME
  FOR DELETE
  USING (
    clerk_org_id = auth.clerk_org_id() AND
    auth.is_clerk_admin()
  );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON $TABLE_NAME TO authenticated;
EOF
    ;;

  3)
    echo -e "\n${GREEN}Generating role-based policies${NC}"
    cat > "$OUTPUT_FILE" <<EOF
-- RLS Policies for $TABLE_NAME (Role-Based Access)
-- Different permissions for admin, editor, viewer roles

-- Enable RLS
ALTER TABLE $TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "${TABLE_NAME}_admin_all" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_editor_write" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_viewer_read" ON $TABLE_NAME;

-- Admin: Full access
CREATE POLICY "${TABLE_NAME}_admin_all"
  ON $TABLE_NAME
  FOR ALL
  USING (auth.is_clerk_admin())
  WITH CHECK (auth.is_clerk_admin());

-- Editor: Can read and write
CREATE POLICY "${TABLE_NAME}_editor_write"
  ON $TABLE_NAME
  FOR ALL
  USING (auth.clerk_role() IN ('admin', 'editor'))
  WITH CHECK (auth.clerk_role() IN ('admin', 'editor'));

-- Viewer: Read-only access
CREATE POLICY "${TABLE_NAME}_viewer_read"
  ON $TABLE_NAME
  FOR SELECT
  USING (auth.clerk_role() IN ('admin', 'editor', 'viewer'));

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON $TABLE_NAME TO authenticated;
EOF
    ;;

  4)
    echo -e "\n${GREEN}Generating public read, authenticated write policies${NC}"
    cat > "$OUTPUT_FILE" <<EOF
-- RLS Policies for $TABLE_NAME (Public Read, Authenticated Write)

-- Enable RLS
ALTER TABLE $TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "${TABLE_NAME}_public_read" ON $TABLE_NAME;
DROP POLICY IF EXISTS "${TABLE_NAME}_auth_write" ON $TABLE_NAME;

-- Public: Anyone can read
CREATE POLICY "${TABLE_NAME}_public_read"
  ON $TABLE_NAME
  FOR SELECT
  USING (true);

-- Authenticated: Can insert/update/delete own records
CREATE POLICY "${TABLE_NAME}_auth_write"
  ON $TABLE_NAME
  FOR ALL
  USING (clerk_id = auth.clerk_user_id())
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- Grant permissions
GRANT SELECT ON $TABLE_NAME TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON $TABLE_NAME TO authenticated;
EOF
    ;;

  5)
    echo -e "\n${GREEN}Generating custom policy template${NC}"
    cat > "$OUTPUT_FILE" <<EOF
-- RLS Policies for $TABLE_NAME (Custom)
-- Customize these policies based on your requirements

-- Enable RLS
ALTER TABLE $TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Example: Custom policy with multiple conditions
DROP POLICY IF EXISTS "${TABLE_NAME}_custom" ON $TABLE_NAME;

CREATE POLICY "${TABLE_NAME}_custom"
  ON $TABLE_NAME
  FOR SELECT
  USING (
    -- Option 1: User owns the record
    clerk_id = auth.clerk_user_id()
    OR
    -- Option 2: User is in the same organization
    clerk_org_id = auth.clerk_org_id()
    OR
    -- Option 3: User has admin role
    auth.is_clerk_admin()
    OR
    -- Option 4: Record is public
    is_public = true
  );

-- Add more policies as needed
-- CREATE POLICY "${TABLE_NAME}_insert" ON $TABLE_NAME FOR INSERT ...
-- CREATE POLICY "${TABLE_NAME}_update" ON $TABLE_NAME FOR UPDATE ...
-- CREATE POLICY "${TABLE_NAME}_delete" ON $TABLE_NAME FOR DELETE ...

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON $TABLE_NAME TO authenticated;
EOF
    ;;

  *)
    echo -e "${RED}Invalid option${NC}"
    exit 1
    ;;
esac

echo -e "${GREEN}✓ RLS policies generated${NC}"
echo ""
echo "File: $OUTPUT_FILE"
echo ""
echo "Review the policies, then apply with:"
echo "  supabase db execute < $OUTPUT_FILE"
echo ""
echo "Or execute in Supabase SQL Editor"
echo ""

# Generate test SQL
TEST_FILE="test-rls-${TABLE_NAME}.sql"
cat > "$TEST_FILE" <<'EOF'
-- Test RLS Policies
-- Run these queries to verify policies work correctly

-- Test 1: Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'TABLE_NAME_PLACEHOLDER';

-- Test 2: List all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'TABLE_NAME_PLACEHOLDER';

-- Test 3: Simulate user query (replace with actual JWT claims)
SET request.jwt.claims = '{
  "sub": "user_test123",
  "email": "test@example.com",
  "role": "user",
  "org_id": "org_test456"
}';

-- Try to SELECT as this user
SELECT * FROM TABLE_NAME_PLACEHOLDER LIMIT 5;

-- Reset
RESET request.jwt.claims;
EOF

sed -i "s/TABLE_NAME_PLACEHOLDER/$TABLE_NAME/g" "$TEST_FILE"

echo "Test queries saved to: $TEST_FILE"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  1. Review policies before applying to production"
echo "  2. Test with different user roles and scenarios"
echo "  3. Ensure helper functions (auth.clerk_user_id, etc.) exist"
echo "  4. Run ./setup-sync.sh first if you haven't already"
echo ""
echo -e "${GREEN}Next: Run ./create-webhooks.sh to enable user sync${NC}"
