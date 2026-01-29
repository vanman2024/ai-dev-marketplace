# App Platform Deployment Skill

Deploy applications to DigitalOcean App Platform - fully managed PaaS for web apps, APIs, workers, and static sites.

## Usage

```
!{skill digitalocean:app-platform-deployment}
```

## App Spec Reference

### Full-Stack Next.js with Database

```yaml
name: nextjs-fullstack
region: nyc
features:
  - buildpack-stack=ubuntu-22

services:
  - name: web
    github:
      repo: username/nextjs-app
      branch: main
      deploy_on_push: true
    build_command: npm run build
    run_command: npm start
    http_port: 3000
    instance_size_slug: apps-s-1vcpu-2gb
    instance_count: 2
    health_check:
      http_path: /api/health
      initial_delay_seconds: 10
      period_seconds: 10
    envs:
      - key: NODE_ENV
        scope: RUN_TIME
        value: production
      - key: DATABASE_URL
        scope: RUN_TIME
        value: ${db.DATABASE_URL}

databases:
  - name: db
    engine: PG
    version: '16'
    production: true
```

### FastAPI Backend

```yaml
name: fastapi-backend
region: nyc

services:
  - name: api
    github:
      repo: username/fastapi-app
      branch: main
    dockerfile_path: Dockerfile
    http_port: 8000
    instance_size_slug: apps-s-2vcpu-4gb
    instance_count: 2
    health_check:
      http_path: /health
    envs:
      - key: DATABASE_URL
        scope: RUN_TIME
        value: ${db.DATABASE_URL}
      - key: REDIS_URL
        scope: RUN_TIME
        value: ${cache.DATABASE_URL}

databases:
  - name: db
    engine: PG
    production: true
  - name: cache
    engine: REDIS
    production: true
```

### Static Site (React/Vue)

```yaml
name: my-static-site
region: nyc

static_sites:
  - name: frontend
    github:
      repo: username/frontend
      branch: main
      deploy_on_push: true
    build_command: npm run build
    output_dir: dist
    envs:
      - key: VITE_API_URL
        scope: BUILD_TIME
        value: https://api.example.com
```

### Worker with Job

```yaml
name: app-with-workers
region: nyc

services:
  - name: web
    github:
      repo: username/app
      branch: main
    http_port: 3000

workers:
  - name: queue-worker
    github:
      repo: username/app
      branch: main
    run_command: npm run worker
    instance_size_slug: apps-s-1vcpu-1gb
    instance_count: 2

jobs:
  - name: daily-cleanup
    github:
      repo: username/app
      branch: main
    run_command: npm run cleanup
    instance_size_slug: apps-s-1vcpu-0.5gb
    kind: PRE_DEPLOY
```

## Instance Sizes

| Slug               | vCPUs | Memory | Price/mo  |
| ------------------ | ----- | ------ | --------- |
| apps-s-1vcpu-0.5gb | 1     | 512MB  | $5        |
| apps-s-1vcpu-1gb   | 1     | 1GB    | $10       |
| apps-s-1vcpu-2gb   | 1     | 2GB    | $20       |
| apps-s-2vcpu-4gb   | 2     | 4GB    | $40       |
| apps-d-1vcpu-0.5gb | 1     | 512MB  | Dedicated |

## Deployment Commands

```bash
# Validate spec
doctl apps spec validate .do/app.yaml

# Create app
doctl apps create --spec .do/app.yaml --wait

# Update app
doctl apps update <app-id> --spec .do/app.yaml

# Deploy
doctl apps create-deployment <app-id> --wait

# Logs
doctl apps logs <app-id> --type=run
```
