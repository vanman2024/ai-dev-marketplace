/**
 * Organization Routes Example
 *
 * Demonstrates organization-scoped route protection with:
 * - Organization membership verification
 * - Organization role-based access
 * - Team and workspace isolation
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Public routes
const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
]);

// Organization routes (require org membership)
const isOrgRoute = createRouteMatcher([
  '/org/(.*)',
  '/teams/(.*)',
  '/workspace/(.*)',
]);

// Organization settings (require org admin role)
const isOrgAdminRoute = createRouteMatcher([
  '/org/settings/(.*)',
  '/org/members/(.*)',
  '/org/billing/(.*)',
]);

// Personal routes (no org required)
const isPersonalRoute = createRouteMatcher([
  '/dashboard',
  '/profile(.*)',
  '/settings(.*)',
]);

export default clerkMiddleware((auth, req) => {
  const { userId, orgId, orgRole, sessionClaims } = auth();

  // =========================================================================
  // 1. Public Routes
  // =========================================================================

  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // =========================================================================
  // 2. Require Authentication
  // =========================================================================

  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  // =========================================================================
  // 3. Personal Routes (No Organization Required)
  // =========================================================================

  if (isPersonalRoute(req)) {
    return NextResponse.next();
  }

  // =========================================================================
  // 4. Organization Routes (Require Organization Membership)
  // =========================================================================

  if (isOrgRoute(req)) {
    // Check if user has active organization
    if (!orgId) {
      const selectOrgUrl = new URL('/select-org', req.url);
      selectOrgUrl.searchParams.set('redirect_url', req.url);
      return NextResponse.redirect(selectOrgUrl);
    }

    // Check organization admin routes
    if (isOrgAdminRoute(req)) {
      // Only org admins can access admin routes
      if (orgRole !== 'org:admin') {
        const unauthorizedUrl = new URL('/org/unauthorized', req.url);
        return NextResponse.redirect(unauthorizedUrl);
      }
    }

    // Optional: Check if organization is active/not suspended
    const orgStatus = sessionClaims?.metadata?.orgStatus as string | undefined;
    if (orgStatus === 'suspended') {
      const suspendedUrl = new URL('/org/suspended', req.url);
      return NextResponse.redirect(suspendedUrl);
    }

    return NextResponse.next();
  }

  // =========================================================================
  // 5. Default Protection
  // =========================================================================

  return NextResponse.next();
});

export const config = {
  matcher: [
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    '/(api|trpc)(.*)',
  ],
};

/**
 * Organization Structure:
 *
 * User without organization:
 * - Can access: /dashboard, /profile, /settings
 * - Cannot access: /org/*, /teams/*, /workspace/*
 * - Redirected to: /select-org when trying to access org routes
 *
 * User with organization (member role):
 * - Can access: /org/dashboard, /org/projects, /teams/*
 * - Cannot access: /org/settings, /org/members, /org/billing
 * - Redirected to: /org/unauthorized for admin-only routes
 *
 * User with organization (admin role):
 * - Can access: All org routes including admin routes
 *
 * Organization Roles:
 * - org:admin - Full access to organization
 * - org:member - Standard member access
 * - org:guest - Limited guest access (optional)
 *
 * Organization Selection Page (/select-org):
 *
 * // app/select-org/page.tsx
 * import { auth, clerkClient } from '@clerk/nextjs/server';
 * import { OrganizationList } from '@clerk/nextjs';
 *
 * export default async function SelectOrgPage({
 *   searchParams,
 * }: {
 *   searchParams: { redirect_url?: string };
 * }) {
 *   return (
 *     <div>
 *       <h1>Select Organization</h1>
 *       <OrganizationList
 *         afterSelectOrganizationUrl={searchParams.redirect_url || '/org/dashboard'}
 *         afterCreateOrganizationUrl={searchParams.redirect_url || '/org/dashboard'}
 *       />
 *     </div>
 *   );
 * }
 *
 * Switching Organizations:
 *
 * // app/org/switch/page.tsx
 * import { OrganizationSwitcher } from '@clerk/nextjs';
 *
 * export default function SwitchOrganization() {
 *   return (
 *     <OrganizationSwitcher
 *       afterSelectOrganizationUrl="/org/dashboard"
 *       organizationProfileMode="modal"
 *     />
 *   );
 * }
 */
