---
name: session-management
description: Clerk session handling, JWT verification, token management, and multi-session workflows. Use when implementing session validation, JWT claims customization, token refresh patterns, session lifecycle management, or when user mentions session errors, authentication tokens, JWT verification, multi-device sessions, or session security.
allowed-tools: Read, Grep, Glob, Bash
---

# Session Management

**Purpose:** Autonomously configure, validate, and troubleshoot Clerk session handling, JWT verification, and token management.

**Activation Triggers:**
- Session validation failures
- JWT verification errors
- Token expiration issues
- Multi-session conflicts
- Custom claims configuration
- Session refresh problems
- Authentication middleware setup
- Session security audits

**Key Resources:**
- `scripts/configure-sessions.sh` - Session configuration helper
- `scripts/setup-jwt.sh` - JWT template setup and validation
- `scripts/test-sessions.sh` - Session testing and verification
- `templates/session-config.ts` - Session configuration patterns
- `templates/jwt-verification.ts` - JWT verification middleware
- `templates/custom-claims.ts` - Custom JWT claims setup
- `templates/session-types.ts` - TypeScript type definitions
- `examples/multi-session.tsx` - Multi-session management
- `examples/session-refresh.ts` - Session refresh patterns
- `examples/session-debugging.ts` - Debugging utilities

## Session Configuration Workflow

### 1. Configure Session Settings

```bash
# Interactive session configuration
./scripts/configure-sessions.sh

# Options configured:
# - Session lifetime (default, maximum)
# - Multi-session mode (single, multi-device)
# - Refresh token strategy
# - Session activity tracking
# - Secure cookie settings
```

**What it configures:**
- ✅ Session duration and expiration
- ✅ Multi-session behavior (allow/restrict)
- ✅ Token refresh intervals
- ✅ Activity-based session extension
- ✅ Cookie security attributes (SameSite, Secure, HttpOnly)

### 2. Setup JWT Templates

```bash
# Create/update JWT templates for custom claims
./scripts/setup-jwt.sh <template-name>

# Examples:
./scripts/setup-jwt.sh default      # Standard user claims
./scripts/setup-jwt.sh hasura       # Hasura integration claims
./scripts/setup-jwt.sh supabase     # Supabase integration claims
./scripts/setup-jwt.sh custom       # Custom business logic claims
```

**Configures:**
- Session ID and user ID claims
- Organization membership
- Role and permission claims
- Custom metadata fields
- Database integration claims (Hasura, Supabase)

### 3. Test Session Validation

```bash
# Test session validation and JWT verification
./scripts/test-sessions.sh <test-type>

# Test types:
# - basic           → Verify session creation and validation
# - jwt-verify      → Test JWT signature verification
# - custom-claims   → Validate custom claims presence
# - multi-session   → Test multi-device session handling
# - refresh         → Test token refresh flow
# - expiration      → Test session expiration handling
```

## Session Management Patterns

### Backend Session Verification

**Next.js App Router:**
```typescript
// Use auth() for session access
import { auth } from '@clerk/nextjs/server';

export async function GET() {
  const { userId, sessionId, sessionClaims } = await auth();

  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Access custom claims
  const userRole = sessionClaims?.role;
  const orgId = sessionClaims?.org_id;

  return Response.json({ userId, role: userRole });
}
```

**Middleware Pattern:**
```typescript
// See templates/jwt-verification.ts for complete implementation
import { clerkMiddleware, createRouteMatcher } from '@clerk/nextjs/server';

const isProtectedRoute = createRouteMatcher(['/dashboard(.*)']);

export default clerkMiddleware((auth, req) => {
  if (isProtectedRoute(req)) {
    auth().protect();
  }
});
```

### Frontend Session Access

**React/Next.js:**
```typescript
import { useAuth, useSession } from '@clerk/nextjs';

function Component() {
  const { userId, sessionId } = useAuth();
  const { session } = useSession();

  // Session properties
  const lastActiveAt = session?.lastActiveAt;
  const expireAt = session?.expireAt;

  // Session management
  const handleRefresh = () => session?.touch(); // Extend session

  return (
    <div>
      <p>Session ID: {sessionId}</p>
      <p>Expires: {expireAt?.toLocaleString()}</p>
    </div>
  );
}
```

### Multi-Session Handling

**Enable multi-session mode:**
```typescript
// See examples/multi-session.tsx for complete implementation
import { useClerk } from '@clerk/nextjs';

function SessionSwitcher() {
  const { client } = useClerk();
  const sessions = client?.sessions || [];

  // Switch between sessions
  const switchSession = async (sessionId: string) => {
    await client?.setActiveSession(sessionId);
  };

  // Sign out of specific session
  const signOutSession = async (sessionId: string) => {
    const session = client?.sessions.find(s => s.id === sessionId);
    await session?.remove();
  };

  return (/* session switcher UI */);
}
```

### JWT Verification (Backend)

**Manual verification:**
```typescript
// See templates/jwt-verification.ts
import { verifyToken } from '@clerk/backend';

async function verifySessionToken(token: string) {
  try {
    const payload = await verifyToken(token, {
      secretKey: process.env.CLERK_SECRET_KEY!,
      // Optional: custom verification options
      authorizedParties: ['https://app.example.com'],
    });

    return {
      valid: true,
      userId: payload.sub,
      sessionId: payload.sid,
      claims: payload,
    };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}
```

### Custom Claims Configuration

**Dashboard setup:**
1. Navigate to Clerk Dashboard → JWT Templates
2. Create/edit template
3. Add custom claims in JSON format:

```json
{
  "metadata": "{{user.public_metadata}}",
  "role": "{{user.public_metadata.role}}",
  "org_id": "{{org.id}}",
  "org_role": "{{org_membership.role}}",
  "permissions": "{{org_membership.permissions}}"
}
```

**Access in code:**
```typescript
// See templates/custom-claims.ts
import { auth } from '@clerk/nextjs/server';

const { sessionClaims } = await auth();

const role = sessionClaims?.role as string;
const orgId = sessionClaims?.org_id as string;
const permissions = sessionClaims?.permissions as string[];
```

## Session Refresh Patterns

### Automatic Refresh

**Client-side auto-refresh:**
```typescript
// See examples/session-refresh.ts
import { useSession } from '@clerk/nextjs';
import { useEffect } from 'react';

function useSessionRefresh() {
  const { session } = useSession();

  useEffect(() => {
    if (!session) return;

    // Refresh session before expiration
    const expiresAt = session.expireAt?.getTime() || 0;
    const refreshAt = expiresAt - (5 * 60 * 1000); // 5 min before expiry
    const now = Date.now();

    if (refreshAt > now) {
      const timeout = setTimeout(() => {
        session.touch(); // Extends session
      }, refreshAt - now);

      return () => clearTimeout(timeout);
    }
  }, [session]);
}
```

### Manual Session Extension

```typescript
import { useSession } from '@clerk/nextjs';

function Component() {
  const { session } = useSession();

  const extendSession = async () => {
    // Touch session to extend lifetime
    await session?.touch();
  };

  return <button onClick={extendSession}>Stay Logged In</button>;
}
```

## Security Best Practices

### Session Configuration

**Recommended settings:**
- Session lifetime: 7 days (default), 30 days (maximum)
- Refresh window: Last 10% of session lifetime
- Multi-session: Enabled for consumer apps, restricted for enterprise
- Secure cookies: Always enable in production
- SameSite: 'lax' (most apps), 'strict' (high security)

### JWT Security

**Verification checklist:**
- ✅ Always verify JWT signature
- ✅ Validate expiration (`exp` claim)
- ✅ Check issuer (`iss` claim matches Clerk)
- ✅ Verify audience (`aud` if using multiple apps)
- ✅ Validate authorized parties for multi-domain
- ✅ Never trust client-provided tokens without verification

### Session Storage

**Frontend:**
- Clerk automatically manages session tokens
- Never store session tokens in localStorage
- Cookies are HttpOnly and Secure in production

**Backend:**
- Validate session on every protected request
- Cache validation results with short TTL (< 1 min)
- Invalidate cache on user metadata changes

## Common Issues & Fixes

### Session Not Persisting

**Problem:** User logged out on page refresh

**Solutions:**
```bash
# Check cookie configuration
./scripts/test-sessions.sh basic

# Verify:
# - Domain settings match deployment URL
# - SameSite attribute compatible with architecture
# - Secure flag enabled in production only
```

### JWT Verification Failure

**Problem:** `verifyToken` throws error

**Diagnosis:**
```bash
./scripts/test-sessions.sh jwt-verify

# Common causes:
# - Wrong CLERK_SECRET_KEY (check .env)
# - Token expired (check exp claim)
# - Issuer mismatch (check iss claim)
# - Invalid signature (token tampered)
```

### Custom Claims Not Available

**Problem:** Custom claims undefined in sessionClaims

**Fix:**
```bash
# Verify JWT template configuration
./scripts/setup-jwt.sh custom

# Steps:
# 1. Ensure template is set as default in Dashboard
# 2. User must sign out and sign in again
# 3. Check claim paths match metadata structure
```

### Multi-Session Conflicts

**Problem:** Wrong session active after sign-in

**Solutions:**
```typescript
// See examples/multi-session.tsx

// Force specific session active
await clerk.setActiveSession(sessionId);

// Or restrict to single session in Dashboard:
// Settings → Sessions → Multi-session handling → Single session
```

## Resources

**Scripts:** All scripts in `scripts/` directory handle:
- Session configuration validation
- JWT template setup and testing
- Session flow verification
- Error diagnosis and fixes

**Templates:** `templates/` contains production-ready code for:
- Session configuration objects
- JWT verification middleware
- Custom claims type definitions
- Session refresh utilities

**Examples:** `examples/` demonstrates:
- Multi-session UI components
- Session refresh strategies
- Protected route patterns
- Session debugging helpers

## Security Compliance

**CRITICAL:** This skill follows strict security rules:
- All code examples use placeholder API keys only
- No real secrets or credentials in templates
- Environment variable references throughout
- `.gitignore` protection documented in all setup scripts

---

**Supported Frameworks:** Next.js (App Router, Pages Router), React, Express, Fastify, Remix
**Clerk SDK Version:** @clerk/nextjs 5+, @clerk/backend 1+
**Version:** 1.0.0
