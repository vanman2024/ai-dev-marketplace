/**
 * Protected Route Example with Clerk + Supabase
 *
 * Demonstrates how to create protected routes that:
 * - Require authentication via Clerk
 * - Fetch user-specific data from Supabase
 * - Enforce RLS policies
 */

'use client'

import { useUser, useAuth, RedirectToSignIn } from '@clerk/nextjs'
import { createClient } from '@supabase/supabase-js'
import { useEffect, useState } from 'react'

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

interface UserData {
  posts_count: number
  last_login: string
  total_views: number
}

/**
 * Protected Dashboard Component
 */
export default function ProtectedDashboard() {
  const { isLoaded, isSignedIn, user } = useUser()
  const { getToken } = useAuth()
  const [userData, setUserData] = useState<UserData | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchUserData() {
      if (!user) return

      try {
        // Get Clerk session token for Supabase
        const token = await getToken({ template: 'supabase' })

        if (!token) {
          throw new Error('No authentication token')
        }

        // Create authenticated Supabase client
        const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
          global: {
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        })

        // Fetch user-specific data (RLS enforced)
        const { data, error } = await supabase
          .from('user_stats')
          .select('*')
          .eq('clerk_id', user.id)
          .single()

        if (error) throw error

        setUserData(data)
      } catch (err: any) {
        console.error('Error fetching user data:', err)
        setError(err.message)
      } finally {
        setIsLoading(false)
      }
    }

    if (isSignedIn) {
      fetchUserData()
    }
  }, [isSignedIn, user, getToken])

  // Loading state
  if (!isLoaded || isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  // Not signed in - redirect to sign in page
  if (!isSignedIn) {
    return <RedirectToSignIn />
  }

  // Error state
  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="bg-red-50 border border-red-200 rounded-lg p-6 max-w-md">
          <h2 className="text-red-800 font-semibold mb-2">Error</h2>
          <p className="text-red-600">{error}</p>
        </div>
      </div>
    )
  }

  // Success state - show protected content
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-8">Protected Dashboard</h1>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatCard
            title="Total Posts"
            value={userData?.posts_count || 0}
            icon="📝"
          />
          <StatCard
            title="Total Views"
            value={userData?.total_views || 0}
            icon="👁️"
          />
          <StatCard
            title="Last Login"
            value={
              userData?.last_login
                ? new Date(userData.last_login).toLocaleDateString()
                : 'Never'
            }
            icon="🕒"
          />
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-semibold mb-4">User Information</h2>
          <div className="space-y-2">
            <InfoRow label="Name" value={user?.fullName || 'N/A'} />
            <InfoRow
              label="Email"
              value={user?.primaryEmailAddress?.emailAddress || 'N/A'}
            />
            <InfoRow label="User ID" value={user?.id || 'N/A'} />
          </div>
        </div>
      </div>
    </div>
  )
}

/**
 * Stat Card Component
 */
function StatCard({
  title,
  value,
  icon,
}: {
  title: string
  value: string | number
  icon: string
}) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between mb-2">
        <span className="text-2xl">{icon}</span>
      </div>
      <h3 className="text-gray-600 text-sm font-medium">{title}</h3>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  )
}

/**
 * Info Row Component
 */
function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between py-2 border-b border-gray-100">
      <span className="text-gray-600 font-medium">{label}:</span>
      <span className="text-gray-900">{value}</span>
    </div>
  )
}

/**
 * Server Component Example (Next.js App Router)
 */
export async function ProtectedServerComponent() {
  const { auth } = await import('@clerk/nextjs/server')
  const { userId, getToken } = auth()

  if (!userId) {
    return <RedirectToSignIn />
  }

  const token = await getToken({ template: 'supabase' })

  if (!token) {
    return <div>Error: No authentication token</div>
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
  })

  const { data, error } = await supabase
    .from('user_stats')
    .select('*')
    .eq('clerk_id', userId)
    .single()

  if (error) {
    return <div>Error loading data: {error.message}</div>
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Server Component</h1>
      <pre className="bg-gray-100 p-4 rounded">
        {JSON.stringify(data, null, 2)}
      </pre>
    </div>
  )
}
