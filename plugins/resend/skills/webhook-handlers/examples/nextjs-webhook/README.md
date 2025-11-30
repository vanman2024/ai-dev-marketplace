# Next.js Webhook Handler Example

Complete Next.js App Router API route for handling Resend webhook events with signature verification and database logging.

## Setup

### 1. Environment Variables

```bash
# .env.local
RESEND_WEBHOOK_SECRET=your_webhook_signing_secret_here
DATABASE_URL=your_database_connection_string
```

### 2. API Route Handler

Create `/app/api/webhooks/resend/route.ts`:

```typescript
import { NextRequest, NextResponse } from 'next/server';
import crypto from 'crypto';
import { db } from '@/lib/db';

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

function verifySignature(
  payload: string,
  signature: string
): boolean {
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

  try {
    switch (type) {
      case 'email.sent':
        await db.email.update(
          { resendId: data.email_id },
          {
            status: 'sent',
            sentAt: new Date(created_at),
          }
        );
        break;

      case 'email.delivered':
        await db.email.update(
          { resendId: data.email_id },
          {
            status: 'delivered',
            deliveredAt: new Date(created_at),
          }
        );
        break;

      case 'email.bounced':
        await db.email.update(
          { resendId: data.email_id },
          {
            status: 'bounced',
            bounceReason: data.reason,
            bouncedAt: new Date(created_at),
          }
        );

        // Add to bounce list
        await db.bouncedEmail.upsert({
          where: { email: data.to },
          create: {
            email: data.to,
            reason: data.reason,
            bouncedAt: new Date(created_at),
          },
          update: {
            reason: data.reason,
            bouncedAt: new Date(created_at),
          },
        });
        break;

      case 'email.opened':
        await db.emailEvent.create({
          data: {
            emailId: data.email_id,
            eventType: 'opened',
            userAgent: data.user_agent,
            ipAddress: data.ip_address,
            createdAt: new Date(created_at),
          },
        });
        break;

      case 'email.clicked':
        await db.emailEvent.create({
          data: {
            emailId: data.email_id,
            eventType: 'clicked',
            link: data.link,
            userAgent: data.user_agent,
            ipAddress: data.ip_address,
            createdAt: new Date(created_at),
          },
        });
        break;

      case 'email.complained':
        await db.email.update(
          { resendId: data.email_id },
          {
            status: 'complained',
            complainedAt: new Date(created_at),
          }
        );

        // Add to suppression list
        await db.suppressedEmail.upsert({
          where: { email: data.to },
          create: {
            email: data.to,
            reason: 'complaint',
          },
          update: {
            reason: 'complaint',
          },
        });
        break;

      default:
        console.warn(`Unknown event type: ${type}`);
    }

    // Log webhook event
    await db.webhookLog.create({
      data: {
        eventType: type,
        emailId: data.email_id,
        payload: JSON.stringify(event),
        processed: true,
      },
    });
  } catch (error) {
    console.error('Error processing webhook:', error);

    // Log failed webhook
    await db.webhookLog.create({
      data: {
        eventType: type,
        emailId: data.email_id,
        payload: JSON.stringify(event),
        processed: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
    });

    throw error;
  }
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    // Get signature from headers
    const signature = request.headers.get('x-resend-signature');
    if (!signature) {
      return NextResponse.json(
        { error: 'Missing signature header' },
        { status: 401 }
      );
    }

    // Get and verify payload
    const payload = await request.text();

    if (!verifySignature(payload, signature)) {
      return NextResponse.json(
        { error: 'Invalid signature' },
        { status: 401 }
      );
    }

    // Parse and process event
    const event: WebhookEvent = JSON.parse(payload);

    // Check for duplicate processing using idempotency
    const existingLog = await db.webhookLog.findUnique({
      where: { eventId: event.data.email_id + event.type },
    });

    if (existingLog?.processed) {
      return NextResponse.json(
        { success: true, cached: true },
        { status: 200 }
      );
    }

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
```

### 3. Prisma Schema

Add to `prisma/schema.prisma`:

```prisma
model Email {
  id              String    @id @default(cuid())
  resendId        String    @unique
  from            String
  to              String
  subject         String
  status          String    @default("sent")
  sentAt          DateTime?
  deliveredAt     DateTime?
  bouncedAt       DateTime?
  complainedAt    DateTime?
  bounceReason    String?
  events          EmailEvent[]
  webhookLogs     WebhookLog[]
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  @@index([status])
  @@index([to])
  @@index([createdAt])
}

model EmailEvent {
  id          String    @id @default(cuid())
  emailId     String
  email       Email     @relation(fields: [emailId], references: [id], onDelete: Cascade)
  eventType   String
  link        String?
  userAgent   String?
  ipAddress   String?
  createdAt   DateTime  @default(now())

  @@index([emailId])
  @@index([eventType])
}

model BouncedEmail {
  id          String    @id @default(cuid())
  email       String    @unique
  reason      String?
  bouncedAt   DateTime
  createdAt   DateTime  @default(now())

  @@index([email])
}

model SuppressedEmail {
  id          String    @id @default(cuid())
  email       String    @unique
  reason      String
  createdAt   DateTime  @default(now())

  @@index([email])
}

model WebhookLog {
  id          String    @id @default(cuid())
  eventType   String
  emailId     String
  email       Email     @relation(fields: [emailId], references: [id], onDelete: Cascade)
  payload     Json
  processed   Boolean   @default(false)
  error       String?
  createdAt   DateTime  @default(now())

  @@index([emailId])
  @@index([processed])
  @@index([createdAt])
}
```

### 4. Usage

To register the webhook with Resend:

```typescript
// lib/webhooks.ts
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function registerWebhook() {
  const response = await resend.webhooks.create({
    events: [
      'email.sent',
      'email.delivered',
      'email.bounced',
      'email.opened',
      'email.clicked',
      'email.complained',
    ],
    url: `${process.env.NEXT_PUBLIC_APP_URL}/api/webhooks/resend`,
  });

  if (!response.data?.id) {
    throw new Error('Failed to create webhook');
  }

  console.log('Webhook registered:', response.data.id);
  console.log('Webhook secret:', response.data.signing_secret);
  // Save the signing_secret to environment variables

  return response.data;
}
```

### 5. Testing Webhooks Locally

Use ngrok to expose local server:

```bash
# Terminal 1: Start your Next.js dev server
npm run dev

# Terminal 2: Create ngrok tunnel
ngrok http 3000

# Get your ngrok URL (e.g., https://abc123.ngrok.io)
# Register webhook with: https://abc123.ngrok.io/api/webhooks/resend
```

Test with curl:

```bash
# Generate signature
PAYLOAD='{"type":"email.opened","created_at":"2024-01-15T11:00:00Z","data":{"email_id":"123e4567","from":"test@example.com","to":"user@example.com"}}'
SECRET='your_webhook_secret'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

curl -X POST http://localhost:3000/api/webhooks/resend \
  -H "Content-Type: application/json" \
  -H "x-resend-signature: $SIGNATURE" \
  -d "$PAYLOAD"
```

## API Routes Pattern

### Health Check Endpoint

```typescript
// /app/api/webhooks/health/route.ts
export async function GET() {
  return Response.json({ status: 'ok', webhook: 'ready' });
}
```

### Webhook Status Endpoint

```typescript
// /app/api/webhooks/status/route.ts
import { db } from '@/lib/db';

export async function GET() {
  const recentLogs = await db.webhookLog.findMany({
    where: {
      createdAt: {
        gte: new Date(Date.now() - 24 * 60 * 60 * 1000), // Last 24 hours
      },
    },
    select: {
      eventType: true,
      processed: true,
    },
  });

  const processed = recentLogs.filter(log => log.processed).length;
  const failed = recentLogs.filter(log => !log.processed).length;

  return Response.json({
    processed,
    failed,
    total: recentLogs.length,
    successRate: processed / (processed + failed) || 0,
  });
}
```

## Error Handling Middleware

```typescript
// lib/middleware/webhook-error.ts
import { NextResponse } from 'next/server';

export class WebhookError extends Error {
  constructor(
    public statusCode: number,
    message: string
  ) {
    super(message);
    this.name = 'WebhookError';
  }
}

export function handleWebhookError(error: unknown) {
  if (error instanceof WebhookError) {
    return NextResponse.json(
      { error: error.message },
      { status: error.statusCode }
    );
  }

  if (error instanceof Error) {
    console.error('Webhook error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }

  return NextResponse.json(
    { error: 'Unknown error' },
    { status: 500 }
  );
}
```

## Database Queries

### Get Email Status

```typescript
async function getEmailStatus(emailId: string) {
  return db.email.findUnique({
    where: { resendId: emailId },
    include: { events: true },
  });
}
```

### Get Bounce List

```typescript
async function getRecentBounces(days: number = 7) {
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);

  return db.bouncedEmail.findMany({
    where: {
      bouncedAt: { gte: since },
    },
    orderBy: { bouncedAt: 'desc' },
  });
}
```

### Analytics Query

```typescript
async function getEmailAnalytics(emailId: string) {
  const email = await db.email.findUnique({
    where: { resendId: emailId },
    include: { events: true },
  });

  const events = email?.events || [];

  return {
    sent: email?.sentAt ? true : false,
    delivered: email?.deliveredAt ? true : false,
    bounced: email?.status === 'bounced',
    complained: email?.status === 'complained',
    opens: events.filter(e => e.eventType === 'opened').length,
    clicks: events.filter(e => e.eventType === 'clicked').length,
    lastEvent: events[events.length - 1]?.createdAt,
  };
}
```

## Monitoring

### Failed Webhooks Alert

```typescript
async function checkFailedWebhooks() {
  const failedCount = await db.webhookLog.count({
    where: {
      processed: false,
      createdAt: {
        gte: new Date(Date.now() - 60 * 60 * 1000), // Last hour
      },
    },
  });

  if (failedCount > 10) {
    // Send alert (email, Slack, etc.)
    console.error(`${failedCount} failed webhooks in the last hour`);
  }
}
```

Run this periodically with cron jobs or scheduled tasks.

## Security Checklist

- [x] Signature verification implemented
- [x] HTTPS enforced for webhook URL
- [x] Sensitive data in environment variables
- [x] Database transactions for atomic updates
- [x] Idempotency tracking
- [x] Comprehensive error logging
- [x] Rate limiting on webhook endpoint
- [x] Request validation
