// backend-sdk-setup.ts - Initialize Clerk Backend SDK

import { Clerk } from '@clerk/backend'

/**
 * Initialize Clerk backend client
 * Uses secret key from environment variables
 */
const clerk = new Clerk({
  secretKey: process.env.CLERK_SECRET_KEY,
})

/**
 * Verify JWT token manually
 */
export async function verifyToken(token: string) {
  try {
    const { sessionId, userId, organizationId } = await clerk.verifyToken(token)

    return {
      valid: true,
      sessionId,
      userId,
      organizationId,
    }
  } catch (error) {
    console.error('Token verification failed:', error)
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * Get user by ID
 */
export async function getUserById(userId: string) {
  try {
    const user = await clerk.users.getUser(userId)
    return user
  } catch (error) {
    console.error('Error fetching user:', error)
    throw error
  }
}

/**
 * Get user's organizations
 */
export async function getUserOrganizations(userId: string) {
  try {
    const memberships = await clerk.users.getOrganizationMembershipList({
      userId,
    })
    return memberships.data
  } catch (error) {
    console.error('Error fetching user organizations:', error)
    throw error
  }
}

/**
 * Update user metadata
 */
export async function updateUserMetadata(
  userId: string,
  metadata: {
    publicMetadata?: Record<string, any>
    privateMetadata?: Record<string, any>
  }
) {
  try {
    const user = await clerk.users.updateUser(userId, metadata)
    return user
  } catch (error) {
    console.error('Error updating user metadata:', error)
    throw error
  }
}

/**
 * Get session by ID
 */
export async function getSession(sessionId: string) {
  try {
    const session = await clerk.sessions.getSession(sessionId)
    return session
  } catch (error) {
    console.error('Error fetching session:', error)
    throw error
  }
}

/**
 * Verify session token
 */
export async function verifySession(sessionId: string, token: string) {
  try {
    const session = await clerk.sessions.verifySession(sessionId, token)
    return {
      valid: true,
      session,
    }
  } catch (error) {
    console.error('Session verification failed:', error)
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

/**
 * Get organization by ID
 */
export async function getOrganization(organizationId: string) {
  try {
    const organization = await clerk.organizations.getOrganization({
      organizationId,
    })
    return organization
  } catch (error) {
    console.error('Error fetching organization:', error)
    throw error
  }
}

/**
 * Check if user is member of organization
 */
export async function isOrganizationMember(
  userId: string,
  organizationId: string
) {
  try {
    const memberships = await clerk.users.getOrganizationMembershipList({
      userId,
    })

    return memberships.data.some(
      (membership) => membership.organization.id === organizationId
    )
  } catch (error) {
    console.error('Error checking organization membership:', error)
    return false
  }
}

/**
 * Verify webhook signature
 */
export async function verifyWebhook(
  payload: string,
  headers: Record<string, string>
) {
  try {
    const { Webhook } = await import('svix')
    const webhook = new Webhook(process.env.CLERK_WEBHOOK_SECRET!)

    const event = webhook.verify(payload, headers)
    return {
      valid: true,
      event,
    }
  } catch (error) {
    console.error('Webhook verification failed:', error)
    return {
      valid: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    }
  }
}

// Export clerk client for advanced usage
export { clerk }

// Usage examples:
//
// // Verify JWT token
// const result = await verifyToken(token)
// if (result.valid) {
//   console.log('User ID:', result.userId)
// }
//
// // Get user details
// const user = await getUserById('user_xxx')
// console.log('User email:', user.emailAddresses[0].emailAddress)
//
// // Update user metadata
// await updateUserMetadata('user_xxx', {
//   publicMetadata: { role: 'admin' },
//   privateMetadata: { internalId: '12345' }
// })
//
// // Check organization membership
// const isMember = await isOrganizationMember('user_xxx', 'org_xxx')
//
// // Verify webhook
// const webhookResult = await verifyWebhook(
//   req.body,
//   {
//     'svix-id': req.headers['svix-id'],
//     'svix-timestamp': req.headers['svix-timestamp'],
//     'svix-signature': req.headers['svix-signature']
//   }
// )
