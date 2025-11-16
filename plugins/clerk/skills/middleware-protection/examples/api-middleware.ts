/**
 * API Middleware Example
 *
 * Demonstrates protecting API routes with Clerk middleware.
 * Shows session validation, error handling, and proper response formats.
 */

import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';
import { NextResponse } from 'next/server';

// Define public API routes (webhooks, health checks, etc.)
const isPublicApiRoute = createRouteMatcher([
  '/api/webhooks/clerk',
  '/api/webhooks/stripe',
  '/api/health',
  '/api/status',
  '/api/public/(.*)',
]);

export default clerkMiddleware((auth, req) => {
  // Only handle API routes
  if (!req.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  // Allow public API routes
  if (isPublicApiRoute(req)) {
    return NextResponse.next();
  }

  // Get authentication state
  const { userId, sessionClaims } = auth();

  // Require authentication for protected API routes
  if (!userId) {
    return NextResponse.json(
      {
        error: 'Unauthorized',
        message: 'Authentication required',
      },
      { status: 401 }
    );
  }

  // Optional: Check rate limiting based on user
  const requestCount = parseInt(
    req.headers.get('x-ratelimit-count') || '0'
  );

  if (requestCount > 100) {
    return NextResponse.json(
      {
        error: 'Rate Limit Exceeded',
        message: 'Too many requests. Please try again later.',
        retryAfter: 3600, // 1 hour
      },
      {
        status: 429,
        headers: {
          'Retry-After': '3600',
          'X-RateLimit-Limit': '100',
          'X-RateLimit-Remaining': '0',
        },
      }
    );
  }

  // Optional: Check API key for programmatic access
  const apiKey = req.headers.get('x-api-key');

  if (apiKey) {
    // Validate API key (stored in user metadata)
    const userApiKey = sessionClaims?.metadata?.apiKey as string | undefined;

    if (apiKey !== userApiKey) {
      return NextResponse.json(
        {
          error: 'Invalid API Key',
          message: 'The provided API key is invalid',
        },
        { status: 403 }
      );
    }
  }

  // Add user context to request headers for API routes
  const response = NextResponse.next();
  response.headers.set('x-user-id', userId);

  if (sessionClaims?.metadata?.role) {
    response.headers.set(
      'x-user-role',
      sessionClaims.metadata.role as string
    );
  }

  return response;
});

export const config = {
  matcher: ['/api/(.*)'],
};

/**
 * Usage in API Routes:
 *
 * // app/api/users/route.ts
 * import { auth } from '@clerk/nextjs/server';
 * import { NextResponse } from 'next/server';
 *
 * export async function GET(req: Request) {
 *   // Middleware has already verified authentication
 *   // Access user ID from headers or auth()
 *   const { userId } = auth();
 *
 *   if (!userId) {
 *     return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
 *   }
 *
 *   // Fetch user data
 *   const users = await db.users.findMany();
 *
 *   return NextResponse.json({ users });
 * }
 *
 * // app/api/admin/users/route.ts
 * export async function DELETE(req: Request) {
 *   const { userId, sessionClaims } = auth();
 *   const role = sessionClaims?.metadata?.role;
 *
 *   // Check admin role
 *   if (role !== 'admin') {
 *     return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
 *   }
 *
 *   // Admin-only logic
 *   const { searchParams } = new URL(req.url);
 *   const targetUserId = searchParams.get('userId');
 *
 *   await db.users.delete({ where: { id: targetUserId } });
 *
 *   return NextResponse.json({ success: true });
 * }
 */
