import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';

interface WebhookEvent {
  type: string;
  created_at: string;
  data: {
    email_id: string;
    from: string;
    to: string;
    [key: string]: any;
  };
}

function verifySignature(payload: string, signature: string): boolean {
  const secret = process.env.RESEND_WEBHOOK_SECRET;
  if (!secret) {
    throw new Error('RESEND_WEBHOOK_SECRET not configured');
  }

  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

async function handleWebhookEvent(event: WebhookEvent): Promise<void> {
  const { type, data, created_at } = event;

  switch (type) {
    case 'email.sent':
      // Handle email sent
      console.log(`Email sent: ${data.email_id}`);
      break;

    case 'email.delivered':
      // Handle email delivered
      console.log(`Email delivered: ${data.email_id}`);
      break;

    case 'email.bounced':
      // Handle email bounced
      console.log(`Email bounced: ${data.email_id} - ${data.reason}`);
      break;

    case 'email.opened':
      // Handle email opened
      console.log(`Email opened: ${data.email_id}`);
      break;

    case 'email.clicked':
      // Handle email clicked
      console.log(`Email clicked: ${data.email_id} - ${data.link}`);
      break;

    case 'email.complained':
      // Handle email complained
      console.log(`Email complained: ${data.email_id}`);
      break;

    default:
      console.warn(`Unknown event type: ${type}`);
  }
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const signature = request.headers.get('x-resend-signature');
    if (!signature) {
      return NextResponse.json(
        { error: 'Missing signature header' },
        { status: 401 }
      );
    }

    const payload = await request.text();

    if (!verifySignature(payload, signature)) {
      return NextResponse.json(
        { error: 'Invalid signature' },
        { status: 401 }
      );
    }

    const event: WebhookEvent = JSON.parse(payload);
    await handleWebhookEvent(event);

    return NextResponse.json(
      { success: true },
      { status: 200 }
    );
  } catch (error) {
    console.error('Webhook handler error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
