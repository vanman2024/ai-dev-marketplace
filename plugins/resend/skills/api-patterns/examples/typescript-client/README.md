# TypeScript Resend Client Setup

Complete TypeScript client setup with authentication, rate limiting, and error handling.

## Installation

```bash
npm install resend dotenv
# or
yarn add resend dotenv
# or
pnpm add resend dotenv
```

## Environment Setup

Create `.env` file in your project root:

```bash
# .env
RESEND_API_KEY=your_resend_api_key_here
```

Add `.env` to `.gitignore`:

```bash
# .gitignore
.env
.env.local
.env.*.local
node_modules/
```

## Basic Client Initialization

```typescript
import { Resend } from 'resend';
import dotenv from 'dotenv';

dotenv.config();

// Initialize client
const resend = new Resend(process.env.RESEND_API_KEY);

// Verify API key is set
if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY environment variable is required');
}
```

## Complete Client with Error Handling

```typescript
import { Resend } from 'resend';
import dotenv from 'dotenv';

dotenv.config();

interface EmailPayload {
  from: string;
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  cc?: string[];
  bcc?: string[];
  reply_to?: string;
  attachments?: Array<{ filename: string; content: Buffer | string }>;
}

interface APIResponse<T> {
  data?: T;
  error?: {
    message: string;
    code?: string;
  };
}

class ResendClient {
  private resend: Resend;
  private maxRetries = 3;
  private initialDelayMs = 100;

  constructor(apiKey: string) {
    if (!apiKey) {
      throw new Error('API key is required');
    }
    this.resend = new Resend(apiKey);
  }

  /**
   * Send email with automatic retry on transient failures
   */
  async sendEmail(payload: EmailPayload): Promise<APIResponse<{ id: string }>> {
    return this.withRetry(
      () => this.resend.emails.send(payload),
      'send email'
    );
  }

  /**
   * Send batch of emails
   */
  async sendBatch(
    emails: EmailPayload[]
  ): Promise<APIResponse<{ id: string }[]>> {
    return this.withRetry(
      () => this.resend.batch.send(emails),
      'send batch emails'
    );
  }

  /**
   * Retry logic with exponential backoff
   */
  private async withRetry<T>(
    fn: () => Promise<T>,
    operationName: string
  ): Promise<APIResponse<T>> {
    let lastError: any = null;
    let delayMs = this.initialDelayMs;

    for (let attempt = 1; attempt <= this.maxRetries; attempt++) {
      try {
        const data = await fn();
        return { data };
      } catch (error: any) {
        lastError = error;

        const statusCode = error.response?.status;
        const isRetryable = this.isRetryableError(statusCode, error);

        if (!isRetryable || attempt === this.maxRetries) {
          return {
            error: {
              message: error.message || `Failed to ${operationName}`,
              code: statusCode?.toString(),
            },
          };
        }

        console.warn(
          `[Attempt ${attempt}/${this.maxRetries}] ${operationName} failed: ${error.message}. ` +
          `Retrying in ${delayMs}ms...`
        );

        await this.delay(delayMs);
        delayMs = Math.min(delayMs * 2, 30000); // Exponential backoff up to 30s
      }
    }

    return {
      error: {
        message: lastError?.message || `Failed to ${operationName} after ${this.maxRetries} attempts`,
        code: lastError?.response?.status?.toString(),
      },
    };
  }

  /**
   * Determine if error is retryable (transient)
   */
  private isRetryableError(statusCode: number | undefined, error: any): boolean {
    // Retry on rate limit (429), server errors (5xx), and timeout errors
    const retryableStatusCodes = [408, 429, 500, 502, 503, 504];

    if (statusCode && retryableStatusCodes.includes(statusCode)) {
      return true;
    }

    // Check for timeout or connection errors
    const errorMessage = error.message?.toLowerCase() || '';
    return (
      errorMessage.includes('timeout') ||
      errorMessage.includes('econnrefused') ||
      errorMessage.includes('enotfound')
    );
  }

  /**
   * Helper to delay execution
   */
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

// Export for use in other modules
export { ResendClient, EmailPayload, APIResponse };
```

## Usage Examples

### Send Single Email

```typescript
import { ResendClient } from './client';

async function main() {
  const client = new ResendClient(process.env.RESEND_API_KEY!);

  const result = await client.sendEmail({
    from: 'notifications@example.com',
    to: 'user@example.com',
    subject: 'Welcome!',
    html: '<h1>Welcome</h1><p>Thanks for signing up!</p>',
  });

  if (result.error) {
    console.error('Error sending email:', result.error);
    process.exit(1);
  }

  console.log('Email sent! ID:', result.data?.id);
}

main().catch(console.error);
```

### Send Batch Emails

```typescript
import { ResendClient } from './client';

async function sendNewsletterBatch() {
  const client = new ResendClient(process.env.RESEND_API_KEY!);

  const subscribers = [
    { email: 'user1@example.com', name: 'User 1' },
    { email: 'user2@example.com', name: 'User 2' },
    { email: 'user3@example.com', name: 'User 3' },
  ];

  const emails = subscribers.map(sub => ({
    from: 'newsletter@example.com',
    to: sub.email,
    subject: 'Monthly Newsletter',
    html: `<h1>Hello ${sub.name}</h1><p>Here's this month's news...</p>`,
  }));

  const result = await client.sendBatch(emails);

  if (result.error) {
    console.error('Error sending batch:', result.error);
    return;
  }

  console.log(`Batch sent! IDs: ${result.data?.map(e => e.id).join(', ')}`);
}

sendNewsletterBatch().catch(console.error);
```

### Send Email with Attachment

```typescript
import fs from 'fs';
import path from 'path';
import { ResendClient } from './client';

async function sendEmailWithAttachment() {
  const client = new ResendClient(process.env.RESEND_API_KEY!);

  const filePath = path.join(__dirname, 'documents', 'report.pdf');
  const fileContent = fs.readFileSync(filePath);

  const result = await client.sendEmail({
    from: 'reports@example.com',
    to: 'manager@example.com',
    subject: 'Monthly Report',
    html: '<p>Please find the attached report.</p>',
    attachments: [
      {
        filename: 'report.pdf',
        content: fileContent,
      },
    ],
  });

  if (result.error) {
    console.error('Error:', result.error);
    return;
  }

  console.log('Email with attachment sent! ID:', result.data?.id);
}

sendEmailWithAttachment().catch(console.error);
```

### Advanced Client with Rate Limiting

```typescript
import { Resend } from 'resend';

class RateLimitedResendClient {
  private queue: Array<() => Promise<any>> = [];
  private isProcessing = false;
  private requestsPerSecond = 2;
  private lastRequestTime = 0;

  constructor(private resend: Resend) {}

  /**
   * Queue email send with rate limiting
   */
  async sendEmailQueued(payload: any): Promise<any> {
    return new Promise((resolve, reject) => {
      this.queue.push(async () => {
        try {
          const result = await this.resend.emails.send(payload);
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });

      this.processQueue();
    });
  }

  /**
   * Process queue with rate limiting
   */
  private async processQueue() {
    if (this.isProcessing || this.queue.length === 0) {
      return;
    }

    this.isProcessing = true;

    while (this.queue.length > 0) {
      const now = Date.now();
      const timeSinceLastRequest = now - this.lastRequestTime;
      const delayNeeded = (1000 / this.requestsPerSecond) - timeSinceLastRequest;

      if (delayNeeded > 0) {
        await new Promise(resolve => setTimeout(resolve, delayNeeded));
      }

      const request = this.queue.shift();
      if (request) {
        await request();
        this.lastRequestTime = Date.now();
      }
    }

    this.isProcessing = false;
  }
}
```

## Error Handling Patterns

### Handle Specific Errors

```typescript
import { ResendClient } from './client';

async function sendWithErrorHandling() {
  const client = new ResendClient(process.env.RESEND_API_KEY!);

  try {
    const result = await client.sendEmail({
      from: 'noreply@example.com',
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test email</p>',
    });

    if (result.error) {
      switch (result.error.code) {
        case '401':
          console.error('Invalid API key');
          break;
        case '429':
          console.error('Rate limit exceeded');
          break;
        case '500':
          console.error('Server error - will retry');
          break;
        default:
          console.error('Unknown error:', result.error.message);
      }
      return;
    }

    console.log('Email sent:', result.data?.id);
  } catch (error) {
    console.error('Unexpected error:', error);
    process.exit(1);
  }
}

sendWithErrorHandling().catch(console.error);
```

## TypeScript Configuration

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Testing Client

### Unit Test Example (Jest)

```typescript
import { ResendClient } from './client';

describe('ResendClient', () => {
  let client: ResendClient;

  beforeEach(() => {
    process.env.RESEND_API_KEY = 'test_key_12345';
    client = new ResendClient(process.env.RESEND_API_KEY);
  });

  test('should initialize with API key', () => {
    expect(client).toBeDefined();
  });

  test('should throw error if API key missing', () => {
    expect(() => new ResendClient('')).toThrow('API key is required');
  });

  test('should handle missing API key', async () => {
    const result = await client.sendEmail({
      from: 'test@example.com',
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });

    expect(result.error).toBeDefined();
  });
});
```

## Deployment Considerations

### Environment Variables for Production

```bash
# .env.production
RESEND_API_KEY=prod_your_resend_api_key_here
RESEND_REQUEST_TIMEOUT=30000
RESEND_MAX_RETRIES=5
```

### Monitoring and Logging

```typescript
import { ResendClient } from './client';
import logger from './logger'; // Your logging service

const client = new ResendClient(process.env.RESEND_API_KEY!);

// Wrap with monitoring
async function sendEmailWithMonitoring(payload: any) {
  const startTime = Date.now();

  try {
    const result = await client.sendEmail(payload);
    const duration = Date.now() - startTime;

    if (result.error) {
      logger.error('Email send failed', {
        error: result.error,
        duration,
        payload: {
          to: payload.to,
          from: payload.from,
        },
      });
    } else {
      logger.info('Email sent successfully', {
        emailId: result.data?.id,
        duration,
        to: payload.to,
      });
    }

    return result;
  } catch (error) {
    logger.error('Unexpected error sending email', {
      error: error instanceof Error ? error.message : String(error),
      payload: {
        to: payload.to,
        from: payload.from,
      },
    });
    throw error;
  }
}
```

## Resources

- [Resend TypeScript SDK](https://resend.com/docs/sdks/typescript)
- [API Reference](https://resend.com/docs/api-reference)
- [Authentication](https://resend.com/docs/knowledge-base/authentication)
