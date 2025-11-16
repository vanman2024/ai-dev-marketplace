/**
 * Basic Middleware Example
 *
 * Simplest Clerk middleware setup for protecting routes.
 * Perfect for getting started with authentication.
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Define which routes are public (no authentication required)
const isPublicRoute = createRouteMatcher([
  '/', // Home page
  '/sign-in(.*)', // Sign-in page and sub-routes
  '/sign-up(.*)', // Sign-up page and sub-routes
]);

export default clerkMiddleware((auth, req) => {
  // Get the user's authentication state
  const { userId } = auth();

  // If this is a public route, allow access without authentication
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // For all other routes, require authentication
  if (!userId) {
    // Redirect to sign-in page
    const signInUrl = new URL('/sign-in', req.url);

    // Preserve the URL user was trying to access
    signInUrl.searchParams.set('redirect_url', req.url);

    return NextResponse.redirect(signInUrl);
  }

  // User is authenticated, allow the request
  return NextResponse.next();
});

// Configure which routes the middleware should run on
export const config = {
  matcher: [
    // Skip Next.js internals and all static files, unless found in search params
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};

/**
 * How This Works:
 *
 * 1. Public Routes (/, /sign-in, /sign-up):
 *    - Accessible by everyone
 *    - No authentication required
 *
 * 2. Protected Routes (everything else):
 *    - Require authentication
 *    - Redirect to /sign-in if not authenticated
 *    - Preserve original URL for redirect after sign-in
 *
 * 3. Matcher Configuration:
 *    - Runs on all routes except static files
 *    - Runs on all API routes
 *    - Skips Next.js internal routes
 *
 * Environment Variables Required:
 * - NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
 * - CLERK_SECRET_KEY=your_clerk_secret_key_here
 *
 * Next Steps:
 * 1. Create sign-in page: app/sign-in/[[...sign-in]]/page.tsx
 * 2. Create sign-up page: app/sign-up/[[...sign-up]]/page.tsx
 * 3. Add ClerkProvider to app/layout.tsx
 */
