---
name: networking-config
description: DigitalOcean networking patterns - VPCs, firewalls, load balancers, DNS
---

# Networking Configuration Skill

## VPC (Virtual Private Cloud)

### Create VPC

```bash
doctl vpcs create \
  --name production-vpc \
  --region nyc1 \
  --ip-range 10.10.10.0/24 \
  --description "Production network"
```

### VPC Best Practices

```
┌─────────────────────────────────────────────────────────┐
│                    VPC: 10.10.10.0/24                   │
├─────────────────────────────────────────────────────────┤
│  10.10.10.0/26    │ Web Servers (Droplets)              │
│  10.10.10.64/26   │ App Servers (Droplets)              │
│  10.10.10.128/26  │ Databases (Managed)                 │
│  10.10.10.192/26  │ Reserved                            │
└─────────────────────────────────────────────────────────┘
```

### Terraform VPC

```hcl
resource "digitalocean_vpc" "production" {
  name     = "production-vpc"
  region   = "nyc1"
  ip_range = "10.10.10.0/24"
}

# Create resources in VPC
resource "digitalocean_droplet" "web" {
  name     = "web-server"
  vpc_uuid = digitalocean_vpc.production.id
  # ...
}

resource "digitalocean_database_cluster" "postgres" {
  name                 = "app-db"
  private_network_uuid = digitalocean_vpc.production.id
  # ...
}
```

## Cloud Firewalls

### Web Server Firewall

```bash
doctl compute firewall create \
  --name web-firewall \
  --inbound-rules "protocol:tcp,ports:22,address:10.0.0.0/8" \
  --inbound-rules "protocol:tcp,ports:80,address:0.0.0.0/0" \
  --inbound-rules "protocol:tcp,ports:443,address:0.0.0.0/0" \
  --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0" \
  --outbound-rules "protocol:udp,ports:53,address:0.0.0.0/0" \
  --droplet-ids <droplet-id>
```

### Database Firewall (Internal Only)

```bash
doctl compute firewall create \
  --name db-firewall \
  --inbound-rules "protocol:tcp,ports:5432,address:10.10.10.0/24" \
  --outbound-rules "protocol:tcp,ports:all,address:0.0.0.0/0" \
  --droplet-ids <db-droplet-id>
```

### Terraform Firewall

```hcl
resource "digitalocean_firewall" "web" {
  name        = "web-firewall"
  droplet_ids = digitalocean_droplet.web[*].id

  # SSH from VPC only
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [digitalocean_vpc.production.ip_range]
  }

  # HTTP/HTTPS from anywhere
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Allow all outbound
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
```

## Load Balancers

### HTTPS Load Balancer

```bash
# First, create SSL certificate
doctl compute certificate create \
  --name my-cert \
  --type lets_encrypt \
  --dns-names example.com,www.example.com

# Create load balancer
doctl compute load-balancer create \
  --name web-lb \
  --region nyc1 \
  --vpc-uuid <vpc-id> \
  --forwarding-rules "entry_protocol:https,entry_port:443,target_protocol:http,target_port:3000,certificate_id:<cert-id>" \
  --forwarding-rules "entry_protocol:http,entry_port:80,target_protocol:http,target_port:3000" \
  --health-check "protocol:http,port:3000,path:/health,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:3,unhealthy_threshold:3" \
  --redirect-http-to-https \
  --droplet-ids <droplet-1>,<droplet-2>
```

### Terraform Load Balancer

```hcl
resource "digitalocean_certificate" "cert" {
  name    = "app-cert"
  type    = "lets_encrypt"
  domains = ["app.example.com"]
}

resource "digitalocean_loadbalancer" "web" {
  name                   = "web-lb"
  region                 = "nyc1"
  vpc_uuid               = digitalocean_vpc.production.id
  redirect_http_to_https = true

  forwarding_rule {
    entry_port      = 443
    entry_protocol  = "https"
    target_port     = 3000
    target_protocol = "http"
    certificate_name = digitalocean_certificate.cert.name
  }

  forwarding_rule {
    entry_port      = 80
    entry_protocol  = "http"
    target_port     = 3000
    target_protocol = "http"
  }

  healthcheck {
    port                   = 3000
    protocol               = "http"
    path                   = "/health"
    check_interval_seconds = 10
    response_timeout_seconds = 5
    healthy_threshold      = 3
    unhealthy_threshold    = 3
  }

  droplet_ids = digitalocean_droplet.web[*].id
}
```

## DNS Management

### Setup Domain

```bash
# Add domain
doctl compute domain create example.com

# Point to load balancer
doctl compute domain records create example.com \
  --record-type A \
  --record-name @ \
  --record-data <lb-ip> \
  --record-ttl 300

# WWW CNAME
doctl compute domain records create example.com \
  --record-type CNAME \
  --record-name www \
  --record-data example.com. \
  --record-ttl 300

# API subdomain
doctl compute domain records create example.com \
  --record-type A \
  --record-name api \
  --record-data <api-ip> \
  --record-ttl 300

# MX records
doctl compute domain records create example.com \
  --record-type MX \
  --record-name @ \
  --record-data mail.example.com. \
  --record-priority 10
```

### Terraform DNS

```hcl
resource "digitalocean_domain" "main" {
  name = "example.com"
}

resource "digitalocean_record" "root" {
  domain = digitalocean_domain.main.id
  type   = "A"
  name   = "@"
  value  = digitalocean_loadbalancer.web.ip
  ttl    = 300
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.main.id
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = 300
}

resource "digitalocean_record" "api" {
  domain = digitalocean_domain.main.id
  type   = "A"
  name   = "api"
  value  = digitalocean_droplet.api.ipv4_address
  ttl    = 300
}
```

## Floating IPs

Reserve static IPs that can be reassigned between Droplets.

```bash
# Create floating IP
doctl compute floating-ip create --region nyc1

# Assign to Droplet
doctl compute floating-ip-action assign <ip> <droplet-id>

# Unassign
doctl compute floating-ip-action unassign <ip>
```

## Network Architecture Example

```
                    ┌─────────────────────────┐
                    │       Internet          │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │    Cloud Firewall       │
                    │    (80, 443 allowed)    │
                    └───────────┬─────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │    Load Balancer        │
                    │    (HTTPS termination)  │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
    ┌─────────┴─────┐ ┌─────────┴─────┐ ┌─────────┴─────┐
    │   Web-1       │ │   Web-2       │ │   Web-3       │
    │   Droplet     │ │   Droplet     │ │   Droplet     │
    └───────────────┘ └───────────────┘ └───────────────┘
              │                 │                 │
              └─────────────────┼─────────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │     VPC (10.10.10.0/24) │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
    ┌─────────┴─────────┐       │       ┌─────────┴─────────┐
    │   PostgreSQL      │       │       │   Redis           │
    │   (Managed)       │       │       │   (Managed)       │
    └───────────────────┘       │       └───────────────────┘
                                │
                    ┌───────────┴─────────────┐
                    │   Spaces (S3)           │
                    │   File Storage          │
                    └─────────────────────────┘
```
