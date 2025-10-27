// middleware.ts - Supabase Auth Middleware for Next.js
// Place this file in the root of your Next.js project

import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

// Configuration
const config = {
  // Routes that require authentication
  protectedRoutes: [
    '/dashboard',
    '/profile',
    '/settings',
    '/api/protected',
  ],

  // Routes that redirect to dashboard if already authenticated
  authRoutes: [
    '/login',
    '/signup',
    '/reset-password',
  ],

  // Public routes (no auth check)
  publicRoutes: [
    '/',
    '/about',
    '/pricing',
    '/api/public',
  ],

  // Default redirect paths
  redirects: {
    afterLogin: '/dashboard',
    afterLogout: '/login',
  },
}

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          // Set cookie in request for current request
          request.cookies.set({
            name,
            value,
            ...options,
          })
          // Update response with new cookie
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: CookieOptions) {
          // Remove cookie from request
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          // Remove cookie from response
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
    }
  )

  // Refresh session if expired - required for Server Components
  const { data: { user } } = await supabase.auth.getUser()

  // Get current path
  const path = request.nextUrl.pathname

  // Check if path is protected
  const isProtectedRoute = config.protectedRoutes.some(route =>
    path.startsWith(route)
  )

  // Check if path is auth route (login, signup, etc)
  const isAuthRoute = config.authRoutes.some(route =>
    path.startsWith(route)
  )

  // Redirect logic
  if (isProtectedRoute && !user) {
    // User is not authenticated, redirect to login
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = '/login'
    redirectUrl.searchParams.set('redirectTo', path)
    return NextResponse.redirect(redirectUrl)
  }

  if (isAuthRoute && user) {
    // User is already authenticated, redirect to dashboard
    const redirectUrl = request.nextUrl.clone()
    redirectUrl.pathname = config.redirects.afterLogin
    return NextResponse.redirect(redirectUrl)
  }

  return response
}

// Configure which routes to run middleware on
export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (images, etc)
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
