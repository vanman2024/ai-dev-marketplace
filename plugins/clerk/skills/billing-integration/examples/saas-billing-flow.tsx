'use client'

import { PricingTable } from '@clerk/nextjs'
import { useAuth, useUser } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { useState, useEffect } from 'react'

/**
 * Complete SaaS Billing Flow Example
 *
 * This example demonstrates a full billing implementation with:
 * - Feature-gated content
 * - Subscription upgrade prompts
 * - Access control based on plan
 * - Usage tracking and limits
 * - Subscription management
 *
 * Features demonstrated:
 * 1. Check subscription status with has()
 * 2. Show upgrade prompts for locked features
 * 3. Track usage against limits
 * 4. Display current plan information
 * 5. Handle subscription upgrades
 */

export default function SaaSBillingFlow() {
  const { isSignedIn, has } = useAuth()
  const { user } = useUser()
  const router = useRouter()

  // Feature access checks
  const hasAIAssistant = has?.({ feature: 'ai_assistant' })
  const hasAdvancedAnalytics = has?.({ feature: 'advanced_analytics' })
  const hasUnlimitedAPI = has?.({ feature: 'unlimited_api_calls' })
  const hasPrioritySupport = has?.({ feature: 'priority_support' })

  // Usage tracking state
  const [apiUsage, setApiUsage] = useState(0)
  const [usageLimit, setUsageLimit] = useState(100) // Free tier limit

  useEffect(() => {
    if (isSignedIn) {
      loadUsageData()
    }
  }, [isSignedIn])

  const loadUsageData = async () => {
    try {
      const response = await fetch('/api/usage')
      const data = await response.json()
      setApiUsage(data.usage || 0)
      setUsageLimit(data.limit || 100)
    } catch (error) {
      console.error('Failed to load usage data:', error)
    }
  }

  const getCurrentPlan = () => {
    if (hasUnlimitedAPI) return 'Enterprise'
    if (hasAdvancedAnalytics) return 'Pro'
    return 'Free'
  }

  const getUsagePercentage = () => {
    if (hasUnlimitedAPI) return 0 // Unlimited
    return Math.min((apiUsage / usageLimit) * 100, 100)
  }

  if (!isSignedIn) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="max-w-md w-full text-center">
          <h2 className="text-2xl font-bold mb-4">Sign in to continue</h2>
          <button
            onClick={() => router.push('/sign-in')}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg"
          >
            Sign In
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-12">
      <div className="container mx-auto px-4">
        {/* Dashboard Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Welcome back, {user?.firstName}!
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            You're on the <strong>{getCurrentPlan()}</strong> plan
          </p>
        </div>

        {/* Usage Widget */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 mb-8">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                API Usage
              </h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {hasUnlimitedAPI
                  ? 'Unlimited'
                  : `${apiUsage.toLocaleString()} / ${usageLimit.toLocaleString()} calls`}
              </p>
            </div>
            {!hasUnlimitedAPI && getUsagePercentage() > 80 && (
              <button
                onClick={() => router.push('/pricing')}
                className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700"
              >
                Upgrade
              </button>
            )}
          </div>

          {!hasUnlimitedAPI && (
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className={`h-2 rounded-full transition-all ${
                  getUsagePercentage() > 90
                    ? 'bg-red-600'
                    : getUsagePercentage() > 70
                    ? 'bg-yellow-600'
                    : 'bg-blue-600'
                }`}
                style={{ width: `${getUsagePercentage()}%` }}
              />
            </div>
          )}

          {!hasUnlimitedAPI && getUsagePercentage() > 90 && (
            <p className="mt-3 text-sm text-red-600 dark:text-red-400">
              ⚠️ You're approaching your monthly limit. Upgrade to continue using the service.
            </p>
          )}
        </div>

        {/* Feature Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          {/* AI Assistant Feature */}
          <FeatureCard
            title="AI Assistant"
            description="Get intelligent responses and automate workflows"
            icon="🤖"
            hasAccess={hasAIAssistant}
            onUpgrade={() => router.push('/pricing')}
          >
            {hasAIAssistant ? (
              <div className="space-y-3">
                <textarea
                  className="w-full p-3 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                  placeholder="Ask the AI assistant anything..."
                  rows={3}
                />
                <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  Send Message
                </button>
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-600 dark:text-gray-400 mb-4">
                  Unlock AI-powered assistance
                </p>
                <button
                  onClick={() => router.push('/pricing')}
                  className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Upgrade to Pro
                </button>
              </div>
            )}
          </FeatureCard>

          {/* Advanced Analytics Feature */}
          <FeatureCard
            title="Advanced Analytics"
            description="Deep insights and custom reports"
            icon="📊"
            hasAccess={hasAdvancedAnalytics}
            onUpgrade={() => router.push('/pricing')}
          >
            {hasAdvancedAnalytics ? (
              <div className="space-y-3">
                <div className="grid grid-cols-3 gap-3">
                  <StatCard label="Total Users" value="1,234" />
                  <StatCard label="Revenue" value="$12.3k" />
                  <StatCard label="Growth" value="+23%" />
                </div>
                <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  View Detailed Report
                </button>
              </div>
            ) : (
              <div className="text-center py-8">
                <div className="blur-sm mb-4">
                  <div className="grid grid-cols-3 gap-3">
                    <StatCard label="Users" value="XXX" />
                    <StatCard label="Revenue" value="$XXX" />
                    <StatCard label="Growth" value="XX%" />
                  </div>
                </div>
                <button
                  onClick={() => router.push('/pricing')}
                  className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Upgrade to Pro
                </button>
              </div>
            )}
          </FeatureCard>

          {/* Priority Support Feature */}
          <FeatureCard
            title="Priority Support"
            description="Get help from our team faster"
            icon="🎧"
            hasAccess={hasPrioritySupport}
            onUpgrade={() => router.push('/pricing')}
          >
            {hasPrioritySupport ? (
              <div className="space-y-3">
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Average response time: <strong>Under 1 hour</strong>
                </p>
                <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                  Contact Support
                </button>
              </div>
            ) : (
              <div className="text-center py-8">
                <p className="text-gray-600 dark:text-gray-400 mb-4">
                  Standard support: 24-48 hours
                </p>
                <button
                  onClick={() => router.push('/pricing')}
                  className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                >
                  Get Priority Support
                </button>
              </div>
            )}
          </FeatureCard>

          {/* API Access Feature */}
          <FeatureCard
            title="API Access"
            description="Integrate with your applications"
            icon="🔌"
            hasAccess={true}
            onUpgrade={() => router.push('/pricing')}
          >
            <div className="space-y-3">
              <div className="flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-700 rounded">
                <code className="text-sm font-mono">
                  {hasUnlimitedAPI ? 'Unlimited calls/month' : `${usageLimit} calls/month`}
                </code>
                {!hasUnlimitedAPI && (
                  <button
                    onClick={() => router.push('/pricing')}
                    className="text-sm text-blue-600 hover:text-blue-700"
                  >
                    Increase limit
                  </button>
                )}
              </div>
              <button className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
                View API Docs
              </button>
            </div>
          </FeatureCard>
        </div>

        {/* Upgrade CTA */}
        {getCurrentPlan() !== 'Enterprise' && (
          <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-8 text-center text-white">
            <h2 className="text-2xl font-bold mb-2">
              Unlock All Features
            </h2>
            <p className="text-blue-100 mb-6">
              Upgrade to {getCurrentPlan() === 'Free' ? 'Pro' : 'Enterprise'} and get access to everything
            </p>
            <button
              onClick={() => router.push('/pricing')}
              className="px-8 py-3 bg-white text-blue-600 font-semibold rounded-lg hover:bg-gray-100"
            >
              View Plans
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

function FeatureCard({
  title,
  description,
  icon,
  hasAccess,
  onUpgrade,
  children,
}: {
  title: string
  description: string
  icon: string
  hasAccess?: boolean
  onUpgrade: () => void
  children: React.ReactNode
}) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center gap-3">
          <span className="text-3xl">{icon}</span>
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {title}
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {description}
            </p>
          </div>
        </div>
        {hasAccess && (
          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-100">
            Active
          </span>
        )}
      </div>
      {children}
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-gray-100 dark:bg-gray-700 rounded-lg p-3 text-center">
      <p className="text-xs text-gray-600 dark:text-gray-400 mb-1">{label}</p>
      <p className="text-lg font-bold text-gray-900 dark:text-white">{value}</p>
    </div>
  )
}
