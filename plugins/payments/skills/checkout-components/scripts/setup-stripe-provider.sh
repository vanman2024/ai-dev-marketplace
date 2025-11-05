#!/bin/bash

# Setup Stripe provider wrapper for Next.js application
# Usage: bash setup-stripe-provider.sh

set -e

echo "Setting up Stripe provider..."

# Create lib directory if it doesn't exist
mkdir -p lib

# Create stripe-client.ts
cat > lib/stripe-client.ts << 'EOF'
import { loadStripe, Stripe } from '@stripe/stripe-js';

// SECURITY: Only publishable key (safe for client-side)
// NEVER expose secret key client-side
const stripePublishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;

if (!stripePublishableKey) {
  throw new Error(
    'NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is not set. ' +
    'Add it to your .env.local file: ' +
    'NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here'
  );
}

// Singleton pattern - load Stripe.js only once
let stripePromise: Promise<Stripe | null>;

export const getStripe = () => {
  if (!stripePromise) {
    stripePromise = loadStripe(stripePublishableKey);
  }
  return stripePromise;
};
EOF

echo "✅ Created lib/stripe-client.ts"

# Create components/providers directory
mkdir -p components/providers

# Create stripe-provider.tsx
cat > components/providers/stripe-provider.tsx << 'EOF'
'use client';

import { Elements } from '@stripe/react-stripe-js';
import { getStripe } from '@/lib/stripe-client';
import { ReactNode } from 'react';

interface StripeProviderProps {
  children: ReactNode;
}

export function StripeProvider({ children }: StripeProviderProps) {
  const stripePromise = getStripe();

  // Customize Stripe Elements appearance
  const appearance = {
    theme: 'stripe' as const,
    variables: {
      colorPrimary: '#0070f3',
      colorBackground: '#ffffff',
      colorText: '#000000',
      colorDanger: '#df1b41',
      fontFamily: 'system-ui, -apple-system, sans-serif',
      spacingUnit: '4px',
      borderRadius: '8px',
    },
  };

  const options = {
    appearance,
  };

  return (
    <Elements stripe={stripePromise} options={options}>
      {children}
    </Elements>
  );
}
EOF

echo "✅ Created components/providers/stripe-provider.tsx"

# Create or update .env.example
if [ ! -f ".env.example" ]; then
  cat > .env.example << 'EOF'
# Stripe Configuration
# Get your keys from: https://dashboard.stripe.com/apikeys

# Public key (safe for client-side, starts with pk_test_ or pk_live_)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here

# Secret key (server-side ONLY, starts with sk_test_ or sk_live_)
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here

# Webhook secret (from Stripe webhook settings)
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here

# Optional: Default currency
NEXT_PUBLIC_STRIPE_CURRENCY=usd

# Optional: App URL for redirects
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
  echo "✅ Created .env.example"
else
  echo "ℹ️  .env.example already exists (not modified)"
fi

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
  echo ""
  echo "⚠️  WARNING: .env.local not found"
  echo "   Create it with: cp .env.example .env.local"
  echo "   Then add your actual Stripe keys"
fi

# Update .gitignore
if [ -f ".gitignore" ]; then
  if ! grep -q ".env.local" .gitignore; then
    cat >> .gitignore << 'EOF'

# Environment variables (NEVER commit actual keys)
.env.local
.env.*.local
.env
EOF
    echo "✅ Updated .gitignore"
  else
    echo "ℹ️  .gitignore already contains .env protection"
  fi
fi

echo ""
echo "✅ Stripe provider setup complete!"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure environment variables:"
echo "   cp .env.example .env.local"
echo "   # Edit .env.local with your actual Stripe keys"
echo ""
echo "2. Wrap your app with StripeProvider in app/layout.tsx:"
echo ""
echo "   import { StripeProvider } from '@/components/providers/stripe-provider';"
echo ""
echo "   export default function RootLayout({ children }) {"
echo "     return ("
echo "       <html>"
echo "         <body>"
echo "           <StripeProvider>"
echo "             {children}"
echo "           </StripeProvider>"
echo "         </body>"
echo "       </html>"
echo "     );"
echo "   }"
echo ""
echo "3. Get your Stripe keys:"
echo "   - Test keys: https://dashboard.stripe.com/test/apikeys"
echo "   - Live keys: https://dashboard.stripe.com/apikeys"
echo ""
