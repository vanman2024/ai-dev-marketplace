-- webhook_events_table.sql
-- Webhook event logging for audit and replay
--
-- Security: NO hardcoded credentials
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- Purpose: Log all webhook events from payment providers for:
--   - Audit trail and compliance
--   - Event replay and debugging
--   - Idempotency checking
--   - Processing status tracking
--
-- Usage:
--   Independent table (no foreign keys to other payment tables)
--   Always enable RLS after creation (see rls_policies.sql)

-- Create webhook_events table
CREATE TABLE IF NOT EXISTS webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Event identification
    provider TEXT NOT NULL, -- 'stripe', 'paddle', 'lemonsqueezy'
    event_id TEXT NOT NULL, -- Provider's unique event ID
    event_type TEXT NOT NULL, -- e.g., 'payment_intent.succeeded', 'subscription.updated'

    -- Event payload (full webhook body for replay)
    payload JSONB NOT NULL,

    -- Processing status
    processed BOOLEAN NOT NULL DEFAULT FALSE,
    processed_at TIMESTAMPTZ,

    -- Error tracking
    processing_attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    last_error_at TIMESTAMPTZ,

    -- Request metadata
    request_id TEXT, -- For tracing and debugging
    api_version TEXT, -- Provider API version at time of event
    ip_address INET, -- Source IP (for security auditing)

    -- Idempotency key (for preventing duplicate processing)
    idempotency_key TEXT UNIQUE,

    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT webhook_events_provider_event_id_unique UNIQUE (provider, event_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_webhook_events_provider ON webhook_events(provider);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_type ON webhook_events(event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON webhook_events(processed);
CREATE INDEX IF NOT EXISTS idx_webhook_events_created_at ON webhook_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_event_id ON webhook_events(event_id);

-- Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_webhook_events_provider_type ON webhook_events(provider, event_type);
CREATE INDEX IF NOT EXISTS idx_webhook_events_provider_processed ON webhook_events(provider, processed);

-- Create GIN index for JSONB payload searching
CREATE INDEX IF NOT EXISTS idx_webhook_events_payload ON webhook_events USING GIN (payload);

-- Create updated_at trigger
CREATE TRIGGER update_webhook_events_updated_at
    BEFORE UPDATE ON webhook_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to mark event as processed
CREATE OR REPLACE FUNCTION mark_webhook_event_processed(event_uuid UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE webhook_events
    SET
        processed = TRUE,
        processed_at = NOW(),
        updated_at = NOW()
    WHERE id = event_uuid;
END;
$$ LANGUAGE plpgsql;

-- Create function to record processing error
CREATE OR REPLACE FUNCTION record_webhook_error(
    event_uuid UUID,
    error_message TEXT
)
RETURNS VOID AS $$
BEGIN
    UPDATE webhook_events
    SET
        processing_attempts = processing_attempts + 1,
        last_error = error_message,
        last_error_at = NOW(),
        updated_at = NOW()
    WHERE id = event_uuid;
END;
$$ LANGUAGE plpgsql;

-- Add helpful comments
COMMENT ON TABLE webhook_events IS 'Audit log of all payment provider webhook events';
COMMENT ON COLUMN webhook_events.event_id IS 'Provider unique event ID (Stripe event ID, etc.)';
COMMENT ON COLUMN webhook_events.payload IS 'Full webhook JSON payload for replay and debugging';
COMMENT ON COLUMN webhook_events.idempotency_key IS 'Prevents duplicate processing of same event';
COMMENT ON COLUMN webhook_events.processing_attempts IS 'Number of times event processing was attempted';

-- Migration verification
DO $$
BEGIN
    RAISE NOTICE 'webhook_events table created successfully';
    RAISE NOTICE 'GIN index created for JSONB payload searching';
    RAISE NOTICE 'Helper functions: mark_webhook_event_processed(), record_webhook_error()';
    RAISE NOTICE 'Indexes created: provider, event_type, processed, created_at, payload';
    RAISE NOTICE 'IMPORTANT: Enable RLS with rls_policies.sql before production use';
END $$;

-- Rollback
-- DROP TRIGGER IF EXISTS update_webhook_events_updated_at ON webhook_events;
-- DROP FUNCTION IF EXISTS record_webhook_error(UUID, TEXT) CASCADE;
-- DROP FUNCTION IF EXISTS mark_webhook_event_processed(UUID) CASCADE;
-- DROP TABLE IF EXISTS webhook_events CASCADE;
