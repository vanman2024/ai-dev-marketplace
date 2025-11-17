// Twitter/X OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/twitter

export const twitterOAuthConfig = {
  // Provider identification
  provider: 'twitter',
  enabled: true,

  // OAuth credentials from Twitter Developer Portal
  clientId: process.env.TWITTER_CLIENT_ID!,
  clientSecret: process.env.TWITTER_CLIENT_SECRET!,

  // Redirect URI
  redirectUri: process.env.TWITTER_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/twitter`,

  // Required scopes (OAuth 2.0)
  scopes: [
    'users.read',   // Read user profile
    'tweet.read'    // Read tweets
  ],

  // Twitter-specific options
  options: {
    // OAuth version (use 2.0)
    version: '2.0' as const
  }
};

// Type definitions
export interface TwitterOAuthConfig {
  provider: 'twitter';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    version: '1.0a' | '2.0';
  };
}

// Validate configuration
export function validateTwitterConfig(): boolean {
  if (!process.env.TWITTER_CLIENT_ID) {
    throw new Error('TWITTER_CLIENT_ID is required');
  }
  if (!process.env.TWITTER_CLIENT_SECRET) {
    throw new Error('TWITTER_CLIENT_SECRET is required');
  }
  return true;
}
