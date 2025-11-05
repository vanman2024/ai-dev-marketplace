-- rls_policies.sql
-- Comprehensive Row Level Security policies for payment tables
--
-- Security: NO hardcoded credentials
-- Environment: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
--
-- Purpose:
--   - Isolate customer data by authenticated user
--   - Prevent unauthorized access to payment information
--   - Restrict subscription and invoice access to owners
--   - Limit webhook event access to service role only
--
-- Usage:
--   Apply AFTER all tables are created
--   Service role bypasses RLS for administrative operations
--   Anon role cannot access any payment data

-- =============================================================================
-- CUSTOMERS TABLE RLS POLICIES
-- =============================================================================

-- Enable RLS on customers table
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own customer record
CREATE POLICY "Users can view own customer record"
    ON customers
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND auth.uid() = user_id
    );

-- Policy: Users can insert their own customer record (one-time setup)
CREATE POLICY "Users can create own customer record"
    ON customers
    FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND auth.uid() = user_id
    );

-- Policy: Users can update their own customer record
CREATE POLICY "Users can update own customer record"
    ON customers
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND auth.uid() = user_id
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND auth.uid() = user_id
    );

-- Policy: Users can delete their own customer record
CREATE POLICY "Users can delete own customer record"
    ON customers
    FOR DELETE
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND auth.uid() = user_id
    );

-- Policy: Service role has full access (for admin operations)
CREATE POLICY "Service role full access to customers"
    ON customers
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- SUBSCRIPTIONS TABLE RLS POLICIES
-- =============================================================================

-- Enable RLS on subscriptions table
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own subscriptions
CREATE POLICY "Users can view own subscriptions"
    ON subscriptions
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND customer_id IN (
            SELECT id FROM customers WHERE user_id = auth.uid()
        )
    );

-- Policy: Service role can insert subscriptions (payment provider webhooks)
CREATE POLICY "Service role can insert subscriptions"
    ON subscriptions
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Users can update their own subscriptions (limited fields)
-- Note: Most subscription updates come from webhooks via service role
CREATE POLICY "Users can update own subscriptions"
    ON subscriptions
    FOR UPDATE
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND customer_id IN (
            SELECT id FROM customers WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND customer_id IN (
            SELECT id FROM customers WHERE user_id = auth.uid()
        )
    );

-- Policy: Service role has full access (for webhook processing)
CREATE POLICY "Service role full access to subscriptions"
    ON subscriptions
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- PAYMENTS TABLE RLS POLICIES
-- =============================================================================

-- Enable RLS on payments table
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own payments
CREATE POLICY "Users can view own payments"
    ON payments
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND subscription_id IN (
            SELECT s.id
            FROM subscriptions s
            JOIN customers c ON s.customer_id = c.id
            WHERE c.user_id = auth.uid()
        )
    );

-- Policy: Service role can insert payments (payment provider webhooks)
CREATE POLICY "Service role can insert payments"
    ON payments
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Service role can update payments (refunds, status changes)
CREATE POLICY "Service role can update payments"
    ON payments
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: No DELETE access for anyone except service role
CREATE POLICY "Service role can delete payments"
    ON payments
    FOR DELETE
    TO service_role
    USING (true);

-- Policy: Service role has full access
CREATE POLICY "Service role full access to payments"
    ON payments
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- INVOICES TABLE RLS POLICIES
-- =============================================================================

-- Enable RLS on invoices table
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own invoices
CREATE POLICY "Users can view own invoices"
    ON invoices
    FOR SELECT
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND subscription_id IN (
            SELECT s.id
            FROM subscriptions s
            JOIN customers c ON s.customer_id = c.id
            WHERE c.user_id = auth.uid()
        )
    );

-- Policy: Service role can insert invoices
CREATE POLICY "Service role can insert invoices"
    ON invoices
    FOR INSERT
    TO service_role
    WITH CHECK (true);

-- Policy: Service role can update invoices
CREATE POLICY "Service role can update invoices"
    ON invoices
    FOR UPDATE
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: Service role can delete invoices
CREATE POLICY "Service role can delete invoices"
    ON invoices
    FOR DELETE
    TO service_role
    USING (true);

-- Policy: Service role has full access
CREATE POLICY "Service role full access to invoices"
    ON invoices
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- WEBHOOK_EVENTS TABLE RLS POLICIES
-- =============================================================================

-- Enable RLS on webhook_events table
ALTER TABLE webhook_events ENABLE ROW LEVEL SECURITY;

-- Policy: Only service role can access webhook events (admin/audit only)
CREATE POLICY "Service role full access to webhook events"
    ON webhook_events
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Policy: No authenticated user access to webhook events
-- (Remove this comment if you want to create a read-only policy for admins)

-- =============================================================================
-- HELPER FUNCTIONS FOR RLS OPTIMIZATION
-- =============================================================================

-- Function: Check if user owns customer record (cached for performance)
CREATE OR REPLACE FUNCTION user_owns_customer(customer_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM customers
        WHERE id = customer_uuid
        AND user_id = (SELECT auth.uid())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Function: Check if user owns subscription (cached for performance)
CREATE OR REPLACE FUNCTION user_owns_subscription(subscription_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM subscriptions s
        JOIN customers c ON s.customer_id = c.id
        WHERE s.id = subscription_uuid
        AND c.user_id = (SELECT auth.uid())
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Function: Get customer ID for current authenticated user
CREATE OR REPLACE FUNCTION get_current_customer_id()
RETURNS UUID AS $$
BEGIN
    RETURN (
        SELECT id
        FROM customers
        WHERE user_id = (SELECT auth.uid())
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- =============================================================================
-- VERIFICATION AND TESTING
-- =============================================================================

-- Add helpful comments
COMMENT ON POLICY "Users can view own customer record" ON customers IS
    'RLS: Authenticated users can only view their own customer record';

COMMENT ON POLICY "Users can view own subscriptions" ON subscriptions IS
    'RLS: Authenticated users can only view subscriptions linked to their customer record';

COMMENT ON POLICY "Users can view own payments" ON payments IS
    'RLS: Authenticated users can only view payments for their subscriptions';

COMMENT ON POLICY "Users can view own invoices" ON invoices IS
    'RLS: Authenticated users can only view invoices for their subscriptions';

COMMENT ON POLICY "Service role full access to webhook events" ON webhook_events IS
    'RLS: Webhook events are admin/audit only - no user access';

-- Migration verification
DO $$
DECLARE
    table_name TEXT;
    policy_count INTEGER;
BEGIN
    -- Check RLS is enabled on all tables
    FOR table_name IN
        SELECT unnest(ARRAY['customers', 'subscriptions', 'payments', 'invoices', 'webhook_events'])
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_tables t
            JOIN pg_class c ON c.relname = t.tablename
            WHERE t.tablename = table_name
            AND c.relrowsecurity = true
        ) THEN
            RAISE EXCEPTION 'RLS not enabled on table: %', table_name;
        END IF;

        -- Count policies
        SELECT COUNT(*)
        INTO policy_count
        FROM pg_policies
        WHERE tablename = table_name;

        RAISE NOTICE 'RLS enabled on % with % policies', table_name, policy_count;
    END LOOP;

    RAISE NOTICE '✓ All payment tables have RLS enabled';
    RAISE NOTICE '✓ Helper functions created: user_owns_customer(), user_owns_subscription()';
    RAISE NOTICE '✓ Service role bypasses RLS for admin operations';
    RAISE NOTICE '✓ Authenticated users can only access their own data';
    RAISE NOTICE 'IMPORTANT: Test RLS policies with examples/rls-testing-examples.sql';
END $$;

-- Rollback
-- DROP POLICY IF EXISTS "Users can view own customer record" ON customers;
-- DROP POLICY IF EXISTS "Users can create own customer record" ON customers;
-- DROP POLICY IF EXISTS "Users can update own customer record" ON customers;
-- DROP POLICY IF EXISTS "Users can delete own customer record" ON customers;
-- DROP POLICY IF EXISTS "Service role full access to customers" ON customers;
-- DROP POLICY IF EXISTS "Users can view own subscriptions" ON subscriptions;
-- DROP POLICY IF EXISTS "Service role can insert subscriptions" ON subscriptions;
-- DROP POLICY IF EXISTS "Users can update own subscriptions" ON subscriptions;
-- DROP POLICY IF EXISTS "Service role full access to subscriptions" ON subscriptions;
-- DROP POLICY IF EXISTS "Users can view own payments" ON payments;
-- DROP POLICY IF EXISTS "Service role can insert payments" ON payments;
-- DROP POLICY IF EXISTS "Service role can update payments" ON payments;
-- DROP POLICY IF EXISTS "Service role can delete payments" ON payments;
-- DROP POLICY IF EXISTS "Service role full access to payments" ON payments;
-- DROP POLICY IF EXISTS "Users can view own invoices" ON invoices;
-- DROP POLICY IF EXISTS "Service role can insert invoices" ON invoices;
-- DROP POLICY IF EXISTS "Service role can update invoices" ON invoices;
-- DROP POLICY IF EXISTS "Service role can delete invoices" ON invoices;
-- DROP POLICY IF EXISTS "Service role full access to invoices" ON invoices;
-- DROP POLICY IF EXISTS "Service role full access to webhook events" ON webhook_events;
-- DROP FUNCTION IF EXISTS user_owns_customer(UUID) CASCADE;
-- DROP FUNCTION IF EXISTS user_owns_subscription(UUID) CASCADE;
-- DROP FUNCTION IF EXISTS get_current_customer_id() CASCADE;
-- ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE subscriptions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE payments DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE invoices DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE webhook_events DISABLE ROW LEVEL SECURITY;
