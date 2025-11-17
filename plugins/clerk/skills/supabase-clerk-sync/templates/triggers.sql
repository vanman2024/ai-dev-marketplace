-- Database Triggers for Clerk + Supabase Integration
-- Audit logging, data validation, and automated workflows

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id UUID,
  clerk_user_id TEXT,
  operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
  old_data JSONB,
  new_data JSONB,
  changed_fields TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying audit logs
CREATE INDEX IF NOT EXISTS idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);

-- ============================================================================
-- AUDIT LOGGING FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION log_audit()
RETURNS TRIGGER AS $$
DECLARE
  changed_fields TEXT[];
  clerk_user TEXT;
BEGIN
  -- Extract Clerk user ID from JWT if available
  BEGIN
    clerk_user := current_setting('request.jwt.claims', true)::json->>'sub';
  EXCEPTION WHEN OTHERS THEN
    clerk_user := NULL;
  END;

  -- For INSERT operations
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO audit_logs (
      table_name,
      record_id,
      clerk_user_id,
      operation,
      new_data
    ) VALUES (
      TG_TABLE_NAME,
      NEW.id,
      clerk_user,
      TG_OP,
      to_jsonb(NEW)
    );
    RETURN NEW;

  -- For UPDATE operations
  ELSIF (TG_OP = 'UPDATE') THEN
    -- Detect changed fields
    SELECT array_agg(key)
    INTO changed_fields
    FROM (
      SELECT key
      FROM jsonb_each(to_jsonb(NEW))
      WHERE to_jsonb(NEW) -> key IS DISTINCT FROM to_jsonb(OLD) -> key
    ) AS changed_keys;

    -- Only log if fields actually changed
    IF changed_fields IS NOT NULL AND array_length(changed_fields, 1) > 0 THEN
      INSERT INTO audit_logs (
        table_name,
        record_id,
        clerk_user_id,
        operation,
        old_data,
        new_data,
        changed_fields
      ) VALUES (
        TG_TABLE_NAME,
        NEW.id,
        clerk_user,
        TG_OP,
        to_jsonb(OLD),
        to_jsonb(NEW),
        changed_fields
      );
    END IF;
    RETURN NEW;

  -- For DELETE operations
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_logs (
      table_name,
      record_id,
      clerk_user_id,
      operation,
      old_data
    ) VALUES (
      TG_TABLE_NAME,
      OLD.id,
      clerk_user,
      TG_OP,
      to_jsonb(OLD)
    );
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- APPLY AUDIT TRIGGERS
-- ============================================================================

-- Users table
DROP TRIGGER IF EXISTS audit_users ON users;
CREATE TRIGGER audit_users
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION log_audit();

-- Organizations table
DROP TRIGGER IF EXISTS audit_organizations ON organizations;
CREATE TRIGGER audit_organizations
  AFTER INSERT OR UPDATE OR DELETE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION log_audit();

-- Organization members table
DROP TRIGGER IF EXISTS audit_org_members ON organization_members;
CREATE TRIGGER audit_org_members
  AFTER INSERT OR UPDATE OR DELETE ON organization_members
  FOR EACH ROW
  EXECUTE FUNCTION log_audit();

-- ============================================================================
-- EMAIL VALIDATION TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_email()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate email format if provided
  IF NEW.email IS NOT NULL AND NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'Invalid email format: %', NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply email validation to users
DROP TRIGGER IF EXISTS validate_user_email ON users;
CREATE TRIGGER validate_user_email
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION validate_email();

-- ============================================================================
-- USERNAME NORMALIZATION TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION normalize_username()
RETURNS TRIGGER AS $$
BEGIN
  -- Normalize username: lowercase, trim whitespace
  IF NEW.username IS NOT NULL THEN
    NEW.username := lower(trim(NEW.username));

    -- Validate username format (alphanumeric, hyphens, underscores)
    IF NEW.username !~ '^[a-z0-9_-]+$' THEN
      RAISE EXCEPTION 'Username can only contain lowercase letters, numbers, hyphens, and underscores';
    END IF;

    -- Minimum length check
    IF length(NEW.username) < 3 THEN
      RAISE EXCEPTION 'Username must be at least 3 characters long';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply username normalization
DROP TRIGGER IF EXISTS normalize_user_username ON users;
CREATE TRIGGER normalize_user_username
  BEFORE INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION normalize_username();

-- ============================================================================
-- ORGANIZATION SLUG NORMALIZATION
-- ============================================================================

CREATE OR REPLACE FUNCTION normalize_org_slug()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate slug from name if not provided
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := lower(regexp_replace(trim(NEW.name), '[^a-zA-Z0-9]+', '-', 'g'));
    NEW.slug := regexp_replace(NEW.slug, '^-+|-+$', '', 'g');
  ELSE
    -- Normalize existing slug
    NEW.slug := lower(trim(NEW.slug));
    NEW.slug := regexp_replace(NEW.slug, '[^a-z0-9-]', '-', 'g');
    NEW.slug := regexp_replace(NEW.slug, '-+', '-', 'g');
    NEW.slug := regexp_replace(NEW.slug, '^-+|-+$', '', 'g');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply slug normalization
DROP TRIGGER IF EXISTS normalize_organization_slug ON organizations;
CREATE TRIGGER normalize_organization_slug
  BEFORE INSERT OR UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION normalize_org_slug();

-- ============================================================================
-- PREVENT DIRECT CLERK_ID MODIFICATION
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_clerk_id_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Prevent changing clerk_id after initial insert
  IF TG_OP = 'UPDATE' AND OLD.clerk_id IS DISTINCT FROM NEW.clerk_id THEN
    RAISE EXCEPTION 'Cannot modify clerk_id after creation';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to users table
DROP TRIGGER IF EXISTS prevent_user_clerk_id_change ON users;
CREATE TRIGGER prevent_user_clerk_id_change
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION prevent_clerk_id_change();

-- ============================================================================
-- CASCADE DELETE FOR USER DATA
-- ============================================================================

CREATE OR REPLACE FUNCTION cascade_delete_user_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete all user's organization memberships
  DELETE FROM organization_members WHERE clerk_user_id = OLD.clerk_id;

  -- Delete any user-owned resources (add more as needed)
  -- DELETE FROM posts WHERE clerk_id = OLD.clerk_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Apply cascade delete
DROP TRIGGER IF EXISTS cascade_delete_user ON users;
CREATE TRIGGER cascade_delete_user
  BEFORE DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION cascade_delete_user_data();

-- ============================================================================
-- HELPER FUNCTIONS FOR QUERYING AUDIT LOGS
-- ============================================================================

-- Get audit history for a specific record
CREATE OR REPLACE FUNCTION get_audit_history(
  p_table_name TEXT,
  p_record_id UUID
)
RETURNS TABLE (
  operation TEXT,
  changed_by TEXT,
  changed_fields TEXT[],
  old_data JSONB,
  new_data JSONB,
  changed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.operation,
    al.clerk_user_id,
    al.changed_fields,
    al.old_data,
    al.new_data,
    al.created_at
  FROM audit_logs al
  WHERE al.table_name = p_table_name
    AND al.record_id = p_record_id
  ORDER BY al.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Get recent user activity
CREATE OR REPLACE FUNCTION get_user_activity(
  p_clerk_user_id TEXT,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  table_name TEXT,
  operation TEXT,
  record_id UUID,
  changed_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    al.table_name,
    al.operation,
    al.record_id,
    al.created_at
  FROM audit_logs al
  WHERE al.clerk_user_id = p_clerk_user_id
  ORDER BY al.created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON audit_logs TO authenticated;
GRANT EXECUTE ON FUNCTION get_audit_history(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_activity(TEXT, INT) TO authenticated;
