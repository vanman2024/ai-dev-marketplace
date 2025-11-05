-- payments_table.sql
-- Payment transaction records
--
-- Security: NO hardcoded credentials, NO credit card numbers stored
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- PCI Compliance: Store payment provider tokens only, never raw card data
--
-- Usage:
--   Apply after subscriptions table exists
--   Always enable RLS after creation (see rls_policies.sql)

-- Create payment status enum
DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM (
        'pending',
        'processing',
        'succeeded',
        'failed',
        'canceled',
        'refunded',
        'partially_refunded'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,

    -- Payment amount
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',

    -- Payment status
    status payment_status NOT NULL DEFAULT 'pending',

    -- Payment method (tokenized reference, NEVER store raw card data)
    payment_method TEXT, -- 'card', 'paypal', 'bank_transfer', etc.
    payment_method_details JSONB DEFAULT '{}'::jsonb, -- Last 4 digits, brand, etc. (non-sensitive)

    -- Payment provider information
    provider TEXT NOT NULL, -- 'stripe', 'paddle', 'lemonsqueezy'
    provider_payment_id TEXT UNIQUE, -- Stripe payment intent ID, etc.

    -- Refund information
    refunded_amount NUMERIC(10, 2) DEFAULT 0,
    refunded_at TIMESTAMPTZ,

    -- Error tracking
    failure_code TEXT,
    failure_message TEXT,

    -- Metadata
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT payments_amount_positive CHECK (amount > 0),
    CONSTRAINT payments_refunded_amount_valid CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
    CONSTRAINT payments_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_subscription_id ON payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_provider_payment_id ON payments(provider_payment_id);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payments_provider ON payments(provider);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_payments_subscription_status ON payments(subscription_id, status);

-- Create updated_at trigger
CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE payments IS 'Payment transaction records - PCI compliant (no raw card data)';
COMMENT ON COLUMN payments.payment_method_details IS 'Non-sensitive details only (last 4, brand)';
COMMENT ON COLUMN payments.provider_payment_id IS 'Payment provider transaction ID for reconciliation';
COMMENT ON COLUMN payments.refunded_amount IS 'Amount refunded (can be partial)';

-- PCI DSS compliance notice
DO $$
BEGIN
    RAISE NOTICE 'payments table created successfully';
    RAISE NOTICE 'PCI COMPLIANCE: NEVER store raw credit card numbers in this table';
    RAISE NOTICE 'Store payment provider tokens only (Stripe payment methods, etc.)';
    RAISE NOTICE 'Indexes created: subscription_id, status, provider_payment_id, created_at';
    RAISE NOTICE 'IMPORTANT: Enable RLS with rls_policies.sql before production use';
END $$;

-- Rollback
-- DROP TRIGGER IF EXISTS update_payments_updated_at ON payments;
-- DROP TABLE IF EXISTS payments CASCADE;
-- DROP TYPE IF EXISTS payment_status CASCADE;
