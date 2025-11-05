/**
 * Stripe Elements Component Template
 * Payment form with card input and Payment Intent confirmation
 */
'use client';

import { useState, FormEvent } from 'react';
import {
  PaymentElement,
  useStripe,
  useElements,
} from '@stripe/react-stripe-js';

interface StripePaymentFormProps {
  amount: number;
  currency?: string;
  onSuccess?: (paymentIntentId: string) => void;
  onError?: (error: string) => void;
}

export default function StripePaymentForm({
  amount,
  currency = 'usd',
  onSuccess,
  onError,
}: StripePaymentFormProps) {
  const stripe = useStripe();
  const elements = useElements();

  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();

    if (!stripe || !elements) {
      // Stripe.js hasn't loaded yet
      return;
    }

    setIsLoading(true);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      // Confirm payment with Stripe
      const { error, paymentIntent } = await stripe.confirmPayment({
        elements,
        confirmParams: {
          // Return URL after payment completion
          return_url: `${window.location.origin}/payment/success`,
        },
        redirect: 'if_required', // Only redirect if 3D Secure required
      });

      if (error) {
        // Payment failed
        setErrorMessage(error.message || 'Payment failed');
        onError?.(error.message || 'Payment failed');
      } else if (paymentIntent && paymentIntent.status === 'succeeded') {
        // Payment succeeded
        setSuccessMessage('Payment successful!');
        onSuccess?.(paymentIntent.id);
      }
    } catch (err) {
      setErrorMessage('An unexpected error occurred');
      onError?.('An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Payment Element - Includes card input and other payment methods */}
      <div>
        <PaymentElement
          options={{
            layout: 'tabs',
          }}
        />
      </div>

      {/* Error Message */}
      {errorMessage && (
        <div className="rounded-md bg-red-50 p-4">
          <p className="text-sm text-red-800">{errorMessage}</p>
        </div>
      )}

      {/* Success Message */}
      {successMessage && (
        <div className="rounded-md bg-green-50 p-4">
          <p className="text-sm text-green-800">{successMessage}</p>
        </div>
      )}

      {/* Submit Button */}
      <button
        type="submit"
        disabled={!stripe || isLoading}
        className="w-full rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
      >
        {isLoading ? 'Processing...' : `Pay $${(amount / 100).toFixed(2)}`}
      </button>

      {/* Security Note */}
      <p className="text-xs text-gray-500 text-center">
        Secured by Stripe. Your payment information is encrypted.
      </p>
    </form>
  );
}

/**
 * Usage Example:
 *
 * import { Elements } from '@stripe/react-stripe-js';
 * import { loadStripe } from '@stripe/stripe-js';
 * import StripePaymentForm from './stripe_elements';
 *
 * // SECURITY: Load publishable key from environment variable
 * const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!);
 *
 * export default function CheckoutPage() {
 *   const [clientSecret, setClientSecret] = useState('');
 *
 *   useEffect(() => {
 *     // Create Payment Intent on backend
 *     fetch('/api/payment-intents/create', {
 *       method: 'POST',
 *       headers: { 'Content-Type': 'application/json' },
 *       body: JSON.stringify({ amount: 2999 }) // $29.99
 *     })
 *       .then(res => res.json())
 *       .then(data => setClientSecret(data.client_secret));
 *   }, []);
 *
 *   if (!clientSecret) {
 *     return <div>Loading...</div>;
 *   }
 *
 *   return (
 *     <Elements stripe={stripePromise} options={{ clientSecret }}>
 *       <StripePaymentForm
 *         amount={2999}
 *         onSuccess={(id) => console.log('Payment succeeded:', id)}
 *         onError={(error) => console.error('Payment failed:', error)}
 *       />
 *     </Elements>
 *   );
 * }
 */
