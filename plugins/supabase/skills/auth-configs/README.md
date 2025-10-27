# Supabase Authentication Configurations Skill

Complete authentication setup for AI applications using Supabase - OAuth providers, JWT configuration, email authentication, and auth flow patterns.

## Overview

This skill provides everything needed to configure robust authentication for AI-powered applications using Supabase. It includes functional scripts, production-ready templates, and comprehensive examples covering OAuth (Google, GitHub, Discord), email authentication with PKCE flow, JWT configuration, and AI-specific auth patterns.

## Directory Structure

```
auth-configs/
├── SKILL.md                           # Main skill manifest
├── README.md                          # This file
├── scripts/                           # Functional automation scripts
│   ├── setup-oauth-provider.sh       # Configure OAuth providers
│   ├── configure-jwt.sh              # Set up JWT settings
│   ├── setup-email-auth.sh           # Configure email authentication
│   └── test-auth-flow.sh             # Test authentication flows
├── templates/                         # Production-ready templates
│   ├── oauth-providers/              # OAuth configuration templates
│   │   ├── google-oauth-config.json
│   │   ├── github-oauth-config.json
│   │   └── discord-oauth-config.json
│   ├── email-templates/              # Customizable email templates
│   │   ├── confirmation.html
│   │   ├── magic-link.html
│   │   ├── password-reset.html
│   │   └── invite.html
│   ├── middleware/                   # Auth middleware templates
│   │   └── auth-middleware.ts
│   └── helpers/                      # Auth helper functions
│       └── auth-helpers.ts
└── examples/                          # Comprehensive guides
    ├── oauth-setup-guide.md
    ├── auth-flows.md
    └── ai-app-patterns.md
```

## Quick Start

### 1. Set Up OAuth Provider

```bash
# Configure Google OAuth
bash scripts/setup-oauth-provider.sh google

# Configure GitHub OAuth
bash scripts/setup-oauth-provider.sh github

# Configure Discord OAuth
bash scripts/setup-oauth-provider.sh discord
```

### 2. Configure JWT Settings

```bash
# Set up JWT with custom expiration and claims
bash scripts/configure-jwt.sh
```

### 3. Set Up Email Authentication

```bash
# Configure email auth with PKCE flow for SSR
bash scripts/setup-email-auth.sh --both
```

### 4. Test Your Setup

```bash
# Run comprehensive authentication tests
bash scripts/test-auth-flow.sh --all

# Test specific provider
bash scripts/test-auth-flow.sh google
```

## Features

### OAuth Provider Support

- ✅ **Google** - Consumer apps, Google Workspace integration
- ✅ **GitHub** - Developer tools, technical audiences
- ✅ **Discord** - Community-driven applications
- ✅ **20+ more providers** - Facebook, Twitter, LinkedIn, Slack, etc.

### Email Authentication

- ✅ **Password-based** - Traditional email/password auth
- ✅ **Magic Links** - Passwordless authentication
- ✅ **PKCE Flow** - Secure SSR authentication
- ✅ **Email Verification** - Confirm email addresses
- ✅ **Password Reset** - Secure password recovery

### JWT Configuration

- ✅ **Custom Expiration** - Configure token lifetimes
- ✅ **Custom Claims** - Add user metadata to JWT
- ✅ **Secret Rotation** - Security best practices
- ✅ **Role-Based Access** - RBAC support

### Production-Ready Templates

- ✅ **Email Templates** - Branded confirmation, magic link, password reset
- ✅ **Middleware** - Next.js route protection
- ✅ **Helper Functions** - Reusable auth utilities
- ✅ **TypeScript Support** - Full type safety

### AI Application Patterns

- ✅ **Conversation Ownership** - User-scoped AI chats
- ✅ **RAG Systems** - Document upload with embeddings
- ✅ **Multi-Tenant Platforms** - Organization-based access
- ✅ **API Key Management** - User-generated API keys
- ✅ **Usage Tracking** - Monitor AI API costs
- ✅ **Rate Limiting** - Prevent abuse

## Usage Examples

### Configure Google OAuth for AI Chat App

```bash
# 1. Run setup script
bash scripts/setup-oauth-provider.sh google

# 2. Follow prompts to configure Google Cloud Console

# 3. Add middleware to your Next.js app
cp templates/middleware/auth-middleware.ts ./middleware.ts

# 4. Test the flow
bash scripts/test-auth-flow.sh google
```

### Multi-Provider Setup for RAG Application

```bash
# Set up multiple OAuth providers
for provider in google github discord; do
  bash scripts/setup-oauth-provider.sh $provider
done

# Configure email auth as fallback
bash scripts/setup-email-auth.sh --both

# Configure JWT with custom claims for AI model access
bash scripts/configure-jwt.sh

# Test all providers
bash scripts/test-auth-flow.sh --all
```

### AI Platform with Role-Based Access

```bash
# 1. Configure JWT with custom claims
bash scripts/configure-jwt.sh

# 2. Set up database function for custom claims
# (See examples/ai-app-patterns.md for SQL)

# 3. Configure RLS policies
# (See examples/ai-app-patterns.md for complete schema)

# 4. Test authentication
bash scripts/test-auth-flow.sh --email
```

## Script Reference

### setup-oauth-provider.sh

Configure OAuth provider authentication.

```bash
./scripts/setup-oauth-provider.sh <provider>

# Supported providers:
# google, github, discord, facebook, apple, twitter, linkedin, slack

# Features:
# - Provider-specific setup instructions
# - Credential management
# - Automatic Supabase configuration
# - Environment variable setup
```

### configure-jwt.sh

Configure JWT settings for secure session management.

```bash
./scripts/configure-jwt.sh [--generate-secret] [--rotate]

# Options:
# --generate-secret  Generate new JWT secret
# --rotate          Rotate existing JWT secret

# Features:
# - Token expiration configuration
# - Custom claims setup
# - Secret generation and rotation
# - Security best practices
```

### setup-email-auth.sh

Configure email authentication with PKCE flow.

```bash
./scripts/setup-email-auth.sh [--magic-link|--password|--both]

# Options:
# --magic-link  Configure magic link only
# --password    Configure password auth only
# --both        Configure both methods (default)

# Features:
# - PKCE flow for SSR
# - Email template customization
# - Password strength requirements
# - Middleware configuration
```

### test-auth-flow.sh

Test authentication flows end-to-end.

```bash
./scripts/test-auth-flow.sh [--email|--magic-link|--all] [provider]

# Options:
# --email       Test email authentication
# --magic-link  Test magic link authentication
# --all         Run comprehensive tests
# provider      Test specific OAuth provider

# Features:
# - Connection testing
# - Email signup/login
# - Magic link testing
# - Session validation
# - OAuth provider testing
```

## Template Reference

### OAuth Provider Configurations

JSON templates with complete setup instructions for each provider:

- `google-oauth-config.json` - Google Cloud Console setup
- `github-oauth-config.json` - GitHub OAuth App setup
- `discord-oauth-config.json` - Discord Developer Portal setup

### Email Templates

HTML templates for authentication emails:

- `confirmation.html` - Email verification
- `magic-link.html` - Passwordless login
- `password-reset.html` - Password recovery
- `invite.html` - Team invitations

Customize with your brand colors, logo, and messaging.

### Middleware & Helpers

TypeScript templates for Next.js integration:

- `auth-middleware.ts` - Route protection middleware
- `auth-helpers.ts` - Reusable authentication utilities

Full TypeScript support with type definitions.

## Example Guides

### oauth-setup-guide.md

Complete step-by-step guide for OAuth provider setup:
- Google Cloud Console walkthrough
- GitHub OAuth App configuration
- Discord Developer Portal setup
- Troubleshooting common issues

### auth-flows.md

Comprehensive authentication flow patterns:
- Client-side authentication
- Server-side authentication (SSR)
- Email/password flow
- Magic link flow
- OAuth flow
- Protected routes
- Session management

### ai-app-patterns.md

AI-specific authentication patterns:
- AI chat applications with conversation ownership
- RAG systems with document embeddings
- Multi-tenant AI platforms
- API key management
- Usage tracking and rate limiting
- Row-level security for AI data

## Environment Variables

Required environment variables:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# JWT
JWT_SECRET=your-jwt-secret (generated by configure-jwt.sh)
SUPABASE_JWT_SECRET=your-jwt-secret

# OAuth Providers (as configured)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
DISCORD_CLIENT_ID=your-discord-client-id
DISCORD_CLIENT_SECRET=your-discord-client-secret
```

**⚠️ Security:** Always add `.env.local` to `.gitignore`!

## Dependencies

Required tools and packages:

### System Dependencies
- `bash` - Shell scripting
- `curl` - HTTP requests
- `jq` - JSON processing
- `openssl` - Secret generation

### Node.js Packages
- `@supabase/supabase-js` - Supabase client
- `@supabase/ssr` - Server-side rendering support
- `@supabase/auth-helpers-nextjs` - Next.js integration

### Installation

```bash
# System dependencies (Ubuntu/Debian)
sudo apt-get install curl jq openssl

# Node.js packages
npm install @supabase/supabase-js @supabase/ssr @supabase/auth-helpers-nextjs

# Or with yarn
yarn add @supabase/supabase-js @supabase/ssr @supabase/auth-helpers-nextjs
```

## Security Best Practices

1. **Never Hardcode Secrets**
   - Use environment variables
   - Add `.env.local` to `.gitignore`
   - Use different secrets for dev/staging/prod

2. **Use PKCE Flow for SSR**
   - Required for Next.js, SvelteKit, Remix
   - Prevents authorization code interception
   - Mandatory for production

3. **Validate Redirect URLs**
   - Whitelist exact redirect URIs
   - Use HTTPS in production
   - Never allow wildcard redirects

4. **Rotate JWT Secrets**
   - Change secrets every 90 days
   - Use strong random strings (32+ chars)
   - Track rotation in secure location

5. **Implement Row-Level Security**
   - Enable RLS on all tables
   - Validate on database level
   - Don't rely on client validation

## Troubleshooting

### OAuth Redirect URI Mismatch

**Error:** `redirect_uri_mismatch`

**Solution:** Verify redirect URI in provider console exactly matches Supabase callback URL.

### Email Not Received

**Error:** Confirmation email not received

**Solution:**
- Check spam folder
- Verify email settings in Supabase Dashboard
- Configure custom SMTP for production

### Session Not Persisting

**Error:** User logged out on page refresh

**Solution:**
- Verify middleware is configured
- Check cookie settings (httpOnly, secure, sameSite)
- Ensure PKCE flow for SSR

### Provider Token Missing

**Error:** `provider_token` is null

**Solution:**
- Not all providers return refresh tokens
- Provider token is intentionally not stored by Supabase
- Request token during OAuth flow if needed

## Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [PKCE RFC 7636](https://tools.ietf.org/html/rfc7636)
- [Next.js Authentication](https://nextjs.org/docs/authentication)
- [Supabase Examples](https://github.com/supabase/supabase/tree/master/examples)

## Support

For issues or questions:

1. Check the [examples](./examples/) directory
2. Review [Supabase documentation](https://supabase.com/docs)
3. Test with [test-auth-flow.sh](./scripts/test-auth-flow.sh)
4. Review common issues in [oauth-setup-guide.md](./examples/oauth-setup-guide.md#troubleshooting)

## Version

**Version:** 1.0.0
**Plugin:** supabase
**Category:** Authentication
**Type:** Configuration Skill
