## Gaming Platform OAuth Setup Example

This example demonstrates how to configure Discord and Twitch OAuth for a gaming platform or community application.

### Use Case

Gaming community platform requiring:
- Discord authentication for community members
- Twitch integration for streamers
- Server/guild membership tracking
- Streaming status integration

### Prerequisites

- Clerk account configured
- Discord application created
- Twitch application registered
- Next.js or React application

### Step 1: Configure Discord OAuth

```bash
# Set up Discord provider
bash scripts/setup-provider.sh discord
```

#### 1.1 Create Discord Application

1. Navigate to [Discord Developer Portal](https://discord.com/developers/applications)
2. Click **New Application**
3. **Name:** Your Gaming Platform
4. Click **Create**

#### 1.2 Configure OAuth2

1. Select your application
2. Go to **OAuth2** section
3. **Redirects:**
   - Add: `http://localhost:3000/api/auth/callback/discord`
   - Add: `https://yourdomain.com/api/auth/callback/discord`
4. **OAuth2 URL Generator:**
   - Scopes: `identify`, `email`, `guilds`
   - Copy generated URL for testing

#### 1.3 Get Credentials

1. Go to **OAuth2** > **General**
2. Copy **Client ID**
3. Click **Reset Secret** and copy **Client Secret**

### Step 2: Configure Twitch OAuth

```bash
# Set up Twitch provider
bash scripts/setup-provider.sh twitch
```

#### 2.1 Register Twitch Application

1. Navigate to [Twitch Developer Console](https://dev.twitch.tv/console/apps)
2. Click **Register Your Application**
3. **Name:** Your Gaming Platform
4. **OAuth Redirect URLs:**
   - Add: `http://localhost:3000/api/auth/callback/twitch`
   - Add: `https://yourdomain.com/api/auth/callback/twitch`
5. **Category:** Website Integration
6. Click **Create**

#### 2.2 Get Credentials

1. Click **Manage** on your application
2. Copy **Client ID**
3. Click **New Secret** and copy **Client Secret**

### Step 3: Environment Configuration

Create `.env.local`:

```bash
# Clerk Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
CLERK_SECRET_KEY=sk_test_your_secret_key_here

# Discord OAuth
DISCORD_CLIENT_ID=your_discord_client_id
DISCORD_CLIENT_SECRET=your_discord_client_secret
DISCORD_REDIRECT_URI=http://localhost:3000/api/auth/callback/discord

# Twitch OAuth
TWITCH_CLIENT_ID=your_twitch_client_id
TWITCH_CLIENT_SECRET=your_twitch_client_secret
TWITCH_REDIRECT_URI=http://localhost:3000/api/auth/callback/twitch

# Application
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### Step 4: Configure Clerk Dashboard

1. Navigate to [Clerk Dashboard](https://dashboard.clerk.com/)
2. **User & Authentication** > **Social Connections**

**Discord:**
- Enable Discord provider
- Paste Client ID
- Paste Client Secret
- Save

**Twitch:**
- Enable Twitch provider
- Paste Client ID
- Paste Client Secret
- Save

### Step 5: Create Gaming Auth Component

Create `components/auth/GamingAuth.tsx`:

```typescript
'use client';

import { SignIn } from '@clerk/nextjs';
import { useState } from 'react';

export function GamingAuth() {
  const [activeTab, setActiveTab] = useState<'player' | 'streamer'>('player');

  return (
    <div className="max-w-md mx-auto bg-gray-900 rounded-lg p-8">
      {/* Tab Selection */}
      <div className="flex gap-4 mb-6">
        <button
          onClick={() => setActiveTab('player')}
          className={`
            flex-1 py-3 rounded-lg font-medium transition-all
            ${activeTab === 'player'
              ? 'bg-indigo-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'}
          `}
        >
          🎮 Player
        </button>
        <button
          onClick={() => setActiveTab('streamer')}
          className={`
            flex-1 py-3 rounded-lg font-medium transition-all
            ${activeTab === 'streamer'
              ? 'bg-purple-600 text-white'
              : 'bg-gray-800 text-gray-400 hover:text-white'}
          `}
        >
          📡 Streamer
        </button>
      </div>

      {/* Authentication Buttons */}
      <SignIn.Root>
        <SignIn.Step name="start">
          <div className="space-y-3">
            {activeTab === 'player' && (
              <>
                <SignIn.Strategy name="oauth_discord">
                  <button
                    type="button"
                    className="
                      w-full px-6 py-4 rounded-lg font-medium
                      flex items-center justify-center gap-3
                      bg-indigo-600 hover:bg-indigo-700
                      text-white transition-all
                    "
                  >
                    <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                      {/* Discord icon SVG */}
                    </svg>
                    <span>Sign in with Discord</span>
                  </button>
                </SignIn.Strategy>

                <p className="text-center text-sm text-gray-400 mt-4">
                  Join your gaming community with Discord
                </p>
              </>
            )}

            {activeTab === 'streamer' && (
              <>
                <SignIn.Strategy name="oauth_twitch">
                  <button
                    type="button"
                    className="
                      w-full px-6 py-4 rounded-lg font-medium
                      flex items-center justify-center gap-3
                      bg-purple-600 hover:bg-purple-700
                      text-white transition-all
                    "
                  >
                    <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                      {/* Twitch icon SVG */}
                    </svg>
                    <span>Sign in with Twitch</span>
                  </button>
                </SignIn.Strategy>

                <SignIn.Strategy name="oauth_discord">
                  <button
                    type="button"
                    className="
                      w-full px-6 py-4 rounded-lg font-medium
                      flex items-center justify-center gap-3
                      bg-gray-700 hover:bg-gray-600
                      text-white transition-all border border-gray-600
                    "
                  >
                    <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
                      {/* Discord icon SVG */}
                    </svg>
                    <span>Also sign in with Discord</span>
                  </button>
                </SignIn.Strategy>

                <p className="text-center text-sm text-gray-400 mt-4">
                  Connect your streaming account
                </p>
              </>
            )}
          </div>
        </SignIn.Step>
      </SignIn.Root>
    </div>
  );
}
```

### Step 6: Fetch Discord Guilds After Authentication

Create `lib/discord.ts`:

```typescript
// Fetch user's Discord guilds (servers)
export async function fetchDiscordGuilds(accessToken: string) {
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

// Check if user is in specific guild
export async function isInGuild(accessToken: string, guildId: string): Promise<boolean> {
  const guilds = await fetchDiscordGuilds(accessToken);
  return guilds.some((guild: any) => guild.id === guildId);
}
```

### Step 7: Fetch Twitch Stream Status

Create `lib/twitch.ts`:

```typescript
// Get Twitch user info
export async function getTwitchUser(accessToken: string) {
  const response = await fetch('https://api.twitch.tv/helix/users', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Client-Id': process.env.TWITCH_CLIENT_ID!
    }
  });

  if (!response.ok) {
    throw new Error('Failed to fetch Twitch user');
  }

  const data = await response.json();
  return data.data[0];
}

// Check if user is currently streaming
export async function isStreaming(accessToken: string, userId: string): Promise<boolean> {
  const response = await fetch(`https://api.twitch.tv/helix/streams?user_id=${userId}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Client-Id': process.env.TWITCH_CLIENT_ID!
    }
  });

  if (!response.ok) {
    return false;
  }

  const data = await response.json();
  return data.data.length > 0;
}

// Get stream information
export async function getStreamInfo(accessToken: string, userId: string) {
  const response = await fetch(`https://api.twitch.tv/helix/streams?user_id=${userId}`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Client-Id': process.env.TWITCH_CLIENT_ID!
    }
  });

  if (!response.ok) {
    return null;
  }

  const data = await response.json();
  return data.data[0] || null;
}
```

### Step 8: Display User Status

Create `components/UserStatus.tsx`:

```typescript
'use client';

import { useUser } from '@clerk/nextjs';
import { useEffect, useState } from 'react';

export function UserStatus() {
  const { user } = useUser();
  const [isStreaming, setIsStreaming] = useState(false);
  const [guilds, setGuilds] = useState<any[]>([]);

  useEffect(() => {
    if (!user) return;

    // Find Discord and Twitch connections
    const discordAccount = user.externalAccounts.find(
      acc => acc.provider === 'discord'
    );
    const twitchAccount = user.externalAccounts.find(
      acc => acc.provider === 'twitch'
    );

    // Fetch Discord guilds
    if (discordAccount) {
      fetchGuilds(discordAccount.accessToken);
    }

    // Check Twitch streaming status
    if (twitchAccount) {
      checkStreamStatus(twitchAccount.accessToken, twitchAccount.providerUserId);
    }
  }, [user]);

  async function fetchGuilds(accessToken: string) {
    const response = await fetch('/api/discord/guilds', {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });
    const data = await response.json();
    setGuilds(data);
  }

  async function checkStreamStatus(accessToken: string, userId: string) {
    const response = await fetch(`/api/twitch/streaming?userId=${userId}`, {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });
    const data = await response.json();
    setIsStreaming(data.isStreaming);
  }

  return (
    <div className="bg-gray-800 rounded-lg p-6">
      <h3 className="text-lg font-bold text-white mb-4">Your Status</h3>

      {/* Discord Guilds */}
      {guilds.length > 0 && (
        <div className="mb-4">
          <h4 className="text-sm font-medium text-gray-400 mb-2">
            Discord Servers ({guilds.length})
          </h4>
          <div className="flex flex-wrap gap-2">
            {guilds.slice(0, 5).map(guild => (
              <div
                key={guild.id}
                className="bg-gray-700 px-3 py-1 rounded text-sm text-gray-300"
              >
                {guild.name}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Twitch Streaming Status */}
      {isStreaming && (
        <div className="bg-purple-600 px-4 py-2 rounded flex items-center gap-2">
          <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
          <span className="text-white font-medium">LIVE on Twitch</span>
        </div>
      )}
    </div>
  );
}
```

### Step 9: Test Gaming OAuth

```bash
# Test Discord OAuth
bash scripts/test-oauth-flow.sh discord

# Test Twitch OAuth
bash scripts/test-oauth-flow.sh twitch

# Generate test report
bash scripts/test-oauth-flow.sh --all --report
```

### Step 10: Production Deployment

Before deploying:

1. **Update redirect URIs** in Discord and Twitch developer portals
2. **Configure production environment variables**
3. **Set up webhooks** for real-time status updates
4. **Test with actual streaming accounts**

### Advanced Features

**Guild-Gated Access:**
```typescript
// Restrict access to users in specific Discord server
export async function requireGuildMembership(guildId: string) {
  const { user } = useUser();
  const discordAccount = user?.externalAccounts.find(acc => acc.provider === 'discord');

  if (!discordAccount) {
    throw new Error('Discord not connected');
  }

  const isMember = await isInGuild(discordAccount.accessToken, guildId);

  if (!isMember) {
    throw new Error('Not a member of required server');
  }

  return true;
}
```

**Streamer Role Badge:**
```typescript
// Display badge for active streamers
export function StreamerBadge({ userId }: { userId: string }) {
  const [isStreaming, setIsStreaming] = useState(false);

  // Check streaming status every 60 seconds
  useEffect(() => {
    const interval = setInterval(checkStatus, 60000);
    return () => clearInterval(interval);
  }, []);

  if (!isStreaming) return null;

  return (
    <span className="bg-purple-600 text-white px-2 py-1 rounded text-xs font-medium">
      🔴 LIVE
    </span>
  );
}
```

### Resources

- [Discord Developer Portal](https://discord.com/developers/applications)
- [Twitch Developer Console](https://dev.twitch.tv/console/apps)
- [Discord OAuth2 Guide](https://discord.com/developers/docs/topics/oauth2)
- [Twitch Authentication Guide](https://dev.twitch.tv/docs/authentication)
- [Clerk Gaming Platform Examples](https://clerk.com/docs/integrations)
