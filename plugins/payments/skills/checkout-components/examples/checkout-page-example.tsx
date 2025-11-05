'use client';

/**
 * Complete Checkout Page Example
 *
 * Demonstrates:
 * - Order summary with items
 * - Checkout form integration
 * - Success/error handling
 * - Loading states
 * - Receipt generation
 */

import { useState } from 'use client';
import { useRouter } from 'next/navigation';
import { CheckoutForm } from '@/components/payments/checkoutform';
import { StripeProvider } from '@/components/providers/stripe-provider';

interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

export default function CheckoutPage() {
  const router = useRouter();
  const [cartItems] = useState<CartItem[]>([
    { id: '1', name: 'Pro Plan - Monthly', price: 2999, quantity: 1 },
    { id: '2', name: 'Additional API Credits', price: 999, quantity: 2 },
  ]);

  const calculateTotal = () => {
    return cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);
  };

  const formatAmount = (cents: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(cents / 100);
  };

  const handleSuccess = async (paymentIntentId: string) => {
    // Save order to database
    try {
      await fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          paymentIntentId,
          items: cartItems,
          total: calculateTotal(),
        }),
      });

      // Redirect to success page
      router.push(`/checkout/success?payment_intent=${paymentIntentId}`);
    } catch (error) {
      console.error('Failed to save order:', error);
    }
  };

  const handleError = (error: any) => {
    console.error('Payment error:', error);
    // Could show toast notification here
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Checkout</h1>
          <p className="mt-2 text-sm text-gray-600">
            Complete your purchase securely with Stripe
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8">
          {/* Order Summary */}
          <div className="bg-white p-6 rounded-lg border border-gray-200 h-fit">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Order Summary</h2>

            {/* Cart Items */}
            <ul className="divide-y divide-gray-200 mb-6" role="list">
              {cartItems.map((item) => (
                <li key={item.id} className="py-4 flex justify-between">
                  <div>
                    <h3 className="text-sm font-medium text-gray-900">{item.name}</h3>
                    <p className="text-sm text-gray-600 mt-1">Qty: {item.quantity}</p>
                  </div>
                  <span className="text-sm font-medium text-gray-900">
                    {formatAmount(item.price * item.quantity)}
                  </span>
                </li>
              ))}
            </ul>

            {/* Subtotal and Total */}
            <div className="space-y-2 pt-4 border-t border-gray-200">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Subtotal</span>
                <span className="text-gray-900">{formatAmount(calculateTotal())}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Tax</span>
                <span className="text-gray-900">Calculated at checkout</span>
              </div>
              <div className="flex justify-between text-lg font-semibold pt-2 border-t border-gray-200">
                <span className="text-gray-900">Total</span>
                <span className="text-gray-900">{formatAmount(calculateTotal())}</span>
              </div>
            </div>

            {/* Security Badges */}
            <div className="mt-6 pt-6 border-t border-gray-200">
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <svg
                  className="h-5 w-5 text-green-500"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"
                  />
                </svg>
                Secure checkout powered by Stripe
              </div>
            </div>
          </div>

          {/* Payment Form */}
          <div className="bg-white p-6 rounded-lg border border-gray-200">
            <h2 className="text-xl font-semibold text-gray-900 mb-6">
              Payment Information
            </h2>

            <StripeProvider>
              <CheckoutForm
                amount={calculateTotal()}
                onSuccess={handleSuccess}
                onError={handleError}
                buttonText={`Pay ${formatAmount(calculateTotal())}`}
              />
            </StripeProvider>

            {/* Additional Info */}
            <div className="mt-6 pt-6 border-t border-gray-200 space-y-3">
              <div className="flex items-start gap-2">
                <svg
                  className="h-5 w-5 text-gray-400 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    Your payment is secure
                  </p>
                  <p className="text-sm text-gray-600">
                    We use industry-standard encryption to protect your data
                  </p>
                </div>
              </div>

              <div className="flex items-start gap-2">
                <svg
                  className="h-5 w-5 text-gray-400 mt-0.5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                <div>
                  <p className="text-sm font-medium text-gray-900">Money-back guarantee</p>
                  <p className="text-sm text-gray-600">
                    Full refund within 30 days if you're not satisfied
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Trust Indicators */}
        <div className="mt-12 text-center">
          <p className="text-sm text-gray-600 mb-4">Trusted by 10,000+ customers worldwide</p>
          <div className="flex justify-center items-center gap-8 opacity-50">
            {/* Add company logos or trust badges here */}
          </div>
        </div>
      </div>
    </div>
  );
}
