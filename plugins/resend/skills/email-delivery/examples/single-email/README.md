# Single Email Delivery

Basic patterns for sending individual transactional emails with Resend.

## Use Cases

- Account confirmation emails
- Password reset notifications
- Order confirmations
- Notification alerts
- Welcome messages

## TypeScript Example

### Basic Transactional Email

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

async function sendConfirmationEmail(userEmail: string, confirmationCode: string) {
  const { data, error } = await resend.emails.send({
    from: 'noreply@example.com',
    to: userEmail,
    subject: 'Confirm Your Email Address',
    html: `
      <h2>Email Confirmation</h2>
      <p>Please confirm your email by clicking the link below:</p>
      <p>
        <a href="https://example.com/confirm?code=${confirmationCode}">
          Confirm Email
        </a>
      </p>
      <p>Or enter this code: <strong>${confirmationCode}</strong></p>
      <p>This link expires in 24 hours.</p>
    `,
  });

  if (error) {
    console.error('Email send failed:', error);
    return { success: false, error };
  }

  console.log('Email sent successfully:', data.id);
  return { success: true, messageId: data.id };
}
```

### With Error Handling and Logging

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

interface SendEmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
  from?: string;
}

async function sendEmail(options: SendEmailOptions) {
  const {
    to,
    subject,
    html,
    text,
    from = 'notifications@example.com',
  } = options;

  try {
    // Validate email format
    if (!to.includes('@')) {
      throw new Error('Invalid email address');
    }

    const { data, error } = await resend.emails.send({
      from,
      to,
      subject,
      html,
      text: text || stripHtmlTags(html), // Fallback text version
    });

    if (error) {
      throw new Error(`Resend API error: ${error.message}`);
    }

    console.log(`Email sent to ${to}`, {
      messageId: data.id,
      timestamp: new Date().toISOString(),
    });

    return {
      success: true,
      messageId: data.id,
      timestamp: new Date().toISOString(),
    };
  } catch (err) {
    console.error('Failed to send email:', {
      error: err instanceof Error ? err.message : String(err),
      recipient: to,
      subject,
      timestamp: new Date().toISOString(),
    });

    return {
      success: false,
      error: err instanceof Error ? err.message : String(err),
      recipient: to,
    };
  }
}

function stripHtmlTags(html: string): string {
  return html.replace(/<[^>]*>/g, '').trim();
}
```

### With Template Variables

```typescript
interface EmailTemplate {
  name: string;
  subject: string;
  getHtml: (data: Record<string, string>) => string;
  getText?: (data: Record<string, string>) => string;
}

const templates: Record<string, EmailTemplate> = {
  welcome: {
    name: 'Welcome Email',
    subject: 'Welcome to Example App',
    getHtml: (data) => `
      <h1>Welcome, ${data.firstName}!</h1>
      <p>We're excited to have you on board.</p>
      <p>
        <a href="${data.dashboardUrl}">Get Started</a>
      </p>
    `,
  },

  passwordReset: {
    name: 'Password Reset',
    subject: 'Reset Your Password',
    getHtml: (data) => `
      <h2>Password Reset Request</h2>
      <p>Click the link below to reset your password:</p>
      <p>
        <a href="${data.resetLink}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
          Reset Password
        </a>
      </p>
      <p>Link expires in 1 hour.</p>
    `,
  },

  orderConfirmation: {
    name: 'Order Confirmation',
    subject: 'Your Order Confirmation',
    getHtml: (data) => `
      <h2>Order Confirmed</h2>
      <p>Thank you for your order!</p>
      <p>Order ID: <strong>${data.orderId}</strong></p>
      <p>Total: <strong>${data.total}</strong></p>
      <p>
        <a href="${data.trackingUrl}">Track Your Order</a>
      </p>
    `,
  },
};

async function sendTemplateEmail(
  templateName: string,
  to: string,
  data: Record<string, string>
) {
  const template = templates[templateName];

  if (!template) {
    throw new Error(`Template not found: ${templateName}`);
  }

  return resend.emails.send({
    from: 'noreply@example.com',
    to,
    subject: template.subject,
    html: template.getHtml(data),
    text: template.getText?.(data),
  });
}

// Usage examples
await sendTemplateEmail('welcome', 'user@example.com', {
  firstName: 'John',
  dashboardUrl: 'https://app.example.com/dashboard',
});

await sendTemplateEmail('passwordReset', 'user@example.com', {
  resetLink: 'https://example.com/reset?token=abc123',
});

await sendTemplateEmail('orderConfirmation', 'user@example.com', {
  orderId: 'ORD-12345',
  total: '$99.99',
  trackingUrl: 'https://example.com/track/ORD-12345',
});
```

## Python Example

### Basic Transactional Email

```python
import os
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_confirmation_email(user_email: str, confirmation_code: str):
    """Send email confirmation."""
    email = {
        "from": "noreply@example.com",
        "to": user_email,
        "subject": "Confirm Your Email Address",
        "html": f"""
            <h2>Email Confirmation</h2>
            <p>Please confirm your email by clicking the link below:</p>
            <p>
                <a href="https://example.com/confirm?code={confirmation_code}">
                    Confirm Email
                </a>
            </p>
            <p>Or enter this code: <strong>{confirmation_code}</strong></p>
            <p>This link expires in 24 hours.</p>
        """,
    }

    response = client.emails.send(email)

    if response.get("error"):
        print(f"Error sending email: {response['error']}")
        return {"success": False, "error": response["error"]}

    print(f"Email sent successfully: {response['data']['id']}")
    return {"success": True, "message_id": response["data"]["id"]}
```

### With Error Handling

```python
import os
import re
from datetime import datetime
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

def send_email(
    to: str,
    subject: str,
    html: str,
    text: str = None,
    from_email: str = "notifications@example.com",
):
    """Send email with error handling."""
    try:
        # Validate email format
        email_pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        if not re.match(email_pattern, to):
            raise ValueError("Invalid email address")

        email_payload = {
            "from": from_email,
            "to": to,
            "subject": subject,
            "html": html,
        }

        # Add plain text version if provided
        if text:
            email_payload["text"] = text
        else:
            # Strip HTML tags for text version
            email_payload["text"] = re.sub(r"<[^>]*>", "", html).strip()

        response = client.emails.send(email_payload)

        if response.get("error"):
            raise Exception(f"Resend API error: {response['error']}")

        print(f"Email sent to {to}", {
            "message_id": response["data"]["id"],
            "timestamp": datetime.now().isoformat(),
        })

        return {
            "success": True,
            "message_id": response["data"]["id"],
            "timestamp": datetime.now().isoformat(),
        }

    except Exception as err:
        print(f"Failed to send email: {str(err)}", {
            "recipient": to,
            "subject": subject,
            "timestamp": datetime.now().isoformat(),
        })

        return {
            "success": False,
            "error": str(err),
            "recipient": to,
        }
```

### With Template System

```python
import os
from typing import Dict
from resend import Resend

client = Resend(api_key=os.environ.get("RESEND_API_KEY"))

TEMPLATES = {
    "welcome": {
        "name": "Welcome Email",
        "subject": "Welcome to Example App",
        "html_template": """
            <h1>Welcome, {first_name}!</h1>
            <p>We're excited to have you on board.</p>
            <p>
                <a href="{dashboard_url}">Get Started</a>
            </p>
        """,
    },
    "password_reset": {
        "name": "Password Reset",
        "subject": "Reset Your Password",
        "html_template": """
            <h2>Password Reset Request</h2>
            <p>Click the link below to reset your password:</p>
            <p>
                <a href="{reset_link}" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px; display: inline-block;">
                    Reset Password
                </a>
            </p>
            <p>Link expires in 1 hour.</p>
        """,
    },
    "order_confirmation": {
        "name": "Order Confirmation",
        "subject": "Your Order Confirmation",
        "html_template": """
            <h2>Order Confirmed</h2>
            <p>Thank you for your order!</p>
            <p>Order ID: <strong>{order_id}</strong></p>
            <p>Total: <strong>{total}</strong></p>
            <p>
                <a href="{tracking_url}">Track Your Order</a>
            </p>
        """,
    },
}

def send_template_email(
    template_name: str,
    to: str,
    data: Dict[str, str],
):
    """Send email using template."""
    if template_name not in TEMPLATES:
        raise ValueError(f"Template not found: {template_name}")

    template = TEMPLATES[template_name]

    email = {
        "from": "noreply@example.com",
        "to": to,
        "subject": template["subject"],
        "html": template["html_template"].format(**data),
    }

    return client.emails.send(email)

# Usage examples
send_template_email("welcome", "user@example.com", {
    "first_name": "John",
    "dashboard_url": "https://app.example.com/dashboard",
})

send_template_email("password_reset", "user@example.com", {
    "reset_link": "https://example.com/reset?token=abc123",
})

send_template_email("order_confirmation", "user@example.com", {
    "order_id": "ORD-12345",
    "total": "$99.99",
    "tracking_url": "https://example.com/track/ORD-12345",
})
```

## Environment Setup

Create a `.env` file:

```bash
RESEND_API_KEY=your_resend_key_here
```

Load the environment variable:

```typescript
// TypeScript
import dotenv from 'dotenv';
dotenv.config();
```

```python
# Python
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("RESEND_API_KEY")
```

## Testing

### TypeScript Test Example

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('Email Sending', () => {
  it('should send confirmation email', async () => {
    const result = await sendConfirmationEmail(
      'test@example.com',
      'ABC123'
    );

    expect(result.success).toBe(true);
    expect(result.messageId).toBeDefined();
  });

  it('should handle invalid email addresses', async () => {
    const result = await sendEmail({
      to: 'invalid-email',
      subject: 'Test',
      html: '<p>Test</p>',
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid');
  });
});
```

### Python Test Example

```python
import pytest
from unittest.mock import patch

def test_send_confirmation_email():
    with patch('resend.Resend.emails.send') as mock_send:
        mock_send.return_value = {
            "data": {"id": "msg-123"},
        }

        result = send_confirmation_email("test@example.com", "ABC123")

        assert result["success"] is True
        assert result["message_id"] == "msg-123"
```

## Best Practices

1. **Always provide text fallback** - Strip HTML for clients that don't support it
2. **Validate email addresses** - Check format before sending
3. **Handle errors gracefully** - Log failures and implement retry logic
4. **Use templates** - Maintain consistency and reduce code duplication
5. **Set appropriate reply-to** - Make it easy for users to respond
6. **Include unsubscribe info** - For marketing emails
7. **Test across clients** - Use email testing services like Litmus
8. **Monitor delivery** - Track bounces and complaints
