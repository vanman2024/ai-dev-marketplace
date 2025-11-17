// GitHub OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/github

export const githubOAuthConfig = {
  // Provider identification
  provider: 'github',
  enabled: true,

  // OAuth credentials from GitHub Developer Settings
  clientId: process.env.GITHUB_CLIENT_ID!,
  clientSecret: process.env.GITHUB_CLIENT_SECRET!,

  // Redirect URI (must match GitHub OAuth App configuration)
  redirectUri: process.env.GITHUB_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/github`,

  // Required scopes for basic authentication
  scopes: [
    'read:user',   // Read user profile data
    'user:email'   // Access email addresses
  ],

  // GitHub-specific options
  options: {
    // Allow users to sign up during OAuth
    allowSignup: true,

    // Request private email if public email not available
    requestPrivateEmail: true
  }
};

// Optional: Additional scopes for extended functionality
export const githubExtendedScopes = {
  // Repository access
  repositories: [
    'repo',           // Full repository access
    'public_repo',    // Public repository access only
    'repo:status',    // Commit status access
    'repo_deployment' // Deployment status access
  ],

  // Organization access
  organizations: [
    'read:org',   // Read organization data
    'write:org'   // Modify organization data
  ],

  // Gist access
  gists: [
    'gist'  // Create and modify gists
  ]
};

// Example usage with Clerk SDK
/*
import { Clerk } from '@clerk/clerk-sdk-node';

const clerk = Clerk({
  apiKey: process.env.CLERK_SECRET_KEY
});

// Configure GitHub OAuth provider
await clerk.socialProviders.update('github', {
  clientId: githubOAuthConfig.clientId,
  clientSecret: githubOAuthConfig.clientSecret,
  scopes: githubOAuthConfig.scopes
});
*/

// Type definitions
export interface GitHubOAuthConfig {
  provider: 'github';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    allowSignup: boolean;
    requestPrivateEmail: boolean;
  };
}

// Validate configuration
export function validateGitHubConfig(): boolean {
  if (!process.env.GITHUB_CLIENT_ID) {
    throw new Error('GITHUB_CLIENT_ID is required');
  }
  if (!process.env.GITHUB_CLIENT_SECRET) {
    throw new Error('GITHUB_CLIENT_SECRET is required');
  }
  return true;
}

// Helper: Get user's GitHub profile
export async function getGitHubProfile(accessToken: string) {
  const response = await fetch('https://api.github.com/user', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/vnd.github.v3+json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch GitHub profile');
  }

  return response.json();
}

// Helper: Get user's primary email
export async function getGitHubEmail(accessToken: string): Promise<string> {
  const response = await fetch('https://api.github.com/user/emails', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/vnd.github.v3+json'
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch GitHub emails');
  }

  const emails = await response.json();
  const primaryEmail = emails.find((email: any) => email.primary);

  return primaryEmail?.email || emails[0]?.email;
}
