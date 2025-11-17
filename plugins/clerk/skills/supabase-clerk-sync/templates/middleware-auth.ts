/**
 * Next.js Middleware for Clerk + Supabase Authentication
 *
 * This middleware:
 * 1. Validates Clerk authentication
 * 2. Adds Clerk session token to Supabase requests
 * 3. Protects routes requiring authentication
 */

import { authMiddleware } from '@clerk/nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export default authMiddleware({
  // Public routes that don't require authentication
  publicRoutes: ['/', '/api/public(.*)'],

  // Routes that should be accessible while signed out
  ignoredRoutes: ['/api/webhooks/clerk'],

  // After authentication, inject Supabase token
  afterAuth(auth, req, evt) {
    // User is signed out
    if (!auth.userId && !auth.isPublicRoute) {
      const signInUrl = new URL('/sign-in', req.url)
      signInUrl.searchParams.set('redirect_url', req.url)
      return NextResponse.redirect(signInUrl)
    }

    // User is signed in but accessing a public route
    if (auth.userId && auth.isPublicRoute) {
      return NextResponse.next()
    }

    // User is signed in and accessing a protected route
    if (auth.userId && !auth.isPublicRoute) {
      return NextResponse.next()
    }

    return NextResponse.next()
  },
})

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)'],
}

/**
 * Custom middleware with Supabase token injection
 *
 * Use this if you need more control over the middleware behavior
 */
export async function customMiddleware(req: NextRequest) {
  const { auth } = await import('@clerk/nextjs/server')
  const { userId, sessionId, getToken } = auth()

  // Allow public routes
  if (req.nextUrl.pathname.startsWith('/api/public')) {
    return NextResponse.next()
  }

  // Protect authenticated routes
  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url)
    signInUrl.searchParams.set('redirect_url', req.url)
    return NextResponse.redirect(signInUrl)
  }

  // Get Clerk session token for Supabase
  const supabaseToken = await getToken({ template: 'supabase' })

  // Create response with Supabase token in headers
  const response = NextResponse.next()

  if (supabaseToken) {
    // Add token to response headers for client-side access
    response.headers.set('x-supabase-token', supabaseToken)
  }

  return response
}

/**
 * Route protection helper
 *
 * Use in API routes to verify authentication
 */
export async function requireAuth() {
  const { auth } = await import('@clerk/nextjs/server')
  const { userId } = auth()

  if (!userId) {
    throw new Error('Unauthorized')
  }

  return { userId }
}

/**
 * Get authenticated Supabase client in middleware
 */
export async function getAuthenticatedSupabaseClient() {
  const { auth } = await import('@clerk/nextjs/server')
  const { getToken } = auth()

  const token = await getToken({ template: 'supabase' })

  if (!token) {
    throw new Error('No authentication token')
  }

  const { createClient } = await import('@supabase/supabase-js')

  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    }
  )
}
