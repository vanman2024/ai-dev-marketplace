'use client';

import { Elements } from '@stripe/react-stripe-js';
import { loadStripe } from '@stripe/stripe-js';
import { ReactNode, useMemo } from 'react';

// SECURITY: Only use publishable key client-side
// NEVER expose secret key (sk_test_ or sk_live_) in client components
const stripePublishableKey = process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY;

if (!stripePublishableKey) {
  console.error(
    'NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is not configured. ' +
      'Add to .env.local: NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here'
  );
}

interface StripeProviderProps {
  children: ReactNode;
}

/**
 * StripeProvider - Wraps app with Stripe Elements context
 *
 * Usage in app/layout.tsx:
 * ```tsx
 * import { StripeProvider } from '@/components/providers/stripe-provider';
 *
 * export default function RootLayout({ children }) {
 *   return (
 *     <html>
 *       <body>
 *         <StripeProvider>
 *           {children}
 *         </StripeProvider>
 *       </body>
 *     </html>
 *   );
 * }
 * ```
 */
export function StripeProvider({ children }: StripeProviderProps) {
  const stripePromise = useMemo(() => {
    if (!stripePublishableKey) return null;
    return loadStripe(stripePublishableKey);
  }, []);

  // Customize Stripe Elements appearance
  const appearance = {
    theme: 'stripe' as const,
    variables: {
      colorPrimary: '#0070f3',
      colorBackground: '#ffffff',
      colorText: '#000000',
      colorDanger: '#df1b41',
      fontFamily: 'system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
      spacingUnit: '4px',
      borderRadius: '8px',
      fontSizeBase: '16px',
    },
    rules: {
      '.Input': {
        border: '1px solid #e5e7eb',
        boxShadow: 'none',
      },
      '.Input:focus': {
        border: '1px solid #0070f3',
        boxShadow: '0 0 0 3px rgba(0, 112, 243, 0.1)',
      },
      '.Input--invalid': {
        border: '1px solid #df1b41',
      },
      '.Label': {
        fontWeight: '500',
        marginBottom: '8px',
      },
    },
  };

  const options = {
    appearance,
  };

  if (!stripePromise) {
    return (
      <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
        <p className="text-yellow-800 font-medium">Stripe Configuration Error</p>
        <p className="text-sm text-yellow-700 mt-1">
          NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY is not set. Please add it to your .env.local file.
        </p>
      </div>
    );
  }

  return (
    <Elements stripe={stripePromise} options={options}>
      {children}
    </Elements>
  );
}
