# Next.js Integration Skill

Complete Clerk authentication integration patterns for Next.js applications, supporting both App Router and Pages Router.

## Overview

This skill provides comprehensive setup and configuration for Clerk authentication in Next.js projects, including:

- **Installation & Setup** - Automated Clerk SDK installation and environment configuration
- **App Router Support** - Full integration for Next.js 13.4+ with Server Components
- **Pages Router Support** - Complete setup for Next.js 12.x and traditional routing
- **Middleware Configuration** - Edge-based route protection and custom auth logic
- **Authentication Patterns** - Server-side and client-side auth examples
- **Protected Routes** - Complete examples of securing pages and API routes

## Files

### Scripts

- **install-clerk.sh** - Installs @clerk/nextjs package and creates environment files
- **setup-app-router.sh** - Configures Clerk for App Router with Server Components
- **setup-pages-router.sh** - Configures Clerk for Pages Router
- **configure-middleware.sh** - Sets up authentication middleware with custom route matching

### Templates

#### App Router Templates
- **middleware.ts** - Edge middleware for route protection
- **layout.tsx** - Root layout with ClerkProvider

#### Pages Router Templates
- **_app.tsx** - Custom App component with ClerkProvider
- **api/auth.ts** - Protected API route example

### Examples

- **protected-route.tsx** - Complete protected route with user data display
- **server-component-auth.tsx** - Advanced Server Component authentication patterns

## Usage

### Quick Start (App Router)

```bash
# 1. Install Clerk
bash ./skills/nextjs-integration/scripts/install-clerk.sh

# 2. Configure App Router
bash ./skills/nextjs-integration/scripts/setup-app-router.sh

# 3. Update .env.local with your Clerk keys
# Get keys from: https://dashboard.clerk.com

# 4. Start development
npm run dev
```

### Quick Start (Pages Router)

```bash
# 1. Install Clerk
bash ./skills/nextjs-integration/scripts/install-clerk.sh

# 2. Configure Pages Router
bash ./skills/nextjs-integration/scripts/setup-pages-router.sh

# 3. Update .env.local with your Clerk keys

# 4. Start development
npm run dev
```

### Custom Middleware Configuration

```bash
# Configure middleware with interactive prompts
bash ./skills/nextjs-integration/scripts/configure-middleware.sh
```

## Requirements

- Next.js 12.0+ (Pages Router) or 13.4+ (App Router)
- React 18+
- Node.js 18.17+ or 20+
- Active Clerk account (free tier available)

## Environment Variables

Required in `.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=your_clerk_publishable_key_here
CLERK_SECRET_KEY=your_clerk_secret_key_here
```

Optional customization:

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/onboarding
```

## Security

**CRITICAL:** Never commit API keys to git!

- `.env.local` is git-ignored (contains real keys)
- `.env.example` is safe to commit (contains placeholders)
- All scripts use placeholder values like `your_clerk_secret_key_here`
- Environment variables are automatically added to `.gitignore`

## Features

### App Router Features
- Server Components with `auth()` helper
- Client Components with `useAuth()` hook
- Edge middleware for route protection
- Automatic session management
- RSC-compatible authentication

### Pages Router Features
- `getServerSideProps` with auth
- API routes with auth protection
- Client-side authentication hooks
- Custom sign-in/sign-up components

### Middleware Features
- Edge Runtime protection
- Public route configuration
- Ignored route patterns
- Custom redirect logic
- Regex route matching

## Documentation

See `SKILL.md` for complete documentation including:
- Detailed setup instructions
- Authentication patterns
- Integration examples
- Troubleshooting guide
- Best practices

## Support

- [Clerk Documentation](https://clerk.com/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Clerk Community](https://clerk.com/community)

## Version

**Version:** 1.0.0
**Plugin:** clerk
**Category:** Authentication
**Skill Type:** Integration & Configuration
