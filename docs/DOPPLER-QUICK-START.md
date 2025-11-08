# Doppler Quick Start Guide

## 5-Minute Setup

### 1. Link Your Project (One-Time)
```bash
cd ~/Projects/my-app
dsetup  # Links this directory to Doppler
```

### 2. Run Commands with Secrets
```bash
drun npm run dev          # Next.js dev server
drun npm run build        # Build with secrets
drun vercel deploy        # Deploy with secrets
drun python main.py       # Python scripts
```

### 3. View Your Secrets
```bash
dlist                     # List all secrets
dget STRIPE_SECRET_KEY    # View specific secret
```

### 4. Add New Secrets
```bash
dadd OPENAI_API_KEY="sk-..."
dadd ANTHROPIC_API_KEY="sk-ant-..."
```

## Common Commands

| What | Command |
|------|---------|
| Run dev server | `drun npm run dev` |
| View all secrets | `dlist` |
| Add secret | `dadd SECRET_NAME="value"` |
| Get secret value | `dget SECRET_NAME` |
| Link project | `dsetup` |
| Export to .env | `dlist --format env > .env` |

## Pro Tips

### Setup Once, Use Everywhere
```bash
# In project root
dsetup

# Now just use:
doppler run -- npm run dev
doppler run -- vercel deploy
```

### Chain Commands
```bash
drun npm install && drun npm run build && drun vercel deploy
```

### Use with Docker
```bash
drun docker-compose up
```

## When Keys Rotate

Simply update in Doppler once:
```bash
dadd STRIPE_SECRET_KEY="new_key_here"
```

All projects automatically get the new key. No need to update 10 different `.env` files!

## Dashboard

Manage visually: https://dashboard.doppler.com/workplace/projects/ai-tech-stack-1

## Need Help?

Full docs: `~/.claude/plugins/marketplaces/ai-dev-marketplace/docs/DOPPLER-WORKFLOW.md`
