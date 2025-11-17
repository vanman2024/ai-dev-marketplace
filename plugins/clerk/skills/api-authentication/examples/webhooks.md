# Clerk Webhook Event Handling

Complete webhook handler for Clerk events with signature verification and event processing.

## Overview

Handle Clerk webhook events to sync user data, track sessions, and respond to organization changes.

## Webhook Events

Clerk sends webhooks for these event types:

### User Events
- `user.created` - New user signed up
- `user.updated` - User profile updated
- `user.deleted` - User account deleted

### Session Events
- `session.created` - New session started
- `session.ended` - Session ended normally
- `session.removed` - Session removed by user
- `session.revoked` - Session revoked by admin

### Organization Events
- `organization.created` - New organization created
- `organization.updated` - Organization updated
- `organization.deleted` - Organization deleted
- `organizationMembership.created` - User joined organization
- `organizationMembership.updated` - Membership role changed
- `organizationMembership.deleted` - User left organization

## Implementation

### 1. Webhook Endpoint with Signature Verification

```typescript
import express from 'express'
import { Webhook } from 'svix'

const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET!

app.post(
  '/api/webhooks/clerk',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    // Get webhook headers
    const svixId = req.headers['svix-id'] as string
    const svixTimestamp = req.headers['svix-timestamp'] as string
    const svixSignature = req.headers['svix-signature'] as string

    if (!svixId || !svixTimestamp || !svixSignature) {
      return res.status(400).json({ error: 'Missing Svix headers' })
    }

    // Verify signature
    const webhook = new Webhook(WEBHOOK_SECRET)
    const payload = req.body.toString()

    try {
      const event = webhook.verify(payload, {
        'svix-id': svixId,
        'svix-timestamp': svixTimestamp,
        'svix-signature': svixSignature,
      })

      // Process event
      await handleWebhookEvent(event)

      res.json({ received: true })
    } catch (error) {
      console.error('Webhook verification failed:', error)
      res.status(400).json({ error: 'Invalid signature' })
    }
  }
)
```

### 2. User Event Handlers

```typescript
async function handleUserCreated(user: any) {
  console.log('New user created:', user.id)

  // Create user in your database
  await db.users.create({
    clerkId: user.id,
    email: user.email_addresses[0]?.email_address,
    firstName: user.first_name,
    lastName: user.last_name,
    imageUrl: user.image_url,
    createdAt: new Date(user.created_at),
  })

  // Send welcome email
  await sendWelcomeEmail(user.email_addresses[0]?.email_address)
}

async function handleUserUpdated(user: any) {
  console.log('User updated:', user.id)

  // Sync changes to database
  await db.users.update(
    { clerkId: user.id },
    {
      email: user.email_addresses[0]?.email_address,
      firstName: user.first_name,
      lastName: user.last_name,
      imageUrl: user.image_url,
    }
  )
}

async function handleUserDeleted(userId: string) {
  console.log('User deleted:', userId)

  // Clean up user data
  await db.posts.deleteMany({ userId })
  await db.users.delete({ clerkId: userId })
}
```

### 3. Session Event Handlers

```typescript
async function handleSessionCreated(session: any) {
  console.log('Session created:', session.id)

  // Track session
  await db.sessions.create({
    clerkSessionId: session.id,
    userId: session.user_id,
    createdAt: new Date(session.created_at),
    expiresAt: new Date(session.expire_at),
  })

  // Update user last seen
  await db.users.update(
    { clerkId: session.user_id },
    { lastSeen: new Date() }
  )
}

async function handleSessionEnded(session: any) {
  console.log('Session ended:', session.id)

  await db.sessions.update(
    { clerkSessionId: session.id },
    { endedAt: new Date() }
  )
}
```

### 4. Organization Event Handlers

```typescript
async function handleOrganizationCreated(org: any) {
  console.log('Organization created:', org.id)

  await db.organizations.create({
    clerkId: org.id,
    name: org.name,
    slug: org.slug,
    createdBy: org.created_by,
    createdAt: new Date(org.created_at),
  })
}

async function handleMembershipCreated(membership: any) {
  console.log('Membership created:', membership.id)

  await db.organizationMembers.create({
    clerkMembershipId: membership.id,
    organizationId: membership.organization.id,
    userId: membership.public_user_data.user_id,
    role: membership.role,
    createdAt: new Date(membership.created_at),
  })

  // Send invitation accepted email
  if (membership.role === 'admin') {
    await sendAdminWelcomeEmail(membership.public_user_data.user_id)
  }
}
```

### 5. Event Router

```typescript
async function handleWebhookEvent(event: any) {
  switch (event.type) {
    // User events
    case 'user.created':
      await handleUserCreated(event.data)
      break
    case 'user.updated':
      await handleUserUpdated(event.data)
      break
    case 'user.deleted':
      await handleUserDeleted(event.data.id)
      break

    // Session events
    case 'session.created':
      await handleSessionCreated(event.data)
      break
    case 'session.ended':
      await handleSessionEnded(event.data)
      break

    // Organization events
    case 'organization.created':
      await handleOrganizationCreated(event.data)
      break
    case 'organizationMembership.created':
      await handleMembershipCreated(event.data)
      break

    default:
      console.log('Unhandled event type:', event.type)
  }
}
```

## Setup Instructions

### 1. Configure Webhook in Clerk Dashboard

1. Go to **Clerk Dashboard** → **Webhooks**
2. Click **Add Endpoint**
3. Enter webhook URL: `https://yourdomain.com/api/webhooks/clerk`
4. Copy the **Signing Secret**
5. Add to `.env`: `CLERK_WEBHOOK_SECRET=whsec_xxx`

### 2. Select Events to Subscribe

Check the events you want to receive:
- ✅ user.created, user.updated, user.deleted
- ✅ session.created, session.ended
- ✅ organization.created, organization.updated
- ✅ organizationMembership.created, organizationMembership.deleted

### 3. Test Webhook

1. Clerk provides a **Test** button in the dashboard
2. Send test events to verify your endpoint
3. Check your server logs for received events

### 4. Monitor Deliveries

- Clerk Dashboard shows webhook delivery status
- View retry attempts for failed deliveries
- Check response codes and error messages

## Security Best Practices

### 1. Always Verify Signatures

```typescript
// ✅ GOOD - Verifies signature
const event = webhook.verify(payload, headers)

// ❌ BAD - Trusts payload without verification
const event = JSON.parse(payload)
```

### 2. Use HTTPS in Production

Webhooks should only be sent to HTTPS endpoints.

### 3. Implement Idempotency

```typescript
// Track processed events to prevent duplicates
const processedEvents = new Set<string>()

async function handleWebhookEvent(event: any) {
  if (processedEvents.has(event.id)) {
    console.log('Event already processed:', event.id)
    return
  }

  // Process event
  await processEvent(event)

  // Mark as processed
  processedEvents.add(event.id)
}
```

### 4. Handle Retries Gracefully

Clerk retries failed webhooks. Ensure operations are idempotent:

```typescript
// Use upsert instead of create
await db.users.upsert({
  where: { clerkId: user.id },
  create: userData,
  update: userData,
})
```

## Troubleshooting

### Webhook verification fails

- Check `CLERK_WEBHOOK_SECRET` is correct
- Ensure raw body is passed to verification
- Verify headers are correctly forwarded

### Events not being received

- Check webhook URL is publicly accessible
- Verify HTTPS is enabled in production
- Review Clerk Dashboard for delivery errors

### Duplicate events

- Implement idempotency checking
- Store processed event IDs
- Use database transactions

## Full Code

See `examples/webhook-handler.ts.bak` for complete implementation with all event handlers.
