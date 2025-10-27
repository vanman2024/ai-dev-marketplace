-- Role-Based Access RLS Policies
-- Pattern: Different permissions per role (admin, editor, user, viewer)
-- Use for: Admin panels, hierarchical access, permission levels, content management

-- Enable RLS on the table
ALTER TABLE TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- ============================================
-- Security Definer Function: Get User Role
-- ============================================
-- Extracts role from JWT claims (app_metadata is secure, user_metadata is NOT)
CREATE OR REPLACE FUNCTION auth.user_role()
RETURNS TEXT AS $$
BEGIN
    -- Try multiple claim locations for flexibility
    RETURN COALESCE(
        auth.jwt() -> 'app_metadata' ->> 'role',  -- Preferred: immutable
        auth.jwt() ->> 'user_role',                -- Alternative claim
        'user'                                      -- Default role
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SELECT Policy: All authenticated users can read
-- ============================================
-- Adjust USING clause if you need role-based read restrictions
CREATE POLICY "TABLE_NAME_select_authenticated" ON TABLE_NAME
    FOR SELECT
    TO authenticated
    USING (true);  -- Everyone can read, or add: auth.user_role() IN ('viewer', 'user', 'editor', 'admin')

-- ============================================
-- INSERT Policy: Users and above can create
-- ============================================
CREATE POLICY "TABLE_NAME_insert_users" ON TABLE_NAME
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.user_role() IN ('user', 'editor', 'admin')
    );

-- ============================================
-- UPDATE Policy: Editors and admins can update
-- ============================================
CREATE POLICY "TABLE_NAME_update_editors" ON TABLE_NAME
    FOR UPDATE
    TO authenticated
    USING (
        auth.user_role() IN ('editor', 'admin')
    )
    WITH CHECK (
        auth.user_role() IN ('editor', 'admin')
    );

-- ============================================
-- DELETE Policy: Only admins can delete
-- ============================================
CREATE POLICY "TABLE_NAME_delete_admins" ON TABLE_NAME
    FOR DELETE
    TO authenticated
    USING (
        auth.user_role() = 'admin'
    );

-- ============================================
-- Alternative: Granular Role Policies
-- ============================================
-- Uncomment for more fine-grained control per role

-- -- Viewers: Read-only access
-- CREATE POLICY "TABLE_NAME_select_viewers" ON TABLE_NAME
--     FOR SELECT
--     TO authenticated
--     USING (auth.user_role() IN ('viewer', 'user', 'editor', 'admin'));

-- -- Users: Read + Create own
-- CREATE POLICY "TABLE_NAME_insert_users_own" ON TABLE_NAME
--     FOR INSERT
--     TO authenticated
--     WITH CHECK (
--         auth.user_role() IN ('user', 'editor', 'admin')
--         AND (SELECT auth.uid()) = user_id
--     );

-- -- Editors: Read + Create + Update any
-- CREATE POLICY "TABLE_NAME_update_editors_any" ON TABLE_NAME
--     FOR UPDATE
--     TO authenticated
--     USING (auth.user_role() IN ('editor', 'admin'))
--     WITH CHECK (auth.user_role() IN ('editor', 'admin'));

-- -- Admins: Full access (already covered above)

-- ============================================
-- Setting User Roles
-- ============================================
-- Roles must be set in app_metadata (server-side only):
--
-- In Supabase Dashboard:
--   Auth → Users → Select user → Edit user → App metadata:
--   { "role": "admin" }
--
-- Via Admin API:
--   await supabase.auth.admin.updateUserById(userId, {
--     app_metadata: { role: 'editor' }
--   })
--
-- Via Database Trigger (automatic on signup):
--   CREATE OR REPLACE FUNCTION public.handle_new_user()
--   RETURNS TRIGGER AS $$
--   BEGIN
--     UPDATE auth.users
--     SET raw_app_meta_data = raw_app_meta_data || '{"role": "user"}'::jsonb
--     WHERE id = NEW.id;
--     RETURN NEW;
--   END;
--   $$ LANGUAGE plpgsql SECURITY DEFINER;
--
--   CREATE TRIGGER on_auth_user_created
--     AFTER INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- Notes:
-- ============================================
-- 1. NEVER use raw_user_meta_data for roles (user can modify it)
-- 2. ALWAYS use app_metadata or JWT claims (server-controlled)
-- 3. Default role is 'user' if not set
-- 4. Role hierarchy: viewer < user < editor < admin
-- 5. Consider caching role in client for UI decisions (not security)
