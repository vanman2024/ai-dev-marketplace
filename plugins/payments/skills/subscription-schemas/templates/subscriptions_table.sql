-- subscriptions_table.sql
-- Subscription tracking with status and billing cycles
--
-- Security: NO hardcoded credentials
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- Usage:
--   Apply after customers table exists
--   Always enable RLS after creation (see rls_policies.sql)

-- Create subscription status enum
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM (
        'trialing',
        'active',
        'past_due',
        'canceled',
        'unpaid',
        'incomplete',
        'incomplete_expired',
        'paused'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,

    -- Plan information
    plan_id TEXT NOT NULL,
    plan_name TEXT,

    -- Status and lifecycle
    status subscription_status NOT NULL DEFAULT 'incomplete',
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,

    -- Billing cycle
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,

    -- Trial information
    trial_start TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,

    -- Pricing
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',
    interval TEXT NOT NULL DEFAULT 'month', -- 'day', 'week', 'month', 'year'
    interval_count INTEGER NOT NULL DEFAULT 1,

    -- Payment provider metadata
    provider_subscription_id TEXT UNIQUE,
    provider TEXT, -- 'stripe', 'paddle', 'lemonsqueezy'
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT subscriptions_amount_positive CHECK (amount > 0),
    CONSTRAINT subscriptions_interval_count_positive CHECK (interval_count > 0),
    CONSTRAINT subscriptions_period_valid CHECK (current_period_end > current_period_start),
    CONSTRAINT subscriptions_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_id ON subscriptions(customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_current_period_end ON subscriptions(current_period_end);
CREATE INDEX IF NOT EXISTS idx_subscriptions_provider_id ON subscriptions(provider_subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_created_at ON subscriptions(created_at DESC);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_subscriptions_customer_status ON subscriptions(customer_id, status);

-- Create updated_at trigger
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE subscriptions IS 'Subscription tracking with status and billing cycles';
COMMENT ON COLUMN subscriptions.customer_id IS 'Foreign key to customers - CASCADE delete for cleanup';
COMMENT ON COLUMN subscriptions.cancel_at_period_end IS 'If true, subscription cancels at period end';
COMMENT ON COLUMN subscriptions.provider_subscription_id IS 'Unique ID from payment provider (Stripe, Paddle, etc.)';
COMMENT ON COLUMN subscriptions.interval IS 'Billing interval: day, week, month, year';

-- Migration verification
DO $$
BEGIN
    RAISE NOTICE 'subscriptions table created successfully';
    RAISE NOTICE 'Indexes created: customer_id, status, period_end, provider_id, customer_status';
    RAISE NOTICE 'IMPORTANT: Enable RLS with rls_policies.sql before production use';
END $$;

-- Rollback
-- DROP TRIGGER IF EXISTS update_subscriptions_updated_at ON subscriptions;
-- DROP TABLE IF EXISTS subscriptions CASCADE;
-- DROP TYPE IF EXISTS subscription_status CASCADE;
