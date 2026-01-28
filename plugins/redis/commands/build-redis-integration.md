---
description: Build complete Redis integration - initializes if needed, then runs specialized agents in parallel for caching, sessions, rate limiting, pub/sub, and vector features
argument-hint: <project-name> [--framework <fastapi|nextjs|express>]
---

# Build Complete Redis Integration

**Goal:** Create a production-ready Redis integration by orchestrating all specialized agents in parallel.

**This command handles everything** - from setup to full integration with caching, sessions, rate limiting, pub/sub, and AI vector features.

## Stack (Always Use Latest Versions)

- **Redis** - Latest (7.x+) with modules
- **Redis Stack** - Latest for vector search, JSON, time series
- **redis-py** - Latest async client for Python
- **ioredis** - Latest for Node.js/Next.js
- **RedisVL** - Latest for vector operations

**IMPORTANT:** Always check for and use the most recent stable versions. Use `redis-server --version` and check docs for current features.

## Arguments

- `$ARGUMENTS` - Project name and optional framework
- `--framework <name>` - Target framework (fastapi, nextjs, express)

## Execution Flow

### Phase 1: Discovery & Planning

**Actions:**

1. Parse `$ARGUMENTS` for project name and framework
2. Auto-detect framework if not specified (check package.json, pyproject.toml)
3. Discover architecture documentation:
   ```
   !{glob docs/architecture/**/*.md}
   !{glob specs/*/spec.md}
   ```
4. Create execution plan based on features needed

### Phase 2: Redis Setup (if needed)

**If Redis not configured, run setup agent:**

```
Task("Initialize Redis", @redis-setup-agent, {
  prompt: "Initialize Redis for '$PROJECT_NAME':
    - Detect framework (FastAPI, Next.js, Express)
    - Install appropriate client library (latest version)
    - Configure connection with environment variables
    - Set up connection pooling
    - Create Redis client singleton
    Prepare for production use."
})
```

**Wait for setup to complete before proceeding.**

### Phase 3: Parallel Agent Execution

**Launch specialized agents based on architecture needs:**

```
// Agent 1: Caching Layer
Task("Build caching layer", @cache-architect, {
  prompt: "Design and implement caching strategy:
    - Analyze data access patterns from architecture
    - Implement cache-aside pattern for queries
    - Set up write-through for critical data
    - Configure TTL policies
    - Add cache invalidation logic
    Follow architecture docs for cache requirements."
})

// Agent 2: Session Management
Task("Setup sessions", @session-manager, {
  prompt: "Implement Redis session storage:
    - Configure session store for detected framework
    - Set secure session options
    - Implement session cleanup
    - Add session middleware
    Follow auth requirements from architecture."
})

// Agent 3: Rate Limiting
Task("Add rate limiting", @rate-limiter-specialist, {
  prompt: "Implement API rate limiting:
    - Sliding window algorithm for accuracy
    - Configure limits per endpoint type
    - Add rate limit headers
    - Implement graceful degradation
    Follow API requirements from architecture."
})

// Agent 4: Real-time Features (if needed)
Task("Setup pub/sub", @pub-sub-specialist, {
  prompt: "Implement real-time messaging if specified:
    - Configure pub/sub channels
    - Set up message handlers
    - Implement event broadcasting
    - Add presence tracking if needed
    Skip if no realtime in architecture."
})

// Agent 5: AI Vector Features (if needed)
Task("Setup vector cache", @vector-cache-specialist, {
  prompt: "Implement AI caching if specified:
    - Set up embedding cache
    - Configure semantic similarity search
    - Implement LLM response caching
    - Add vector index for RAG
    Skip if no AI features in architecture."
})
```

### Phase 4: Infrastructure Setup

**After feature agents complete:**

```
// Monitoring
Task("Add monitoring", @monitoring-integrator, {
  prompt: "Set up Redis monitoring:
    - Health check endpoints
    - Prometheus metrics export
    - Connection pool monitoring
    - Cache hit/miss ratios
    Configure for production observability."
})

// Deployment config
Task("Configure deployment", @deployment-architect, {
  prompt: "Prepare deployment configuration:
    - Docker Compose for local dev
    - Production connection strings
    - Sentinel/Cluster config if needed
    - Cloud provider setup (Railway, Upstash, etc.)
    Output deployment documentation."
})
```

### Phase 5: Final Output

**Provide summary:**

- List all Redis features implemented
- Show configuration files created
- Provide test commands:

  ```bash
  # Test connection
  redis-cli ping

  # Start local Redis
  docker-compose up redis -d

  # Run integration tests
  pytest tests/test_redis.py -v
  ```

- Note any manual steps (env vars, cloud setup)

## Utility Commands

For individual features, use these commands instead:

- `/redis:add-cache` - Add caching layer only
- `/redis:add-session-store` - Add session management only
- `/redis:add-rate-limiting` - Add rate limiting only
- `/redis:add-pub-sub` - Add pub/sub messaging only
- `/redis:add-vector-cache` - Add AI vector caching
- `/redis:add-semantic-cache` - Add semantic query caching
- `/redis:integrate-fastapi` - FastAPI-specific integration
- `/redis:integrate-nextjs` - Next.js-specific integration
