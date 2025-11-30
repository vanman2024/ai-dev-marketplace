---
name: api-patterns
description: Resend API integration patterns, authentication, error handling, and rate limiting. Use when implementing API clients, handling authentication, managing rate limits, implementing retry strategies, or building resilient email service integrations.
allowed-tools: Read, Write, Bash, Grep
---

# API Patterns Skill

Comprehensive patterns and best practices for integrating with the Resend API, covering authentication, rate limiting, error handling, and resilient retry strategies.

## Use When

- Implementing Resend API clients in TypeScript/JavaScript
- Building Python-based email service integrations
- Handling API authentication and Bearer tokens
- Managing rate limits (2 requests/second default)
- Implementing exponential backoff retry logic
- Processing API error responses (4xx/5xx codes)
- Building resilient API integrations with error recovery
- Validating API responses and handling edge cases

## Core Patterns

### 1. API Authentication

**Bearer token authentication** for all Resend API requests:

#### TypeScript/JavaScript

```typescript
import { Resend } from 'resend';

// Initialize with API key from environment
const resend = new Resend(process.env.RESEND_API_KEY);

// Or with explicit initialization
const apiKey = process.env.RESEND_API_KEY;
if (!apiKey) {
  throw new Error('RESEND_API_KEY environment variable is not set');
}

const resend = new Resend(apiKey);

// For custom HTTP requests (if needed)
async function makeAuthenticatedRequest(endpoint: string, body: any) {
  const response = await fetch(`https://api.resend.com/${endpoint}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  return response.json();
}
```

#### Python

```python
import os
from resend import Resend

# Initialize with API key from environment
api_key = os.environ.get("RESEND_API_KEY")
if not api_key:
    raise ValueError("RESEND_API_KEY environment variable is not set")

client = Resend(api_key=api_key)

# For custom HTTP requests (if needed)
import httpx

async def make_authenticated_request(endpoint: str, body: dict):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"https://api.resend.com/{endpoint}",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json=body,
        )
        return response.json()
```

### 2. Rate Limiting Handling

**Resend API rate limits**: 2 requests per second per account

#### TypeScript Implementation

```typescript
class ResendAPIClient {
  private requestQueue: Array<() => Promise<any>> = [];
  private isProcessing = false;
  private readonly requestsPerSecond = 2;
  private lastRequestTime = 0;

  async executeWithRateLimit<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.requestQueue.push(async () => {
        try {
          const result = await fn();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });

      this.processQueue();
    });
  }

  private async processQueue() {
    if (this.isProcessing || this.requestQueue.length === 0) {
      return;
    }

    this.isProcessing = true;

    while (this.requestQueue.length > 0) {
      const now = Date.now();
      const timeSinceLastRequest = now - this.lastRequestTime;
      const delayNeeded = (1000 / this.requestsPerSecond) - timeSinceLastRequest;

      if (delayNeeded > 0) {
        await new Promise(resolve => setTimeout(resolve, delayNeeded));
      }

      const request = this.requestQueue.shift();
      if (request) {
        await request();
        this.lastRequestTime = Date.now();
      }
    }

    this.isProcessing = false;
  }

  async sendEmail(payload: any) {
    return this.executeWithRateLimit(() =>
      resend.emails.send(payload)
    );
  }

  async sendBatch(emails: any[]) {
    return this.executeWithRateLimit(() =>
      resend.batch.send(emails)
    );
  }
}
```

#### Python Implementation

```python
import asyncio
import time
from typing import TypeVar, Callable, Coroutine, Any

T = TypeVar('T')

class ResendAPIClient:
    def __init__(self, api_key: str, requests_per_second: int = 2):
        self.client = Resend(api_key=api_key)
        self.request_queue = asyncio.Queue()
        self.is_processing = False
        self.requests_per_second = requests_per_second
        self.last_request_time = 0

    async def execute_with_rate_limit(
        self,
        fn: Callable[[], Coroutine[Any, Any, T]]
    ) -> T:
        await self.request_queue.put(fn)
        asyncio.create_task(self.process_queue())

        # Wait for result (simplified - in production use proper queuing)
        return await fn()

    async def process_queue(self):
        if self.is_processing or self.request_queue.empty():
            return

        self.is_processing = True

        while not self.request_queue.empty():
            now = time.time()
            time_since_last = now - self.last_request_time
            delay_needed = (1.0 / self.requests_per_second) - time_since_last

            if delay_needed > 0:
                await asyncio.sleep(delay_needed)

            try:
                fn = self.request_queue.get_nowait()
                await fn()
                self.last_request_time = time.time()
            except asyncio.QueueEmpty:
                break

        self.is_processing = False

    async def send_email(self, payload: dict):
        async def send():
            return self.client.emails.send(payload)

        return await self.execute_with_rate_limit(send)
```

### 3. Error Response Codes

**HTTP status codes and error handling**:

| Code | Error | Handling Strategy |
|------|-------|-------------------|
| 200 | Success | Process response normally |
| 400 | Bad Request | Validate request payload, check required fields |
| 401 | Unauthorized | Verify API key is correct and valid |
| 403 | Forbidden | Check API key has required permissions |
| 404 | Not Found | Verify resource ID/email address exists |
| 409 | Conflict | Handle duplicate resource creation attempts |
| 429 | Rate Limited | Implement exponential backoff retry |
| 500 | Server Error | Retry with exponential backoff |
| 502 | Bad Gateway | Retry with exponential backoff |
| 503 | Service Unavailable | Retry with exponential backoff |

#### TypeScript Error Handler

```typescript
interface APIError {
  code: number;
  message: string;
  statusText: string;
}

async function handleAPIError(error: any): Promise<void> {
  if (error.response) {
    const status = error.response.status;
    const data = error.response.data;

    switch (status) {
      case 400:
        console.error('Bad Request:', data.message);
        throw new Error(`Invalid request: ${data.message}`);

      case 401:
        console.error('Unauthorized: Check API key');
        throw new Error('Invalid API key. Set RESEND_API_KEY environment variable.');

      case 403:
        console.error('Forbidden: Insufficient permissions');
        throw new Error('API key lacks required permissions.');

      case 404:
        console.error('Not Found:', data.message);
        throw new Error(`Resource not found: ${data.message}`);

      case 409:
        console.error('Conflict: Resource already exists');
        throw new Error(`Duplicate resource: ${data.message}`);

      case 429:
        console.warn('Rate limited: Implement retry');
        throw new Error('Rate limit exceeded. Retry after delay.');

      case 500:
      case 502:
      case 503:
        console.error(`Server error (${status}): Retry recommended`);
        throw new Error(`Server error (${status}). Retry in progress...`);

      default:
        console.error(`Unknown error (${status}):`, data);
        throw new Error(`API error: ${data.message || 'Unknown error'}`);
    }
  }

  throw error;
}
```

#### Python Error Handler

```python
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

class ResendAPIError(Exception):
    """Base exception for Resend API errors"""
    pass

class AuthenticationError(ResendAPIError):
    """API authentication failed"""
    pass

class RateLimitError(ResendAPIError):
    """Rate limit exceeded"""
    pass

class ServerError(ResendAPIError):
    """Server-side error"""
    pass

def handle_api_error(error: Exception, status_code: Optional[int] = None) -> None:
    """Handle Resend API errors based on status code"""

    if status_code == 400:
        logger.error(f"Bad Request: {str(error)}")
        raise ResendAPIError(f"Invalid request: {str(error)}")

    elif status_code == 401:
        logger.error("Unauthorized: Check API key")
        raise AuthenticationError(
            "Invalid API key. Set RESEND_API_KEY environment variable."
        )

    elif status_code == 403:
        logger.error("Forbidden: Insufficient permissions")
        raise AuthenticationError("API key lacks required permissions.")

    elif status_code == 404:
        logger.error(f"Not Found: {str(error)}")
        raise ResendAPIError(f"Resource not found: {str(error)}")

    elif status_code == 409:
        logger.error("Conflict: Resource already exists")
        raise ResendAPIError(f"Duplicate resource: {str(error)}")

    elif status_code == 429:
        logger.warning("Rate limited: Implement retry")
        raise RateLimitError("Rate limit exceeded. Retry after delay.")

    elif status_code in [500, 502, 503]:
        logger.error(f"Server error ({status_code}): Retry recommended")
        raise ServerError(f"Server error ({status_code}). Retry in progress...")

    else:
        logger.error(f"Unknown error: {str(error)}")
        raise ResendAPIError(f"API error: {str(error)}")
```

### 4. Exponential Backoff Retry Strategy

**Resilient retry logic** with exponential backoff for transient failures:

#### TypeScript Implementation

```typescript
interface RetryOptions {
  maxRetries?: number;
  initialDelayMs?: number;
  maxDelayMs?: number;
  backoffMultiplier?: number;
  retryableStatusCodes?: number[];
}

const DEFAULT_RETRY_OPTIONS: Required<RetryOptions> = {
  maxRetries: 5,
  initialDelayMs: 100,
  maxDelayMs: 30000,
  backoffMultiplier: 2,
  retryableStatusCodes: [408, 429, 500, 502, 503, 504],
};

async function withExponentialBackoff<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const config = { ...DEFAULT_RETRY_OPTIONS, ...options };
  let lastError: Error | null = null;
  let delayMs = config.initialDelayMs;

  for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      lastError = error;

      // Check if error is retryable
      const isRetryable =
        (error.response?.status &&
         config.retryableStatusCodes.includes(error.response.status)) ||
        error.code === 'ECONNREFUSED' ||
        error.code === 'ETIMEDOUT';

      if (!isRetryable || attempt === config.maxRetries) {
        throw error;
      }

      // Calculate delay with jitter
      const jitter = Math.random() * 0.1 * delayMs;
      const actualDelay = Math.min(delayMs + jitter, config.maxDelayMs);

      console.warn(
        `Attempt ${attempt + 1} failed. Retrying in ${actualDelay.toFixed(0)}ms...`,
        error.message
      );

      await new Promise(resolve => setTimeout(resolve, actualDelay));
      delayMs = Math.min(delayMs * config.backoffMultiplier, config.maxDelayMs);
    }
  }

  throw lastError || new Error('Retry loop exhausted');
}

// Usage
async function sendEmailWithRetry(payload: any) {
  return withExponentialBackoff(
    () => resend.emails.send(payload),
    {
      maxRetries: 5,
      initialDelayMs: 100,
      maxDelayMs: 10000,
      backoffMultiplier: 2,
    }
  );
}
```

#### Python Implementation

```python
import asyncio
import random
import logging
from typing import TypeVar, Callable, Coroutine, Optional, List
from enum import Enum

logger = logging.getLogger(__name__)
T = TypeVar('T')

class RetryStrategy(Enum):
    EXPONENTIAL = "exponential"
    LINEAR = "linear"

async def with_exponential_backoff(
    fn: Callable[[], Coroutine],
    max_retries: int = 5,
    initial_delay_ms: float = 100,
    max_delay_ms: float = 30000,
    backoff_multiplier: float = 2,
    retryable_status_codes: Optional[List[int]] = None,
) -> T:
    """
    Execute async function with exponential backoff retry

    Args:
        fn: Async function to execute
        max_retries: Maximum retry attempts
        initial_delay_ms: Initial delay in milliseconds
        max_delay_ms: Maximum delay in milliseconds
        backoff_multiplier: Multiplier for each retry
        retryable_status_codes: HTTP status codes to retry on

    Returns:
        Result from function call

    Raises:
        Exception: If all retries exhausted
    """
    if retryable_status_codes is None:
        retryable_status_codes = [408, 429, 500, 502, 503, 504]

    last_error = None
    delay_ms = initial_delay_ms

    for attempt in range(max_retries + 1):
        try:
            return await fn()
        except Exception as error:
            last_error = error

            # Check if error is retryable
            is_retryable = (
                (hasattr(error, 'status_code') and
                 error.status_code in retryable_status_codes) or
                'timeout' in str(error).lower() or
                'connection' in str(error).lower()
            )

            if not is_retryable or attempt == max_retries:
                raise error

            # Calculate delay with jitter
            jitter = random.random() * 0.1 * delay_ms
            actual_delay = min(delay_ms + jitter, max_delay_ms)

            logger.warning(
                f"Attempt {attempt + 1} failed. "
                f"Retrying in {actual_delay:.0f}ms... Error: {str(error)}"
            )

            await asyncio.sleep(actual_delay / 1000)
            delay_ms = min(delay_ms * backoff_multiplier, max_delay_ms)

    if last_error:
        raise last_error
    raise Exception("Retry loop exhausted")
```

### 5. Request Validation

**Validate payloads before sending** to catch errors early:

#### TypeScript Validator

```typescript
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
  scheduled_at?: string;
  tags?: Array<{ name: string; value: string }>;
}

function validateEmailPayload(payload: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Check required fields
  if (!payload.from) {
    errors.push("'from' field is required");
  }
  if (!payload.to) {
    errors.push("'to' field is required");
  }
  if (!payload.subject) {
    errors.push("'subject' field is required");
  }

  // Validate email addresses
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (payload.from && !emailRegex.test(payload.from)) {
    errors.push(`Invalid 'from' email: ${payload.from}`);
  }

  const recipients = Array.isArray(payload.to) ? payload.to : [payload.to];
  recipients.forEach((email: string) => {
    if (!emailRegex.test(email)) {
      errors.push(`Invalid recipient email: ${email}`);
    }
  });

  // Validate optional email fields
  if (payload.reply_to && !emailRegex.test(payload.reply_to)) {
    errors.push(`Invalid 'reply_to' email: ${payload.reply_to}`);
  }

  if (payload.cc) {
    payload.cc.forEach((email: string) => {
      if (!emailRegex.test(email)) {
        errors.push(`Invalid 'cc' email: ${email}`);
      }
    });
  }

  if (payload.bcc) {
    payload.bcc.forEach((email: string) => {
      if (!emailRegex.test(email)) {
        errors.push(`Invalid 'bcc' email: ${email}`);
      }
    });
  }

  // Validate attachment content
  if (payload.attachments) {
    payload.attachments.forEach((att: any, index: number) => {
      if (!att.filename) {
        errors.push(`Attachment ${index} missing 'filename'`);
      }
      if (!att.content) {
        errors.push(`Attachment ${index} missing 'content'`);
      }
    });
  }

  // Validate scheduled_at format if present
  if (payload.scheduled_at) {
    try {
      new Date(payload.scheduled_at);
    } catch {
      errors.push(`Invalid 'scheduled_at' format: ${payload.scheduled_at}`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

// Usage
async function sendEmailSafely(payload: EmailPayload) {
  const validation = validateEmailPayload(payload);

  if (!validation.valid) {
    console.error('Validation errors:', validation.errors);
    throw new Error(`Payload validation failed: ${validation.errors.join(', ')}`);
  }

  return resend.emails.send(payload);
}
```

#### Python Validator

```python
import re
from typing import Dict, List, Any, Tuple
from datetime import datetime

class EmailPayloadValidator:
    EMAIL_REGEX = r'^[^\s@]+@[^\s@]+\.[^\s@]+$'

    @staticmethod
    def validate_email(email: str) -> bool:
        """Validate email address format"""
        return re.match(EmailPayloadValidator.EMAIL_REGEX, email) is not None

    @staticmethod
    def validate_payload(payload: Dict[str, Any]) -> Tuple[bool, List[str]]:
        """
        Validate email payload before sending

        Returns:
            Tuple of (is_valid, error_list)
        """
        errors = []

        # Check required fields
        if not payload.get('from'):
            errors.append("'from' field is required")
        if not payload.get('to'):
            errors.append("'to' field is required")
        if not payload.get('subject'):
            errors.append("'subject' field is required")

        # Validate email addresses
        if payload.get('from'):
            if not EmailPayloadValidator.validate_email(payload['from']):
                errors.append(f"Invalid 'from' email: {payload['from']}")

        # Validate recipients
        recipients = payload.get('to', [])
        if isinstance(recipients, str):
            recipients = [recipients]

        for email in recipients:
            if not EmailPayloadValidator.validate_email(email):
                errors.append(f"Invalid recipient email: {email}")

        # Validate optional email fields
        if payload.get('reply_to'):
            if not EmailPayloadValidator.validate_email(payload['reply_to']):
                errors.append(f"Invalid 'reply_to' email: {payload['reply_to']}")

        for cc_email in payload.get('cc', []):
            if not EmailPayloadValidator.validate_email(cc_email):
                errors.append(f"Invalid 'cc' email: {cc_email}")

        for bcc_email in payload.get('bcc', []):
            if not EmailPayloadValidator.validate_email(bcc_email):
                errors.append(f"Invalid 'bcc' email: {bcc_email}")

        # Validate attachments
        for i, attachment in enumerate(payload.get('attachments', [])):
            if not attachment.get('filename'):
                errors.append(f"Attachment {i} missing 'filename'")
            if not attachment.get('content'):
                errors.append(f"Attachment {i} missing 'content'")

        # Validate scheduled_at format
        if payload.get('scheduled_at'):
            try:
                datetime.fromisoformat(
                    payload['scheduled_at'].replace('Z', '+00:00')
                )
            except ValueError:
                errors.append(f"Invalid 'scheduled_at' format: {payload['scheduled_at']}")

        return len(errors) == 0, errors

def send_email_safely(client, payload: Dict[str, Any]):
    """Send email with validation"""
    is_valid, errors = EmailPayloadValidator.validate_payload(payload)

    if not is_valid:
        raise ValueError(f"Payload validation failed: {', '.join(errors)}")

    return client.emails.send(payload)
```

## Environment Setup

### Required Environment Variables

```bash
# .env
RESEND_API_KEY=your_resend_api_key_here
```

### .env.example (Safe to Commit)

```bash
# Resend API Configuration
RESEND_API_KEY=your_resend_api_key_here

# Optional: Custom request timeout (ms)
RESEND_REQUEST_TIMEOUT=30000

# Optional: Max retries for transient failures
RESEND_MAX_RETRIES=5

# Optional: Rate limit requests per second
RESEND_RATE_LIMIT=2
```

### Installation

#### TypeScript/JavaScript

```bash
npm install resend
# or
yarn add resend
# or
pnpm add resend
```

#### Python

```bash
pip install resend
```

## Best Practices

### 1. Always Use Environment Variables

```typescript
// CORRECT
const apiKey = process.env.RESEND_API_KEY;

// WRONG - Never hardcode
const apiKey = 're_abc123xyz...';
```

### 2. Implement Graceful Degradation

```typescript
async function sendEmailWithFallback(payload: EmailPayload) {
  try {
    return await resend.emails.send(payload);
  } catch (error) {
    // Log error for monitoring
    console.error('Email send failed:', error);

    // Implement fallback behavior
    // - Queue for retry
    // - Alert administrator
    // - Use alternative service

    throw error;
  }
}
```

### 3. Monitor API Usage

```typescript
interface APIMetrics {
  successCount: number;
  failureCount: number;
  rateLimitHits: number;
  averageResponseTime: number;
}

class APIMonitor {
  private metrics: APIMetrics = {
    successCount: 0,
    failureCount: 0,
    rateLimitHits: 0,
    averageResponseTime: 0,
  };

  recordSuccess(duration: number) {
    this.metrics.successCount++;
    this.updateAverageResponseTime(duration);
  }

  recordFailure(error: any) {
    this.metrics.failureCount++;
    if (error?.response?.status === 429) {
      this.metrics.rateLimitHits++;
    }
  }

  private updateAverageResponseTime(duration: number) {
    const totalRequests = this.metrics.successCount + this.metrics.failureCount;
    const currentAvg = this.metrics.averageResponseTime;
    this.metrics.averageResponseTime =
      (currentAvg * (totalRequests - 1) + duration) / totalRequests;
  }

  getMetrics(): APIMetrics {
    return { ...this.metrics };
  }
}
```

### 4. Implement Circuit Breaker Pattern

```typescript
enum CircuitState {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount = 0;
  private failureThreshold = 5;
  private resetTimeout = 60000; // 1 minute
  private lastFailureTime = 0;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        throw new Error('Circuit breaker is OPEN');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    this.state = CircuitState.CLOSED;
  }

  private onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();
    if (this.failureCount >= this.failureThreshold) {
      this.state = CircuitState.OPEN;
    }
  }
}
```

## Examples Directory Structure

- `typescript-client/` - Complete TypeScript client setup with authentication
- `python-client/` - Complete Python client setup with authentication
- `error-handling/` - Comprehensive error handling and recovery patterns

See individual example README files for complete code and usage patterns.

## Related Skills

- **email-delivery** - Email sending patterns (single, batch, scheduled)
- **email-templates** - HTML template management and rendering
- **email-webhooks** - Delivery event tracking and status handling

## Security Compliance

This skill follows strict security rules:
- All code examples use placeholder values only
- No real API keys, passwords, or secrets
- Environment variable references in all code
- `.gitignore` protection documented
- Clear guidance on key acquisition

## Resources

- [Resend API Documentation](https://resend.com/docs)
- [Resend API Reference](https://resend.com/docs/api-reference)
- [Authentication Best Practices](https://resend.com/docs/knowledge-base/authentication)
- [Rate Limiting Guide](https://resend.com/docs/knowledge-base/rate-limiting)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
