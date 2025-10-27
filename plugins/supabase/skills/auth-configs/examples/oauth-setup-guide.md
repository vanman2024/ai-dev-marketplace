# OAuth Provider Setup Guide

Complete step-by-step guide for setting up OAuth authentication with Supabase.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Google OAuth Setup](#google-oauth-setup)
3. [GitHub OAuth Setup](#github-oauth-setup)
4. [Discord OAuth Setup](#discord-oauth-setup)
5. [Testing Your Setup](#testing-your-setup)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before setting up OAuth providers, ensure you have:

- ✅ Active Supabase project
- ✅ Supabase project URL and keys
- ✅ Development environment set up (Node.js 18+)
- ✅ Basic understanding of OAuth 2.0 flow

### Environment Variables

Create `.env.local` in your project root:

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# OAuth Providers (add as you configure them)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
DISCORD_CLIENT_ID=
DISCORD_CLIENT_SECRET=
```

**⚠️ Security:** Add `.env.local` to `.gitignore` to prevent committing secrets!

---

## Google OAuth Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Note your Project ID

### Step 2: Enable APIs

1. Navigate to **APIs & Services** > **Library**
2. Search for "Google+ API" (or "People API")
3. Click **Enable**

### Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Choose **External** (or Internal for Workspace)
3. Fill in required fields:
   - **App name**: Your application name
   - **User support email**: Your email
   - **Developer contact**: Your email
4. Add scopes:
   - `email`
   - `profile`
   - `openid`
5. Add test users (during development)
6. Click **Save and Continue**

### Step 4: Create OAuth Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Web application**
4. Configure:
   - **Name**: "Supabase Auth"
   - **Authorized JavaScript origins**:
     ```
     http://localhost:3000
     https://yourdomain.com
     ```
   - **Authorized redirect URIs**:
     ```
     https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
     http://localhost:3000/auth/callback
     ```
5. Click **Create**
6. Copy **Client ID** and **Client Secret**

### Step 5: Configure in Supabase

1. Open Supabase Dashboard
2. Go to **Authentication** > **Providers**
3. Find **Google** and enable it
4. Paste:
   - Client ID from Google Cloud Console
   - Client Secret from Google Cloud Console
5. Click **Save**

### Step 6: Test Google OAuth

Use the setup script:

```bash
bash /path/to/skills/auth-configs/scripts/setup-oauth-provider.sh google
```

Or test manually:

```typescript
// In your app
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'http://localhost:3000/auth/callback',
  }
})
```

---

## GitHub OAuth Setup

### Step 1: Create OAuth App

1. Go to [GitHub Settings](https://github.com/settings/developers)
2. Click **OAuth Apps** > **New OAuth App**

### Step 2: Configure Application

Fill in application details:

- **Application name**: Your app name
- **Homepage URL**: `https://yourdomain.com`
- **Authorization callback URL**:
  ```
  https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
  ```

### Step 3: Generate Client Secret

1. Click **Register application**
2. Click **Generate a new client secret**
3. Copy both:
   - Client ID
   - Client Secret (save immediately, won't be shown again)

### Step 4: Configure in Supabase

1. Supabase Dashboard > **Authentication** > **Providers**
2. Enable **GitHub**
3. Paste Client ID and Client Secret
4. Click **Save**

### Step 5: Test GitHub OAuth

```bash
bash /path/to/skills/auth-configs/scripts/setup-oauth-provider.sh github
```

### Advanced: GitHub App vs OAuth App

For enhanced features, consider GitHub App:

**OAuth App:**
- Simpler setup
- User authentication only
- Basic user data access

**GitHub App:**
- Fine-grained permissions
- Webhooks support
- Organization installation
- Higher rate limits

**When to use GitHub App:**
- Need repository access
- Organization-wide installation
- Webhook integrations
- Advanced GitHub API features

---

## Discord OAuth Setup

### Step 1: Create Discord Application

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **New Application**
3. Enter application name
4. Click **Create**

### Step 2: Configure OAuth2

1. Navigate to **OAuth2** section
2. Add redirect URIs:
   ```
   https://YOUR-PROJECT-REF.supabase.co/auth/v1/callback
   http://localhost:3000/auth/callback
   ```
3. Click **Save Changes**

### Step 3: Get Credentials

1. Copy **Client ID**
2. Click **Reset Secret** to generate new secret
3. Copy **Client Secret** immediately

### Step 4: Configure Scopes (Optional)

Default scopes (`identify` and `email`) are sufficient for authentication.

Optional scopes:
- `guilds` - See user's Discord servers
- `guilds.join` - Join user to a Discord server
- `connections` - See user's connections (Twitch, YouTube, etc)

### Step 5: Configure in Supabase

1. Supabase Dashboard > **Authentication** > **Providers**
2. Enable **Discord**
3. Paste Client ID and Client Secret
4. Click **Save**

### Step 6: Test Discord OAuth

```bash
bash /path/to/skills/auth-configs/scripts/setup-oauth-provider.sh discord
```

---

## Testing Your Setup

### Automated Testing

Run comprehensive auth flow tests:

```bash
# Test all configured providers
bash /path/to/skills/auth-configs/scripts/test-auth-flow.sh --all

# Test specific provider
bash /path/to/skills/auth-configs/scripts/test-auth-flow.sh google
```

### Manual Testing

1. **Start your development server:**
   ```bash
   npm run dev
   ```

2. **Create a login button:**
   ```typescript
   // components/LoginButton.tsx
   'use client'

   import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'

   export function LoginButton({ provider }: { provider: 'google' | 'github' | 'discord' }) {
     const supabase = createClientComponentClient()

     const handleLogin = async () => {
       await supabase.auth.signInWithOAuth({
         provider,
         options: {
           redirectTo: `${window.location.origin}/auth/callback`,
         },
       })
     }

     return (
       <button onClick={handleLogin}>
         Sign in with {provider}
       </button>
     )
   }
   ```

3. **Create callback route:**
   ```typescript
   // app/auth/callback/route.ts
   import { createRouteHandlerClient } from '@supabase/auth-helpers-nextjs'
   import { cookies } from 'next/headers'
   import { NextResponse } from 'next/server'

   export async function GET(request: Request) {
     const requestUrl = new URL(request.url)
     const code = requestUrl.searchParams.get('code')

     if (code) {
       const supabase = createRouteHandlerClient({ cookies })
       await supabase.auth.exchangeCodeForSession(code)
     }

     return NextResponse.redirect(requestUrl.origin + '/dashboard')
   }
   ```

4. **Test the flow:**
   - Click login button
   - Authorize with provider
   - Verify redirect to callback
   - Check user session

---

## Troubleshooting

### Common Issues

#### Redirect URI Mismatch

**Error:** `redirect_uri_mismatch`

**Solution:**
- Verify redirect URI in provider console EXACTLY matches Supabase callback URL
- Include protocol (https://)
- No trailing slashes
- Check for typos in project reference ID

#### OAuth Consent Not Configured

**Error:** `invalid_client` or consent screen error

**Solution:**
- Configure OAuth consent screen in provider console
- Add required scopes
- Add test users during development
- Publish app for production

#### Missing Email Permission

**Error:** Email is `null` or `undefined`

**Solution:**
- Ensure `email` scope is requested
- Check user has verified email with provider
- Some providers require explicit permission for email access

#### Token Exchange Failed

**Error:** `invalid_grant` or session error

**Solution:**
- Verify callback route is handling code exchange
- Check Supabase project URL is correct
- Ensure cookies are enabled
- Clear browser cookies and try again

#### CORS Errors

**Error:** CORS policy blocked request

**Solution:**
- Add origin to authorized domains in provider console
- Check Next.js middleware isn't blocking requests
- Verify Supabase project settings allow your domain

### Debug Mode

Enable debug logging:

```typescript
// In your app
const supabase = createClientComponentClient({
  auth: {
    debug: true, // Enable debug logs
  },
})
```

### Check Provider Status

Verify provider is enabled in Supabase:

```bash
curl "https://YOUR-PROJECT.supabase.co/auth/v1/settings" \
  -H "apikey: YOUR-ANON-KEY"
```

Response should show provider configuration:

```json
{
  "external": {
    "google": true,
    "github": true,
    "discord": true
  }
}
```

---

## Next Steps

1. ✅ **Configure Multiple Providers**: Set up Google, GitHub, and Discord
2. ✅ **Add Email Auth**: Implement email/password as fallback
3. ✅ **Customize Email Templates**: Brand your authentication emails
4. ✅ **Implement Middleware**: Add route protection
5. ✅ **Add User Profiles**: Store additional user data
6. ✅ **Configure RLS**: Secure database with row-level security

## Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Next.js Authentication Patterns](https://nextjs.org/docs/authentication)
- [Testing Auth Flows](./auth-flows.md)
- [AI App Auth Patterns](./ai-app-patterns.md)
