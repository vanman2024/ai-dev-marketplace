// Apple OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/apple

export const appleOAuthConfig = {
  // Provider identification
  provider: 'apple',
  enabled: true,

  // OAuth credentials from Apple Developer Portal
  clientId: process.env.APPLE_CLIENT_ID!, // Service ID
  clientSecret: process.env.APPLE_CLIENT_SECRET!, // Generated from private key

  // Redirect URI (must match Apple configuration)
  redirectUri: process.env.APPLE_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/apple`,

  // Required scopes for Apple Sign In
  scopes: [
    'name',   // User's name (first name, last name)
    'email'   // Email address
  ],

  // Apple-specific options
  options: {
    // Response mode (Apple requires form_post)
    responseMode: 'form_post' as const,

    // Response type
    responseType: 'code id_token' as const
  }
};

// Type definitions
export interface AppleOAuthConfig {
  provider: 'apple';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    responseMode: 'form_post' | 'query' | 'fragment';
    responseType: 'code' | 'code id_token';
  };
}

// Validate configuration
export function validateAppleConfig(): boolean {
  if (!process.env.APPLE_CLIENT_ID) {
    throw new Error('APPLE_CLIENT_ID (Service ID) is required');
  }
  if (!process.env.APPLE_CLIENT_SECRET) {
    throw new Error('APPLE_CLIENT_SECRET is required');
  }
  return true;
}
