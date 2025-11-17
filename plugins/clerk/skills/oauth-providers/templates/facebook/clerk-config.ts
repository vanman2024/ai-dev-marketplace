// Facebook OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/facebook

export const facebookOAuthConfig = {
  // Provider identification
  provider: 'facebook',
  enabled: true,

  // OAuth credentials from Facebook Developer Console
  clientId: process.env.FACEBOOK_CLIENT_ID!, // App ID
  clientSecret: process.env.FACEBOOK_CLIENT_SECRET!, // App Secret

  // Redirect URI
  redirectUri: process.env.FACEBOOK_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/facebook`,

  // Required permissions
  scopes: [
    'email',          // Email address
    'public_profile'  // Public profile information
  ],

  // Facebook-specific options
  options: {
    // API version
    apiVersion: 'v18.0',

    // Display type for auth dialog
    display: 'page' as const
  }
};

// Type definitions
export interface FacebookOAuthConfig {
  provider: 'facebook';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    apiVersion: string;
    display: 'page' | 'popup' | 'touch' | 'wap';
  };
}

// Validate configuration
export function validateFacebookConfig(): boolean {
  if (!process.env.FACEBOOK_CLIENT_ID) {
    throw new Error('FACEBOOK_CLIENT_ID (App ID) is required');
  }
  if (!process.env.FACEBOOK_CLIENT_SECRET) {
    throw new Error('FACEBOOK_CLIENT_SECRET (App Secret) is required');
  }
  return true;
}
