#!/bin/bash

# Clerk Pricing Plans Configuration Script
# Guides through creating subscription plans and features

set -e

echo "==================================================================="
echo "Clerk Pricing Plans Configuration"
echo "==================================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will guide you through configuring subscription plans.${NC}"
echo ""

# Step 1: Plan type selection
echo "Step 1: Choose Plan Type"
echo "------------------------"
echo ""
echo "What type of billing are you implementing?"
echo ""
echo "  1) User Plans (B2C - individual subscriptions)"
echo "  2) Organization Plans (B2B - team/company subscriptions)"
echo "  3) Both (hybrid model)"
echo ""
echo -e "${YELLOW}Enter your choice (1-3): ${NC}"
read -r plan_type

case $plan_type in
    1)
        PLAN_MODE="user"
        echo -e "${GREEN}✓ Selected: User Plans (B2C)${NC}"
        ;;
    2)
        PLAN_MODE="organization"
        echo -e "${GREEN}✓ Selected: Organization Plans (B2B)${NC}"
        ;;
    3)
        PLAN_MODE="both"
        echo -e "${GREEN}✓ Selected: Both User and Organization Plans${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""

# Step 2: Pricing model
echo "Step 2: Choose Pricing Model"
echo "-----------------------------"
echo ""
echo "What pricing model will you use?"
echo ""
echo "  1) Subscription-based (fixed monthly/yearly pricing)"
echo "  2) Usage-based (pay per API call/feature use)"
echo "  3) Hybrid (base subscription + usage charges)"
echo ""
echo -e "${YELLOW}Enter your choice (1-3): ${NC}"
read -r pricing_model

case $pricing_model in
    1)
        PRICING_TYPE="subscription"
        echo -e "${GREEN}✓ Selected: Subscription-based pricing${NC}"
        ;;
    2)
        PRICING_TYPE="usage"
        echo -e "${GREEN}✓ Selected: Usage-based pricing${NC}"
        ;;
    3)
        PRICING_TYPE="hybrid"
        echo -e "${GREEN}✓ Selected: Hybrid pricing${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""

# Step 3: Dashboard navigation
echo "Step 3: Create Plans in Clerk Dashboard"
echo "----------------------------------------"
echo ""
echo -e "${BLUE}Open your Clerk Dashboard and follow these steps:${NC}"
echo ""
echo "1. Navigate to: Configure → Subscription Plans"
echo ""

if [ "$PLAN_MODE" = "user" ] || [ "$PLAN_MODE" = "both" ]; then
    echo "2. Click: 'Add User Plan'"
    echo "3. Fill in plan details:"
    echo "   - Plan Name: (e.g., 'Free', 'Pro', 'Enterprise')"
    echo "   - Plan Slug: (auto-generated, e.g., 'pro_plan')"
    echo "   - Description: (brief plan description)"
    echo "   - Monthly Price: (e.g., \$29/month)"
    echo "   - Yearly Price: (optional, e.g., \$290/year - 17% discount)"
    echo ""
fi

if [ "$PLAN_MODE" = "organization" ] || [ "$PLAN_MODE" = "both" ]; then
    echo "2. Click: 'Add Organization Plan'"
    echo "3. Fill in plan details:"
    echo "   - Plan Name: (e.g., 'Team', 'Business', 'Enterprise')"
    echo "   - Plan Slug: (auto-generated, e.g., 'team_plan')"
    echo "   - Description: (brief plan description)"
    echo "   - Pricing: (e.g., \$99/month base + \$10/user)"
    echo ""
fi

echo "4. Add Features to Plan:"
echo "   - Click 'Add Feature'"
echo "   - Feature Name: (e.g., 'AI Assistant')"
echo "   - Feature Slug: (e.g., 'ai_assistant') ← IMPORTANT: Save this!"
echo "   - Feature Description: (what this feature provides)"

if [ "$PRICING_TYPE" = "usage" ] || [ "$PRICING_TYPE" = "hybrid" ]; then
    echo "   - Usage Limit: (e.g., 1000 API calls/month)"
fi

echo ""
echo "5. Repeat for each plan tier (Free, Pro, Enterprise, etc.)"
echo ""
echo -e "${YELLOW}Press Enter when you have created your plans...${NC}"
read -r

echo ""

# Step 4: Feature slug collection
echo "Step 4: Document Feature Slugs"
echo "-------------------------------"
echo ""
echo "Feature slugs are used in your code for access control."
echo "Let's document them for reference."
echo ""

FEATURE_SLUGS_FILE=".clerk-features.txt"

echo "# Clerk Feature Slugs" > "$FEATURE_SLUGS_FILE"
echo "# Generated: $(date)" >> "$FEATURE_SLUGS_FILE"
echo "# Use these slugs in has({ feature: 'slug_name' }) checks" >> "$FEATURE_SLUGS_FILE"
echo "" >> "$FEATURE_SLUGS_FILE"

echo -e "${YELLOW}Enter your feature slugs (one per line, empty line to finish):${NC}"
echo ""

while true; do
    echo -n "Feature slug: "
    read -r feature_slug

    if [ -z "$feature_slug" ]; then
        break
    fi

    echo "$feature_slug" >> "$FEATURE_SLUGS_FILE"
    echo -e "${GREEN}✓ Added: $feature_slug${NC}"
done

echo ""
echo -e "${GREEN}✓ Feature slugs saved to: $FEATURE_SLUGS_FILE${NC}"
echo ""

# Step 5: Access control examples
echo "Step 5: Access Control Implementation"
echo "--------------------------------------"
echo ""
echo "Here's how to use your feature slugs in code:"
echo ""

# Read the first feature slug for examples
EXAMPLE_SLUG=$(grep -v '^#' "$FEATURE_SLUGS_FILE" | grep -v '^$' | head -1)

if [ -n "$EXAMPLE_SLUG" ]; then
    echo -e "${BLUE}Frontend (Client Component):${NC}"
    echo ""
    cat <<EOF
import { useAuth } from '@clerk/nextjs'

export default function FeatureComponent() {
  const { has } = useAuth()
  const canUse = has?.({ feature: '$EXAMPLE_SLUG' })

  if (!canUse) {
    return <UpgradePrompt />
  }

  return <FeatureInterface />
}
EOF
    echo ""
    echo -e "${BLUE}Backend (API Route):${NC}"
    echo ""
    cat <<EOF
import { auth } from '@clerk/nextjs/server'

export async function POST(request: Request) {
  const { has } = await auth()

  if (!has({ feature: '$EXAMPLE_SLUG' })) {
    return Response.json(
      { error: 'Subscription required' },
      { status: 403 }
    )
  }

  // Process request
}
EOF
    echo ""
fi

# Step 6: Testing guidance
echo ""
echo "Step 6: Testing Your Setup"
echo "--------------------------"
echo ""
echo "Test your billing configuration:"
echo ""
echo "1. View pricing in your app:"
echo "   - Copy pricing page: cp ./skills/billing-integration/templates/pricing-page.tsx app/pricing/page.tsx"
echo "   - Visit: http://localhost:3000/pricing"
echo ""
echo "2. Test subscription flow:"
echo "   - Use Stripe test cards: 4242 4242 4242 4242"
echo "   - Subscribe to a plan"
echo "   - Verify features unlock"
echo ""
echo "3. Test access control:"
echo "   - Try accessing gated features"
echo "   - Check both client and server-side protection"
echo ""
echo "4. Test subscription management:"
echo "   - Click UserButton → Billing tab"
echo "   - View invoices and payment methods"
echo "   - Try upgrading/downgrading"
echo ""

# Summary
echo ""
echo "==================================================================="
echo "Configuration Complete!"
echo "==================================================================="
echo ""
echo "Summary:"
echo "  Plan Type: $PLAN_MODE"
echo "  Pricing Model: $PRICING_TYPE"
echo "  Feature Slugs: $FEATURE_SLUGS_FILE"
echo ""
echo "Next Steps:"
echo ""
echo "1. Implement pricing page:"
echo "   cp ./skills/billing-integration/templates/pricing-page.tsx app/pricing/page.tsx"
echo ""
echo "2. Add access control to features"
echo "   - Use feature slugs from: $FEATURE_SLUGS_FILE"
echo "   - Protect both frontend and API routes"
echo ""
echo "3. Setup subscription management:"
echo "   cp ./skills/billing-integration/templates/subscription-management.tsx components/"
echo ""
echo "4. Review complete example:"
echo "   ./skills/billing-integration/examples/saas-billing-flow.tsx"
echo ""
echo "Resources:"
echo "  - Clerk Dashboard: https://dashboard.clerk.com"
echo "  - Stripe Test Cards: https://stripe.com/docs/testing"
echo "  - Feature Slugs Reference: ./$FEATURE_SLUGS_FILE"
echo ""
echo -e "${GREEN}Plans configured successfully! 🎯${NC}"
echo ""
