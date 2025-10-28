# Ayrshare MCP Server - Deployment Guide

Complete guide for deploying the Ayrshare MCP server to various platforms.

## 📋 Table of Contents

1. [Docker Deployment](#docker-deployment)
2. [Railway Deployment](#railway-deployment)
3. [Render Deployment](#render-deployment)
4. [Fly.io Deployment](#flyio-deployment)
5. [FastMCP Cloud](#fastmcp-cloud)
6. [Environment Variables](#environment-variables)
7. [Health Checks](#health-checks)
8. [Monitoring & Logs](#monitoring--logs)

---

## 🐳 Docker Deployment

### Prerequisites
- Docker installed: https://docs.docker.com/get-docker/
- Docker Compose (optional): https://docs.docker.com/compose/install/

### Quick Start

**1. Build the image:**
```bash
docker build -t ayrshare-mcp:latest .
```

**2. Run the container:**
```bash
docker run -d \
  --name ayrshare-mcp \
  -p 8000:8000 \
  -e AYRSHARE_API_KEY=your_key_here \
  ayrshare-mcp:latest
```

**3. Using Docker Compose:**
```bash
# Create .env file with your API key
cp .env.example .env
# Edit .env and add your AYRSHARE_API_KEY

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Docker Commands

```bash
# View logs
docker logs -f ayrshare-mcp

# Check health
docker inspect --format='{{.State.Health.Status}}' ayrshare-mcp

# Execute commands inside container
docker exec -it ayrshare-mcp python -c "import src.server as s; print('OK')"

# Restart container
docker restart ayrshare-mcp

# Remove container
docker rm -f ayrshare-mcp
```

### Production Docker Setup

```bash
# Use specific tag for production
docker build -t ayrshare-mcp:1.0.0 .

# Run with restart policy
docker run -d \
  --name ayrshare-mcp \
  --restart unless-stopped \
  -p 8000:8000 \
  -e AYRSHARE_API_KEY=${AYRSHARE_API_KEY} \
  --health-cmd="python -c 'import httpx; httpx.get(\"http://localhost:8000/health\")'" \
  --health-interval=30s \
  --health-timeout=3s \
  --health-retries=3 \
  ayrshare-mcp:1.0.0
```

---

## 🚂 Railway Deployment

Railway provides simple, Git-based deployments with automatic scaling.

### Deployment Steps

**1. Install Railway CLI (optional):**
```bash
npm install -g @railway/cli
railway login
```

**2. Deploy via Web Dashboard:**
- Visit https://railway.app
- Click "New Project" → "Deploy from GitHub"
- Select your repository
- Railway auto-detects `railway.json` configuration
- Set environment variables:
  - `AYRSHARE_API_KEY`: Your API key
  - `AYRSHARE_PROFILE_KEY`: Optional profile key

**3. Deploy via CLI:**
```bash
# Initialize Railway project
railway init

# Set secrets
railway variables set AYRSHARE_API_KEY=your_key_here

# Deploy
railway up
```

**4. Access your server:**
```
https://ayrshare-mcp-production.up.railway.app/mcp
```

### Railway Configuration

The `railway.json` file includes:
- Dockerfile-based build
- Auto-restart on failure
- Health check at `/health`
- Environment variable definitions

### Railway Commands

```bash
# View logs
railway logs

# Check status
railway status

# Open in browser
railway open

# Link local project
railway link

# Run commands in Railway environment
railway run python src/server.py --http
```

---

## 🎨 Render Deployment

Render offers free tier with automatic deployments from Git.

### Deployment Steps

**1. Via Web Dashboard:**
- Visit https://render.com
- Click "New +" → "Blueprint"
- Connect your GitHub/GitLab repository
- Render detects `render.yaml` configuration
- Set environment variables:
  - `AYRSHARE_API_KEY`: Your API key (keep secret!)
  - `AYRSHARE_PROFILE_KEY`: Optional

**2. Manual Service Creation:**
- Click "New +" → "Web Service"
- Connect repository
- Settings:
  - **Name**: ayrshare-mcp
  - **Region**: Oregon (or closest to you)
  - **Branch**: main
  - **Runtime**: Python 3
  - **Build Command**: `pip install -r requirements.txt`
  - **Start Command**: `python src/server.py --http`
  - **Plan**: Free or Starter

**3. Deploy:**
- Click "Create Web Service"
- Render automatically builds and deploys
- Your server will be at: `https://ayrshare-mcp.onrender.com`

### Render Features

- **Auto-deploy** on Git push
- **Free HTTPS** with custom domains
- **Auto-scaling** on paid plans
- **Health checks** automatic
- **Zero-downtime** deployments

### Render Tips

```bash
# Free tier limitations:
# - Spins down after 15 minutes of inactivity
# - ~30 second cold start time
# - 750 hours/month free

# For production:
# - Use Starter plan ($7/month) for always-on
# - Enable auto-scaling
# - Add custom domain
```

---

## 🪂 Fly.io Deployment

Fly.io provides global edge deployment with Docker containers.

### Deployment Steps

**1. Install Fly.io CLI:**
```bash
# Mac
brew install flyctl

# Linux
curl -L https://fly.io/install.sh | sh

# Windows
iwr https://fly.io/install.ps1 -useb | iex
```

**2. Login:**
```bash
flyctl auth login
```

**3. Launch app:**
```bash
# Initialize (uses fly.toml)
flyctl launch --config fly.toml

# Set secrets
flyctl secrets set AYRSHARE_API_KEY=your_key_here
flyctl secrets set AYRSHARE_PROFILE_KEY=your_profile_key  # Optional
```

**4. Deploy:**
```bash
flyctl deploy
```

**5. Access your server:**
```
https://ayrshare-mcp.fly.dev/mcp
```

### Fly.io Commands

```bash
# View logs
flyctl logs

# Check status
flyctl status

# Scale instances
flyctl scale count 2

# SSH into container
flyctl ssh console

# Check regions
flyctl regions list

# Add more regions
flyctl regions add lax ord

# Monitor app
flyctl monitor

# Update secrets
flyctl secrets list
flyctl secrets set KEY=value
flyctl secrets unset KEY
```

### Fly.io Features

- **Global deployment**: Deploy to multiple regions
- **Auto-scaling**: Scale to zero when idle
- **Built-in CDN**: Fast worldwide access
- **Free allowance**: 3 shared-cpu-1x VMs with 256MB RAM

---

## ☁️ FastMCP Cloud

FastMCP Cloud provides serverless hosting for MCP servers.

### Deployment Steps

**1. Push to GitHub:**
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/ayrshare-mcp.git
git push -u origin main
```

**2. Deploy to FastMCP Cloud:**
- Visit https://fastmcp.cloud
- Sign in with GitHub
- Click "New Project"
- Select repository: `yourusername/ayrshare-mcp`
- Configure:
  - **Entry point**: `src/server.py:mcp`
  - **Python version**: 3.12
  - Add environment variable: `AYRSHARE_API_KEY`

**3. Access server:**
```
https://your-project.fastmcp.app/mcp
```

### FastMCP Cloud Features

- **Free for personal servers**
- **Automatic HTTPS**
- **Built-in authentication** support
- **Instant deployment** from Git

---

## 🔐 Environment Variables

### Required Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `AYRSHARE_API_KEY` | Your Ayrshare API key | ✅ Yes | `2MPXPKQ-S03M5LS-GR5RX5G-AZCK8EA` |

### Optional Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `AYRSHARE_PROFILE_KEY` | Profile key for multi-user | ❌ No | `AX1XGG-9jK3M5LS-GR5RX5G-LLCK8EA` |
| `PORT` | HTTP server port | ❌ No | `8000` (default) |
| `PYTHONUNBUFFERED` | Enable unbuffered output | ❌ No | `1` (default) |

### Getting API Keys

1. **Ayrshare API Key**:
   - Sign up at https://www.ayrshare.com
   - Navigate to https://app.ayrshare.com/api-key
   - Copy your API key

2. **Profile Key** (Business/Enterprise only):
   - Go to https://app.ayrshare.com/profiles
   - Create or select a profile
   - Copy the profile key

### Setting Variables by Platform

**Docker:**
```bash
docker run -e AYRSHARE_API_KEY=your_key ...
```

**Railway:**
```bash
railway variables set AYRSHARE_API_KEY=your_key
```

**Render:**
- Dashboard → Environment → Add Environment Variable

**Fly.io:**
```bash
flyctl secrets set AYRSHARE_API_KEY=your_key
```

**FastMCP Cloud:**
- Project Settings → Environment Variables → Add

---

## ❤️ Health Checks

All deployment configurations include health checks at `/health` endpoint.

### Health Check Endpoint

**URL**: `http://your-server:8000/health`

**Response (healthy):**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-27T10:30:00Z",
  "server": "Ayrshare Social Media API",
  "version": "1.0.0"
}
```

### Testing Health Check

```bash
# Local
curl http://localhost:8000/health

# Production
curl https://your-server.com/health

# With timeout
curl --max-time 3 https://your-server.com/health
```

### Health Check Configuration

| Platform | Interval | Timeout | Retries |
|----------|----------|---------|---------|
| Docker | 30s | 3s | 3 |
| Railway | 30s | 30s | 3 |
| Render | 60s | 5s | 3 |
| Fly.io | 30s | 5s | 3 |

---

## 📊 Monitoring & Logs

### Viewing Logs

**Docker:**
```bash
docker logs -f ayrshare-mcp
docker-compose logs -f
```

**Railway:**
```bash
railway logs
railway logs --tail 100
```

**Render:**
- Dashboard → Logs tab
- Or use Render CLI: `render logs -f`

**Fly.io:**
```bash
flyctl logs
flyctl logs --tail
```

### Log Levels

The server logs all requests and errors:
- **INFO**: Normal operations
- **WARNING**: Non-critical issues
- **ERROR**: API errors and exceptions

### Monitoring Metrics

Monitor these key metrics:
- **Response time**: < 2 seconds typical
- **Error rate**: Should be < 1%
- **Uptime**: 99.9% target
- **Memory usage**: ~100-200MB typical
- **CPU usage**: < 50% typical

### Setting Up Alerts

**Railway:**
- Deployment notifications built-in
- Integrate with Discord/Slack

**Render:**
- Email notifications for deploy failures
- Status page available

**Fly.io:**
```bash
# Set up metrics dashboard
flyctl dashboard

# Configure alerts in dashboard
```

---

## 🚀 Production Checklist

Before deploying to production:

- [ ] **Security**
  - [ ] API key stored as environment variable (never in code)
  - [ ] `.env` file in `.gitignore`
  - [ ] HTTPS enabled (automatic on cloud platforms)
  - [ ] Health check endpoint working

- [ ] **Configuration**
  - [ ] Correct region selected (closest to users)
  - [ ] Auto-restart enabled
  - [ ] Resource limits set appropriately
  - [ ] Environment variables configured

- [ ] **Testing**
  - [ ] All 19 tools tested
  - [ ] Health check returning 200
  - [ ] Can connect from Claude Desktop
  - [ ] API key authentication working

- [ ] **Monitoring**
  - [ ] Logging enabled
  - [ ] Health checks configured
  - [ ] Alerts set up for failures
  - [ ] Performance metrics tracked

- [ ] **Documentation**
  - [ ] Server URL documented
  - [ ] API key setup instructions
  - [ ] Team access configured
  - [ ] Rollback procedure documented

---

## 🆘 Troubleshooting

### Common Issues

**Issue**: Container fails to start
```bash
# Check logs
docker logs ayrshare-mcp

# Common cause: Missing API key
# Solution: Set AYRSHARE_API_KEY environment variable
```

**Issue**: Health check failing
```bash
# Test manually
curl http://localhost:8000/health

# Check if port is correct
docker ps  # Verify port mapping

# Check logs for errors
docker logs ayrshare-mcp
```

**Issue**: Ayrshare API errors
```bash
# Verify API key is correct
# Test key with curl:
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.ayrshare.com/api

# Check if account has active subscription
# Visit: https://app.ayrshare.com/billing
```

**Issue**: Out of memory
```bash
# Increase Docker memory
docker run -m 512m ...

# Or in docker-compose.yml:
services:
  ayrshare-mcp:
    mem_limit: 512m
```

---

## 📞 Support

- **Ayrshare API**: https://www.ayrshare.com/docs
- **FastMCP Docs**: https://gofastmcp.com
- **Docker Help**: https://docs.docker.com
- **Railway Support**: https://railway.app/help
- **Render Support**: https://render.com/docs
- **Fly.io Docs**: https://fly.io/docs

---

**Last Updated**: 2025-01-27
**Version**: 1.0.0
