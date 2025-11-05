/**
 * Stripe Checkout Page Template
 * Complete checkout flow with product display and Checkout Session redirect
 */
'use client';

import { useState } from 'react';
import { loadStripe } from '@stripe/stripe-js';

// SECURITY: Load publishable key from environment variable
// NEVER hardcode API keys in frontend code!
const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || 'your_stripe_publishable_key_here'
);

interface Product {
  id: string;
  name: string;
  description: string;
  price: number; // in cents
  currency: string;
  image?: string;
}

interface CheckoutPageProps {
  product: Product;
  priceId?: string; // Optional: Use existing Stripe Price ID
}

export default function CheckoutPage({ product, priceId }: CheckoutPageProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [quantity, setQuantity] = useState(1);

  const handleCheckout = async () => {
    setIsLoading(true);
    setError(null);

    try {
      // Create Checkout Session on backend
      const response = await fetch('/api/checkout/create-session', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          line_items: [
            {
              price_id: priceId,
              name: product.name,
              amount: product.price,
              currency: product.currency,
              quantity: quantity,
            },
          ],
          mode: 'payment',
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to create checkout session');
      }

      const { url } = await response.json();

      // Redirect to Stripe Checkout
      window.location.href = url;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      setIsLoading(false);
    }
  };

  const totalPrice = (product.price * quantity) / 100;

  return (
    <div className="max-w-2xl mx-auto p-6">
      {/* Product Display */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <div className="flex gap-6">
          {/* Product Image */}
          {product.image && (
            <div className="flex-shrink-0">
              <img
                src={product.image}
                alt={product.name}
                className="w-32 h-32 object-cover rounded-md"
              />
            </div>
          )}

          {/* Product Details */}
          <div className="flex-grow">
            <h1 className="text-2xl font-bold mb-2">{product.name}</h1>
            <p className="text-gray-600 mb-4">{product.description}</p>

            <div className="flex items-center gap-4 mb-4">
              <span className="text-3xl font-bold">
                ${(product.price / 100).toFixed(2)}
              </span>
              <span className="text-gray-500 uppercase">{product.currency}</span>
            </div>

            {/* Quantity Selector */}
            <div className="flex items-center gap-2">
              <label htmlFor="quantity" className="text-sm font-medium">
                Quantity:
              </label>
              <select
                id="quantity"
                value={quantity}
                onChange={(e) => setQuantity(Number(e.target.value))}
                className="border rounded-md px-3 py-1"
              >
                {[1, 2, 3, 4, 5, 10].map((num) => (
                  <option key={num} value={num}>
                    {num}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>
      </div>

      {/* Order Summary */}
      <div className="bg-gray-50 rounded-lg p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">Order Summary</h2>

        <div className="space-y-2">
          <div className="flex justify-between">
            <span>Subtotal ({quantity} item{quantity > 1 ? 's' : ''})</span>
            <span>${totalPrice.toFixed(2)}</span>
          </div>
          <div className="flex justify-between text-sm text-gray-600">
            <span>Taxes</span>
            <span>Calculated at checkout</span>
          </div>
          <div className="border-t pt-2 mt-2">
            <div className="flex justify-between font-bold text-lg">
              <span>Total</span>
              <span>${totalPrice.toFixed(2)}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-md p-4 mb-6">
          <p className="text-red-800 text-sm">{error}</p>
        </div>
      )}

      {/* Checkout Button */}
      <button
        onClick={handleCheckout}
        disabled={isLoading}
        className="w-full bg-blue-600 text-white py-3 px-6 rounded-md font-semibold hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed transition-colors"
      >
        {isLoading ? (
          <span className="flex items-center justify-center gap-2">
            <svg
              className="animate-spin h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            Processing...
          </span>
        ) : (
          `Proceed to Checkout`
        )}
      </button>

      {/* Security Badge */}
      <div className="mt-6 flex items-center justify-center gap-2 text-sm text-gray-500">
        <svg
          className="w-4 h-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={2}
            d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
          />
        </svg>
        <span>Secure checkout powered by Stripe</span>
      </div>

      {/* Test Mode Notice */}
      {process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY?.includes('test') && (
        <div className="mt-4 bg-yellow-50 border border-yellow-200 rounded-md p-4">
          <p className="text-yellow-800 text-sm">
            <strong>Test Mode:</strong> Use test card 4242 4242 4242 4242
          </p>
        </div>
      )}
    </div>
  );
}

/**
 * Success Page Example:
 *
 * // app/success/page.tsx
 * 'use client';
 *
 * import { useEffect, useState } from 'react';
 * import { useSearchParams } from 'next/navigation';
 *
 * export default function SuccessPage() {
 *   const searchParams = useSearchParams();
 *   const sessionId = searchParams.get('session_id');
 *   const [session, setSession] = useState(null);
 *
 *   useEffect(() => {
 *     if (sessionId) {
 *       fetch(`/api/checkout/session/${sessionId}`)
 *         .then(res => res.json())
 *         .then(data => setSession(data));
 *     }
 *   }, [sessionId]);
 *
 *   return (
 *     <div className="max-w-md mx-auto p-6 text-center">
 *       <div className="text-green-500 text-6xl mb-4">✓</div>
 *       <h1 className="text-2xl font-bold mb-2">Payment Successful!</h1>
 *       <p className="text-gray-600">
 *         Your order has been confirmed.
 *       </p>
 *       {session && (
 *         <div className="mt-6 bg-gray-50 p-4 rounded-md">
 *           <p className="text-sm">Order ID: {session.id}</p>
 *           <p className="text-sm">Amount: ${(session.amount_total / 100).toFixed(2)}</p>
 *         </div>
 *       )}
 *     </div>
 *   );
 * }
 *
 * // Cancel Page Example:
 * // app/cancel/page.tsx
 * export default function CancelPage() {
 *   return (
 *     <div className="max-w-md mx-auto p-6 text-center">
 *       <h1 className="text-2xl font-bold mb-2">Checkout Canceled</h1>
 *       <p className="text-gray-600 mb-6">
 *         Your payment was not processed.
 *       </p>
 *       <a
 *         href="/checkout"
 *         className="text-blue-600 hover:underline"
 *       >
 *         Return to checkout
 *       </a>
 *     </div>
 *   );
 * }
 */
