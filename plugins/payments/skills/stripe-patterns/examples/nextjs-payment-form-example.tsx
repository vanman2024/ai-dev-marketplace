/**
 * Complete Next.js Payment Form Example
 * Payment Intent workflow with Stripe Elements
 */
'use client';

import { useState, useEffect, FormEvent } from 'react';
import { loadStripe, StripeElementsOptions } from '@stripe/stripe-js';
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js';

// SECURITY: Load publishable key from environment variable
// NEVER hardcode API keys!
const stripePromise = loadStripe(
  process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY || 'your_stripe_publishable_key_here'
);

/**
 * Payment Form Component
 */
function PaymentForm({ amount, onSuccess }: { amount: number; onSuccess: () => void }) {
  const stripe = useStripe();
  const elements = useElements();

  const [isProcessing, setIsProcessing] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setIsProcessing(true);
    setMessage(null);

    try {
      const { error, paymentIntent } = await stripe.confirmPayment({
        elements,
        confirmParams: {
          return_url: `${window.location.origin}/payment-success`,
        },
        redirect: 'if_required',
      });

      if (error) {
        setMessage(error.message || 'Payment failed');
      } else if (paymentIntent && paymentIntent.status === 'succeeded') {
        setMessage('Payment successful!');
        onSuccess();
      }
    } catch (err) {
      setMessage('An unexpected error occurred');
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="bg-white p-6 rounded-lg shadow-md">
        <h2 className="text-xl font-semibold mb-4">Payment Details</h2>
        <PaymentElement />
      </div>

      {message && (
        <div
          className={`p-4 rounded-md ${
            message.includes('successful')
              ? 'bg-green-50 text-green-800'
              : 'bg-red-50 text-red-800'
          }`}
        >
          {message}
        </div>
      )}

      <button
        type="submit"
        disabled={!stripe || isProcessing}
        className="w-full bg-blue-600 text-white py-3 px-6 rounded-md font-semibold hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
      >
        {isProcessing ? 'Processing...' : `Pay $${(amount / 100).toFixed(2)}`}
      </button>

      <p className="text-xs text-gray-500 text-center">
        Your payment is secured by Stripe
      </p>
    </form>
  );
}

/**
 * Main Payment Page Component
 */
export default function PaymentPage() {
  const [clientSecret, setClientSecret] = useState<string>('');
  const [amount, setAmount] = useState<number>(2999); // $29.99
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Create Payment Intent on component mount
  useEffect(() => {
    createPaymentIntent(amount);
  }, []);

  const createPaymentIntent = async (amount: number) => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch('/api/payment-intents/create', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount,
          currency: 'usd',
          description: 'Product purchase',
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to create payment intent');
      }

      const data = await response.json();
      setClientSecret(data.client_secret);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleAmountChange = (newAmount: number) => {
    setAmount(newAmount);
    createPaymentIntent(newAmount);
  };

  const handlePaymentSuccess = () => {
    // Redirect to success page or show confirmation
    window.location.href = '/payment-success';
  };

  if (loading) {
    return (
      <div className="max-w-2xl mx-auto p-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4" />
            <p className="text-gray-600">Loading payment form...</p>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="max-w-2xl mx-auto p-6">
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <h3 className="text-red-800 font-semibold mb-2">Error</h3>
          <p className="text-red-700">{error}</p>
          <button
            onClick={() => createPaymentIntent(amount)}
            className="mt-4 text-red-800 underline"
          >
            Try again
          </button>
        </div>
      </div>
    );
  }

  const options: StripeElementsOptions = {
    clientSecret,
    appearance: {
      theme: 'stripe',
      variables: {
        colorPrimary: '#2563eb',
      },
    },
  };

  return (
    <div className="max-w-2xl mx-auto p-6">
      {/* Product Summary */}
      <div className="bg-white rounded-lg shadow-md p-6 mb-6">
        <h1 className="text-2xl font-bold mb-4">Complete Your Purchase</h1>

        <div className="space-y-3">
          <div className="flex justify-between">
            <span className="text-gray-600">Product</span>
            <span className="font-semibold">Premium Plan</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">Price</span>
            <span className="font-semibold">${(amount / 100).toFixed(2)}</span>
          </div>
          <div className="border-t pt-3 mt-3">
            <div className="flex justify-between text-lg font-bold">
              <span>Total</span>
              <span>${(amount / 100).toFixed(2)}</span>
            </div>
          </div>
        </div>

        {/* Amount Selector (for demo) */}
        <div className="mt-6 pt-6 border-t">
          <label className="block text-sm font-medium mb-2">
            Select Amount (Demo)
          </label>
          <div className="flex gap-2">
            {[999, 2999, 9999].map((price) => (
              <button
                key={price}
                onClick={() => handleAmountChange(price)}
                className={`px-4 py-2 rounded-md border ${
                  amount === price
                    ? 'bg-blue-600 text-white border-blue-600'
                    : 'bg-white text-gray-700 border-gray-300 hover:border-blue-600'
                }`}
              >
                ${(price / 100).toFixed(2)}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Payment Form */}
      {clientSecret && (
        <Elements stripe={stripePromise} options={options}>
          <PaymentForm amount={amount} onSuccess={handlePaymentSuccess} />
        </Elements>
      )}

      {/* Test Mode Notice */}
      {process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY?.includes('test') && (
        <div className="mt-6 bg-yellow-50 border border-yellow-200 rounded-md p-4">
          <p className="text-yellow-800 text-sm">
            <strong>Test Mode:</strong> Use card 4242 4242 4242 4242 with any
            future date and CVC
          </p>
        </div>
      )}
    </div>
  );
}

/**
 * API Route Example (app/api/payment-intents/create/route.ts):
 *
 * import { NextRequest, NextResponse } from 'next/server';
 * import Stripe from 'stripe';
 *
 * // SECURITY: Load secret key from environment variable
 * const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
 *   apiVersion: '2023-10-16',
 * });
 *
 * export async function POST(request: NextRequest) {
 *   try {
 *     const { amount, currency, description } = await request.json();
 *
 *     const paymentIntent = await stripe.paymentIntents.create({
 *       amount,
 *       currency: currency || 'usd',
 *       description,
 *       automatic_payment_methods: {
 *         enabled: true,
 *       },
 *     });
 *
 *     return NextResponse.json({
 *       payment_intent_id: paymentIntent.id,
 *       client_secret: paymentIntent.client_secret,
 *       status: paymentIntent.status,
 *     });
 *   } catch (error) {
 *     return NextResponse.json(
 *       { error: error instanceof Error ? error.message : 'Unknown error' },
 *       { status: 500 }
 *     );
 *   }
 * }
 */

/**
 * Environment Setup (.env.local):
 *
 * NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key_here
 * STRIPE_SECRET_KEY=your_stripe_secret_key_here
 */

/**
 * Dependencies (package.json):
 *
 * npm install @stripe/stripe-js @stripe/react-stripe-js stripe
 */
