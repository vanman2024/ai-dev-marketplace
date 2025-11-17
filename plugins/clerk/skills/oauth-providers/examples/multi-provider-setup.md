## Multi-Provider OAuth Setup Example

This example demonstrates how to set up multiple OAuth providers (Google, GitHub, Discord) for a SaaS application using Clerk.

### Prerequisites

- Clerk account and application created
- Node.js 18+ installed
- Next.js project (or other supported framework)

### Step 1: Install Dependencies

```bash
npm install @clerk/nextjs
# or
pnpm add @clerk/nextjs
```

### Step 2: Configure OAuth Providers

Run the setup script for each provider:

```bash
# Set up Google OAuth
bash scripts/setup-provider.sh google

# Set up GitHub OAuth
bash scripts/setup-provider.sh github

# Set up Discord OAuth
bash scripts/setup-provider.sh discord
```

This creates configuration files in `.clerk/providers/` for each provider.

### Step 3: Create OAuth Applications

Follow the setup instructions generated for each provider:

**Google:**
1. Read: `.clerk/providers/google-SETUP.md`
2. Create OAuth app in [Google Cloud Console](https://console.cloud.google.com/)
3. Configure authorized redirect URIs
4. Copy Client ID and Client Secret

**GitHub:**
1. Read: `.clerk/providers/github-SETUP.md`
2. Create OAuth App in [GitHub Settings](https://github.com/settings/developers)
3. Add authorization callback URL
4. Copy Client ID and Client Secret

**Discord:**
1. Read: `.clerk/providers/discord-SETUP.md`
2. Create application in [Discord Developer Portal](https://discord.com/developers/applications)
3. Add redirect URIs in OAuth2 section
4. Copy Client ID and Client Secret

### Step 4: Configure Environment Variables

Create `.env.local` file in your project root:

```bash
# Clerk Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
CLERK_SECRET_KEY=sk_test_your_secret_key_here

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id_from_cloud_console
GOOGLE_CLIENT_SECRET=your_google_client_secret_from_cloud_console
GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/callback/google

# GitHub OAuth
GITHUB_CLIENT_ID=your_github_client_id_from_developer_settings
GITHUB_CLIENT_SECRET=your_github_client_secret_from_developer_settings
GITHUB_REDIRECT_URI=http://localhost:3000/api/auth/callback/github

# Discord OAuth
DISCORD_CLIENT_ID=your_discord_client_id_from_developer_portal
DISCORD_CLIENT_SECRET=your_discord_client_secret_from_developer_portal
DISCORD_REDIRECT_URI=http://localhost:3000/api/auth/callback/discord
```

**IMPORTANT:** Never commit this file to git. Add to `.gitignore`:

```bash
echo '.env.local' >> .gitignore
```

### Step 5: Configure Clerk Dashboard

1. Navigate to [Clerk Dashboard](https://dashboard.clerk.com/)
2. Select your application
3. Go to **User & Authentication** > **Social Connections**
4. For each provider (Google, GitHub, Discord):
   - Toggle the provider ON
   - Paste Client ID
   - Paste Client Secret
   - Save configuration

### Step 6: Add Authentication UI

Copy the auth buttons component:

```bash
cp templates/oauth-shared/AuthButtons.tsx ./components/auth/
```

Create a sign-in page (`app/sign-in/page.tsx`):

```typescript
import { AuthButtons } from '@/components/auth/AuthButtons';

export default function SignInPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full bg-white rounded-lg shadow-lg p-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Welcome back</h1>
          <p className="text-gray-600 mt-2">Sign in to your account</p>
        </div>

        <AuthButtons
          providers={['google', 'github', 'discord']}
          orientation="vertical"
          showDivider={true}
          onSuccess={(userId) => {
            console.log('Successfully authenticated:', userId);
            // Redirect to dashboard
            window.location.href = '/dashboard';
          }}
          onError={(error) => {
            console.error('Authentication error:', error);
          }}
        />

        <p className="text-center text-sm text-gray-500 mt-6">
          Don't have an account?{' '}
          <a href="/sign-up" className="text-blue-600 hover:underline">
            Sign up
          </a>
        </p>
      </div>
    </div>
  );
}
```

### Step 7: Configure Clerk Middleware

Create `middleware.ts` in your project root:

```typescript
import { authMiddleware } from '@clerk/nextjs';

export default authMiddleware({
  // Public routes that don't require authentication
  publicRoutes: ['/', '/sign-in', '/sign-up'],

  // Routes that should always be accessible
  ignoredRoutes: ['/api/webhook'],
});

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)'],
};
```

### Step 8: Test OAuth Flows

Generate redirect URLs for all providers:

```bash
bash scripts/generate-redirect-urls.sh --all
```

Test each provider configuration:

```bash
# Test Google OAuth
bash scripts/test-oauth-flow.sh google

# Test GitHub OAuth
bash scripts/test-oauth-flow.sh github

# Test Discord OAuth
bash scripts/test-oauth-flow.sh discord
```

Or test all at once:

```bash
bash scripts/test-oauth-flow.sh --all --report
```

### Step 9: Test in Browser

1. Start your development server:
   ```bash
   npm run dev
   ```

2. Navigate to `http://localhost:3000/sign-in`

3. Click each OAuth button to test:
   - **Google**: Should redirect to Google login
   - **GitHub**: Should redirect to GitHub authorization
   - **Discord**: Should redirect to Discord authorization

4. Complete the OAuth flow and verify you're redirected back

### Step 10: Production Deployment

Before deploying to production:

1. **Update redirect URIs** in each provider console:
   ```
   https://yourdomain.com/api/auth/callback/google
   https://yourdomain.com/api/auth/callback/github
   https://yourdomain.com/api/auth/callback/discord
   ```

2. **Update environment variables** in production:
   - Vercel: Project Settings > Environment Variables
   - Railway: Variables tab
   - Other: Platform-specific configuration

3. **Test production OAuth flows**:
   ```bash
   # Update .env for production domain
   NEXT_PUBLIC_APP_URL=https://yourdomain.com

   # Generate production redirect URLs
   bash scripts/generate-redirect-urls.sh --all --export > .env.production
   ```

### Troubleshooting

**Redirect URI Mismatch:**
- Verify exact URL match in provider console
- Check for trailing slashes
- Ensure protocol matches (http vs https)

**Invalid Client Credentials:**
- Verify credentials are copied correctly
- Check for whitespace
- Ensure credentials match environment (dev vs prod)

**Provider Not Appearing:**
- Verify provider is enabled in Clerk Dashboard
- Check environment variables are set
- Restart development server

**OAuth Flow Hangs:**
- Check browser console for errors
- Verify redirect URI is accessible
- Check Clerk Dashboard logs

### Security Best Practices

1. **Never commit credentials:**
   - Use `.env.local` for local development
   - Use platform environment variables for production
   - Add all `.env*` files to `.gitignore` (except `.env.example`)

2. **Use HTTPS in production:**
   - Always use HTTPS redirect URIs
   - HTTP only for localhost development

3. **Rotate secrets regularly:**
   - Change OAuth client secrets periodically
   - Update in both provider console and environment

4. **Monitor authentication:**
   - Review Clerk Dashboard logs
   - Set up alerts for failed authentications
   - Track OAuth provider errors

### Next Steps

- Add email/password authentication as fallback
- Implement role-based access control
- Set up user profile management
- Configure session settings
- Add OAuth scope customization for advanced features

### Resources

- [Clerk Documentation](https://clerk.com/docs)
- [Google OAuth Guide](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Guide](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Discord OAuth Guide](https://discord.com/developers/docs/topics/oauth2)
