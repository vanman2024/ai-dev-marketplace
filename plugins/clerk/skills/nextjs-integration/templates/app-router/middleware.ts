import { authMiddleware } from "@clerk/nextjs";

/**
 * Clerk authentication middleware for Next.js App Router
 *
 * This middleware runs on the Edge Runtime and protects routes
 * before they reach your application.
 *
 * @see https://clerk.com/docs/references/nextjs/auth-middleware
 */
export default authMiddleware({
  /**
   * Public routes accessible without authentication
   * Use regex patterns for dynamic routes
   */
  publicRoutes: [
    "/",
    "/sign-in(.*)",
    "/sign-up(.*)",
    "/api/public(.*)",
  ],

  /**
   * Routes completely ignored by Clerk
   * No authentication checks or session creation
   */
  ignoredRoutes: [
    "/api/webhook(.*)",
    "/_next(.*)",
    "/favicon.ico",
  ],

  /**
   * Optional: Custom logic after authentication check
   * Uncomment and modify as needed
   */
  // afterAuth(auth, req) {
  //   // Redirect unauthenticated users
  //   if (!auth.userId && !auth.isPublicRoute) {
  //     const signInUrl = new URL('/sign-in', req.url);
  //     signInUrl.searchParams.set('redirect_url', req.url);
  //     return Response.redirect(signInUrl);
  //   }
  //
  //   // Redirect authenticated users from home to dashboard
  //   if (auth.userId && req.nextUrl.pathname === '/') {
  //     return Response.redirect(new URL('/dashboard', req.url));
  //   }
  // },
});

/**
 * Configure which routes this middleware should run on
 */
export const config = {
  matcher: [
    // Match all routes except static files and Next.js internals
    '/((?!.+\\.[\\w]+$|_next).*)',
    '/',
    '/(api|trpc)(.*)',
  ],
};
