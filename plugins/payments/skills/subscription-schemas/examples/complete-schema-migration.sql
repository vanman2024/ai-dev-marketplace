-- complete-schema-migration.sql
-- Complete payment schema migration in a single file
--
-- Security: NO hardcoded credentials
-- This is a reference file showing the complete schema
--
-- Usage:
--   For production, use: bash scripts/migrate-schema.sh
--   For manual application: Copy sections as needed to Supabase SQL Editor
--
-- IMPORTANT: Replace placeholders with actual values:
--   - SUPABASE_URL: your_supabase_url_here
--   - SUPABASE_SERVICE_ROLE_KEY: your_service_role_key_here

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- ENUMS
-- =============================================================================

-- Subscription status
DO $$ BEGIN
    CREATE TYPE subscription_status AS ENUM (
        'trialing', 'active', 'past_due', 'canceled',
        'unpaid', 'incomplete', 'incomplete_expired', 'paused'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Payment status
DO $$ BEGIN
    CREATE TYPE payment_status AS ENUM (
        'pending', 'processing', 'succeeded',
        'failed', 'canceled', 'refunded', 'partially_refunded'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Invoice status
DO $$ BEGIN
    CREATE TYPE invoice_status AS ENUM (
        'draft', 'open', 'paid', 'void', 'uncollectible'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- TABLE: customers
-- =============================================================================

CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT,
    billing_address JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT customers_email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_created_at ON customers(created_at DESC);

CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: subscriptions
-- =============================================================================

CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL,
    plan_name TEXT,
    status subscription_status NOT NULL DEFAULT 'incomplete',
    cancel_at_period_end BOOLEAN NOT NULL DEFAULT FALSE,
    canceled_at TIMESTAMPTZ,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    trial_start TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',
    interval TEXT NOT NULL DEFAULT 'month',
    interval_count INTEGER NOT NULL DEFAULT 1,
    provider_subscription_id TEXT UNIQUE,
    provider TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT subscriptions_amount_positive CHECK (amount > 0),
    CONSTRAINT subscriptions_interval_count_positive CHECK (interval_count > 0),
    CONSTRAINT subscriptions_period_valid CHECK (current_period_end > current_period_start),
    CONSTRAINT subscriptions_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

CREATE INDEX idx_subscriptions_customer_id ON subscriptions(customer_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_current_period_end ON subscriptions(current_period_end);
CREATE INDEX idx_subscriptions_provider_id ON subscriptions(provider_subscription_id);
CREATE INDEX idx_subscriptions_customer_status ON subscriptions(customer_id, status);

CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: payments
-- =============================================================================

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'usd',
    status payment_status NOT NULL DEFAULT 'pending',
    payment_method TEXT,
    payment_method_details JSONB DEFAULT '{}'::jsonb,
    provider TEXT NOT NULL,
    provider_payment_id TEXT UNIQUE,
    refunded_amount NUMERIC(10, 2) DEFAULT 0,
    refunded_at TIMESTAMPTZ,
    failure_code TEXT,
    failure_message TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT payments_amount_positive CHECK (amount > 0),
    CONSTRAINT payments_refunded_amount_valid CHECK (refunded_amount >= 0 AND refunded_amount <= amount),
    CONSTRAINT payments_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

CREATE INDEX idx_payments_subscription_id ON payments(subscription_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_provider_payment_id ON payments(provider_payment_id);
CREATE INDEX idx_payments_subscription_status ON payments(subscription_id, status);

CREATE TRIGGER update_payments_updated_at
    BEFORE UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: invoices
-- =============================================================================

CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
    next_num INTEGER;
    invoice_num TEXT;
BEGIN
    next_num := nextval('invoice_number_seq');
    invoice_num := 'INV-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(next_num::TEXT, 6, '0');
    RETURN invoice_num;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    invoice_number TEXT UNIQUE NOT NULL,
    amount_due NUMERIC(10, 2) NOT NULL,
    amount_paid NUMERIC(10, 2) NOT NULL DEFAULT 0,
    amount_remaining NUMERIC(10, 2) GENERATED ALWAYS AS (amount_due - amount_paid) STORED,
    currency TEXT NOT NULL DEFAULT 'usd',
    status invoice_status NOT NULL DEFAULT 'draft',
    due_date DATE,
    paid_at TIMESTAMPTZ,
    voided_at TIMESTAMPTZ,
    line_items JSONB DEFAULT '[]'::jsonb,
    tax_amount NUMERIC(10, 2) DEFAULT 0,
    discount_amount NUMERIC(10, 2) DEFAULT 0,
    provider TEXT,
    provider_invoice_id TEXT UNIQUE,
    hosted_invoice_url TEXT,
    invoice_pdf_url TEXT,
    notes TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT invoices_amount_due_positive CHECK (amount_due >= 0),
    CONSTRAINT invoices_amount_paid_valid CHECK (amount_paid >= 0 AND amount_paid <= amount_due),
    CONSTRAINT invoices_tax_valid CHECK (tax_amount >= 0),
    CONSTRAINT invoices_discount_valid CHECK (discount_amount >= 0),
    CONSTRAINT invoices_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

CREATE INDEX idx_invoices_subscription_id ON invoices(subscription_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_subscription_status ON invoices(subscription_id, status);

CREATE OR REPLACE FUNCTION set_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL THEN
        NEW.invoice_number := generate_invoice_number();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invoices_invoice_number
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION set_invoice_number();

CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- TABLE: webhook_events
-- =============================================================================

CREATE TABLE IF NOT EXISTS webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider TEXT NOT NULL,
    event_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ,
    processing_attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    last_error_at TIMESTAMPTZ,
    request_id TEXT,
    api_version TEXT,
    ip_address INET,
    idempotency_key TEXT UNIQUE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT webhook_events_provider_event_id_unique UNIQUE (provider, event_id)
);

CREATE INDEX idx_webhook_events_provider ON webhook_events(provider);
CREATE INDEX idx_webhook_events_event_type ON webhook_events(event_type);
CREATE INDEX idx_webhook_events_processed ON webhook_events(processed);
CREATE INDEX idx_webhook_events_provider_type ON webhook_events(provider, event_type);
CREATE INDEX idx_webhook_events_payload ON webhook_events USING GIN (payload);

CREATE TRIGGER update_webhook_events_updated_at
    BEFORE UPDATE ON webhook_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;

-- Customers policies
CREATE POLICY "Users can view own customer record" ON customers
    FOR SELECT TO authenticated
    USING (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Users can create own customer record" ON customers
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Users can update own customer record" ON customers
    FOR UPDATE TO authenticated
    USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
    WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id);

CREATE POLICY "Service role full access to customers" ON customers
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Subscriptions policies
CREATE POLICY "Users can view own subscriptions" ON subscriptions
    FOR SELECT TO authenticated
    USING (auth.uid() IS NOT NULL AND customer_id IN (
        SELECT id FROM customers WHERE user_id = auth.uid()
    ));

CREATE POLICY "Service role full access to subscriptions" ON subscriptions
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Payments policies
CREATE POLICY "Users can view own payments" ON payments
    FOR SELECT TO authenticated
    USING (auth.uid() IS NOT NULL AND subscription_id IN (
        SELECT s.id FROM subscriptions s
        JOIN customers c ON s.customer_id = c.id
        WHERE c.user_id = auth.uid()
    ));

CREATE POLICY "Service role full access to payments" ON payments
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Invoices policies
CREATE POLICY "Users can view own invoices" ON invoices
    FOR SELECT TO authenticated
    USING (auth.uid() IS NOT NULL AND subscription_id IN (
        SELECT s.id FROM subscriptions s
        JOIN customers c ON s.customer_id = c.id
        WHERE c.user_id = auth.uid()
    ));

CREATE POLICY "Service role full access to invoices" ON invoices
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Webhook events policies (service role only)
CREATE POLICY "Service role full access to webhook events" ON webhook_events
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Payment Schema Migration Complete!';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables created: 5';
    RAISE NOTICE '  ✓ customers';
    RAISE NOTICE '  ✓ subscriptions';
    RAISE NOTICE '  ✓ payments';
    RAISE NOTICE '  ✓ invoices';
    RAISE NOTICE '  ✓ webhook_events';
    RAISE NOTICE '';
    RAISE NOTICE 'Security: Row Level Security ENABLED';
    RAISE NOTICE 'Indexes: Created for performance';
    RAISE NOTICE 'Triggers: updated_at, invoice numbering';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '  1. Test RLS policies';
    RAISE NOTICE '  2. Integrate payment provider';
    RAISE NOTICE '  3. Set up webhook handlers';
    RAISE NOTICE '';
END $$;
