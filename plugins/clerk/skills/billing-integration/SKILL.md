---
name: billing-integration
description: Clerk Billing and Stripe subscription management setup. Use when implementing subscriptions, configuring pricing plans, setting up billing, adding payment flows, managing entitlements, or when user mentions Clerk Billing, Stripe integration, subscription management, pricing tables, payment processing, or monetization.
allowed-tools: Bash, Read, Write, Edit, WebFetch
---

# billing-integration

## Instructions

This skill provides complete Clerk Billing integration with Stripe for subscription management, pricing plans, and payment processing. Clerk Billing eliminates the need for custom webhooks and payment UI by connecting directly to Stripe while handling user interface, entitlement logic, and session-aware billing flows.

### 1. Enable Clerk Billing

Initialize Clerk Billing in your Clerk Dashboard:

```bash
# Run automated setup script
bash ./skills/billing-integration/scripts/setup-billing.sh
```

**What This Does:**
- Guides you through Clerk Dashboard setup
- Connects your Stripe account
- Enables billing features
- Configures production/sandbox modes

**Manual Setup Steps:**
1. Navigate to Clerk Dashboard > Configure > Billing
2. Click "Enable Billing"
3. Connect your Stripe account (or use sandbox mode for development)
4. Configure billing settings and defaults

### 2. Configure Pricing Plans

Create subscription plans and features:

```bash
# Run plan configuration script
bash ./skills/billing-integration/scripts/configure-plans.sh
```

**Configuration Process:**
1. Navigate to Dashboard > Configure > Subscription Plans
2. Click "Add User Plan" (B2C) or "Add Organization Plan" (B2B)
3. Enter plan details:
   - Name (e.g., "Pro Plan")
   - Slug (auto-generated, e.g., "pro_plan")
   - Description
   - Pricing (monthly/yearly)
4. Add features to plan:
   - Feature name (e.g., "AI Assistant")
   - Feature slug (e.g., "ai_assistant")
   - Feature description
5. Set feature limits if usage-based

**Plan Types:**
- **User Plans**: B2C subscriptions tied to individual users
- **Organization Plans**: B2B subscriptions for teams/companies
- **Free Tier**: Optional free plan with limited features
- **Trial Plans**: Time-limited free access to paid features

### 3. Implement Pricing Table

Add the pricing display component:

**Using Template:**
```bash
# Copy pricing page template
cp ./skills/billing-integration/templates/pricing-page.tsx app/pricing/page.tsx
```

**Basic Implementation:**
```typescript
import { PricingTable } from '@clerk/nextjs'

export default function PricingPage() {
  return (
    <div className="container mx-auto py-12">
      <h1 className="text-4xl font-bold text-center mb-8">
        Choose Your Plan
      </h1>
      <PricingTable />
    </div>
  )
}
```

**What PricingTable Provides:**
- Automatic plan rendering from Dashboard configuration
- Built-in payment form with Stripe Elements
- Subscription creation and management
- Responsive design matching Clerk UI
- Session-aware (shows current plan for logged-in users)

### 4. Implement Checkout Flow

Create a complete checkout experience:

```bash
# Copy checkout flow template
cp ./skills/billing-integration/templates/checkout-flow.tsx components/checkout-flow.tsx
```

**Checkout Features:**
- Plan selection and comparison
- Payment method collection
- Subscription confirmation
- Error handling
- Success redirects
- Email receipts (automatic via Stripe)

**Customization Options:**
```typescript
<PricingTable
  appearance={{
    theme: 'dark',
    variables: {
      colorPrimary: '#3b82f6',
      borderRadius: '0.5rem',
    }
  }}
  onSuccess={(subscription) => {
    // Custom success handler
    router.push('/dashboard')
  }}
/>
```

### 5. Access Control & Entitlements

Protect features based on subscription status:

**Frontend Protection:**
```typescript
import { useAuth } from '@clerk/nextjs'

export default function FeatureComponent() {
  const { has } = useAuth()
  const canUseFeature = has?.({ feature: 'ai_assistant' })

  if (!canUseFeature) {
    return <UpgradePrompt feature="AI Assistant" />
  }

  return <AIAssistantInterface />
}
```

**Backend Protection (API Routes):**
```typescript
import { auth } from '@clerk/nextjs/server'

export async function POST(request: Request) {
  const { has } = await auth()

  if (!has({ feature: 'ai_assistant' })) {
    return Response.json(
      { error: 'Subscription required' },
      { status: 403 }
    )
  }

  // Process request
}
```

**Organization-Level Access:**
```typescript
const { has } = useAuth()
const orgHasFeature = has?.({
  permission: 'org:billing:manage',
  feature: 'team_workspace'
})
```

### 6. Subscription Management

Enable users to manage subscriptions:

**Built-in Management:**
```typescript
import { UserButton } from '@clerk/nextjs'

export default function Navigation() {
  return (
    <UserButton afterSignOutUrl="/" />
  )
}
```

**What Users Can Access:**
- View current plan and features
- See invoice history
- Update payment methods
- Upgrade/downgrade plans
- Cancel subscriptions
- View upcoming renewals

**Custom Management Interface:**
```bash
# Copy subscription management template
cp ./skills/billing-integration/templates/subscription-management.tsx components/subscription-management.tsx
```

### 7. Webhook Handling (Optional)

While Clerk handles most webhook logic automatically, you may need custom webhooks for:
- Usage tracking
- Custom notifications
- Analytics integration
- Third-party service integration

```bash
# Setup webhook handlers
bash ./skills/billing-integration/scripts/setup-webhooks.sh
```

**Common Webhook Events:**
- `subscription.created` - New subscription
- `subscription.updated` - Plan change
- `subscription.deleted` - Cancellation
- `invoice.payment_succeeded` - Successful payment
- `invoice.payment_failed` - Failed payment

**Handler Templates:**
```bash
# Copy webhook handler templates
cp ./skills/billing-integration/templates/webhook-handlers/subscription-created.ts app/api/webhooks/subscription-created/route.ts
cp ./skills/billing-integration/templates/webhook-handlers/payment-succeeded.ts app/api/webhooks/payment-succeeded/route.ts
```

### 8. Testing & Development

**Sandbox Mode:**
- Use Clerk's sandbox mode for development
- No Stripe account required initially
- Test all billing flows without real payments
- Switch to production when ready

**Test Cards (Stripe):**
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
3D Secure: 4000 0027 6000 3184
```

**Testing Checklist:**
- [ ] Plan selection and display
- [ ] Payment form functionality
- [ ] Subscription creation
- [ ] Feature access control
- [ ] Plan upgrades/downgrades
- [ ] Subscription cancellation
- [ ] Invoice generation
- [ ] Email notifications

## Examples

### Example 1: Complete SaaS Billing Flow

```bash
# 1. Enable billing in Dashboard
bash ./skills/billing-integration/scripts/setup-billing.sh

# 2. Configure pricing plans
bash ./skills/billing-integration/scripts/configure-plans.sh

# 3. Implement pricing page
cp ./skills/billing-integration/templates/pricing-page.tsx app/pricing/page.tsx

# 4. Add subscription management
cp ./skills/billing-integration/templates/subscription-management.tsx components/subscription-management.tsx

# 5. Copy complete example
cp ./skills/billing-integration/examples/saas-billing-flow.tsx app/subscribe/page.tsx
```

**Result:** Full billing system with pricing display, checkout, and subscription management

### Example 2: Freemium Model with Feature Gates

**Setup:**
1. Create "Free" plan with basic features
2. Create "Pro" plan with premium features
3. Implement feature gates throughout app

**Implementation:**
```typescript
// Feature-gated component
import { useAuth } from '@clerk/nextjs'
import { PricingTable } from '@clerk/nextjs'

export default function PremiumFeature() {
  const { has } = useAuth()

  if (!has({ feature: 'premium_analytics' })) {
    return (
      <div className="border rounded-lg p-6">
        <h3>Premium Analytics</h3>
        <p>Upgrade to Pro to unlock advanced analytics</p>
        <PricingTable />
      </div>
    )
  }

  return <AdvancedAnalyticsDashboard />
}
```

### Example 3: Organization Billing (B2B)

**Setup:**
1. Enable Organization Plans in Dashboard
2. Configure team-based pricing
3. Implement organization billing interface

**Implementation:**
```typescript
import { useOrganization } from '@clerk/nextjs'

export default function OrgBilling() {
  const { organization } = useOrganization()

  return (
    <div>
      <h2>Billing for {organization?.name}</h2>
      <PricingTable mode="organization" />
    </div>
  )
}
```

### Example 4: Usage-Based Billing

**Setup:**
1. Configure usage-based features in Dashboard
2. Set usage limits per plan
3. Track usage in your application

**Implementation:**
```typescript
// Track API usage
import { clerkClient } from '@clerk/nextjs/server'

export async function POST(request: Request) {
  const { userId } = await auth()

  // Check current usage
  const user = await clerkClient.users.getUser(userId)
  const currentUsage = user.publicMetadata.apiUsage || 0

  // Check limit
  const { has } = await auth()
  const limit = has({ feature: 'api_calls_1000' }) ? 1000 : 100

  if (currentUsage >= limit) {
    return Response.json({ error: 'Usage limit reached' }, { status: 429 })
  }

  // Increment usage
  await clerkClient.users.updateUserMetadata(userId, {
    publicMetadata: {
      apiUsage: currentUsage + 1
    }
  })

  // Process request
}
```

## Requirements

**Clerk Setup:**
- Clerk account with application configured
- Clerk Billing enabled in Dashboard
- Next.js 13.4+ with App Router
- `@clerk/nextjs` version 5.0+

**Stripe Requirements:**
- Stripe account (production or test mode)
- Stripe publishable and secret keys
- Products and prices configured in Stripe (synced via Clerk)

**Environment Variables:**
```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
```

**Dependencies:**
```json
{
  "@clerk/nextjs": "^5.0.0",
  "next": "^14.0.0",
  "react": "^18.0.0"
}
```

**Project Structure:**
```
app/
├── pricing/
│   └── page.tsx          # Pricing page with PricingTable
├── subscribe/
│   └── page.tsx          # Checkout flow
├── api/
│   └── webhooks/         # Optional custom webhooks
components/
├── subscription-management.tsx
└── upgrade-prompt.tsx
```

## Security Best Practices

**Never Hardcode Credentials:**
```bash
# ❌ WRONG
STRIPE_SECRET_KEY=sk_live_actual_key_here

# ✅ CORRECT
STRIPE_SECRET_KEY=your_stripe_secret_key_here
```

**Always Use Environment Variables:**
```typescript
// ✅ Read from environment
const stripeKey = process.env.STRIPE_SECRET_KEY
if (!stripeKey) {
  throw new Error('STRIPE_SECRET_KEY not configured')
}
```

**Protect API Routes:**
- Always verify authentication with `auth()`
- Check feature entitlements on server-side
- Validate webhook signatures
- Use HTTPS in production

**Webhook Security:**
```typescript
import { headers } from 'next/headers'
import { stripe } from '@/lib/stripe'

export async function POST(request: Request) {
  const body = await request.text()
  const signature = headers().get('stripe-signature')

  try {
    const event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET
    )
    // Process event
  } catch (err) {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }
}
```

## Configuration Files

**Clerk Billing Settings (Dashboard):**
- Subscription plans and features
- Pricing tiers and intervals
- Trial period configuration
- Cancellation behavior
- Invoice settings
- Payment methods accepted

**Stripe Configuration (Synced):**
- Products → Clerk Plans
- Prices → Clerk Pricing Tiers
- Customers → Clerk Users
- Subscriptions → User/Org Subscriptions
- Payment Methods → Stored automatically

## Best Practices

**Plan Design:**
- Start with 2-3 clear tiers (Free, Pro, Enterprise)
- Make feature differences obvious
- Use clear, benefit-focused names
- Set appropriate price points
- Consider annual discounts

**User Experience:**
- Show current plan clearly
- Make upgrading easy (one-click from app)
- Provide grace period on cancellation
- Send clear email notifications
- Display usage limits proactively

**Access Control:**
- Always check entitlements server-side
- Use frontend checks for UX only
- Implement graceful degradation
- Show upgrade prompts at relevant moments
- Don't break existing functionality on downgrade

**Pricing Strategy:**
- Price based on value, not cost
- Use psychological pricing ($29 vs $30)
- Offer annual plans with discount
- Consider usage-based for scalability
- Test pricing with real users

**Monetization Approach:**
- Freemium: Free tier + paid upgrades
- Trial: 7-14 day free trial, then charge
- Tiered: Multiple plans with different features
- Usage-based: Pay per API call/user/feature
- Hybrid: Base fee + usage charges

## Integration with Clerk Features

**Organizations:**
- Enable organization billing for B2B
- Set per-seat pricing
- Allow organization admins to manage billing
- Track usage at organization level

**User Management:**
- Link subscriptions to user accounts
- Store subscription status in user metadata
- Use `publicMetadata` for client-accessible data
- Use `privateMetadata` for sensitive billing data

**Session Awareness:**
- PricingTable shows current plan when logged in
- Automatically handles upgrade flows
- Redirects to login if unauthenticated
- Preserves intended plan selection

## Troubleshooting

**Common Issues:**

1. **PricingTable not displaying:**
   - Verify Billing is enabled in Dashboard
   - Check plans are configured
   - Ensure Stripe is connected
   - Verify component import

2. **Payment failing:**
   - Check Stripe API keys
   - Verify webhook endpoint
   - Test with Stripe test cards
   - Review Stripe Dashboard logs

3. **Access control not working:**
   - Verify feature slugs match exactly
   - Check plan includes the feature
   - Ensure subscription is active
   - Test both client and server checks

4. **Webhooks not firing:**
   - Verify webhook URL is correct
   - Check webhook signing secret
   - Enable webhook forwarding for local dev
   - Review Clerk webhook logs

**Debugging:**
```typescript
// Log subscription status
const { has, debug } = useAuth()
console.log('Auth debug:', debug)
console.log('Has feature:', has({ feature: 'ai_assistant' }))
```

---

**Plugin:** clerk
**Version:** 1.0.0
**Category:** Billing & Monetization
**Skill Type:** Integration & Setup
