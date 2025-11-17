// api-middleware.ts - Clerk authentication middleware for Express/Fastify

import { ClerkExpressRequireAuth, ClerkExpressWithAuth } from '@clerk/clerk-sdk-node'
import type { Request, Response, NextFunction } from 'express'

/**
 * Require authentication middleware
 * Rejects requests without valid JWT tokens (401)
 */
export const requireAuth = ClerkExpressRequireAuth({
  onError: (error: any) => {
    console.error('Authentication error:', error)
    return {
      status: 401,
      message: 'Unauthorized - valid authentication required',
    }
  },
})

/**
 * Optional authentication middleware
 * Allows both authenticated and anonymous requests
 * Populates req.auth if token is present
 */
export const optionalAuth = ClerkExpressWithAuth({
  onError: (error: any) => {
    console.error('Auth processing error:', error)
    // Don't reject the request, just log the error
    return undefined
  },
})

/**
 * Role-based access control middleware
 * Requires specific role in user's public metadata
 */
export function requireRole(role: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = (req as any).auth

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    try {
      const { clerkClient } = await import('@clerk/clerk-sdk-node')
      const user = await clerkClient.users.getUser(userId)

      const userRole = user.publicMetadata?.role as string | undefined

      if (userRole !== role) {
        return res.status(403).json({
          error: 'Forbidden - insufficient permissions',
          required: role,
          actual: userRole || 'none',
        })
      }

      next()
    } catch (error) {
      console.error('Role check error:', error)
      return res.status(500).json({ error: 'Internal server error' })
    }
  }
}

/**
 * Multiple roles middleware
 * Allows access if user has any of the specified roles
 */
export function requireAnyRole(roles: string[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = (req as any).auth

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    try {
      const { clerkClient } = await import('@clerk/clerk-sdk-node')
      const user = await clerkClient.users.getUser(userId)

      const userRole = user.publicMetadata?.role as string | undefined

      if (!userRole || !roles.includes(userRole)) {
        return res.status(403).json({
          error: 'Forbidden - insufficient permissions',
          required: roles,
          actual: userRole || 'none',
        })
      }

      next()
    } catch (error) {
      console.error('Role check error:', error)
      return res.status(500).json({ error: 'Internal server error' })
    }
  }
}

/**
 * Custom permission middleware
 * Checks for specific permission in user's public metadata
 */
export function requirePermission(permission: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = (req as any).auth

    if (!userId) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    try {
      const { clerkClient } = await import('@clerk/clerk-sdk-node')
      const user = await clerkClient.users.getUser(userId)

      const permissions = (user.publicMetadata?.permissions as string[]) || []

      if (!permissions.includes(permission)) {
        return res.status(403).json({
          error: 'Forbidden - permission denied',
          required: permission,
        })
      }

      next()
    } catch (error) {
      console.error('Permission check error:', error)
      return res.status(500).json({ error: 'Internal server error' })
    }
  }
}

/**
 * Rate limiting middleware (basic implementation)
 * Limits requests per user per time window
 */
const rateLimitStore = new Map<string, { count: number; resetAt: number }>()

export function rateLimit(maxRequests: number, windowMs: number) {
  return (req: Request, res: Response, next: NextFunction) => {
    const { userId } = (req as any).auth

    if (!userId) {
      // Don't rate limit unauthenticated requests (handled by requireAuth)
      return next()
    }

    const now = Date.now()
    const userLimit = rateLimitStore.get(userId)

    if (!userLimit || now > userLimit.resetAt) {
      // New window
      rateLimitStore.set(userId, {
        count: 1,
        resetAt: now + windowMs,
      })
      return next()
    }

    if (userLimit.count >= maxRequests) {
      const resetIn = Math.ceil((userLimit.resetAt - now) / 1000)
      return res.status(429).json({
        error: 'Too many requests',
        retryAfter: resetIn,
      })
    }

    userLimit.count++
    next()
  }
}

// Usage examples:
//
// // Protect single route
// app.get('/api/protected', requireAuth, (req, res) => {
//   const { userId } = req.auth
//   res.json({ message: 'Protected data', userId })
// })
//
// // Protect route group
// app.use('/api/admin', requireAuth, requireRole('admin'))
//
// // Optional auth
// app.get('/api/public', optionalAuth, (req, res) => {
//   const userId = req.auth?.userId
//   res.json({ public: true, authenticated: !!userId })
// })
//
// // Role-based access
// app.delete('/api/users/:id', requireAuth, requireRole('admin'), handler)
//
// // Multiple roles
// app.get('/api/reports', requireAuth, requireAnyRole(['admin', 'manager']), handler)
//
// // Permission-based access
// app.post('/api/content', requireAuth, requirePermission('content:write'), handler)
//
// // Rate limiting
// app.use('/api', requireAuth, rateLimit(100, 60000)) // 100 requests per minute
