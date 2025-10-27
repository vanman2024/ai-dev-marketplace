-- User Isolation RLS Policies
-- Pattern: User owns row directly via user_id column
-- Use for: User profiles, settings, personal documents, user-specific data

-- Enable RLS on the table
ALTER TABLE TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Performance index on user_id column
CREATE INDEX IF NOT EXISTS idx_TABLE_NAME_user_id ON TABLE_NAME(user_id);

-- ============================================
-- SELECT Policy: Users can view their own records
-- ============================================
CREATE POLICY "TABLE_NAME_select_own" ON TABLE_NAME
    FOR SELECT
    TO authenticated
    USING (
        (SELECT auth.uid()) = user_id
    );

-- ============================================
-- INSERT Policy: Users can create records for themselves
-- ============================================
CREATE POLICY "TABLE_NAME_insert_own" ON TABLE_NAME
    FOR INSERT
    TO authenticated
    WITH CHECK (
        (SELECT auth.uid()) = user_id
    );

-- ============================================
-- UPDATE Policy: Users can update their own records
-- ============================================
CREATE POLICY "TABLE_NAME_update_own" ON TABLE_NAME
    FOR UPDATE
    TO authenticated
    USING (
        (SELECT auth.uid()) = user_id
    )
    WITH CHECK (
        (SELECT auth.uid()) = user_id
    );

-- ============================================
-- DELETE Policy: Users can delete their own records
-- ============================================
CREATE POLICY "TABLE_NAME_delete_own" ON TABLE_NAME
    FOR DELETE
    TO authenticated
    USING (
        (SELECT auth.uid()) = user_id
    );

-- ============================================
-- Notes:
-- ============================================
-- 1. (SELECT auth.uid()) wrapping improves performance via caching
-- 2. USING clause checks existing row ownership
-- 3. WITH CHECK clause validates new/modified row ownership
-- 4. TO authenticated prevents unnecessary checks for anon users
-- 5. Always filter queries in client: .eq('user_id', userId)
