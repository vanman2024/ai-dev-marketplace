-- sample-queries.sql
-- Common query patterns for payment data
--
-- Security: All queries use RLS - run as authenticated user
-- Environment: These queries assume you have auth.uid() context
--
-- Usage: Copy queries to Supabase SQL Editor or use in application code

-- =============================================================================
-- CUSTOMER QUERIES
-- =============================================================================

-- Get current user's customer profile
SELECT
    id,
    email,
    name,
    billing_address,
    created_at
FROM customers
WHERE user_id = auth.uid();

-- Get customer with metadata
SELECT
    id,
    email,
    name,
    metadata->>'stripe_customer_id' as stripe_customer_id,
    metadata->>'paddle_customer_id' as paddle_customer_id,
    created_at
FROM customers
WHERE user_id = auth.uid();

-- =============================================================================
-- SUBSCRIPTION QUERIES
-- =============================================================================

-- Get active subscriptions for current user
SELECT
    s.id,
    s.plan_id,
    s.plan_name,
    s.status,
    s.amount,
    s.currency,
    s.interval,
    s.current_period_start,
    s.current_period_end,
    s.cancel_at_period_end
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND s.status = 'active'
ORDER BY s.created_at DESC;

-- Get all subscriptions with status summary
SELECT
    s.id,
    s.plan_name,
    s.status,
    s.amount,
    s.currency,
    s.current_period_end,
    CASE
        WHEN s.cancel_at_period_end THEN 'Canceling at period end'
        WHEN s.status = 'trialing' THEN 'In trial period'
        WHEN s.status = 'active' THEN 'Active'
        WHEN s.status = 'past_due' THEN 'Payment failed'
        ELSE INITCAP(s.status::TEXT)
    END as status_description
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
ORDER BY
    CASE s.status
        WHEN 'active' THEN 1
        WHEN 'trialing' THEN 2
        WHEN 'past_due' THEN 3
        ELSE 4
    END,
    s.created_at DESC;

-- Get subscription with upcoming renewal
SELECT
    s.id,
    s.plan_name,
    s.amount,
    s.currency,
    s.current_period_end,
    s.current_period_end - NOW() as time_until_renewal,
    CASE
        WHEN s.current_period_end - NOW() < INTERVAL '7 days' THEN true
        ELSE false
    END as renewal_soon
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND s.status = 'active';

-- =============================================================================
-- PAYMENT QUERIES
-- =============================================================================

-- Get payment history for current user
SELECT
    p.id,
    p.amount,
    p.currency,
    p.status,
    p.payment_method,
    p.description,
    p.created_at,
    s.plan_name
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
ORDER BY p.created_at DESC
LIMIT 20;

-- Get successful payments summary
SELECT
    DATE_TRUNC('month', p.created_at) as payment_month,
    COUNT(*) as payment_count,
    SUM(p.amount) as total_amount,
    p.currency
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND p.status = 'succeeded'
GROUP BY DATE_TRUNC('month', p.created_at), p.currency
ORDER BY payment_month DESC;

-- Get failed payment attempts
SELECT
    p.id,
    p.amount,
    p.currency,
    p.failure_code,
    p.failure_message,
    p.created_at,
    s.plan_name
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND p.status = 'failed'
ORDER BY p.created_at DESC;

-- Get refunded payments
SELECT
    p.id,
    p.amount,
    p.refunded_amount,
    p.amount - p.refunded_amount as net_amount,
    p.currency,
    p.status,
    p.refunded_at,
    s.plan_name
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND p.refunded_amount > 0
ORDER BY p.refunded_at DESC;

-- =============================================================================
-- INVOICE QUERIES
-- =============================================================================

-- Get all invoices for current user
SELECT
    i.id,
    i.invoice_number,
    i.status,
    i.amount_due,
    i.amount_paid,
    i.amount_remaining,
    i.currency,
    i.due_date,
    i.hosted_invoice_url,
    i.created_at,
    s.plan_name
FROM invoices i
JOIN subscriptions s ON i.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
ORDER BY i.created_at DESC;

-- Get unpaid invoices
SELECT
    i.id,
    i.invoice_number,
    i.amount_due,
    i.amount_remaining,
    i.currency,
    i.due_date,
    i.hosted_invoice_url,
    CASE
        WHEN i.due_date < CURRENT_DATE THEN 'Overdue'
        WHEN i.due_date = CURRENT_DATE THEN 'Due today'
        ELSE 'Upcoming'
    END as due_status
FROM invoices i
JOIN subscriptions s ON i.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND i.status IN ('open', 'draft')
AND i.amount_remaining > 0
ORDER BY i.due_date ASC;

-- Get invoice with line items
SELECT
    i.id,
    i.invoice_number,
    i.status,
    i.amount_due,
    i.tax_amount,
    i.discount_amount,
    i.line_items,
    jsonb_array_length(i.line_items) as item_count
FROM invoices i
JOIN subscriptions s ON i.subscription_id = s.id
JOIN customers c ON s.customer_id = c.id
WHERE c.user_id = auth.uid()
AND i.id = 'invoice_id_here'; -- Replace with actual invoice ID

-- =============================================================================
-- COMBINED QUERIES
-- =============================================================================

-- Get customer billing overview
SELECT
    c.email,
    c.name,
    COUNT(DISTINCT s.id) FILTER (WHERE s.status = 'active') as active_subscriptions,
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'succeeded') as successful_payments,
    SUM(p.amount) FILTER (WHERE p.status = 'succeeded') as total_paid,
    COUNT(DISTINCT i.id) FILTER (WHERE i.status = 'open') as open_invoices,
    SUM(i.amount_remaining) FILTER (WHERE i.status = 'open') as amount_due
FROM customers c
LEFT JOIN subscriptions s ON s.customer_id = c.id
LEFT JOIN payments p ON p.subscription_id = s.id
LEFT JOIN invoices i ON i.subscription_id = s.id
WHERE c.user_id = auth.uid()
GROUP BY c.id, c.email, c.name;

-- Get subscription with latest payment
SELECT
    s.id as subscription_id,
    s.plan_name,
    s.status as subscription_status,
    s.amount as subscription_amount,
    s.current_period_end,
    p.id as latest_payment_id,
    p.status as latest_payment_status,
    p.created_at as latest_payment_date
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
LEFT JOIN LATERAL (
    SELECT id, status, created_at
    FROM payments
    WHERE subscription_id = s.id
    ORDER BY created_at DESC
    LIMIT 1
) p ON true
WHERE c.user_id = auth.uid()
AND s.status = 'active';

-- Get revenue by subscription plan
SELECT
    s.plan_name,
    s.plan_id,
    COUNT(DISTINCT s.id) as subscription_count,
    COUNT(p.id) FILTER (WHERE p.status = 'succeeded') as payment_count,
    SUM(p.amount) FILTER (WHERE p.status = 'succeeded') as total_revenue,
    s.currency
FROM subscriptions s
JOIN customers c ON s.customer_id = c.id
LEFT JOIN payments p ON p.subscription_id = s.id
WHERE c.user_id = auth.uid()
GROUP BY s.plan_name, s.plan_id, s.currency
ORDER BY total_revenue DESC NULLS LAST;

-- =============================================================================
-- ANALYTICS QUERIES (Service Role Only)
-- =============================================================================

-- Note: The following queries require service_role access
-- Use these in backend services, not client-side

/*
-- Monthly Recurring Revenue (MRR)
SELECT
    DATE_TRUNC('month', current_period_start) as month,
    SUM(amount) as mrr,
    COUNT(*) as active_subscriptions
FROM subscriptions
WHERE status = 'active'
AND interval = 'month'
GROUP BY DATE_TRUNC('month', current_period_start)
ORDER BY month DESC;

-- Churn rate by month
SELECT
    DATE_TRUNC('month', canceled_at) as month,
    COUNT(*) as churned_subscriptions
FROM subscriptions
WHERE canceled_at IS NOT NULL
GROUP BY DATE_TRUNC('month', canceled_at)
ORDER BY month DESC;
*/
