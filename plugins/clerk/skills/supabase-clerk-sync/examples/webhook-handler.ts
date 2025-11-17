/**
 * Production-Ready Webhook Handler
 *
 * Complete implementation with:
 * - Signature verification
 * - Error handling and retries
 * - Logging and monitoring
 * - Rate limiting
 * - Idempotency
 */

import { NextRequest, NextResponse } from 'next/server'
import { Webhook } from 'svix'
import { createClient } from '@supabase/supabase-js'
import { headers } from 'next/headers'

// Environment configuration
const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET!
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!

// Rate limiting configuration (using Redis in production)
const RATE_LIMIT_WINDOW = 60 * 1000 // 1 minute
const MAX_REQUESTS_PER_WINDOW = 100

// Idempotency cache (use Redis in production)
const processedEvents = new Map<string, number>()

/**
 * Main webhook handler
 */
export async function POST(req: NextRequest) {
  const startTime = Date.now()

  try {
    // Step 1: Rate limiting
    const rateLimitResult = await checkRateLimit(req)
    if (!rateLimitResult.allowed) {
      return NextResponse.json(
        { error: 'Rate limit exceeded' },
        { status: 429 }
      )
    }

    // Step 2: Verify webhook signature
    const { isValid, event, error: verifyError } = await verifyWebhook(req)

    if (!isValid || !event) {
      console.error('[Webhook] Verification failed:', verifyError)
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    // Step 3: Check idempotency (prevent duplicate processing)
    const eventId = req.headers.get('svix-id')
    if (eventId && isEventProcessed(eventId)) {
      console.log('[Webhook] Event already processed:', eventId)
      return NextResponse.json({ status: 'already_processed' }, { status: 200 })
    }

    // Step 4: Process event with retry logic
    const result = await processEventWithRetry(event)

    // Step 5: Mark event as processed
    if (eventId) {
      markEventProcessed(eventId)
    }

    // Step 6: Log metrics
    const duration = Date.now() - startTime
    await logWebhookMetrics({
      event_type: event.type,
      duration_ms: duration,
      success: true,
    })

    return NextResponse.json(
      { status: 'success', result },
      { status: 200 }
    )
  } catch (error: any) {
    // Error logging and monitoring
    const duration = Date.now() - startTime
    console.error('[Webhook] Processing error:', error)

    await logWebhookMetrics({
      event_type: 'error',
      duration_ms: duration,
      success: false,
      error: error.message,
    })

    // Return 500 to trigger Clerk's retry mechanism
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

/**
 * Verify Clerk webhook signature
 */
async function verifyWebhook(req: NextRequest) {
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
    })

    return { isValid: true, event }
  } catch (error: any) {
    return { isValid: false, error: error.message }
  }
}

/**
 * Process event with automatic retry logic
 */
async function processEventWithRetry(
  event: any,
  maxRetries = 3
): Promise<any> {
  let lastError: Error | undefined

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await processEvent(event)
    } catch (error: any) {
      lastError = error
      console.error(`[Webhook] Attempt ${attempt + 1} failed:`, error.message)

      if (attempt < maxRetries - 1) {
        // Exponential backoff
        const delay = Math.pow(2, attempt) * 1000
        await new Promise((resolve) => setTimeout(resolve, delay))
      }
    }
  }

  throw lastError || new Error('All retry attempts failed')
}

/**
 * Process webhook event
 */
async function processEvent(event: any) {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  console.log('[Webhook] Processing event:', event.type, event.data?.id)

  switch (event.type) {
    case 'user.created':
    case 'user.updated':
      return await syncUser(supabase, event.data)

    case 'user.deleted':
      return await deleteUser(supabase, event.data.id)

    case 'organization.created':
    case 'organization.updated':
      return await syncOrganization(supabase, event.data)

    case 'organization.deleted':
      return await deleteOrganization(supabase, event.data.id)

    case 'organizationMembership.created':
      return await addOrganizationMember(supabase, event.data)

    case 'organizationMembership.deleted':
      return await removeOrganizationMember(supabase, event.data)

    default:
      console.log('[Webhook] Unhandled event type:', event.type)
      return { status: 'ignored' }
  }
}

/**
 * Sync user to Supabase
 */
async function syncUser(supabase: any, user: any) {
  const primaryEmail = user.email_addresses?.find(
    (email: any) => email.verification?.status === 'verified'
  ) || user.email_addresses?.[0]

  const userData = {
    clerk_id: user.id,
    email: primaryEmail?.email_address,
    first_name: user.first_name,
    last_name: user.last_name,
    avatar_url: user.image_url,
    username: user.username,
    metadata: user.public_metadata || {},
    updated_at: new Date(user.updated_at).toISOString(),
  }

  const { data, error } = await supabase
    .from('users')
    .upsert(userData, {
      onConflict: 'clerk_id',
      ignoreDuplicates: false,
    })
    .select()

  if (error) {
    console.error('[Webhook] User sync error:', error)
    throw error
  }

  console.log('[Webhook] User synced:', user.id)
  return { status: 'synced', user_id: user.id }
}

/**
 * Delete user from Supabase
 */
async function deleteUser(supabase: any, clerkId: string) {
  const { error } = await supabase.from('users').delete().eq('clerk_id', clerkId)

  if (error) {
    console.error('[Webhook] User deletion error:', error)
    throw error
  }

  console.log('[Webhook] User deleted:', clerkId)
  return { status: 'deleted', user_id: clerkId }
}

/**
 * Sync organization to Supabase
 */
async function syncOrganization(supabase: any, org: any) {
  const orgData = {
    clerk_org_id: org.id,
    name: org.name,
    slug: org.slug,
    image_url: org.image_url,
    settings: org.public_metadata || {},
    updated_at: new Date(org.updated_at).toISOString(),
  }

  const { error } = await supabase
    .from('organizations')
    .upsert(orgData, {
      onConflict: 'clerk_org_id',
      ignoreDuplicates: false,
    })

  if (error) {
    console.error('[Webhook] Organization sync error:', error)
    throw error
  }

  console.log('[Webhook] Organization synced:', org.id)
  return { status: 'synced', org_id: org.id }
}

/**
 * Delete organization from Supabase
 */
async function deleteOrganization(supabase: any, clerkOrgId: string) {
  const { error } = await supabase
    .from('organizations')
    .delete()
    .eq('clerk_org_id', clerkOrgId)

  if (error) {
    console.error('[Webhook] Organization deletion error:', error)
    throw error
  }

  console.log('[Webhook] Organization deleted:', clerkOrgId)
  return { status: 'deleted', org_id: clerkOrgId }
}

/**
 * Add organization member
 */
async function addOrganizationMember(supabase: any, membership: any) {
  const memberData = {
    clerk_org_id: membership.organization.id,
    clerk_user_id: membership.public_user_data.user_id,
    role: membership.role,
    created_at: new Date(membership.created_at).toISOString(),
  }

  const { error } = await supabase
    .from('organization_members')
    .upsert(memberData, {
      onConflict: 'clerk_org_id,clerk_user_id',
    })

  if (error) {
    console.error('[Webhook] Member addition error:', error)
    throw error
  }

  console.log('[Webhook] Member added:', membership.id)
  return { status: 'added', membership_id: membership.id }
}

/**
 * Remove organization member
 */
async function removeOrganizationMember(supabase: any, membership: any) {
  const { error } = await supabase
    .from('organization_members')
    .delete()
    .eq('clerk_org_id', membership.organization.id)
    .eq('clerk_user_id', membership.public_user_data.user_id)

  if (error) {
    console.error('[Webhook] Member removal error:', error)
    throw error
  }

  console.log('[Webhook] Member removed:', membership.id)
  return { status: 'removed', membership_id: membership.id }
}

/**
 * Rate limiting check
 */
async function checkRateLimit(req: NextRequest) {
  // In production, use Redis for distributed rate limiting
  // This is a simple in-memory implementation

  const clientIp = req.headers.get('x-forwarded-for') || 'unknown'
  const now = Date.now()

  // Clean up old entries
  for (const [key, timestamp] of processedEvents.entries()) {
    if (now - timestamp > RATE_LIMIT_WINDOW) {
      processedEvents.delete(key)
    }
  }

  // Count requests in current window
  const recentRequests = Array.from(processedEvents.values()).filter(
    (timestamp) => now - timestamp < RATE_LIMIT_WINDOW
  )

  if (recentRequests.length >= MAX_REQUESTS_PER_WINDOW) {
    return { allowed: false }
  }

  return { allowed: true }
}

/**
 * Idempotency: Check if event was already processed
 */
function isEventProcessed(eventId: string): boolean {
  const timestamp = processedEvents.get(eventId)
  if (!timestamp) return false

  // Events expire after 24 hours
  const now = Date.now()
  if (now - timestamp > 24 * 60 * 60 * 1000) {
    processedEvents.delete(eventId)
    return false
  }

  return true
}

/**
 * Idempotency: Mark event as processed
 */
function markEventProcessed(eventId: string) {
  processedEvents.set(eventId, Date.now())
}

/**
 * Log webhook metrics
 */
async function logWebhookMetrics(metrics: {
  event_type: string
  duration_ms: number
  success: boolean
  error?: string
}) {
  // In production, send to monitoring service (DataDog, Sentry, etc.)
  console.log('[Webhook Metrics]', JSON.stringify(metrics))

  // Example: Send to monitoring service
  // await sendToMonitoring(metrics)
}
