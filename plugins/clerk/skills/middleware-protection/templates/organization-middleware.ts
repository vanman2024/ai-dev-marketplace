import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

/**
 * Organization Middleware Template
 *
 * Provides organization-scoped route protection with:
 * - Organization membership verification
 * - Organization role-based access control
 * - Automatic organization selection flow
 */

// Public routes
const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/about',
  '/pricing',
]);

// Organization routes (require organization membership)
const isOrgRoute = createRouteMatcher([
  '/org/(.*)',
  '/workspace/(.*)',
  '/teams/(.*)',
]);

// Organization admin routes (require org:admin role)
const isOrgAdminRoute = createRouteMatcher([
  '/org/settings/(.*)',
  '/org/members/(.*)',
  '/org/billing/(.*)',
  '/org/integrations/(.*)',
]);

export default clerkMiddleware((auth, req) => {
  const { userId, orgId, orgRole } = auth();

  // Allow public routes
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // Require authentication
  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  // Handle organization routes
  if (isOrgRoute(req)) {
    // Require organization membership
    if (!orgId) {
      const selectOrgUrl = new URL('/select-org', req.url);
      selectOrgUrl.searchParams.set('redirect_url', req.url);
      return NextResponse.redirect(selectOrgUrl);
    }

    // Check organization admin routes
    if (isOrgAdminRoute(req)) {
      if (orgRole !== 'org:admin') {
        const unauthorizedUrl = new URL('/org/unauthorized', req.url);
        return NextResponse.redirect(unauthorizedUrl);
      }
    }
  }

  return NextResponse.next();
});

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
};
