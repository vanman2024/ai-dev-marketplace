#!/bin/bash

# Generate or retrieve webhook secret
# Usage: ./generate-webhook-secret.sh [provider]

set -e

PROVIDER="${1:-stripe}"

echo "Webhook Secret Generator"
echo "======================="
echo "Provider: $PROVIDER"
echo ""

case "$PROVIDER" in
    stripe)
        echo "Stripe Webhook Secret Retrieval"
        echo "--------------------------------"
        echo ""
        echo "Option 1: Use Stripe CLI (Recommended for local testing)"
        echo "  stripe listen --print-secret"
        echo ""
        echo "Option 2: Get from Stripe Dashboard"
        echo "  1. Go to: https://dashboard.stripe.com/webhooks"
        echo "  2. Click on your webhook endpoint"
        echo "  3. Click 'Reveal' next to 'Signing secret'"
        echo "  4. Copy the secret (starts with 'whsec_')"
        echo ""
        echo "Option 3: Create new endpoint via API"
        echo "  (Requires Stripe API key)"
        echo ""

        # Check if Stripe CLI is available
        if command -v stripe &> /dev/null; then
            read -p "Generate new webhook secret using Stripe CLI? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo ""
                echo "Generating temporary webhook secret..."
                echo "This secret is only valid while 'stripe listen' is running"
                echo ""
                stripe listen --print-secret
                echo ""
                echo "To make this permanent:"
                echo "  1. Create endpoint in Stripe Dashboard"
                echo "  2. Use the signing secret from the dashboard"
            fi
        else
            echo "Install Stripe CLI to generate secrets automatically:"
            echo "  https://stripe.com/docs/stripe-cli"
        fi
        ;;

    paypal)
        echo "PayPal Webhook ID Retrieval"
        echo "---------------------------"
        echo ""
        echo "1. Go to: https://developer.paypal.com/dashboard/applications"
        echo "2. Select your application"
        echo "3. Scroll to 'Webhooks'"
        echo "4. Click on your webhook URL"
        echo "5. Copy the 'Webhook ID'"
        echo ""
        echo "Note: PayPal uses Webhook ID instead of a signing secret"
        ;;

    square)
        echo "Square Signature Key Retrieval"
        echo "-------------------------------"
        echo ""
        echo "1. Go to: https://developer.squareup.com/apps"
        echo "2. Select your application"
        echo "3. Click 'Webhooks' in the left sidebar"
        echo "4. Click on your webhook URL"
        echo "5. Copy the 'Signature Key'"
        echo ""
        ;;

    *)
        echo "Unknown provider: $PROVIDER"
        echo "Supported providers: stripe, paypal, square"
        exit 1
        ;;
esac

echo ""
echo "Security Best Practices:"
echo "========================"
echo ""
echo "✅ DO:"
echo "  - Store secrets in environment variables (.env file)"
echo "  - Use different secrets for development and production"
echo "  - Rotate secrets quarterly"
echo "  - Add .env to .gitignore"
echo ""
echo "❌ DON'T:"
echo "  - Hardcode secrets in source code"
echo "  - Commit secrets to version control"
echo "  - Share secrets in public channels"
echo "  - Use the same secret across environments"
echo ""
echo "Example .env file:"
echo "=================="
echo ""
case "$PROVIDER" in
    stripe)
        echo "STRIPE_API_KEY=sk_test_your_stripe_key_here"
        echo "STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here"
        ;;
    paypal)
        echo "PAYPAL_CLIENT_ID=your_paypal_client_id_here"
        echo "PAYPAL_CLIENT_SECRET=your_paypal_client_secret_here"
        echo "PAYPAL_WEBHOOK_ID=your_webhook_id_here"
        ;;
    square)
        echo "SQUARE_ACCESS_TOKEN=your_square_access_token_here"
        echo "SQUARE_SIGNATURE_KEY=your_signature_key_here"
        ;;
esac
echo ""
