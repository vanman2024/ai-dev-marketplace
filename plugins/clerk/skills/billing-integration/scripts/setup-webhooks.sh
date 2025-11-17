#!/bin/bash

# Clerk Billing Webhook Setup Script
# Configures custom webhook handlers for billing events

set -e

echo "==================================================================="
echo "Clerk Billing Webhook Setup"
echo "==================================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will help you set up custom billing webhooks.${NC}"
echo ""
echo -e "${BLUE}Note: Clerk handles most webhook logic automatically.${NC}"
echo "You only need custom webhooks for:"
echo "  - Usage tracking and metering"
echo "  - Custom notifications"
echo "  - Analytics integration"
echo "  - Third-party service sync"
echo ""
echo -e "${YELLOW}Do you need custom webhook handlers? (y/n): ${NC}"
read -r need_webhooks

if [ "$need_webhooks" != "y" ]; then
    echo ""
    echo "No custom webhooks needed. Clerk's built-in webhook handling"
    echo "will manage subscriptions, payments, and user updates automatically."
    echo ""
    exit 0
fi

echo ""

# Step 1: Create webhook directory
echo "Step 1: Create Webhook Directory Structure"
echo "-------------------------------------------"
echo ""

WEBHOOK_DIR="app/api/webhooks/clerk"

if [ ! -d "$WEBHOOK_DIR" ]; then
    mkdir -p "$WEBHOOK_DIR"
    echo -e "${GREEN}✓ Created: $WEBHOOK_DIR${NC}"
else
    echo -e "${YELLOW}Directory already exists: $WEBHOOK_DIR${NC}"
fi

echo ""

# Step 2: Select webhook events
echo "Step 2: Select Webhook Events to Handle"
echo "----------------------------------------"
echo ""
echo "Which events do you want to handle?"
echo ""
echo "Billing Events:"
echo "  1) subscription.created"
echo "  2) subscription.updated"
echo "  3) subscription.deleted"
echo "  4) invoice.payment_succeeded"
echo "  5) invoice.payment_failed"
echo ""
echo "User Events:"
echo "  6) user.created"
echo "  7) user.updated"
echo ""
echo "Organization Events:"
echo "  8) organization.created"
echo "  9) organization.updated"
echo ""
echo -e "${YELLOW}Enter event numbers separated by spaces (e.g., 1 2 4): ${NC}"
read -r selected_events

echo ""

# Step 3: Copy webhook handlers
echo "Step 3: Copy Webhook Handler Templates"
echo "---------------------------------------"
echo ""

for event_num in $selected_events; do
    case $event_num in
        1)
            EVENT_NAME="subscription-created"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/subscription-created.ts"
            ;;
        2)
            EVENT_NAME="subscription-updated"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/subscription-updated.ts"
            ;;
        3)
            EVENT_NAME="subscription-deleted"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/subscription-deleted.ts"
            ;;
        4)
            EVENT_NAME="payment-succeeded"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/payment-succeeded.ts"
            ;;
        5)
            EVENT_NAME="payment-failed"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/payment-failed.ts"
            ;;
        6)
            EVENT_NAME="user-created"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/user-created.ts"
            ;;
        7)
            EVENT_NAME="user-updated"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/user-updated.ts"
            ;;
        8)
            EVENT_NAME="org-created"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/org-created.ts"
            ;;
        9)
            EVENT_NAME="org-updated"
            TEMPLATE_FILE="./skills/billing-integration/templates/webhook-handlers/org-updated.ts"
            ;;
        *)
            echo -e "${RED}Invalid event number: $event_num${NC}"
            continue
            ;;
    esac

    if [ -f "$TEMPLATE_FILE" ]; then
        TARGET_FILE="$WEBHOOK_DIR/$EVENT_NAME/route.ts"
        mkdir -p "$WEBHOOK_DIR/$EVENT_NAME"
        cp "$TEMPLATE_FILE" "$TARGET_FILE"
        echo -e "${GREEN}✓ Created: $TARGET_FILE${NC}"
    else
        echo -e "${YELLOW}Template not found: $TEMPLATE_FILE${NC}"
        echo "  Creating basic handler..."

        mkdir -p "$WEBHOOK_DIR/$EVENT_NAME"
        cat > "$WEBHOOK_DIR/$EVENT_NAME/route.ts" <<EOF
import { headers } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  try {
    const body = await request.json()

    // TODO: Implement $EVENT_NAME handler
    console.log('Webhook received:', body)

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Webhook error:', error)
    return NextResponse.json(
      { error: 'Webhook processing failed' },
      { status: 500 }
    )
  }
}
EOF
        echo -e "${GREEN}✓ Created basic handler: $WEBHOOK_DIR/$EVENT_NAME/route.ts${NC}"
    fi
done

echo ""

# Step 4: Environment variables
echo "Step 4: Configure Webhook Secret"
echo "---------------------------------"
echo ""

if [ ! -f .env.local ]; then
    touch .env.local
fi

if ! grep -q "CLERK_WEBHOOK_SECRET" .env.local; then
    echo "" >> .env.local
    echo "# Clerk Webhook Configuration" >> .env.local
    echo "CLERK_WEBHOOK_SECRET=your_clerk_webhook_secret_here" >> .env.local
    echo -e "${GREEN}✓ Added CLERK_WEBHOOK_SECRET to .env.local${NC}"
else
    echo -e "${YELLOW}CLERK_WEBHOOK_SECRET already exists in .env.local${NC}"
fi

echo ""
echo "Get your webhook secret from:"
echo "  Dashboard → Webhooks → Endpoints → Signing Secret"
echo ""

# Step 5: Dashboard configuration
echo "Step 5: Configure Webhook Endpoint in Dashboard"
echo "------------------------------------------------"
echo ""
echo -e "${BLUE}Configure your webhook endpoint in Clerk Dashboard:${NC}"
echo ""
echo "1. Navigate to: https://dashboard.clerk.com"
echo "2. Go to: Webhooks → Endpoints"
echo "3. Click: 'Add Endpoint'"
echo "4. Enter endpoint URL:"
echo ""

if [ -f .env.local ] && grep -q "NEXT_PUBLIC_APP_URL" .env.local; then
    APP_URL=$(grep NEXT_PUBLIC_APP_URL .env.local | cut -d'=' -f2)
    echo "   Production: ${APP_URL}/api/webhooks/clerk"
else
    echo "   Production: https://your-domain.com/api/webhooks/clerk"
fi

echo "   Development: Use ngrok or Clerk's webhook forwarding"
echo ""
echo "5. Select events to receive:"

for event_num in $selected_events; do
    case $event_num in
        1) echo "   ☑ subscription.created" ;;
        2) echo "   ☑ subscription.updated" ;;
        3) echo "   ☑ subscription.deleted" ;;
        4) echo "   ☑ invoice.payment_succeeded" ;;
        5) echo "   ☑ invoice.payment_failed" ;;
        6) echo "   ☑ user.created" ;;
        7) echo "   ☑ user.updated" ;;
        8) echo "   ☑ organization.created" ;;
        9) echo "   ☑ organization.updated" ;;
    esac
done

echo ""
echo "6. Save and copy the Signing Secret to .env.local"
echo ""
echo -e "${YELLOW}Press Enter when webhook endpoint is configured...${NC}"
read -r

echo ""

# Step 6: Local development setup
echo "Step 6: Local Development Testing"
echo "----------------------------------"
echo ""
echo "For local webhook testing, you have two options:"
echo ""
echo "Option 1: Clerk Webhook Forwarding (Recommended)"
echo "  - Automatically forwards webhooks to localhost"
echo "  - No external tools needed"
echo "  - Configure in Dashboard → Webhooks → Local Development"
echo ""
echo "Option 2: ngrok"
echo "  1. Install ngrok: https://ngrok.com/download"
echo "  2. Run: ngrok http 3000"
echo "  3. Copy HTTPS URL (e.g., https://abc123.ngrok.io)"
echo "  4. Update webhook endpoint: https://abc123.ngrok.io/api/webhooks/clerk"
echo ""
echo -e "${YELLOW}Which option will you use? (1/2): ${NC}"
read -r dev_option

if [ "$dev_option" = "2" ]; then
    echo ""
    echo "To start ngrok:"
    echo "  ngrok http 3000"
    echo ""
    echo "Then update your webhook endpoint URL in Clerk Dashboard."
    echo ""
fi

# Step 7: Testing
echo ""
echo "Step 7: Test Webhooks"
echo "---------------------"
echo ""
echo "Test your webhook handlers:"
echo ""
echo "1. Trigger events in your app:"
echo "   - Subscribe to a plan"
echo "   - Update subscription"
echo "   - Cancel subscription"
echo ""
echo "2. Monitor webhook logs:"
echo "   - Dashboard → Webhooks → Attempts"
echo "   - Check for successful deliveries"
echo "   - Review request/response details"
echo ""
echo "3. Check application logs:"
echo "   - npm run dev (watch console output)"
echo "   - Look for 'Webhook received:' messages"
echo ""

# Summary
echo ""
echo "==================================================================="
echo "Webhook Setup Complete!"
echo "==================================================================="
echo ""
echo "Summary:"
echo "  Webhook Directory: $WEBHOOK_DIR"
echo "  Events Configured: $(echo $selected_events | wc -w)"
echo ""
echo "Files Created:"

for event_num in $selected_events; do
    case $event_num in
        1) echo "  - subscription-created/route.ts" ;;
        2) echo "  - subscription-updated/route.ts" ;;
        3) echo "  - subscription-deleted/route.ts" ;;
        4) echo "  - payment-succeeded/route.ts" ;;
        5) echo "  - payment-failed/route.ts" ;;
        6) echo "  - user-created/route.ts" ;;
        7) echo "  - user-updated/route.ts" ;;
        8) echo "  - org-created/route.ts" ;;
        9) echo "  - org-updated/route.ts" ;;
    esac
done

echo ""
echo "Next Steps:"
echo ""
echo "1. Add CLERK_WEBHOOK_SECRET to .env.local"
echo "   - Get from: Dashboard → Webhooks → Signing Secret"
echo ""
echo "2. Implement webhook handler logic"
echo "   - Update files in: $WEBHOOK_DIR"
echo "   - Add your custom processing code"
echo ""
echo "3. Test webhooks locally"
echo "   - Use Clerk forwarding or ngrok"
echo "   - Trigger events and check logs"
echo ""
echo "4. Deploy to production"
echo "   - Update webhook URL in Dashboard"
echo "   - Add CLERK_WEBHOOK_SECRET to production env"
echo ""
echo "Resources:"
echo "  - Clerk Webhooks: https://clerk.com/docs/webhooks"
echo "  - Webhook Events: https://clerk.com/docs/webhooks/overview"
echo "  - Testing Guide: https://clerk.com/docs/webhooks/testing"
echo ""
echo -e "${GREEN}Webhooks configured successfully! 🔔${NC}"
echo ""
