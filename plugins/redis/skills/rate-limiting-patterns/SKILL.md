---
name: rate-limiting-patterns
description: Redis-based rate limiting implementations with token bucket, leaky bucket, and sliding window algorithms. Use when implementing API rate limiting, throttling, or request quota management.
allowed-tools: Read, Bash, Grep, Glob
---

# rate-limiting-patterns

**Purpose**: Redis-based rate limiting implementations with various algorithms.

**Activation Triggers**:
- When implementing rate limiting
- When user mentions API throttling, request quotas
- When designing rate-limited endpoints

## Quick Reference

This skill provides templates, scripts, and examples for Redis rate limiting.

## Scripts

- `scripts/setup-redis.sh` - Initial Redis setup and configuration
- `scripts/validate-config.sh` - Validate Redis configuration
- `scripts/test-connection.sh` - Test Redis connectivity

## Templates

- `templates/basic-config.ts.template` - TypeScript rate limiting config
- `templates/basic-config.py.template` - Python rate limiting config
- `templates/redis-config.env.template` - Environment variables template
- `templates/docker-compose.yml.template` - Docker Compose setup

## Examples

- `examples/basic-usage.md` - Basic rate limiting patterns
- `examples/fastapi-example.md` - FastAPI integration example
- `examples/nextjs-example.md` - Next.js integration example

## Security Compliance

This skill follows strict security rules:
- All code examples use placeholder values only
- No real API keys, passwords, or secrets
- Environment variable references in all code
- `.gitignore` protection documented
