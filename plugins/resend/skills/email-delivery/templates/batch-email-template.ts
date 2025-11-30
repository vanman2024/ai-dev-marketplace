/**
 * Batch Email Template
 * Pattern for sending up to 100 emails in a single request
 */

import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

interface BatchEmailPayload {
  from: string;
  to: string;
  subject: string;
  html: string;
  text?: string;
}

interface BatchOptions {
  batchSize?: number;
  delayBetweenBatches?: number;
  retryAttempts?: number;
}

/**
 * Send batch of emails (up to 100 per request)
 */
export async function sendBatchEmails(
  emails: BatchEmailPayload[],
  options: BatchOptions = {}
) {
  const {
    batchSize = 100,
    delayBetweenBatches = 1000,
    retryAttempts = 3,
  } = options;

  if (emails.length > batchSize) {
    throw new Error(`Batch size cannot exceed ${batchSize} emails`);
  }

  try {
    const { data, error } = await resend.batch.send(emails);

    if (error) {
      console.error('Batch send failed:', error);
      return { success: false, error: error.message };
    }

    console.log(`Batch sent to ${emails.length} recipients`);
    return {
      success: true,
      totalSent: emails.length,
      messageIds: data.map(d => d.id),
    };
  } catch (err) {
    console.error('Batch send exception:', err);
    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

/**
 * Send large batch with automatic chunking
 */
export async function sendLargeBatch(
  emails: BatchEmailPayload[],
  options: BatchOptions = {}
) {
  const {
    batchSize = 100,
    delayBetweenBatches = 1000,
    retryAttempts = 3,
  } = options;

  const results: any[] = [];

  for (let i = 0; i < emails.length; i += batchSize) {
    const batchNumber = Math.floor(i / batchSize) + 1;
    const batch = emails.slice(i, i + batchSize);

    console.log(`Sending batch ${batchNumber}...`);

    let lastError: string | null = null;

    for (let attempt = 1; attempt <= retryAttempts; attempt++) {
      try {
        const { data, error } = await resend.batch.send(batch);

        if (error) {
          lastError = error.message;

          if (attempt < retryAttempts) {
            const delay = Math.pow(2, attempt) * 100;
            console.log(`Retry ${attempt}/${retryAttempts} in ${delay}ms...`);
            await new Promise(resolve => setTimeout(resolve, delay));
            continue;
          }
        }

        results.push({
          batchNumber,
          success: !error,
          count: batch.length,
          messageIds: data?.map(d => d.id),
          error: error?.message,
        });

        break;
      } catch (err) {
        lastError = err instanceof Error ? err.message : String(err);
      }
    }

    if (!results[results.length - 1]?.success) {
      console.error(`Batch ${batchNumber} failed: ${lastError}`);
    }

    // Rate limiting
    if (i + batchSize < emails.length) {
      await new Promise(resolve => setTimeout(resolve, delayBetweenBatches));
    }
  }

  return {
    totalEmails: emails.length,
    successfulBatches: results.filter(r => r.success).length,
    failedBatches: results.filter(r => !r.success).length,
    details: results,
  };
}

// Segmentation helper
interface UserSegment {
  segment: 'free' | 'premium' | 'enterprise';
  users: Array<{ email: string; name: string }>;
}

/**
 * Send segmented batch with different templates per segment
 */
export async function sendSegmentedBatch(
  users: Array<{ email: string; name: string; segment: string }>,
  campaignTitle: string,
  contentBySegment: Record<string, string>
) {
  // Group users by segment
  const segments: Record<string, typeof users> = {};
  for (const user of users) {
    const segment = user.segment || 'free';
    if (!segments[segment]) segments[segment] = [];
    segments[segment].push(user);
  }

  const results: Record<string, any> = {};

  for (const [segment, segmentUsers] of Object.entries(segments)) {
    if (segmentUsers.length === 0) continue;

    const emails: BatchEmailPayload[] = segmentUsers.map(user => ({
      from: 'marketing@example.com',
      to: user.email,
      subject: campaignTitle,
      html: `
        <h2>Hello ${user.name},</h2>
        ${contentBySegment[segment] || '<p>Campaign content</p>'}
      `,
    }));

    const result = await sendBatchEmails(emails);
    results[segment] = result;

    // Rate limiting between segments
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  return results;
}

// Newsletter template
export function createNewsletterEmail(
  recipientEmail: string,
  recipientName: string,
  content: string,
  unsubscribeUrl: string
): BatchEmailPayload {
  return {
    from: 'newsletter@example.com',
    to: recipientEmail,
    subject: 'Weekly Newsletter',
    html: `
      <h2>Hello ${recipientName},</h2>
      <div>${content}</div>
      <hr>
      <p>
        <a href="${unsubscribeUrl}">Unsubscribe</a> |
        <a href="https://example.com/preferences">Preferences</a>
      </p>
    `,
  };
}

// Announcement template
export function createAnnouncementEmail(
  recipientEmail: string,
  title: string,
  message: string,
  actionUrl?: string
): BatchEmailPayload {
  return {
    from: 'announcements@example.com',
    to: recipientEmail,
    subject: title,
    html: `
      <h2>${title}</h2>
      <p>${message}</p>
      ${actionUrl ? `
        <p>
          <a href="${actionUrl}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
            Learn More
          </a>
        </p>
      ` : ''}
    `,
  };
}

// Usage example
export async function sendNewsletterBatch(
  recipients: Array<{ email: string; name: string }>,
  newsletterContent: string
) {
  const emails = recipients.map(recipient =>
    createNewsletterEmail(
      recipient.email,
      recipient.name,
      newsletterContent,
      `https://example.com/unsubscribe?email=${encodeURIComponent(recipient.email)}`
    )
  );

  return sendBatchEmails(emails);
}
