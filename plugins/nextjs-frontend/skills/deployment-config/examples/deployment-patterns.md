# Vercel Deployment Patterns

This guide covers common deployment patterns and configurations for Next.js applications on Vercel.

## Pattern 1: Simple Production Deployment

**Use case:** Standard Next.js app with minimal configuration

### Configuration

```json
// vercel.json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "framework": "nextjs"
}
```

### Deployment

```bash
# Connect Git repository in Vercel Dashboard
# Push to main branch
git push origin main

# Or deploy via CLI
vercel --prod
```

### Environment Variables

```bash
# Add via CLI
vercel env add NEXT_PUBLIC_API_URL production
vercel env add DATABASE_URL production

# Or via Dashboard
# Settings > Environment Variables
```

---

## Pattern 2: Multi-Environment Setup

**Use case:** Separate development, staging, and production environments

### Branch Strategy

- `main` → Production
- `staging` → Staging (Preview)
- `develop` → Development (Preview)

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "github": {
    "enabled": true,
    "autoAlias": true,
    "silent": false
  }
}
```

### Environment Variables

```bash
# Development
vercel env add NEXT_PUBLIC_API_URL development
# Value: http://localhost:3000/api

# Preview (staging)
vercel env add NEXT_PUBLIC_API_URL preview
# Value: https://api-staging.example.com

# Production
vercel env add NEXT_PUBLIC_API_URL production
# Value: https://api.example.com
```

### Custom Domains

```bash
# Production (main branch)
vercel domains add example.com

# Staging (staging branch)
vercel domains add staging.example.com
```

---

## Pattern 3: Monorepo Deployment

**Use case:** Next.js app in a monorepo (Turborepo, npm workspaces, etc.)

### Project Structure

```
monorepo/
├── apps/
│   └── web/              # Next.js app
│       ├── package.json
│       └── vercel.json
├── packages/
│   ├── ui/
│   └── config/
└── package.json          # Root package.json
```

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "cd ../.. && npm run build --filter=web",
  "installCommand": "npm install --prefix=../.. --frozen-lockfile",
  "outputDirectory": ".next",
  "framework": "nextjs"
}
```

### Turborepo Configuration

```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**"]
    }
  }
}
```

### Deployment

Vercel automatically detects monorepo structure. Configure Root Directory in Project Settings:
- Root Directory: `apps/web`

---

## Pattern 4: Edge Functions for Global Performance

**Use case:** Geo-routing, A/B testing, authentication at the edge

### Middleware Configuration

```typescript
// middleware.ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export const config = {
  matcher: [
    '/',
    '/api/auth/:path*',
    '/dashboard/:path*',
  ]
}

export function middleware(request: NextRequest) {
  // Geo-based routing
  const country = request.geo?.country || 'US'

  // A/B testing
  const bucket = request.cookies.get('bucket')?.value
  if (!bucket) {
    const response = NextResponse.next()
    response.cookies.set('bucket', Math.random() > 0.5 ? 'A' : 'B')
    return response
  }

  // Authentication check
  const token = request.cookies.get('auth-token')
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}
```

### Edge API Routes

```typescript
// app/api/edge/route.ts
export const runtime = 'edge'
export const preferredRegion = ['iad1', 'sfo1', 'lhr1']

export async function GET(request: Request) {
  const geo = request.headers.get('x-vercel-ip-country') || 'Unknown'

  return new Response(JSON.stringify({ geo }), {
    headers: { 'content-type': 'application/json' }
  })
}
```

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "functions": {
    "app/api/edge/**/*.{ts,js}": {
      "runtime": "edge",
      "regions": ["iad1", "sfo1", "lhr1"]
    }
  }
}
```

---

## Pattern 5: Incremental Static Regeneration (ISR)

**Use case:** Content-heavy sites needing both performance and freshness

### Page Configuration

```typescript
// app/blog/[slug]/page.tsx
export const revalidate = 60 // Revalidate every 60 seconds

export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ slug: post.slug }))
}

export default async function BlogPost({ params }: { params: { slug: string } }) {
  const post = await getPost(params.slug)
  return <article>{post.content}</article>
}
```

### On-Demand Revalidation

```typescript
// app/api/revalidate/route.ts
import { revalidatePath } from 'next/cache'
import { NextRequest } from 'next/server'

export async function POST(request: NextRequest) {
  const secret = request.nextUrl.searchParams.get('secret')

  if (secret !== process.env.REVALIDATE_SECRET) {
    return new Response('Invalid token', { status: 401 })
  }

  const path = request.nextUrl.searchParams.get('path') || '/'

  revalidatePath(path)
  return Response.json({ revalidated: true, path })
}
```

### Trigger Revalidation

```bash
# From your CMS webhook
curl -X POST "https://example.com/api/revalidate?secret=YOUR_SECRET&path=/blog/post-slug"
```

---

## Pattern 6: API Proxying and Rewrites

**Use case:** Hide external API endpoints, avoid CORS issues

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "rewrites": [
    {
      "source": "/api/external/:path*",
      "destination": "https://external-api.example.com/:path*"
    },
    {
      "source": "/api/stripe/:path*",
      "destination": "https://api.stripe.com/v1/:path*"
    }
  ],
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Access-Control-Allow-Origin",
          "value": "https://example.com"
        },
        {
          "key": "Access-Control-Allow-Methods",
          "value": "GET,POST,PUT,DELETE,OPTIONS"
        }
      ]
    }
  ]
}
```

### Usage

```typescript
// Client-side code
const response = await fetch('/api/external/users')
// Actually calls: https://external-api.example.com/users
```

---

## Pattern 7: Custom Redirects and Clean URLs

**Use case:** SEO, URL migrations, legacy URL support

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "cleanUrls": true,
  "trailingSlash": false,
  "redirects": [
    {
      "source": "/old-blog/:slug",
      "destination": "/blog/:slug",
      "permanent": true
    },
    {
      "source": "/home",
      "destination": "/",
      "permanent": true
    },
    {
      "source": "/docs/:path(.*)",
      "destination": "https://docs.example.com/:path*",
      "permanent": false
    }
  ]
}
```

### Dynamic Redirects in next.config.js

```javascript
// next.config.js
module.exports = {
  async redirects() {
    return [
      {
        source: '/user/:id(\\d{1,})',
        destination: '/profile/:id',
        permanent: false,
      },
      {
        source: '/:path((?!api|_next).*)',
        has: [
          {
            type: 'host',
            value: 'old-domain.com',
          },
        ],
        destination: 'https://new-domain.com/:path*',
        permanent: true,
      },
    ]
  },
}
```

---

## Pattern 8: Environment-Aware Configuration

**Use case:** Different settings per deployment environment

### next.config.js

```javascript
// next.config.js
const isDev = process.env.NODE_ENV === 'development'
const isPreview = process.env.VERCEL_ENV === 'preview'
const isProd = process.env.VERCEL_ENV === 'production'

module.exports = {
  // Enable React strict mode in dev
  reactStrictMode: !isProd,

  // Different image domains per environment
  images: {
    domains: isDev
      ? ['localhost', 'placeholder.com']
      : ['cdn.example.com', 'images.example.com'],
  },

  // Compression only in production
  compress: isProd,

  // Source maps only in preview/dev
  productionBrowserSourceMaps: !isProd,
}
```

### Environment Detection

```typescript
// lib/env.ts
export const ENV = {
  isDevelopment: process.env.NODE_ENV === 'development',
  isPreview: process.env.VERCEL_ENV === 'preview',
  isProduction: process.env.VERCEL_ENV === 'production',

  // Vercel provides these
  url: process.env.VERCEL_URL,
  gitCommitSha: process.env.VERCEL_GIT_COMMIT_SHA,
  gitBranch: process.env.VERCEL_GIT_COMMIT_REF,
}
```

---

## Pattern 9: Deploy Hooks for External Triggers

**Use case:** Rebuild on CMS updates, scheduled rebuilds

### Setup

1. Go to Project Settings > Git > Deploy Hooks
2. Create a hook with name and target branch
3. Copy the generated URL

### Trigger Deployment

```bash
# From CI/CD or CMS webhook
curl -X POST https://api.vercel.com/v1/integrations/deploy/[HOOK_ID]/[SECRET]
```

### With Parameters

```bash
# Trigger with environment variables
curl -X POST "https://api.vercel.com/v1/integrations/deploy/[HOOK_ID]/[SECRET]" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Scheduled Rebuilds

```bash
# In GitHub Actions (.github/workflows/scheduled-build.yml)
name: Scheduled Rebuild
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
jobs:
  trigger-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Vercel Deploy
        run: |
          curl -X POST ${{ secrets.VERCEL_DEPLOY_HOOK }}
```

---

## Pattern 10: Security Headers and CORS

**Use case:** Secure production deployments

### vercel.json

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        },
        {
          "key": "Referrer-Policy",
          "value": "strict-origin-when-cross-origin"
        },
        {
          "key": "Permissions-Policy",
          "value": "camera=(), microphone=(), geolocation=()"
        },
        {
          "key": "Strict-Transport-Security",
          "value": "max-age=63072000; includeSubDomains; preload"
        },
        {
          "key": "Content-Security-Policy",
          "value": "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
        }
      ]
    },
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Access-Control-Allow-Credentials",
          "value": "true"
        },
        {
          "key": "Access-Control-Allow-Origin",
          "value": "https://example.com"
        },
        {
          "key": "Access-Control-Allow-Methods",
          "value": "GET,DELETE,PATCH,POST,PUT"
        },
        {
          "key": "Access-Control-Allow-Headers",
          "value": "X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version"
        }
      ]
    }
  ]
}
```

---

## Troubleshooting Common Patterns

### Build Failure: Out of Memory

```json
// vercel.json
{
  "builds": [{
    "src": "package.json",
    "use": "@vercel/next",
    "config": {
      "maxLambdaSize": "50mb"
    }
  }]
}
```

### 404 on Dynamic Routes

Ensure dynamic routes are being generated:

```typescript
// Must export generateStaticParams for app router
export async function generateStaticParams() {
  return [{ slug: 'post-1' }, { slug: 'post-2' }]
}
```

### Environment Variables Not Working

```bash
# Restart dev server after adding variables
vercel dev

# Pull latest from Vercel
vercel env pull .env.local

# Check correct environment
vercel env ls production
```

### Function Timeout

```json
// vercel.json - Increase timeout (requires Pro plan)
{
  "functions": {
    "app/api/long-task/**/*.{ts,js}": {
      "maxDuration": 60
    }
  }
}
```

---

## Best Practices Summary

1. **Use Git Integration** - Automatic deployments on push
2. **Separate Environments** - Different configs for dev/preview/prod
3. **Environment Variables** - Never hardcode secrets
4. **Edge Functions** - For geo-routing, auth, A/B testing
5. **ISR** - Balance performance and freshness
6. **Security Headers** - Always in production
7. **Clean URLs** - Better SEO and UX
8. **Monitoring** - Use Vercel Analytics and Logs
9. **Preview Deployments** - Test before production
10. **Documentation** - Keep .env.example updated
