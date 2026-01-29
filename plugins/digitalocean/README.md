# DigitalOcean Plugin

Complete DigitalOcean cloud deployment plugin for building and managing cloud infrastructure. Deploy apps, manage Droplets, Kubernetes clusters, serverless functions, databases, and storage.

## Features

- **App Platform** - PaaS deployment from Git or container images
- **Droplets** - Virtual machine provisioning and management
- **Kubernetes** - Managed K8s cluster deployment
- **Functions** - Serverless function deployment
- **Managed Databases** - PostgreSQL, MySQL, Redis, MongoDB, Kafka
- **Spaces** - S3-compatible object storage
- **MCP Integration** - Official DigitalOcean MCP server support

## Commands

| Command               | Description                                            |
| --------------------- | ------------------------------------------------------ |
| `/digitalocean:build` | Deploy complete infrastructure on DigitalOcean         |
| `/digitalocean:add`   | Add specific DigitalOcean services to existing project |

## Agents

| Agent                  | Role                                  | Model  |
| ---------------------- | ------------------------------------- | ------ |
| `app-platform-agent`   | App Platform deployment orchestration | sonnet |
| `infrastructure-agent` | Droplets, VPC, networking setup       | sonnet |
| `kubernetes-agent`     | Managed K8s cluster deployment        | sonnet |
| `database-agent`       | Managed database provisioning         | haiku  |

## Quick Start

```bash
# Deploy full-stack app to App Platform
/digitalocean:build

# Add managed database to existing project
/digitalocean:add database postgresql

# Add Spaces storage
/digitalocean:add spaces
```

## Documentation Links

- [DigitalOcean Docs](https://docs.digitalocean.com/)
- [App Platform](https://docs.digitalocean.com/products/app-platform/)
- [API Reference](https://docs.digitalocean.com/reference/api/)
- [doctl CLI](https://docs.digitalocean.com/reference/doctl/)
- [MCP Server](https://docs.digitalocean.com/reference/mcp/)
- [Terraform Provider](https://docs.digitalocean.com/reference/terraform/)

## Environment Variables

```bash
# Required
DIGITALOCEAN_TOKEN=your_digitalocean_api_token_here

# Optional
DIGITALOCEAN_SPACES_ACCESS_KEY=your_spaces_access_key_here
DIGITALOCEAN_SPACES_SECRET_KEY=your_spaces_secret_key_here
```

## MCP Server Integration

DigitalOcean provides official MCP servers for AI tool integration:

```json
{
  "mcpServers": {
    "digitalocean": {
      "url": "https://mcp.digitalocean.com/sse",
      "headers": {
        "Authorization": "Bearer ${DIGITALOCEAN_TOKEN}"
      }
    }
  }
}
```
