# Social Authentication Implementation Guide

This guide demonstrates how to implement OAuth provider buttons with Clerk for social authentication.

## Overview

Clerk supports multiple OAuth providers including Google, GitHub, Discord, Microsoft, Facebook, and Apple. This guide shows how to create custom social authentication buttons with proper error handling and loading states.

## Implementation

See `social-buttons.tsx` for complete implementations including:
- Full-width social buttons
- Compact icon-only buttons
- Grid layout for multiple providers

## Supported OAuth Providers

### Major Providers

| Provider | Strategy | Use Case |
|----------|----------|----------|
| Google | `oauth_google` | General consumer apps |
| GitHub | `oauth_github` | Developer tools |
| Microsoft | `oauth_microsoft` | Enterprise apps |
| Discord | `oauth_discord` | Gaming/community apps |
| Facebook | `oauth_facebook` | Social apps |
| Apple | `oauth_apple` | iOS apps, privacy-focused |

## Basic Implementation

```typescript
import { useSignIn } from '@clerk/nextjs'

export function GoogleSignInButton() {
  const { signIn } = useSignIn()

  const signInWithGoogle = async () => {
    await signIn.authenticateWithRedirect({
      strategy: 'oauth_google',
      redirectUrl: '/sso-callback',
      redirectUrlComplete: '/dashboard'
    })
  }

  return (
    <button onClick={signInWithGoogle}>
      Sign in with Google
    </button>
  )
}
```

## Advanced Features

### Loading States

```typescript
const [isLoading, setIsLoading] = useState(false)

const signInWith = async (strategy: OAuthStrategy) => {
  setIsLoading(true)
  try {
    await signIn.authenticateWithRedirect({ strategy })
  } finally {
    setIsLoading(false)
  }
}
```

### Error Handling

```typescript
const [error, setError] = useState<string | null>(null)

try {
  await signIn.authenticateWithRedirect({ strategy })
} catch (err: any) {
  setError(err?.errors?.[0]?.message || 'Authentication failed')
}
```

### Multiple Providers

```typescript
const providers: OAuthStrategy[] = [
  'oauth_google',
  'oauth_github',
  'oauth_discord'
]

return (
  <>
    {providers.map(strategy => (
      <SocialButton
        key={strategy}
        strategy={strategy}
        onClick={() => signInWith(strategy)}
      />
    ))}
  </>
)
```

## Component Variants

### 1. Full-Width Buttons (`SocialAuthButtons`)

Best for dedicated sign-in pages:
- Large touch targets
- Clear provider labels
- Icon + text layout
- Full-width responsive

### 2. Compact Buttons (`CompactSocialButtons`)

Best for headers/navbars:
- Icon-only design
- Minimal space usage
- Tooltip support
- Horizontal layout

### 3. Grid Layout (`SocialButtonGrid`)

Best for multiple providers:
- 2x2 grid layout
- Balanced visual weight
- Icons + short labels
- Responsive columns

## Configuration

### 1. Enable Providers in Clerk Dashboard

1. Go to [Clerk Dashboard](https://dashboard.clerk.com)
2. Select your application
3. Navigate to **User & Authentication** > **Social Connections**
4. Enable desired OAuth providers
5. Configure OAuth credentials for each provider

### 2. OAuth Credentials

Each provider requires:
- **Client ID** (from provider)
- **Client Secret** (from provider)
- **Redirect URI** (provided by Clerk)

### 3. Redirect URLs

Configure in your application:

```typescript
await signIn.authenticateWithRedirect({
  strategy: 'oauth_google',
  redirectUrl: '/sso-callback',        // SSO processing page
  redirectUrlComplete: '/dashboard'    // Final destination
})
```

## SSO Callback Page

Create `app/sso-callback/page.tsx`:

```typescript
'use client'

import { AuthenticateWithRedirectCallback } from '@clerk/nextjs'

export default function SSOCallback() {
  return <AuthenticateWithRedirectCallback />
}
```

## Styling Examples

### Custom Social Button

```typescript
<button
  onClick={() => signInWith('oauth_google')}
  className="flex items-center gap-3 px-4 py-3 border-2 border-gray-300 rounded-lg hover:border-blue-500 transition-colors"
>
  <GoogleIcon />
  <span>Continue with Google</span>
</button>
```

### With Loading State

```typescript
<button disabled={isLoading}>
  {isLoading ? (
    <LoadingSpinner />
  ) : (
    <>
      <GoogleIcon />
      <span>Continue with Google</span>
    </>
  )}
</button>
```

## Best Practices

1. **Provider Selection**: Offer 2-4 providers relevant to your audience
2. **Visual Hierarchy**: Place most popular provider first
3. **Loading Feedback**: Show loading state during OAuth flow
4. **Error Handling**: Display clear error messages
5. **Accessibility**: Include proper ARIA labels
6. **Mobile Optimization**: Large touch targets (min 44x44px)
7. **Brand Guidelines**: Follow each provider's branding rules
8. **Fallback**: Always offer email/password as alternative

## Common Patterns

### OAuth + Email/Password

```tsx
<div>
  {/* Social buttons */}
  <SocialAuthButtons />

  {/* Divider */}
  <div>Or continue with email</div>

  {/* Email/password form */}
  <EmailPasswordForm />
</div>
```

### Mobile-First Design

```tsx
<div className="space-y-3">
  {/* Stack vertically on mobile */}
  <GoogleButton className="w-full" />
  <GitHubButton className="w-full" />
</div>
```

### Conditional Providers

```tsx
const isMobile = /iPhone|iPad|Android/i.test(navigator.userAgent)

{isMobile && <AppleSignInButton />}
{!isMobile && <MicrosoftSignInButton />}
```

## Security Considerations

1. **HTTPS Required**: OAuth only works over HTTPS
2. **CSRF Protection**: Clerk handles CSRF tokens automatically
3. **State Parameter**: Clerk manages OAuth state validation
4. **Redirect Validation**: Configure allowed redirect URLs in dashboard
5. **Token Storage**: Clerk securely stores OAuth tokens

## Troubleshooting

### OAuth Flow Not Starting

- Check provider is enabled in Clerk Dashboard
- Verify OAuth credentials are configured
- Ensure redirect URLs match exactly

### Authentication Fails

- Check browser console for errors
- Verify provider credentials
- Test in incognito mode (clear cookies)
- Check Clerk Dashboard logs

### Redirect Issues

- Verify `redirectUrl` path exists
- Check `redirectUrlComplete` is accessible
- Ensure `/sso-callback` page is created

## Resources

- Full implementation: `social-buttons.tsx`
- [Clerk OAuth Documentation](https://clerk.com/docs/authentication/social-connections)
- [OAuth Provider Setup](https://clerk.com/docs/authentication/social-connections/oauth)
- [Google OAuth Setup](https://clerk.com/docs/authentication/social-connections/google)
- [GitHub OAuth Setup](https://clerk.com/docs/authentication/social-connections/github)
