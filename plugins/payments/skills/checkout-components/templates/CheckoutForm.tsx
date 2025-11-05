'use client';

import { useState, FormEvent } from 'react';
import {
  useStripe,
  useElements,
  CardElement,
  PaymentElement,
} from '@stripe/react-stripe-js';
import type { StripeError } from '@stripe/stripe-js';

interface CheckoutFormProps {
  /** Amount in cents (e.g., 4999 = $49.99) */
  amount: number;
  /** Currency code (default: 'usd') */
  currency?: string;
  /** Callback on successful payment */
  onSuccess?: (paymentIntentId: string) => void;
  /** Callback on payment error */
  onError?: (error: StripeError) => void;
  /** Custom button text (default: 'Pay Now') */
  buttonText?: string;
  /** Custom CSS classes */
  className?: string;
  /** Custom button CSS classes */
  buttonClassName?: string;
  /** Use PaymentElement instead of CardElement (supports more payment methods) */
  usePaymentElement?: boolean;
}

/**
 * CheckoutForm - Complete checkout form with Stripe CardElement or PaymentElement
 *
 * Usage:
 * ```tsx
 * import { CheckoutForm } from '@/components/payments/checkoutform';
 *
 * export default function CheckoutPage() {
 *   return (
 *     <div className="max-w-md mx-auto p-6">
 *       <CheckoutForm
 *         amount={4999}
 *         onSuccess={(id) => router.push(`/success?payment=${id}`)}
 *         onError={(error) => console.error(error)}
 *       />
 *     </div>
 *   );
 * }
 * ```
 *
 * Requires:
 * - Server-side API route at /api/create-payment-intent
 * - StripeProvider wrapping this component
 */
export function CheckoutForm({
  amount,
  currency = 'usd',
  onSuccess,
  onError,
  buttonText = 'Pay Now',
  className = '',
  buttonClassName = '',
  usePaymentElement = false,
}: CheckoutFormProps) {
  const stripe = useStripe();
  const elements = useElements();

  const [error, setError] = useState<string | null>(null);
  const [processing, setProcessing] = useState(false);
  const [succeeded, setSucceeded] = useState(false);
  const [clientSecret, setClientSecret] = useState<string | null>(null);

  // Create payment intent when component mounts
  const createPaymentIntent = async () => {
    try {
      const response = await fetch('/api/create-payment-intent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount, currency }),
      });

      if (!response.ok) {
        throw new Error('Failed to create payment intent');
      }

      const data = await response.json();
      setClientSecret(data.clientSecret);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to initialize payment');
    }
  };

  // Initialize payment intent
  if (!clientSecret && !processing && !error) {
    createPaymentIntent();
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setProcessing(true);
    setError(null);

    try {
      let result;

      if (usePaymentElement) {
        // Use PaymentElement (supports multiple payment methods)
        result = await stripe.confirmPayment({
          elements,
          confirmParams: {
            return_url: `${window.location.origin}/payment/success`,
          },
          redirect: 'if_required',
        });
      } else {
        // Use CardElement (card payments only)
        const cardElement = elements.getElement(CardElement);

        if (!cardElement) {
          throw new Error('Card element not found');
        }

        if (!clientSecret) {
          throw new Error('Payment intent not initialized');
        }

        result = await stripe.confirmCardPayment(clientSecret, {
          payment_method: {
            card: cardElement,
          },
        });
      }

      if (result.error) {
        setError(result.error.message || 'An error occurred');
        onError?.(result.error);
      } else {
        setSucceeded(true);
        onSuccess?.(result.paymentIntent.id);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Payment failed';
      setError(errorMessage);
      onError?.({ type: 'api_error', message: errorMessage } as StripeError);
    } finally {
      setProcessing(false);
    }
  };

  const formatAmount = (cents: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
    }).format(cents / 100);
  };

  const cardElementOptions = {
    style: {
      base: {
        fontSize: '16px',
        color: '#000000',
        fontFamily: 'system-ui, sans-serif',
        '::placeholder': {
          color: '#9ca3af',
        },
      },
      invalid: {
        color: '#df1b41',
        iconColor: '#df1b41',
      },
    },
    hidePostalCode: false,
  };

  return (
    <form
      onSubmit={handleSubmit}
      className={`space-y-6 ${className}`}
      aria-label="Payment form"
    >
      {/* Amount Display */}
      <div className="bg-gray-50 p-4 rounded-lg">
        <p className="text-sm text-gray-600">Amount to pay</p>
        <p className="text-2xl font-semibold text-gray-900" aria-live="polite">
          {formatAmount(amount)}
        </p>
      </div>

      {/* Payment Element or Card Element */}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">
          Payment Details
        </label>

        {usePaymentElement ? (
          <div className="p-4 border border-gray-300 rounded-lg">
            <PaymentElement />
          </div>
        ) : (
          <div className="p-4 border border-gray-300 rounded-lg">
            <CardElement options={cardElementOptions} />
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div
          className="p-4 bg-red-50 border border-red-200 rounded-lg"
          role="alert"
          aria-live="assertive"
        >
          <p className="text-sm text-red-800">{error}</p>
        </div>
      )}

      {/* Success Message */}
      {succeeded && (
        <div
          className="p-4 bg-green-50 border border-green-200 rounded-lg"
          role="status"
          aria-live="polite"
        >
          <p className="text-sm text-green-800">Payment successful!</p>
        </div>
      )}

      {/* Submit Button */}
      <button
        type="submit"
        disabled={!stripe || processing || succeeded}
        className={`w-full py-3 px-4 rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 ${
          !stripe || processing || succeeded
            ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
            : 'bg-blue-600 text-white hover:bg-blue-700'
        } ${buttonClassName}`}
        aria-label={processing ? 'Processing payment' : buttonText}
        aria-disabled={!stripe || processing || succeeded}
      >
        {processing ? (
          <span className="flex items-center justify-center gap-2">
            <svg
              className="animate-spin h-5 w-5"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              aria-hidden="true"
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
        ) : succeeded ? (
          'Payment Complete'
        ) : (
          buttonText
        )}
      </button>

      {/* Stripe Branding */}
      <p className="text-xs text-center text-gray-500">
        Powered by{' '}
        <a
          href="https://stripe.com"
          target="_blank"
          rel="noopener noreferrer"
          className="underline hover:text-gray-700"
        >
          Stripe
        </a>
      </p>
    </form>
  );
}
