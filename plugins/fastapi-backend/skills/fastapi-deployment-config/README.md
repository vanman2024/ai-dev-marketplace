# FastAPI Deployment Configuration Skill

Autonomous multi-platform deployment configuration for FastAPI applications with production-ready optimizations.

## Overview

This skill provides comprehensive deployment capabilities for FastAPI applications across multiple cloud platforms and self-hosted environments. It includes Docker containerization, platform-specific configurations, health check implementations, and production optimization patterns.

## Features

### Multi-Platform Support
- **Railway** - Git-based deployment with automatic HTTPS
- **DigitalOcean App Platform** - Container registry with managed databases
- **AWS ECS** - Enterprise-grade container orchestration
- **AWS App Runner** - Simplified container deployment
- **Self-hosted** - Docker + Nginx reverse proxy

### Production Optimizations
- Multi-stage Docker builds for minimal image size
- Gunicorn + Uvicorn worker configuration
- Database connection pooling
- Redis caching integration
- Security hardening (non-root user, read-only filesystem)
- Health check endpoints
- Comprehensive logging

### Configuration Management
- Environment variable templates
- Platform-specific deployment configs
- Nginx reverse proxy configuration
- Docker Compose orchestration
- CORS and security headers

## Skill Structure

```
fastapi-deployment-config/
├── SKILL.md                    # Main skill instructions
├── README.md                   # This file
├── scripts/
│   ├── build-docker.sh        # Docker build automation
│   ├── validate-deployment.sh # Pre-deployment validation
│   └── health-check.sh        # Health endpoint verification
├── templates/
│   ├── Dockerfile             # Multi-stage production Dockerfile
│   ├── docker-compose.yml     # Local development orchestration
│   ├── railway.json           # Railway platform configuration
│   ├── digitalocean-app.yaml  # DigitalOcean App Platform config
│   ├── nginx.conf             # Reverse proxy configuration
│   ├── .env.example           # Development environment template
│   └── .env.production.example # Production environment template
└── examples/
    ├── railway_setup.md       # Railway deployment guide
    ├── digitalocean_setup.md  # DigitalOcean deployment guide
    └── aws_setup.md           # AWS ECS and App Runner guide
```

## Usage

### Quick Start

1. **Validate your FastAPI application:**
   ```bash
   ./scripts/validate-deployment.sh
   ```

2. **Build Docker container:**
   ```bash
   ./scripts/build-docker.sh --tag myapp:latest
   ```

3. **Test locally with Docker Compose:**
   ```bash
   docker-compose up -d
   ```

4. **Deploy to platform:**
   - Railway: See `examples/railway_setup.md`
   - DigitalOcean: See `examples/digitalocean_setup.md`
   - AWS: See `examples/aws_setup.md`

### Script Reference

#### build-docker.sh

Builds optimized Docker images with multi-stage builds:

```bash
./scripts/build-docker.sh [OPTIONS]

Options:
  --platform=PLATFORM  Target platform (default: linux/amd64)
  --tag=TAG           Docker image tag (default: fastapi-app:latest)
  --no-cache          Build without cache
  --verbose           Show detailed build output
  --help              Display help message

Examples:
  ./scripts/build-docker.sh --tag myapp:v1.0.0
  ./scripts/build-docker.sh --platform=linux/arm64 --tag myapp:latest
```

#### validate-deployment.sh

Pre-deployment validation checks:

```bash
./scripts/validate-deployment.sh [OPTIONS]

Options:
  --app-dir=DIR       FastAPI application directory (default: .)
  --strict            Fail on warnings
  --verbose           Show detailed validation output
  --help              Display help message

Validates:
  - requirements.txt exists and is valid
  - Environment variable configuration
  - FastAPI application structure
  - Database migration files (if using Alembic)
  - CORS configuration
  - Security settings
```

#### health-check.sh

Application health verification:

```bash
./scripts/health-check.sh <URL> [OPTIONS]

Options:
  --timeout=SECONDS   Request timeout (default: 10)
  --interval=SECONDS  Check interval for continuous monitoring (default: none)
  --retries=N         Number of retry attempts (default: 3)
  --debug             Show detailed request/response
  --help              Display help message

Examples:
  ./scripts/health-check.sh http://localhost:8000/health
  ./scripts/health-check.sh https://api.example.com/health --interval=30
```

### Template Reference

#### Dockerfile

Multi-stage production-ready Dockerfile:

**Stage 1: Builder**
- Python 3.11 slim base
- Install build dependencies
- Create virtual environment
- Install Python packages

**Stage 2: Runtime**
- Minimal Python runtime
- Non-root user (appuser)
- Copy virtual environment from builder
- Health check configuration
- Optimized for production

**Key features:**
- Layer caching optimization
- Security hardening
- Minimal image size (~150MB)
- Health check integration

#### docker-compose.yml

Local development orchestration:

**Services:**
- `api` - FastAPI application
- `db` - PostgreSQL database
- `redis` - Cache/session storage
- `nginx` - Reverse proxy (optional)

**Features:**
- Hot reload for development
- Volume mounts for code
- Environment variable injection
- Network isolation
- Health check dependencies

#### railway.json

Railway platform configuration:

```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "uvicorn main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "restartPolicyType": "ON_FAILURE"
  }
}
```

#### digitalocean-app.yaml

DigitalOcean App Platform specification:

```yaml
name: fastapi-app
services:
  - name: api
    dockerfile_path: Dockerfile
    health_check:
      http_path: /health
    envs:
      - key: DATABASE_URL
        scope: RUN_TIME
        type: SECRET
```

#### nginx.conf

Production reverse proxy configuration:

**Features:**
- SSL/TLS termination
- Rate limiting (100 req/min per IP)
- Request buffering
- Gzip compression
- Static file serving
- WebSocket support
- Security headers (HSTS, X-Frame-Options, CSP)

## Platform Selection Guide

### Railway
**Best for:**
- Small to medium applications
- Quick prototypes
- Budget-conscious projects ($5-10/mo)

**Pros:**
- Simplest setup
- Git-based deployment
- Automatic HTTPS
- Integrated databases

**Cons:**
- Limited scaling options
- No advanced networking

### DigitalOcean App Platform
**Best for:**
- Production applications
- Teams needing managed infrastructure
- Balanced cost/features ($12+/mo)

**Pros:**
- Managed databases
- Auto-scaling
- CDN integration
- Good monitoring

**Cons:**
- More complex than Railway
- Higher base cost

### AWS ECS
**Best for:**
- Enterprise applications
- High-traffic services
- Complex microservices

**Pros:**
- Advanced orchestration
- Deep AWS integration
- Multi-AZ deployment
- Enterprise support

**Cons:**
- Steep learning curve
- Higher operational complexity
- Higher costs ($20-30+/mo)

### AWS App Runner
**Best for:**
- Simplified AWS deployment
- Container-based apps
- Auto-scaling needs

**Pros:**
- Easier than ECS
- Automatic scaling
- AWS ecosystem benefits

**Cons:**
- Less control than ECS
- Limited networking options

## Environment Variables

### Required Variables

```bash
# Application
SECRET_KEY=your-secret-key-here
ENVIRONMENT=production

# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# CORS
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Optional: Redis
REDIS_URL=redis://localhost:6379/0

# Optional: Logging
LOG_LEVEL=INFO
```

### Platform-Specific Variables

**Railway:**
```bash
PORT=8000  # Automatically set by Railway
DATABASE_URL  # Automatically set if using Railway PostgreSQL
```

**DigitalOcean:**
```bash
DATABASE_URL  # Set via App Platform UI
REDIS_URL     # Set if using managed Redis
```

**AWS:**
```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-key-id
AWS_SECRET_ACCESS_KEY=your-secret-key
```

## Security Best Practices

### Implemented in Templates
- ✅ Non-root Docker user (appuser:1000)
- ✅ Read-only root filesystem where possible
- ✅ Minimal base images (Python slim)
- ✅ Security headers (HSTS, CSP, X-Frame-Options)
- ✅ CORS configuration
- ✅ Rate limiting (Nginx)
- ✅ Secret management via environment variables
- ✅ SQL injection prevention (SQLAlchemy ORM)
- ✅ Input validation (Pydantic models)

### Additional Recommendations
- Use secrets management (AWS Secrets Manager, Railway variables)
- Enable HTTPS only (redirect HTTP to HTTPS)
- Implement authentication (OAuth2, JWT)
- Regular dependency updates
- Container image scanning
- Database connection encryption

## Performance Tuning

### Worker Configuration

**Gunicorn workers formula:**
```
workers = (2 × CPU cores) + 1
```

**Example configuration:**
```bash
gunicorn main:app \
  --workers 4 \
  --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000 \
  --worker-tmp-dir /dev/shm \
  --access-logfile - \
  --error-logfile - \
  --log-level info
```

### Database Connection Pooling

```python
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    pool_size=10,          # Number of persistent connections
    max_overflow=20,       # Additional connections when pool is full
    pool_pre_ping=True,    # Verify connections before use
    pool_recycle=3600      # Recycle connections after 1 hour
)
```

### Redis Caching

```python
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from redis import asyncio as aioredis

@app.on_event("startup")
async def startup():
    redis = await aioredis.from_url(REDIS_URL)
    FastAPICache.init(RedisBackend(redis), prefix="fastapi-cache")
```

## Troubleshooting

### Common Issues

**Port binding errors:**
```bash
# Check if port is in use
lsof -i :8000

# Use different port
uvicorn main:app --port 8001
```

**Database connection failures:**
```bash
# Verify DATABASE_URL format
# PostgreSQL: postgresql://user:password@host:port/database
# MySQL: mysql://user:password@host:port/database

# Test connection
python -c "from sqlalchemy import create_engine; engine = create_engine('$DATABASE_URL'); engine.connect()"
```

**Docker build failures:**
```bash
# Clear build cache
docker builder prune

# Build with verbose output
./scripts/build-docker.sh --verbose --no-cache
```

**Health check failures:**
```bash
# Test health endpoint locally
curl http://localhost:8000/health

# Check logs
docker logs <container-id>
```

## Version Compatibility

- **FastAPI:** 0.104.0 or higher
- **Python:** 3.11 or higher
- **Docker:** 20.10 or higher
- **Docker Compose:** 2.0 or higher

## Contributing

When modifying this skill:

1. Test all scripts with `bash -n script.sh` (syntax check)
2. Validate templates with actual deployments
3. Update version compatibility notes
4. Keep SKILL.md under 500 lines (use progressive disclosure)
5. Ensure all scripts are executable (`chmod +x`)

## Resources

### Official Documentation
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)
- [Railway Documentation](https://docs.railway.app/)
- [DigitalOcean App Platform](https://docs.digitalocean.com/products/app-platform/)
- [AWS ECS](https://docs.aws.amazon.com/ecs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Related Skills
- `database-config` - Database setup and migrations
- `api-testing` - API endpoint testing
- `monitoring-setup` - Application monitoring and logging

---

**Skill Version:** 1.0.0
**Last Updated:** 2025-10-31
**Maintainer:** fastapi-backend plugin
