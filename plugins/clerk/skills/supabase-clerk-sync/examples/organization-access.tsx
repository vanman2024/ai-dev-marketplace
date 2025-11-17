/**
 * Organization-Based Access Example
 *
 * Demonstrates multi-tenant architecture with Clerk organizations
 * and Supabase RLS policies for organization-scoped data access.
 */

'use client'

import { useOrganization, useOrganizationList, useAuth } from '@clerk/nextjs'
import { createClient } from '@supabase/supabase-js'
import { useEffect, useState } from 'react'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

interface OrganizationResource {
  id: string
  clerk_org_id: string
  name: string
  data: any
  created_by: string
  created_at: string
}

/**
 * Organization Dashboard with Multi-Tenant Access
 */
export default function OrganizationDashboard() {
  const { organization, isLoaded } = useOrganization()
  const { setActive, organizationList } = useOrganizationList()
  const { getToken } = useAuth()

  const [resources, setResources] = useState<OrganizationResource[]>([])
  const [isLoadingResources, setIsLoadingResources] = useState(true)

  useEffect(() => {
    async function fetchOrgResources() {
      if (!organization) {
        setIsLoadingResources(false)
        return
      }

      try {
        const token = await getToken({ template: 'supabase' })
        if (!token) return

        const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
          global: {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        })

        // RLS policy ensures user can only access their org's resources
        const { data, error } = await supabase
          .from('org_resources')
          .select('*')
          .eq('clerk_org_id', organization.id)
          .order('created_at', { ascending: false })

        if (error) throw error

        setResources(data || [])
      } catch (error) {
        console.error('Error fetching org resources:', error)
      } finally {
        setIsLoadingResources(false)
      }
    }

    fetchOrgResources()
  }, [organization, getToken])

  if (!isLoaded) {
    return <div>Loading...</div>
  }

  if (!organization) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">No Organization Selected</h2>
          <p className="mb-4">Please select or create an organization</p>
          <OrganizationSelector
            organizations={organizationList || []}
            onSelect={setActive}
          />
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <img
                src={organization.imageUrl}
                alt={organization.name}
                className="w-12 h-12 rounded-full"
              />
              <div>
                <h1 className="text-2xl font-bold">{organization.name}</h1>
                <p className="text-gray-600">
                  {organization.membersCount} members
                </p>
              </div>
            </div>

            <OrganizationSelector
              organizations={organizationList || []}
              onSelect={setActive}
            />
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="mb-6">
          <h2 className="text-xl font-semibold mb-4">Organization Resources</h2>
          <CreateResourceButton orgId={organization.id} />
        </div>

        {isLoadingResources ? (
          <div>Loading resources...</div>
        ) : (
          <ResourcesList resources={resources} />
        )}
      </main>
    </div>
  )
}

/**
 * Organization Selector Component
 */
function OrganizationSelector({
  organizations,
  onSelect,
}: {
  organizations: any[]
  onSelect: any
}) {
  return (
    <select
      onChange={(e) => {
        const org = organizations.find((o) => o.organization.id === e.target.value)
        if (org) {
          onSelect({ organization: org.organization })
        }
      }}
      className="border rounded px-3 py-2"
    >
      <option value="">Select Organization</option>
      {organizations.map(({ organization }) => (
        <option key={organization.id} value={organization.id}>
          {organization.name}
        </option>
      ))}
    </select>
  )
}

/**
 * Create Resource Button
 */
function CreateResourceButton({ orgId }: { orgId: string }) {
  const { getToken } = useAuth()
  const [isCreating, setIsCreating] = useState(false)

  async function handleCreate() {
    setIsCreating(true)

    try {
      const token = await getToken({ template: 'supabase' })
      if (!token) return

      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      })

      const resourceName = prompt('Enter resource name:')
      if (!resourceName) return

      // JWT automatically includes org_id claim
      // RLS policy verifies it matches the data
      const { error } = await supabase.from('org_resources').insert({
        clerk_org_id: orgId,
        name: resourceName,
        data: { created_from: 'dashboard' },
      })

      if (error) throw error

      alert('Resource created successfully')
      window.location.reload()
    } catch (error: any) {
      alert('Error creating resource: ' + error.message)
    } finally {
      setIsCreating(false)
    }
  }

  return (
    <button
      onClick={handleCreate}
      disabled={isCreating}
      className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
    >
      {isCreating ? 'Creating...' : 'Create Resource'}
    </button>
  )
}

/**
 * Resources List Component
 */
function ResourcesList({ resources }: { resources: OrganizationResource[] }) {
  const { getToken } = useAuth()

  async function handleDelete(resourceId: string) {
    if (!confirm('Delete this resource?')) return

    try {
      const token = await getToken({ template: 'supabase' })
      if (!token) return

      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        global: {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      })

      const { error } = await supabase
        .from('org_resources')
        .delete()
        .eq('id', resourceId)

      if (error) throw error

      alert('Resource deleted')
      window.location.reload()
    } catch (error: any) {
      alert('Error deleting resource: ' + error.message)
    }
  }

  if (resources.length === 0) {
    return (
      <div className="text-center py-12 bg-white rounded-lg shadow">
        <p className="text-gray-600">No resources yet</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {resources.map((resource) => (
        <div key={resource.id} className="bg-white rounded-lg shadow p-6">
          <h3 className="font-semibold text-lg mb-2">{resource.name}</h3>
          <p className="text-sm text-gray-600 mb-4">
            Created {new Date(resource.created_at).toLocaleDateString()}
          </p>
          <button
            onClick={() => handleDelete(resource.id)}
            className="text-red-600 hover:text-red-800 text-sm"
          >
            Delete
          </button>
        </div>
      ))}
    </div>
  )
}

/**
 * Check organization membership and role
 */
export function useOrganizationRole() {
  const { organization, membership } = useOrganization()

  const isAdmin = membership?.role === 'admin'
  const isEditor = membership?.role === 'admin' || membership?.role === 'editor'
  const isMember = !!membership

  return {
    organization,
    membership,
    isAdmin,
    isEditor,
    isMember,
    role: membership?.role,
  }
}

/**
 * Role-based component wrapper
 */
export function RequireRole({
  children,
  role,
}: {
  children: React.ReactNode
  role: 'admin' | 'editor' | 'member'
}) {
  const { membership } = useOrganization()

  if (!membership) {
    return <div>Not a member of this organization</div>
  }

  const hasAccess =
    role === 'member' ||
    (role === 'editor' &&
      (membership.role === 'admin' || membership.role === 'editor')) ||
    (role === 'admin' && membership.role === 'admin')

  if (!hasAccess) {
    return <div>Insufficient permissions</div>
  }

  return <>{children}</>
}
