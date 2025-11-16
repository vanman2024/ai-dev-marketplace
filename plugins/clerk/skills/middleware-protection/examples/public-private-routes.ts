/**
 * Public vs Private Routes Example
 *
 * Demonstrates clear separation between public and private sections
 * of an application with explicit route definitions.
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// =============================================================================
// PUBLIC ROUTES - Marketing & Landing Pages
// =============================================================================

const isPublicRoute = createRouteMatcher([
  // Landing pages
  '/',
  '/home',

  // Marketing pages
  '/about',
  '/features',
  '/pricing',
  '/blog',
  '/blog/(.*)', // All blog posts

  // Legal pages
  '/terms',
  '/privacy',
  '/contact',

  // Authentication pages
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/sso-callback(.*)',
]);

// =============================================================================
// PRIVATE ROUTES - User Dashboard & Features
// =============================================================================

const isPrivateRoute = createRouteMatcher([
  // Main dashboard
  '/dashboard(.*)',

  // User-specific pages
  '/profile(.*)',
  '/settings(.*)',

  // Feature pages
  '/projects(.*)',
  '/files(.*)',
  '/analytics(.*)',

  // API routes (protected by default)
  '/api/user/(.*)',
  '/api/projects/(.*)',
  '/api/analytics/(.*)',
]);

export default clerkMiddleware((auth, req) => {
  const { userId } = auth();

  // -----------------------------------------------------------------------------
  // 1. Allow Public Routes
  // -----------------------------------------------------------------------------

  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // -----------------------------------------------------------------------------
  // 2. Protect Private Routes
  // -----------------------------------------------------------------------------

  if (isPrivateRoute(req)) {
    if (!userId) {
      const signInUrl = new URL('/sign-in', req.url);
      signInUrl.searchParams.set('redirect_url', req.url);
      return NextResponse.redirect(signInUrl);
    }

    // User is authenticated, allow access
    return NextResponse.next();
  }

  // -----------------------------------------------------------------------------
  // 3. Default Behavior: Protect Everything Else
  // -----------------------------------------------------------------------------

  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
};

/**
 * Route Structure:
 *
 * Public Routes (No Auth):
 * ├── / (landing page)
 * ├── /about
 * ├── /features
 * ├── /pricing
 * ├── /blog/*
 * ├── /terms
 * ├── /privacy
 * ├── /contact
 * ├── /sign-in
 * └── /sign-up
 *
 * Private Routes (Auth Required):
 * ├── /dashboard
 * │   ├── /dashboard/overview
 * │   ├── /dashboard/recent
 * │   └── /dashboard/stats
 * ├── /profile
 * │   ├── /profile/edit
 * │   └── /profile/security
 * ├── /settings
 * │   ├── /settings/account
 * │   ├── /settings/billing
 * │   └── /settings/notifications
 * ├── /projects
 * │   ├── /projects/list
 * │   ├── /projects/new
 * │   └── /projects/[id]
 * └── API Routes
 *     ├── /api/user/*
 *     ├── /api/projects/*
 *     └── /api/analytics/*
 *
 * Customization:
 *
 * To add more public routes:
 * const isPublicRoute = createRouteMatcher([
 *   ...(existing routes),
 *   '/your-new-route',
 *   '/another-route(.*)',
 * ]);
 *
 * To add more private routes:
 * const isPrivateRoute = createRouteMatcher([
 *   ...(existing routes),
 *   '/your-protected-route(.*)',
 * ]);
 */
