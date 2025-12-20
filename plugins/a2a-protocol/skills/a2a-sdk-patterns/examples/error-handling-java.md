# Error Handling Patterns - Java

## Exception Hierarchy

```java
A2AException (base exception)
├── A2AConnectionException (network/connectivity issues)
├── A2AAuthenticationException (invalid credentials)
├── A2ARateLimitException (rate limit exceeded)
├── A2AValidationException (invalid request data)
└── A2AServerException (server-side errors)
```

## Basic Error Handling

```java
import com.a2a.protocol.A2AClient;
import com.a2a.protocol.exceptions.*;

A2AClient client = A2AClient.builder()
    .apiKey(System.getenv("A2A_API_KEY"))
    .build();

try {
    Message response = client.sendMessage(
        SendMessageRequest.builder()
            .recipientId("agent-123")
            .message(Map.of("type", "request"))
            .build()
    );
} catch (A2AAuthenticationException e) {
    System.err.println("Authentication failed: " + e.getMessage());
    System.err.println("Please check your API key");
} catch (A2ARateLimitException e) {
    System.err.println("Rate limit exceeded: " + e.getMessage());
    System.err.println("Retry after: " + e.getRetryAfter() + " seconds");
    Thread.sleep(e.getRetryAfter() * 1000);
    // Retry the request
} catch (A2AException e) {
    System.err.println("A2A error: " + e.getMessage());
    System.err.println("Error code: " + e.getErrorCode());
    System.err.println("Status code: " + e.getStatusCode());
}
```

## Retry with Exponential Backoff

```java
import java.util.Map;

public class RetryHandler {
    private static final int MAX_RETRIES = 3;
    private static final long INITIAL_DELAY = 1000; // 1 second

    public static Message sendWithRetry(
        A2AClient client,
        String recipientId,
        Map<String, Object> message
    ) throws A2AException {
        long delay = INITIAL_DELAY;

        for (int attempt = 0; attempt < MAX_RETRIES; attempt++) {
            try {
                return client.sendMessage(
                    SendMessageRequest.builder()
                        .recipientId(recipientId)
                        .message(message)
                        .build()
                );
            } catch (A2ARateLimitException e) {
                if (attempt == MAX_RETRIES - 1) {
                    throw e;
                }
                long waitTime = e.getRetryAfter() > 0 ?
                    e.getRetryAfter() * 1000 : delay;
                System.out.println("Rate limited. Waiting " + waitTime + "ms...");
                Thread.sleep(waitTime);
                delay *= 2; // Exponential backoff
            } catch (A2AConnectionException e) {
                if (attempt == MAX_RETRIES - 1) {
                    throw e;
                }
                System.out.println("Connection error. Retrying in " + delay + "ms...");
                Thread.sleep(delay);
                delay *= 2;
            }
        }

        throw new A2AException("Max retries exceeded");
    }
}
```

## Try-with-Resources Pattern

```java
// A2AClient implements AutoCloseable
try (A2AClient client = A2AClient.builder()
        .apiKey(System.getenv("A2A_API_KEY"))
        .build()) {

    Message response = client.sendMessage(
        SendMessageRequest.builder()
            .recipientId("agent-123")
            .message(Map.of("type", "request"))
            .build()
    );

} catch (A2AException e) {
    System.err.println("Error: " + e.getMessage());
} // Client automatically closed here
```

## Custom Exception Handler

```java
@FunctionalInterface
public interface A2AExceptionHandler {
    void handle(A2AException e);
}

public class ErrorHandlers {
    public static A2AExceptionHandler loggingHandler(Logger logger) {
        return e -> {
            logger.error("A2A operation failed", e);
            logger.error("Error code: {}", e.getErrorCode());
            logger.error("Status code: {}", e.getStatusCode());
        };
    }

    public static A2AExceptionHandler retryHandler(int maxRetries) {
        return new A2AExceptionHandler() {
            private int retries = 0;

            @Override
            public void handle(A2AException e) {
                if (retries < maxRetries &&
                    e instanceof A2AConnectionException) {
                    retries++;
                    // Implement retry logic
                } else {
                    throw new RuntimeException("Max retries exceeded", e);
                }
            }
        };
    }
}
```

## CompletableFuture Error Handling

```java
import java.util.concurrent.CompletableFuture;

public class AsyncErrorHandling {
    public static CompletableFuture<Message> sendMessageAsync(
        A2AClient client,
        String recipientId,
        Map<String, Object> message
    ) {
        return CompletableFuture.supplyAsync(() -> {
            try {
                return client.sendMessage(
                    SendMessageRequest.builder()
                        .recipientId(recipientId)
                        .message(message)
                        .build()
                );
            } catch (A2AException e) {
                throw new RuntimeException(e);
            }
        }).exceptionally(e -> {
            if (e.getCause() instanceof A2ARateLimitException) {
                System.err.println("Rate limited - implement backoff");
            } else if (e.getCause() instanceof A2AException) {
                System.err.println("A2A error: " + e.getCause().getMessage());
            }
            return null;
        });
    }
}
```

## Logging with SLF4J

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class A2AService {
    private static final Logger logger = LoggerFactory.getLogger(A2AService.class);
    private final A2AClient client;

    public Message sendMessage(String recipientId, Map<String, Object> message) {
        try {
            Message response = client.sendMessage(
                SendMessageRequest.builder()
                    .recipientId(recipientId)
                    .message(message)
                    .build()
            );
            logger.info("Message sent successfully to {}", recipientId);
            return response;
        } catch (A2AException e) {
            logger.error("Failed to send message to {}", recipientId, e);
            logger.error("Error code: {}, Status code: {}",
                e.getErrorCode(), e.getStatusCode());
            throw new RuntimeException("Message send failed", e);
        }
    }
}
```

## Graceful Degradation

```java
public class SafeA2AClient {
    private final A2AClient client;
    private final Logger logger;

    public Agent getAgentStatusSafe(String agentId) {
        try {
            return client.getAgentStatus(agentId);
        } catch (A2AConnectionException e) {
            logger.warn("Could not fetch status for {}", agentId);
            return Agent.builder()
                .id(agentId)
                .status("unknown")
                .build();
        } catch (A2AException e) {
            logger.error("Error fetching status for {}", agentId, e);
            return Agent.builder()
                .id(agentId)
                .status("error")
                .build();
        }
    }
}
```
