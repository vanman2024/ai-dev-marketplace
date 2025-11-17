---
name: api-authentication
description: Backend API authentication patterns with Clerk JWT middleware and route protection. Use when building REST APIs, GraphQL APIs, protecting backend routes, implementing JWT validation, setting up Express middleware, or when user mentions API authentication, backend security, JWT tokens, or protected endpoints.
allowed-tools: Read, Write, Bash, Glob, Grep
---

# api-authentication

Backend API authentication skill for Clerk integration. Provides JWT middleware, route protection patterns, and API client generation for REST and GraphQL backends.

## Instructions

### Phase 1: Understand Requirements

1. Identify backend framework (Express, Fastify, Next.js API routes, etc.)
2. Determine authentication strategy (JWT validation, session tokens)
3. Check for existing Clerk configuration
4. Identify API endpoints to protect

### Phase 2: Setup API Authentication

Run the setup script to configure backend authentication:

```bash
bash scripts/setup-api-auth.sh <framework> <project-path>
```

**Supported Frameworks:**
- `express` - Express.js middleware
- `fastify` - Fastify decorators
- `nextjs` - Next.js API route helpers
- `fastapi` - FastAPI dependencies (Python)

**What it does:**
- Installs required Clerk SDK packages
- Creates middleware files from templates
- Configures environment variables
- Sets up JWT verification utilities
- Creates route protection helpers

### Phase 3: Implement Route Protection

**For Express/Node.js backends:**

Use the `api-middleware.ts` template:

```typescript
import { requireAuth } from './middleware/clerk-auth'

// Protect individual routes
app.get('/api/protected', requireAuth, (req, res) => {
  const userId = req.auth.userId
  res.json({ message: 'Protected data', userId })
})

// Protect route groups
app.use('/api/admin', requireAuth, adminRouter)
```

**For Next.js API routes:**

Use the `api-routes.ts` template:

```typescript
import { withAuth } from '@/lib/clerk-middleware'

export default withAuth(async (req, res) => {
  const { userId } = req.auth
  // Protected route logic
})
```

**For GraphQL:**

Use the `graphql-clerk.ts` example:

```typescript
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node'

const server = new ApolloServer({
  context: ({ req }) => ({
    userId: req.auth?.userId,
    user: req.auth?.user
  })
})

app.use('/graphql', ClerkExpressRequireAuth(), apolloMiddleware)
```

### Phase 4: Generate API Client

Create type-safe API clients with authentication headers:

```bash
bash scripts/generate-api-client.sh <api-type> <output-path>
```

**API Types:**
- `rest` - REST API client with fetch
- `graphql` - GraphQL client with Apollo
- `axios` - Axios-based REST client
- `trpc` - tRPC client with auth context

**Generated Client Features:**
- Automatic JWT token attachment
- Token refresh handling
- Type-safe request methods
- Error handling for auth failures

### Phase 5: Test Authentication

Run comprehensive authentication tests:

```bash
bash scripts/test-api-auth.sh <project-path>
```

**Test Coverage:**
- ✅ Unauthenticated requests rejected (401)
- ✅ Valid JWT tokens accepted
- ✅ Expired tokens refreshed
- ✅ Invalid tokens rejected
- ✅ Protected routes accessible with auth
- ✅ User context available in handlers

## Common Patterns

### Pattern 1: Express Middleware

```typescript
// middleware/clerk-auth.ts
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node'

export const requireAuth = ClerkExpressRequireAuth({
  onError: (error) => {
    console.error('Auth error:', error)
    return { status: 401, message: 'Unauthorized' }
  }
})

// Optional auth (allows both authenticated and anonymous)
export const optionalAuth = ClerkExpressWithAuth()
```

### Pattern 2: Custom JWT Validation

```typescript
// lib/jwt-verify.ts
import { verifyToken } from '@clerk/backend'

export async function validateJWT(token: string) {
  try {
    const payload = await verifyToken(token, {
      secretKey: process.env.CLERK_SECRET_KEY
    })
    return { valid: true, userId: payload.sub }
  } catch (error) {
    return { valid: false, error: error.message }
  }
}
```

### Pattern 3: Role-Based Access Control

```typescript
// middleware/rbac.ts
export function requireRole(role: string) {
  return async (req, res, next) => {
    const { userId } = req.auth
    const user = await clerkClient.users.getUser(userId)

    if (user.publicMetadata.role !== role) {
      return res.status(403).json({ error: 'Forbidden' })
    }
    next()
  }
}

// Usage
app.get('/api/admin', requireAuth, requireRole('admin'), handler)
```

### Pattern 4: GraphQL Context Integration

```typescript
// graphql/context.ts
import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node'

export const context = async ({ req }) => {
  const userId = req.auth?.userId

  if (!userId) {
    throw new AuthenticationError('Must be authenticated')
  }

  const user = await clerkClient.users.getUser(userId)

  return {
    userId,
    user,
    isAdmin: user.publicMetadata.role === 'admin'
  }
}
```

## Environment Variables

Required environment variables (always use placeholders in committed files):

```bash
# .env.example
CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here

# Optional: For webhook verification
CLERK_WEBHOOK_SECRET=your_webhook_secret_here

# Optional: For custom JWT configuration
CLERK_JWT_KEY=your_jwt_key_here
```

## Security Best Practices

1. **Always validate tokens server-side** - Never trust client-side validation alone
2. **Use HTTPS in production** - JWT tokens must be transmitted securely
3. **Implement rate limiting** - Prevent brute force attacks on protected endpoints
4. **Sanitize user inputs** - Validate all data even from authenticated users
5. **Log authentication events** - Track failed auth attempts and suspicious activity
6. **Rotate secrets regularly** - Update webhook and JWT secrets periodically
7. **Use environment variables** - Never hardcode API keys or secrets

## Troubleshooting

**Issue: "Invalid token" errors**
- Verify `CLERK_SECRET_KEY` is correct
- Check token expiration settings in Clerk dashboard
- Ensure clock sync between client and server

**Issue: CORS errors on API requests**
- Configure CORS middleware before Clerk middleware
- Whitelist your frontend domain in CORS config
- Include credentials in fetch requests

**Issue: "Missing userId" in request context**
- Verify middleware is applied to route
- Check that token is sent in Authorization header
- Ensure middleware order is correct

**Issue: GraphQL authentication not working**
- Apply Clerk middleware before GraphQL middleware
- Extract auth from request in context function
- Check that Apollo Server receives request object

## Requirements

- Clerk account with secret key
- Backend framework (Express, Fastify, Next.js, etc.)
- Node.js 16+ or Python 3.8+ (for FastAPI)
- Environment variables configured
- HTTPS enabled in production

## Templates Reference

- `templates/api-middleware.ts` - Express/Node.js middleware
- `templates/api-routes.ts` - Next.js API route helpers
- `templates/backend-sdk-setup.ts` - Backend SDK initialization
- `templates/fastapi-middleware.py` - FastAPI authentication dependencies

## Examples Reference

- `examples/rest-api.md` - Complete REST API with authentication
- `examples/graphql-api.md` - GraphQL server with Clerk context
- `examples/webhooks.md` - Webhook event handling and processing

## Scripts Reference

- `scripts/setup-api-auth.sh` - Configure backend authentication
- `scripts/generate-api-client.sh` - Create authenticated API clients
- `scripts/test-api-auth.sh` - Test authentication flows

---

## Security Compliance

This skill follows strict security rules:
- All code examples use placeholder values only
- No real API keys, passwords, or secrets
- Environment variable references in all code
- `.gitignore` protection documented

**Reference:** `@docs/security/SECURITY-RULES.md`
