import { headers } from 'next/headers'
import { NextResponse } from 'next/server'
import { Webhook } from 'svix'

export async function POST(request: Request) {
  // Get webhook secret from environment
  const webhookSecret = process.env.CLERK_WEBHOOK_SECRET

  if (!webhookSecret) {
    throw new Error('CLERK_WEBHOOK_SECRET is not configured')
  }

  // Get headers
  const headerPayload = headers()
  const svixId = headerPayload.get('svix-id')
  const svixTimestamp = headerPayload.get('svix-timestamp')
  const svixSignature = headerPayload.get('svix-signature')

  // Verify headers exist
  if (!svixId || !svixTimestamp || !svixSignature) {
    return NextResponse.json(
      { error: 'Missing svix headers' },
      { status: 400 }
    )
  }

  // Get request body
  const payload = await request.json()
  const body = JSON.stringify(payload)

  // Verify webhook signature
  const wh = new Webhook(webhookSecret)
  let evt

  try {
    evt = wh.verify(body, {
      'svix-id': svixId,
      'svix-timestamp': svixTimestamp,
      'svix-signature': svixSignature,
    })
  } catch (err) {
    console.error('Webhook verification failed:', err)
    return NextResponse.json(
      { error: 'Webhook verification failed' },
      { status: 400 }
    )
  }

  // Process subscription.created event
  const { data, type } = evt

  if (type === 'subscription.created') {
    console.log('New subscription created:', {
      subscriptionId: data.id,
      userId: data.userId,
      organizationId: data.organizationId,
      planId: data.planId,
      status: data.status,
      createdAt: data.createdAt,
    })

    try {
      // TODO: Add your custom logic here
      // Examples:
      // - Send welcome email
      // - Grant feature access
      // - Track analytics event
      // - Sync to external service
      // - Update user metadata

      // Example: Send welcome email
      // await sendWelcomeEmail(data.userId, data.planId)

      // Example: Track analytics
      // await analytics.track({
      //   userId: data.userId,
      //   event: 'Subscription Created',
      //   properties: {
      //     planId: data.planId,
      //     subscriptionId: data.id,
      //   },
      // })

      // Example: Update user metadata
      // await clerkClient.users.updateUserMetadata(data.userId, {
      //   publicMetadata: {
      //     subscriptionId: data.id,
      //     planId: data.planId,
      //     subscribedAt: new Date().toISOString(),
      //   },
      // })

      console.log('Subscription created webhook processed successfully')
    } catch (error) {
      console.error('Error processing subscription.created:', error)
      // Don't return error - acknowledge webhook was received
      // Log error for monitoring/alerting
    }
  }

  return NextResponse.json({ received: true })
}
