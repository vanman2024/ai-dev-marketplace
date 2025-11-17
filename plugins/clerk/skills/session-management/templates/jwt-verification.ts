// jwt-verification.ts
// JWT token verification middleware and utilities

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { verifyToken } from '@clerk/backend';
import type { NextRequest } from 'next/server';

/**
 * JWT Verification Result
 */
export interface JWTVerificationResult {
  valid: boolean;
  userId?: string;
  sessionId?: string;
  claims?: Record<string, unknown>;
  error?: string;
}

/**
 * Protected route matcher
 * Define routes that require authentication
 */
const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/api/protected(.*)',
  '/admin(.*)',
  '/settings(.*)',
]);

/**
 * Public API routes that don't require auth
 */
const isPublicApiRoute = createRouteMatcher([
  '/api/public(.*)',
  '/api/webhooks(.*)',
  '/api/health',
]);

/**
 * Clerk Middleware Configuration
 * Protects routes and provides session context
 */
export default clerkMiddleware((auth, req) => {
  // Skip public routes
  if (isPublicApiRoute(req)) {
    return;
  }

  // Protect authenticated routes
  if (isProtectedRoute(req)) {
    auth().protect();
  }
});

export const config = {
  matcher: [
    // Skip Next.js internals and static files
    '/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)',
    // Always run for API routes
    '/(api|trpc)(.*)',
  ],
};

/**
 * Manual JWT Verification
 * For custom authentication flows or API routes
 */
export async function verifySessionToken(
  token: string
): Promise<JWTVerificationResult> {
  try {
    const secretKey = process.env.CLERK_SECRET_KEY;

    if (!secretKey) {
      return {
        valid: false,
        error: 'CLERK_SECRET_KEY not configured',
      };
    }

    const payload = await verifyToken(token, {
      secretKey,
      // Optional: validate authorized parties (for multi-domain apps)
      // authorizedParties: ['https://app.example.com'],
    });

    return {
      valid: true,
      userId: payload.sub,
      sessionId: payload.sid,
      claims: payload,
    };
  } catch (error) {
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Verification failed',
    };
  }
}

/**
 * Extract JWT from request headers
 */
export function extractToken(req: NextRequest): string | null {
  // Check Authorization header
  const authHeader = req.headers.get('authorization');
  if (authHeader?.startsWith('Bearer ')) {
    return authHeader.substring(7);
  }

  // Check __session cookie (Clerk's default)
  const sessionCookie = req.cookies.get('__session')?.value;
  if (sessionCookie) {
    return sessionCookie;
  }

  return null;
}

/**
 * Middleware for API routes requiring authentication
 *
 * Usage in API route:
 * ```typescript
 * import { withAuth } from '@/lib/jwt-verification';
 *
 * export const GET = withAuth(async (req, { userId, claims }) => {
 *   // Your authenticated logic here
 *   return Response.json({ userId });
 * });
 * ```
 */
export function withAuth(
  handler: (
    req: Request,
    context: { userId: string; sessionId: string; claims: Record<string, unknown> }
  ) => Promise<Response>
) {
  return async (req: Request) => {
    const token = extractToken(req as NextRequest);

    if (!token) {
      return Response.json(
        { error: 'No authentication token provided' },
        { status: 401 }
      );
    }

    const result = await verifySessionToken(token);

    if (!result.valid) {
      return Response.json(
        { error: result.error || 'Invalid token' },
        { status: 401 }
      );
    }

    return handler(req, {
      userId: result.userId!,
      sessionId: result.sessionId!,
      claims: result.claims!,
    });
  };
}

/**
 * Role-based authorization middleware
 *
 * Usage:
 * ```typescript
 * export const GET = withRole('admin', async (req, context) => {
 *   // Admin-only logic
 * });
 * ```
 */
export function withRole(
  requiredRole: string | string[],
  handler: (
    req: Request,
    context: { userId: string; sessionId: string; claims: Record<string, unknown> }
  ) => Promise<Response>
) {
  return withAuth(async (req, context) => {
    const userRole = context.claims.role as string | undefined;

    const allowedRoles = Array.isArray(requiredRole)
      ? requiredRole
      : [requiredRole];

    if (!userRole || !allowedRoles.includes(userRole)) {
      return Response.json(
        { error: 'Insufficient permissions' },
        { status: 403 }
      );
    }

    return handler(req, context);
  });
}

/**
 * Organization-based authorization
 *
 * Usage:
 * ```typescript
 * export const GET = withOrganization(async (req, context) => {
 *   const orgId = context.claims.org_id;
 *   // Organization-specific logic
 * });
 * ```
 */
export function withOrganization(
  handler: (
    req: Request,
    context: {
      userId: string;
      sessionId: string;
      claims: Record<string, unknown>;
      orgId: string;
    }
  ) => Promise<Response>
) {
  return withAuth(async (req, context) => {
    const orgId = context.claims.org_id as string | undefined;

    if (!orgId) {
      return Response.json(
        { error: 'No organization context' },
        { status: 403 }
      );
    }

    return handler(req, { ...context, orgId });
  });
}

/**
 * Validate specific claims presence
 */
export function validateClaims(
  claims: Record<string, unknown>,
  requiredClaims: string[]
): { valid: boolean; missing: string[] } {
  const missing = requiredClaims.filter(
    (claim) => claims[claim] === undefined || claims[claim] === null
  );

  return {
    valid: missing.length === 0,
    missing,
  };
}

/**
 * Check if token is expired
 */
export function isTokenExpired(claims: Record<string, unknown>): boolean {
  const exp = claims.exp as number | undefined;
  if (!exp) return true;

  return Date.now() >= exp * 1000;
}

/**
 * Get time until token expiration
 */
export function getTokenExpiration(
  claims: Record<string, unknown>
): number | null {
  const exp = claims.exp as number | undefined;
  if (!exp) return null;

  const expiresAt = exp * 1000;
  return Math.max(0, expiresAt - Date.now());
}

/**
 * Security Best Practices:
 *
 * 1. Always verify JWT signature (never trust client tokens)
 * 2. Validate expiration time (exp claim)
 * 3. Check issuer matches your Clerk instance (iss claim)
 * 4. Validate audience if using multiple apps (aud claim)
 * 5. Use HTTPS in production (secure cookies)
 * 6. Set appropriate session lifetimes
 * 7. Implement refresh token rotation
 * 8. Log authentication failures for monitoring
 * 9. Rate limit authentication endpoints
 * 10. Never log or expose JWT tokens
 */

/**
 * Example Usage in API Route:
 *
 * ```typescript
 * // Simple authentication
 * export const GET = withAuth(async (req, { userId }) => {
 *   const data = await db.query({ userId });
 *   return Response.json(data);
 * });
 *
 * // Role-based access
 * export const DELETE = withRole('admin', async (req, { userId }) => {
 *   await db.delete({ userId });
 *   return Response.json({ success: true });
 * });
 *
 * // Organization context
 * export const POST = withOrganization(async (req, { userId, orgId }) => {
 *   const body = await req.json();
 *   await db.insert({ ...body, orgId, createdBy: userId });
 *   return Response.json({ success: true });
 * });
 *
 * // Manual verification
 * export async function GET(req: Request) {
 *   const token = extractToken(req as NextRequest);
 *   const result = await verifySessionToken(token || '');
 *
 *   if (!result.valid) {
 *     return Response.json({ error: result.error }, { status: 401 });
 *   }
 *
 *   // Custom logic with verified claims
 *   const customClaim = result.claims?.customField;
 *   return Response.json({ customClaim });
 * }
 * ```
 */
