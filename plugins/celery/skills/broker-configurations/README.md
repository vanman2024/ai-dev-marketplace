# Broker Configurations Skill

Comprehensive message broker configuration patterns for Celery including Redis, RabbitMQ, and Amazon SQS.

## Overview

This skill provides production-ready configuration templates, setup scripts, and comprehensive examples for all major Celery message brokers.

## Contents

### Templates (5)

1. **redis-config.py** - Production Redis configuration with Sentinel support
2. **rabbitmq-config.py** - RabbitMQ with quorum queues and HA
3. **sqs-config.py** - AWS SQS with IAM roles and FIFO queues
4. **connection-strings.env** - Environment variable templates for all brokers
5. **ssl-config.py** - SSL/TLS configuration for Redis and RabbitMQ

### Scripts (3)

1. **test-broker-connection.sh** - Test connectivity to any broker type
2. **setup-redis.sh** - Install and configure Redis with production settings
3. **setup-rabbitmq.sh** - Install and configure RabbitMQ cluster

All scripts are executable and include comprehensive error handling.

### Examples (3)

1. **redis-sentinel.md** - High availability with Redis Sentinel
2. **rabbitmq-ha.md** - RabbitMQ clustering with quorum queues
3. **sqs-setup.md** - Complete AWS SQS integration guide

## Quick Start

### Redis

```bash
# Setup
./scripts/setup-redis.sh --install --configure

# Test
./scripts/test-broker-connection.sh redis

# Use template
cp templates/redis-config.py celeryconfig.py
```

### RabbitMQ

```bash
# Setup
./scripts/setup-rabbitmq.sh --install --configure

# Test
./scripts/test-broker-connection.sh rabbitmq

# Use template
cp templates/rabbitmq-config.py celeryconfig.py
```

### AWS SQS

```bash
# Configure IAM
# See examples/sqs-setup.md for complete guide

# Test
./scripts/test-broker-connection.sh sqs

# Use template
cp templates/sqs-config.py celeryconfig.py
```

## Broker Selection

| Feature | Redis | RabbitMQ | SQS |
|---------|-------|----------|-----|
| Speed | ★★★★★ | ★★★★☆ | ★★★☆☆ |
| Reliability | ★★★☆☆ | ★★★★★ | ★★★★★ |
| Management | ★★★☆☆ | ★★★★★ | ★★☆☆☆ |
| Scalability | ★★★★☆ | ★★★★☆ | ★★★★★ |
| Cost | Server | Server | Pay-per-use |

## Features

- Production-ready configurations
- SSL/TLS support
- High availability patterns
- Docker Compose examples
- Comprehensive testing scripts
- Security best practices
- Performance tuning guides
- Troubleshooting guides

## Security

All templates use environment variables and placeholders only. No hardcoded credentials.

**See:** `templates/connection-strings.env` for proper credential management.

## Requirements

- Python 3.8+
- Celery 5.0+
- Redis 6+ / RabbitMQ 3.8+ / AWS SQS

## Documentation

Comprehensive documentation is provided in:
- SKILL.md - Main skill documentation
- examples/*.md - Detailed setup guides
- templates/*.py - Inline code documentation

## License

Part of the AI Dev Marketplace Celery plugin.
