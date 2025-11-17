// LinkedIn OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/linkedin

export const linkedinOAuthConfig = {
  // Provider identification
  provider: 'linkedin',
  enabled: true,

  // OAuth credentials from LinkedIn Developer Console
  clientId: process.env.LINKEDIN_CLIENT_ID!,
  clientSecret: process.env.LINKEDIN_CLIENT_SECRET!,

  // Redirect URI
  redirectUri: process.env.LINKEDIN_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/linkedin`,

  // Required scopes
  scopes: [
    'r_liteprofile',   // Profile information
    'r_emailaddress'   // Email address
  ],

  // LinkedIn-specific options
  options: {}
};

// Type definitions
export interface LinkedInOAuthConfig {
  provider: 'linkedin';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: Record<string, never>;
}

// Validate configuration
export function validateLinkedInConfig(): boolean {
  if (!process.env.LINKEDIN_CLIENT_ID) {
    throw new Error('LINKEDIN_CLIENT_ID is required');
  }
  if (!process.env.LINKEDIN_CLIENT_SECRET) {
    throw new Error('LINKEDIN_CLIENT_SECRET is required');
  }
  return true;
}
