# Environment Variables Template

This template documents environment variables for Next.js deployment on Vercel.

## File Structure

```
.env.local           # Local development (DO NOT COMMIT)
.env.development     # Development environment
.env.production      # Production environment
.env.example         # Documentation template (COMMIT THIS)
```

## Variable Categories

### Public Variables (Browser-Accessible)

Must start with `NEXT_PUBLIC_` prefix. These are embedded in the JavaScript bundle.

```bash
# API URLs
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_SITE_URL=https://example.com

# Analytics
NEXT_PUBLIC_ANALYTICS_ID=G-XXXXXXXXXX
NEXT_PUBLIC_GTM_ID=GTM-XXXXXXX

# Feature Flags
NEXT_PUBLIC_FEATURE_NEW_UI=true
NEXT_PUBLIC_ENABLE_BETA=false

# Third-party public keys
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
NEXT_PUBLIC_MAPBOX_TOKEN=pk.xxxxx
```

### Private Variables (Server-Side Only)

No `NEXT_PUBLIC_` prefix. Only available in:
- API Routes
- Server Components
- getServerSideProps
- getStaticProps

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
DATABASE_POOL_SIZE=10

# Authentication
AUTH_SECRET=your-secret-here
NEXTAUTH_URL=https://example.com
NEXTAUTH_SECRET=generate-with-openssl-rand

# API Keys (server-side)
STRIPE_SECRET_KEY=sk_test_xxxxx
SENDGRID_API_KEY=SG.xxxxx
OPENAI_API_KEY=sk-xxxxx

# OAuth Credentials
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxx
GITHUB_CLIENT_ID=xxxxx
GITHUB_CLIENT_SECRET=xxxxx

# AWS
AWS_ACCESS_KEY_ID=xxxxx
AWS_SECRET_ACCESS_KEY=xxxxx
AWS_REGION=us-east-1
S3_BUCKET_NAME=my-bucket

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=user@gmail.com
SMTP_PASSWORD=xxxxx

# External Services
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxxxx
SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
```

## Environment-Specific Values

### Development (.env.development)

```bash
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_SITE_URL=http://localhost:3000
DATABASE_URL=postgresql://localhost:5432/myapp_dev
```

### Preview (.env.preview or Vercel Preview)

```bash
NEXT_PUBLIC_API_URL=https://api-preview.example.com
NEXT_PUBLIC_SITE_URL=https://preview.example.com
DATABASE_URL=postgresql://preview-db:5432/myapp_preview
```

### Production (.env.production)

```bash
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_SITE_URL=https://example.com
DATABASE_URL=postgresql://prod-db:5432/myapp_prod
```

## Vercel CLI Commands

### Add Variables

```bash
# Add to production
vercel env add VARIABLE_NAME production

# Add to preview
vercel env add VARIABLE_NAME preview

# Add to development
vercel env add VARIABLE_NAME development

# Add to all environments
vercel env add VARIABLE_NAME production preview development
```

### List Variables

```bash
# List all environment variables
vercel env ls

# List variables for specific environment
vercel env ls production
```

### Remove Variables

```bash
# Remove from production
vercel env rm VARIABLE_NAME production
```

### Pull Variables

```bash
# Pull from Vercel to local .env.local
vercel env pull .env.local

# Pull specific environment
vercel env pull .env.production production
```

## Security Best Practices

### DO

- ✅ Use different values per environment
- ✅ Commit `.env.example` (without values)
- ✅ Add `.env.local` to `.gitignore`
- ✅ Use `NEXT_PUBLIC_` only when necessary
- ✅ Rotate secrets regularly
- ✅ Use strong random values for secrets
- ✅ Document all variables
- ✅ Validate environment variables at build time

### DON'T

- ❌ Commit `.env.local` or `.env.production`
- ❌ Share secrets in code or comments
- ❌ Use production values in development
- ❌ Hardcode API keys or secrets
- ❌ Expose sensitive data with `NEXT_PUBLIC_`
- ❌ Reuse secrets across environments
- ❌ Leave default/placeholder values in production

## Validation Pattern

Create `lib/env.ts` to validate environment variables:

```typescript
// lib/env.ts
const requiredEnvVars = [
  'DATABASE_URL',
  'AUTH_SECRET',
  'NEXT_PUBLIC_API_URL',
] as const

export function validateEnv() {
  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new Error(`Missing required environment variable: ${envVar}`)
    }
  }
}

// Call in next.config.js or startup
validateEnv()
```

## .gitignore

Ensure these entries exist in `.gitignore`:

```gitignore
# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.env*.local

# Vercel
.vercel
```

## Generate Secrets

```bash
# Generate random secret (32 bytes)
openssl rand -base64 32

# Generate UUID
uuidgen

# Generate JWT secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## Common Patterns

### Feature Flags

```bash
# Boolean flags
NEXT_PUBLIC_FEATURE_NEW_UI=true
NEXT_PUBLIC_ENABLE_ANALYTICS=false

# Usage in code
const isNewUI = process.env.NEXT_PUBLIC_FEATURE_NEW_UI === 'true'
```

### Multiple Environments

```bash
# Use NODE_ENV to determine environment
NODE_ENV=production  # Vercel sets this automatically

# Custom environment detection
NEXT_PUBLIC_APP_ENV=staging
```

### Database URLs

```bash
# PostgreSQL
DATABASE_URL=postgresql://user:password@host:5432/database?schema=public

# MySQL
DATABASE_URL=mysql://user:password@host:3306/database

# MongoDB
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/database
```

## Troubleshooting

### Variable not available in browser

- Ensure it starts with `NEXT_PUBLIC_`
- Restart dev server after adding new variables
- Check it's set in correct environment

### Variable not available on server

- Remove `NEXT_PUBLIC_` prefix
- Use only in server-side code
- Verify it's uploaded to Vercel

### Build-time vs Runtime

- Build-time: Embedded during `next build`
- Runtime: Server-side only, fetched per request
- `NEXT_PUBLIC_*` are build-time (cannot change after build)
- Server variables are runtime (can change without rebuild)
