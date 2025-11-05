'use client';

/**
 * Multi-Step Payment Form Integration Example
 *
 * Demonstrates:
 * - Multi-step checkout flow
 * - Shipping information collection
 * - Payment details with CheckoutForm
 * - Order confirmation
 * - Progress indicator
 * - Form validation
 */

import { useState } from 'react';
import { CheckoutForm } from '@/components/payments/checkoutform';
import { StripeProvider } from '@/components/providers/stripe-provider';

type Step = 'shipping' | 'payment' | 'confirmation';

interface ShippingInfo {
  fullName: string;
  email: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
}

export default function MultiStepCheckout() {
  const [currentStep, setCurrentStep] = useState<Step>('shipping');
  const [shippingInfo, setShippingInfo] = useState<ShippingInfo>({
    fullName: '',
    email: '',
    address: '',
    city: '',
    state: '',
    zipCode: '',
    country: 'US',
  });
  const [paymentIntentId, setPaymentIntentId] = useState<string>('');

  const orderAmount = 4999; // $49.99

  const steps: { id: Step; name: string; description: string }[] = [
    { id: 'shipping', name: 'Shipping', description: 'Enter your address' },
    { id: 'payment', name: 'Payment', description: 'Complete payment' },
    { id: 'confirmation', name: 'Confirmation', description: 'Order complete' },
  ];

  const currentStepIndex = steps.findIndex((step) => step.id === currentStep);

  const handleShippingSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validate shipping info
    if (!shippingInfo.fullName || !shippingInfo.email || !shippingInfo.address) {
      alert('Please fill in all required fields');
      return;
    }

    // Proceed to payment
    setCurrentStep('payment');
  };

  const handlePaymentSuccess = (pmtIntentId: string) => {
    setPaymentIntentId(pmtIntentId);
    setCurrentStep('confirmation');
  };

  const formatAmount = (cents: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(cents / 100);
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Progress Indicator */}
        <div className="mb-8">
          <nav aria-label="Progress">
            <ol className="flex items-center">
              {steps.map((step, index) => (
                <li
                  key={step.id}
                  className={`relative ${index !== steps.length - 1 ? 'pr-8 sm:pr-20 flex-1' : ''}`}
                >
                  {/* Connector Line */}
                  {index !== steps.length - 1 && (
                    <div
                      className="absolute top-4 left-4 -ml-px mt-0.5 h-0.5 w-full bg-gray-300"
                      aria-hidden="true"
                    >
                      <div
                        className={`h-0.5 transition-all duration-300 ${
                          index < currentStepIndex ? 'bg-blue-600 w-full' : 'bg-gray-300 w-0'
                        }`}
                      />
                    </div>
                  )}

                  <div className="relative flex items-start">
                    <span className="flex h-9 items-center" aria-hidden="true">
                      <span
                        className={`relative z-10 flex h-8 w-8 items-center justify-center rounded-full transition-colors ${
                          index < currentStepIndex
                            ? 'bg-blue-600'
                            : index === currentStepIndex
                            ? 'border-2 border-blue-600 bg-white'
                            : 'border-2 border-gray-300 bg-white'
                        }`}
                      >
                        {index < currentStepIndex ? (
                          <svg
                            className="h-5 w-5 text-white"
                            viewBox="0 0 20 20"
                            fill="currentColor"
                          >
                            <path
                              fillRule="evenodd"
                              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                              clipRule="evenodd"
                            />
                          </svg>
                        ) : (
                          <span
                            className={`h-2.5 w-2.5 rounded-full ${
                              index === currentStepIndex ? 'bg-blue-600' : 'bg-transparent'
                            }`}
                          />
                        )}
                      </span>
                    </span>
                    <span className="ml-4 flex min-w-0 flex-col">
                      <span
                        className={`text-sm font-medium ${
                          index <= currentStepIndex ? 'text-blue-600' : 'text-gray-500'
                        }`}
                      >
                        {step.name}
                      </span>
                      <span className="text-sm text-gray-500">{step.description}</span>
                    </span>
                  </div>
                </li>
              ))}
            </ol>
          </nav>
        </div>

        {/* Step Content */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
          {/* Step 1: Shipping Information */}
          {currentStep === 'shipping' && (
            <form onSubmit={handleShippingSubmit} className="space-y-6">
              <h2 className="text-2xl font-bold text-gray-900">Shipping Information</h2>

              <div className="grid md:grid-cols-2 gap-6">
                <div className="md:col-span-2">
                  <label htmlFor="fullName" className="block text-sm font-medium text-gray-700">
                    Full Name *
                  </label>
                  <input
                    type="text"
                    id="fullName"
                    required
                    value={shippingInfo.fullName}
                    onChange={(e) =>
                      setShippingInfo({ ...shippingInfo, fullName: e.target.value })
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div className="md:col-span-2">
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                    Email *
                  </label>
                  <input
                    type="email"
                    id="email"
                    required
                    value={shippingInfo.email}
                    onChange={(e) =>
                      setShippingInfo({ ...shippingInfo, email: e.target.value })
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div className="md:col-span-2">
                  <label htmlFor="address" className="block text-sm font-medium text-gray-700">
                    Street Address *
                  </label>
                  <input
                    type="text"
                    id="address"
                    required
                    value={shippingInfo.address}
                    onChange={(e) =>
                      setShippingInfo({ ...shippingInfo, address: e.target.value })
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div>
                  <label htmlFor="city" className="block text-sm font-medium text-gray-700">
                    City *
                  </label>
                  <input
                    type="text"
                    id="city"
                    required
                    value={shippingInfo.city}
                    onChange={(e) => setShippingInfo({ ...shippingInfo, city: e.target.value })}
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div>
                  <label htmlFor="state" className="block text-sm font-medium text-gray-700">
                    State *
                  </label>
                  <input
                    type="text"
                    id="state"
                    required
                    value={shippingInfo.state}
                    onChange={(e) =>
                      setShippingInfo({ ...shippingInfo, state: e.target.value })
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>

                <div>
                  <label htmlFor="zipCode" className="block text-sm font-medium text-gray-700">
                    ZIP Code *
                  </label>
                  <input
                    type="text"
                    id="zipCode"
                    required
                    value={shippingInfo.zipCode}
                    onChange={(e) =>
                      setShippingInfo({ ...shippingInfo, zipCode: e.target.value })
                    }
                    className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>

              <button
                type="submit"
                className="w-full py-3 px-4 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
              >
                Continue to Payment
              </button>
            </form>
          )}

          {/* Step 2: Payment */}
          {currentStep === 'payment' && (
            <div className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">Payment Details</h2>
                <p className="mt-2 text-sm text-gray-600">
                  Complete your purchase for {formatAmount(orderAmount)}
                </p>
              </div>

              <div className="p-4 bg-gray-50 rounded-lg">
                <h3 className="text-sm font-medium text-gray-900 mb-2">
                  Shipping to:
                </h3>
                <p className="text-sm text-gray-600">
                  {shippingInfo.fullName}
                  <br />
                  {shippingInfo.address}
                  <br />
                  {shippingInfo.city}, {shippingInfo.state} {shippingInfo.zipCode}
                </p>
                <button
                  onClick={() => setCurrentStep('shipping')}
                  className="mt-2 text-sm text-blue-600 hover:text-blue-700 font-medium"
                >
                  Edit shipping address
                </button>
              </div>

              <StripeProvider>
                <CheckoutForm
                  amount={orderAmount}
                  onSuccess={handlePaymentSuccess}
                  buttonText={`Pay ${formatAmount(orderAmount)}`}
                />
              </StripeProvider>
            </div>
          )}

          {/* Step 3: Confirmation */}
          {currentStep === 'confirmation' && (
            <div className="text-center py-8">
              <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-green-100 mb-6">
                <svg
                  className="h-8 w-8 text-green-600"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </div>

              <h2 className="text-3xl font-bold text-gray-900 mb-2">Order Complete!</h2>
              <p className="text-gray-600 mb-8">
                Thank you for your purchase. Your order has been confirmed.
              </p>

              <div className="bg-gray-50 rounded-lg p-6 mb-8 text-left">
                <h3 className="text-sm font-medium text-gray-900 mb-4">Order Details</h3>

                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Order ID:</span>
                    <span className="font-medium text-gray-900">{paymentIntentId}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Amount:</span>
                    <span className="font-medium text-gray-900">
                      {formatAmount(orderAmount)}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Email:</span>
                    <span className="font-medium text-gray-900">{shippingInfo.email}</span>
                  </div>
                </div>
              </div>

              <div className="flex gap-4 justify-center">
                <a
                  href="/orders"
                  className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
                >
                  View Order
                </a>
                <a
                  href="/"
                  className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-colors"
                >
                  Continue Shopping
                </a>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
