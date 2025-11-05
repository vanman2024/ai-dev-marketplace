#!/bin/bash

# Test webhooks locally using Stripe CLI
# Usage: ./test-webhook-locally.sh [port]

set -e

PORT="${1:-8000}"

echo "Webhook Local Testing"
echo "===================="
echo ""

# Check if Stripe CLI is installed
if ! command -v stripe &> /dev/null; then
    echo "Stripe CLI not found!"
    echo ""
    echo "Install Stripe CLI:"
    echo "  macOS:   brew install stripe/stripe-cli/stripe"
    echo "  Linux:   Download from https://github.com/stripe/stripe-cli/releases"
    echo "  Windows: scoop install stripe"
    echo ""
    echo "After installation, run: stripe login"
    exit 1
fi

# Check if logged in to Stripe
if ! stripe config --list &> /dev/null; then
    echo "Not logged in to Stripe CLI"
    echo "Run: stripe login"
    exit 1
fi

# Check if application is running
if ! curl -s "http://localhost:${PORT}/health" > /dev/null 2>&1; then
    echo "Application not running on port ${PORT}"
    echo ""
    echo "Start your application first:"
    echo "  uvicorn app.main:app --reload --port ${PORT}"
    echo ""
    exit 1
fi

echo "Starting webhook forwarding..."
echo "Forwarding webhooks to: http://localhost:${PORT}/webhooks/stripe"
echo ""
echo "The Stripe CLI will:"
echo "  1. Forward webhook events from Stripe to your local server"
echo "  2. Show you the webhook signing secret (add to .env)"
echo "  3. Display incoming events in real-time"
echo ""
echo "Test events with:"
echo "  stripe trigger payment_intent.succeeded"
echo "  stripe trigger customer.subscription.created"
echo "  stripe trigger invoice.payment_failed"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Forward webhooks to local server
stripe listen --forward-to "localhost:${PORT}/webhooks/stripe"
