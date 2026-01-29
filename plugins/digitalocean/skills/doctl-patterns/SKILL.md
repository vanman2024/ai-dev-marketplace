# doctl CLI Patterns Skill

DigitalOcean CLI (doctl) command patterns for all services.

## Usage

```
!{skill digitalocean:doctl-patterns}
```

## Authentication

```bash
# Authenticate with API token
doctl auth init

# Use specific context
doctl auth switch --context personal

# List contexts
doctl auth list

# Validate authentication
doctl account get
```

## Droplets

```bash
# Create Droplet
doctl compute droplet create my-server \
  --image ubuntu-22-04-x64 \
  --size s-2vcpu-4gb \
  --region nyc1 \
  --ssh-keys <fingerprint> \
  --enable-monitoring \
  --enable-backups \
  --vpc-uuid <vpc-id> \
  --tag-names "env:production,role:web"

# List Droplets
doctl compute droplet list --format ID,Name,PublicIPv4,Memory,Region

# Get Droplet
doctl compute droplet get <droplet-id>

# Delete Droplet
doctl compute droplet delete <droplet-id>

# Droplet Actions
doctl compute droplet-action power-off <droplet-id>
doctl compute droplet-action power-on <droplet-id>
doctl compute droplet-action reboot <droplet-id>
doctl compute droplet-action snapshot <droplet-id> --snapshot-name "backup-$(date +%Y%m%d)"
doctl compute droplet-action resize <droplet-id> --size s-4vcpu-8gb
```

## VPCs

```bash
# Create VPC
doctl vpcs create \
  --name production-vpc \
  --region nyc1 \
  --ip-range 10.10.10.0/24

# List VPCs
doctl vpcs list

# Get VPC members
doctl vpcs list-members <vpc-id>
```

## Firewalls

```bash
# Create firewall
doctl compute firewall create \
  --name web-firewall \
  --inbound-rules "protocol:tcp,ports:22,address:10.0.0.0/8" \
  --inbound-rules "protocol:tcp,ports:80,address:0.0.0.0/0" \
  --inbound-rules "protocol:tcp,ports:443,address:0.0.0.0/0" \
  --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0" \
  --droplet-ids <droplet-id>
```

## Databases

```bash
# Create PostgreSQL
doctl databases create my-db \
  --engine pg \
  --version 16 \
  --region nyc1 \
  --size db-s-2vcpu-4gb \
  --num-nodes 2

# Get connection
doctl databases connection <cluster-id>

# Create database
doctl databases db create <cluster-id> myapp_production

# Create user
doctl databases user create <cluster-id> app_user
```

## Kubernetes

```bash
# Create cluster
doctl kubernetes cluster create my-cluster \
  --region nyc1 \
  --version latest \
  --node-pool "name=default;size=s-4vcpu-8gb;count=3;auto-scale=true;min-nodes=2;max-nodes=10"

# Get kubeconfig
doctl kubernetes cluster kubeconfig save my-cluster

# List clusters
doctl kubernetes cluster list
```

## Apps (App Platform)

```bash
# Create app
doctl apps create --spec .do/app.yaml

# Update app
doctl apps update <app-id> --spec .do/app.yaml

# List apps
doctl apps list

# Logs
doctl apps logs <app-id> --type run

# Deploy
doctl apps create-deployment <app-id>
```

## Registry

```bash
# Create registry
doctl registry create my-registry

# Login
doctl registry login

# Kubernetes integration
doctl registry kubernetes-manifest | kubectl apply -f -
```

## DNS

```bash
# Add A record
doctl compute domain records create example.com \
  --record-type A \
  --record-name www \
  --record-data <ip-address> \
  --record-ttl 3600
```
