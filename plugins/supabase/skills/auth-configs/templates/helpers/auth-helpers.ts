// auth-helpers.ts - Reusable Supabase authentication utilities
// Place this in your lib/ or utils/ directory

import { createClientComponentClient, createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { createClient } from '@supabase/supabase-js'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database.types' // Generate with: npx supabase gen types typescript

// ============================================================================
// Client-Side Helpers (for use in Client Components)
// ============================================================================

/**
 * Get Supabase client for client components
 * Use in 'use client' components only
 */
export function getSupabaseClient() {
  return createClientComponentClient<Database>()
}

/**
 * Sign in with email and password
 */
export async function signInWithEmail(email: string, password: string) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Sign up with email and password
 */
export async function signUpWithEmail(
  email: string,
  password: string,
  metadata?: Record<string, any>
) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: metadata,
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Sign in with magic link (passwordless)
 */
export async function signInWithMagicLink(email: string) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Sign in with OAuth provider
 */
export async function signInWithOAuth(
  provider: 'google' | 'github' | 'discord' | 'facebook' | 'twitter',
  redirectTo?: string
) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: redirectTo || `${window.location.origin}/auth/callback`,
    },
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Sign out the current user
 */
export async function signOut() {
  const supabase = getSupabaseClient()

  const { error } = await supabase.auth.signOut()

  if (error) {
    throw new Error(error.message)
  }
}

/**
 * Reset password for email
 */
export async function resetPasswordForEmail(email: string) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password`,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Update user password (requires authenticated session)
 */
export async function updatePassword(newPassword: string) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.updateUser({
    password: newPassword,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Update user metadata
 */
export async function updateUserMetadata(metadata: Record<string, any>) {
  const supabase = getSupabaseClient()

  const { data, error } = await supabase.auth.updateUser({
    data: metadata,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Get current user session
 */
export async function getSession() {
  const supabase = getSupabaseClient()

  const { data: { session }, error } = await supabase.auth.getSession()

  if (error) {
    throw new Error(error.message)
  }

  return session
}

/**
 * Get current user
 */
export async function getUser() {
  const supabase = getSupabaseClient()

  const { data: { user }, error } = await supabase.auth.getUser()

  if (error) {
    throw new Error(error.message)
  }

  return user
}

// ============================================================================
// Server-Side Helpers (for use in Server Components and API Routes)
// ============================================================================

/**
 * Get Supabase client for server components
 * Use in Server Components and Route Handlers
 */
export function getSupabaseServerClient() {
  return createServerComponentClient<Database>({ cookies })
}

/**
 * Get server-side admin client (uses service role key)
 * ⚠️ Only use in secure server-side contexts (API routes, server actions)
 * NEVER expose service role key to client
 */
export function getSupabaseAdminClient() {
  if (!process.env.SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error('SUPABASE_SERVICE_ROLE_KEY not set')
  }

  return createClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  )
}

/**
 * Get user from server component
 */
export async function getServerUser() {
  const supabase = getSupabaseServerClient()

  const { data: { user }, error } = await supabase.auth.getUser()

  if (error) {
    return null
  }

  return user
}

/**
 * Require authentication in server component
 * Throws error if user is not authenticated
 */
export async function requireAuth() {
  const user = await getServerUser()

  if (!user) {
    throw new Error('Authentication required')
  }

  return user
}

/**
 * Check if user has specific role (from JWT claims)
 */
export async function hasRole(role: string) {
  const supabase = getSupabaseServerClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) return false

  // Check custom claims (requires custom JWT function in Supabase)
  const userRole = user.app_metadata?.role || user.user_metadata?.role

  return userRole === role
}

/**
 * Admin-only function to create user (bypasses email confirmation)
 */
export async function createUserAsAdmin(
  email: string,
  password: string,
  metadata?: Record<string, any>
) {
  const supabase = getSupabaseAdminClient()

  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true, // Skip email confirmation
    user_metadata: metadata,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Admin-only function to delete user
 */
export async function deleteUserAsAdmin(userId: string) {
  const supabase = getSupabaseAdminClient()

  const { data, error } = await supabase.auth.admin.deleteUser(userId)

  if (error) {
    throw new Error(error.message)
  }

  return data
}

/**
 * Admin-only function to list users with pagination
 */
export async function listUsers(page = 1, perPage = 50) {
  const supabase = getSupabaseAdminClient()

  const { data, error } = await supabase.auth.admin.listUsers({
    page,
    perPage,
  })

  if (error) {
    throw new Error(error.message)
  }

  return data
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Verify if email is valid format
 */
export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

/**
 * Check password strength
 */
export function validatePasswordStrength(password: string): {
  isValid: boolean
  errors: string[]
} {
  const errors: string[] = []

  if (password.length < 8) {
    errors.push('Password must be at least 8 characters')
  }

  if (!/[A-Z]/.test(password)) {
    errors.push('Password must contain at least one uppercase letter')
  }

  if (!/[a-z]/.test(password)) {
    errors.push('Password must contain at least one lowercase letter')
  }

  if (!/[0-9]/.test(password)) {
    errors.push('Password must contain at least one number')
  }

  return {
    isValid: errors.length === 0,
    errors,
  }
}

/**
 * Extract provider from OAuth URL
 */
export function getProviderFromUrl(url: string): string | null {
  const match = url.match(/provider=([^&]+)/)
  return match ? match[1] : null
}

/**
 * Format user display name
 */
export function getUserDisplayName(user: any): string {
  return (
    user?.user_metadata?.full_name ||
    user?.user_metadata?.name ||
    user?.email?.split('@')[0] ||
    'User'
  )
}

/**
 * Get user avatar URL with fallback
 */
export function getUserAvatarUrl(user: any, fallback?: string): string {
  return (
    user?.user_metadata?.avatar_url ||
    user?.user_metadata?.picture ||
    fallback ||
    `https://ui-avatars.com/api/?name=${encodeURIComponent(getUserDisplayName(user))}`
  )
}

// ============================================================================
// React Hooks (for Client Components)
// ============================================================================

/**
 * Custom hook to get current user in client component
 * Example usage:
 *
 * const user = useUser()
 * if (!user) return <div>Loading...</div>
 */
export function useUser() {
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const supabase = getSupabaseClient()

    // Get initial user
    supabase.auth.getUser().then(({ data: { user } }) => {
      setUser(user)
      setLoading(false)
    })

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null)
        setLoading(false)
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  return { user, loading }
}

// Type imports for better TypeScript support
import { useState, useEffect } from 'react'
