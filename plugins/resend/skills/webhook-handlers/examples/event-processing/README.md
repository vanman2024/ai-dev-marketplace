# Event Processing and Analytics Example

Complete patterns for processing webhook events, logging to database, generating analytics, and building real-time dashboards.

## Event Processing Pipeline

### TypeScript Processing Pattern

```typescript
// lib/webhooks/event-processor.ts
import { Prisma } from '@prisma/client';
import { db } from '@/lib/db';

interface EmailEvent {
  type: string;
  created_at: string;
  data: {
    email_id: string;
    from: string;
    to: string;
    [key: string]: any;
  };
}

interface ProcessingResult {
  success: boolean;
  emailId: string;
  eventType: string;
  error?: string;
}

class EventProcessor {
  private retryConfig = {
    maxRetries: 3,
    backoffMs: 1000,
  };

  async processEvent(event: EmailEvent): Promise<ProcessingResult> {
    const { data, type } = event;

    try {
      // Check for duplicate
      const isDuplicate = await this.checkDuplicate(data.email_id, type);
      if (isDuplicate) {
        console.log(`Duplicate event: ${type} ${data.email_id}`);
        return {
          success: true,
          emailId: data.email_id,
          eventType: type,
        };
      }

      // Process with retry
      await this.retryableProcess(event);

      return {
        success: true,
        emailId: data.email_id,
        eventType: type,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      console.error(`Failed to process event: ${errorMessage}`);

      return {
        success: false,
        emailId: data.email_id,
        eventType: type,
        error: errorMessage,
      };
    }
  }

  private async checkDuplicate(emailId: string, eventType: string): Promise<boolean> {
    const existing = await db.processedWebhook.findUnique({
      where: {
        emailId_eventType: {
          emailId,
          eventType,
        },
      },
    });

    return !!existing;
  }

  private async retryableProcess(event: EmailEvent): Promise<void> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.retryConfig.maxRetries; attempt++) {
      try {
        await this.executeUpdate(event);
        return;
      } catch (error) {
        lastError = error as Error;
        console.warn(`Attempt ${attempt} failed:`, lastError.message);

        if (attempt < this.retryConfig.maxRetries) {
          const delay = this.retryConfig.backoffMs * Math.pow(2, attempt - 1);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw lastError;
  }

  private async executeUpdate(event: EmailEvent): Promise<void> {
    const { type, data } = event;

    switch (type) {
      case 'email.sent':
        await this.updateSentStatus(data);
        break;
      case 'email.delivered':
        await this.updateDeliveredStatus(data);
        break;
      case 'email.bounced':
        await this.updateBounceStatus(data);
        break;
      case 'email.opened':
        await this.logOpenEvent(data);
        break;
      case 'email.clicked':
        await this.logClickEvent(data);
        break;
      case 'email.complained':
        await this.updateComplaintStatus(data);
        break;
    }

    // Record processed webhook
    await db.processedWebhook.create({
      data: {
        emailId: data.email_id,
        eventType: type,
        timestamp: new Date(event.created_at),
      },
    });
  }

  private async updateSentStatus(data: any): Promise<void> {
    await db.email.update({
      where: { resendId: data.email_id },
      data: {
        status: 'SENT',
        sentAt: new Date(data.created_at),
      },
    });
  }

  private async updateDeliveredStatus(data: any): Promise<void> {
    await db.email.update({
      where: { resendId: data.email_id },
      data: {
        status: 'DELIVERED',
        deliveredAt: new Date(data.created_at),
      },
    });
  }

  private async updateBounceStatus(data: any): Promise<void> {
    const timestamp = new Date(data.created_at);

    // Update email
    await db.email.update({
      where: { resendId: data.email_id },
      data: {
        status: 'BOUNCED',
        bounceReason: data.reason,
        bouncedAt: timestamp,
      },
    });

    // Add to bounce list
    await db.bouncedEmail.upsert({
      where: { email: data.to },
      update: {
        reason: data.reason,
        bouncedAt: timestamp,
      },
      create: {
        email: data.to,
        reason: data.reason,
        bouncedAt: timestamp,
      },
    });
  }

  private async updateComplaintStatus(data: any): Promise<void> {
    // Update email
    await db.email.update({
      where: { resendId: data.email_id },
      data: {
        status: 'COMPLAINED',
        complainedAt: new Date(data.created_at),
      },
    });

    // Add to suppression list
    await db.suppressedEmail.upsert({
      where: { email: data.to },
      update: {
        reason: 'COMPLAINT',
      },
      create: {
        email: data.to,
        reason: 'COMPLAINT',
      },
    });
  }

  private async logOpenEvent(data: any): Promise<void> {
    await db.emailEvent.create({
      data: {
        emailId: data.email_id,
        eventType: 'OPENED',
        userAgent: data.user_agent,
        ipAddress: data.ip_address,
        timestamp: new Date(data.created_at),
      },
    });
  }

  private async logClickEvent(data: any): Promise<void> {
    await db.emailEvent.create({
      data: {
        emailId: data.email_id,
        eventType: 'CLICKED',
        link: data.link,
        userAgent: data.user_agent,
        ipAddress: data.ip_address,
        timestamp: new Date(data.created_at),
      },
    });
  }
}

export const eventProcessor = new EventProcessor();
```

## Analytics Queries

### Email Status Summary

```typescript
// lib/analytics/email-stats.ts
import { db } from '@/lib/db';
import { startOfDay, endOfDay, subDays } from 'date-fns';

interface EmailStats {
  total: number;
  sent: number;
  delivered: number;
  bounced: number;
  complained: number;
  pendingDelivery: number;
  bounceRate: number;
  complaintRate: number;
}

export async function getEmailStatsByDate(date: Date): Promise<EmailStats> {
  const start = startOfDay(date);
  const end = endOfDay(date);

  const emails = await db.email.findMany({
    where: {
      createdAt: {
        gte: start,
        lte: end,
      },
    },
  });

  const statuses = {
    SENT: emails.filter(e => e.status === 'SENT').length,
    DELIVERED: emails.filter(e => e.status === 'DELIVERED').length,
    BOUNCED: emails.filter(e => e.status === 'BOUNCED').length,
    COMPLAINED: emails.filter(e => e.status === 'COMPLAINED').length,
  };

  const pendingDelivery = emails.length -
    (statuses.DELIVERED + statuses.BOUNCED + statuses.COMPLAINED);

  return {
    total: emails.length,
    sent: statuses.SENT,
    delivered: statuses.DELIVERED,
    bounced: statuses.BOUNCED,
    complained: statuses.COMPLAINED,
    pendingDelivery,
    bounceRate: emails.length ? (statuses.BOUNCED / emails.length) * 100 : 0,
    complaintRate: emails.length ? (statuses.COMPLAINED / emails.length) * 100 : 0,
  };
}

export async function getEmailStatsRange(days: number = 7): Promise<EmailStats[]> {
  const stats = [];

  for (let i = days - 1; i >= 0; i--) {
    const date = subDays(new Date(), i);
    const dailyStats = await getEmailStatsByDate(date);
    stats.push(dailyStats);
  }

  return stats;
}
```

### Engagement Analytics

```typescript
// lib/analytics/engagement.ts
import { db } from '@/lib/db';

interface EngagementMetrics {
  emailId: string;
  sent: boolean;
  delivered: boolean;
  opened: boolean;
  clicked: boolean;
  bounced: boolean;
  complained: boolean;
  opens: number;
  clicks: number;
  lastEvent?: Date;
}

export async function getEmailEngagement(emailId: string): Promise<EngagementMetrics> {
  const email = await db.email.findUnique({
    where: { resendId: emailId },
    include: { events: true },
  });

  if (!email) {
    throw new Error(`Email not found: ${emailId}`);
  }

  const events = email.events || [];
  const openCount = events.filter(e => e.eventType === 'OPENED').length;
  const clickCount = events.filter(e => e.eventType === 'CLICKED').length;

  return {
    emailId,
    sent: !!email.sentAt,
    delivered: !!email.deliveredAt,
    opened: openCount > 0,
    clicked: clickCount > 0,
    bounced: email.status === 'BOUNCED',
    complained: email.status === 'COMPLAINED',
    opens: openCount,
    clicks: clickCount,
    lastEvent: events[events.length - 1]?.timestamp,
  };
}

export async function getCampaignEngagement(campaignId: string) {
  const emails = await db.email.findMany({
    where: { campaignId },
    include: { events: true },
  });

  const metrics = {
    total: emails.length,
    delivered: emails.filter(e => e.deliveredAt).length,
    opened: emails.filter(e =>
      e.events?.some(ev => ev.eventType === 'OPENED')
    ).length,
    clicked: emails.filter(e =>
      e.events?.some(ev => ev.eventType === 'CLICKED')
    ).length,
    bounced: emails.filter(e => e.status === 'BOUNCED').length,
  };

  return {
    ...metrics,
    deliveryRate: (metrics.delivered / metrics.total) * 100,
    openRate: (metrics.opened / metrics.delivered) * 100,
    clickRate: (metrics.clicked / metrics.opened) * 100,
    bounceRate: (metrics.bounced / metrics.total) * 100,
  };
}
```

### Bounce Analysis

```typescript
// lib/analytics/bounces.ts
import { db } from '@/lib/db';
import { startOfDay, subDays } from 'date-fns';

interface BounceAnalysis {
  totalBounces: number;
  bouncesByReason: Record<string, number>;
  recentBounces: Array<{
    email: string;
    reason: string;
    bouncedAt: Date;
  }>;
  bounceRate: number;
}

export async function analyzeBounces(days: number = 7): Promise<BounceAnalysis> {
  const since = subDays(startOfDay(new Date()), days);

  const bounces = await db.bouncedEmail.findMany({
    where: {
      bouncedAt: { gte: since },
    },
    orderBy: { bouncedAt: 'desc' },
  });

  const bouncesByReason: Record<string, number> = {};
  bounces.forEach(bounce => {
    const reason = bounce.reason || 'unknown';
    bouncesByReason[reason] = (bouncesByReason[reason] || 0) + 1;
  });

  const totalEmails = await db.email.count({
    where: {
      createdAt: { gte: since },
    },
  });

  return {
    totalBounces: bounces.length,
    bouncesByReason,
    recentBounces: bounces.slice(0, 10),
    bounceRate: totalEmails ? (bounces.length / totalEmails) * 100 : 0,
  };
}
```

## Real-time Dashboard

### Next.js Dashboard Component

```typescript
// app/dashboard/analytics/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { EmailStats, EngagementMetrics } from '@/types';

export default function AnalyticsDashboard() {
  const [stats, setStats] = useState<EmailStats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const response = await fetch('/api/analytics/today');
        const data = await response.json();
        setStats(data);
      } catch (error) {
        console.error('Failed to fetch stats:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchStats();
    // Refresh every 30 seconds
    const interval = setInterval(fetchStats, 30000);

    return () => clearInterval(interval);
  }, []);

  if (loading) return <div>Loading analytics...</div>;
  if (!stats) return <div>No data available</div>;

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
      <StatCard
        label="Total Sent"
        value={stats.total}
        color="bg-blue-50"
      />
      <StatCard
        label="Delivered"
        value={stats.delivered}
        percentage={(stats.delivered / stats.total) * 100}
        color="bg-green-50"
      />
      <StatCard
        label="Bounced"
        value={stats.bounced}
        percentage={stats.bounceRate}
        color="bg-red-50"
      />
      <StatCard
        label="Complained"
        value={stats.complained}
        percentage={stats.complaintRate}
        color="bg-yellow-50"
      />
      <StatCard
        label="Pending"
        value={stats.pendingDelivery}
        color="bg-gray-50"
      />
    </div>
  );
}

function StatCard({
  label,
  value,
  percentage,
  color,
}: {
  label: string;
  value: number;
  percentage?: number;
  color: string;
}) {
  return (
    <div className={`p-4 rounded-lg ${color}`}>
      <p className="text-sm font-medium text-gray-700">{label}</p>
      <p className="text-3xl font-bold text-gray-900 mt-2">{value}</p>
      {percentage !== undefined && (
        <p className="text-sm text-gray-600 mt-2">{percentage.toFixed(1)}%</p>
      )}
    </div>
  );
}
```

### API Routes

```typescript
// app/api/analytics/today/route.ts
import { getEmailStatsByDate } from '@/lib/analytics/email-stats';

export async function GET() {
  try {
    const stats = await getEmailStatsByDate(new Date());
    return Response.json(stats);
  } catch (error) {
    console.error('Failed to fetch analytics:', error);
    return Response.json(
      { error: 'Failed to fetch analytics' },
      { status: 500 }
    );
  }
}
```

```typescript
// app/api/analytics/engagement/[emailId]/route.ts
import { getEmailEngagement } from '@/lib/analytics/engagement';

export async function GET(
  request: Request,
  { params }: { params: { emailId: string } }
) {
  try {
    const metrics = await getEmailEngagement(params.emailId);
    return Response.json(metrics);
  } catch (error) {
    return Response.json(
      { error: 'Email not found' },
      { status: 404 }
    );
  }
}
```

## Event Archival

### Archive Old Events

```typescript
// lib/webhooks/archiver.ts
import { db } from '@/lib/db';
import { subDays } from 'date-fns';

export async function archiveOldEvents(daysToKeep: number = 90) {
  const cutoffDate = subDays(new Date(), daysToKeep);

  const archived = await db.emailEvent.deleteMany({
    where: {
      timestamp: { lt: cutoffDate },
    },
  });

  console.log(`Archived ${archived.count} events older than ${daysToKeep} days`);

  return archived;
}

// Run daily via cron job
// 0 2 * * * node scripts/archive-events.js
```

## Monitoring and Alerting

### Alert on High Bounce Rate

```typescript
// lib/webhooks/alerts.ts
import { analyzeBounces } from '@/lib/analytics/bounces';

export async function checkBounceRateAlert() {
  const analysis = await analyzeBounces(1); // Last 24 hours

  if (analysis.bounceRate > 5) {
    // Send alert
    await sendAlert({
      level: 'warning',
      title: 'High Bounce Rate',
      message: `Bounce rate is ${analysis.bounceRate.toFixed(2)}%`,
      details: analysis.bouncesByReason,
    });
  }
}

async function sendAlert(alert: any) {
  // Send to Slack, email, or other notification service
  console.log('ALERT:', alert);
}
```

### Scheduled Checks

```typescript
// lib/cron/daily-checks.ts
import { checkBounceRateAlert } from '@/lib/webhooks/alerts';
import { archiveOldEvents } from '@/lib/webhooks/archiver';

export async function runDailyChecks() {
  console.log('Running daily checks...');

  await Promise.all([
    checkBounceRateAlert(),
    archiveOldEvents(90),
  ]);

  console.log('Daily checks completed');
}
```

## Performance Optimization

### Index Strategy

```sql
-- Critical indexes for analytics queries
CREATE INDEX idx_email_created_status ON emails(created_at DESC, status);
CREATE INDEX idx_email_event_timestamp ON email_events(timestamp DESC);
CREATE INDEX idx_bounced_bounced_at ON bounced_emails(bounced_at DESC);
CREATE INDEX idx_processed_webhook_timestamp ON processed_webhooks(timestamp DESC);
```

### Query Caching

```typescript
import { cache } from '@/lib/cache';

export async function getEmailStatsCached(date: Date) {
  const cacheKey = `stats:${date.toISOString().split('T')[0]}`;

  return cache.remember(cacheKey, async () => {
    return getEmailStatsByDate(date);
  }, 300); // Cache for 5 minutes
}
```

## Example: Complete Webhook Flow

```
1. Webhook received from Resend
   ↓
2. Signature verification
   ↓
3. Duplicate check (idempotency)
   ↓
4. Event processing with retry logic
   ↓
5. Database updates (atomic transaction)
   ↓
6. Analytics aggregation
   ↓
7. Webhook logging
   ↓
8. Response sent to Resend (202 Accepted)
   ↓
9. Background job: Update dashboards
   ↓
10. Background job: Check alerts
```

## Best Practices

- Use database transactions for atomic updates
- Implement comprehensive logging
- Cache frequently accessed analytics
- Archive old events for compliance
- Monitor webhook processing latency
- Alert on anomalies (bounce rate, complaint rate)
- Use proper indexing for analytics queries
- Implement data retention policies
