// Discord OAuth Configuration for Clerk
// Documentation: https://clerk.com/docs/authentication/social-connections/discord

export const discordOAuthConfig = {
  // Provider identification
  provider: 'discord',
  enabled: true,

  // OAuth credentials from Discord Developer Portal
  clientId: process.env.DISCORD_CLIENT_ID!,
  clientSecret: process.env.DISCORD_CLIENT_SECRET!,

  // Redirect URI (must match Discord OAuth2 configuration)
  redirectUri: process.env.DISCORD_REDIRECT_URI ||
    `${process.env.NEXT_PUBLIC_APP_URL}/api/auth/callback/discord`,

  // Required scopes for basic authentication
  scopes: [
    'identify',  // User identity information
    'email'      // Email address
  ],

  // Discord-specific options
  options: {
    // Bot permissions (set to '0' for OAuth-only, no bot)
    permissions: '0',

    // Disable joining to guild during OAuth
    disableGuildSelect: false,

    // Prompt for authorization on every login
    prompt: 'consent' as const
  }
};

// Optional: Additional scopes for extended functionality
export const discordExtendedScopes = {
  // Guild (server) access
  guilds: [
    'guilds',              // List of guilds user is in
    'guilds.join',         // Join guilds on behalf of user
    'guilds.members.read'  // Read guild member data
  ],

  // Activity and presence
  activities: [
    'activities.read',   // Read user's activity
    'activities.write'   // Update user's activity
  ],

  // Relationships
  relationships: [
    'relationships.read'  // Read user's relationships
  ],

  // Voice
  voice: [
    'voice',        // Join voice channels
    'rpc.voice.read',  // Read voice state
    'rpc.voice.write'  // Update voice state
  ],

  // Messages
  messages: [
    'messages.read',  // Read messages
    'dm_channels.read'  // Read DM channels
  ],

  // Applications
  applications: [
    'applications.builds.read',    // Read build data
    'applications.commands',       // Create/update commands
    'applications.entitlements',   // Read entitlements
    'applications.store.update'    // Update store
  ]
};

// Example usage with Clerk SDK
/*
import { Clerk } from '@clerk/clerk-sdk-node';

const clerk = Clerk({
  apiKey: process.env.CLERK_SECRET_KEY
});

// Configure Discord OAuth provider
await clerk.socialProviders.update('discord', {
  clientId: discordOAuthConfig.clientId,
  clientSecret: discordOAuthConfig.clientSecret,
  scopes: discordOAuthConfig.scopes
});
*/

// Type definitions
export interface DiscordOAuthConfig {
  provider: 'discord';
  enabled: boolean;
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scopes: string[];
  options: {
    permissions: string;
    disableGuildSelect: boolean;
    prompt: 'consent' | 'none';
  };
}

// Validate configuration
export function validateDiscordConfig(): boolean {
  if (!process.env.DISCORD_CLIENT_ID) {
    throw new Error('DISCORD_CLIENT_ID is required');
  }
  if (!process.env.DISCORD_CLIENT_SECRET) {
    throw new Error('DISCORD_CLIENT_SECRET is required');
  }
  return true;
}

// Helper: Get user's Discord profile
export async function getDiscordProfile(accessToken: string) {
  const response = await fetch('https://discord.com/api/v10/users/@me', {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch Discord profile');
  }

  return response.json();
}

// Helper: Get user's Discord guilds (servers)
export async function getDiscordGuilds(accessToken: string) {
  const response = await fetch('https://discord.com/api/v10/users/@me/guilds', {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch Discord guilds');
  }

  return response.json();
}

// Helper: Format Discord avatar URL
export function getDiscordAvatarUrl(userId: string, avatarHash: string): string {
  return `https://cdn.discordapp.com/avatars/${userId}/${avatarHash}.png`;
}
