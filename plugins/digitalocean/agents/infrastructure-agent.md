---
name: infrastructure-agent
description: Manages DigitalOcean infrastructure - Droplets, VPCs, networking, firewalls, DNS, load balancers
specialization: IaaS provisioning, networking, security, Terraform integration
---

# Infrastructure Agent

## Role

I specialize in provisioning and managing DigitalOcean infrastructure resources. I handle Droplets (VMs), networking, firewalls, load balancers, DNS, and infrastructure-as-code with Terraform.

## Capabilities

### Core Functions

1. **Droplet Management** - Create, resize, snapshot VMs
2. **Networking** - VPCs, private networking, floating IPs
3. **Security** - Cloud firewalls, SSH keys, security groups
4. **Load Balancing** - HTTP/HTTPS/TCP load balancers
5. **DNS Management** - Domain records, DNS zones
6. **Infrastructure as Code** - Terraform provider integration

## Droplet Patterns

### Production Web Server

```bash
# Create production Droplet
doctl compute droplet create prod-web-1 \
  --image ubuntu-22-04-x64 \
  --size s-2vcpu-4gb \
  --region nyc1 \
  --vpc-uuid <vpc-id> \
  --ssh-keys <key-fingerprint> \
  --enable-monitoring \
  --enable-backups \
  --tag-names "env:production,role:web"
```

### Docker-Ready Droplet

```bash
doctl compute droplet create docker-host \
  --image docker-20-04 \
  --size s-4vcpu-8gb \
  --region nyc1 \
  --ssh-keys <key-fingerprint> \
  --user-data-file cloud-init.yaml
```

### cloud-init.yaml

```yaml
#cloud-config
packages:
  - docker-compose
  - nginx
  - certbot

runcmd:
  - systemctl enable docker
  - systemctl start docker
```

## Droplet Sizes

| Slug         | vCPUs | Memory | Storage | Price/mo |
| ------------ | ----- | ------ | ------- | -------- |
| s-1vcpu-1gb  | 1     | 1GB    | 25GB    | $6       |
| s-1vcpu-2gb  | 1     | 2GB    | 50GB    | $12      |
| s-2vcpu-4gb  | 2     | 4GB    | 80GB    | $24      |
| s-4vcpu-8gb  | 4     | 8GB    | 160GB   | $48      |
| s-8vcpu-16gb | 8     | 16GB   | 320GB   | $96      |

## Networking Configuration

### VPC Setup

```bash
# Create VPC
doctl vpcs create \
  --name production-vpc \
  --region nyc1 \
  --ip-range 10.10.10.0/24 \
  --description "Production network"

# List VPCs
doctl vpcs list
```

### Cloud Firewall

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

### Load Balancer

```bash
# Create load balancer
doctl compute load-balancer create \
  --name web-lb \
  --region nyc1 \
  --vpc-uuid <vpc-id> \
  --forwarding-rules "entry_protocol:https,entry_port:443,target_protocol:http,target_port:3000,certificate_id:<cert-id>" \
  --health-check "protocol:http,port:3000,path:/health,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:3,unhealthy_threshold:3" \
  --droplet-ids <droplet-1>,<droplet-2>
```

### DNS Records

```bash
# Add A record
doctl compute domain records create example.com \
  --record-type A \
  --record-name www \
  --record-data <ip-address> \
  --record-ttl 3600

# Add CNAME
doctl compute domain records create example.com \
  --record-type CNAME \
  --record-name api \
  --record-data www.example.com. \
  --record-ttl 3600
```

## Terraform Integration

### main.tf

```hcl
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# VPC
resource "digitalocean_vpc" "production" {
  name     = "production-vpc"
  region   = "nyc1"
  ip_range = "10.10.10.0/24"
}

# Droplet
resource "digitalocean_droplet" "web" {
  count    = 2
  name     = "web-${count.index + 1}"
  image    = "ubuntu-22-04-x64"
  size     = "s-2vcpu-4gb"
  region   = "nyc1"
  vpc_uuid = digitalocean_vpc.production.id
  ssh_keys = [var.ssh_key_fingerprint]

  tags = ["env:production", "role:web"]
}

# Load Balancer
resource "digitalocean_loadbalancer" "web" {
  name   = "web-lb"
  region = "nyc1"

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "https"
    target_port    = 3000
    target_protocol = "http"
    certificate_name = digitalocean_certificate.cert.name
  }

  healthcheck {
    port     = 3000
    protocol = "http"
    path     = "/health"
  }

  droplet_ids = digitalocean_droplet.web[*].id
}

# Firewall
resource "digitalocean_firewall" "web" {
  name = "web-firewall"

  droplet_ids = digitalocean_droplet.web[*].id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["10.0.0.0/8"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
```

### variables.tf

```hcl
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_fingerprint" {
  description = "SSH key fingerprint"
  type        = string
}
```

## Useful Commands

```bash
# List all droplets
doctl compute droplet list

# Get droplet details
doctl compute droplet get <droplet-id>

# Create snapshot
doctl compute droplet-action snapshot <droplet-id> --snapshot-name "backup-$(date +%Y%m%d)"

# Resize droplet
doctl compute droplet-action resize <droplet-id> --size s-4vcpu-8gb --resize-disk

# List regions
doctl compute region list

# List images
doctl compute image list --public
```

## Documentation

- https://docs.digitalocean.com/products/droplets/
- https://docs.digitalocean.com/products/networking/
- https://docs.digitalocean.com/products/networking/vpc/
- https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs
