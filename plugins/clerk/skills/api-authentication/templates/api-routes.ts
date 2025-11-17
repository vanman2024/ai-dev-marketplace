// api-routes.ts - Clerk authentication helpers for Next.js API routes

import { auth, currentUser } from '@clerk/nextjs/server'
import type { NextRequest, NextResponse } from 'next/server'

/**
 * Higher-order function to protect API routes
 * Automatically handles authentication and passes userId to handler
 */
export function withAuth<T>(
  handler: (
    req: NextRequest,
    context: { params: any; userId: string }
  ) => Promise<T>
) {
  return async (req: NextRequest, { params }: { params: any }) => {
    const { userId } = auth()

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    return handler(req, { params, userId })
  }
}

/**
 * Higher-order function that provides full user object
 */
export function withUser<T>(
  handler: (
    req: NextRequest,
    context: { params: any; userId: string; user: any }
  ) => Promise<T>
) {
  return async (req: NextRequest, { params }: { params: any }) => {
    const user = await currentUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    return handler(req, { params, userId: user.id, user })
  }
}

/**
 * Role-based access control for Next.js API routes
 */
export function withRole<T>(
  role: string,
  handler: (
    req: NextRequest,
    context: { params: any; userId: string; user: any }
  ) => Promise<T>
) {
  return async (req: NextRequest, { params }: { params: any }) => {
    const user = await currentUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    const userRole = user.publicMetadata?.role as string | undefined

    if (userRole !== role) {
      return new Response(
        JSON.stringify({
          error: 'Forbidden',
          required: role,
          actual: userRole || 'none',
        }),
        {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    return handler(req, { params, userId: user.id, user })
  }
}

/**
 * Multiple roles helper
 */
export function withAnyRole<T>(
  roles: string[],
  handler: (
    req: NextRequest,
    context: { params: any; userId: string; user: any }
  ) => Promise<T>
) {
  return async (req: NextRequest, { params }: { params: any }) => {
    const user = await currentUser()

    if (!user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    const userRole = user.publicMetadata?.role as string | undefined

    if (!userRole || !roles.includes(userRole)) {
      return new Response(
        JSON.stringify({
          error: 'Forbidden',
          required: roles,
          actual: userRole || 'none',
        }),
        {
          status: 403,
          headers: { 'Content-Type': 'application/json' },
        }
      )
    }

    return handler(req, { params, userId: user.id, user })
  }
}

/**
 * Get current authenticated user
 * Returns null if not authenticated
 */
export async function getCurrentUser() {
  try {
    const user = await currentUser()
    return user
  } catch {
    return null
  }
}

/**
 * Get current user ID
 * Returns null if not authenticated
 */
export function getCurrentUserId(): string | null {
  const { userId } = auth()
  return userId
}

/**
 * Check if user has permission
 */
export async function hasPermission(permission: string): Promise<boolean> {
  const user = await currentUser()
  if (!user) return false

  const permissions = (user.publicMetadata?.permissions as string[]) || []
  return permissions.includes(permission)
}

/**
 * Check if user has role
 */
export async function hasRole(role: string): Promise<boolean> {
  const user = await currentUser()
  if (!user) return false

  const userRole = user.publicMetadata?.role as string | undefined
  return userRole === role
}

/**
 * Check if user has any of the specified roles
 */
export async function hasAnyRole(roles: string[]): Promise<boolean> {
  const user = await currentUser()
  if (!user) return false

  const userRole = user.publicMetadata?.role as string | undefined
  return !!userRole && roles.includes(userRole)
}

// Usage examples:
//
// // app/api/protected/route.ts
// export const GET = withAuth(async (req, { userId }) => {
//   return Response.json({ message: 'Protected data', userId })
// })
//
// // app/api/user/route.ts
// export const GET = withUser(async (req, { user }) => {
//   return Response.json({ user })
// })
//
// // app/api/admin/route.ts
// export const POST = withRole('admin', async (req, { userId, user }) => {
//   return Response.json({ message: 'Admin action completed' })
// })
//
// // app/api/dashboard/route.ts
// export const GET = withAnyRole(['admin', 'manager'], async (req, { userId }) => {
//   return Response.json({ dashboard: 'data' })
// })
//
// // Manual auth check
// export async function GET(req: NextRequest) {
//   const userId = getCurrentUserId()
//   if (!userId) {
//     return new Response('Unauthorized', { status: 401 })
//   }
//
//   if (await hasRole('admin')) {
//     // Admin-only logic
//   }
//
//   return Response.json({ userId })
// }
