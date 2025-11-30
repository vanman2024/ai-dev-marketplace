# Comprehensive Error Handling Patterns

Production-ready error handling strategies for Resend API integration.

## Error Categories

### 1. Client Errors (4xx)

**400 Bad Request** - Invalid request payload
- Missing required fields
- Invalid email format
- Invalid payload structure

```typescript
// TypeScript
async function handleBadRequest() {
  try {
    const result = await resend.emails.send({
      // Missing 'to' field
      from: 'test@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });
  } catch (error: any) {
    if (error.response?.status === 400) {
      console.error('Bad Request:', error.response.data);
      // Log validation error
      // Alert developer
      // Return helpful error message
      throw new Error(`Invalid email payload: ${error.response.data.message}`);
    }
  }
}
```

```python
# Python
async def handle_bad_request():
    try:
        response = await client.emails.send({
            # Missing 'to' field
            "from": "test@example.com",
            "subject": "Test",
            "html": "<p>Test</p>",
        })
    except Exception as error:
        if hasattr(error, 'status_code') and error.status_code == 400:
            logger.error(f"Bad Request: {str(error)}")
            raise ValueError(f"Invalid email payload: {str(error)}")
```

**401 Unauthorized** - Invalid or missing API key

```typescript
// TypeScript
async function handleUnauthorized() {
  try {
    const result = await resend.emails.send({
      from: 'test@example.com',
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });
  } catch (error: any) {
    if (error.response?.status === 401) {
      console.error('Authentication failed');
      // API key is invalid or expired
      // Options:
      // 1. Check RESEND_API_KEY environment variable
      // 2. Regenerate API key in Resend dashboard
      // 3. Ensure key is properly set in .env
      throw new Error(
        'Invalid Resend API key. ' +
        'Verify RESEND_API_KEY is set correctly.'
      );
    }
  }
}
```

```python
# Python
async def handle_unauthorized():
    try:
        response = await client.emails.send({
            "from": "test@example.com",
            "to": "user@example.com",
            "subject": "Test",
            "html": "<p>Test</p>",
        })
    except Exception as error:
        if hasattr(error, 'status_code') and error.status_code == 401:
            logger.error("Authentication failed - Invalid API key")
            raise ValueError(
                "Invalid Resend API key. "
                "Verify RESEND_API_KEY environment variable."
            )
```

**403 Forbidden** - Insufficient permissions

```typescript
// TypeScript
async function handleForbidden() {
  try {
    const result = await resend.emails.send({
      from: 'unverified@example.com',  // Not verified in Resend
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });
  } catch (error: any) {
    if (error.response?.status === 403) {
      console.error('Access forbidden');
      // Possible causes:
      // 1. Sender email not verified
      // 2. API key lacks required permissions
      // 3. Account restrictions
      throw new Error(
        'Forbidden: Check that sender email is verified in Resend dashboard'
      );
    }
  }
}
```

**404 Not Found** - Resource doesn't exist

```typescript
// TypeScript
async function handleNotFound() {
  try {
    const result = await resend.contacts.get('invalid-id');
  } catch (error: any) {
    if (error.response?.status === 404) {
      console.error('Resource not found');
      // Contact, audience, or template doesn't exist
      throw new Error('Requested resource does not exist');
    }
  }
}
```

**409 Conflict** - Resource already exists

```typescript
// TypeScript
async function handleConflict() {
  try {
    const result = await resend.audiences.create({
      name: 'Existing Audience',  // Already exists
    });
  } catch (error: any) {
    if (error.response?.status === 409) {
      console.error('Duplicate resource');
      // Resource already exists
      // Handle gracefully - either update or skip
      console.log('Audience already exists, skipping creation');
      return;
    }
  }
}
```

### 2. Rate Limiting (429)

**429 Too Many Requests** - Rate limit exceeded (2 req/sec)

```typescript
// TypeScript - With Exponential Backoff
async function handleRateLimit() {
  const maxRetries = 5;
  let delayMs = 1000;  // Start with 1 second

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await resend.emails.send({
        from: 'test@example.com',
        to: 'user@example.com',
        subject: 'Test',
        html: '<p>Test</p>',
      });
    } catch (error: any) {
      if (error.response?.status === 429) {
        if (attempt < maxRetries) {
          console.warn(
            `Rate limited. Retrying in ${delayMs}ms... ` +
            `(Attempt ${attempt}/${maxRetries})`
          );
          await new Promise(resolve => setTimeout(resolve, delayMs));
          delayMs *= 2;  // Exponential backoff
          continue;
        }
      }
      throw error;
    }
  }
}
```

```python
# Python - With Queue and Rate Limiting
import asyncio
import time

class RateLimitHandler:
    def __init__(self, requests_per_second: int = 2):
        self.requests_per_second = requests_per_second
        self.last_request_time = 0

    async def execute_with_rate_limit(self, fn, max_retries: int = 5):
        """Execute function with rate limiting"""
        delay = 1.0  # seconds

        for attempt in range(1, max_retries + 1):
            try:
                # Check rate limit before request
                now = time.time()
                time_since_last = now - self.last_request_time
                min_interval = 1.0 / self.requests_per_second

                if time_since_last < min_interval:
                    await asyncio.sleep(min_interval - time_since_last)

                result = await fn()
                self.last_request_time = time.time()
                return result

            except Exception as error:
                if hasattr(error, 'status_code') and error.status_code == 429:
                    if attempt < max_retries:
                        logger.warning(
                            f"Rate limited. Retrying in {delay:.1f}s... "
                            f"(Attempt {attempt}/{max_retries})"
                        )
                        await asyncio.sleep(delay)
                        delay *= 2
                        continue

                raise error
```

### 3. Server Errors (5xx)

**500 Internal Server Error** - Temporary server issue

```typescript
// TypeScript - Retry Strategy
async function handleServerError() {
  const maxRetries = 5;
  let delayMs = 500;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await resend.emails.send({
        from: 'test@example.com',
        to: 'user@example.com',
        subject: 'Test',
        html: '<p>Test</p>',
      });
    } catch (error: any) {
      const status = error.response?.status;

      // Retryable server errors
      if ([500, 502, 503, 504].includes(status)) {
        if (attempt < maxRetries) {
          console.warn(
            `Server error (${status}). ` +
            `Retrying in ${delayMs}ms... ` +
            `(Attempt ${attempt}/${maxRetries})`
          );

          await new Promise(resolve => setTimeout(resolve, delayMs));
          delayMs = Math.min(delayMs * 2, 30000);  // Max 30s delay
          continue;
        }
      }

      throw error;
    }
  }
}
```

**503 Service Unavailable** - Temporary maintenance or overload

```typescript
// TypeScript - With Circuit Breaker
class CircuitBreaker {
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  private failureCount = 0;
  private failureThreshold = 5;
  private resetTimeout = 60000;  // 1 minute
  private lastFailureTime = 0;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = 'HALF_OPEN';
      } else {
        throw new Error(
          'Circuit breaker is OPEN. Service temporarily unavailable.'
        );
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure(error);
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  private onFailure(error: any) {
    const status = error.response?.status;
    if ([500, 502, 503, 504].includes(status)) {
      this.failureCount++;
      this.lastFailureTime = Date.now();

      if (this.failureCount >= this.failureThreshold) {
        this.state = 'OPEN';
      }
    }
  }
}
```

### 4. Validation Errors

**Email Validation**

```typescript
// TypeScript
function validateEmail(email: string): { valid: boolean; error?: string } {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  if (!email) {
    return { valid: false, error: 'Email is required' };
  }

  if (!emailRegex.test(email)) {
    return { valid: false, error: `Invalid email format: ${email}` };
  }

  if (email.length > 254) {
    return { valid: false, error: 'Email is too long' };
  }

  return { valid: true };
}

// Usage
async function sendEmailWithValidation(payload: any) {
  const validation = validateEmail(payload.to);
  if (!validation.valid) {
    throw new Error(validation.error);
  }

  return resend.emails.send(payload);
}
```

**Payload Validation**

```typescript
// TypeScript
interface ValidationError {
  field: string;
  message: string;
}

function validateEmailPayload(payload: any): ValidationError[] {
  const errors: ValidationError[] = [];

  // Required fields
  if (!payload.from) {
    errors.push({ field: 'from', message: 'from is required' });
  }
  if (!payload.to) {
    errors.push({ field: 'to', message: 'to is required' });
  }
  if (!payload.subject) {
    errors.push({ field: 'subject', message: 'subject is required' });
  }

  // Content validation
  if (!payload.html && !payload.text) {
    errors.push({
      field: 'content',
      message: 'html or text is required',
    });
  }

  // Email format validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (payload.from && !emailRegex.test(payload.from)) {
    errors.push({ field: 'from', message: 'Invalid from email format' });
  }

  return errors;
}

// Usage
async function sendEmailValidated(payload: any) {
  const validationErrors = validateEmailPayload(payload);

  if (validationErrors.length > 0) {
    throw new Error(
      `Validation failed: ${validationErrors
        .map(e => `${e.field}: ${e.message}`)
        .join(', ')}`
    );
  }

  return resend.emails.send(payload);
}
```

### 5. Network Errors

**Timeout** - Request took too long

```typescript
// TypeScript - With Timeout Wrapper
async function withTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number
): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(
        () => reject(new Error(`Request timeout after ${timeoutMs}ms`)),
        timeoutMs
      )
    ),
  ]);
}

// Usage
async function sendEmailWithTimeout() {
  try {
    const result = await withTimeout(
      resend.emails.send({
        from: 'test@example.com',
        to: 'user@example.com',
        subject: 'Test',
        html: '<p>Test</p>',
      }),
      5000  // 5 second timeout
    );
    return result;
  } catch (error: any) {
    if (error.message.includes('timeout')) {
      console.error('Request timeout - API not responding');
      // Fallback action
    }
    throw error;
  }
}
```

**Connection Refused** - API unreachable

```typescript
// TypeScript
async function handleConnectionError() {
  try {
    const result = await resend.emails.send({
      from: 'test@example.com',
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });
  } catch (error: any) {
    if (error.code === 'ECONNREFUSED') {
      console.error('Cannot connect to API');
      // Queue for retry
      // Use fallback service
      // Alert administrator
    }
    throw error;
  }
}
```

## Comprehensive Error Handler

```typescript
// TypeScript
enum ErrorSeverity {
  LOW = 'LOW',        // Can retry safely
  MEDIUM = 'MEDIUM',  // Retry with backoff
  HIGH = 'HIGH',      // Retry with circuit breaker
  CRITICAL = 'CRITICAL',  // Alert + manual intervention
}

interface HandledError {
  code: string;
  message: string;
  severity: ErrorSeverity;
  retryable: boolean;
  suggestedAction: string;
}

class ResendErrorHandler {
  static handle(error: any): HandledError {
    const status = error.response?.status;
    const message = error.message || 'Unknown error';

    switch (status) {
      case 400:
        return {
          code: 'BAD_REQUEST',
          message,
          severity: ErrorSeverity.LOW,
          retryable: false,
          suggestedAction: 'Fix request payload and retry',
        };

      case 401:
        return {
          code: 'UNAUTHORIZED',
          message: 'Invalid API key',
          severity: ErrorSeverity.CRITICAL,
          retryable: false,
          suggestedAction: 'Verify RESEND_API_KEY environment variable',
        };

      case 403:
        return {
          code: 'FORBIDDEN',
          message: 'Insufficient permissions or unverified sender',
          severity: ErrorSeverity.CRITICAL,
          retryable: false,
          suggestedAction: 'Verify sender email in Resend dashboard',
        };

      case 404:
        return {
          code: 'NOT_FOUND',
          message,
          severity: ErrorSeverity.LOW,
          retryable: false,
          suggestedAction: 'Verify resource exists',
        };

      case 409:
        return {
          code: 'CONFLICT',
          message: 'Resource already exists',
          severity: ErrorSeverity.LOW,
          retryable: false,
          suggestedAction: 'Use existing resource or delete and retry',
        };

      case 429:
        return {
          code: 'RATE_LIMITED',
          message: 'Rate limit exceeded (2 req/sec)',
          severity: ErrorSeverity.MEDIUM,
          retryable: true,
          suggestedAction: 'Retry with exponential backoff',
        };

      case 500:
      case 502:
      case 503:
      case 504:
        return {
          code: 'SERVER_ERROR',
          message: `Server error (${status})`,
          severity: ErrorSeverity.HIGH,
          retryable: true,
          suggestedAction: 'Retry with circuit breaker pattern',
        };

      default:
        if (error.code === 'ECONNREFUSED') {
          return {
            code: 'CONNECTION_REFUSED',
            message: 'Cannot connect to API',
            severity: ErrorSeverity.HIGH,
            retryable: true,
            suggestedAction: 'Check API availability and retry',
          };
        }

        if (message.includes('timeout')) {
          return {
            code: 'TIMEOUT',
            message: 'Request timeout',
            severity: ErrorSeverity.MEDIUM,
            retryable: true,
            suggestedAction: 'Retry with longer timeout',
          };
        }

        return {
          code: 'UNKNOWN',
          message,
          severity: ErrorSeverity.MEDIUM,
          retryable: true,
          suggestedAction: 'Retry operation',
        };
    }
  }
}

// Usage
async function sendEmailWithComprehensiveHandling() {
  try {
    return await resend.emails.send({
      from: 'test@example.com',
      to: 'user@example.com',
      subject: 'Test',
      html: '<p>Test</p>',
    });
  } catch (error) {
    const handled = ResendErrorHandler.handle(error);

    console.error(`[${handled.severity}] ${handled.code}: ${handled.message}`);
    console.log(`Action: ${handled.suggestedAction}`);

    if (!handled.retryable) {
      throw new Error(`Non-retryable error: ${handled.message}`);
    }

    // Handle based on severity
    if (handled.severity === ErrorSeverity.CRITICAL) {
      // Alert administrator
      // Fallback to alternative service
    } else if (handled.severity === ErrorSeverity.HIGH) {
      // Circuit breaker + retry
    } else {
      // Standard retry with backoff
    }

    throw error;
  }
}
```

## Logging and Monitoring

```typescript
// TypeScript
interface ErrorLog {
  timestamp: string;
  code: string;
  message: string;
  statusCode?: number;
  retryCount?: number;
  email?: string;
  duration?: number;
}

class ErrorLogger {
  private logs: ErrorLog[] = [];

  log(error: any, context: { email?: string; retryCount?: number; duration?: number }) {
    const entry: ErrorLog = {
      timestamp: new Date().toISOString(),
      code: error.code || 'UNKNOWN',
      message: error.message,
      statusCode: error.response?.status,
      retryCount: context.retryCount,
      email: context.email,
      duration: context.duration,
    };

    this.logs.push(entry);

    // Send to monitoring service
    this.sendToMonitoring(entry);
  }

  private sendToMonitoring(entry: ErrorLog) {
    // Send to Sentry, DataDog, etc.
    console.error('Error logged:', entry);
  }

  getErrorStats() {
    const stats = {
      totalErrors: this.logs.length,
      byCode: {} as Record<string, number>,
      byStatus: {} as Record<number, number>,
    };

    for (const log of this.logs) {
      stats.byCode[log.code] = (stats.byCode[log.code] || 0) + 1;
      if (log.statusCode) {
        stats.byStatus[log.statusCode] =
          (stats.byStatus[log.statusCode] || 0) + 1;
      }
    }

    return stats;
  }
}
```

## Best Practices

1. **Always validate input before sending**
2. **Implement exponential backoff for retries**
3. **Use circuit breaker for cascading failures**
4. **Log all errors with context**
5. **Alert on critical errors (401, 403)**
6. **Monitor rate limit hits**
7. **Set appropriate timeouts**
8. **Provide fallback mechanisms**
9. **Test error scenarios**
10. **Document error recovery procedures**

## Related Skills

- **api-patterns** - Core API integration patterns
- **email-delivery** - Email sending best practices

## Resources

- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [Resend Error Handling](https://resend.com/docs/knowledge-base/error-handling)
- [API Rate Limiting](https://resend.com/docs/knowledge-base/rate-limiting)
