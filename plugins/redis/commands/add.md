---
description: Add a specific feature to an existing Redis project. Features include cache, session, ratelimit, pubsub, vector, semantic.
argument-hint: <feature> [options]
---

# Add Redis Feature

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Caching Features

**If `$0` = "cache":**

```
Task(cache-architect) Add CACHING.

Requirements:
- Cache type: $1 (simple, lru, ttl - default: ttl)
- TTL: $2 (duration in seconds - default: 3600)
- Create cache utilities
- Set up key patterns
- Add invalidation
- Configure serialization
```

**If `$0` = "semantic":**

```
Task(semantic-cache-specialist) Add SEMANTIC CACHE.

Requirements:
- Provider: $1 (openai, upstash - default: upstash)
- Create semantic cache client
- Configure similarity threshold
- Add LLM integration
- Set up embeddings
```

**If `$0` = "vector":**

```
Task(vector-cache-specialist) Add VECTOR CACHE.

Requirements:
- Vector type: $1 (embeddings, search - default: embeddings)
- Dimensions: $2 (vector dimensions - default: 1536)
- Set up vector storage
- Configure similarity search
- Add batch operations
```

### Session Features

**If `$0` = "session":**

```
Task(session-manager) Add SESSION storage.

Requirements:
- Framework: $1 (nextjs, fastapi, express - default: nextjs)
- TTL: $2 (session duration - default: 86400)
- Create session store
- Configure serialization
- Add session helpers
- Handle cleanup
```

### Rate Limiting Features

**If `$0` = "ratelimit":**

```
Task(rate-limiter-specialist) Add RATE LIMITING.

Requirements:
- Algorithm: $1 (sliding-window, token-bucket, fixed - default: sliding-window)
- Limit: $2 (requests per window - default: 100)
- Create rate limiter
- Add middleware
- Configure limits per route
- Add bypass rules
```

### Pub/Sub Features

**If `$0` = "pubsub":**

```
Task(pub-sub-specialist) Add PUB/SUB.

Requirements:
- Pattern: $1 (channels, patterns, streams - default: channels)
- Create publishers
- Set up subscribers
- Add message handlers
- Configure acknowledgment
```

### Framework Integration

**If `$0` = "nextjs":**

```
Task(nextjs-integrator) Add NEXT.JS integration.

Requirements:
- Feature: $1 (cache, session, middleware - default: cache)
- Create Next.js helpers
- Add route caching
- Configure middleware
```

**If `$0` = "fastapi":**

```
Task(fastapi-integrator) Add FASTAPI integration.

Requirements:
- Feature: $1 (cache, session, middleware - default: cache)
- Create FastAPI dependencies
- Add route decorators
- Configure middleware
```

### Infrastructure Features

**If `$0` = "sentinel":**

```
Task(sentinel-architect) Add SENTINEL (HA).

Requirements:
- Mode: $1 (basic, cluster - default: basic)
- Configure Sentinel
- Set up failover
- Add health checks
```

**If `$0` = "monitoring":**

```
Task(monitoring-integrator) Add MONITORING.

Requirements:
- Tool: $1 (prometheus, datadog, custom - default: prometheus)
- Set up metrics
- Configure dashboards
- Add alerts
```

**If `$0` = "deploy":**

```
Task(deployment-architect) Add DEPLOYMENT config.

Requirements:
- Platform: $1 (upstash, redis-cloud, docker - default: upstash)
- Configure connection
- Set up environment
- Add health checks
```

---

## Usage Examples

```bash
# Caching
/redis:add cache ttl 7200
/redis:add semantic upstash
/redis:add vector embeddings 1536

# Sessions
/redis:add session nextjs 86400
/redis:add session fastapi

# Rate limiting
/redis:add ratelimit sliding-window 1000
/redis:add ratelimit token-bucket 50

# Pub/Sub
/redis:add pubsub channels
/redis:add pubsub streams

# Framework integration
/redis:add nextjs cache
/redis:add fastapi middleware

# Infrastructure
/redis:add sentinel cluster
/redis:add monitoring prometheus
/redis:add deploy upstash
```

---

## Feature Reference

| Feature      | Agent                 | $1 Options                        | Description         |
| ------------ | --------------------- | --------------------------------- | ------------------- |
| `cache`      | cache-architect       | simple/lru/ttl                    | Basic caching       |
| `semantic`   | semantic-specialist   | openai/upstash                    | Semantic cache      |
| `vector`     | vector-specialist     | embeddings/search                 | Vector cache        |
| `session`    | session-manager       | nextjs/fastapi/express            | Session storage     |
| `ratelimit`  | rate-limiter          | sliding-window/token-bucket/fixed | Rate limiting       |
| `pubsub`     | pub-sub-specialist    | channels/patterns/streams         | Pub/Sub messaging   |
| `nextjs`     | nextjs-integrator     | cache/session/middleware          | Next.js integration |
| `fastapi`    | fastapi-integrator    | cache/session/middleware          | FastAPI integration |
| `sentinel`   | sentinel-architect    | basic/cluster                     | High availability   |
| `monitoring` | monitoring-integrator | prometheus/datadog/custom         | Monitoring          |
| `deploy`     | deployment-architect  | upstash/redis-cloud/docker        | Deployment          |
