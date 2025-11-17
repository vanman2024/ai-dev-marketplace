'use client'

import { useAuth, useUser } from '@clerk/nextjs'
import { useEffect, useState } from 'react'
import Link from 'next/link'

interface Subscription {
  id: string
  planName: string
  status: 'active' | 'canceled' | 'past_due' | 'trialing'
  currentPeriodEnd: string
  cancelAtPeriodEnd: boolean
  amount: number
  interval: 'month' | 'year'
}

export default function SubscriptionManagement() {
  const { isSignedIn, has } = useAuth()
  const { user } = useUser()
  const [subscription, setSubscription] = useState<Subscription | null>(null)
  const [loading, setLoading] = useState(true)
  const [showCancelDialog, setShowCancelDialog] = useState(false)

  useEffect(() => {
    if (isSignedIn) {
      fetchSubscription()
    }
  }, [isSignedIn])

  const fetchSubscription = async () => {
    try {
      // Fetch subscription details from your API
      const response = await fetch('/api/subscription')
      const data = await response.json()
      setSubscription(data.subscription)
    } catch (error) {
      console.error('Failed to fetch subscription:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCancelSubscription = async () => {
    try {
      const response = await fetch('/api/subscription/cancel', {
        method: 'POST',
      })

      if (response.ok) {
        await fetchSubscription()
        setShowCancelDialog(false)
      }
    } catch (error) {
      console.error('Failed to cancel subscription:', error)
    }
  }

  const handleReactivateSubscription = async () => {
    try {
      const response = await fetch('/api/subscription/reactivate', {
        method: 'POST',
      })

      if (response.ok) {
        await fetchSubscription()
      }
    } catch (error) {
      console.error('Failed to reactivate subscription:', error)
    }
  }

  if (!isSignedIn) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-600 dark:text-gray-400">
          Please sign in to manage your subscription
        </p>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  const getStatusBadge = (status: string) => {
    const badges = {
      active: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100',
      trialing: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-100',
      canceled: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300',
      past_due: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-100',
    }
    return badges[status as keyof typeof badges] || badges.active
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  }

  return (
    <div className="max-w-4xl mx-auto">
      {/* Current Plan Overview */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              Current Plan
            </h2>
            {subscription ? (
              <>
                <p className="text-3xl font-bold text-blue-600 mb-2">
                  {subscription.planName}
                </p>
                <div className="flex items-center gap-2">
                  <span
                    className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${getStatusBadge(
                      subscription.status
                    )}`}
                  >
                    {subscription.status.charAt(0).toUpperCase() +
                      subscription.status.slice(1)}
                  </span>
                  {subscription.cancelAtPeriodEnd && (
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-100">
                      Canceling
                    </span>
                  )}
                </div>
              </>
            ) : (
              <>
                <p className="text-xl text-gray-600 dark:text-gray-400 mb-2">
                  Free Plan
                </p>
                <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                  No active subscription
                </span>
              </>
            )}
          </div>

          {subscription && (
            <div className="text-right">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">
                Billing Amount
              </p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                ${subscription.amount / 100}
                <span className="text-base font-normal text-gray-600 dark:text-gray-400">
                  /{subscription.interval}
                </span>
              </p>
            </div>
          )}
        </div>

        {subscription && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-6 border-t border-gray-200 dark:border-gray-700">
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">
                {subscription.cancelAtPeriodEnd
                  ? 'Access ends on'
                  : 'Next billing date'}
              </p>
              <p className="text-lg font-semibold text-gray-900 dark:text-white">
                {formatDate(subscription.currentPeriodEnd)}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">
                Subscription ID
              </p>
              <p className="text-sm font-mono text-gray-700 dark:text-gray-300">
                {subscription.id}
              </p>
            </div>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-4 mt-6">
          {!subscription && (
            <Link
              href="/pricing"
              className="flex-1 py-3 px-6 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors text-center"
            >
              Upgrade to Pro
            </Link>
          )}

          {subscription && !subscription.cancelAtPeriodEnd && (
            <>
              <Link
                href="/pricing"
                className="flex-1 py-3 px-6 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-colors text-center"
              >
                Change Plan
              </Link>
              <button
                onClick={() => setShowCancelDialog(true)}
                className="flex-1 py-3 px-6 bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-900 dark:text-white font-semibold rounded-lg transition-colors"
              >
                Cancel Subscription
              </button>
            </>
          )}

          {subscription && subscription.cancelAtPeriodEnd && (
            <button
              onClick={handleReactivateSubscription}
              className="flex-1 py-3 px-6 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition-colors"
            >
              Reactivate Subscription
            </button>
          )}
        </div>
      </div>

      {/* Features */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
          Your Plan Features
        </h3>
        <div className="space-y-3">
          <FeatureItem
            enabled={has?.({ feature: 'ai_assistant' })}
            label="AI Assistant"
          />
          <FeatureItem
            enabled={has?.({ feature: 'advanced_analytics' })}
            label="Advanced Analytics"
          />
          <FeatureItem
            enabled={has?.({ feature: 'priority_support' })}
            label="Priority Support"
          />
          <FeatureItem
            enabled={has?.({ feature: 'custom_integrations' })}
            label="Custom Integrations"
          />
          <FeatureItem
            enabled={has?.({ feature: 'unlimited_api_calls' })}
            label="Unlimited API Calls"
          />
        </div>
      </div>

      {/* Billing History */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8">
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-xl font-bold text-gray-900 dark:text-white">
            Billing History
          </h3>
          <button className="text-blue-600 hover:text-blue-700 font-medium text-sm">
            View All Invoices
          </button>
        </div>

        <div className="space-y-4">
          {/* This would be populated from your API */}
          <p className="text-gray-600 dark:text-gray-400 text-sm">
            Your billing history will appear here
          </p>
        </div>
      </div>

      {/* Cancel Confirmation Dialog */}
      {showCancelDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-md w-full p-6">
            <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-4">
              Cancel Subscription?
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Are you sure you want to cancel your subscription? You'll still have
              access until {subscription && formatDate(subscription.currentPeriodEnd)}.
            </p>
            <div className="flex gap-4">
              <button
                onClick={() => setShowCancelDialog(false)}
                className="flex-1 py-2 px-4 bg-gray-200 hover:bg-gray-300 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-900 dark:text-white font-medium rounded-lg transition-colors"
              >
                Keep Subscription
              </button>
              <button
                onClick={handleCancelSubscription}
                className="flex-1 py-2 px-4 bg-red-600 hover:bg-red-700 text-white font-medium rounded-lg transition-colors"
              >
                Yes, Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function FeatureItem({
  enabled,
  label,
}: {
  enabled?: boolean
  label: string
}) {
  return (
    <div className="flex items-center gap-3">
      {enabled ? (
        <svg
          className="w-5 h-5 text-green-500 flex-shrink-0"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path
            fillRule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
            clipRule="evenodd"
          />
        </svg>
      ) : (
        <svg
          className="w-5 h-5 text-gray-300 dark:text-gray-600 flex-shrink-0"
          fill="currentColor"
          viewBox="0 0 20 20"
        >
          <path
            fillRule="evenodd"
            d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
            clipRule="evenodd"
          />
        </svg>
      )}
      <span className={enabled ? 'text-gray-900 dark:text-white' : 'text-gray-400 dark:text-gray-600'}>
        {label}
      </span>
    </div>
  )
}
