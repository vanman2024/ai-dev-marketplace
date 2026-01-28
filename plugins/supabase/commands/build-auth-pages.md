---
description: Build complete authentication UI pages - sign in, sign up, forgot password, profile pages with OAuth support for Next.js, SvelteKit, or React
argument-hint: [--pages <all|sign-in|sign-up|forgot-password|profile>] [--providers <google,github,discord>]
---

# Build Authentication Pages

**Goal:** Create production-ready authentication pages with full Supabase integration.

## What Gets Created

### Core Auth Pages
- **Sign In** (`/sign-in`) - Email/password + OAuth buttons
- **Sign Up** (`/sign-up`) - Registration with email verification
- **Forgot Password** (`/forgot-password`) - Password reset request
- **Reset Password** (`/reset-password`) - New password form
- **Email Verification** (`/verify-email`) - Email confirmation handling

### Supporting Files
- **OAuth Callback** (`/auth/callback`) - Handle OAuth redirects
- **Middleware** - Protect routes, redirect logic
- **Supabase Client** - Server/client utilities (if not exists)

### Optional Pages
- **Profile/Account** (`/account`) - User settings, password change
- **Connected Accounts** - Manage OAuth connections

## Arguments

- `--pages <list>` - Which pages to create (default: all)
- `--providers <list>` - OAuth providers to include (default: google,github)

## Execution

```
Task("Build auth pages", @supabase-auth-pages-builder, {
  prompt: "Build authentication pages for this project:
    - Detect framework (Next.js App Router, Pages Router, SvelteKit)
    - Create sign in page with $PROVIDERS OAuth buttons
    - Create sign up page with email verification
    - Create forgot/reset password pages
    - Add OAuth callback route handler
    - Configure middleware for route protection
    - Use shadcn/ui components with proper styling
    - Add loading states and error handling
    - Follow latest Supabase Auth patterns"
})
```

## Framework Detection

The agent auto-detects your framework:
- **Next.js App Router** → `app/(auth)/sign-in/page.tsx`
- **Next.js Pages Router** → `pages/sign-in.tsx`
- **SvelteKit** → `src/routes/(auth)/sign-in/+page.svelte`

## OAuth Provider Setup

After page generation, you'll need to configure providers in Supabase Dashboard:

1. Go to **Authentication > Providers**
2. Enable each provider (Google, GitHub, Discord, etc.)
3. Add OAuth credentials from provider's developer console
4. Set redirect URL: `https://your-project.supabase.co/auth/v1/callback`

## Example Output Structure (Next.js App Router)

```
app/
├── (auth)/
│   ├── layout.tsx          # Auth pages layout (centered, minimal)
│   ├── sign-in/
│   │   └── page.tsx        # Sign in form + OAuth
│   ├── sign-up/
│   │   └── page.tsx        # Registration form
│   ├── forgot-password/
│   │   └── page.tsx        # Password reset request
│   └── reset-password/
│       └── page.tsx        # New password form
├── auth/
│   └── callback/
│       └── route.ts        # OAuth callback handler
├── (dashboard)/
│   └── account/
│       └── page.tsx        # Profile settings
lib/
├── supabase/
│   ├── client.ts           # Browser client
│   ├── server.ts           # Server client  
│   └── middleware.ts       # Auth middleware helper
middleware.ts               # Route protection
```

## Related Commands

- `/supabase:add-auth` - Configure auth providers (backend only)
- `/supabase:add-rls` - Add Row Level Security for user data
- `/nextjs-frontend:build-nextjs-app` - Full Next.js app with auth
