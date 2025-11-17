/**
 * Feature Gate Pattern Example
 *
 * Demonstrates how to implement feature gating throughout your application
 * using Clerk's has() helper for subscription-based access control.
 */

import { useAuth } from '@clerk/nextjs'
import { auth } from '@clerk/nextjs/server'
import Link from 'next/link'

// ============================================================================
// Client-Side Feature Gate (UI Components)
// ============================================================================

export function ClientFeatureGate({
  feature,
  children,
  fallback,
}: {
  feature: string
  children: React.ReactNode
  fallback?: React.ReactNode
}) {
  const { has } = useAuth()
  const hasFeature = has?.({ feature })

  if (!hasFeature) {
    return (
      fallback || (
        <UpgradePrompt
          feature={feature}
          message={`Upgrade to access ${feature.replace('_', ' ')}`}
        />
      )
    )
  }

  return <>{children}</>
}

// ============================================================================
// Server-Side Feature Gate (API Routes & Server Components)
// ============================================================================

export async function requireFeature(feature: string) {
  const { has } = await auth()

  if (!has({ feature })) {
    throw new Error(`Feature ${feature} not available on current plan`)
  }
}

// Usage in API Route:
export async function POST_EXAMPLE(request: Request) {
  try {
    await requireFeature('ai_assistant')

    // Feature is available, proceed with request
    return Response.json({ success: true })
  } catch (error) {
    return Response.json(
      { error: 'Subscription required' },
      { status: 403 }
    )
  }
}

// ============================================================================
// Usage Examples
// ============================================================================

// Example 1: Basic Feature Gate
export function AIAssistantFeature() {
  return (
    <ClientFeatureGate feature="ai_assistant">
      <div className="p-6 bg-white rounded-lg shadow">
        <h3 className="text-xl font-bold mb-4">AI Assistant</h3>
        <textarea
          className="w-full p-3 border rounded"
          placeholder="Ask anything..."
        />
        <button className="mt-3 px-6 py-2 bg-blue-600 text-white rounded">
          Send
        </button>
      </div>
    </ClientFeatureGate>
  )
}

// Example 2: Custom Fallback
export function AdvancedAnalytics() {
  return (
    <ClientFeatureGate
      feature="advanced_analytics"
      fallback={
        <div className="p-6 bg-gray-100 rounded-lg border-2 border-dashed border-gray-300">
          <div className="blur-sm mb-4">
            <h3 className="text-xl font-bold">Analytics Dashboard</h3>
            <p className="text-gray-600">Preview of locked content...</p>
          </div>
          <div className="text-center">
            <h4 className="font-semibold mb-2">Unlock Advanced Analytics</h4>
            <p className="text-sm text-gray-600 mb-4">
              Get detailed insights into your data
            </p>
            <Link
              href="/pricing"
              className="inline-block px-6 py-2 bg-blue-600 text-white rounded"
            >
              Upgrade to Pro
            </Link>
          </div>
        </div>
      }
    >
      <div className="p-6 bg-white rounded-lg shadow">
        <h3 className="text-xl font-bold mb-4">Analytics Dashboard</h3>
        {/* Full analytics UI */}
      </div>
    </ClientFeatureGate>
  )
}

// Example 3: Multiple Features
export function PremiumFeatureSet() {
  const { has } = useAuth()

  const hasAI = has?.({ feature: 'ai_assistant' })
  const hasAnalytics = has?.({ feature: 'advanced_analytics' })
  const hasSupport = has?.({ feature: 'priority_support' })

  return (
    <div className="grid grid-cols-3 gap-4">
      <FeatureCard
        title="AI Assistant"
        enabled={hasAI}
        feature="ai_assistant"
      />
      <FeatureCard
        title="Analytics"
        enabled={hasAnalytics}
        feature="advanced_analytics"
      />
      <FeatureCard
        title="Support"
        enabled={hasSupport}
        feature="priority_support"
      />
    </div>
  )
}

// Example 4: Graceful Degradation
export function SearchFeature() {
  const { has } = useAuth()
  const hasAdvancedSearch = has?.({ feature: 'advanced_search' })

  return (
    <div className="p-6">
      <input
        type="text"
        placeholder={
          hasAdvancedSearch
            ? 'Search with filters, operators, and fuzzy matching...'
            : 'Basic search...'
        }
        className="w-full p-3 border rounded"
      />

      {hasAdvancedSearch ? (
        <div className="mt-4 space-y-2">
          <FilterOption label="Date Range" />
          <FilterOption label="Category" />
          <FilterOption label="Tags" />
        </div>
      ) : (
        <div className="mt-4 p-4 bg-blue-50 rounded">
          <p className="text-sm text-blue-900">
            💡 Upgrade to Pro for advanced filters and search operators
          </p>
        </div>
      )}
    </div>
  )
}

// Example 5: Progressive Disclosure
export function ExportFeature() {
  const { has } = useAuth()

  const canExportCSV = true // Available on all plans
  const canExportPDF = has?.({ feature: 'pdf_export' })
  const canExportAdvanced = has?.({ feature: 'advanced_export' })

  return (
    <div className="p-6">
      <h3 className="font-semibold mb-4">Export Options</h3>

      <button className="w-full mb-2 p-3 bg-blue-600 text-white rounded">
        Export as CSV
      </button>

      <button
        className={`w-full mb-2 p-3 rounded ${
          canExportPDF
            ? 'bg-blue-600 text-white'
            : 'bg-gray-200 text-gray-500 cursor-not-allowed'
        }`}
        disabled={!canExportPDF}
      >
        {canExportPDF ? 'Export as PDF' : 'Export as PDF (Pro)'}
      </button>

      <button
        className={`w-full p-3 rounded ${
          canExportAdvanced
            ? 'bg-blue-600 text-white'
            : 'bg-gray-200 text-gray-500 cursor-not-allowed'
        }`}
        disabled={!canExportAdvanced}
      >
        {canExportAdvanced
          ? 'Export with Custom Template'
          : 'Custom Export (Enterprise)'}
      </button>
    </div>
  )
}

// ============================================================================
// Reusable Components
// ============================================================================

function UpgradePrompt({
  feature,
  message,
}: {
  feature: string
  message: string
}) {
  return (
    <div className="p-8 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-lg border-2 border-blue-200 dark:border-blue-800">
      <div className="text-center">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
          <svg
            className="w-8 h-8 text-white"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
        </div>
        <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
          Premium Feature
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-6">{message}</p>
        <Link
          href="/pricing"
          className="inline-block px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors"
        >
          View Plans
        </Link>
      </div>
    </div>
  )
}

function FeatureCard({
  title,
  enabled,
  feature,
}: {
  title: string
  enabled?: boolean
  feature: string
}) {
  return (
    <div
      className={`p-4 border-2 rounded-lg ${
        enabled
          ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
          : 'border-gray-300 bg-gray-50 dark:bg-gray-800'
      }`}
    >
      <div className="flex items-center justify-between mb-2">
        <h4 className="font-semibold">{title}</h4>
        {enabled ? (
          <svg
            className="w-5 h-5 text-green-500"
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
            className="w-5 h-5 text-gray-400"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fillRule="evenodd"
              d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z"
              clipRule="evenodd"
            />
          </svg>
        )}
      </div>
      <p className="text-sm text-gray-600 dark:text-gray-400">
        {enabled ? 'Active' : 'Locked'}
      </p>
    </div>
  )
}

function FilterOption({ label }: { label: string }) {
  return (
    <div className="flex items-center gap-2">
      <input type="checkbox" id={label} />
      <label htmlFor={label} className="text-sm">
        {label}
      </label>
    </div>
  )
}

// ============================================================================
// Server Component Example
// ============================================================================

export async function ServerProtectedFeature() {
  const { has } = await auth()

  if (!has({ feature: 'advanced_analytics' })) {
    return (
      <div className="p-6 text-center">
        <h3 className="text-xl font-bold mb-2">Analytics Locked</h3>
        <p className="text-gray-600 mb-4">
          Upgrade to access advanced analytics
        </p>
        <Link href="/pricing" className="text-blue-600 hover:underline">
          View Plans
        </Link>
      </div>
    )
  }

  // Server-rendered protected content
  return (
    <div className="p-6">
      <h3 className="text-xl font-bold mb-4">Advanced Analytics</h3>
      {/* Server-rendered analytics data */}
    </div>
  )
}
