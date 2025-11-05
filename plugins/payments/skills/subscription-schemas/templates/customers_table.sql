-- customers_table.sql
-- Customer profiles linked to Supabase Auth users
--
-- Security: NO hardcoded credentials
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- Usage:
--   Apply via Supabase migration or service role connection
--   Always enable RLS after creation (see rls_policies.sql)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create customers table
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,

    -- Billing information (stored as JSONB for flexibility)
    billing_address JSONB DEFAULT '{}'::jsonb,

    -- Payment provider metadata (Stripe customer ID, Paddle customer ID, etc.)
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT customers_email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at DESC);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE customers IS 'Customer profiles linked to Supabase Auth users';
COMMENT ON COLUMN customers.user_id IS 'Foreign key to auth.users - CASCADE delete ensures cleanup';
COMMENT ON COLUMN customers.billing_address IS 'JSONB storage for flexible address formats';
COMMENT ON COLUMN customers.metadata IS 'Payment provider IDs and custom metadata';

-- Migration verification
DO $$
BEGIN
    RAISE NOTICE 'customers table created successfully';
    RAISE NOTICE 'Indexes created: user_id, email, created_at';
    RAISE NOTICE 'IMPORTANT: Enable RLS with rls_policies.sql before production use';
END $$;

-- Rollback
-- DROP TRIGGER IF EXISTS update_customers_updated_at ON customers;
-- DROP TABLE IF EXISTS customers CASCADE;
