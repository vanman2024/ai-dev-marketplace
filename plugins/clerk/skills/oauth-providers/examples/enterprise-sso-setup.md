## Enterprise SSO Setup Example

This example demonstrates how to configure enterprise Single Sign-On (SSO) using Microsoft Azure AD and LinkedIn for a B2B SaaS application.

### Use Case

Enterprise B2B application requiring:
- Microsoft 365 integration for corporate users
- LinkedIn authentication for professional networking
- Domain-based automatic provider selection
- Custom claims for role mapping

### Prerequisites

- Clerk Pro plan (for enterprise features)
- Azure AD tenant access
- LinkedIn Company Page (for API access)
- Custom domain configured

### Step 1: Configure Microsoft Azure AD

#### 1.1 Register Application

```bash
# Set up Microsoft OAuth provider
bash scripts/setup-provider.sh microsoft
```

Navigate to [Azure Portal](https://portal.azure.com/):

1. **Azure Active Directory** > **App registrations** > **New registration**
2. **Name:** Your Application Name
3. **Supported account types:**
   - **Single tenant** (your org only)
   - **Multi-tenant** (any Azure AD org)
   - **Multi-tenant + personal accounts**
4. **Redirect URI:** Web - `https://yourdomain.com/api/auth/callback/microsoft`
5. Click **Register**

#### 1.2 Configure Authentication

1. **Authentication** > **Platform configurations** > **Add a platform** > **Web**
2. Add redirect URIs:
   ```
   https://yourdomain.com/api/auth/callback/microsoft
   https://your-clerk-domain.clerk.accounts.dev/v1/oauth_callback
   ```
3. **Implicit grant and hybrid flows:** Enable both ID tokens and Access tokens
4. **Supported account types:** Configure based on requirements
5. **Save**

#### 1.3 Generate Client Secret

1. **Certificates & secrets** > **New client secret**
2. **Description:** Clerk OAuth Integration
3. **Expires:** 24 months (recommended)
4. Copy the **Value** (client secret) - you won't see it again

#### 1.4 Configure API Permissions

1. **API permissions** > **Add a permission** > **Microsoft Graph**
2. **Delegated permissions:**
   - `openid`
   - `profile`
   - `email`
   - `User.Read`
3. **Grant admin consent** (if required by your organization)

#### 1.5 Brand Configuration

1. **Branding & properties**
2. Upload logo
3. Set privacy policy URL
4. Set terms of service URL

### Step 2: Configure LinkedIn OAuth

#### 2.1 Create LinkedIn App

```bash
# Set up LinkedIn OAuth provider
bash scripts/setup-provider.sh linkedin
```

Navigate to [LinkedIn Developers](https://www.linkedin.com/developers/apps):

1. **Create app**
2. **App name:** Your Application
3. **LinkedIn Page:** Select your company page (required)
4. **Privacy policy URL:** Your privacy policy
5. **App logo:** Upload logo
6. Click **Create app**

#### 2.2 Configure OAuth Settings

1. **Auth** tab
2. **Authorized redirect URLs:**
   ```
   https://yourdomain.com/api/auth/callback/linkedin
   https://your-clerk-domain.clerk.accounts.dev/v1/oauth_callback
   ```
3. **OAuth 2.0 scopes:**
   - `r_liteprofile` (Profile)
   - `r_emailaddress` (Email)
4. Copy **Client ID** and **Client Secret**

### Step 3: Environment Configuration

Create `.env.production`:

```bash
# Clerk Configuration
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_your_publishable_key_here
CLERK_SECRET_KEY=sk_live_your_secret_key_here

# Microsoft Azure AD OAuth
MICROSOFT_CLIENT_ID=your_azure_ad_client_id
MICROSOFT_CLIENT_SECRET=your_azure_ad_client_secret
MICROSOFT_TENANT_ID=your_tenant_id_or_common
MICROSOFT_REDIRECT_URI=https://yourdomain.com/api/auth/callback/microsoft
MICROSOFT_DOMAIN_HINT=yourcompany.com

# LinkedIn OAuth
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=https://yourdomain.com/api/auth/callback/linkedin

# Application Configuration
NEXT_PUBLIC_APP_URL=https://yourdomain.com
```

### Step 4: Configure Clerk Dashboard

1. Navigate to [Clerk Dashboard](https://dashboard.clerk.com/)
2. **User & Authentication** > **Social Connections**

**Microsoft:**
- Enable Microsoft provider
- Paste Client ID from Azure AD
- Paste Client Secret from Azure AD
- **Advanced:** Set tenant ID if single-tenant
- Save

**LinkedIn:**
- Enable LinkedIn provider
- Paste Client ID from LinkedIn
- Paste Client Secret from LinkedIn
- Save

### Step 5: Implement Domain-Based Provider Selection

Create `lib/auth/provider-selector.ts`:

```typescript
// Automatically select OAuth provider based on email domain

const DOMAIN_PROVIDER_MAP: Record<string, 'microsoft' | 'linkedin'> = {
  // Microsoft domains
  'yourcompany.com': 'microsoft',
  'subsidiary.com': 'microsoft',

  // Force LinkedIn for specific partners
  'partnercompany.com': 'linkedin',
};

export function getProviderForEmail(email: string): 'microsoft' | 'linkedin' | null {
  const domain = email.split('@')[1]?.toLowerCase();
  return domain ? DOMAIN_PROVIDER_MAP[domain] || null : null;
}

export function getProviderForDomain(domain: string): 'microsoft' | 'linkedin' | null {
  return DOMAIN_PROVIDER_MAP[domain.toLowerCase()] || null;
}
```

Create smart auth component (`components/auth/EnterpriseAuth.tsx`):

```typescript
'use client';

import { useState } from 'react';
import { SignIn } from '@clerk/nextjs';
import { getProviderForEmail } from '@/lib/auth/provider-selector';

export function EnterpriseAuth() {
  const [email, setEmail] = useState('');
  const [suggestedProvider, setSuggestedProvider] = useState<string | null>(null);

  const handleEmailChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setEmail(value);

    if (value.includes('@')) {
      const provider = getProviderForEmail(value);
      setSuggestedProvider(provider);
    } else {
      setSuggestedProvider(null);
    }
  };

  return (
    <div className="space-y-6">
      {/* Email input for domain detection */}
      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700">
          Work email
        </label>
        <input
          type="email"
          id="email"
          value={email}
          onChange={handleEmailChange}
          placeholder="you@company.com"
          className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
        />
      </div>

      {/* Suggested provider */}
      {suggestedProvider && (
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <p className="text-sm text-blue-800">
            We detected you're from {email.split('@')[1]}.
            We recommend signing in with {suggestedProvider === 'microsoft' ? 'Microsoft' : 'LinkedIn'}.
          </p>
        </div>
      )}

      {/* OAuth buttons */}
      <SignIn.Root>
        <SignIn.Step name="start">
          <div className="space-y-3">
            <SignIn.Strategy name="oauth_microsoft">
              <button
                type="button"
                className={`
                  w-full px-6 py-3 rounded-lg font-medium
                  flex items-center justify-center gap-3
                  ${suggestedProvider === 'microsoft'
                    ? 'bg-blue-600 text-white ring-2 ring-blue-400'
                    : 'bg-white text-gray-700 border border-gray-300'}
                  hover:bg-blue-700 hover:text-white
                  transition-all
                `}
              >
                <span>🪟</span>
                <span>Continue with Microsoft</span>
                {suggestedProvider === 'microsoft' && (
                  <span className="ml-auto text-xs">Recommended</span>
                )}
              </button>
            </SignIn.Strategy>

            <SignIn.Strategy name="oauth_linkedin">
              <button
                type="button"
                className={`
                  w-full px-6 py-3 rounded-lg font-medium
                  flex items-center justify-center gap-3
                  ${suggestedProvider === 'linkedin'
                    ? 'bg-blue-700 text-white ring-2 ring-blue-400'
                    : 'bg-white text-gray-700 border border-gray-300'}
                  hover:bg-blue-800 hover:text-white
                  transition-all
                `}
              >
                <span>💼</span>
                <span>Continue with LinkedIn</span>
                {suggestedProvider === 'linkedin' && (
                  <span className="ml-auto text-xs">Recommended</span>
                )}
              </button>
            </SignIn.Strategy>
          </div>
        </SignIn.Step>
      </SignIn.Root>
    </div>
  );
}
```

### Step 6: Configure Custom Claims and Role Mapping

Create webhook to map Microsoft groups to application roles:

```typescript
// app/api/webhooks/clerk/route.ts

import { Webhook } from 'svix';
import { headers } from 'next/headers';

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  const headerPayload = headers();
  const svix_id = headerPayload.get('svix-id');
  const svix_timestamp = headerPayload.get('svix-timestamp');
  const svix_signature = headerPayload.get('svix-signature');

  const body = await req.text();

  const wh = new Webhook(WEBHOOK_SECRET!);
  let evt;

  try {
    evt = wh.verify(body, {
      'svix-id': svix_id!,
      'svix-timestamp': svix_timestamp!,
      'svix-signature': svix_signature!,
    }) as any;
  } catch (err) {
    return new Response('Error verifying webhook', { status: 400 });
  }

  // Handle user.created event
  if (evt.type === 'user.created') {
    const { id, email_addresses, external_accounts } = evt.data;

    // Find Microsoft external account
    const microsoftAccount = external_accounts.find(
      (acc: any) => acc.provider === 'microsoft'
    );

    if (microsoftAccount) {
      // Fetch Microsoft Graph groups
      const groups = await fetchMicrosoftGroups(microsoftAccount.access_token);

      // Map groups to application roles
      const roles = mapGroupsToRoles(groups);

      // Update user metadata in Clerk
      await updateUserRoles(id, roles);
    }
  }

  return new Response('', { status: 200 });
}

async function fetchMicrosoftGroups(accessToken: string) {
  const response = await fetch('https://graph.microsoft.com/v1.0/me/memberOf', {
    headers: {
      Authorization: `Bearer ${accessToken}`
    }
  });

  const data = await response.json();
  return data.value;
}

function mapGroupsToRoles(groups: any[]): string[] {
  const GROUP_ROLE_MAP: Record<string, string> = {
    'Admins': 'admin',
    'Power Users': 'power_user',
    'Sales Team': 'sales',
    'Support Team': 'support'
  };

  return groups
    .map(group => GROUP_ROLE_MAP[group.displayName])
    .filter(Boolean);
}

async function updateUserRoles(userId: string, roles: string[]) {
  // Update user with Clerk API
  // Implementation depends on your role management system
}
```

### Step 7: Test Enterprise SSO

```bash
# Test Microsoft OAuth
bash scripts/test-oauth-flow.sh microsoft

# Test LinkedIn OAuth
bash scripts/test-oauth-flow.sh linkedin

# Generate test report
bash scripts/test-oauth-flow.sh --all --report
```

### Step 8: Production Deployment

1. **Update redirect URIs** in Azure AD and LinkedIn
2. **Configure production environment variables**
3. **Set up Clerk webhook** for user provisioning
4. **Test with corporate accounts**
5. **Monitor authentication metrics**

### Security Best Practices

1. **Use specific tenant ID** for single-tenant apps
2. **Require admin consent** for sensitive scopes
3. **Implement conditional access** policies in Azure AD
4. **Enable MFA** for all corporate accounts
5. **Audit OAuth access** regularly
6. **Rotate secrets** every 6 months

### Troubleshooting

**Azure AD: "AADSTS50011: Reply URL mismatch"**
- Verify exact redirect URI match
- Check for trailing slashes
- Ensure HTTPS in production

**LinkedIn: "Unauthorized redirect_uri"**
- Verify LinkedIn app has company page associated
- Check redirect URI exactly matches
- Ensure app is verified for production

**Clerk: Provider not appearing**
- Verify provider enabled in Dashboard
- Check client credentials are correct
- Restart application

### Resources

- [Microsoft Identity Platform Docs](https://docs.microsoft.com/en-us/azure/active-directory/develop/)
- [LinkedIn OAuth 2.0 Guide](https://docs.microsoft.com/en-us/linkedin/shared/authentication/authentication)
- [Clerk Enterprise SSO](https://clerk.com/docs/authentication/enterprise-connections)
