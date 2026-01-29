---
description: Build complete DigitalOcean infrastructure for new or existing projects with App Platform, databases, storage, and networking
argument-hint: [project-name] [--platform <app-platform|droplets|kubernetes>]
---

# Build DigitalOcean Infrastructure

**Project Name:** `$0`
**Platform:** `$1` (--platform app-platform, droplets, or kubernetes - default: app-platform)
**Options:** `$2` `$3`

> **Note:** Kubernetes (DOKS) is optional and recommended only for larger scale deployments, microservices architectures, or when you need advanced orchestration. For most applications, App Platform provides simpler deployment with auto-scaling.

---

## Phase 1: Project Analysis

**Goal:** Understand project context and choose deployment strategy

**Actions:**

```
Task(app-platform-agent) Analyze project for DigitalOcean deployment.

Detect: Framework (Next.js, FastAPI, Node.js, Go, static site)
Check: Database requirements, storage needs, scaling requirements
Output: Deployment strategy and resource plan
```

---

## Phase 2: Infrastructure Setup

**Goal:** Provision core infrastructure

**Actions:**

```
Task(infrastructure-agent) Set up DigitalOcean infrastructure.

Requirements:
- Create VPC for network isolation
- Configure firewall rules
- Set up SSH keys
- Create DNS records (if domain provided)
- Configure environment variables
```

---

## Phase 3: Database Provisioning

**Goal:** Create managed databases

**Actions:**

```
Task(database-agent) Provision managed databases.

Requirements:
- Create PostgreSQL cluster (if needed)
- Create Redis cache (if needed)
- Configure connection pooling
- Generate connection strings
- Set up SSL certificates
- Add database to VPC
```

---

## Phase 4: Storage Configuration

**Goal:** Set up object storage

**Actions:**

```
Task(infrastructure-agent) Configure Spaces storage.

Requirements:
- Create Spaces bucket
- Configure CORS policies
- Enable CDN (optional)
- Generate access credentials
- Add SDK integration code
```

---

## Phase 5: Application Deployment

**Goal:** Deploy application based on platform choice

### If Platform = "app-platform" (Default):

```
Task(app-platform-agent) Deploy to App Platform.

Requirements:
- Generate .do/app.yaml spec
- Configure build and run commands
- Set up environment variables
- Connect managed databases
- Configure auto-deploy from GitHub
- Set up health checks
- Deploy application
```

### If Platform = "droplets":

```
Task(infrastructure-agent) Deploy to Droplets.

Requirements:
- Create Droplet(s) with Docker
- Configure cloud-init
- Set up reverse proxy (nginx/caddy)
- Configure SSL with Let's Encrypt
- Set up systemd services
- Create deployment scripts
```

### If Platform = "kubernetes":

```
Task(kubernetes-agent) Deploy to DOKS.

Requirements:
- Create Kubernetes cluster
- Configure node pools with auto-scaling
- Install NGINX ingress controller
- Set up cert-manager for SSL
- Create Kubernetes manifests
- Configure container registry
- Deploy application
```

---

## Phase 6: Monitoring & DNS

**Goal:** Configure monitoring and domain

**Actions:**

```
Task(infrastructure-agent) Set up monitoring and DNS.

Requirements:
- Configure monitoring alerts
- Set up uptime checks
- Configure DNS records
- Set up SSL certificates
- Verify deployment health
```

---

## Output Structure

```
project/
├── .do/
│   ├── app.yaml           # App Platform spec (if using)
│   └── deploy.sh          # Deployment script
├── terraform/             # Infrastructure as code (optional)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── k8s/                   # Kubernetes manifests (if using)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── docker-compose.yml     # Local development
├── Dockerfile             # Container build
└── .env.example           # Environment template
```

---

## Usage Examples

```bash
# Build with App Platform (default)
/digitalocean:build my-app

# Build with Droplets
/digitalocean:build my-app --platform droplets

# Build with Kubernetes
/digitalocean:build my-app --platform kubernetes
```
