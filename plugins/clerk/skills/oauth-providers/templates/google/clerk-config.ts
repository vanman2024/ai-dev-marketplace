// Google OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/google

export const googleOAuthConfig = {
  // Provider identification
  provider: 'google',
  enabled: true,

  // OAuth credentials from Google Cloud Console
  clientId: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,

  // Redirect URI (must match Google Cloud Console configuration)
  redirectUri: process.env.GOOGLE_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/google`,

  // Required scopes for basic authentication
  scopes: [
    'profile',    // User profile information
    'email',      // Email address
    'openid'      // OpenID Connect authentication
  ],

  // Google-specific options
  options: {
    // Request offline access for refresh tokens
    accessType: 'offline' as const,

    // Force consent screen on every login
    prompt: 'consent' as const,

    // Include granted scopes in token response
    includeGrantedScopes: true,

    // Use stable Google Account ID
    stableId: true
  }
};

// Example usage with Clerk SDK
/*
import { Clerk } from '@clerk/clerk-sdk-node';

const clerk = Clerk({
  apiKey: process.env.CLERK_SECRET_KEY
});

// Configure Google OAuth provider
await clerk.socialProviders.update('google', {
  clientId: googleOAuthConfig.clientId,
  clientSecret: googleOAuthConfig.clientSecret,
  scopes: googleOAuthConfig.scopes
});
*/

// Type definitions
export interface GoogleOAuthConfig {
  provider: 'google';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    accessType: 'offline' | 'online';
    prompt: 'consent' | 'select_account' | 'none';
    includeGrantedScopes: boolean;
    stableId: boolean;
  };
}

// Validate configuration
export function validateGoogleConfig(): boolean {
  if (!process.env.GOOGLE_CLIENT_ID) {
    throw new Error('GOOGLE_CLIENT_ID is required');
  }
  if (!process.env.GOOGLE_CLIENT_SECRET) {
    throw new Error('GOOGLE_CLIENT_SECRET is required');
  }
  return true;
}
