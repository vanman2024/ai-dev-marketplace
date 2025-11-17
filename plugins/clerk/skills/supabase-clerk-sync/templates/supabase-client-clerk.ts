/**
 * Supabase Client with Clerk Authentication
 *
 * This module configures the Supabase client to use Clerk session tokens
 * for authentication, enabling RLS policies based on Clerk JWT claims.
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js'
import { useAuth } from '@clerk/nextjs'

// Environment variables
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

/**
 * Create Supabase client with Clerk session token
 *
 * This client automatically includes the Clerk JWT in requests,
 * allowing Supabase RLS policies to use Clerk user identity.
 *
 * @param supabaseAccessToken - Clerk session token from getToken()
 * @returns Configured Supabase client
 */
export function createClerkSupabaseClient(
  supabaseAccessToken: string
): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${supabaseAccessToken}`,
      },
    },
  })
}

/**
 * React Hook: Get Supabase client with current Clerk session
 *
 * Usage in React components:
 *
 * ```tsx
 * const { supabase, isLoading } = useSupabaseClient()
 *
 * if (isLoading) return <div>Loading...</div>
 *
 * const { data } = await supabase.from('users').select()
 * ```
 */
export function useSupabaseClient() {
  const { getToken } = useAuth()
  const [supabase, setSupabase] = React.useState<SupabaseClient | null>(null)
  const [isLoading, setIsLoading] = React.useState(true)

  React.useEffect(() => {
    const initSupabase = async () => {
      try {
        // Get Clerk session token for Supabase
        const token = await getToken({ template: 'supabase' })

        if (!token) {
          console.warn('No Clerk token available')
          setSupabase(null)
          return
        }

        const client = createClerkSupabaseClient(token)
        setSupabase(client)
      } catch (error) {
        console.error('Failed to initialize Supabase client:', error)
        setSupabase(null)
      } finally {
        setIsLoading(false)
      }
    }

    initSupabase()
  }, [getToken])

  return { supabase, isLoading }
}

/**
 * Server-side: Get Supabase client with Clerk auth
 *
 * Usage in API routes or server components:
 *
 * ```tsx
 * import { auth } from '@clerk/nextjs'
 *
 * export async function GET() {
 *   const supabase = await getServerSupabaseClient()
 *   const { data } = await supabase.from('users').select()
 *   return Response.json(data)
 * }
 * ```
 */
export async function getServerSupabaseClient(): Promise<SupabaseClient> {
  const { getToken } = auth()

  const token = await getToken({ template: 'supabase' })

  if (!token) {
    throw new Error('No authentication token available')
  }

  return createClerkSupabaseClient(token)
}

/**
 * Admin Supabase client (bypasses RLS)
 *
 * WARNING: Use only in secure server contexts!
 * This client has full access and bypasses all RLS policies.
 *
 * Usage:
 * ```tsx
 * const adminClient = createAdminSupabaseClient()
 * // Can access all data regardless of RLS
 * ```
 */
export function createAdminSupabaseClient(): SupabaseClient {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY

  if (!serviceRoleKey) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY not configured')
  }

  return createClient(SUPABASE_URL, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })
}

/**
 * Type-safe Supabase client with Database types
 *
 * Generate types with:
 * ```bash
 * npx supabase gen types typescript --project-id YOUR_PROJECT_REF > types/database.types.ts
 * ```
 *
 * Then import and use:
 * ```tsx
 * import { Database } from './types/database.types'
 *
 * const supabase = createClerkSupabaseClient<Database>(token)
 * // Now fully type-safe!
 * ```
 */
export function createTypedClerkSupabaseClient<Database>(
  supabaseAccessToken: string
): SupabaseClient<Database> {
  return createClient<Database>(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${supabaseAccessToken}`,
      },
    },
  })
}

/**
 * Example: Query with automatic auth
 *
 * This shows a complete example of using Clerk auth with Supabase queries
 */
export async function exampleAuthenticatedQuery() {
  const { getToken } = auth()
  const token = await getToken({ template: 'supabase' })

  if (!token) {
    throw new Error('Not authenticated')
  }

  const supabase = createClerkSupabaseClient(token)

  // This query will use RLS policies with Clerk JWT claims
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('clerk_id', 'user_xxx') // RLS will verify this matches JWT

  if (error) {
    throw error
  }

  return data
}

/**
 * Token refresh handler
 *
 * Clerk tokens expire after 1 hour. This utility helps handle refreshes.
 */
export async function withTokenRefresh<T>(
  operation: (supabase: SupabaseClient) => Promise<T>
): Promise<T> {
  const { getToken } = auth()

  // Get fresh token
  const token = await getToken({ template: 'supabase' })

  if (!token) {
    throw new Error('Authentication required')
  }

  const supabase = createClerkSupabaseClient(token)

  try {
    return await operation(supabase)
  } catch (error: any) {
    // If auth error, might be expired token
    if (error?.code === 'PGRST301' || error?.message?.includes('JWT')) {
      console.log('Token might be expired, refreshing...')

      // Force refresh
      const newToken = await getToken({
        template: 'supabase',
        skipCache: true
      })

      if (!newToken) {
        throw new Error('Failed to refresh token')
      }

      const newSupabase = createClerkSupabaseClient(newToken)
      return await operation(newSupabase)
    }

    throw error
  }
}
