# Railway Deployment Guide for FastAPI

Complete walkthrough for deploying FastAPI applications on Railway with automatic HTTPS, database provisioning, and CI/CD.

## Overview

Railway provides:
- Git-based deployment (automatic deploys on push)
- Automatic HTTPS with custom domains
- Managed PostgreSQL database add-on
- Environment variable management
- Build and deploy logs
- Free tier available ($5 credit/month)

## Prerequisites

- [ ] Railway account (sign up at [railway.app](https://railway.app))
- [ ] GitHub repository with your FastAPI application
- [ ] Dockerfile in repository root
- [ ] `railway.json` configuration file (optional but recommended)

## Step-by-Step Deployment

### 1. Prepare Your Application

**Required files in repository:**

```bash
your-repo/
├── main.py              # FastAPI application
├── requirements.txt     # Python dependencies
├── Dockerfile          # Container configuration
├── railway.json        # Railway configuration (optional)
└── .env.example        # Environment variable template
```

**Verify Dockerfile:**

```dockerfile
# Should expose port dynamically
ENV PORT=8000
EXPOSE $PORT

# Start command should use $PORT
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "$PORT"]
```

**Add health check endpoint** (main.py):

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```

### 2. Create railway.json

Create `railway.json` in repository root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "uvicorn main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 100,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 3. Deploy to Railway

#### Option A: Deploy via Railway Dashboard

1. **Login to Railway**
   - Go to [railway.app](https://railway.app)
   - Click "Login with GitHub"

2. **Create New Project**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository

3. **Configure Build**
   - Railway auto-detects Dockerfile
   - Confirm build settings

4. **Set Environment Variables**
   - Click on your service
   - Navigate to "Variables" tab
   - Add required variables:
     ```
     ENVIRONMENT=production
     SECRET_KEY=<generate-secure-key>
     LOG_LEVEL=INFO
     ```

5. **Deploy**
   - Click "Deploy"
   - Wait for build to complete
   - Railway provides a public URL: `https://your-app.up.railway.app`

#### Option B: Deploy via Railway CLI

1. **Install Railway CLI:**

   ```bash
   # macOS
   brew install railway

   # Linux/WSL
   curl -fsSL https://railway.app/install.sh | sh

   # Windows
   # Download from: https://railway.app/cli
   ```

2. **Login:**

   ```bash
   railway login
   ```

3. **Initialize project:**

   ```bash
   cd your-fastapi-app
   railway init
   ```

4. **Link to GitHub repository:**

   ```bash
   railway link
   ```

5. **Set environment variables:**

   ```bash
   railway variables set ENVIRONMENT=production
   railway variables set SECRET_KEY=your-secure-secret-key
   railway variables set LOG_LEVEL=INFO
   ```

6. **Deploy:**

   ```bash
   railway up
   ```

### 4. Add PostgreSQL Database

1. **Via Dashboard:**
   - In your Railway project
   - Click "New Service"
   - Select "Database" → "PostgreSQL"
   - Railway automatically sets `DATABASE_URL` environment variable

2. **Via CLI:**

   ```bash
   railway add --database postgres
   ```

3. **Verify DATABASE_URL:**

   ```bash
   railway variables
   # Should show: DATABASE_URL=postgresql://...
   ```

4. **Update your FastAPI app** to use `DATABASE_URL`:

   ```python
   import os
   from sqlalchemy import create_engine

   DATABASE_URL = os.getenv("DATABASE_URL")
   engine = create_engine(DATABASE_URL)
   ```

### 5. Configure Custom Domain

1. **In Railway Dashboard:**
   - Click on your service
   - Navigate to "Settings" tab
   - Scroll to "Domains"
   - Click "Generate Domain" (Railway subdomain)
   - Or click "Custom Domain" to add your own

2. **Add Custom Domain:**
   - Enter your domain: `api.yourdomain.com`
   - Add CNAME record to your DNS:
     ```
     CNAME api yourapprailway.up.railway.app
     ```
   - Railway automatically provisions SSL certificate

3. **Update CORS origins** in environment variables:

   ```bash
   railway variables set CORS_ORIGINS=https://yourdomain.com,https://api.yourdomain.com
   ```

### 6. Set Up Automatic Deployments

Railway automatically deploys when you push to your connected branch:

1. **Configure deployment branch:**
   - In Railway Dashboard → Settings
   - "Source" section
   - Set "Branch" to `main` or `production`

2. **Deployment workflow:**

   ```bash
   # Make changes locally
   git add .
   git commit -m "feat: Add new endpoint"
   git push origin main

   # Railway automatically:
   # 1. Detects the push
   # 2. Builds Docker image
   # 3. Runs tests (if configured)
   # 4. Deploys to production
   # 5. Health checks new deployment
   ```

3. **Deployment notifications:**
   - Railway sends deployment status to GitHub
   - View logs in Railway Dashboard

### 7. Monitoring and Logs

**View logs:**

```bash
# Via CLI
railway logs

# Follow logs in real-time
railway logs --follow
```

**Via Dashboard:**
- Click on your service
- Navigate to "Deployments" tab
- Click on latest deployment
- View build and runtime logs

**Metrics:**
- Railway Dashboard shows:
  - Memory usage
  - CPU usage
  - Network traffic
  - Response times

### 8. Environment Variable Management

**View all variables:**

```bash
railway variables
```

**Set variable:**

```bash
railway variables set KEY=value
```

**Delete variable:**

```bash
railway variables delete KEY
```

**Load from .env file:**

```bash
railway variables set --from-env-file .env.production
```

### 9. Database Migrations

If using Alembic for database migrations:

1. **Run migrations as one-off command:**

   ```bash
   railway run alembic upgrade head
   ```

2. **Or add to Dockerfile:**

   ```dockerfile
   # Run migrations before starting server
   CMD alembic upgrade head && uvicorn main:app --host 0.0.0.0 --port $PORT
   ```

3. **Or create a separate migration service:**

   Create `migrate.sh`:
   ```bash
   #!/bin/bash
   alembic upgrade head
   ```

   Add to `railway.json`:
   ```json
   {
     "deploy": {
       "startCommand": "bash migrate.sh && uvicorn main:app --host 0.0.0.0 --port $PORT"
     }
   }
   ```

### 10. Troubleshooting

#### Build Fails

**Check build logs:**
```bash
railway logs --deployment
```

**Common issues:**
- Missing dependencies in requirements.txt
- Incorrect Python version in Dockerfile
- Build timeout (increase in Settings)

#### Application Won't Start

**Check runtime logs:**
```bash
railway logs
```

**Common issues:**
- Port not set to `$PORT`
- Missing environment variables
- Database connection errors

#### Database Connection Errors

**Verify DATABASE_URL:**
```bash
railway variables | grep DATABASE_URL
```

**Test connection:**
```python
# test_db.py
import os
from sqlalchemy import create_engine

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
conn = engine.connect()
print("Connected successfully!")
```

```bash
railway run python test_db.py
```

#### Health Check Failures

**Verify health endpoint:**
```bash
curl https://your-app.up.railway.app/health
```

**Check railway.json:**
```json
{
  "deploy": {
    "healthcheckPath": "/health",
    "healthcheckTimeout": 100
  }
}
```

## Cost Optimization

### Free Tier
- $5 credit per month
- Resets monthly
- Typically enough for small apps

### Pricing
- $0.000231 per GB-second for memory
- $0.000463 per vCPU-second
- PostgreSQL: $5/month minimum

### Tips to Reduce Costs
1. **Optimize Docker image size:**
   - Use multi-stage builds
   - Remove unnecessary dependencies
   - Use slim base images

2. **Reduce memory usage:**
   - Limit Gunicorn workers
   - Optimize database queries
   - Use connection pooling

3. **Use sleep mode:**
   - Railway can sleep inactive services
   - Enable in Settings → "Sleep inactive services"

## Best Practices

### 1. Use railway.json
Always include `railway.json` for consistent deployments

### 2. Environment-Specific Configs
```bash
# Development
railway link --environment development

# Production
railway link --environment production
```

### 3. Database Backups
Railway automatically backs up PostgreSQL:
- Point-in-time recovery (PITR)
- Access via Railway Dashboard

### 4. Secrets Management
Use Railway variables for sensitive data:
```bash
railway variables set SECRET_KEY=$(openssl rand -hex 32)
```

### 5. Health Checks
Always implement `/health` endpoint for reliability

### 6. Monitoring
Set up external monitoring (UptimeRobot, Pingdom):
```
https://your-app.up.railway.app/health
```

## Example: Complete Setup Script

```bash
#!/bin/bash

# Railway FastAPI Deployment Script

set -e

echo "🚂 Railway FastAPI Deployment"

# 1. Install Railway CLI (if not installed)
if ! command -v railway &> /dev/null; then
    echo "Installing Railway CLI..."
    curl -fsSL https://railway.app/install.sh | sh
fi

# 2. Login
echo "Logging in to Railway..."
railway login

# 3. Initialize project
echo "Initializing Railway project..."
railway init

# 4. Set environment variables
echo "Setting environment variables..."
railway variables set ENVIRONMENT=production
railway variables set SECRET_KEY=$(openssl rand -hex 32)
railway variables set LOG_LEVEL=INFO

# 5. Add PostgreSQL
echo "Adding PostgreSQL database..."
railway add --database postgres

# 6. Deploy
echo "Deploying application..."
railway up

# 7. Get deployment URL
echo "Getting deployment URL..."
railway status

echo "✅ Deployment complete!"
echo "View logs: railway logs"
echo "Open dashboard: railway open"
```

## Resources

- [Railway Documentation](https://docs.railway.app/)
- [Railway CLI Reference](https://docs.railway.app/develop/cli)
- [Railway Pricing](https://railway.app/pricing)
- [Railway Discord Community](https://discord.gg/railway)
- [Railway Status](https://status.railway.app/)

## Next Steps

After successful deployment:

1. ✅ Test all API endpoints
2. ✅ Monitor logs for errors
3. ✅ Set up custom domain
4. ✅ Configure external monitoring
5. ✅ Implement CI/CD workflows
6. ✅ Set up database backups
7. ✅ Review and optimize costs

---

**Deployment Time:** ~5-10 minutes
**Difficulty:** Easy
**Best For:** Small to medium applications, prototypes, MVPs
