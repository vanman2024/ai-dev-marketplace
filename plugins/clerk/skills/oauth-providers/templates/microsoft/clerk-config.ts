// Microsoft OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/microsoft

export const microsoftOAuthConfig = {
  // Provider identification
  provider: 'microsoft',
  enabled: true,

  // OAuth credentials from Azure AD Portal
  clientId: process.env.MICROSOFT_CLIENT_ID!,
  clientSecret: process.env.MICROSOFT_CLIENT_SECRET!,

  // Redirect URI (must match Azure AD configuration)
  redirectUri: process.env.MICROSOFT_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/microsoft`,

  // Required scopes for Microsoft Graph API
  scopes: [
    'openid',      // OpenID Connect authentication
    'profile',     // User profile information
    'email',       // Email address
    'User.Read'    // Microsoft Graph API user read
  ],

  // Microsoft-specific options
  options: {
    // Azure AD tenant ID
    // 'common' - Multi-tenant and personal Microsoft accounts
    // 'organizations' - Multi-tenant organizational accounts only
    // 'consumers' - Personal Microsoft accounts only
    // Or specific tenant ID for single-tenant apps
    tenant: process.env.MICROSOFT_TENANT_ID || 'common',

    // Prompt behavior
    prompt: 'select_account' as const,

    // Domain hint for faster login
    domainHint: process.env.MICROSOFT_DOMAIN_HINT,

    // Response mode
    responseMode: 'query' as const
  }
};

// Optional: Additional Microsoft Graph scopes
export const microsoftExtendedScopes = {
  // Calendar access
  calendar: [
    'Calendars.Read',
    'Calendars.ReadWrite'
  ],

  // Email access
  mail: [
    'Mail.Read',
    'Mail.ReadWrite',
    'Mail.Send'
  ],

  // OneDrive access
  files: [
    'Files.Read',
    'Files.ReadWrite',
    'Files.Read.All'
  ],

  // Teams access
  teams: [
    'Team.ReadBasic.All',
    'Channel.ReadBasic.All'
  ],

  // Groups access
  groups: [
    'Group.Read.All',
    'Group.ReadWrite.All'
  ]
};

// Type definitions
export interface MicrosoftOAuthConfig {
  provider: 'microsoft';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    tenant: string;
    prompt: 'login' | 'none' | 'consent' | 'select_account';
    domainHint?: string;
    responseMode: 'query' | 'fragment' | 'form_post';
  };
}

// Validate configuration
export function validateMicrosoftConfig(): boolean {
  if (!process.env.MICROSOFT_CLIENT_ID) {
    throw new Error('MICROSOFT_CLIENT_ID is required');
  }
  if (!process.env.MICROSOFT_CLIENT_SECRET) {
    throw new Error('MICROSOFT_CLIENT_SECRET is required');
  }
  return true;
}

// Helper: Get Microsoft Graph user profile
export async function getMicrosoftProfile(accessToken: string) {
  const response = await fetch('https://graph.microsoft.com/v1.0/me', {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch Microsoft profile');
  }

  return response.json();
}

// Helper: Get user's profile photo
export async function getMicrosoftPhoto(accessToken: string): Promise<string> {
  const response = await fetch('https://graph.microsoft.com/v1.0/me/photo/$value', {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  if (!response.ok) {
    return ''; // No photo available
  }

  const blob = await response.blob();
  return URL.createObjectURL(blob);
}
