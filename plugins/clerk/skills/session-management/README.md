# Clerk Session Management Skill

Comprehensive session handling, JWT verification, and token management for Clerk authentication.

## Overview

This skill provides complete session management capabilities for Clerk-powered applications, including:

- Session configuration and lifecycle management
- JWT template setup and custom claims
- Token verification and validation
- Multi-session handling
- Session refresh patterns
- Security best practices

## Structure

```
session-management/
├── SKILL.md                       # Main skill documentation
├── README.md                      # This file
├── scripts/
│   ├── configure-sessions.sh      # Interactive session configuration
│   ├── setup-jwt.sh               # JWT template setup and generation
│   └── test-sessions.sh           # Session validation and testing
├── templates/
│   ├── session-config.ts          # Session configuration patterns
│   ├── jwt-verification.ts        # JWT verification middleware
│   └── custom-claims.ts           # Custom JWT claims types and helpers
└── examples/
    ├── multi-session.tsx          # Multi-session management UI
    └── session-refresh.ts         # Session refresh hooks and components
```

## Quick Start

### 1. Configure Session Settings

```bash
# Run interactive session configuration
./scripts/configure-sessions.sh

# Follow prompts to set:
# - Session lifetime (default, maximum)
# - Multi-session mode
# - Auto-refresh settings
# - Security attributes
```

This creates:
- `middleware.ts` - Clerk middleware configuration
- `.clerk/session-config.md` - Setup instructions and checklist

### 2. Setup JWT Templates

```bash
# Create JWT template for custom claims
./scripts/setup-jwt.sh custom

# Available templates:
# - default: Standard user claims
# - hasura: Hasura GraphQL integration
# - supabase: Supabase integration
# - custom: Business logic claims
```

This creates:
- `.clerk/jwt-templates/<template>.json` - JWT template configuration
- `.clerk/jwt-templates/<template>.types.ts` - TypeScript types
- `.clerk/jwt-templates/<template>-setup.md` - Setup instructions

### 3. Test Session Validation

```bash
# Test basic session setup
./scripts/test-sessions.sh basic

# Test JWT verification
./scripts/test-sessions.sh jwt-verify

# Test custom claims
./scripts/test-sessions.sh custom-claims

# Test multi-session handling
./scripts/test-sessions.sh multi-session

# Test session refresh
./scripts/test-sessions.sh refresh

# Run all tests
./scripts/test-sessions.sh all
```

## Usage Patterns

### Session Verification (API Routes)

```typescript
import { auth } from '@clerk/nextjs/server';

export async function GET() {
  const { userId, sessionId, sessionClaims } = await auth();

  if (!userId) {
    return Response.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Access custom claims
  const role = sessionClaims?.role;
  const orgId = sessionClaims?.org_id;

  return Response.json({ userId, role, orgId });
}
```

### JWT Verification Middleware

```typescript
import { withAuth, withRole } from '@/templates/jwt-verification';

// Simple authentication
export const GET = withAuth(async (req, { userId }) => {
  return Response.json({ userId });
});

// Role-based access
export const DELETE = withRole('admin', async (req, { userId }) => {
  return Response.json({ success: true });
});
```

### Multi-Session Management

```typescript
import { MultiSessionManager } from '@/examples/multi-session';

export default function SessionsPage() {
  return <MultiSessionManager />;
}
```

### Session Auto-Refresh

```typescript
import { useSessionRefresh } from '@/examples/session-refresh';

export default function RootLayout({ children }) {
  useSessionRefresh({ thresholdPercent: 10 });
  return <html>{children}</html>;
}
```

## Scripts Reference

### configure-sessions.sh

Interactive session configuration tool that:
- Prompts for session settings (lifetime, multi-session, refresh)
- Generates middleware configuration
- Creates setup documentation
- Provides testing checklist

**Usage:**
```bash
./scripts/configure-sessions.sh
```

### setup-jwt.sh

JWT template generator that:
- Creates JSON templates for custom claims
- Generates TypeScript type definitions
- Provides Dashboard configuration instructions
- Includes usage examples

**Usage:**
```bash
./scripts/setup-jwt.sh <template-name>
```

**Templates:**
- `default` - Standard user claims
- `hasura` - Hasura GraphQL integration
- `supabase` - Supabase integration
- `custom` - Custom business logic

### test-sessions.sh

Session validation suite that:
- Validates environment configuration
- Tests JWT verification endpoints
- Verifies custom claims presence
- Tests multi-session functionality
- Validates refresh patterns

**Usage:**
```bash
./scripts/test-sessions.sh <test-type>
```

**Test Types:**
- `basic` - Environment and configuration
- `jwt-verify` - JWT verification
- `custom-claims` - Custom claims validation
- `multi-session` - Multi-session handling
- `refresh` - Session refresh patterns
- `expiration` - Expiration testing
- `all` - Run all tests

## Templates Reference

### session-config.ts

Session configuration types and helpers:
- Environment-based configurations (dev, prod, high-security)
- SessionConfigHelper class for refresh calculations
- Time formatting utilities
- Expiration checking

### jwt-verification.ts

JWT verification middleware:
- Manual token verification
- Protected route matchers
- `withAuth` HOF for API routes
- `withRole` for role-based access
- `withOrganization` for org context
- Token extraction utilities

### custom-claims.ts

Custom JWT claims types and helpers:
- Base Clerk claims interface
- Custom business logic claims
- Hasura/Supabase integration claims
- Type guards and helpers
- JWT template configurations

## Examples Reference

### multi-session.tsx

Multi-session management components:
- `MultiSessionManager` - Full session list with controls
- `SessionCard` - Individual session display
- `SessionInfo` - Lightweight session display
- Session switching and revocation

### session-refresh.ts

Session refresh patterns:
- `useSessionRefresh` - Auto-refresh hook
- `useManualSessionRefresh` - Manual control
- `SessionCountdown` - Visual countdown
- `useInactivityMonitor` - Activity tracking
- `InactivityWarning` - Warning component

## Security Best Practices

1. **JWT Security:**
   - Always verify signatures server-side
   - Validate expiration times
   - Check issuer matches your Clerk instance
   - Never trust client-provided tokens

2. **Session Configuration:**
   - Use shorter lifetimes for sensitive apps
   - Enable inactivity timeout for banking/healthcare
   - Consider single-session mode for high-security
   - Use secure cookies in production

3. **Custom Claims:**
   - Never store sensitive data in JWTs
   - Keep JWTs under 4KB
   - Use `publicMetadata` for claims
   - Use `privateMetadata` for server-only data

4. **Multi-Session:**
   - Enable for consumer apps (multiple devices)
   - Disable for enterprise (tighter control)
   - Implement session revocation UI
   - Monitor for suspicious activity

## Dashboard Configuration

Most session settings require configuration in Clerk Dashboard:

1. **Session Settings:** Settings → Sessions
   - Session lifetime
   - Multi-session handling
   - Inactivity timeout

2. **JWT Templates:** JWT Templates
   - Create/edit templates
   - Set as default
   - Configure custom claims

## Troubleshooting

### Sessions Not Persisting

Check:
- Domain settings match deployment URL
- SameSite attribute compatible
- Secure flag correct for environment

**Solution:**
```bash
./scripts/test-sessions.sh basic
```

### JWT Verification Fails

Check:
- CLERK_SECRET_KEY correct
- Token not expired
- Issuer matches instance

**Solution:**
```bash
./scripts/test-sessions.sh jwt-verify
```

### Custom Claims Missing

Requirements:
- JWT template set as default in Dashboard
- User signed out and back in (claims cached)
- Metadata exists on user object

**Solution:**
```bash
./scripts/setup-jwt.sh custom
./scripts/test-sessions.sh custom-claims
```

## Dependencies

- `@clerk/nextjs` 5+ (or framework-specific SDK)
- `@clerk/backend` 1+ (for server-side verification)
- `@clerk/types` (TypeScript types)

## Version

- **Skill Version:** 1.0.0
- **Clerk SDK:** 5+
- **Last Updated:** 2025-11-16

## Related Skills

- `auth-flow-builder` - Sign-in/sign-up configuration
- `user-management` - User data and metadata
- `organization-setup` - Multi-tenancy and organizations

## Support

For issues or questions:
1. Check skill documentation in `SKILL.md`
2. Review examples in `examples/` directory
3. Run relevant test script from `scripts/`
4. Consult Clerk documentation: https://clerk.com/docs
