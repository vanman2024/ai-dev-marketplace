/**
 * Conditional Routing Example
 *
 * Demonstrates advanced conditional routing based on:
 * - User authentication state
 * - User roles and permissions
 * - Organization membership
 * - Feature flags
 * - Custom business logic
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
]);

const isOnboardingRoute = createRouteMatcher(['/onboarding(.*)']);
const isDashboardRoute = createRouteMatcher(['/dashboard(.*)']);
const isPremiumRoute = createRouteMatcher(['/premium(.*)']);

export default clerkMiddleware((auth, req) => {
  const { userId, sessionClaims, orgId } = auth();

  // =========================================================================
  // 1. Public Routes - Allow Everyone
  // =========================================================================

  if (isPublicRoute(req)) {
    return NextResponse.next();
  }

  // =========================================================================
  // 2. Authentication Required
  // =========================================================================

  if (!userId) {
    const signInUrl = new URL('/sign-in', req.url);
    signInUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(signInUrl);
  }

  // =========================================================================
  // 3. Onboarding Flow - First-Time Users
  // =========================================================================

  const hasCompletedOnboarding = sessionClaims?.metadata?.onboardingComplete as
    | boolean
    | undefined;

  // Redirect to onboarding if not completed (except when already on onboarding page)
  if (!hasCompletedOnboarding && !isOnboardingRoute(req)) {
    const onboardingUrl = new URL('/onboarding', req.url);
    return NextResponse.redirect(onboardingUrl);
  }

  // Prevent accessing onboarding if already completed
  if (hasCompletedOnboarding && isOnboardingRoute(req)) {
    const dashboardUrl = new URL('/dashboard', req.url);
    return NextResponse.redirect(dashboardUrl);
  }

  // =========================================================================
  // 4. Premium Features - Subscription Check
  // =========================================================================

  if (isPremiumRoute(req)) {
    const subscriptionTier = sessionClaims?.metadata?.subscriptionTier as
      | string
      | undefined;

    if (subscriptionTier !== 'premium' && subscriptionTier !== 'enterprise') {
      const upgradeUrl = new URL('/pricing', req.url);
      upgradeUrl.searchParams.set('upgrade_required', 'true');
      return NextResponse.redirect(upgradeUrl);
    }
  }

  // =========================================================================
  // 5. Organization-Scoped Routes
  // =========================================================================

  const isOrgRequired = req.nextUrl.pathname.startsWith('/org/') ||
    req.nextUrl.pathname.startsWith('/teams/');

  if (isOrgRequired && !orgId) {
    const selectOrgUrl = new URL('/select-org', req.url);
    selectOrgUrl.searchParams.set('redirect_url', req.url);
    return NextResponse.redirect(selectOrgUrl);
  }

  // =========================================================================
  // 6. Role-Based Access Control
  // =========================================================================

  const userRole = sessionClaims?.metadata?.role as string | undefined;

  // Admin-only routes
  if (req.nextUrl.pathname.startsWith('/admin/')) {
    if (userRole !== 'admin') {
      const unauthorizedUrl = new URL('/unauthorized', req.url);
      return NextResponse.redirect(unauthorizedUrl);
    }
  }

  // Manager-only routes
  if (req.nextUrl.pathname.startsWith('/manage/')) {
    if (userRole !== 'manager' && userRole !== 'admin') {
      const unauthorizedUrl = new URL('/unauthorized', req.url);
      return NextResponse.redirect(unauthorizedUrl);
    }
  }

  // =========================================================================
  // 7. Feature Flags - Beta Features
  // =========================================================================

  const hasBetaAccess = sessionClaims?.metadata?.betaFeatures as
    | boolean
    | undefined;

  if (req.nextUrl.pathname.startsWith('/beta/')) {
    if (!hasBetaAccess) {
      const waitlistUrl = new URL('/beta/waitlist', req.url);
      return NextResponse.redirect(waitlistUrl);
    }
  }

  // =========================================================================
  // 8. Time-Based Access (e.g., maintenance mode)
  // =========================================================================

  const isMaintenanceMode = false; // Set this via environment variable

  if (isMaintenanceMode && userRole !== 'admin') {
    const maintenanceUrl = new URL('/maintenance', req.url);
    return NextResponse.redirect(maintenanceUrl);
  }

  // =========================================================================
  // 9. Geographic Restrictions (optional)
  // =========================================================================

  const userCountry = req.geo?.country || 'unknown';
  const restrictedCountries = ['XX', 'YY']; // ISO country codes

  if (
    restrictedCountries.includes(userCountry) &&
    req.nextUrl.pathname.startsWith('/restricted/')
  ) {
    const blockedUrl = new URL('/region-blocked', req.url);
    return NextResponse.redirect(blockedUrl);
  }

  // =========================================================================
  // 10. Custom Business Logic
  // =========================================================================

  // Example: Redirect free users trying to access project limit
  const projectCount = sessionClaims?.metadata?.projectCount as
    | number
    | undefined;
  const subscriptionTier = sessionClaims?.metadata?.subscriptionTier as
    | string
    | undefined;

  if (
    req.nextUrl.pathname === '/projects/new' &&
    subscriptionTier === 'free' &&
    projectCount &&
    projectCount >= 3
  ) {
    const limitUrl = new URL('/pricing', req.url);
    limitUrl.searchParams.set('reason', 'project_limit');
    return NextResponse.redirect(limitUrl);
  }

  // =========================================================================
  // Allow Request to Continue
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
 * Setting Custom Metadata:
 *
 * You can set custom metadata in Clerk Dashboard or via API:
 *
 * // app/api/complete-onboarding/route.ts
 * import { clerkClient, auth } from '@clerk/nextjs/server';
 *
 * export async function POST() {
 *   const { userId } = auth();
 *
 *   await clerkClient.users.updateUserMetadata(userId, {
 *     publicMetadata: {
 *       onboardingComplete: true,
 *       role: 'user',
 *     },
 *   });
 *
 *   return NextResponse.json({ success: true });
 * }
 *
 * // app/api/upgrade-subscription/route.ts
 * export async function POST() {
 *   const { userId } = auth();
 *
 *   await clerkClient.users.updateUserMetadata(userId, {
 *     publicMetadata: {
 *       subscriptionTier: 'premium',
 *     },
 *   });
 *
 *   return NextResponse.json({ success: true });
 * }
 */
