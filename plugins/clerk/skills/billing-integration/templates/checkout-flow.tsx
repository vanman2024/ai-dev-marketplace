'use client'

import { PricingTable } from '@clerk/nextjs'
import { useAuth, useUser } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function CheckoutFlow() {
  const { isSignedIn } = useAuth()
  const { user } = useUser()
  const router = useRouter()
  const [isLoading, setIsLoading] = useState(false)

  const handleSuccess = (subscription: any) => {
    console.log('Subscription created:', subscription)

    // Redirect to success page or dashboard
    router.push('/dashboard?subscription=success')
  }

  const handleError = (error: any) => {
    console.error('Subscription error:', error)

    // Show error notification
    alert('Failed to create subscription. Please try again.')
  }

  if (!isSignedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="max-w-md w-full bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
          <div className="text-center mb-6">
            <svg
              className="mx-auto h-12 w-12 text-gray-400"
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
            <h2 className="mt-4 text-2xl font-bold text-gray-900 dark:text-white">
              Sign In Required
            </h2>
            <p className="mt-2 text-gray-600 dark:text-gray-400">
              Please sign in to subscribe to a plan
            </p>
          </div>
          <button
            onClick={() => router.push('/sign-in?redirect_url=/checkout')}
            className="w-full py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors"
          >
            Sign In
          </button>
          <p className="mt-4 text-center text-sm text-gray-600 dark:text-gray-400">
            Don't have an account?{' '}
            <a
              href="/sign-up?redirect_url=/checkout"
              className="text-blue-600 hover:text-blue-700 font-medium"
            >
              Sign up
            </a>
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-12">
        {/* Progress Steps */}
        <div className="max-w-3xl mx-auto mb-12">
          <div className="flex items-center justify-center">
            <div className="flex items-center">
              <div className="flex items-center">
                <div className="flex items-center justify-center w-10 h-10 bg-green-500 text-white rounded-full">
                  <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                </div>
                <span className="ml-2 text-sm font-medium text-gray-900 dark:text-white">
                  Account
                </span>
              </div>

              <div className="w-16 h-1 mx-4 bg-blue-600"></div>

              <div className="flex items-center">
                <div className="flex items-center justify-center w-10 h-10 bg-blue-600 text-white rounded-full font-semibold">
                  2
                </div>
                <span className="ml-2 text-sm font-medium text-gray-900 dark:text-white">
                  Choose Plan
                </span>
              </div>

              <div className="w-16 h-1 mx-4 bg-gray-300 dark:bg-gray-700"></div>

              <div className="flex items-center">
                <div className="flex items-center justify-center w-10 h-10 bg-gray-300 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded-full font-semibold">
                  3
                </div>
                <span className="ml-2 text-sm font-medium text-gray-500 dark:text-gray-400">
                  Complete
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* User Info */}
        <div className="max-w-4xl mx-auto mb-8">
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4">
                <img
                  src={user?.imageUrl}
                  alt={user?.fullName || 'User'}
                  className="w-12 h-12 rounded-full"
                />
                <div>
                  <p className="font-semibold text-gray-900 dark:text-white">
                    {user?.fullName || 'Welcome'}
                  </p>
                  <p className="text-sm text-gray-600 dark:text-gray-400">
                    {user?.primaryEmailAddress?.emailAddress}
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Subscribing as
                </p>
                <p className="font-semibold text-gray-900 dark:text-white">
                  Individual Account
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Checkout Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
            Complete Your Subscription
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300">
            Choose your plan and enter payment details
          </p>
        </div>

        {/* Pricing Table with Checkout */}
        <div className="max-w-6xl mx-auto">
          {isLoading && (
            <div className="absolute inset-0 bg-white/80 dark:bg-gray-900/80 flex items-center justify-center z-50">
              <div className="text-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
                <p className="text-gray-900 dark:text-white font-medium">
                  Processing your subscription...
                </p>
              </div>
            </div>
          )}

          <PricingTable
            appearance={{
              elements: {
                rootBox: 'w-full',
                cardBox: 'shadow-lg hover:shadow-xl transition-shadow border-2 border-transparent hover:border-blue-600',
                planName: 'text-2xl font-bold',
                planPrice: 'text-3xl font-bold text-blue-600',
                planDescription: 'text-gray-600 dark:text-gray-400 min-h-[3rem]',
                featureList: 'space-y-3 my-6',
                featureItem: 'flex items-center gap-2',
                subscribeButton: 'w-full py-3 px-6 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors shadow-md hover:shadow-lg',
                currentPlanBadge: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100',
              },
              variables: {
                colorPrimary: '#3b82f6',
                colorBackground: '#ffffff',
                borderRadius: '0.75rem',
                fontFamily: 'inherit',
              },
            }}
            onSubscriptionCreated={handleSuccess}
            onError={handleError}
          />
        </div>

        {/* Security Badges */}
        <div className="max-w-4xl mx-auto mt-12">
          <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
            <div className="flex items-center justify-center gap-8 flex-wrap">
              <div className="flex items-center gap-2">
                <svg className="w-6 h-6 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd" />
                </svg>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Secure Payment
                </span>
              </div>

              <div className="flex items-center gap-2">
                <svg className="w-6 h-6 text-blue-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  PCI Compliant
                </span>
              </div>

              <div className="flex items-center gap-2">
                <svg className="w-6 h-6 text-purple-600" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
                </svg>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Cancel Anytime
                </span>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Powered by
                </span>
                <span className="text-sm font-bold text-blue-600">Stripe</span>
              </div>
            </div>
          </div>
        </div>

        {/* Help Section */}
        <div className="max-w-4xl mx-auto mt-8 text-center">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Need help choosing a plan?{' '}
            <a href="/contact" className="text-blue-600 hover:text-blue-700 font-medium">
              Contact our sales team
            </a>
            {' '}or{' '}
            <a href="/pricing" className="text-blue-600 hover:text-blue-700 font-medium">
              view detailed pricing
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
