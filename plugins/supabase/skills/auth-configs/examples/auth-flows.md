# Authentication Flows with Supabase

Comprehensive guide to implementing different authentication patterns for AI applications.

## Table of Contents

1. [Client-Side Authentication](#client-side-authentication)
2. [Server-Side Authentication (SSR)](#server-side-authentication-ssr)
3. [Email/Password Flow](#emailpassword-flow)
4. [Magic Link Flow](#magic-link-flow)
5. [OAuth Flow](#oauth-flow)
6. [Protected Routes](#protected-routes)
7. [Session Management](#session-management)

---

## Client-Side Authentication

Best for: Single-page applications (SPAs), client-heavy apps

### Setup

```typescript
// lib/supabase.ts
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import type { Database } from '@/types/database.types'

export const createClient = () => {
  return createClientComponentClient<Database>()
}
```

### Sign Up

```typescript
// components/SignUp.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'

export function SignUp() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const supabase = createClient()

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const { data, error } = await supabase.auth.signUp({
      email
      password
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`
        data: {
          // Optional user metadata
          full_name: 'User Name'
        }
      }
    })

    if (error) {
      setError(error.message)
    } else {
      // Check if email confirmation is required
      if (data.user && !data.session) {
        setError('Check your email for confirmation link')
      } else {
        // User is signed up and logged in
        window.location.href = '/dashboard'
      }
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleSignUp}>
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Signing up...' : 'Sign Up'}
      </button>
      {error && <p className="error">{error}</p>}
    </form>
  )
}
```

### Sign In

```typescript
// components/SignIn.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'

export function SignIn() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const supabase = createClient()

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const { error } = await supabase.auth.signInWithPassword({
      email
      password
    })

    if (error) {
      setError(error.message)
    } else {
      window.location.href = '/dashboard'
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleSignIn}>
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Signing in...' : 'Sign In'}
      </button>
      {error && <p className="error">{error}</p>}
    </form>
  )
}
```

---

## Server-Side Authentication (SSR)

Best for: SEO-critical pages, server-rendered AI applications

### Setup

```typescript
// lib/supabase-server.ts
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database.types'

export const createServerClient = () => {
  return createServerComponentClient<Database>({ cookies })
}
```

### Protected Server Component

```typescript
// app/dashboard/page.tsx
import { createServerClient } from '@/lib/supabase-server'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const supabase = createServerClient()

  // Check authentication
  const {
    data: { user }
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  // Fetch user-specific data
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()

  return (
    <div>
      <h1>Welcome, {profile?.full_name || user.email}</h1>
      <p>User ID: {user.id}</p>
    </div>
  )
}
```

### Server Action Authentication

```typescript
// app/actions/profile.ts
'use server'

import { createServerClient } from '@/lib/supabase-server'
import { revalidatePath } from 'next/cache'

export async function updateProfile(formData: FormData) {
  const supabase = createServerClient()

  // Verify authentication
  const {
    data: { user }
  } = await supabase.auth.getUser()

  if (!user) {
    throw new Error('Not authenticated')
  }

  const fullName = formData.get('fullName') as string

  // Update profile
  const { error } = await supabase
    .from('profiles')
    .update({ full_name: fullName })
    .eq('id', user.id)

  if (error) {
    throw error
  }

  revalidatePath('/dashboard')
}
```

---

## Email/Password Flow

### Complete Sign Up Flow

```typescript
// app/signup/page.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function SignUpPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const supabase = createClient()
  const router = useRouter()

  // Password validation
  const validatePassword = (pwd: string) => {
    const errors = []
    if (pwd.length < 8) errors.push('At least 8 characters')
    if (!/[A-Z]/.test(pwd)) errors.push('One uppercase letter')
    if (!/[a-z]/.test(pwd)) errors.push('One lowercase letter')
    if (!/[0-9]/.test(pwd)) errors.push('One number')
    return errors
  }

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage(null)

    // Validate passwords match
    if (password !== confirmPassword) {
      setMessage('Passwords do not match')
      setLoading(false)
      return
    }

    // Validate password strength
    const passwordErrors = validatePassword(password)
    if (passwordErrors.length > 0) {
      setMessage(`Password must have: ${passwordErrors.join(', ')}`)
      setLoading(false)
      return
    }

    // Sign up
    const { data, error } = await supabase.auth.signUp({
      email
      password
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`
      }
    })

    if (error) {
      setMessage(error.message)
    } else if (data.user && !data.session) {
      // Email confirmation required
      setMessage('Check your email to confirm your account')
    } else {
      // Auto sign-in enabled
      router.push('/dashboard')
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleSignUp}>
      <h1>Create Account</h1>

      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />

      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />

      <input
        type="password"
        placeholder="Confirm Password"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        required
      />

      <button type="submit" disabled={loading}>
        {loading ? 'Creating account...' : 'Sign Up'}
      </button>

      {message && <p>{message}</p>}
    </form>
  )
}
```

### Password Reset Flow

```typescript
// app/forgot-password/page.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const supabase = createClient()

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage(null)

    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/reset-password`
    })

    if (error) {
      setMessage(error.message)
    } else {
      setMessage('Check your email for password reset link')
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleResetPassword}>
      <h1>Reset Password</h1>
      <input
        type="email"
        placeholder="Enter your email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Sending...' : 'Send Reset Link'}
      </button>
      {message && <p>{message}</p>}
    </form>
  )
}
```

```typescript
// app/reset-password/page.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function ResetPasswordPage() {
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState<string | null>(null)

  const supabase = createClient()
  const router = useRouter()

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage(null)

    if (password !== confirmPassword) {
      setMessage('Passwords do not match')
      setLoading(false)
      return
    }

    const { error } = await supabase.auth.updateUser({
      password
    })

    if (error) {
      setMessage(error.message)
    } else {
      setMessage('Password updated successfully!')
      setTimeout(() => router.push('/dashboard'), 2000)
    }

    setLoading(false)
  }

  return (
    <form onSubmit={handleUpdatePassword}>
      <h1>Set New Password</h1>
      <input
        type="password"
        placeholder="New Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      <input
        type="password"
        placeholder="Confirm Password"
        value={confirmPassword}
        onChange={(e) => setConfirmPassword(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Updating...' : 'Update Password'}
      </button>
      {message && <p>{message}</p>}
    </form>
  )
}
```

---

## Magic Link Flow

Passwordless authentication with one-time links

```typescript
// app/magic-link/page.tsx
'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase'

export default function MagicLinkPage() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [sent, setSent] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const supabase = createClient()

  const handleMagicLink = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const { error } = await supabase.auth.signInWithOtp({
      email
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`
      }
    })

    if (error) {
      setError(error.message)
    } else {
      setSent(true)
    }

    setLoading(false)
  }

  if (sent) {
    return (
      <div>
        <h1>Check Your Email</h1>
        <p>We sent a magic link to {email}</p>
        <p>Click the link in the email to sign in</p>
      </div>
    )
  }

  return (
    <form onSubmit={handleMagicLink}>
      <h1>Sign In with Magic Link</h1>
      <p>No password required!</p>
      <input
        type="email"
        placeholder="Enter your email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <button type="submit" disabled={loading}>
        {loading ? 'Sending...' : 'Send Magic Link'}
      </button>
      {error && <p className="error">{error}</p>}
    </form>
  )
}
```

---

## OAuth Flow

Social login implementation

```typescript
// components/OAuthButtons.tsx
'use client'

import { createClient } from '@/lib/supabase'

type Provider = 'google' | 'github' | 'discord'

export function OAuthButtons() {
  const supabase = createClient()

  const handleOAuth = async (provider: Provider) => {
    const { error } = await supabase.auth.signInWithOAuth({
      provider
      options: {
        redirectTo: `${window.location.origin}/auth/callback`
        scopes: provider === 'github' ? 'user:email read:user' : undefined
      }
    })

    if (error) {
      console.error('OAuth error:', error.message)
    }
  }

  return (
    <div>
      <button onClick={() => handleOAuth('google')}>
        Sign in with Google
      </button>
      <button onClick={() => handleOAuth('github')}>
        Sign in with GitHub
      </button>
      <button onClick={() => handleOAuth('discord')}>
        Sign in with Discord
      </button>
    </div>
  )
}
```

### OAuth Callback Handler

```typescript
// app/auth/callback/route.ts
import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const requestUrl = new URL(request.url)
  const code = requestUrl.searchParams.get('code')
  const next = requestUrl.searchParams.get('next') || '/dashboard'

  if (code) {
    const supabase = createRouteHandlerClient({ cookies })
    const { error } = await supabase.auth.exchangeCodeForSession(code)

    if (error) {
      return NextResponse.redirect(`${requestUrl.origin}/error?message=${error.message}`)
    }
  }

  return NextResponse.redirect(`${requestUrl.origin}${next}`)
}
```

---

## Protected Routes

### Client-Side Protection

```typescript
// app/dashboard/layout.tsx
'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export default function DashboardLayout({
  children
}: {
  children: React.ReactNode
}) {
  const [loading, setLoading] = useState(true)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    const checkAuth = async () => {
      const {
        data: { user }
      } = await supabase.auth.getUser()

      if (!user) {
        router.push('/login')
      } else {
        setLoading(false)
      }
    }

    checkAuth()
  }, [router, supabase])

  if (loading) {
    return <div>Loading...</div>
  }

  return <>{children}</>
}
```

### Server-Side Protection (Middleware)

See `/templates/middleware/auth-middleware.ts` for complete implementation.

---

## Session Management

### Listen for Auth Changes

```typescript
// app/providers.tsx
'use client'

import { useEffect } from 'react'
import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const supabase = createClient()
  const router = useRouter()

  useEffect(() => {
    const {
      data: { subscription }
    } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN') {
        router.push('/dashboard')
      } else if (event === 'SIGNED_OUT') {
        router.push('/login')
      } else if (event === 'TOKEN_REFRESHED') {
        console.log('Session refreshed')
      }
    })

    return () => subscription.unsubscribe()
  }, [supabase, router])

  return <>{children}</>
}
```

### Sign Out

```typescript
// components/SignOutButton.tsx
'use client'

import { createClient } from '@/lib/supabase'
import { useRouter } from 'next/navigation'

export function SignOutButton() {
  const supabase = createClient()
  const router = useRouter()

  const handleSignOut = async () => {
    await supabase.auth.signOut()
    router.push('/login')
  }

  return <button onClick={handleSignOut}>Sign Out</button>
}
```

---

## Best Practices

1. **Always validate on server-side** - Client validation is UX, server validation is security
2. **Use HTTPS in production** - Required for secure cookie transmission
3. **Implement rate limiting** - Prevent brute force attacks
4. **Store sessions in httpOnly cookies** - Prevents XSS attacks
5. **Refresh tokens automatically** - Supabase handles this via `onAuthStateChange`
6. **Handle auth errors gracefully** - Provide clear error messages
7. **Log security events** - Track failed login attempts

## Next Steps

- [AI Application Auth Patterns](./ai-app-patterns.md)
- [OAuth Setup Guide](./oauth-setup-guide.md)
- [Testing Auth Flows](../scripts/test-auth-flow.sh)
