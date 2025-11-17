/**
 * Usage-Based Billing Example
 *
 * Demonstrates how to implement usage-based billing with metering,
 * quota tracking, and overages for API calls or feature usage.
 */

import { useAuth, useUser } from '@clerk/nextjs'
import { auth, clerkClient } from '@clerk/nextjs/server'
import { useEffect, useState } from 'react'

// ============================================================================
// Usage Dashboard (Client Component)
// ============================================================================

export function UsageDashboard() {
  const { has } = useAuth()
  const { user } = useUser()
  const [usage, setUsage] = useState<UsageData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchUsageData()
  }, [])

  const fetchUsageData = async () => {
    try {
      const response = await fetch('/api/usage')
      const data = await response.json()
      setUsage(data)
    } catch (error) {
      console.error('Failed to fetch usage:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <div className="p-12 text-center">Loading usage data...</div>
  }

  if (!usage) {
    return <div className="p-12 text-center">Failed to load usage data</div>
  }

  const { current, limit, resetDate, overage } = usage
  const percentage = limit > 0 ? (current / limit) * 100 : 0
  const isNearLimit = percentage >= 80
  const hasExceeded = current >= limit

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Usage Overview */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
              API Usage
            </h2>
            <p className="text-gray-600 dark:text-gray-400">
              Current billing period: {formatResetDate(resetDate)}
            </p>
          </div>
          {isNearLimit && (
            <button
              onClick={() => window.location.href = '/pricing'}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              Upgrade Plan
            </button>
          )}
        </div>

        {/* Usage Meter */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
              {has?.({ feature: 'unlimited_api_calls' })
                ? 'Unlimited Usage'
                : `${current.toLocaleString()} / ${limit.toLocaleString()} calls`}
            </span>
            <span
              className={`text-sm font-medium ${
                hasExceeded
                  ? 'text-red-600'
                  : isNearLimit
                  ? 'text-yellow-600'
                  : 'text-gray-600'
              }`}
            >
              {percentage.toFixed(1)}%
            </span>
          </div>

          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3">
            <div
              className={`h-3 rounded-full transition-all ${
                hasExceeded
                  ? 'bg-red-600'
                  : isNearLimit
                  ? 'bg-yellow-600'
                  : 'bg-blue-600'
              }`}
              style={{ width: `${Math.min(percentage, 100)}%` }}
            />
          </div>
        </div>

        {/* Alerts */}
        {hasExceeded && (
          <div className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg mb-4">
            <div className="flex items-start gap-3">
              <svg
                className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fillRule="evenodd"
                  d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
                  clipRule="evenodd"
                />
              </svg>
              <div>
                <h4 className="font-semibold text-red-900 dark:text-red-100 mb-1">
                  Usage Limit Exceeded
                </h4>
                <p className="text-sm text-red-800 dark:text-red-200">
                  You've exceeded your monthly limit. API calls are currently blocked.
                  {overage && overage > 0 && (
                    <> Overage charges: ${(overage / 100).toFixed(2)}</>
                  )}
                </p>
              </div>
            </div>
          </div>
        )}

        {isNearLimit && !hasExceeded && (
          <div className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg mb-4">
            <div className="flex items-start gap-3">
              <svg
                className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path
                  fillRule="evenodd"
                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                  clipRule="evenodd"
                />
              </svg>
              <div>
                <h4 className="font-semibold text-yellow-900 dark:text-yellow-100 mb-1">
                  Approaching Limit
                </h4>
                <p className="text-sm text-yellow-800 dark:text-yellow-200">
                  You've used {percentage.toFixed(0)}% of your monthly quota.
                  Consider upgrading to avoid service interruption.
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Quick Stats */}
        <div className="grid grid-cols-3 gap-4 pt-6 border-t border-gray-200 dark:border-gray-700">
          <QuickStat label="Today" value={usage.today || 0} />
          <QuickStat label="This Week" value={usage.week || 0} />
          <QuickStat label="This Month" value={current} />
        </div>
      </div>

      {/* Usage History Chart Placeholder */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <h3 className="text-xl font-bold mb-4">Usage History</h3>
        <div className="h-64 flex items-center justify-center bg-gray-50 dark:bg-gray-700 rounded">
          <p className="text-gray-500">Chart visualization would go here</p>
        </div>
      </div>

      {/* Upgrade Options */}
      {!has?.({ feature: 'unlimited_api_calls' }) && (
        <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg p-8 text-white">
          <h3 className="text-2xl font-bold mb-2">Need More API Calls?</h3>
          <p className="text-blue-100 mb-6">
            Upgrade to a higher tier for increased limits or unlimited usage
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <PlanOption
              name="Pro"
              limit="10,000 calls/month"
              price="$29"
            />
            <PlanOption
              name="Business"
              limit="100,000 calls/month"
              price="$99"
            />
            <PlanOption
              name="Enterprise"
              limit="Unlimited"
              price="$299"
            />
          </div>
        </div>
      )}
    </div>
  )
}

// ============================================================================
// API Route: Track Usage
// ============================================================================

export async function POST_TrackUsage(request: Request) {
  const { userId } = await auth()

  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    // Get current usage from user metadata
    const user = await clerkClient.users.getUser(userId)
    const metadata = user.privateMetadata as any

    const currentPeriodStart = getCurrentPeriodStart()
    const usage = metadata.usage || {}

    // Reset if new billing period
    if (usage.periodStart !== currentPeriodStart) {
      usage.periodStart = currentPeriodStart
      usage.count = 0
    }

    // Check limits based on plan
    const { has } = await auth()
    const limit = getUsageLimit(has)

    if (!has({ feature: 'unlimited_api_calls' }) && usage.count >= limit) {
      // Check if overage allowed
      if (has({ feature: 'overage_billing' })) {
        // Track overage for billing
        usage.overage = (usage.overage || 0) + 1
      } else {
        return Response.json(
          { error: 'Usage limit exceeded', limit, current: usage.count },
          { status: 429 }
        )
      }
    }

    // Increment usage
    usage.count = (usage.count || 0) + 1
    usage.lastUsed = new Date().toISOString()

    // Update user metadata
    await clerkClient.users.updateUserMetadata(userId, {
      privateMetadata: { usage },
    })

    return Response.json({
      success: true,
      usage: {
        current: usage.count,
        limit,
        overage: usage.overage || 0,
        percentage: (usage.count / limit) * 100,
      },
    })
  } catch (error) {
    console.error('Failed to track usage:', error)
    return Response.json(
      { error: 'Failed to track usage' },
      { status: 500 }
    )
  }
}

// ============================================================================
// API Route: Get Usage Data
// ============================================================================

export async function GET_Usage(request: Request) {
  const { userId, has } = await auth()

  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 })
  }

  try {
    const user = await clerkClient.users.getUser(userId)
    const metadata = user.privateMetadata as any
    const usage = metadata.usage || {}

    const limit = getUsageLimit(has)
    const resetDate = getNextResetDate()

    return Response.json({
      current: usage.count || 0,
      limit,
      resetDate,
      overage: usage.overage || 0,
      today: usage.today || 0,
      week: usage.week || 0,
      lastUsed: usage.lastUsed,
    })
  } catch (error) {
    console.error('Failed to get usage:', error)
    return Response.json(
      { error: 'Failed to get usage' },
      { status: 500 }
    )
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

function getUsageLimit(has: any): number {
  if (has({ feature: 'unlimited_api_calls' })) return Infinity
  if (has({ feature: 'business_api_calls' })) return 100000
  if (has({ feature: 'pro_api_calls' })) return 10000
  return 100 // Free tier
}

function getCurrentPeriodStart(): string {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth(), 1).toISOString()
}

function getNextResetDate(): string {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth() + 1, 1).toISOString()
}

function formatResetDate(date: string): string {
  const resetDate = new Date(date)
  const now = new Date()
  const daysUntilReset = Math.ceil(
    (resetDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
  )

  return `Resets in ${daysUntilReset} days (${resetDate.toLocaleDateString()})`
}

// ============================================================================
// Type Definitions
// ============================================================================

interface UsageData {
  current: number
  limit: number
  resetDate: string
  overage?: number
  today?: number
  week?: number
  lastUsed?: string
}

// ============================================================================
// Reusable Components
// ============================================================================

function QuickStat({ label, value }: { label: string; value: number }) {
  return (
    <div className="text-center">
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">{label}</p>
      <p className="text-2xl font-bold text-gray-900 dark:text-white">
        {value.toLocaleString()}
      </p>
    </div>
  )
}

function PlanOption({
  name,
  limit,
  price,
}: {
  name: string
  limit: string
  price: string
}) {
  return (
    <div className="bg-white/10 backdrop-blur rounded-lg p-4 text-center">
      <h4 className="font-semibold mb-1">{name}</h4>
      <p className="text-sm text-blue-100 mb-2">{limit}</p>
      <p className="text-2xl font-bold">{price}/mo</p>
    </div>
  )
}
