-- Multi-Tenant RLS Policies
-- Pattern: Organization/team-based isolation via organization_id
-- Use for: SaaS apps, team workspaces, shared resources, collaborative tools

-- Ensure org_members table exists
-- CREATE TABLE IF NOT EXISTS org_members (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
--     user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
--     role TEXT NOT NULL DEFAULT 'member',
--     created_at TIMESTAMPTZ DEFAULT NOW(),
--     UNIQUE(organization_id, user_id)
-- );

-- Enable RLS on the table
ALTER TABLE TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Performance index on organization_id column
CREATE INDEX IF NOT EXISTS idx_TABLE_NAME_organization_id ON TABLE_NAME(organization_id);

-- ============================================
-- Security Definer Function: Check Organization Access
-- ============================================
-- This function bypasses RLS for the membership check (performance optimization)
CREATE OR REPLACE FUNCTION auth.user_has_org_access(org_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM org_members
        WHERE user_id = auth.uid()
        AND organization_id = org_uuid
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SELECT Policy: Users can view records in their organizations
-- ============================================
CREATE POLICY "TABLE_NAME_select_org" ON TABLE_NAME
    FOR SELECT
    TO authenticated
    USING (
        auth.user_has_org_access(organization_id)
    );

-- ============================================
-- INSERT Policy: Users can create records in their organizations
-- ============================================
CREATE POLICY "TABLE_NAME_insert_org" ON TABLE_NAME
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.user_has_org_access(organization_id)
    );

-- ============================================
-- UPDATE Policy: Users can update records in their organizations
-- ============================================
CREATE POLICY "TABLE_NAME_update_org" ON TABLE_NAME
    FOR UPDATE
    TO authenticated
    USING (
        auth.user_has_org_access(organization_id)
    )
    WITH CHECK (
        auth.user_has_org_access(organization_id)
    );

-- ============================================
-- DELETE Policy: Users can delete records in their organizations
-- ============================================
CREATE POLICY "TABLE_NAME_delete_org" ON TABLE_NAME
    FOR DELETE
    TO authenticated
    USING (
        auth.user_has_org_access(organization_id)
    );

-- ============================================
-- Optional: Role-Based Permissions within Organization
-- ============================================
-- Uncomment to restrict INSERT/UPDATE/DELETE to specific org roles

-- CREATE POLICY "TABLE_NAME_insert_org_editors" ON TABLE_NAME
--     FOR INSERT
--     TO authenticated
--     WITH CHECK (
--         EXISTS (
--             SELECT 1
--             FROM org_members
--             WHERE user_id = auth.uid()
--             AND organization_id = TABLE_NAME.organization_id
--             AND role IN ('admin', 'editor')
--         )
--     );

-- ============================================
-- Notes:
-- ============================================
-- 1. Security definer function avoids RLS performance penalty on org_members
-- 2. Add index on org_members(user_id, organization_id) for best performance
-- 3. Consider caching organization memberships in JWT claims for high-traffic apps
-- 4. Always filter queries: .eq('organization_id', orgId)
-- 5. Ensure org_members table has RLS policies as well!
