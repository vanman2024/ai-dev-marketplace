# Doppler Integration with AI Dev Lifecycle Marketplace

## Overview

Doppler is now integrated into the AI Dev Lifecycle Marketplace as an **optional** advanced secret management solution. It solves the key rotation problem (like Stripe's 90-day CLI keys) and provides a scalable approach for managing secrets across multiple projects and environments.

## Integration Points

### 1. Foundation Plugin Commands

#### `/foundation:doppler-setup [project-name]`

**Purpose:** Complete Doppler setup for a single project

**Features:**
- Installs Doppler CLI (if not present)
- Authenticates user
- Creates Doppler project with 4 environments (dev, dev_personal, stg, prd)
- Imports existing .env secrets to Doppler
- Creates bidirectional sync scripts (`doppler-sync.sh`)
- Updates npm scripts for Doppler integration
- Generates documentation (DOPPLER.md)

**Usage:**
```bash
/foundation:doppler-setup my-saas-app
```

**Files Created:**
- `.doppler.yaml` - Project configuration (safe to commit)
- `doppler-sync.sh` - Bidirectional sync helper
- `DOPPLER.md` - Project-specific documentation
- `package.json` - Updated with Doppler scripts

#### `/foundation:env-vars sync-from-doppler [environment]`

**Purpose:** Download secrets from Doppler to .env

**Usage:**
```bash
/foundation:env-vars sync-from-doppler dev
/foundation:env-vars sync-from-doppler prd
```

**Behavior:**
- Downloads secrets from specified Doppler environment
- Overwrites local .env file
- Creates .env.backup for safety
- Reports count of synced variables

#### `/foundation:env-vars sync-to-doppler [environment]`

**Purpose:** Upload .env secrets to Doppler

**Usage:**
```bash
/foundation:env-vars sync-to-doppler dev
```

**Behavior:**
- Uploads .env contents to specified Doppler environment
- Preserves existing Doppler secrets not in .env
- Reports count of uploaded variables
- Shows dashboard URL for verification

### 2. Phase 0 Orchestrator Integration

**Location:** `plugins/ai-tech-stack-1/commands/build-full-stack-phase-0.md`

**Phase 9.5: Optional Doppler Setup**

Added between Phase 9 (MCP Configuration) and Phase 10 (Summary).

**Flow:**
1. User is asked: "Would you like to setup Doppler for centralized secret management?"
2. Options presented:
   - "Yes - Setup Doppler (recommended for teams and key rotation)"
   - "No - Use local .env files only (simpler for solo projects)"
3. Benefits explained:
   - Solves 90-day Stripe CLI key rotation
   - Multi-environment support
   - Team collaboration
   - Audit logs
   - Free for personal use
4. If "Yes": Executes `/foundation:doppler-setup $ARGUMENTS`
5. If "No": Continues with local .env files
6. Tracks choice in `.ai-stack-config.json` as `dopplerEnabled: true/false`

**Summary Updated:**
- Shows "Secret management: [Doppler enabled/Local .env only]"
- Displays Doppler quick commands if enabled
- Includes dashboard URL

## Workflow Comparison

### Old Workflow (Local .env Only)

```bash
# Phase 0
/ai-tech-stack-1:build-full-stack-phase-0 "My App"
# Creates .env with placeholders

# Development
npm run dev  # Reads from .env

# When keys rotate (e.g., Stripe after 90 days)
# Manually update .env
# Manually update all other projects
# Manually update CI/CD secrets
# Hope you didn't miss any
```

### New Workflow (Doppler Enabled)

```bash
# Phase 0
/ai-tech-stack-1:build-full-stack-phase-0 "My App"
# Asks about Doppler → User selects "Yes"
# Doppler setup runs automatically
# .env secrets imported to Doppler

# Development (Option 1 - Direct Doppler)
doppler run -- npm run dev  # Secrets injected automatically

# Development (Option 2 - Sync to .env)
./doppler-sync.sh from-doppler dev
npm run dev  # Uses synced .env

# When keys rotate (e.g., Stripe after 90 days)
doppler secrets set STRIPE_SECRET_KEY="new_key" --config dev
doppler secrets set STRIPE_SECRET_KEY="new_key" --config prd
# Done! All projects get new key automatically
```

## Bidirectional Sync

The `doppler-sync.sh` script provides 3 modes:

### 1. Download from Doppler to .env
```bash
./doppler-sync.sh from-doppler dev
```

Use when:
- You want to work offline
- Tool requires .env file (doesn't support `doppler run`)
- Testing local changes before pushing to Doppler

### 2. Upload from .env to Doppler
```bash
./doppler-sync.sh to-doppler dev
```

Use when:
- You added secrets locally to .env
- Want to backup local secrets to Doppler
- Migrating from .env-only workflow

### 3. Compare Doppler vs .env
```bash
./doppler-sync.sh compare dev
```

Use when:
- Checking for sync drift
- Identifying missing secrets
- Validating before deployment

## Integration with Existing Commands

### `/foundation:env-vars` Actions

**Before Doppler:**
- `scan` - Detect required variables
- `generate` - Create .env files
- `setup-multi-env` - Multi-environment setup
- `add` - Add variable to .env
- `remove` - Remove variable from .env
- `list` - List all variables
- `check` - Validate completeness

**After Doppler:**
- All previous actions work unchanged
- **New:** `sync-from-doppler [env]` - Download from Doppler
- **New:** `sync-to-doppler [env]` - Upload to Doppler

### Backwards Compatibility

**Projects without Doppler:**
- All existing commands work exactly as before
- No breaking changes
- Doppler is purely optional

**Projects with Doppler:**
- Can still use `.env` files locally
- Can switch between Doppler and .env anytime
- `doppler run` wraps any command

## Key Rotation Example

### Problem: Stripe CLI Keys Expire Every 90 Days

**Old Way (Without Doppler):**
```bash
# 1. Stripe CLI key expires
stripe login  # Get new key

# 2. Update in multiple places:
vim ~/Projects/saas-app-1/.env
vim ~/Projects/saas-app-2/.env
vim ~/Projects/marketing-site/.env
# ... 10+ more projects

# 3. Update CI/CD secrets:
# GitHub Actions secrets
# Vercel environment variables
# Railway secrets
# ... multiple platforms

# 4. Update team members:
# Send new keys via Slack (insecure!)
# Hope everyone updates their .env

# 5. Production servers:
# SSH into each server
# Update .env manually
# Restart services

# Risk: Miss a project, production breaks
```

**New Way (With Doppler):**
```bash
# 1. Stripe CLI key expires
stripe login  # Get new key

# 2. Update once in Doppler:
doppler secrets set STRIPE_SECRET_KEY="new_key" --config dev
doppler secrets set STRIPE_SECRET_KEY="new_key" --config prd

# 3. Done!
# All projects using `doppler run` get new key instantly
# CI/CD uses Doppler service tokens (automatic)
# Team members access via Doppler (automatic)
# Production servers pull from Doppler (automatic)

# Risk: Zero (one place to update, propagates everywhere)
```

## Team Collaboration

### Without Doppler
- Share .env files via Slack/email (insecure)
- Each developer maintains their own .env
- No visibility into who has which keys
- No audit trail of changes
- Onboarding: Send .env files to new developers

### With Doppler
- Add team member in Dashboard
- They get access to all secrets automatically
- Granular permissions (read-only vs admin)
- Full audit trail (who changed what, when)
- Onboarding: Invite to Doppler, they're ready

## CI/CD Integration

### Service Tokens

For GitHub Actions, Vercel, Railway, etc.:

```bash
# Create service token
doppler configs tokens create github-actions --project my-app --config prd

# Add to GitHub Secrets as DOPPLER_TOKEN

# Use in workflow:
- name: Run with secrets
  run: doppler run --token ${{ secrets.DOPPLER_TOKEN }} -- npm run build
```

**Benefits:**
- One token gives access to all secrets
- Rotate token without updating secrets
- Revoke access instantly
- Audit which services accessed secrets

## Cost Structure

### Free Tier (Current Setup)
- Unlimited secrets
- 5 projects
- 5 team members
- Unlimited environments
- CLI + Dashboard access
- Perfect for: Solo developers, small teams, side projects

### Paid Tier ($12/user/month for teams)
- Unlimited projects
- Unlimited team members
- Role-based access control
- Advanced audit logging
- Priority support
- Perfect for: Growing teams, enterprises

## Documentation Hierarchy

```
ai-dev-marketplace/docs/
├── DOPPLER-QUICK-START.md       # 5-minute quickstart
├── DOPPLER-WORKFLOW.md          # Complete workflow guide
├── DOPPLER-INTEGRATION.md       # This file - integration details
└── DOPPLER-SETUP-SUMMARY.md     # Initial setup summary

Generated per-project:
├── DOPPLER.md                   # Project-specific guide
└── doppler-sync.sh              # Sync helper script
```

## Common Use Cases

### Use Case 1: Solo Developer, Multiple Projects

**Problem:** Managing secrets across 10+ side projects

**Solution:**
```bash
# One-time: Setup Doppler globally
doppler login

# Per project:
cd project1 && /foundation:doppler-setup project1
cd project2 && /foundation:doppler-setup project2

# Usage:
cd project1 && doppler run -- npm run dev
cd project2 && doppler run -- npm run dev

# Key rotation: Update once in Doppler, applies to all
```

### Use Case 2: Team of 5, Shared Project

**Problem:** Keeping secrets in sync across team

**Solution:**
```bash
# Lead developer:
/foundation:doppler-setup team-project
# Invite team in Dashboard

# Team members:
doppler login
cd team-project && doppler setup
doppler run -- npm run dev

# No .env files shared via Slack!
```

### Use Case 3: Multi-Environment Deployment

**Problem:** Different keys for dev/staging/production

**Solution:**
```bash
# Setup once:
/foundation:doppler-setup production-app

# Add environment-specific keys:
doppler secrets set DB_URL="dev-db" --config dev
doppler secrets set DB_URL="staging-db" --config stg
doppler secrets set DB_URL="prod-db" --config prd

# Development:
doppler run --config dev -- npm run dev

# Deployment to staging:
doppler run --config stg -- vercel deploy

# Deployment to production:
doppler run --config prd -- vercel deploy --prod
```

## Troubleshooting

### "Doppler CLI not found"
```bash
/foundation:doppler-setup
# Or manually:
curl -Ls https://cli.doppler.com/install.sh | sudo sh
```

### "Not authenticated"
```bash
doppler login -y
# Follow browser authentication
```

### "Project not linked"
```bash
doppler setup --project my-project --config dev
```

### "Secrets out of sync"
```bash
./doppler-sync.sh compare dev
./doppler-sync.sh from-doppler dev  # Pull from Doppler
# OR
./doppler-sync.sh to-doppler dev    # Push to Doppler
```

## Migration Path

### Existing Projects (Already Have .env)

1. **Install Doppler:**
   ```bash
   /foundation:doppler-setup
   ```

2. **Import existing secrets:**
   - Automatically imports .env during setup
   - Or manually: `doppler secrets upload .env --config dev`

3. **Start using:**
   ```bash
   doppler run -- npm run dev
   ```

4. **Gradually adopt:**
   - Keep .env as backup initially
   - Test with Doppler in development
   - Deploy with Doppler when confident

### New Projects

1. **Phase 0 prompts for Doppler:**
   ```bash
   /ai-tech-stack-1:build-full-stack-phase-0 "New App"
   # Select "Yes" when asked about Doppler
   ```

2. **Doppler setup runs automatically:**
   - No manual setup needed
   - Ready to use immediately

3. **Development starts with Doppler:**
   ```bash
   doppler run -- npm run dev
   ```

## Best Practices

1. **Use Doppler for secrets, .env for config:**
   - Secrets (API keys, passwords): Doppler
   - Configuration (NODE_ENV, PORT): .env or Doppler

2. **Commit .doppler.yaml, ignore .env:**
   ```gitignore
   .env
   .env.local
   .env.*.local
   !.env.example
   ```

3. **Use environment-specific configs:**
   - `dev` for local development
   - `stg` for staging/preview
   - `prd` for production

4. **Rotate keys regularly:**
   - Update in Doppler when keys expire
   - One place, propagates everywhere

5. **Use service tokens for CI/CD:**
   - Don't hardcode secrets in workflows
   - Use Doppler service tokens

## Comparison: Doppler vs Alternatives

| Feature | Doppler | 1Password | AWS Secrets Manager | .env Files |
|---------|---------|-----------|---------------------|------------|
| Free tier | ✅ (5 projects) | ❌ | ❌ | ✅ |
| CLI | ✅ | ✅ | ✅ | N/A |
| Multi-environment | ✅ | ⚠️ | ✅ | Manual |
| Team collaboration | ✅ | ✅ | ✅ | ❌ |
| Audit logs | ✅ | ✅ | ✅ | ❌ |
| Version history | ✅ | ✅ | ✅ | Git only |
| Auto rotation | ⚠️ Limited | ❌ | ✅ | ❌ |
| Learning curve | Low | Medium | High | None |
| Dev-friendly | ✅ | ⚠️ | ⚠️ | ✅ |

**Why Doppler for AI Dev Marketplace:**
- Free tier sufficient for most users
- Developer-friendly CLI
- Easy integration with existing workflows
- Perfect balance of features and simplicity
- No AWS account required

## Future Enhancements

### Planned

- [ ] Auto-detect Doppler in project initialization
- [ ] Doppler integration in deployment commands
- [ ] Automatic service token creation for CI/CD
- [ ] Doppler metrics in project dashboard

### Wishlist

- [ ] Doppler secrets validation against code usage
- [ ] Automatic key rotation reminders
- [ ] Integration with secret scanning tools
- [ ] Doppler environment templates

## Resources

- **Quick Start:** `docs/DOPPLER-QUICK-START.md`
- **Full Workflow:** `docs/DOPPLER-WORKFLOW.md`
- **Setup Summary:** `docs/DOPPLER-SETUP-SUMMARY.md`
- **Doppler Docs:** https://docs.doppler.com
- **Dashboard:** https://dashboard.doppler.com

---

**Last Updated:** 2025-11-05
**Integration Version:** 1.0
**Maintained By:** AI Dev Lifecycle Marketplace Team
