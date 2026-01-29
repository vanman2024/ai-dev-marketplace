---
description: Add a specific feature to an existing Clerk project. Features include mfa, oauth, organizations, webhooks, billing, supabase.
argument-hint: <feature> [options]
---

# Add Clerk Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Security Features

**If `$0` = "mfa":**

```
Task(clerk-mfa-specialist) Add MFA to this Clerk project.

Requirements:
- MFA type: $1 (totp, sms, backup-codes, all - default: all)
- Enable multi-factor authentication
- Configure MFA settings
- Add enrollment UI
- Create recovery flow
```

**If `$0` = "oauth":**

```
Task(clerk-oauth-specialist) Add OAuth PROVIDER.

Requirements:
- Provider: $1 (google, github, discord, apple, microsoft - required)
- Configure OAuth credentials
- Add social sign-in buttons
- Set up callback handling
- Configure scopes
```

### Organization Features

**If `$0` = "organizations":**

```
Task(clerk-organization-builder) Add ORGANIZATIONS support.

Requirements:
- Org type: $1 (basic, enterprise - default: basic)
- Enable organization features
- Create org management UI
- Add member invitations
- Set up role-based permissions
- Configure org switching
```

### Integration Features

**If `$0` = "webhooks":**

```
Task(clerk-api-builder) Add WEBHOOK handlers.

Requirements:
- Event types: $1 (user, session, organization, all - default: all)
- Create webhook endpoint
- Set up event handlers
- Add signature verification
- Implement user sync
```

**If `$0` = "billing":**

```
Task(clerk-billing-integrator) Add BILLING integration.

Requirements:
- Provider: $1 (stripe - default: stripe)
- Connect Clerk with Stripe
- Sync user metadata
- Set up subscription tiers
- Add billing portal
```

**If `$0` = "supabase":**

```
Task(clerk-supabase-integrator) Add SUPABASE integration.

Requirements:
- Sync users to Supabase
- Configure RLS policies
- Set up JWT verification
- Create auth hooks
```

**If `$0` = "ai":**

```
Task(clerk-vercel-ai-integrator) Add AI SDK integration.

Requirements:
- Protect AI routes
- Add user context to prompts
- Set up rate limiting
- Configure usage tracking
```

---

## Usage Examples

```bash
# Security
/clerk:add mfa totp
/clerk:add oauth google
/clerk:add oauth github

# Organizations
/clerk:add organizations
/clerk:add organizations enterprise

# Integrations
/clerk:add webhooks user
/clerk:add billing stripe
/clerk:add supabase
/clerk:add ai
```

---

## Feature Reference

| Feature         | Agent                | $1 Options                      | Description         |
| --------------- | -------------------- | ------------------------------- | ------------------- |
| `mfa`           | mfa-specialist       | totp/sms/backup-codes/all       | Multi-factor auth   |
| `oauth`         | oauth-specialist     | google/github/discord/apple/etc | OAuth provider      |
| `organizations` | organization-builder | basic/enterprise                | Multi-tenant orgs   |
| `webhooks`      | api-builder          | user/session/organization/all   | Webhook handlers    |
| `billing`       | billing-integrator   | stripe                          | Payment integration |
| `supabase`      | supabase-integrator  | -                               | Supabase sync       |
| `ai`            | ai-integrator        | -                               | AI SDK protection   |
