'use client';

import { useState, FormEvent } from 'react';
import { useStripe, useElements, CardElement } from '@stripe/react-stripe-js';
import type { StripeError } from '@stripe/stripe-js';

interface PaymentMethodFormProps {
  /** Stripe customer ID to attach payment method to */
  customerId?: string;
  /** Callback when payment method is successfully created */
  onComplete?: (paymentMethodId: string) => void;
  /** Callback on error */
  onError?: (error: StripeError) => void;
  /** Custom button text (default: 'Save Payment Method') */
  buttonText?: string;
  /** Show billing details fields (default: false) */
  collectBillingDetails?: boolean;
  /** Custom CSS classes */
  className?: string;
}

/**
 * PaymentMethodForm - Collect and save payment methods for future use
 *
 * Usage:
 * ```tsx
 * import { PaymentMethodForm } from '@/components/payments/paymentmethodform';
 *
 * export default function AddCard() {
 *   return (
 *     <PaymentMethodForm
 *       customerId="cus_xxx"
 *       onComplete={(pmId) => {
 *         console.log('Payment method created:', pmId);
 *         router.push('/payment-methods');
 *       }}
 *     />
 *   );
 * }
 * ```
 */
export function PaymentMethodForm({
  customerId,
  onComplete,
  onError,
  buttonText = 'Save Payment Method',
  collectBillingDetails = false,
  className = '',
}: PaymentMethodFormProps) {
  const stripe = useStripe();
  const elements = useElements();

  const [error, setError] = useState<string | null>(null);
  const [processing, setProcessing] = useState(false);
  const [succeeded, setSucceeded] = useState(false);

  // Billing details state
  const [billingDetails, setBillingDetails] = useState({
    name: '',
    email: '',
    address: {
      line1: '',
      city: '',
      state: '',
      postal_code: '',
      country: 'US',
    },
  });

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setProcessing(true);
    setError(null);

    try {
      const cardElement = elements.getElement(CardElement);

      if (!cardElement) {
        throw new Error('Card element not found');
      }

      // Create payment method
      const { error: pmError, paymentMethod } = await stripe.createPaymentMethod({
        type: 'card',
        card: cardElement,
        billing_details: collectBillingDetails ? billingDetails : undefined,
      });

      if (pmError) {
        setError(pmError.message || 'Failed to create payment method');
        onError?.(pmError);
        return;
      }

      // Attach payment method to customer (server-side)
      if (customerId && paymentMethod) {
        const response = await fetch('/api/attach-payment-method', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            paymentMethodId: paymentMethod.id,
            customerId,
          }),
        });

        if (!response.ok) {
          throw new Error('Failed to attach payment method to customer');
        }
      }

      setSucceeded(true);
      onComplete?.(paymentMethod?.id || '');
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred';
      setError(errorMessage);
      onError?.({ type: 'api_error', message: errorMessage } as StripeError);
    } finally {
      setProcessing(false);
    }
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
  };

  return (
    <form
      onSubmit={handleSubmit}
      className={`space-y-6 ${className}`}
      aria-label="Payment method form"
    >
      {/* Billing Details (Optional) */}
      {collectBillingDetails && (
        <div className="space-y-4">
          <h3 className="text-lg font-medium text-gray-900">Billing Details</h3>

          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700">
              Full Name
            </label>
            <input
              type="text"
              id="name"
              value={billingDetails.name}
              onChange={(e) =>
                setBillingDetails({ ...billingDetails, name: e.target.value })
              }
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
              required={collectBillingDetails}
            />
          </div>

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700">
              Email
            </label>
            <input
              type="email"
              id="email"
              value={billingDetails.email}
              onChange={(e) =>
                setBillingDetails({ ...billingDetails, email: e.target.value })
              }
              className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
              required={collectBillingDetails}
            />
          </div>
        </div>
      )}

      {/* Card Element */}
      <div className="space-y-2">
        <label className="block text-sm font-medium text-gray-700">
          Card Information
        </label>
        <div className="p-4 border border-gray-300 rounded-lg">
          <CardElement options={cardElementOptions} />
        </div>
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
          <p className="text-sm text-green-800">Payment method saved successfully!</p>
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
        }`}
        aria-label={processing ? 'Saving payment method' : buttonText}
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
            Saving...
          </span>
        ) : succeeded ? (
          'Saved'
        ) : (
          buttonText
        )}
      </button>

      {/* Security Note */}
      <p className="text-xs text-center text-gray-500">
        Your payment information is encrypted and secure. We never store your card details.
      </p>
    </form>
  );
}
