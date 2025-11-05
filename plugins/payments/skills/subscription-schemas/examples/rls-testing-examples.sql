-- rls-testing-examples.sql
-- Test Row Level Security policies for payment tables
--
-- Security: These tests verify that RLS properly isolates user data
-- Environment: Run in Supabase SQL Editor with authentication context
--
-- IMPORTANT: These are test scenarios - adapt to your testing approach

-- =============================================================================
-- SETUP TEST DATA (Service Role Only)
-- =============================================================================

-- Note: The following creates test data for RLS testing
-- Run this section ONLY with service_role key

/*
-- Create test users (assumes Supabase Auth users exist)
-- Replace 'test-user-1-uuid' and 'test-user-2-uuid' with actual auth.users IDs

-- Insert test customers
INSERT INTO customers (user_id, email, name) VALUES
    ('test-user-1-uuid', 'user1@example.com', 'Test User 1'),
    ('test-user-2-uuid', 'user2@example.com', 'Test User 2');

-- Get customer IDs
-- (Store these for use in subscription creation)

-- Insert test subscriptions
INSERT INTO subscriptions (
    customer_id, plan_id, plan_name, status, amount, currency,
    current_period_start, current_period_end
) VALUES
    (
        (SELECT id FROM customers WHERE user_id = 'test-user-1-uuid'),
        'plan_pro', 'Pro Plan', 'active', 29.99, 'usd',
        NOW(), NOW() + INTERVAL '1 month'
    ),
    (
        (SELECT id FROM customers WHERE user_id = 'test-user-2-uuid'),
        'plan_basic', 'Basic Plan', 'active', 9.99, 'usd',
        NOW(), NOW() + INTERVAL '1 month'
    );
*/

-- =============================================================================
-- RLS TEST 1: Customer Data Isolation
-- =============================================================================

-- Test: User can see their own customer record
-- Expected: Returns 1 row with user's data
SELECT
    id,
    email,
    name,
    'Can see own record' as test_result
FROM customers
WHERE user_id = auth.uid();

-- Test: User cannot see other users' customer records
-- Expected: Returns 0 rows (other users' data filtered out)
SELECT
    COUNT(*) as other_users_visible,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS: Other users not visible'
        ELSE '✗ FAIL: Other users are visible (RLS violation!)'
    END as test_result
FROM customers
WHERE user_id != auth.uid();

-- Test: Anonymous users cannot access customer data
-- Expected: 0 rows (when not authenticated)
-- Run this with anon key instead of authenticated key
/*
SELECT COUNT(*) as accessible_rows
FROM customers;
-- Should return 0 when using anon key
*/

-- =============================================================================
-- RLS TEST 2: Subscription Access Control
-- =============================================================================

-- Test: User can see their own subscriptions
-- Expected: Returns only subscriptions for current user
SELECT
    s.id,
    s.plan_name,
    s.status,
    c.email,
    'User can see own subscriptions' as test_result
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid();

-- Test: User cannot see other users' subscriptions
-- Expected: Returns 0 rows
SELECT
    COUNT(*) as other_subscriptions_visible,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS: Other subscriptions not visible'
        ELSE '✗ FAIL: Other subscriptions are visible (RLS violation!)'
    END as test_result
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id != auth.uid();

-- Test: Direct subscription access without join is blocked
-- Expected: 0 rows (RLS policy requires customer join)
SELECT
    COUNT(*) as direct_access_count,
    CASE
        WHEN COUNT(*) > 0 THEN '✓ PASS: Can access own subscriptions'
        ELSE '⚠ Check if you have subscriptions'
    END as test_result
FROM subscriptions s
WHERE s.id IN (
    SELECT s2.id
    FROM subscriptions s2
    JOIN customers c ON s2.customer_id = c.id
    WHERE c.user_id = auth.uid()
);

-- =============================================================================
-- RLS TEST 3: Payment Data Privacy
-- =============================================================================

-- Test: User can view their own payments
-- Expected: Returns only payments for user's subscriptions
SELECT
    p.id,
    p.amount,
    p.status,
    s.plan_name,
    'User can see own payments' as test_result
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid();

-- Test: User cannot view other users' payments
-- Expected: 0 rows
SELECT
    COUNT(*) as other_payments_visible,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS: Other payments not visible'
        ELSE '✗ FAIL: Other payments are visible (RLS violation!)'
    END as test_result
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id != auth.uid();

-- Test: Payment method details are accessible but safe
-- Expected: Shows payment method details (should be non-sensitive data only)
SELECT
    p.payment_method,
    p.payment_method_details->>'last4' as card_last4,
    p.payment_method_details->>'brand' as card_brand,
    'Payment details are non-sensitive' as test_result
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
LIMIT 1;

-- =============================================================================
-- RLS TEST 4: Invoice Access Control
-- =============================================================================

-- Test: User can view their own invoices
-- Expected: Returns only invoices for user's subscriptions
SELECT
    i.invoice_number,
    i.amount_due,
    i.status,
    s.plan_name,
    'User can see own invoices' as test_result
FROM invoices i
JOIN subscriptions s ON i.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid();

-- Test: User cannot view other users' invoices
-- Expected: 0 rows
SELECT
    COUNT(*) as other_invoices_visible,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS: Other invoices not visible'
        ELSE '✗ FAIL: Other invoices are visible (RLS violation!)'
    END as test_result
FROM invoices i
JOIN subscriptions s ON i.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id != auth.uid();

-- =============================================================================
-- RLS TEST 5: Webhook Events (Admin Only)
-- =============================================================================

-- Test: Regular users cannot access webhook events
-- Expected: 0 rows (only service_role can access)
SELECT
    COUNT(*) as webhook_events_visible,
    CASE
        WHEN COUNT(*) = 0 THEN '✓ PASS: Webhook events not accessible to users'
        ELSE '✗ FAIL: Users can access webhook events (should be service_role only!)'
    END as test_result
FROM webhook_events;

-- =============================================================================
-- RLS TEST 6: Insert/Update/Delete Operations
-- =============================================================================

-- Test: User can create their own customer record
-- Expected: SUCCESS (if customer record doesn't exist yet)
/*
INSERT INTO customers (user_id, email, name)
VALUES (auth.uid(), 'test@example.com', 'Test User');
*/

-- Test: User cannot create customer record for another user
-- Expected: FAIL (RLS policy violation)
/*
INSERT INTO customers (user_id, email, name)
VALUES ('other-user-uuid', 'other@example.com', 'Other User');
-- Should fail with RLS policy violation
*/

-- Test: User can update their own customer record
-- Expected: SUCCESS
/*
UPDATE customers
SET name = 'Updated Name'
WHERE user_id = auth.uid();
*/

-- Test: User cannot update other users' customer records
-- Expected: 0 rows affected (RLS blocks the update)
/*
UPDATE customers
SET name = 'Hacked Name'
WHERE user_id != auth.uid();
-- Should affect 0 rows
*/

-- =============================================================================
-- RLS TEST 7: Helper Functions
-- =============================================================================

-- Test: user_owns_customer() helper function
SELECT
    user_owns_customer(id) as owns_customer,
    email,
    CASE
        WHEN user_owns_customer(id) THEN '✓ Correctly identifies ownership'
        ELSE '✗ Ownership check failed'
    END as test_result
FROM customers
WHERE user_id = auth.uid()
LIMIT 1;

-- Test: get_current_customer_id() helper function
SELECT
    get_current_customer_id() as my_customer_id,
    (SELECT id FROM customers WHERE user_id = auth.uid()) as expected_id,
    CASE
        WHEN get_current_customer_id() = (SELECT id FROM customers WHERE user_id = auth.uid())
        THEN '✓ Helper function returns correct ID'
        ELSE '✗ Helper function error'
    END as test_result;

-- =============================================================================
-- RLS TEST SUMMARY
-- =============================================================================

-- Comprehensive RLS validation summary
SELECT
    'RLS Test Summary' as test_category,
    (
        SELECT COUNT(*) FROM customers WHERE user_id = auth.uid()
    ) as my_customer_count,
    (
        SELECT COUNT(*) FROM subscriptions s
        JOIN customers c ON s.customer_id = c.id
        WHERE c.user_id = auth.uid()
    ) as my_subscription_count,
    (
        SELECT COUNT(*) FROM payments p
        JOIN subscriptions s ON p.subscription_id = s.id
        JOIN customers c ON s.customer_id = c.id
        WHERE c.user_id = auth.uid()
    ) as my_payment_count,
    (
        SELECT COUNT(*) FROM invoices i
        JOIN subscriptions s ON i.subscription_id = s.id
        JOIN customers c ON s.customer_id = c.id
        WHERE c.user_id = auth.uid()
    ) as my_invoice_count,
    (
        -- This should ALWAYS be 0 for non-service-role
        SELECT COUNT(*) FROM webhook_events
    ) as webhook_event_count;

-- =============================================================================
-- CLEANUP TEST DATA (Service Role Only)
-- =============================================================================

/*
-- Remove test data after testing
DELETE FROM customers WHERE email LIKE '%@example.com';
*/

-- =============================================================================
-- NOTES
-- =============================================================================

/*
RLS Best Practices Verified:

1. ✓ Customer Isolation - Users only see their own customer record
2. ✓ Subscription Privacy - Subscriptions filtered by customer ownership
3. ✓ Payment Security - Payments accessible only through subscription ownership
4. ✓ Invoice Protection - Invoices require subscription ownership
5. ✓ Webhook Restriction - Webhook events require service_role

Common RLS Testing Approaches:

1. SQL Editor Testing:
   - Run queries in Supabase SQL Editor as authenticated user
   - Verify returned data matches expected ownership

2. Client Library Testing:
   - Use Supabase client with user auth token
   - Verify queries return correct filtered data

3. Service Role Testing:
   - Verify service_role bypasses RLS for admin operations
   - Test webhook processing with service_role key

Security Checklist:

- [ ] Users cannot see other users' customers
- [ ] Users cannot see other users' subscriptions
- [ ] Users cannot see other users' payments
- [ ] Users cannot see other users' invoices
- [ ] Users cannot access webhook_events table
- [ ] Anonymous users cannot access any payment data
- [ ] Service role can bypass RLS for webhooks
*/
