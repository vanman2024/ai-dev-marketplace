import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Define route matchers
const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
]);

const isAdminRoute = createRouteMatcher([
  '/admin(.*)',
  '/analytics(.*)',
  '/users(.*)',
]);

const isOrgRoute = createRouteMatcher([
  '/org/(.*)',
  '/teams/(.*)',
]);

export default clerkMiddleware((auth, req) => {
  const { userId, orgId, sessionClaims } = auth();

  // Allow public routes
  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // Require authentication for all protected routes
  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  // Check admin routes - require 'admin' role
  if (isAdminRoute(req)) {
    const userRole = sessionClaims?.metadata?.role as string | undefined;

    if (userRole !== 'admin') {
      const unauthorizedUrl = new URL('/unauthorized', req.url);
      return NextResponse.redirect(unauthorizedUrl);
    }
  }

  // Check organization routes - require organization membership
  if (isOrgRoute(req)) {
    if (!orgId) {
      const selectOrgUrl = new URL('/select-org', req.url);
      selectOrgUrl.searchParams.set('redirect_url', req.url);
      return NextResponse.redirect(selectOrgUrl);
    }

    // Optional: Check organization role
    const orgRole = sessionClaims?.metadata?.orgRole as string | undefined;
    if (req.nextUrl.pathname.startsWith('/org/settings') && orgRole !== 'admin') {
      const unauthorizedUrl = new URL('/org/unauthorized', req.url);
      return NextResponse.redirect(unauthorizedUrl);
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
