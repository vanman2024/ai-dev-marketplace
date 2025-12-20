# Error Handling Patterns - TypeScript

## Exception Hierarchy

```typescript
A2AError (base exception)
├── A2AConnectionError (network/connectivity issues)
├── A2AAuthenticationError (invalid credentials)
├── A2ARateLimitError (rate limit exceeded)
├── A2AValidationError (invalid request data)
└── A2AServerError (server-side errors)
```

## Basic Error Handling

```typescript
import {
    A2AClient,
    A2AError,
    A2AAuthenticationError,
    A2ARateLimitError,
    A2AConnectionError
} from '@a2a/protocol';

const client = new A2AClient({ apiKey: process.env.A2A_API_KEY! });

try {
    const response = await client.sendMessage({
        recipientId: 'agent-123',
        message: { type: 'request' }
    });
} catch (error) {
    if (error instanceof A2AAuthenticationError) {
        console.error('Authentication failed:', error.message);
        console.error('Please check your API key');
    } else if (error instanceof A2ARateLimitError) {
        console.error('Rate limit exceeded:', error.message);
        console.error(`Retry after: ${error.retryAfter} seconds`);
        await new Promise(resolve => setTimeout(resolve, error.retryAfter * 1000));
        // Retry the request
    } else if (error instanceof A2AError) {
        console.error('A2A error:', error.message);
        console.error('Error code:', error.code);
        console.error('Status code:', error.statusCode);
    } else {
        console.error('Unexpected error:', error);
    }
}
```

## Retry with Exponential Backoff

```typescript
async function sendWithRetry(
    client: A2AClient,
    recipientId: string,
    message: Record<string, unknown>,
    maxRetries: number = 3,
    initialDelay: number = 1000
): Promise<unknown> {
    let delay = initialDelay;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
        try {
            return await client.sendMessage({ recipientId, message });
        } catch (error) {
            if (error instanceof A2ARateLimitError) {
                if (attempt === maxRetries - 1) throw error;
                const waitTime = error.retryAfter ? error.retryAfter * 1000 : delay;
                console.log(`Rate limited. Waiting ${waitTime}ms before retry...`);
                await new Promise(resolve => setTimeout(resolve, waitTime));
                delay *= 2; // Exponential backoff
            } else if (error instanceof A2AConnectionError) {
                if (attempt === maxRetries - 1) throw error;
                console.log(`Connection error. Retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
                delay *= 2;
            } else {
                throw error;
            }
        }
    }

    throw new Error('Max retries exceeded');
}
```

## Type-Safe Error Handling

```typescript
type A2AResult<T> =
    | { success: true; data: T }
    | { success: false; error: A2AError };

async function safeSendMessage(
    client: A2AClient,
    recipientId: string,
    message: Record<string, unknown>
): Promise<A2AResult<unknown>> {
    try {
        const data = await client.sendMessage({ recipientId, message });
        return { success: true, data };
    } catch (error) {
        if (error instanceof A2AError) {
            return { success: false, error };
        }
        throw error; // Re-throw unexpected errors
    }
}

// Usage
const result = await safeSendMessage(client, 'agent-123', { type: 'request' });
if (result.success) {
    console.log('Success:', result.data);
} else {
    console.error('Error:', result.error.message);
}
```

## Timeout Handling

```typescript
async function sendWithTimeout<T>(
    promise: Promise<T>,
    timeoutMs: number
): Promise<T> {
    const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('Request timeout')), timeoutMs)
    );

    return Promise.race([promise, timeoutPromise]);
}

// Usage
try {
    const response = await sendWithTimeout(
        client.sendMessage({ recipientId: 'agent-123', message: {} }),
        10000 // 10 seconds
    );
} catch (error) {
    console.error('Request timed out or failed:', error);
}
```

## Error Logging with Winston

```typescript
import winston from 'winston';

const logger = winston.createLogger({
    level: 'info',
    format: winston.format.json(),
    transports: [
        new winston.transports.Console(),
        new winston.transports.File({ filename: 'a2a-errors.log', level: 'error' })
    ]
});

try {
    const response = await client.sendMessage({
        recipientId: 'agent-123',
        message: { type: 'request' }
    });
} catch (error) {
    if (error instanceof A2AError) {
        logger.error('A2A operation failed', {
            errorCode: error.code,
            statusCode: error.statusCode,
            recipientId: 'agent-123',
            message: error.message,
            timestamp: new Date().toISOString()
        });
    }
    throw error;
}
```

## Graceful Degradation

```typescript
async function getAgentStatusSafe(
    client: A2AClient,
    agentId: string
): Promise<{ id: string; status: string }> {
    try {
        return await client.getAgentStatus(agentId);
    } catch (error) {
        if (error instanceof A2AConnectionError) {
            logger.warn(`Could not fetch status for ${agentId}`);
            return { id: agentId, status: 'unknown' };
        } else if (error instanceof A2AError) {
            logger.error(`Error fetching status: ${error.message}`);
            return { id: agentId, status: 'error' };
        }
        throw error;
    }
}
```

## Circuit Breaker Pattern

```typescript
class CircuitBreaker {
    private failures = 0;
    private lastFailureTime = 0;
    private readonly threshold = 5;
    private readonly timeout = 60000; // 1 minute

    async execute<T>(fn: () => Promise<T>): Promise<T> {
        if (this.isOpen()) {
            throw new Error('Circuit breaker is open');
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

    private isOpen(): boolean {
        return this.failures >= this.threshold &&
               Date.now() - this.lastFailureTime < this.timeout;
    }

    private onSuccess(): void {
        this.failures = 0;
    }

    private onFailure(): void {
        this.failures++;
        this.lastFailureTime = Date.now();
    }
}

// Usage
const breaker = new CircuitBreaker();

try {
    const response = await breaker.execute(() =>
        client.sendMessage({ recipientId: 'agent-123', message: {} })
    );
} catch (error) {
    console.error('Request failed or circuit breaker open:', error);
}
```
