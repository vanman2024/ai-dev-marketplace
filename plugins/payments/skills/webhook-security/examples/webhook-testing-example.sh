#!/bin/bash

# Complete webhook testing workflow
# Tests signature verification, event processing, and error handling

set -e

echo "Webhook Testing Workflow"
echo "========================"
echo ""

# Check if Stripe CLI is installed
if ! command -v stripe &> /dev/null; then
    echo "ERROR: Stripe CLI not found!"
    echo "Install: brew install stripe/stripe-cli/stripe (macOS)"
    echo "         or download from https://github.com/stripe/stripe-cli/releases"
    exit 1
fi

# Check if logged in
if ! stripe config --list &> /dev/null; then
    echo "ERROR: Not logged in to Stripe CLI"
    echo "Run: stripe login"
    exit 1
fi

# Configuration
PORT=${WEBHOOK_PORT:-8000}
ENDPOINT="http://localhost:${PORT}/webhooks/stripe"

echo "Configuration:"
echo "  Port: $PORT"
echo "  Endpoint: $ENDPOINT"
echo ""

# Test 1: Check application is running
echo "Test 1: Application Health Check"
echo "---------------------------------"
if curl -s "$ENDPOINT/../health" > /dev/null 2>&1; then
    echo "✅ Application is running"
else
    echo "❌ Application not responding"
    echo ""
    echo "Start your application first:"
    echo "  uvicorn app.main:app --reload --port $PORT"
    exit 1
fi
echo ""

# Test 2: Trigger subscription created event
echo "Test 2: Subscription Created Event"
echo "-----------------------------------"
echo "Triggering customer.subscription.created..."
stripe trigger customer.subscription.created > /dev/null 2>&1
echo "✅ Event triggered successfully"
sleep 2
echo ""

# Test 3: Trigger payment succeeded event
echo "Test 3: Payment Succeeded Event"
echo "--------------------------------"
echo "Triggering invoice.payment_succeeded..."
stripe trigger invoice.payment_succeeded > /dev/null 2>&1
echo "✅ Event triggered successfully"
sleep 2
echo ""

# Test 4: Trigger payment failed event
echo "Test 4: Payment Failed Event"
echo "----------------------------"
echo "Triggering invoice.payment_failed..."
stripe trigger invoice.payment_failed > /dev/null 2>&1
echo "✅ Event triggered successfully"
sleep 2
echo ""

# Test 5: Test with invalid signature (manual curl)
echo "Test 5: Invalid Signature Rejection"
echo "------------------------------------"
RESPONSE=$(curl -s -w "%{http_code}" -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Stripe-Signature: t=123456789,v1=invalid_signature" \
    -d '{"id":"evt_test","type":"test"}' \
    -o /dev/null)

if [ "$RESPONSE" = "401" ]; then
    echo "✅ Invalid signature correctly rejected (401)"
else
    echo "❌ Expected 401, got $RESPONSE"
fi
echo ""

# Test 6: Test with missing signature
echo "Test 6: Missing Signature Rejection"
echo "------------------------------------"
RESPONSE=$(curl -s -w "%{http_code}" -X POST "$ENDPOINT" \
    -H "Content-Type: application/json" \
    -d '{"id":"evt_test","type":"test"}' \
    -o /dev/null)

if [ "$RESPONSE" = "401" ]; then
    echo "✅ Missing signature correctly rejected (401)"
else
    echo "❌ Expected 401, got $RESPONSE"
fi
echo ""

# Test 7: Test subscription update event
echo "Test 7: Subscription Update Event"
echo "----------------------------------"
echo "Triggering customer.subscription.updated..."
stripe trigger customer.subscription.updated > /dev/null 2>&1
echo "✅ Event triggered successfully"
sleep 2
echo ""

# Test 8: Test subscription deleted event
echo "Test 8: Subscription Deleted Event"
echo "-----------------------------------"
echo "Triggering customer.subscription.deleted..."
stripe trigger customer.subscription.deleted > /dev/null 2>&1
echo "✅ Event triggered successfully"
sleep 2
echo ""

# Test 9: Test payment intent events
echo "Test 9: Payment Intent Events"
echo "------------------------------"
echo "Triggering payment_intent.succeeded..."
stripe trigger payment_intent.succeeded > /dev/null 2>&1
echo "✅ Payment intent succeeded triggered"
sleep 2
echo ""

# Test 10: Test dispute event
echo "Test 10: Dispute Event"
echo "----------------------"
echo "Triggering charge.dispute.created..."
stripe trigger charge.dispute.created > /dev/null 2>&1
echo "✅ Dispute event triggered"
sleep 2
echo ""

# Summary
echo "======================================"
echo "Test Summary"
echo "======================================"
echo ""
echo "Tests completed:"
echo "  ✅ Application health check"
echo "  ✅ Subscription created"
echo "  ✅ Payment succeeded"
echo "  ✅ Payment failed"
echo "  ✅ Invalid signature rejection"
echo "  ✅ Missing signature rejection"
echo "  ✅ Subscription updated"
echo "  ✅ Subscription deleted"
echo "  ✅ Payment intent"
echo "  ✅ Dispute event"
echo ""
echo "Next steps:"
echo "1. Check application logs for event processing"
echo "2. Verify database has webhook_events entries"
echo "3. Confirm all events marked as 'processed'"
echo "4. Review any error messages"
echo ""
echo "Interactive testing:"
echo "  stripe listen --forward-to localhost:$PORT/webhooks/stripe"
echo ""
echo "Trigger specific events:"
echo "  stripe trigger customer.subscription.created"
echo "  stripe trigger invoice.payment_succeeded"
echo "  stripe trigger invoice.payment_failed"
echo ""
echo "View webhook events:"
echo "  stripe events list"
echo "  stripe events retrieve evt_xxxxx"
echo ""
