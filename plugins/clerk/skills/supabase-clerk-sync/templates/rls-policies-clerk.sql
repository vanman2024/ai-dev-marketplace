-- Row Level Security Policies for Clerk Authentication
-- This file contains comprehensive RLS policy templates for Supabase + Clerk integration

-- ============================================================================
-- HELPER FUNCTIONS (Run these first)
-- ============================================================================

-- Extract Clerk user ID from JWT
CREATE OR REPLACE FUNCTION auth.clerk_user_id()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Extract user email from JWT
CREATE OR REPLACE FUNCTION auth.clerk_user_email()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'email',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Extract organization ID from JWT
CREATE OR REPLACE FUNCTION auth.clerk_org_id()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'org_id',
    NULL
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Extract user role from JWT
CREATE OR REPLACE FUNCTION auth.clerk_role()
RETURNS TEXT AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'role',
    'user'
  )::TEXT;
$$ LANGUAGE SQL STABLE;

-- Check if user is admin
CREATE OR REPLACE FUNCTION auth.is_clerk_admin()
RETURNS BOOLEAN AS $$
  SELECT auth.clerk_role() = 'admin';
$$ LANGUAGE SQL STABLE;

-- Check if user is in organization
CREATE OR REPLACE FUNCTION auth.is_in_org()
RETURNS BOOLEAN AS $$
  SELECT auth.clerk_org_id() IS NOT NULL;
$$ LANGUAGE SQL STABLE;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
DROP POLICY IF EXISTS "users_select_own" ON users;
CREATE POLICY "users_select_own"
  ON users
  FOR SELECT
  USING (clerk_id = auth.clerk_user_id());

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "users_update_own" ON users;
CREATE POLICY "users_update_own"
  ON users
  FOR UPDATE
  USING (clerk_id = auth.clerk_user_id())
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- Policy: Service role can manage all users (for webhook sync)
DROP POLICY IF EXISTS "users_service_all" ON users;
CREATE POLICY "users_service_all"
  ON users
  FOR ALL
  USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT, UPDATE ON users TO authenticated;
GRANT ALL ON users TO service_role;

-- ============================================================================
-- USER PROFILES (PUBLIC DATA)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id TEXT UNIQUE NOT NULL,
  username TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view public profiles
DROP POLICY IF EXISTS "profiles_public_read" ON user_profiles;
CREATE POLICY "profiles_public_read"
  ON user_profiles
  FOR SELECT
  USING (true);

-- Policy: Users can update their own profile
DROP POLICY IF EXISTS "profiles_update_own" ON user_profiles;
CREATE POLICY "profiles_update_own"
  ON user_profiles
  FOR UPDATE
  USING (clerk_id = auth.clerk_user_id())
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- Grant permissions
GRANT SELECT ON user_profiles TO anon, authenticated;
GRANT UPDATE ON user_profiles TO authenticated;

-- ============================================================================
-- POSTS (USER-OWNED CONTENT)
-- ============================================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view published posts
DROP POLICY IF EXISTS "posts_public_published" ON posts;
CREATE POLICY "posts_public_published"
  ON posts
  FOR SELECT
  USING (is_published = true);

-- Policy: Users can view their own posts (published or not)
DROP POLICY IF EXISTS "posts_select_own" ON posts;
CREATE POLICY "posts_select_own"
  ON posts
  FOR SELECT
  USING (clerk_id = auth.clerk_user_id());

-- Policy: Users can insert their own posts
DROP POLICY IF EXISTS "posts_insert_own" ON posts;
CREATE POLICY "posts_insert_own"
  ON posts
  FOR INSERT
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- Policy: Users can update their own posts
DROP POLICY IF EXISTS "posts_update_own" ON posts;
CREATE POLICY "posts_update_own"
  ON posts
  FOR UPDATE
  USING (clerk_id = auth.clerk_user_id())
  WITH CHECK (clerk_id = auth.clerk_user_id());

-- Policy: Users can delete their own posts
DROP POLICY IF EXISTS "posts_delete_own" ON posts;
CREATE POLICY "posts_delete_own"
  ON posts
  FOR DELETE
  USING (clerk_id = auth.clerk_user_id());

-- Grant permissions
GRANT SELECT ON posts TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON posts TO authenticated;

-- ============================================================================
-- ORGANIZATIONS (MULTI-TENANT)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_org_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;

-- Policy: Org members can view their organization
DROP POLICY IF EXISTS "orgs_select_members" ON organizations;
CREATE POLICY "orgs_select_members"
  ON organizations
  FOR SELECT
  USING (clerk_org_id = auth.clerk_org_id());

-- Policy: Org admins can update organization
DROP POLICY IF EXISTS "orgs_update_admins" ON organizations;
CREATE POLICY "orgs_update_admins"
  ON organizations
  FOR UPDATE
  USING (
    clerk_org_id = auth.clerk_org_id() AND
    auth.is_clerk_admin()
  )
  WITH CHECK (clerk_org_id = auth.clerk_org_id());

-- Grant permissions
GRANT SELECT ON organizations TO authenticated;
GRANT UPDATE ON organizations TO authenticated;

-- ============================================================================
-- ORG RESOURCES (SHARED WITHIN ORGANIZATION)
-- ============================================================================

CREATE TABLE IF NOT EXISTS org_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_org_id TEXT NOT NULL,
  name TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  created_by TEXT NOT NULL, -- clerk_id of creator
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE org_resources ENABLE ROW LEVEL SECURITY;

-- Policy: Org members can view org resources
DROP POLICY IF EXISTS "org_resources_select" ON org_resources;
CREATE POLICY "org_resources_select"
  ON org_resources
  FOR SELECT
  USING (clerk_org_id = auth.clerk_org_id());

-- Policy: Org members can create resources
DROP POLICY IF EXISTS "org_resources_insert" ON org_resources;
CREATE POLICY "org_resources_insert"
  ON org_resources
  FOR INSERT
  WITH CHECK (
    clerk_org_id = auth.clerk_org_id() AND
    created_by = auth.clerk_user_id()
  );

-- Policy: Org admins and editors can update
DROP POLICY IF EXISTS "org_resources_update" ON org_resources;
CREATE POLICY "org_resources_update"
  ON org_resources
  FOR UPDATE
  USING (
    clerk_org_id = auth.clerk_org_id() AND
    auth.clerk_role() IN ('admin', 'editor')
  )
  WITH CHECK (clerk_org_id = auth.clerk_org_id());

-- Policy: Only org admins can delete
DROP POLICY IF EXISTS "org_resources_delete" ON org_resources;
CREATE POLICY "org_resources_delete"
  ON org_resources
  FOR DELETE
  USING (
    clerk_org_id = auth.clerk_org_id() AND
    auth.is_clerk_admin()
  );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON org_resources TO authenticated;

-- ============================================================================
-- ROLE-BASED ACCESS (ADMIN, EDITOR, VIEWER)
-- ============================================================================

CREATE TABLE IF NOT EXISTS admin_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value JSONB,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE admin_settings ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can access
DROP POLICY IF EXISTS "admin_settings_all" ON admin_settings;
CREATE POLICY "admin_settings_all"
  ON admin_settings
  FOR ALL
  USING (auth.is_clerk_admin())
  WITH CHECK (auth.is_clerk_admin());

-- Grant permissions
GRANT ALL ON admin_settings TO authenticated;

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_clerk_id ON users(clerk_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Organizations table indexes
CREATE INDEX IF NOT EXISTS idx_orgs_clerk_org_id ON organizations(clerk_org_id);

-- Posts table indexes
CREATE INDEX IF NOT EXISTS idx_posts_clerk_id ON posts(clerk_id);
CREATE INDEX IF NOT EXISTS idx_posts_published ON posts(is_published);

-- Org resources table indexes
CREATE INDEX IF NOT EXISTS idx_org_resources_org_id ON org_resources(clerk_org_id);
CREATE INDEX IF NOT EXISTS idx_org_resources_created_by ON org_resources(created_by);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_posts_updated_at ON posts;
CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_orgs_updated_at ON organizations;
CREATE TRIGGER update_orgs_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS update_org_resources_updated_at ON org_resources;
CREATE TRIGGER update_org_resources_updated_at
  BEFORE UPDATE ON org_resources
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- VERIFY POLICIES
-- ============================================================================

-- Query to verify all policies are enabled
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual IS NOT NULL as has_using,
  with_check IS NOT NULL as has_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Query to verify RLS is enabled
SELECT
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
