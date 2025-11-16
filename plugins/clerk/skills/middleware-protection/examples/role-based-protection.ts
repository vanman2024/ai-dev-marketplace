/**
 * Role-Based Protection Example
 *
 * Demonstrates role-based access control (RBAC) with:
 * - Multiple user roles (admin, manager, user, guest)
 * - Permission-based route protection
 * - Hierarchical role checking
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Public routes
const isPublicRoute = createRouteMatcher([
  '/',
  '/sign-in(.*)',
  '/sign-up(.*)',
]);

// Admin routes (require 'admin' role)
const isAdminRoute = createRouteMatcher([
  '/admin(.*)',
  '/users/(.*)',
  '/analytics(.*)',
  '/logs(.*)',
]);

// Manager routes (require 'manager' or 'admin' role)
const isManagerRoute = createRouteMatcher([
  '/manage(.*)',
  '/reports(.*)',
  '/team/(.*)',
]);

// User routes (require authenticated user)
const isUserRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/profile(.*)',
  '/projects(.*)',
]);

/**
 * Role Hierarchy (from highest to lowest):
 * admin > manager > user > guest
 */
const roleHierarchy = {
  admin: 4,
  manager: 3,
  user: 2,
  guest: 1,
} as const;

type Role = keyof typeof roleHierarchy;

/**
 * Check if user role has sufficient permissions
 */
function hasRole(userRole: string | undefined, requiredRole: Role): boolean {
  if (!userRole) return false;

  const userLevel = roleHierarchy[userRole as Role] || 0;
  const requiredLevel = roleHierarchy[requiredRole];

  return userLevel >= requiredLevel;
}

export default clerkMiddleware((auth, req) => {
  const { userId, sessionClaims } = auth();

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

  // Get user role from session claims
  const userRole = sessionClaims?.metadata?.role as string | undefined;

  // =========================================================================
  // 3. Admin Routes (Admin Only)
  // =========================================================================

  if (isAdminRoute(req)) {
    if (!hasRole(userRole, 'admin')) {
      const unauthorizedUrl = new URL('/unauthorized', req.url);
      unauthorizedUrl.searchParams.set('required_role', 'admin');
      return NextResponse.redirect(unauthorizedUrl);
    }

    return NextResponse.next();
  }

  // =========================================================================
  // 4. Manager Routes (Manager or Admin)
  // =========================================================================

  if (isManagerRoute(req)) {
    if (!hasRole(userRole, 'manager')) {
      const unauthorizedUrl = new URL('/unauthorized', req.url);
      unauthorizedUrl.searchParams.set('required_role', 'manager');
      return NextResponse.redirect(unauthorizedUrl);
    }

    return NextResponse.next();
  }

  // =========================================================================
  // 5. User Routes (Any Authenticated User)
  // =========================================================================

  if (isUserRoute(req)) {
    // Guest users have limited access
    if (userRole === 'guest' && req.nextUrl.pathname.startsWith('/projects')) {
      const upgradeUrl = new URL('/upgrade', req.url);
      upgradeUrl.searchParams.set('feature', 'projects');
      return NextResponse.redirect(upgradeUrl);
    }

    return NextResponse.next();
  }

  // =========================================================================
  // 6. Default: Allow Access
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
 * Setting User Roles:
 *
 * You can set roles via Clerk Dashboard or API:
 *
 * // app/api/set-role/route.ts
 * import { clerkClient, auth } from '@clerk/nextjs/server';
 * import { NextResponse } from 'next/server';
 *
 * export async function POST(req: Request) {
 *   const { userId } = auth();
 *
 *   if (!userId) {
 *     return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
 *   }
 *
 *   const { role } = await req.json();
 *
 *   // Validate role
 *   if (!['admin', 'manager', 'user', 'guest'].includes(role)) {
 *     return NextResponse.json({ error: 'Invalid role' }, { status: 400 });
 *   }
 *
 *   await clerkClient.users.updateUserMetadata(userId, {
 *     publicMetadata: {
 *       role,
 *     },
 *   });
 *
 *   return NextResponse.json({ success: true, role });
 * }
 *
 * Permission-Based Access Control:
 *
 * For more granular control, use permissions instead of roles:
 *
 * const permissions = sessionClaims?.metadata?.permissions as string[] | undefined;
 *
 * const hasPermission = (permission: string) => {
 *   return permissions?.includes(permission) || false;
 * };
 *
 * // Check for specific permission
 * if (req.nextUrl.pathname.startsWith('/admin/users')) {
 *   if (!hasPermission('users:manage')) {
 *     return NextResponse.redirect(new URL('/unauthorized', req.url));
 *   }
 * }
 *
 * Common Permissions:
 * - users:read, users:write, users:delete
 * - projects:read, projects:write, projects:delete
 * - analytics:view
 * - settings:manage
 * - billing:manage
 *
 * Advanced: Combining Roles and Permissions:
 *
 * const canAccess = (route: string) => {
 *   // Admins can access everything
 *   if (userRole === 'admin') return true;
 *
 *   // Check specific permissions
 *   if (route.startsWith('/users')) {
 *     return hasPermission('users:manage');
 *   }
 *
 *   if (route.startsWith('/analytics')) {
 *     return hasRole(userRole, 'manager') || hasPermission('analytics:view');
 *   }
 *
 *   return false;
 * };
 */
