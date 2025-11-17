-- User Schema for Clerk + Supabase Integration
-- This creates the necessary tables for storing synced user data

-- ============================================================================
-- USERS TABLE (Core user data synced from Clerk)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_id TEXT UNIQUE NOT NULL,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  avatar_url TEXT,
  username TEXT UNIQUE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_clerk_id ON users(clerk_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Comments for documentation
COMMENT ON TABLE users IS 'User profiles synced from Clerk authentication';
COMMENT ON COLUMN users.clerk_id IS 'Clerk user ID (sub claim in JWT)';
COMMENT ON COLUMN users.metadata IS 'User public_metadata from Clerk';

-- ============================================================================
-- ORGANIZATIONS TABLE (For multi-tenant applications)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_org_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  image_url TEXT,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_orgs_clerk_org_id ON organizations(clerk_org_id);
CREATE INDEX IF NOT EXISTS idx_orgs_slug ON organizations(slug);

-- Comments
COMMENT ON TABLE organizations IS 'Organizations synced from Clerk';
COMMENT ON COLUMN organizations.clerk_org_id IS 'Clerk organization ID';

-- ============================================================================
-- ORGANIZATION_MEMBERS (Junction table for org memberships)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clerk_org_id TEXT NOT NULL REFERENCES organizations(clerk_org_id) ON DELETE CASCADE,
  clerk_user_id TEXT NOT NULL,
  role TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(clerk_org_id, clerk_user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_org_members_org ON organization_members(clerk_org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user ON organization_members(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_role ON organization_members(role);

-- Comments
COMMENT ON TABLE organization_members IS 'Organization memberships from Clerk';
COMMENT ON COLUMN organization_members.role IS 'Clerk organization role (admin, member, etc.)';

-- ============================================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- ============================================================================

-- Function to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to users
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Apply trigger to organizations
DROP TRIGGER IF EXISTS update_orgs_updated_at ON organizations;
CREATE TRIGGER update_orgs_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Apply trigger to organization_members
DROP TRIGGER IF EXISTS update_org_members_updated_at ON organization_members;
CREATE TRIGGER update_org_members_updated_at
  BEFORE UPDATE ON organization_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Service role needs full access for webhook sync
GRANT ALL ON users TO service_role;
GRANT ALL ON organizations TO service_role;
GRANT ALL ON organization_members TO service_role;

-- Authenticated users need read access (controlled by RLS)
GRANT SELECT ON users TO authenticated;
GRANT SELECT ON organizations TO authenticated;
GRANT SELECT ON organization_members TO authenticated;

-- Anonymous users have no direct access (controlled by RLS)
GRANT SELECT ON users TO anon;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Verify tables were created
SELECT
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('users', 'organizations', 'organization_members')
ORDER BY table_name;

-- Verify indexes
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('users', 'organizations', 'organization_members')
ORDER BY tablename, indexname;

-- Verify triggers
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('users', 'organizations', 'organization_members')
ORDER BY event_object_table, trigger_name;
