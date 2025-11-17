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

  // Process invoice.payment_succeeded event
  const { data, type } = evt

  if (type === 'invoice.payment_succeeded') {
    console.log('Payment succeeded:', {
      invoiceId: data.id,
      userId: data.userId,
      organizationId: data.organizationId,
      subscriptionId: data.subscriptionId,
      amountPaid: data.amountPaid,
      currency: data.currency,
      paidAt: data.paidAt,
    })

    try {
      // TODO: Add your custom logic here
      // Examples:
      // - Send payment receipt email
      // - Update usage limits
      // - Reset API quotas
      // - Trigger provisioning
      // - Track revenue analytics

      // Example: Send receipt email
      // await sendPaymentReceipt({
      //   userId: data.userId,
      //   amount: data.amountPaid,
      //   currency: data.currency,
      //   invoiceId: data.id,
      //   paidAt: data.paidAt,
      // })

      // Example: Reset usage limits for new billing period
      // if (data.billingReason === 'subscription_cycle') {
      //   await resetUsageLimits(data.userId, data.subscriptionId)
      // }

      // Example: Track revenue
      // await analytics.track({
      //   userId: data.userId,
      //   event: 'Payment Succeeded',
      //   properties: {
      //     amount: data.amountPaid / 100, // Convert cents to dollars
      //     currency: data.currency,
      //     invoiceId: data.id,
      //     subscriptionId: data.subscriptionId,
      //   },
      // })

      // Example: Update user metadata with last payment
      // await clerkClient.users.updateUserMetadata(data.userId, {
      //   privateMetadata: {
      //     lastPaymentAmount: data.amountPaid,
      //     lastPaymentDate: new Date().toISOString(),
      //     totalRevenue: (existingRevenue || 0) + data.amountPaid,
      //   },
      // })

      console.log('Payment succeeded webhook processed successfully')
    } catch (error) {
      console.error('Error processing invoice.payment_succeeded:', error)
      // Don't return error - acknowledge webhook was received
    }
  }

  return NextResponse.json({ received: true })
}
