# Batch Email Delivery

Patterns for sending bulk emails (up to 100 recipients per request) with Resend.

## Use Cases

- Newsletter campaigns
- User notifications
- Marketing campaigns
- Bulk announcements
- Daily digests
- Notification broadcasts

## TypeScript Example

### Basic Batch Sending

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

interface BatchRecipient {
  email: string;
  name: string;
}

async function sendNewsletterBatch(recipients: BatchRecipient[], content: string) {
  // Ensure batch size doesn't exceed 100
  if (recipients.length > 100) {
    throw new Error('Batch size cannot exceed 100 recipients');
  }

  const emails = recipients.map(recipient => ({
    from: 'newsletter@example.com',
    to: recipient.email,
    subject: 'Weekly Newsletter',
    html: `
      <h2>Hello ${recipient.name},</h2>
      <div>${content}</div>
      <p>
        <a href="https://example.com/unsubscribe?email=${encodeURIComponent(recipient.email)}">
          Unsubscribe
        </a>
      </p>
    `,
  }));

  const { data, error } = await resend.batch.send(emails);

  if (error) {
    console.error('Batch send failed:', error);
    return { success: false, error };
  }

  console.log(`Batch sent to ${recipients.length} recipients`);
  return {
    success: true,
    totalSent: recipients.length,
    messageIds: data,
  };
}
```

### Batch with Rate Limiting for Large Lists

```typescript
interface BatchOptions {
  batchSize?: number;
  delayBetweenBatches?: number; // milliseconds
  retryAttempts?: number;
}

async function sendLargeBatch(
  emails: Array<{
    from: string;
    to: string;
    subject: string;
    html: string;
  }>,
  options: BatchOptions = {}
) {
  const {
    batchSize = 100,
    delayBetweenBatches = 1000,
    retryAttempts = 3,
  } = options;

  const results: Array<{
    batchNumber: number;
    success: boolean;
    count: number;
    messageIds?: string[];
    error?: string;
  }> = [];

  for (let i = 0; i < emails.length; i += batchSize) {
    const batchNumber = Math.floor(i / batchSize) + 1;
    const batch = emails.slice(i, i + batchSize);

    console.log(`Processing batch ${batchNumber}...`);

    let lastError: string | null = null;

    for (let attempt = 1; attempt <= retryAttempts; attempt++) {
      try {
        const { data, error } = await resend.batch.send(batch);

        if (error) {
          lastError = error.message;
          if (attempt < retryAttempts) {
            const delay = Math.pow(2, attempt) * 100;
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

    if (results[results.length - 1].success === false) {
      console.error(`Batch ${batchNumber} failed after ${retryAttempts} attempts`);
    }

    // Delay between batches to avoid rate limiting
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
```

### Segmented Batch Sending

```typescript
interface User {
  id: string;
  email: string;
  name: string;
  segment: 'free' | 'premium' | 'enterprise';
}

async function sendSegmentedCampaign(
  users: User[],
  campaign: {
    title: string;
    content: string;
    cta: string;
  }
) {
  const templates: Record<string, (user: User, campaign: any) => string> = {
    free: (user, campaign) => `
      <h2>Hello ${user.name}!</h2>
      <p>${campaign.content}</p>
      <p>
        <a href="https://example.com/upgrade">Upgrade to Premium</a>
      </p>
      <p>${campaign.cta}</p>
    `,

    premium: (user, campaign) => `
      <h2>Hello ${user.name}!</h2>
      <p>${campaign.content}</p>
      <p>
        <a href="https://example.com/premium-features">${campaign.cta}</a>
      </p>
    `,

    enterprise: (user, campaign) => `
      <h2>Hello ${user.name}!</h2>
      <p>${campaign.content}</p>
      <p>
        <a href="https://example.com/contact-sales">${campaign.cta}</a>
      </p>
    `,
  };

  const segments = {
    free: users.filter(u => u.segment === 'free'),
    premium: users.filter(u => u.segment === 'premium'),
    enterprise: users.filter(u => u.segment === 'enterprise'),
  };

  const results: Record<string, any> = {};

  for (const [segment, segmentUsers] of Object.entries(segments)) {
    if (segmentUsers.length === 0) continue;

    const emails = segmentUsers.map(user => ({
      from: 'marketing@example.com',
      to: user.email,
      subject: campaign.title,
      html: templates[segment](user, campaign),
    }));

    const { data, error } = await resend.batch.send(emails);

    results[segment] = {
      totalSent: segmentUsers.length,
      success: !error,
      error: error?.message,
    };

    // Rate limiting between segments
    await new Promise(resolve => setTimeout(resolve, 500));
  }

  return results;
}
```

### Batch with Personalization

```typescript
interface PersonalizedEmail {
  to: string;
  subject: string;
  variables: Record<string, string>;
}

async function sendPersonalizedBatch(
  emails: PersonalizedEmail[],
  htmlTemplate: (vars: Record<string, string>) => string
) {
  if (emails.length > 100) {
    throw new Error('Batch size cannot exceed 100');
  }

  const batchEmails = emails.map(email => ({
    from: 'notifications@example.com',
    to: email.to,
    subject: email.subject,
    html: htmlTemplate(email.variables),
  }));

  return resend.batch.send(batchEmails);
}

// Usage
const emails: PersonalizedEmail[] = [
  {
    to: 'user1@example.com',
    subject: 'Hello John!',
    variables: {
      firstName: 'John',
      userId: 'usr_123',
      plan: 'Professional',
      renewalDate: '2024-12-31',
    },
  },
  {
    to: 'user2@example.com',
    subject: 'Hello Jane!',
    variables: {
      firstName: 'Jane',
      userId: 'usr_456',
      plan: 'Enterprise',
      renewalDate: '2025-06-30',
    },
  },
];

const htmlTemplate = (vars: Record<string, string>) => `
  <h2>Hello ${vars.firstName}!</h2>
  <p>Your <strong>${vars.plan}</strong> plan renews on ${vars.renewalDate}</p>
  <p>
    <a href="https://app.example.com/account?id=${vars.userId}">
      Manage Your Account
    </a>
  </p>
`;

await sendPersonalizedBatch(emails, htmlTemplate);
```

## Python Example

### Basic Batch Sending

```python
import os
from typing import List
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_newsletter_batch(recipients: List[dict], content: str):
    """Send newsletter to batch of recipients."""
    if len(recipients) > 100:
        raise ValueError("Batch size cannot exceed 100 recipients")

    emails = []
    for recipient in recipients:
        email = {
            "from": "newsletter@example.com",
            "to": recipient["email"],
            "subject": "Weekly Newsletter",
            "html": f"""
                <h2>Hello {recipient['name']},</h2>
                <div>{content}</div>
                <p>
                    <a href="https://example.com/unsubscribe?email={recipient['email']}">
                        Unsubscribe
                    </a>
                </p>
            """,
        }
        emails.append(email)

    response = client.batch.send(emails)

    if response.get("error"):
        print(f"Batch send failed: {response['error']}")
        return {"success": False, "error": response["error"]}

    print(f"Batch sent to {len(recipients)} recipients")
    return {
        "success": True,
        "total_sent": len(recipients),
    }
```

### Large Batch with Rate Limiting

```python
import os
import time
from typing import List, Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_large_batch(
    emails: List[Dict],
    batch_size: int = 100,
    delay_between_batches: int = 1000,
    retry_attempts: int = 3,
):
    """Send large batch with rate limiting and retry logic."""
    results = []

    for i in range(0, len(emails), batch_size):
        batch_number = (i // batch_size) + 1
        batch = emails[i : i + batch_size]

        print(f"Processing batch {batch_number}...")

        last_error = None

        for attempt in range(1, retry_attempts + 1):
            try:
                response = client.batch.send(batch)

                if response.get("error"):
                    last_error = response["error"]
                    if attempt < retry_attempts:
                        delay = (2 ** attempt) * 100
                        time.sleep(delay / 1000)  # Convert to seconds
                        continue

                results.append({
                    "batch_number": batch_number,
                    "success": True,
                    "count": len(batch),
                })
                break

            except Exception as err:
                last_error = str(err)

        if not results or not results[-1]["success"]:
            results.append({
                "batch_number": batch_number,
                "success": False,
                "count": len(batch),
                "error": str(last_error),
            })

        # Delay between batches
        if i + batch_size < len(emails):
            time.sleep(delay_between_batches / 1000)  # Convert to seconds

    return {
        "total_emails": len(emails),
        "successful_batches": sum(1 for r in results if r["success"]),
        "failed_batches": sum(1 for r in results if not r["success"]),
        "details": results,
    }
```

### Segmented Campaign

```python
import os
from typing import List, Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

TEMPLATES = {
    "free": """
        <h2>Hello {name}!</h2>
        <p>{content}</p>
        <p>
            <a href="https://example.com/upgrade">Upgrade to Premium</a>
        </p>
    """,
    "premium": """
        <h2>Hello {name}!</h2>
        <p>{content}</p>
        <p>
            <a href="https://example.com/premium-features">View Premium Features</a>
        </p>
    """,
    "enterprise": """
        <h2>Hello {name}!</h2>
        <p>{content}</p>
        <p>
            <a href="https://example.com/contact-sales">Contact Sales</a>
        </p>
    """,
}

def send_segmented_campaign(
    users: List[Dict],
    campaign: Dict,
):
    """Send campaign with different templates per segment."""
    segments = {}

    # Group users by segment
    for user in users:
        segment = user.get("segment", "free")
        if segment not in segments:
            segments[segment] = []
        segments[segment].append(user)

    results = {}

    for segment, segment_users in segments.items():
        if not segment_users:
            continue

        emails = []
        for user in segment_users:
            template = TEMPLATES.get(segment, TEMPLATES["free"])
            email = {
                "from": "marketing@example.com",
                "to": user["email"],
                "subject": campaign["title"],
                "html": template.format(
                    name=user["name"],
                    content=campaign["content"],
                ),
            }
            emails.append(email)

        response = client.batch.send(emails)

        results[segment] = {
            "total_sent": len(segment_users),
            "success": not response.get("error"),
            "error": response.get("error"),
        }

        # Rate limiting between segments
        time.sleep(0.5)

    return results
```

### Batch with Personalization

```python
import os
from typing import List, Dict, Callable
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_personalized_batch(
    emails: List[Dict],
    html_template: Callable[[Dict], str],
):
    """Send batch with personalized content."""
    if len(emails) > 100:
        raise ValueError("Batch size cannot exceed 100")

    batch_emails = []
    for email in emails:
        batch_email = {
            "from": "notifications@example.com",
            "to": email["to"],
            "subject": email["subject"],
            "html": html_template(email["variables"]),
        }
        batch_emails.append(batch_email)

    return client.batch.send(batch_emails)

# Usage
emails = [
    {
        "to": "user1@example.com",
        "subject": "Hello John!",
        "variables": {
            "first_name": "John",
            "user_id": "usr_123",
            "plan": "Professional",
            "renewal_date": "2024-12-31",
        },
    },
    {
        "to": "user2@example.com",
        "subject": "Hello Jane!",
        "variables": {
            "first_name": "Jane",
            "user_id": "usr_456",
            "plan": "Enterprise",
            "renewal_date": "2025-06-30",
        },
    },
]

def html_template(variables: Dict) -> str:
    return f"""
        <h2>Hello {variables['first_name']}!</h2>
        <p>Your <strong>{variables['plan']}</strong> plan renews on {variables['renewal_date']}</p>
        <p>
            <a href="https://app.example.com/account?id={variables['user_id']}">
                Manage Your Account
            </a>
        </p>
    """

send_personalized_batch(emails, html_template)
```

## Best Practices

1. **Respect Batch Limits** - Keep batches to 100 or fewer recipients
2. **Implement Rate Limiting** - Add delays between batches to avoid throttling
3. **Retry Failed Batches** - Use exponential backoff for transient failures
4. **Segment Users** - Tailor content based on user segments
5. **Personalize When Possible** - Use recipient data in templates
6. **Monitor Delivery** - Track success/failure rates
7. **Log Results** - Keep records of batch operations
8. **Test First** - Send test batches before large campaigns
9. **Validate Lists** - Clean email lists before sending
10. **Handle Unsubscribes** - Always provide unsubscribe links

## Monitoring

```typescript
async function monitorBatchDelivery(messageIds: string[]) {
  // Implement tracking using webhooks or status endpoints
  const results = await Promise.all(
    messageIds.map(id => checkEmailStatus(id))
  );

  return {
    total: messageIds.length,
    delivered: results.filter(r => r.status === 'delivered').length,
    bounced: results.filter(r => r.status === 'bounced').length,
    complained: results.filter(r => r.status === 'complained').length,
  };
}
```

## Rate Limiting Strategy

- Free tier: 100 emails/second
- Pro tier: 1000 emails/second
- Batch requests: Queue up to 100 at a time
- Always wait between batches: 500-1000ms delay recommended
