#!/bin/bash

# configure-sessions.sh
# Interactive Clerk session configuration helper

set -e

echo "=== Clerk Session Configuration ==="
echo ""

# Check if in a Next.js project
if [ ! -f "package.json" ]; then
    echo "Error: package.json not found. Run this from your project root."
    exit 1
fi

# Check for Clerk installation
if ! grep -q '"@clerk/nextjs"' package.json && ! grep -q '"@clerk/clerk-react"' package.json; then
    echo "Warning: Clerk package not found in package.json"
    echo "Install with: npm install @clerk/nextjs"
    echo ""
fi

# Function to prompt for configuration
prompt_config() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    echo -n "$prompt [$default]: "
    read -r input
    eval "$var_name=\"${input:-$default}\""
}

echo "Session Lifetime Configuration"
echo "------------------------------"
prompt_config "Default session lifetime (days)" "7" SESSION_LIFETIME_DAYS
prompt_config "Maximum session lifetime (days)" "30" MAX_SESSION_LIFETIME_DAYS
prompt_config "Inactivity timeout (hours, 0 for none)" "0" INACTIVITY_TIMEOUT_HOURS

echo ""
echo "Multi-Session Configuration"
echo "---------------------------"
echo "1) Single session only (sign out other devices)"
echo "2) Multi-session enabled (multiple devices)"
prompt_config "Select mode" "2" MULTI_SESSION_MODE

echo ""
echo "Token Refresh Configuration"
echo "--------------------------"
prompt_config "Enable automatic refresh?" "yes" AUTO_REFRESH
if [ "$AUTO_REFRESH" = "yes" ]; then
    prompt_config "Refresh in last X% of session" "10" REFRESH_THRESHOLD_PERCENT
fi

echo ""
echo "Security Settings"
echo "----------------"
prompt_config "Environment (development/production)" "development" ENVIRONMENT
prompt_config "Enable secure cookies (HTTPS only)?" "yes" SECURE_COOKIES
prompt_config "SameSite attribute (strict/lax/none)" "lax" SAMESITE

echo ""
echo "=== Configuration Summary ==="
echo "Session Lifetime: $SESSION_LIFETIME_DAYS days (max: $MAX_SESSION_LIFETIME_DAYS days)"
[ "$INACTIVITY_TIMEOUT_HOURS" != "0" ] && echo "Inactivity Timeout: $INACTIVITY_TIMEOUT_HOURS hours"
[ "$MULTI_SESSION_MODE" = "1" ] && echo "Multi-Session: Disabled (single session only)"
[ "$MULTI_SESSION_MODE" = "2" ] && echo "Multi-Session: Enabled"
echo "Auto-Refresh: $AUTO_REFRESH"
[ "$AUTO_REFRESH" = "yes" ] && echo "Refresh Threshold: Last $REFRESH_THRESHOLD_PERCENT% of session"
echo "Environment: $ENVIRONMENT"
echo "Secure Cookies: $SECURE_COOKIES"
echo "SameSite: $SAMESITE"
echo ""

# Generate middleware configuration
MIDDLEWARE_FILE="middleware.ts"
if [ -f "$MIDDLEWARE_FILE" ]; then
    echo "Found existing $MIDDLEWARE_FILE"
    echo -n "Update with new session configuration? (yes/no) [yes]: "
    read -r update_middleware
    update_middleware="${update_middleware:-yes}"
else
    update_middleware="yes"
fi

if [ "$update_middleware" = "yes" ]; then
    cat > "$MIDDLEWARE_FILE" <<EOF
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

// Define protected routes that require authentication
const isProtectedRoute = createRouteMatcher([
  '/dashboard(.*)',
  '/api/protected(.*)',
]);

export default clerkMiddleware((auth, req) => {
  // Protect routes that require authentication
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
EOF
    echo "✓ Created/updated $MIDDLEWARE_FILE"
fi

# Generate session configuration notes
CONFIG_FILE=".clerk/session-config.md"
mkdir -p .clerk
cat > "$CONFIG_FILE" <<EOF
# Clerk Session Configuration

Generated: $(date)

## Dashboard Settings Required

Configure these settings in Clerk Dashboard → Settings → Sessions:

### Session Lifetime
- **Session lifetime**: $SESSION_LIFETIME_DAYS days
- **Maximum lifetime**: $MAX_SESSION_LIFETIME_DAYS days
$([ "$INACTIVITY_TIMEOUT_HOURS" != "0" ] && echo "- **Inactivity timeout**: $INACTIVITY_TIMEOUT_HOURS hours")

### Multi-Session Handling
$([ "$MULTI_SESSION_MODE" = "1" ] && echo "- **Multi-session mode**: Disabled (single active session)")
$([ "$MULTI_SESSION_MODE" = "2" ] && echo "- **Multi-session mode**: Enabled (allow multiple devices)")

### Security
- **Secure cookies**: $([ "$SECURE_COOKIES" = "yes" ] && echo "Enabled" || echo "Disabled")
- **SameSite attribute**: $SAMESITE

## Environment Variables

Ensure these are set in your .env.local:

\`\`\`bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
CLERK_SECRET_KEY=sk_test_your_secret_key_here

# Optional: Custom domain configuration
$([ "$ENVIRONMENT" = "production" ] && echo "NEXT_PUBLIC_CLERK_DOMAIN=yourdomain.com")
\`\`\`

## Client-Side Configuration

If using auto-refresh, add to your root layout or app component:

\`\`\`typescript
import { useSession } from '@clerk/nextjs';
import { useEffect } from 'react';

function useSessionRefresh() {
  const { session } = useSession();

  useEffect(() => {
    if (!session) return;

    const expiresAt = session.expireAt?.getTime() || 0;
    const refreshThreshold = $REFRESH_THRESHOLD_PERCENT / 100;
    const sessionDuration = expiresAt - (session.createdAt?.getTime() || 0);
    const refreshAt = expiresAt - (sessionDuration * refreshThreshold);
    const now = Date.now();

    if (refreshAt > now) {
      const timeout = setTimeout(() => {
        session.touch(); // Extend session
      }, refreshAt - now);

      return () => clearTimeout(timeout);
    }
  }, [session]);
}
\`\`\`

## Testing Checklist

- [ ] Session persists across page refreshes
- [ ] Session expires after configured lifetime
$([ "$INACTIVITY_TIMEOUT_HOURS" != "0" ] && echo "- [ ] Session expires after $INACTIVITY_TIMEOUT_HOURS hours of inactivity")
$([ "$MULTI_SESSION_MODE" = "2" ] && echo "- [ ] Multiple sessions can be active simultaneously")
$([ "$MULTI_SESSION_MODE" = "1" ] && echo "- [ ] Signing in on new device signs out other sessions")
- [ ] Protected routes redirect to sign-in when unauthenticated
$([ "$AUTO_REFRESH" = "yes" ] && echo "- [ ] Session automatically refreshes before expiration")

## Next Steps

1. Apply settings in Clerk Dashboard (Settings → Sessions)
2. Test session behavior in development
3. Verify secure cookies work in production environment
4. Monitor session metrics in Dashboard → Analytics

EOF

echo "✓ Created session configuration guide: $CONFIG_FILE"
echo ""
echo "Next Steps:"
echo "1. Review configuration in .clerk/session-config.md"
echo "2. Apply settings in Clerk Dashboard → Settings → Sessions"
echo "3. Test with: ./scripts/test-sessions.sh basic"
echo ""
