---
description: Build complete Redis infrastructure for new or existing projects with caching, sessions, pub/sub, and rate limiting
argument-hint: [project-name] [--existing]
---

# Build Redis Infrastructure

**Project Name:** `$0`
**Mode:** `$1` (--existing for existing project, omit for new)

---

## Phase 1: Project Analysis

**Goal:** Understand project context

**Actions:**

```
Task(redis-setup-agent) Analyze project for Redis setup.

Detect: Framework (Next.js, FastAPI), existing caching
Check: Environment, deployment target
Output: Redis strategy
```

---

## Phase 2: Core Setup

**Goal:** Set up Redis client

**Actions:**

```
Task(redis-setup-agent) Set up Redis core.

Requirements:
- Install Redis client (ioredis, upstash)
- Configure connection
- Set up client instance
- Add connection pooling
- Test connection
```

---

## Phase 3: Caching Layer

**Goal:** Configure caching

**Actions:**

```
Task(cache-architect) Set up caching layer.

Requirements:
- Configure cache patterns
- Set TTL strategies
- Add cache invalidation
- Create cache helpers
- Add monitoring
```

---

## Phase 4: Session Management

**Goal:** Add session support

**Actions:**

```
Task(session-manager) Configure sessions.

Requirements:
- Set up session storage
- Configure expiration
- Add session helpers
- Handle session cleanup
```

---

## Phase 5: Rate Limiting

**Goal:** Add rate limiting

**Actions:**

```
Task(rate-limiter-specialist) Set up rate limiting.

Requirements:
- Configure rate limit rules
- Set up sliding window
- Add IP-based limits
- Create middleware
```

---

## Phase 6: Pub/Sub

**Goal:** Set up pub/sub

**Actions:**

```
Task(pub-sub-specialist) Configure pub/sub.

Requirements:
- Set up publishers
- Configure subscribers
- Add message handling
- Create event patterns
```

---

## Summary

**Output:**

```
✅ Redis Infrastructure Complete

To add features:
  /redis:add cache <type>              # Caching
  /redis:add session                   # Session store
  /redis:add ratelimit <rules>         # Rate limiting
  /redis:add pubsub                    # Pub/Sub
  /redis:add vector                    # Vector cache

To run:
  Ensure Redis is running
```
