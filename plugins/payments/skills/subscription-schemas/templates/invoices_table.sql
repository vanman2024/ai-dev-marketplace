-- invoices_table.sql
-- Invoice generation and tracking
--
-- Security: NO hardcoded credentials
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- Usage:
--   Apply after subscriptions table exists
--   Always enable RLS after creation (see rls_policies.sql)

-- Create invoice status enum
DO $$ BEGIN
    CREATE TYPE invoice_status AS ENUM (
        'draft',
        'open',
        'paid',
        'void',
        'uncollectible'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,

    -- Invoice identification
    invoice_number TEXT UNIQUE NOT NULL,

    -- Amounts
    amount_due NUMERIC(10, 2) NOT NULL,
    amount_paid NUMERIC(10, 2) NOT NULL DEFAULT 0,
    amount_remaining NUMERIC(10, 2) GENERATED ALWAYS AS (amount_due - amount_paid) STORED,
    currency TEXT NOT NULL DEFAULT 'usd',

    -- Status and dates
    status invoice_status NOT NULL DEFAULT 'draft',
    due_date DATE,
    paid_at TIMESTAMPTZ,
    voided_at TIMESTAMPTZ,

    -- Line items (stored as JSONB for flexibility)
    line_items JSONB DEFAULT '[]'::jsonb,

    -- Tax and discounts
    tax_amount NUMERIC(10, 2) DEFAULT 0,
    discount_amount NUMERIC(10, 2) DEFAULT 0,

    -- Payment provider information
    provider TEXT, -- 'stripe', 'paddle', 'lemonsqueezy'
    provider_invoice_id TEXT UNIQUE,

    -- Invoice URLs
    hosted_invoice_url TEXT,
    invoice_pdf_url TEXT,

    -- Notes and metadata
    notes TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT invoices_amount_due_positive CHECK (amount_due >= 0),
    CONSTRAINT invoices_amount_paid_valid CHECK (amount_paid >= 0 AND amount_paid <= amount_due),
    CONSTRAINT invoices_tax_valid CHECK (tax_amount >= 0),
    CONSTRAINT invoices_discount_valid CHECK (discount_amount >= 0),
    CONSTRAINT invoices_currency_valid CHECK (currency ~* '^[a-z]{3}$')
);

-- Create sequence for invoice numbers (format: INV-YYYY-NNNNNN)
CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

-- Create function to generate invoice numbers
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

-- Create trigger to auto-generate invoice numbers
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

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_invoices_subscription_id ON invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_provider_invoice_id ON invoices(provider_invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON invoices(created_at DESC);

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS idx_invoices_subscription_status ON invoices(subscription_id, status);

-- Create updated_at trigger
CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE invoices IS 'Invoice generation and tracking with auto-numbered invoices';
COMMENT ON COLUMN invoices.invoice_number IS 'Auto-generated unique invoice number (INV-YYYY-NNNNNN)';
COMMENT ON COLUMN invoices.amount_remaining IS 'Computed column: amount_due - amount_paid';
COMMENT ON COLUMN invoices.line_items IS 'JSONB array of invoice line items';
COMMENT ON COLUMN invoices.hosted_invoice_url IS 'Public URL for customer to view invoice';

-- Migration verification
DO $$
BEGIN
    RAISE NOTICE 'invoices table created successfully';
    RAISE NOTICE 'Auto-numbering enabled: INV-YYYY-NNNNNN format';
    RAISE NOTICE 'Indexes created: subscription_id, status, due_date, provider_invoice_id';
    RAISE NOTICE 'IMPORTANT: Enable RLS with rls_policies.sql before production use';
END $$;

-- Rollback
-- DROP TRIGGER IF EXISTS set_invoices_invoice_number ON invoices;
-- DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
-- DROP FUNCTION IF EXISTS set_invoice_number() CASCADE;
-- DROP FUNCTION IF EXISTS generate_invoice_number() CASCADE;
-- DROP SEQUENCE IF EXISTS invoice_number_seq CASCADE;
-- DROP TABLE IF EXISTS invoices CASCADE;
-- DROP TYPE IF EXISTS invoice_status CASCADE;
