# Doppler Secret Management for AI Tech Stack 1

## Overview

Doppler is the centralized secret management solution for all AI Tech Stack 1 projects. It replaces hardcoded secrets in `.bashrc` and `.env` files with a secure, scalable, and team-friendly approach.

**Why Doppler?**
- ✅ Centralized secret management (one place for all keys)
- ✅ Automatic key rotation support
- ✅ Environment-specific configs (dev, staging, production)
- ✅ Team collaboration without sharing keys
- ✅ No more `.env` files in git
- ✅ CLI integration for local development
- ✅ Free for personal use (unlimited secrets, 5 projects)

## Installation

```bash
# Install Doppler CLI (Ubuntu/WSL)
curl -Ls https://cli.doppler.com/install.sh | sudo sh

# Verify installation
doppler --version
```

## Authentication

```bash
# Login to Doppler (opens browser for auth)
doppler login -y

# Verify authentication
doppler me
```

## Project Structure

**Project:** `ai-tech-stack-1`
**Description:** Global secrets for all AI Tech Stack 1 projects

**Environments:**
- `dev` - Local development (default)
- `dev_personal` - Personal development branches
- `stg` - Staging/preview deployments
- `prd` - Production deployments

## Current Secrets (Dev Environment)

| Secret Name | Purpose | Source |
|------------|---------|--------|
| `STRIPE_SECRET_KEY` | Stripe API (backend) | Stripe Dashboard |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Stripe API (frontend) | Stripe Dashboard |
| `DIGITALOCEAN_ACCESS_TOKEN` | DigitalOcean deployments | DigitalOcean Console |
| `VERCEL_TOKEN` | Vercel deployments | Vercel Dashboard |
| `CONTEXT7_API_KEY` | Context7 MCP Server | Context7 Dashboard |
| `FASTMCP_CLOUD_API_KEY` | FastMCP Cloud | FastMCP Dashboard |
| `FIGMA_DESIGN_SYSTEM_PROJECT_REF` | Figma design system | Figma Project |

**Note:** Doppler automatically injects `DOPPLER_CONFIG`, `DOPPLER_ENVIRONMENT`, and `DOPPLER_PROJECT` into your environment.

## Usage Workflows

### 1. Local Development (Next.js / React)

```bash
# Navigate to your project
cd ~/Projects/my-saas-app

# Run development server with Doppler secrets
doppler run --project ai-tech-stack-1 --config dev -- npm run dev

# Or build
doppler run --project ai-tech-stack-1 --config dev -- npm run build
```

### 2. Local Development (FastAPI / Python)

```bash
# Navigate to backend
cd ~/Projects/my-saas-app/backend

# Activate venv and run with Doppler
source venv/bin/activate
doppler run --project ai-tech-stack-1 --config dev -- uvicorn main:app --reload
```

### 3. Setup Doppler in Project (One-Time Setup)

```bash
# Navigate to project root
cd ~/Projects/my-saas-app

# Link this directory to Doppler project
doppler setup --project ai-tech-stack-1 --config dev

# Now you can run without --project and --config flags
doppler run -- npm run dev
```

### 4. Export Secrets to .env (For Local Tools)

```bash
# Export to .env file (DO NOT COMMIT THIS FILE)
doppler secrets download --project ai-tech-stack-1 --config dev --no-file --format env > .env

# View secrets without saving
doppler secrets --project ai-tech-stack-1 --config dev
```

### 5. Add New Secrets

```bash
# Add single secret
doppler secrets set ANTHROPIC_API_KEY="sk-ant-..." --project ai-tech-stack-1 --config dev

# Add multiple secrets from file
cat > secrets.txt << EOF
OPENAI_API_KEY="sk-..."
SUPABASE_URL="https://..."
SUPABASE_ANON_KEY="eyJ..."
EOF

doppler secrets upload secrets.txt --project ai-tech-stack-1 --config dev
trash-put secrets.txt  # Clean up
```

### 6. Copy Secrets to Other Environments

```bash
# Copy dev secrets to staging
doppler secrets download --project ai-tech-stack-1 --config dev --no-file --format json | \
  doppler secrets upload --project ai-tech-stack-1 --config stg

# Copy specific secret to production
doppler secrets get STRIPE_SECRET_KEY --project ai-tech-stack-1 --config dev --plain | \
  doppler secrets set STRIPE_SECRET_KEY --project ai-tech-stack-1 --config prd
```

## Integration with AI Tech Stack 1 Commands

### Recommended: Setup in Project Directory

```bash
# Step 1: Navigate to your project
cd ~/Projects/my-ai-app

# Step 2: Link to Doppler
doppler setup --project ai-tech-stack-1 --config dev

# Step 3: Run any command with secrets
doppler run -- npm run dev
doppler run -- vercel deploy
doppler run -- doctl apps create
```

### For New Projects

When running `/ai-tech-stack-1:build-full-stack`, Doppler secrets are automatically available:

```bash
# Phase 0: Foundation
/ai-tech-stack-1:build-full-stack-phase-0 "My App"

# Doppler secrets are used by:
# - Supabase initialization (SUPABASE_URL, SUPABASE_ANON_KEY)
# - Vercel deployment (VERCEL_TOKEN)
# - DigitalOcean deployment (DIGITALOCEAN_ACCESS_TOKEN)
# - Stripe setup (STRIPE_SECRET_KEY)
```

## Best Practices

### 1. **Never Commit .env Files**

```bash
# Add to .gitignore
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
echo ".env.*.local" >> .gitignore
```

### 2. **Use Environment-Specific Configs**

- `dev` - For local development and testing
- `stg` - For preview/staging deployments
- `prd` - For production (use different API keys!)

### 3. **Rotate Keys Regularly**

```bash
# Update a key in all environments
doppler secrets set STRIPE_SECRET_KEY="new_key" --config dev
doppler secrets set STRIPE_SECRET_KEY="new_key" --config stg
doppler secrets set STRIPE_SECRET_KEY="new_key" --config prd
```

### 4. **Use Service Tokens for CI/CD**

```bash
# Create service token for GitHub Actions
doppler configs tokens create github-actions --project ai-tech-stack-1 --config dev

# Add to GitHub Secrets: DOPPLER_TOKEN
# Use in workflow:
- run: doppler secrets download --token ${{ secrets.DOPPLER_TOKEN }}
```

## Aliases for Convenience

Add to your `~/.bashrc`:

```bash
# Doppler shortcuts
alias drun='doppler run --project ai-tech-stack-1 --config dev --'
alias dlist='doppler secrets --project ai-tech-stack-1 --config dev'
alias dadd='doppler secrets set --project ai-tech-stack-1 --config dev'

# Usage:
# drun npm run dev
# dlist
# dadd NEW_KEY="value"
```

## Troubleshooting

### "Not authenticated"
```bash
doppler login -y
```

### "Project not found"
```bash
# List all projects
doppler projects

# Create if missing
doppler projects create ai-tech-stack-1
```

### "Config not found"
```bash
# List configs
doppler configs --project ai-tech-stack-1

# Create custom config
doppler configs create my-config --project ai-tech-stack-1
```

### View secret values
```bash
# Show secret in plain text
doppler secrets get STRIPE_SECRET_KEY --project ai-tech-stack-1 --config dev --plain
```

## Migration from .bashrc

Your existing secrets in `~/.bashrc` have been migrated to Doppler. You can now:

**Option 1: Keep Both (Recommended for transition)**
- Keep secrets in `.bashrc` as fallback
- Use Doppler for new projects
- Gradually migrate old projects

**Option 2: Fully Migrate (Clean approach)**
- Remove secrets from `.bashrc`
- Always use `doppler run` for commands
- Add Doppler aliases for convenience

## Dashboard Access

View and manage secrets in the web UI:
https://dashboard.doppler.com/workplace/projects/ai-tech-stack-1

**Features:**
- Visual secret editor
- Audit logs (who changed what, when)
- Team member access control
- Secret references (link secrets together)
- Webhooks (notify on secret changes)

## Cost & Limits

**Free Tier (Current):**
- Unlimited secrets
- 5 projects
- 5 team members
- Unlimited config environments
- CLI + Dashboard access

**Paid Tier ($0/month for personal, $12/user for teams):**
- Unlimited projects
- Unlimited team members
- Role-based access control
- Advanced audit logging
- Priority support

## Next Steps

1. ✅ Doppler installed and authenticated
2. ✅ `ai-tech-stack-1` project created
3. ✅ Essential secrets migrated
4. ⏳ Add remaining secrets (Anthropic, OpenAI, Supabase, etc.)
5. ⏳ Setup Doppler in existing projects
6. ⏳ Add Doppler to deployment workflows
7. ⏳ Share access with team members (if applicable)

## Resources

- **Doppler Docs:** https://docs.doppler.com
- **CLI Reference:** https://docs.doppler.com/docs/cli
- **Best Practices:** https://docs.doppler.com/docs/best-practices
- **Integrations:** https://docs.doppler.com/docs/integrations

---

**Last Updated:** 2025-11-05
**Maintained By:** AI Tech Stack 1 Team
