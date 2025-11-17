#!/bin/bash

# configure-middleware.sh
# Configures authentication middleware with custom route matching

set -e

echo "=========================================="
echo "Clerk Middleware Configuration"
echo "=========================================="

# Check if @clerk/nextjs is installed
if ! grep -q "@clerk/nextjs" package.json; then
  echo "Error: @clerk/nextjs not found in package.json"
  echo "Run: bash ./skills/nextjs-integration/scripts/install-clerk.sh first"
  exit 1
fi

# Check if middleware.ts already exists
if [ -f "middleware.ts" ]; then
  echo "middleware.ts already exists. Creating backup..."
  cp middleware.ts middleware.ts.backup
  echo "✓ Backup created at middleware.ts.backup"
fi

# Interactive configuration
echo ""
echo "Configure route protection patterns:"
echo ""

# Ask for public routes
echo "Enter public routes (comma-separated, e.g., /, /about, /api/public):"
echo "Default: /, /sign-in(.*), /sign-up(.*):"
read -r PUBLIC_ROUTES
if [ -z "$PUBLIC_ROUTES" ]; then
  PUBLIC_ROUTES='"/", "/sign-in(.*)", "/sign-up(.*))"'
else
  # Convert comma-separated list to JSON array format
  PUBLIC_ROUTES=$(echo "$PUBLIC_ROUTES" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
fi

# Ask for ignored routes
echo ""
echo "Enter ignored routes (comma-separated, e.g., /api/webhook, /_next):"
echo "Default: /api/webhook(.*), /_next(.*), /favicon.ico:"
read -r IGNORED_ROUTES
if [ -z "$IGNORED_ROUTES" ]; then
  IGNORED_ROUTES='"/api/webhook(.*)", "/_next(.*)", "/favicon.ico"'
else
  IGNORED_ROUTES=$(echo "$IGNORED_ROUTES" | sed 's/,/", "/g' | sed 's/^/"/' | sed 's/$/"/')
fi

# Create comprehensive middleware.ts
echo ""
echo "Creating middleware.ts with custom configuration..."

cat > middleware.ts << EOF
import { authMiddleware } from "@clerk/nextjs";

/**
 * Clerk authentication middleware
 *
 * This middleware runs on the Edge Runtime and protects routes
 * before they reach your Next.js application.
 *
 * Documentation: https://clerk.com/docs/references/nextjs/auth-middleware
 */
export default authMiddleware({
  /**
   * Public routes that can be accessed without authentication
   * Use regex patterns for dynamic routes: "/blog(.*)" matches /blog, /blog/post-1, etc.
   */
  publicRoutes: [
    $PUBLIC_ROUTES
  ],

  /**
   * Ignored routes that are completely bypassed by Clerk
   * No authentication checks or redirects will occur on these routes
   */
  ignoredRoutes: [
    $IGNORED_ROUTES
  ],

  /**
   * Optional: Custom redirect URLs
   * Uncomment to override default behavior
   */
  // afterAuth(auth, req) {
  //   // Handle users who aren't authenticated
  //   if (!auth.userId && !auth.isPublicRoute) {
  //     const signInUrl = new URL('/sign-in', req.url);
  //     signInUrl.searchParams.set('redirect_url', req.url);
  //     return Response.redirect(signInUrl);
  //   }
  //
  //   // Handle authenticated users
  //   if (auth.userId && req.nextUrl.pathname === '/') {
  //     const dashboardUrl = new URL('/dashboard', req.url);
  //     return Response.redirect(dashboardUrl);
  //   }
  // },
});

/**
 * Matcher configuration for Edge Runtime
 *
 * Specifies which routes this middleware should run on.
 * Default: All routes except static files and Next.js internals
 */
export const config = {
  matcher: [
    // Match all routes except static files and Next.js internals
    '/((?!.+\\.[\\w]+$|_next).*)',
    // Include root
    '/',
    // Include API routes and tRPC
    '/(api|trpc)(.*)',
  ],
};
EOF

echo "✓ middleware.ts created with custom configuration"

# Create helper documentation
echo ""
echo "Creating middleware documentation..."

cat > MIDDLEWARE_GUIDE.md << 'EOF'
# Clerk Middleware Configuration Guide

## Overview

The `middleware.ts` file runs on the Edge Runtime and protects your Next.js routes before they reach your application code.

## Configuration Options

### Public Routes

Routes accessible without authentication:

```typescript
publicRoutes: [
  "/",                    // Homepage
  "/sign-in(.*)",         // Sign-in page and sub-routes
  "/sign-up(.*)",         // Sign-up page and sub-routes
  "/api/public(.*)",      // Public API routes
  "/blog(.*)",            // Public blog routes
]
```

### Ignored Routes

Routes completely bypassed by Clerk (no auth checks):

```typescript
ignoredRoutes: [
  "/api/webhook(.*)",     // Webhook endpoints
  "/_next(.*)",           // Next.js internals
  "/favicon.ico",         // Static assets
]
```

## Route Patterns

### Exact Match
```typescript
"/about"  // Matches only /about
```

### Regex Pattern
```typescript
"/blog(.*)"  // Matches /blog, /blog/post-1, /blog/category/tech
```

### API Routes
```typescript
"/api/public(.*)"  // Matches /api/public, /api/public/users
```

## Custom Redirect Logic

Use `afterAuth` callback for custom behavior:

```typescript
export default authMiddleware({
  afterAuth(auth, req) {
    // Redirect unauthenticated users to sign-in
    if (!auth.userId && !auth.isPublicRoute) {
      const signInUrl = new URL('/sign-in', req.url);
      signInUrl.searchParams.set('redirect_url', req.url);
      return Response.redirect(signInUrl);
    }

    // Redirect authenticated users from root to dashboard
    if (auth.userId && req.nextUrl.pathname === '/') {
      return Response.redirect(new URL('/dashboard', req.url));
    }
  },
});
```

## Testing Middleware

1. **Public Routes**: Should be accessible without sign-in
2. **Protected Routes**: Should redirect to sign-in page
3. **Ignored Routes**: Should work without any auth checks
4. **API Routes**: Test both public and protected endpoints

## Debugging

Enable debug mode in Clerk dashboard:
1. Go to Dashboard → Settings → Advanced
2. Enable "Debug mode"
3. Check browser console for auth events

## Common Issues

**Middleware not running:**
- Check matcher configuration
- Ensure middleware.ts is at project root
- Verify Edge Runtime compatibility

**Redirect loop:**
- Ensure sign-in/sign-up pages are in publicRoutes
- Check afterAuth logic for circular redirects

**API routes not protected:**
- Verify matcher includes API routes: `/(api|trpc)(.*)`
- Check if route is in ignoredRoutes

## Performance

- Middleware runs on Edge Runtime (faster than server)
- Minimal cold start times
- Caches auth state for subsequent requests

EOF

echo "✓ MIDDLEWARE_GUIDE.md created"

echo ""
echo "=========================================="
echo "✓ Middleware configuration complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - middleware.ts (custom route protection)"
echo "  - MIDDLEWARE_GUIDE.md (documentation)"
echo ""
echo "Public routes: $PUBLIC_ROUTES"
echo "Ignored routes: $IGNORED_ROUTES"
echo ""
echo "Next steps:"
echo "1. Review middleware.ts configuration"
echo "2. Test public routes without sign-in"
echo "3. Test protected routes redirect to sign-in"
echo "4. Customize afterAuth callback if needed"
echo ""
echo "Documentation: See MIDDLEWARE_GUIDE.md"
echo ""
