---
description: Add specific DigitalOcean services to existing project. Features include database, spaces, droplet, kubernetes, functions, vpc, firewall, load-balancer.
argument-hint: <feature> [options]
---

# Add DigitalOcean Service

**Requested Feature:** `$0`
**Additional Options:** `$1` `$2` `$3`

---

## Argument Routing

Based on the feature argument `$0`, route to the appropriate specialized agent:

### Database Features

**If `$0` = "database":**

```
Task(database-agent) Add MANAGED DATABASE.

Requirements:
- Engine: $1 (pg, mysql, redis, mongodb, kafka, opensearch - default: pg)
- Size: $2 (db-s-1vcpu-1gb, db-s-2vcpu-4gb, etc. - default: db-s-1vcpu-2gb)
- Region: $3 (nyc1, sfo3, ams3, etc. - default: nyc1)
- Create managed database cluster
- Configure connection pooling
- Generate connection strings
- Set up SSL certificates
- Add to VPC if exists
```

**If `$0` = "redis" or `$0` = "cache":**

```
Task(database-agent) Add REDIS/VALKEY cache.

Requirements:
- Size: $1 (default: db-s-1vcpu-1gb)
- Region: $2 (default: nyc1)
- Create managed Redis cluster
- Configure eviction policy
- Generate connection URL
- Add SDK integration code
```

### Storage Features

**If `$0` = "spaces" or `$0` = "storage":**

```
Task(infrastructure-agent) Add SPACES object storage.

Requirements:
- Space name: $1 (required)
- Region: $2 (nyc3, sfo3, ams3, sgp1, fra1 - default: nyc3)
- Create Space bucket
- Configure CORS
- Enable CDN (optional)
- Generate access keys
- Add S3-compatible SDK code
```

### Compute Features

**If `$0` = "droplet":**

```
Task(infrastructure-agent) Add DROPLET VM.

Requirements:
- Name: $1 (required)
- Size: $2 (s-1vcpu-1gb, s-2vcpu-4gb, etc. - default: s-2vcpu-4gb)
- Image: $3 (ubuntu-22-04-x64, docker-20-04, etc. - default: ubuntu-22-04-x64)
- Create Droplet
- Configure SSH keys
- Add to VPC
- Set up firewall rules
- Generate cloud-init (optional)
```

**If `$0` = "kubernetes" or `$0` = "k8s":** _(Optional - for larger scale deployments)_

```
Task(kubernetes-agent) Add KUBERNETES cluster.

Requirements:
- Cluster name: $1 (required)
- Node size: $2 (s-2vcpu-4gb, s-4vcpu-8gb - default: s-4vcpu-8gb)
- Node count: $3 (default: 3)
- Create DOKS cluster
- Configure node pool with auto-scaling
- Save kubeconfig
- Install ingress controller
- Set up cert-manager

Note: Kubernetes is recommended for microservices, high availability needs,
or when scaling beyond App Platform limits. For most apps, use App Platform.
```

**If `$0` = "functions" or `$0` = "serverless":**

```
Task(app-platform-agent) Add SERVERLESS FUNCTIONS.

Requirements:
- Project name: $1 (required)
- Runtime: $2 (nodejs:18, python:3.11, go:1.21 - default: nodejs:18)
- Initialize functions project
- Create sample function
- Configure project.yml
- Deploy to DO Functions
```

### Networking Features

**If `$0` = "vpc":**

```
Task(infrastructure-agent) Add VPC network.

Requirements:
- Name: $1 (required)
- Region: $2 (default: nyc1)
- IP range: $3 (default: 10.10.10.0/24)
- Create VPC
- Configure subnets
- Update existing resources
```

**If `$0` = "firewall":**

```
Task(infrastructure-agent) Add CLOUD FIREWALL.

Requirements:
- Name: $1 (required)
- Type: $2 (web, api, database, custom - default: web)
- Create firewall rules
- Apply to Droplets/tags
- Configure inbound/outbound rules
```

**If `$0` = "load-balancer" or `$0` = "lb":**

```
Task(infrastructure-agent) Add LOAD BALANCER.

Requirements:
- Name: $1 (required)
- Target port: $2 (default: 3000)
- SSL: $3 (true/false - default: true)
- Create load balancer
- Configure health checks
- Set up SSL termination
- Add backend Droplets
```

**If `$0` = "dns":**

```
Task(infrastructure-agent) Add DNS RECORDS.

Requirements:
- Domain: $1 (required)
- Record type: $2 (A, CNAME, MX, TXT - default: A)
- Value: $3 (IP address or hostname)
- Create/update DNS records
- Configure TTL
```

### Deployment Features

**If `$0` = "app" or `$0` = "app-platform":**

```
Task(app-platform-agent) Add APP PLATFORM deployment.

Requirements:
- App name: $1 (required)
- Type: $2 (web, worker, static, job - default: web)
- Create app spec (.do/app.yaml)
- Configure build/run commands
- Set up environment variables
- Connect database (optional)
- Deploy to App Platform
```

**If `$0` = "registry":**

```
Task(kubernetes-agent) Add CONTAINER REGISTRY.

Requirements:
- Registry name: $1 (required)
- Create container registry
- Configure Docker login
- Set up Kubernetes integration
- Generate push/pull commands
```

---

## Usage Examples

```bash
# Add PostgreSQL database
/digitalocean:add database pg db-s-2vcpu-4gb nyc1

# Add Redis cache
/digitalocean:add redis

# Add Spaces storage
/digitalocean:add spaces my-assets nyc3

# Add Kubernetes cluster
/digitalocean:add kubernetes prod-cluster s-4vcpu-8gb 3

# Add VPC
/digitalocean:add vpc production-vpc nyc1

# Add load balancer
/digitalocean:add load-balancer web-lb 3000 true

# Add App Platform deployment
/digitalocean:add app my-app web
```

---

## Skills Used

- `!{skill digitalocean:managed-databases}` - Database provisioning patterns
- `!{skill digitalocean:spaces-storage}` - Object storage integration
- `!{skill digitalocean:functions-serverless}` - Serverless deployment
- `!{skill digitalocean:networking-config}` - VPC, firewalls, load balancers

## Documentation

- https://docs.digitalocean.com/products/databases/
- https://docs.digitalocean.com/products/spaces/
- https://docs.digitalocean.com/products/functions/
- https://docs.digitalocean.com/products/networking/
