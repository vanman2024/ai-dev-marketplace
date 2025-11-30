# Scheduled Email Delivery

Patterns for scheduling emails to be sent at specific times in the future.

## Use Cases

- Onboarding email sequences
- Birthday/Anniversary emails
- Delayed notifications
- Reminder emails
- Time-zone aware sending
- Campaign scheduling

## TypeScript Example

### Basic Scheduled Email

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

async function scheduleWelcomeEmail(
  userEmail: string,
  firstName: string,
  delayMinutes: number = 5
) {
  // Calculate scheduled time
  const scheduledDate = new Date();
  scheduledDate.setMinutes(scheduledDate.getMinutes() + delayMinutes);

  const { data, error } = await resend.emails.send({
    from: 'onboarding@example.com',
    to: userEmail,
    subject: 'Welcome to Example App!',
    html: `
      <h1>Welcome, ${firstName}!</h1>
      <p>Get started with our app in 3 easy steps:</p>
      <ol>
        <li>Complete your profile</li>
        <li>Invite team members</li>
        <li>Start using the app</li>
      </ol>
      <p>
        <a href="https://app.example.com/onboarding">
          Begin Onboarding
        </a>
      </p>
    `,
    scheduled_at: scheduledDate.toISOString(),
  });

  if (error) {
    console.error('Failed to schedule email:', error);
    return { success: false, error };
  }

  console.log(`Email scheduled for ${scheduledDate.toISOString()}`);
  return {
    success: true,
    messageId: data.id,
    scheduledAt: scheduledDate.toISOString(),
  };
}
```

### Onboarding Sequence

```typescript
interface OnboardingStep {
  delayHours: number;
  subject: string;
  html: string;
}

const onboardingSequence: OnboardingStep[] = [
  {
    delayHours: 0,
    subject: 'Welcome to Example!',
    html: '<p>Your account is ready. Get started now.</p>',
  },
  {
    delayHours: 24,
    subject: 'Pro Tip: How to Optimize Your Setup',
    html: '<p>Here are some best practices...</p>',
  },
  {
    delayHours: 72,
    subject: 'Explore Advanced Features',
    html: '<p>Unlock more power with these features...</p>',
  },
  {
    delayHours: 168, // 1 week
    subject: 'We Want Your Feedback',
    html: '<p>How is your experience? Share feedback...</p>',
  },
];

async function scheduleOnboardingSequence(
  userEmail: string,
  firstName: string
) {
  const results = [];

  for (const step of onboardingSequence) {
    const scheduledDate = new Date();
    scheduledDate.setHours(scheduledDate.getHours() + step.delayHours);

    const { data, error } = await resend.emails.send({
      from: 'onboarding@example.com',
      to: userEmail,
      subject: step.subject,
      html: `<h2>${step.subject}</h2>${step.html}<p>Welcome, ${firstName}!</p>`,
      scheduled_at: scheduledDate.toISOString(),
    });

    results.push({
      step: onboardingSequence.indexOf(step) + 1,
      success: !error,
      scheduledAt: scheduledDate.toISOString(),
      messageId: data?.id,
      error: error?.message,
    });

    // Avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  return results;
}
```

### Time-Zone Aware Scheduling

```typescript
function scheduleForTimeZone(
  targetHour: number,
  targetMinute: number,
  userTimeZone: string
): Date {
  // Get current time in user's timezone
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: userTimeZone,
  });

  const now = new Date();
  const userTime = new Date(formatter.format(now));

  // Calculate offset
  const utcTime = new Date();
  const offsetMs = userTime.getTime() - utcTime.getTime();

  // Create target time
  const targetTime = new Date();
  targetTime.setHours(targetHour, targetMinute, 0, 0);
  targetTime.setTime(targetTime.getTime() - offsetMs);

  // If time has passed today, schedule for tomorrow
  if (targetTime < now) {
    targetTime.setDate(targetTime.getDate() + 1);
  }

  return targetTime;
}

async function scheduleAtUserTime(
  userEmail: string,
  hour: number,
  minute: number,
  timeZone: string
) {
  const scheduledTime = scheduleForTimeZone(hour, minute, timeZone);

  return resend.emails.send({
    from: 'reminders@example.com',
    to: userEmail,
    subject: 'Daily Reminder',
    html: '<p>Your daily reminder at your preferred time.</p>',
    scheduled_at: scheduledTime.toISOString(),
  });
}

// Usage
await scheduleAtUserTime(
  'user@example.com',
  9, // 9 AM
  0,
  'America/New_York'
);
```

### Recurring Scheduled Emails (via Batch)

```typescript
async function scheduleBirthdayEmails(users: Array<{
  email: string;
  name: string;
  birthDate: string; // YYYY-MM-DD
}>) {
  const emails = users.map(user => {
    // Parse birth date
    const [year, month, day] = user.birthDate.split('-');

    // Schedule for this year
    let birthdayDate = new Date(`${new Date().getFullYear()}-${month}-${day}`);

    // If birthday has passed, schedule for next year
    if (birthdayDate < new Date()) {
      birthdayDate.setFullYear(birthdayDate.getFullYear() + 1);
    }

    // Schedule for 8 AM in their timezone (assuming UTC for simplicity)
    birthdayDate.setHours(8, 0, 0, 0);

    return {
      from: 'birthday@example.com',
      to: user.email,
      subject: `Happy Birthday, ${user.name}!`,
      html: `
        <h1>Happy Birthday, ${user.name}!</h1>
        <p>We hope you have an amazing day!</p>
      `,
      scheduled_at: birthdayDate.toISOString(),
    };
  });

  return resend.batch.send(emails);
}
```

### Campaign Scheduling with Delay Ladder

```typescript
interface CampaignSchedule {
  email: string;
  delayMinutes: number;
}

async function scheduleStaggeredCampaign(
  recipients: string[],
  campaignContent: string,
  staggerMinutes: number = 5
) {
  const schedules: CampaignSchedule[] = recipients.map((email, index) => ({
    email,
    delayMinutes: index * staggerMinutes,
  }));

  const results = [];

  for (const schedule of schedules) {
    const scheduledDate = new Date();
    scheduledDate.setMinutes(scheduledDate.getMinutes() + schedule.delayMinutes);

    const { data, error } = await resend.emails.send({
      from: 'campaigns@example.com',
      to: schedule.email,
      subject: 'Special Campaign Offer',
      html: campaignContent,
      scheduled_at: scheduledDate.toISOString(),
    });

    results.push({
      email: schedule.email,
      success: !error,
      scheduledAt: scheduledDate.toISOString(),
    });

    // Rate limiting
    await new Promise(resolve => setTimeout(resolve, 50));
  }

  return results;
}
```

## Python Example

### Basic Scheduled Email

```python
import os
from datetime import datetime, timedelta
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def schedule_welcome_email(
    user_email: str,
    first_name: str,
    delay_minutes: int = 5,
):
    """Schedule welcome email for future delivery."""
    # Calculate scheduled time
    scheduled_date = datetime.utcnow() + timedelta(minutes=delay_minutes)

    email = {
        "from": "onboarding@example.com",
        "to": user_email,
        "subject": "Welcome to Example App!",
        "html": f"""
            <h1>Welcome, {first_name}!</h1>
            <p>Get started with our app in 3 easy steps:</p>
            <ol>
                <li>Complete your profile</li>
                <li>Invite team members</li>
                <li>Start using the app</li>
            </ol>
            <p>
                <a href="https://app.example.com/onboarding">
                    Begin Onboarding
                </a>
            </p>
        """,
        "scheduled_at": scheduled_date.isoformat() + "Z",
    }

    response = client.emails.send(email)

    if response.get("error"):
        print(f"Failed to schedule email: {response['error']}")
        return {"success": False, "error": response["error"]}

    print(f"Email scheduled for {scheduled_date.isoformat()}")
    return {
        "success": True,
        "message_id": response["data"]["id"],
        "scheduled_at": scheduled_date.isoformat(),
    }
```

### Onboarding Sequence

```python
import os
import time
from datetime import datetime, timedelta
from typing import List, Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

ONBOARDING_SEQUENCE = [
    {
        "delay_hours": 0,
        "subject": "Welcome to Example!",
        "html": "<p>Your account is ready. Get started now.</p>",
    },
    {
        "delay_hours": 24,
        "subject": "Pro Tip: How to Optimize Your Setup",
        "html": "<p>Here are some best practices...</p>",
    },
    {
        "delay_hours": 72,
        "subject": "Explore Advanced Features",
        "html": "<p>Unlock more power with these features...</p>",
    },
    {
        "delay_hours": 168,  # 1 week
        "subject": "We Want Your Feedback",
        "html": "<p>How is your experience? Share feedback...</p>",
    },
]

def schedule_onboarding_sequence(
    user_email: str,
    first_name: str,
) -> List[Dict]:
    """Schedule entire onboarding email sequence."""
    results = []

    for idx, step in enumerate(ONBOARDING_SEQUENCE):
        scheduled_date = datetime.utcnow() + timedelta(hours=step["delay_hours"])

        email = {
            "from": "onboarding@example.com",
            "to": user_email,
            "subject": step["subject"],
            "html": f"""
                <h2>{step['subject']}</h2>
                {step['html']}
                <p>Welcome, {first_name}!</p>
            """,
            "scheduled_at": scheduled_date.isoformat() + "Z",
        }

        response = client.emails.send(email)

        results.append({
            "step": idx + 1,
            "success": not response.get("error"),
            "scheduled_at": scheduled_date.isoformat(),
            "message_id": response.get("data", {}).get("id"),
            "error": response.get("error"),
        })

        # Avoid rate limiting
        time.sleep(0.1)

    return results
```

### Time-Zone Aware Scheduling

```python
import os
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def schedule_for_time_zone(
    target_hour: int,
    target_minute: int,
    user_time_zone: str,
) -> datetime:
    """Calculate scheduled time in user's timezone."""
    # Get current time in user's timezone
    user_tz = ZoneInfo(user_time_zone)
    now = datetime.now(user_tz)

    # Create target time in user's timezone
    target_time = now.replace(hour=target_hour, minute=target_minute, second=0, microsecond=0)

    # If time has passed today, schedule for tomorrow
    if target_time < now:
        target_time += timedelta(days=1)

    return target_time

def schedule_at_user_time(
    user_email: str,
    hour: int,
    minute: int,
    time_zone: str,
):
    """Schedule email at user's preferred time."""
    scheduled_time = schedule_for_time_zone(hour, minute, time_zone)

    email = {
        "from": "reminders@example.com",
        "to": user_email,
        "subject": "Daily Reminder",
        "html": "<p>Your daily reminder at your preferred time.</p>",
        "scheduled_at": scheduled_time.isoformat(),
    }

    return client.emails.send(email)

# Usage
schedule_at_user_time(
    "user@example.com",
    9,  # 9 AM
    0,
    "America/New_York",
)
```

### Birthday Emails

```python
import os
from datetime import datetime
from typing import List, Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def schedule_birthday_emails(
    users: List[Dict],
) -> Dict:
    """Schedule birthday emails for all users."""
    emails = []

    for user in users:
        # Parse birth date (YYYY-MM-DD)
        birth_parts = user["birth_date"].split("-")
        birth_month = birth_parts[1]
        birth_day = birth_parts[2]

        # Create birthday date for this year
        birthday = datetime(
            datetime.now().year,
            int(birth_month),
            int(birth_day),
        )

        # If birthday has passed, schedule for next year
        if birthday < datetime.now():
            birthday = birthday.replace(year=birthday.year + 1)

        # Schedule for 8 AM
        birthday = birthday.replace(hour=8, minute=0, second=0)

        emails.append({
            "from": "birthday@example.com",
            "to": user["email"],
            "subject": f"Happy Birthday, {user['name']}!",
            "html": f"""
                <h1>Happy Birthday, {user['name']}!</h1>
                <p>We hope you have an amazing day!</p>
            """,
            "scheduled_at": birthday.isoformat(),
        })

    response = client.batch.send(emails)

    return {
        "total": len(users),
        "scheduled": not response.get("error"),
        "error": response.get("error"),
    }
```

## Important Considerations

### Scheduling Limits

- **Minimum delay**: 5 minutes from now
- **Maximum delay**: Up to 365 days in advance
- **Time format**: Must be ISO 8601 format (`YYYY-MM-DDTHH:mm:ssZ`)

### Best Practices

1. **Use UTC timestamps** - Always convert to UTC for consistency
2. **Handle timezone conversions** - Use proper timezone libraries
3. **Validate dates** - Ensure scheduled time is in the future
4. **Plan sequences carefully** - Space out emails appropriately
5. **Monitor scheduling** - Log all scheduled emails
6. **Allow cancellation** - Keep ability to cancel scheduled emails
7. **Test scheduling** - Schedule test emails first
8. **Account for rate limits** - Don't schedule too many at once

### Validation Example

```typescript
function validateScheduleTime(scheduledAt: string): boolean {
  const scheduledDate = new Date(scheduledAt);
  const now = new Date();

  // Minimum 5 minutes in future
  const minDate = new Date(now.getTime() + 5 * 60 * 1000);
  if (scheduledDate < minDate) {
    throw new Error('Email must be scheduled at least 5 minutes in advance');
  }

  // Maximum 365 days in future
  const maxDate = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
  if (scheduledDate > maxDate) {
    throw new Error('Email cannot be scheduled more than 365 days in advance');
  }

  return true;
}
```

## Real-World Example: Subscription Renewal Reminders

```typescript
async function scheduleSubscriptionReminders(subscription: {
  userEmail: string;
  renewalDate: Date;
  planName: string;
  amount: number;
}) {
  const renewalDate = new Date(subscription.renewalDate);

  // 7 days before renewal
  const sevenDaysBefore = new Date(renewalDate.getTime() - 7 * 24 * 60 * 60 * 1000);

  // 1 day before renewal
  const oneDayBefore = new Date(renewalDate.getTime() - 1 * 24 * 60 * 60 * 1000);

  const reminders = [
    {
      scheduledAt: sevenDaysBefore,
      subject: 'Your subscription renews in 7 days',
      message: 'Update your payment method if needed.',
    },
    {
      scheduledAt: oneDayBefore,
      subject: 'Your subscription renews tomorrow',
      message: 'Your subscription will renew in 24 hours.',
    },
  ];

  const results = [];

  for (const reminder of reminders) {
    const { data, error } = await resend.emails.send({
      from: 'billing@example.com',
      to: subscription.userEmail,
      subject: reminder.subject,
      html: `
        <h2>${reminder.subject}</h2>
        <p>${reminder.message}</p>
        <p>Plan: ${subscription.planName}</p>
        <p>Amount: $${subscription.amount}</p>
      `,
      scheduled_at: reminder.scheduledAt.toISOString(),
    });

    results.push({
      daysBefore: Math.floor((reminder.scheduledAt.getTime() - Date.now()) / (24 * 60 * 60 * 1000)),
      success: !error,
      messageId: data?.id,
    });
  }

  return results;
}
```
