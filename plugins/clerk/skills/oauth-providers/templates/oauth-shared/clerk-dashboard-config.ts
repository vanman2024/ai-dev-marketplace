// Clerk Dashboard OAuth Configuration
// Use this as a reference when configuring providers in Clerk Dashboard

export interface OAuthProviderConfig {
  provider: string;
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  scopes: string[];
  redirectUri?: string;
  options?: Record<string, any>;
}

// All supported OAuth providers with default configurations
export const oauthProviders: OAuthProviderConfig[] = [
  // Tier 1: Most Common Providers
  {
    provider: 'google',
    enabled: true,
    clientId: process.env.GOOGLE_CLIENT_ID!,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    scopes: ['profile', 'email', 'openid'],
    options: {
      accessType: 'offline',
      prompt: 'consent'
    }
  },
  {
    provider: 'github',
    enabled: true,
    clientId: process.env.GITHUB_CLIENT_ID!,
    clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    scopes: ['read:user', 'user:email'],
    options: {
      allowSignup: true
    }
  },
  {
    provider: 'discord',
    enabled: true,
    clientId: process.env.DISCORD_CLIENT_ID!,
    clientSecret: process.env.DISCORD_CLIENT_SECRET!,
    scopes: ['identify', 'email'],
    options: {
      permissions: '0'
    }
  },
  {
    provider: 'microsoft',
    enabled: false,
    clientId: process.env.MICROSOFT_CLIENT_ID || 'microsoft_dev_your_client_id_here',
    clientSecret: process.env.MICROSOFT_CLIENT_SECRET || 'microsoft_dev_your_client_secret_here',
    scopes: ['openid', 'profile', 'email', 'User.Read'],
    options: {
      tenant: 'common'
    }
  },

  // Tier 2: Social & Professional
  {
    provider: 'facebook',
    enabled: false,
    clientId: process.env.FACEBOOK_CLIENT_ID || 'facebook_dev_your_client_id_here',
    clientSecret: process.env.FACEBOOK_CLIENT_SECRET || 'facebook_dev_your_client_secret_here',
    scopes: ['email', 'public_profile']
  },
  {
    provider: 'linkedin',
    enabled: false,
    clientId: process.env.LINKEDIN_CLIENT_ID || 'linkedin_dev_your_client_id_here',
    clientSecret: process.env.LINKEDIN_CLIENT_SECRET || 'linkedin_dev_your_client_secret_here',
    scopes: ['r_liteprofile', 'r_emailaddress']
  },
  {
    provider: 'twitter',
    enabled: false,
    clientId: process.env.TWITTER_CLIENT_ID || 'twitter_dev_your_client_id_here',
    clientSecret: process.env.TWITTER_CLIENT_SECRET || 'twitter_dev_your_client_secret_here',
    scopes: ['users.read', 'tweet.read']
  },
  {
    provider: 'apple',
    enabled: false,
    clientId: process.env.APPLE_CLIENT_ID || 'apple_dev_your_client_id_here',
    clientSecret: process.env.APPLE_CLIENT_SECRET || 'apple_dev_your_client_secret_here',
    scopes: ['name', 'email'],
    options: {
      responseMode: 'form_post'
    }
  },

  // Tier 3: Specialized Providers
  {
    provider: 'gitlab',
    enabled: false,
    clientId: process.env.GITLAB_CLIENT_ID || 'gitlab_dev_your_client_id_here',
    clientSecret: process.env.GITLAB_CLIENT_SECRET || 'gitlab_dev_your_client_secret_here',
    scopes: ['read_user', 'email']
  },
  {
    provider: 'bitbucket',
    enabled: false,
    clientId: process.env.BITBUCKET_CLIENT_ID || 'bitbucket_dev_your_client_id_here',
    clientSecret: process.env.BITBUCKET_CLIENT_SECRET || 'bitbucket_dev_your_client_secret_here',
    scopes: ['account', 'email']
  },
  {
    provider: 'slack',
    enabled: false,
    clientId: process.env.SLACK_CLIENT_ID || 'slack_dev_your_client_id_here',
    clientSecret: process.env.SLACK_CLIENT_SECRET || 'slack_dev_your_client_secret_here',
    scopes: ['identity.basic', 'identity.email']
  },
  {
    provider: 'notion',
    enabled: false,
    clientId: process.env.NOTION_CLIENT_ID || 'notion_dev_your_client_id_here',
    clientSecret: process.env.NOTION_CLIENT_SECRET || 'notion_dev_your_client_secret_here',
    scopes: ['read_user']
  },
  {
    provider: 'linear',
    enabled: false,
    clientId: process.env.LINEAR_CLIENT_ID || 'linear_dev_your_client_id_here',
    clientSecret: process.env.LINEAR_CLIENT_SECRET || 'linear_dev_your_client_secret_here',
    scopes: ['read']
  },
  {
    provider: 'dropbox',
    enabled: false,
    clientId: process.env.DROPBOX_CLIENT_ID || 'dropbox_dev_your_client_id_here',
    clientSecret: process.env.DROPBOX_CLIENT_SECRET || 'dropbox_dev_your_client_secret_here',
    scopes: ['account_info.read']
  },
  {
    provider: 'twitch',
    enabled: false,
    clientId: process.env.TWITCH_CLIENT_ID || 'twitch_dev_your_client_id_here',
    clientSecret: process.env.TWITCH_CLIENT_SECRET || 'twitch_dev_your_client_secret_here',
    scopes: ['user:read:email']
  },
  {
    provider: 'tiktok',
    enabled: false,
    clientId: process.env.TIKTOK_CLIENT_ID || 'tiktok_dev_your_client_id_here',
    clientSecret: process.env.TIKTOK_CLIENT_SECRET || 'tiktok_dev_your_client_secret_here',
    scopes: ['user.info.basic']
  },
  {
    provider: 'coinbase',
    enabled: false,
    clientId: process.env.COINBASE_CLIENT_ID || 'coinbase_dev_your_client_id_here',
    clientSecret: process.env.COINBASE_CLIENT_SECRET || 'coinbase_dev_your_client_secret_here',
    scopes: ['wallet:user:read', 'wallet:user:email']
  },
  {
    provider: 'hubspot',
    enabled: false,
    clientId: process.env.HUBSPOT_CLIENT_ID || 'hubspot_dev_your_client_id_here',
    clientSecret: process.env.HUBSPOT_CLIENT_SECRET || 'hubspot_dev_your_client_secret_here',
    scopes: ['oauth']
  }
];

// Helper: Get enabled providers
export function getEnabledProviders(): OAuthProviderConfig[] {
  return oauthProviders.filter(p => p.enabled);
}

// Helper: Get provider configuration by name
export function getProviderConfig(provider: string): OAuthProviderConfig | undefined {
  return oauthProviders.find(p => p.provider === provider);
}

// Helper: Validate all enabled providers have credentials
export function validateProviders(): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  for (const provider of getEnabledProviders()) {
    const upperProvider = provider.provider.toUpperCase();

    if (!provider.clientId || provider.clientId.includes('your_client_id_here')) {
      errors.push(`${provider.provider}: Missing or placeholder CLIENT_ID`);
    }

    if (!provider.clientSecret || provider.clientSecret.includes('your_client_secret_here')) {
      errors.push(`${provider.provider}: Missing or placeholder CLIENT_SECRET`);
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

// Helper: Generate environment variable template
export function generateEnvTemplate(): string {
  let template = '# OAuth Provider Credentials\n';
  template += '# DO NOT commit actual credentials - use placeholders only\n\n';

  for (const provider of oauthProviders) {
    const upperProvider = provider.provider.toUpperCase();
    template += `# ${provider.provider.charAt(0).toUpperCase() + provider.provider.slice(1)} OAuth\n`;
    template += `${upperProvider}_CLIENT_ID=${provider.provider}_dev_your_client_id_here\n`;
    template += `${upperProvider}_CLIENT_SECRET=${provider.provider}_dev_your_client_secret_here\n`;
    template += `${upperProvider}_REDIRECT_URI=http://localhost:3000/api/auth/callback/${provider.provider}\n\n`;
  }

  return template;
}

// Type guard: Check if provider is supported
export function isSupportedProvider(provider: string): boolean {
  return oauthProviders.some(p => p.provider === provider);
}

// Export provider names for type safety
export const SUPPORTED_PROVIDERS = oauthProviders.map(p => p.provider) as const;
export type SupportedProvider = typeof SUPPORTED_PROVIDERS[number];
