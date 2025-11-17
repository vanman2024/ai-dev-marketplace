/**
 * Clerk Webhook Handler for User Synchronization
 *
 * This handles Clerk webhook events and syncs user data to Supabase.
 * Supports user.created, user.updated, and user.deleted events.
 *
 * Deploy as:
 * - Next.js API route (app/api/webhooks/clerk/route.ts)
 * - Standalone Express/Fastify endpoint
 * - Supabase Edge Function (see edge-function-webhook.ts)
 */

import { Webhook } from 'svix'
import { WebhookEvent } from '@clerk/nextjs/server'
import { createClient } from '@supabase/supabase-js'
import { headers } from 'next/headers'

// Environment variables
const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET!
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!

/**
 * Webhook Event Types
 */
type ClerkWebhookEvent =
  | { type: 'user.created'; data: ClerkUser }
  | { type: 'user.updated'; data: ClerkUser }
  | { type: 'user.deleted'; data: { id: string } }
  | { type: 'organization.created'; data: ClerkOrganization }
  | { type: 'organization.updated'; data: ClerkOrganization }
  | { type: 'organization.deleted'; data: { id: string } }
  | { type: 'organizationMembership.created'; data: OrganizationMembership }
  | { type: 'organizationMembership.deleted'; data: OrganizationMembership }

interface ClerkUser {
  id: string
  email_addresses: Array<{
    id: string
    email_address: string
    verification: { status: string }
  }>
  first_name: string | null
  last_name: string | null
  image_url: string
  username: string | null
  public_metadata: Record<string, any>
  private_metadata: Record<string, any>
  created_at: number
  updated_at: number
}

interface ClerkOrganization {
  id: string
  name: string
  slug: string
  image_url: string
  public_metadata: Record<string, any>
  created_at: number
  updated_at: number
}

interface OrganizationMembership {
  id: string
  organization: { id: string; name: string }
  public_user_data: { user_id: string }
  role: string
  created_at: number
  updated_at: number
}

/**
 * Next.js App Router webhook handler
 */
export async function POST(req: Request) {
  // Verify webhook signature
  const { isValid, event, error } = await verifyWebhook(req)

  if (!isValid || !event) {
    console.error('Webhook verification failed:', error)
    return new Response('Unauthorized', { status: 401 })
  }

  // Initialize Supabase with service role (bypasses RLS)
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  try {
    // Route to appropriate handler
    switch (event.type) {
      case 'user.created':
      case 'user.updated':
        await handleUserSync(supabase, event.data)
        break

      case 'user.deleted':
        await handleUserDeletion(supabase, event.data.id)
        break

      case 'organization.created':
      case 'organization.updated':
        await handleOrganizationSync(supabase, event.data)
        break

      case 'organization.deleted':
        await handleOrganizationDeletion(supabase, event.data.id)
        break

      case 'organizationMembership.created':
        await handleMembershipCreated(supabase, event.data)
        break

      case 'organizationMembership.deleted':
        await handleMembershipDeleted(supabase, event.data)
        break

      default:
        console.log('Unhandled event type:', event.type)
    }

    return new Response('Success', { status: 200 })
  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response('Internal Server Error', { status: 500 })
  }
}

/**
 * Verify Clerk webhook signature using Svix
 */
async function verifyWebhook(req: Request): Promise<{
  isValid: boolean
  event?: ClerkWebhookEvent
  error?: string
}> {
  const headersList = headers()
  const svix_id = headersList.get('svix-id')
  const svix_timestamp = headersList.get('svix-timestamp')
  const svix_signature = headersList.get('svix-signature')

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return { isValid: false, error: 'Missing svix headers' }
  }

  if (!WEBHOOK_SECRET) {
    return { isValid: false, error: 'WEBHOOK_SECRET not configured' }
  }

  const body = await req.text()
  const webhook = new Webhook(WEBHOOK_SECRET)

  try {
    const event = webhook.verify(body, {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature,
    }) as ClerkWebhookEvent

    return { isValid: true, event }
  } catch (error: any) {
    console.error('Webhook verification error:', error.message)
    return { isValid: false, error: error.message }
  }
}

/**
 * Sync user to Supabase
 */
async function handleUserSync(supabase: any, user: ClerkUser) {
  const primaryEmail = user.email_addresses.find(
    (email) => email.verification.status === 'verified'
  ) || user.email_addresses[0]

  const userData = {
    clerk_id: user.id,
    email: primaryEmail?.email_address,
    first_name: user.first_name,
    last_name: user.last_name,
    avatar_url: user.image_url,
    username: user.username,
    metadata: user.public_metadata,
    updated_at: new Date(user.updated_at).toISOString(),
  }

  const { error } = await supabase
    .from('users')
    .upsert(userData, {
      onConflict: 'clerk_id',
      ignoreDuplicates: false,
    })

  if (error) {
    console.error('Error syncing user:', error)
    throw error
  }

  console.log('User synced successfully:', user.id)
}

/**
 * Delete user from Supabase
 */
async function handleUserDeletion(supabase: any, clerkId: string) {
  const { error } = await supabase
    .from('users')
    .delete()
    .eq('clerk_id', clerkId)

  if (error) {
    console.error('Error deleting user:', error)
    throw error
  }

  console.log('User deleted successfully:', clerkId)
}

/**
 * Sync organization to Supabase
 */
async function handleOrganizationSync(supabase: any, org: ClerkOrganization) {
  const orgData = {
    clerk_org_id: org.id,
    name: org.name,
    slug: org.slug,
    image_url: org.image_url,
    settings: org.public_metadata,
    updated_at: new Date(org.updated_at).toISOString(),
  }

  const { error } = await supabase
    .from('organizations')
    .upsert(orgData, {
      onConflict: 'clerk_org_id',
      ignoreDuplicates: false,
    })

  if (error) {
    console.error('Error syncing organization:', error)
    throw error
  }

  console.log('Organization synced successfully:', org.id)
}

/**
 * Delete organization from Supabase
 */
async function handleOrganizationDeletion(supabase: any, clerkOrgId: string) {
  const { error } = await supabase
    .from('organizations')
    .delete()
    .eq('clerk_org_id', clerkOrgId)

  if (error) {
    console.error('Error deleting organization:', error)
    throw error
  }

  console.log('Organization deleted successfully:', clerkOrgId)
}

/**
 * Handle organization membership creation
 */
async function handleMembershipCreated(
  supabase: any,
  membership: OrganizationMembership
) {
  const membershipData = {
    clerk_org_id: membership.organization.id,
    clerk_user_id: membership.public_user_data.user_id,
    role: membership.role,
    created_at: new Date(membership.created_at).toISOString(),
  }

  const { error } = await supabase
    .from('organization_members')
    .upsert(membershipData, {
      onConflict: 'clerk_org_id,clerk_user_id',
    })

  if (error) {
    console.error('Error creating membership:', error)
    throw error
  }

  console.log('Membership created:', membership.id)
}

/**
 * Handle organization membership deletion
 */
async function handleMembershipDeleted(
  supabase: any,
  membership: OrganizationMembership
) {
  const { error } = await supabase
    .from('organization_members')
    .delete()
    .eq('clerk_org_id', membership.organization.id)
    .eq('clerk_user_id', membership.public_user_data.user_id)

  if (error) {
    console.error('Error deleting membership:', error)
    throw error
  }

  console.log('Membership deleted:', membership.id)
}

/**
 * Retry logic for failed operations
 *
 * Webhooks may fail due to transient errors. This utility
 * retries operations with exponential backoff.
 */
async function withRetry<T>(
  operation: () => Promise<T>,
  maxRetries = 3,
  initialDelay = 1000
): Promise<T> {
  let lastError: Error | undefined

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation()
    } catch (error: any) {
      lastError = error
      console.error(`Attempt ${attempt + 1} failed:`, error.message)

      if (attempt < maxRetries - 1) {
        const delay = initialDelay * Math.pow(2, attempt)
        console.log(`Retrying in ${delay}ms...`)
        await new Promise((resolve) => setTimeout(resolve, delay))
      }
    }
  }

  throw lastError || new Error('Operation failed after retries')
}

/**
 * Batch sync utility for initial migration
 *
 * Use this to sync all existing Clerk users to Supabase
 */
export async function syncAllUsers() {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  // This would be called from a separate script or admin endpoint
  // Implementation depends on Clerk API usage
  console.log('Use sync-users.sh script for batch synchronization')
}
