-- Multi-tenant RLS policies for organization isolation

-- Add organization_id column if not exists
ALTER TABLE posts ADD COLUMN IF NOT EXISTS organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_posts_organization ON posts(organization_id);

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Users can only access their organization's content
CREATE POLICY "Users access own organization"
ON posts FOR ALL
TO authenticated
USING (
  organization_id IN (
    SELECT organization_id FROM user_organizations
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  organization_id IN (
    SELECT organization_id FROM user_organizations
    WHERE user_id = auth.uid()
  )
);

-- Public can read published content
CREATE POLICY "Public read published"
ON posts FOR SELECT
TO public
USING (status = 'published');
