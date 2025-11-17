#!/bin/bash

# Clerk Billing Setup Script
# Guides through enabling Clerk Billing and connecting Stripe

set -e

echo "==================================================================="
echo "Clerk Billing Setup"
echo "==================================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will guide you through setting up Clerk Billing.${NC}"
echo ""

# Step 1: Check Clerk setup
echo "Step 1: Verify Clerk Configuration"
echo "-----------------------------------"

if [ ! -f .env.local ]; then
    echo -e "${RED}Error: .env.local not found${NC}"
    echo "Please ensure Clerk is configured with required environment variables:"
    echo "  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here"
    echo "  CLERK_SECRET_KEY=your_clerk_secret_key_here"
    exit 1
fi

if ! grep -q "NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY" .env.local; then
    echo -e "${RED}Error: Clerk publishable key not found in .env.local${NC}"
    exit 1
fi

if ! grep -q "CLERK_SECRET_KEY" .env.local; then
    echo -e "${RED}Error: Clerk secret key not found in .env.local${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Clerk environment variables found${NC}"
echo ""

# Step 2: Dashboard setup instructions
echo "Step 2: Enable Clerk Billing in Dashboard"
echo "------------------------------------------"
echo ""
echo "Follow these steps in your Clerk Dashboard:"
echo ""
echo "1. Navigate to: https://dashboard.clerk.com"
echo "2. Select your application"
echo "3. Go to: Configure → Billing"
echo "4. Click: 'Enable Billing'"
echo "5. Choose one of the following:"
echo "   - Connect Stripe Account (for production)"
echo "   - Use Sandbox Mode (for development/testing)"
echo ""
echo -e "${YELLOW}Press Enter when you have completed these steps...${NC}"
read -r

# Step 3: Verify billing is enabled
echo ""
echo "Step 3: Verification"
echo "--------------------"
echo ""
echo "Please verify the following:"
echo "  □ Billing is enabled in Clerk Dashboard"
echo "  □ Stripe connection is active (or sandbox mode enabled)"
echo "  □ You can see the 'Subscription Plans' menu"
echo ""
echo -e "${YELLOW}Is billing enabled? (y/n): ${NC}"
read -r billing_enabled

if [ "$billing_enabled" != "y" ]; then
    echo -e "${RED}Please complete billing setup in the Dashboard before proceeding.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Billing enabled${NC}"
echo ""

# Step 4: Stripe configuration (optional)
echo "Step 4: Stripe Configuration"
echo "-----------------------------"
echo ""
echo "If you connected a Stripe account, you can optionally add Stripe"
echo "environment variables for custom webhook handling:"
echo ""
echo "  STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here"
echo "  STRIPE_SECRET_KEY=your_stripe_secret_key_here"
echo "  STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret_here"
echo ""
echo -e "${YELLOW}Do you want to add Stripe environment variables now? (y/n): ${NC}"
read -r add_stripe

if [ "$add_stripe" = "y" ]; then
    if ! grep -q "STRIPE_PUBLISHABLE_KEY" .env.local; then
        echo "" >> .env.local
        echo "# Stripe Configuration (Optional - for custom webhooks)" >> .env.local
        echo "STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here" >> .env.local
        echo "STRIPE_SECRET_KEY=your_stripe_secret_key_here" >> .env.local
        echo "STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret_here" >> .env.local
        echo -e "${GREEN}✓ Stripe placeholders added to .env.local${NC}"
        echo -e "${YELLOW}Please replace placeholders with your actual Stripe keys.${NC}"
    else
        echo -e "${YELLOW}Stripe variables already exist in .env.local${NC}"
    fi
fi

echo ""

# Step 5: Install dependencies
echo "Step 5: Verify Dependencies"
echo "---------------------------"
echo ""

if [ ! -f package.json ]; then
    echo -e "${RED}Error: package.json not found. Are you in a Next.js project?${NC}"
    exit 1
fi

# Check if @clerk/nextjs is installed
if ! grep -q "@clerk/nextjs" package.json; then
    echo -e "${YELLOW}@clerk/nextjs not found. Installing...${NC}"
    npm install @clerk/nextjs
    echo -e "${GREEN}✓ @clerk/nextjs installed${NC}"
else
    echo -e "${GREEN}✓ @clerk/nextjs already installed${NC}"
fi

echo ""

# Step 6: Setup summary
echo "==================================================================="
echo "Setup Complete!"
echo "==================================================================="
echo ""
echo "Clerk Billing is now enabled. Next steps:"
echo ""
echo "1. Configure pricing plans:"
echo "   bash ./skills/billing-integration/scripts/configure-plans.sh"
echo ""
echo "2. Add PricingTable component to your app:"
echo "   cp ./skills/billing-integration/templates/pricing-page.tsx app/pricing/page.tsx"
echo ""
echo "3. Implement access control:"
echo "   - See examples in: ./skills/billing-integration/examples/"
echo ""
echo "4. Test in development:"
echo "   - Use sandbox mode for testing"
echo "   - Test with Stripe test cards"
echo ""
echo "Documentation:"
echo "  - Clerk Billing: https://clerk.com/docs/billing"
echo "  - Stripe Integration: https://stripe.com/docs"
echo ""
echo -e "${GREEN}Happy billing! 💰${NC}"
echo ""
