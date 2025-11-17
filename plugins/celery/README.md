# Celery Plugin

Production-ready Celery distributed task queue with worker management, beat scheduling, monitoring (Flower), and framework integrations (Django, Flask, FastAPI)

## Overview

The Celery plugin provides comprehensive support for building distributed task queue systems in Python applications. It covers everything from initial setup to production deployment with monitoring, scheduling, and framework-specific integrations.

## Features

- **Task Queue Setup**: Initialize Celery with Redis, RabbitMQ, or Amazon SQS brokers
- **Task Development**: Create production-ready tasks with retries, rate limiting, and validation
- **Workflow Composition**: Build complex workflows with chains, groups, and chords
- **Worker Management**: Configure worker pools, concurrency, and autoscaling
- **Beat Scheduling**: Set up periodic tasks with crontab, interval, or solar schedules
- **Framework Integration**: Deep integration with Django, Flask, and FastAPI
- **Monitoring**: Flower web interface with authentication and Prometheus metrics
- **Production Deployment**: Docker, Kubernetes, and systemd configurations

## Installation

This plugin is part of the AI Dev Marketplace and is automatically available in Claude Code.

## Quick Start

```bash
# Initialize Celery in your project
/celery:init

# Configure message broker
/celery:add-broker

# Create your first task
/celery:add-task send-email "Send email notifications"

# Add monitoring
/celery:add-monitoring

# Test everything
/celery:test
```

## Available Commands

### Setup & Initialization
- `/celery:init` - Initialize Celery in existing project
- `/celery:add-broker` - Configure message broker (Redis/RabbitMQ/SQS)
- `/celery:add-result-backend` - Configure result backend

### Task Development
- `/celery:add-task` - Generate new Celery task
- `/celery:add-workflow` - Create task workflows (chains, groups, chords)
- `/celery:add-beat` - Configure periodic task scheduling

### Framework Integration
- `/celery:integrate-django` - Django integration with celery-results and celery-beat
- `/celery:integrate-flask` - Flask integration with app context
- `/celery:integrate-fastapi` - FastAPI integration with async support

### Operations
- `/celery:add-workers` - Configure worker pools and concurrency
- `/celery:add-routing` - Set up task routing and queues
- `/celery:add-monitoring` - Install and configure Flower

### Production
- `/celery:add-error-handling` - Implement error handling and retries
- `/celery:deploy` - Production deployment configurations
- `/celery:test` - Generate test suite for tasks

## Framework Support

### Django
- django-celery-results for database-backed results
- django-celery-beat for database-backed schedules
- Transaction-safe task execution
- ORM integration

### FastAPI
- Async/await compatibility
- Dependency injection integration
- Background task endpoints
- OpenAPI documentation

### Flask
- Application factory pattern
- Blueprint integration
- Request context handling
- Configuration management

## Broker & Backend Options

### Message Brokers
- **RabbitMQ**: High reliability, advanced routing
- **Redis**: Fast, simple setup
- **Amazon SQS**: AWS native, managed service

### Result Backends
- **Redis**: Fast, in-memory storage
- **PostgreSQL/MySQL**: Persistent, queryable results
- **RabbitMQ RPC**: Transient results
- **MongoDB**: Document storage

## Workflow Patterns

- **Chains**: Sequential task execution
- **Groups**: Parallel task execution
- **Chords**: Group with callback
- **Signatures**: Task composition primitives

## Monitoring & Observability

- **Flower**: Real-time web monitoring interface
- **Prometheus**: Metrics export and alerting
- **Event Monitoring**: Task lifecycle events
- **Health Checks**: Worker and broker health

## Production Features

- **Worker Pools**: prefork, eventlet, gevent, threads
- **Autoscaling**: Dynamic worker scaling based on load
- **Task Routing**: Route tasks to specific workers/queues
- **Priority Queues**: Task prioritization
- **Rate Limiting**: Control task execution rate
- **Time Limits**: Hard and soft time limits
- **Retries**: Automatic retry with exponential backoff

## Security

All generated configurations follow strict security rules:
- Never hardcode credentials or API keys
- Use environment variables for sensitive data
- Provide `.env.example` templates with placeholders
- Document key acquisition for all services

## Documentation

- [Celery Architecture](docs/CELERY-ARCHITECTURE.md)
- [Broker Comparison](docs/BROKER-COMPARISON.md)
- [Monitoring Guide](docs/MONITORING-GUIDE.md)

## Contributing

Contributions are welcome! Please follow the marketplace plugin development guidelines.

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions, please visit the AI Dev Marketplace repository.
