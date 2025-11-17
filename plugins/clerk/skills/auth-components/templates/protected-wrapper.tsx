'use client'

import { useAuth } from '@clerk/nextjs'
import { useRouter } from 'next/navigation'
import { useEffect, ReactNode } from 'react'

interface ProtectedRouteProps {
  children: ReactNode
  redirectTo?: string
  fallback?: ReactNode
}

export function ProtectedRoute({
  children,
  redirectTo = '/sign-in',
  fallback = <LoadingSpinner />
}: ProtectedRouteProps) {
  const { isLoaded, isSignedIn } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (isLoaded && !isSignedIn) {
      router.push(redirectTo)
    }
  }, [isLoaded, isSignedIn, router, redirectTo])

  if (!isLoaded) {
    return <>{fallback}</>
  }

  if (!isSignedIn) {
    return <>{fallback}</>
  }

  return <>{children}</>
}

// Loading spinner component
function LoadingSpinner() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="flex flex-col items-center gap-4">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-gray-200 border-t-blue-600" />
        <p className="text-gray-600">Loading...</p>
      </div>
    </div>
  )
}

// Higher-order component version
export function withProtectedRoute<P extends object>(
  Component: React.ComponentType<P>,
  redirectTo = '/sign-in'
) {
  return function ProtectedComponent(props: P) {
    return (
      <ProtectedRoute redirectTo={redirectTo}>
        <Component {...props} />
      </ProtectedRoute>
    )
  }
}

// Example usage:
// const ProtectedDashboard = withProtectedRoute(DashboardPage)

// Role-based protection
interface RoleProtectedRouteProps extends ProtectedRouteProps {
  allowedRoles: string[]
}

export function RoleProtectedRoute({
  children,
  allowedRoles,
  redirectTo = '/unauthorized',
  fallback = <LoadingSpinner />
}: RoleProtectedRouteProps) {
  const { isLoaded, isSignedIn, orgRole } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (isLoaded && !isSignedIn) {
      router.push('/sign-in')
      return
    }

    if (isLoaded && isSignedIn && orgRole && !allowedRoles.includes(orgRole)) {
      router.push(redirectTo)
    }
  }, [isLoaded, isSignedIn, orgRole, allowedRoles, router, redirectTo])

  if (!isLoaded) {
    return <>{fallback}</>
  }

  if (!isSignedIn || (orgRole && !allowedRoles.includes(orgRole))) {
    return <>{fallback}</>
  }

  return <>{children}</>
}
