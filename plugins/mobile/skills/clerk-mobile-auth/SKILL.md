# clerk-mobile-auth

Clerk authentication patterns for React Native/Expo apps.

## Contents

- Expo SDK integration
- Token cache with SecureStore
- Sign-in/sign-up flows
- OAuth providers (Google, Apple)
- Protected routes

## Usage

Reference this skill when implementing Clerk auth in mobile apps.

## Key Patterns

### Setup
- ClerkProvider with publishableKey
- tokenCache using expo-secure-store
- ClerkLoaded wrapper

### Authentication
- useSignIn, useSignUp hooks
- Email verification flow
- Error handling

### OAuth
- useOAuth hook
- expo-web-browser for OAuth flow
- expo-linking for redirects

### Protection
- useAuth for auth state
- Redirect component for guards
- Protected route groups

## Security

- Use SecureStore for token storage
- Never log auth tokens
- HTTPS only
- Placeholder keys in .env.example
