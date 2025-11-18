# Redis Plugin for AI Dev Marketplace

Production-ready Redis integration for caching, sessions, rate limiting, pub/sub messaging, and AI embedding cache with multi-framework support.

## Features

### Core Capabilities
- **Caching Strategies**: Cache-aside, write-through, write-behind patterns
- **Session Management**: Secure session storage for FastAPI, Next.js, Express
- **Rate Limiting**: API rate limiting with multiple algorithms
- **Pub/Sub Messaging**: Real-time messaging for distributed systems
- **Connection Management**: Pooling, retries, failover, circuit breakers

### AI-Specific Features
- **Embedding Cache**: Reduce AI API costs by 50%+
- **Vector Query Cache**: Cache vector search results
- **Semantic Cache**: AI query result caching with similarity
- **Conversation Context**: Session-scoped memory for chatbots

### Production Ready
- **High Availability**: Sentinel and Cluster support
- **Monitoring**: Metrics, health checks, Prometheus integration
- **Security**: TLS/SSL, ACLs, environment variables only
- **Deployment**: Docker, Kubernetes, Redis Cloud, self-hosted

## Quick Start

```bash
# Initialize Redis in your project
/redis:init

# Add caching layer
/redis:add-cache

# Add session management
/redis:add-session-store

# Add AI embedding cache (50%+ cost savings)
/redis:add-vector-cache
```

## Commands (18 total)

### Setup
- `/redis:init` - Initialize with framework detection
- `/redis:add-connection-pool` - Configure connection pooling
- `/redis:add-sentinel` - High availability
- `/redis:add-cluster` - Cluster configuration

### Features
- `/redis:add-cache` - Caching layer
- `/redis:add-session-store` - Session management
- `/redis:add-rate-limiting` - Rate limiting
- `/redis:add-pub-sub` - Pub/sub messaging
- `/redis:add-vector-cache` - AI embedding cache
- `/redis:add-semantic-cache` - AI semantic cache
- `/redis:add-queue` - Simple queue

### Integrations
- `/redis:integrate-fastapi` - FastAPI
- `/redis:integrate-nextjs` - Next.js
- `/redis:integrate-express` - Express
- `/redis:integrate-celery` - Celery

### Operations
- `/redis:add-monitoring` - Monitoring
- `/redis:deploy` - Deployment
- `/redis:test` - Testing

## Agents (12 specialists)

1. redis-setup-agent - Configuration & detection
2. cache-architect - Caching strategies
3. session-manager - Session stores
4. rate-limiter-specialist - Rate limiting
5. pub-sub-specialist - Messaging
6. vector-cache-specialist - AI embeddings
7. semantic-cache-specialist - AI queries
8. sentinel-architect - High availability
9. monitoring-integrator - Observability
10. fastapi-integrator - FastAPI integration
11. nextjs-integrator - Next.js integration
12. deployment-architect - Production deployment

## Skills (10 comprehensive)

1. cache-strategies - Patterns & eviction
2. session-management - Implementations
3. rate-limiting-patterns - Algorithms
4. pub-sub-patterns - Messaging
5. ai-cache-patterns - AI optimization
6. sentinel-configurations - HA templates
7. monitoring-patterns - Metrics & alerts
8. deployment-configs - Docker/K8s
9. connection-management - Pooling
10. framework-integrations - Multi-framework

## Security

✅ Environment variables only
✅ `.env.example` with placeholders
✅ `.gitignore` protection
✅ TLS/SSL for production

```bash
# .env.example (safe to commit)
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=redis_your_password_here
```

## Framework Support

- **Python**: FastAPI, Django, Flask
- **Node.js**: Next.js, Express
- **Task Queue**: Celery

## Deployment

- Local Docker/Docker Compose
- Redis Cloud (managed)
- Self-hosted (DigitalOcean, AWS, GCP)
- Kubernetes with Operators
- Redis Enterprise

## AI Cost Optimization

```python
# Embedding cache - 50%+ savings
embedding = cache_embedding(text, "text-embedding-3-small")

# Semantic cache - Similar queries
response = semantic_cache_query(prompt, threshold=0.90)
```

## License

MIT
