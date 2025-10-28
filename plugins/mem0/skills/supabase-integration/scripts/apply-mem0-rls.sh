#!/bin/bash
# Apply Row Level Security policies to Mem0 tables

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
RLS_PATTERN=${MEM0_RLS_PATTERN:-user-isolation}  # user-isolation, multi-tenant, or hybrid

echo "Applying RLS policies to Mem0 tables..."
echo ""
echo "Security pattern: $RLS_PATTERN"
echo ""

# Check prerequisites
if [ -z "$SUPABASE_DB_URL" ]; then
    echo -e "${RED}✗${NC} SUPABASE_DB_URL not set"
    exit 1
fi

echo "Applying RLS policies..."

psql "$SUPABASE_DB_URL" <<SQL
-- Enable RLS on all Mem0 tables
ALTER TABLE memories ENABLE ROW LEVEL SECURITY;

DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_relationships') THEN
        ALTER TABLE memory_relationships ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_history') THEN
        ALTER TABLE memory_history ENABLE ROW LEVEL SECURITY;
    END IF;
END \$\$;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users access own memories" ON memories;
DROP POLICY IF EXISTS "Users insert own memories" ON memories;
DROP POLICY IF EXISTS "Users update own memories" ON memories;
DROP POLICY IF EXISTS "Users delete own memories" ON memories;
DROP POLICY IF EXISTS "Service role bypass" ON memories;

-- User isolation policies (default)
-- Users can only access memories where user_id matches their auth.uid()
CREATE POLICY "Users access own memories"
ON memories FOR SELECT
TO authenticated
USING ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "Users insert own memories"
ON memories FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "Users update own memories"
ON memories FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()::text) = user_id)
WITH CHECK ((SELECT auth.uid()::text) = user_id);

CREATE POLICY "Users delete own memories"
ON memories FOR DELETE
TO authenticated
USING ((SELECT auth.uid()::text) = user_id);

-- Service role bypass (for admin operations)
CREATE POLICY "Service role bypass"
ON memories FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

$(if [ "$RLS_PATTERN" = "multi-tenant" ] || [ "$RLS_PATTERN" = "hybrid" ]; then
cat <<MULTITENANT_SQL
-- Multi-tenant policies (organization-based)
-- Assumes metadata contains org_id and org_members table exists

-- Allow access if user is member of organization
DROP POLICY IF EXISTS "Organization members access memories" ON memories;
CREATE POLICY "Organization members access memories"
ON memories FOR SELECT
TO authenticated
USING (
    metadata->>'org_id' IS NOT NULL
    AND (
        -- User is org member
        EXISTS (
            SELECT 1 FROM org_members
            WHERE org_members.user_id = (SELECT auth.uid()::text)
            AND org_members.org_id = memories.metadata->>'org_id'
        )
        OR
        -- Or user owns the memory
        (SELECT auth.uid()::text) = user_id
    )
);
MULTITENANT_SQL
fi)

-- Public agent knowledge policies
-- Agent memories without user_id are readable by all authenticated users
DROP POLICY IF EXISTS "Public agent knowledge readable" ON memories;
CREATE POLICY "Public agent knowledge readable"
ON memories FOR SELECT
TO authenticated
USING (agent_id IS NOT NULL AND user_id IS NULL);

-- RLS policies for memory_relationships table
DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_relationships') THEN
        DROP POLICY IF EXISTS "Users access own relationships" ON memory_relationships;
        DROP POLICY IF EXISTS "Users manage own relationships" ON memory_relationships;
        DROP POLICY IF EXISTS "Service role bypass relationships" ON memory_relationships;

        CREATE POLICY "Users access own relationships"
        ON memory_relationships FOR SELECT
        TO authenticated
        USING ((SELECT auth.uid()::text) = user_id);

        CREATE POLICY "Users manage own relationships"
        ON memory_relationships FOR ALL
        TO authenticated
        USING ((SELECT auth.uid()::text) = user_id)
        WITH CHECK ((SELECT auth.uid()::text) = user_id);

        CREATE POLICY "Service role bypass relationships"
        ON memory_relationships FOR ALL
        TO service_role
        USING (true)
        WITH CHECK (true);
    END IF;
END \$\$;

-- RLS policies for memory_history table
DO \$\$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'memory_history') THEN
        DROP POLICY IF EXISTS "Users view own history" ON memory_history;
        DROP POLICY IF EXISTS "Service role bypass history" ON memory_history;

        -- Users can only view their own history
        CREATE POLICY "Users view own history"
        ON memory_history FOR SELECT
        TO authenticated
        USING ((SELECT auth.uid()::text) = user_id);

        -- Service role can view all history
        CREATE POLICY "Service role bypass history"
        ON memory_history FOR ALL
        TO service_role
        USING (true);
    END IF;
END \$\$;

SQL

# Verify RLS is enabled
echo ""
echo "Verifying RLS status..."

TABLES=("memories")
if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = 'memory_relationships';" | grep -q 1; then
    TABLES+=("memory_relationships")
fi
if psql "$SUPABASE_DB_URL" -t -c "SELECT 1 FROM pg_tables WHERE tablename = 'memory_history';" | grep -q 1; then
    TABLES+=("memory_history")
fi

ALL_ENABLED=true
for table in "${TABLES[@]}"; do
    RLS_STATUS=$(psql "$SUPABASE_DB_URL" -t -c "SELECT rowsecurity FROM pg_tables WHERE tablename = '$table';" | xargs)
    if [ "$RLS_STATUS" = "t" ]; then
        echo -e "${GREEN}✓${NC} RLS enabled on: $table"
    else
        echo -e "${RED}✗${NC} RLS not enabled on: $table"
        ALL_ENABLED=false
    fi
done

# List applied policies
echo ""
echo "Applied policies:"
psql "$SUPABASE_DB_URL" -c "
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename IN ('memories', 'memory_relationships', 'memory_history')
ORDER BY tablename, policyname;
"

if [ "$ALL_ENABLED" = true ]; then
    echo ""
    echo -e "${GREEN}Success!${NC} RLS policies applied"
    echo ""
    echo "Security features:"
    echo "  - User isolation (users only see own memories)"
    echo "  - Service role bypass (for admin operations)"
    if [ "$RLS_PATTERN" = "multi-tenant" ] || [ "$RLS_PATTERN" = "hybrid" ]; then
        echo "  - Multi-tenant support (organization-based access)"
    fi
    echo "  - Public agent knowledge (shared across users)"
    echo "  - Relationship isolation (graph memory security)"
    echo "  - Audit trail protection (history table)"
    echo ""
    echo "Next step: bash scripts/validate-mem0-setup.sh"
else
    echo -e "${RED}✗${NC} Some tables failed RLS enablement"
    exit 1
fi
