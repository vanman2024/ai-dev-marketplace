import { createRouteMatcher } from '@clerk/nextjs/server';

/**
 * Route Matcher Patterns for Clerk Middleware
 *
 * Use createRouteMatcher to define route groups for different protection levels.
 * Patterns support glob syntax and regular expressions.
 */

// =============================================================================
// PUBLIC ROUTES (No authentication required)
// =============================================================================

export const isPublicRoute = createRouteMatcher([
  // Landing and marketing pages
  '/',
  '/about',
  '/features',
  '/pricing',
  '/blog',
  '/blog/(.*)', // All blog posts
  '/contact',

  // Legal pages
  '/terms',
  '/privacy',
  '/cookies',

  // Authentication pages
  '/sign-in(.*)',
  '/sign-up(.*)',
  '/sso-callback(.*)',

  // Public API routes
  '/api/webhooks/(.*)', // Clerk webhooks
  '/api/public/(.*)',   // Public API endpoints
]);

// =============================================================================
// PROTECTED ROUTES (Authentication required)
// =============================================================================

export const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/profile(.*)',
  '/settings(.*)',
  '/projects(.*)',
]);

// =============================================================================
// ORGANIZATION ROUTES (Organization membership required)
// =============================================================================

export const isOrgRoute = createRouteMatcher([
  '/org/(.*)',
  '/teams/(.*)',
  '/workspace/(.*)',
]);

// =============================================================================
// ADMIN ROUTES (Admin role required)
// =============================================================================

export const isAdminRoute = createRouteMatcher([
  '/admin(.*)',
  '/analytics(.*)',
  '/users(.*)',
]);

// =============================================================================
// API ROUTES
// =============================================================================

export const isApiRoute = createRouteMatcher([
  '/api/(.*)',
]);

export const isPublicApiRoute = createRouteMatcher([
  '/api/webhooks/(.*)',
  '/api/public/(.*)',
  '/api/health',
  '/api/status',
]);

export const isProtectedApiRoute = createRouteMatcher([
  '/api/user/(.*)',
  '/api/projects/(.*)',
  '/api/data/(.*)',
]);

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Check if route requires authentication
 */
export function requiresAuth(req: Request): boolean {
  return !isPublicRoute(req);
}

/**
 * Check if route requires organization membership
 */
export function requiresOrg(req: Request): boolean {
  return isOrgRoute(req);
}

/**
 * Check if route requires admin access
 */
export function requiresAdmin(req: Request): boolean {
  return isAdminRoute(req);
}

/**
 * Get route protection level
 */
export function getProtectionLevel(req: Request): 'public' | 'protected' | 'org' | 'admin' {
  if (isPublicRoute(req)) return 'public';
  if (isAdminRoute(req)) return 'admin';
  if (isOrgRoute(req)) return 'org';
  if (isProtectedRoute(req)) return 'protected';
  return 'protected'; // Default to protected
}
