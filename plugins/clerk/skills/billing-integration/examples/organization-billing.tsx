/**
 * Organization Billing (B2B) Example
 *
 * Demonstrates how to implement team/organization-based billing
 * with per-seat pricing and organization-level feature access.
 */

import { PricingTable } from '@clerk/nextjs'
import { useAuth, useOrganization, useOrganizationList } from '@clerk/nextjs'
import { auth, clerkClient } from '@clerk/nextjs/server'
import Link from 'next/link'
import { useState } from 'react'

// ============================================================================
// Organization Billing Page (Client Component)
// ============================================================================

export function OrganizationBillingPage() {
  const { organization, membership } = useOrganization()
  const { has } = useAuth()
  const [showPricing, setShowPricing] = useState(false)

  // Check if user has billing permissions
  const canManageBilling = membership?.role === 'admin' || has?.({ permission: 'org:billing:manage' })

  if (!organization) {
    return (
      <div className="p-12 text-center">
        <h2 className="text-2xl font-bold mb-4">No Organization Selected</h2>
        <p className="text-gray-600 mb-6">
          Please create or select an organization to manage billing
        </p>
        <Link
          href="/organizations"
          className="px-6 py-3 bg-blue-600 text-white rounded-lg"
        >
          View Organizations
        </Link>
      </div>
    )
  }

  if (!canManageBilling) {
    return (
      <div className="p-12 text-center">
        <h2 className="text-2xl font-bold mb-4">Access Denied</h2>
        <p className="text-gray-600">
          Only organization admins can manage billing
        </p>
      </div>
    )
  }

  const hasTeamPlan = has?.({ feature: 'team_workspace' })
  const hasBusinessPlan = has?.({ feature: 'business_features' })
  const hasEnterprisePlan = has?.({ feature: 'enterprise_features' })

  const getCurrentPlan = () => {
    if (hasEnterprisePlan) return 'Enterprise'
    if (hasBusinessPlan) return 'Business'
    if (hasTeamPlan) return 'Team'
    return 'Free'
  }

  return (
    <div className="max-w-6xl mx-auto p-6">
      {/* Organization Overview */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <div className="flex items-start justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
              {organization.name}
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Current Plan: <strong>{getCurrentPlan()}</strong>
            </p>
          </div>
          <button
            onClick={() => setShowPricing(true)}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            {getCurrentPlan() === 'Free' ? 'Upgrade Plan' : 'Change Plan'}
          </button>
        </div>

        {/* Team Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-6 border-t border-gray-200 dark:border-gray-700">
          <StatCard
            label="Team Members"
            value={organization.membersCount?.toString() || '0'}
            icon="👥"
          />
          <StatCard
            label="Active Projects"
            value="12"
            icon="📁"
          />
          <StatCard
            label="Monthly Spend"
            value="$299"
            icon="💰"
          />
        </div>
      </div>

      {/* Pricing Modal */}
      {showPricing && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-6xl w-full max-h-[90vh] overflow-y-auto p-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold">Choose Organization Plan</h2>
              <button
                onClick={() => setShowPricing(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                ✕
              </button>
            </div>

            <PricingTable
              mode="organization"
              organizationId={organization.id}
              appearance={{
                elements: {
                  cardBox: 'border-2 hover:border-blue-600',
                  subscribeButton: 'w-full py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg',
                },
              }}
            />
          </div>
        </div>
      )}

      {/* Feature Access */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 mb-6">
        <h2 className="text-2xl font-bold mb-6">Organization Features</h2>
        <div className="space-y-4">
          <FeatureRow
            name="Team Workspace"
            enabled={hasTeamPlan}
            description="Collaborate with your team"
          />
          <FeatureRow
            name="Advanced Permissions"
            enabled={hasBusinessPlan}
            description="Role-based access control"
          />
          <FeatureRow
            name="SSO & SAML"
            enabled={hasEnterprisePlan}
            description="Enterprise authentication"
          />
          <FeatureRow
            name="Audit Logs"
            enabled={hasBusinessPlan}
            description="Track all organization activities"
          />
          <FeatureRow
            name="Dedicated Support"
            enabled={hasEnterprisePlan}
            description="Priority support with SLA"
          />
        </div>
      </div>

      {/* Seat-Based Billing Info */}
      {hasTeamPlan && (
        <div className="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-6">
          <h3 className="font-semibold text-blue-900 dark:text-blue-100 mb-2">
            Per-Seat Billing
          </h3>
          <p className="text-blue-800 dark:text-blue-200 text-sm">
            Your plan includes {organization.membersCount} seats at $10/seat/month.
            Add more team members to scale your subscription automatically.
          </p>
        </div>
      )}
    </div>
  )
}

// ============================================================================
// Organization Switcher with Billing Info
// ============================================================================

export function OrganizationSwitcherWithBilling() {
  const { organizationList } = useOrganizationList()
  const { organization: currentOrg } = useOrganization()

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold mb-6">Your Organizations</h2>
      <div className="space-y-4">
        {organizationList?.map((org) => (
          <div
            key={org.organization.id}
            className={`p-4 border-2 rounded-lg ${
              currentOrg?.id === org.organization.id
                ? 'border-blue-600 bg-blue-50'
                : 'border-gray-200'
            }`}
          >
            <div className="flex items-center justify-between">
              <div>
                <h3 className="font-semibold">{org.organization.name}</h3>
                <p className="text-sm text-gray-600">
                  {org.organization.membersCount} members • {getOrgPlan(org.organization)}
                </p>
              </div>
              <Link
                href={`/organizations/${org.organization.id}/billing`}
                className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              >
                Manage Billing
              </Link>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ============================================================================
// Server-Side Organization Billing Check
// ============================================================================

export async function getOrganizationBilling(organizationId: string) {
  const { has } = await auth()

  // Check organization-level features
  const hasTeamPlan = has({ feature: 'team_workspace' })
  const hasBusinessPlan = has({ feature: 'business_features' })
  const hasEnterprisePlan = has({ feature: 'enterprise_features' })

  return {
    plan: hasEnterprisePlan
      ? 'Enterprise'
      : hasBusinessPlan
      ? 'Business'
      : hasTeamPlan
      ? 'Team'
      : 'Free',
    features: {
      teamWorkspace: hasTeamPlan,
      advancedPermissions: hasBusinessPlan,
      sso: hasEnterprisePlan,
      auditLogs: hasBusinessPlan,
      dedicatedSupport: hasEnterprisePlan,
    },
  }
}

// ============================================================================
// API Route: Add Organization Member (Seat-Based Billing)
// ============================================================================

export async function POST_AddOrganizationMember(request: Request) {
  const { organizationId, userId } = await request.json()

  try {
    // Check if organization has team plan (required for multiple members)
    const { has } = await auth()

    if (!has({ feature: 'team_workspace' })) {
      return Response.json(
        { error: 'Team plan required to add members' },
        { status: 403 }
      )
    }

    // Add member to organization
    const org = await clerkClient.organizations.getOrganization({
      organizationId,
    })

    // Check seat limits based on plan
    const currentMembers = org.membersCount || 0
    const maxSeats = getMaxSeats(has)

    if (currentMembers >= maxSeats) {
      return Response.json(
        { error: `Seat limit reached (${maxSeats} seats)` },
        { status: 403 }
      )
    }

    // Add member (Clerk handles automatic seat billing)
    await clerkClient.organizations.createOrganizationMembership({
      organizationId,
      userId,
      role: 'basic_member',
    })

    return Response.json({
      success: true,
      message: 'Member added successfully',
      newSeatCount: currentMembers + 1,
    })
  } catch (error) {
    console.error('Failed to add member:', error)
    return Response.json(
      { error: 'Failed to add member' },
      { status: 500 }
    )
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

function getOrgPlan(org: any): string {
  // In real app, fetch from org metadata or subscription
  return org.publicMetadata?.plan || 'Free'
}

function getMaxSeats(has: any): number {
  if (has({ feature: 'enterprise_features' })) return Infinity
  if (has({ feature: 'business_features' })) return 50
  if (has({ feature: 'team_workspace' })) return 10
  return 1
}

// ============================================================================
// Reusable Components
// ============================================================================

function StatCard({
  label,
  value,
  icon,
}: {
  label: string
  value: string
  icon: string
}) {
  return (
    <div className="text-center">
      <div className="text-3xl mb-2">{icon}</div>
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">{label}</p>
      <p className="text-2xl font-bold text-gray-900 dark:text-white">{value}</p>
    </div>
  )
}

function FeatureRow({
  name,
  enabled,
  description,
}: {
  name: string
  enabled?: boolean
  description: string
}) {
  return (
    <div className="flex items-center justify-between p-4 border rounded-lg">
      <div className="flex items-center gap-3">
        {enabled ? (
          <svg
            className="w-6 h-6 text-green-500"
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
            className="w-6 h-6 text-gray-300"
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
        <div>
          <h4 className="font-semibold text-gray-900 dark:text-white">{name}</h4>
          <p className="text-sm text-gray-600 dark:text-gray-400">{description}</p>
        </div>
      </div>
      {!enabled && (
        <span className="px-3 py-1 text-xs font-medium bg-gray-100 text-gray-600 rounded-full">
          Upgrade Required
        </span>
      )}
    </div>
  )
}
