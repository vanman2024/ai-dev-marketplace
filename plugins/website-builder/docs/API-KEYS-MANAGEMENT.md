# API Keys Management Guide

## Overview

This guide explains how to manage API keys for the website-builder plugin across multiple projects.

## Recommended Approach: Project-Specific Keys in ~/.bashrc

### Why This Approach?

✅ **Per-project budgeting** - Track costs by project
✅ **Easy to rotate** - Update one place, affects all projects
✅ **Never committed** - Keys stay in your bashrc, not in Git
✅ **Auto-loaded** - Scripts can pull from bashrc automatically

### Setup in ~/.bashrc

Add this to your `~/.bashrc`:

```bash
# ============================================
# Website Builder Projects - API Keys
# ============================================

# --- Project: My Blog ---
export MY_BLOG_ANTHROPIC_API_KEY="sk-ant-api03-xxx"
export MY_BLOG_GOOGLE_API_KEY="AIzaSyxxx"
export MY_BLOG_SUPABASE_URL="https://xxx.supabase.co"
export MY_BLOG_SUPABASE_ANON_KEY="eyJxxx"
export MY_BLOG_MEM0_API_KEY="m0-xxx"

# --- Project: Marketing Site ---
export MARKETING_SITE_ANTHROPIC_API_KEY="sk-ant-api03-yyy"
export MARKETING_SITE_GOOGLE_API_KEY="AIzaSyyyy"
export MARKETING_SITE_SUPABASE_URL="https://yyy.supabase.co"
export MARKETING_SITE_SUPABASE_ANON_KEY="eyJyyy"

# --- Default/Shared Keys (fallback) ---
export WEBSITE_BUILDER_ANTHROPIC_API_KEY="sk-ant-api03-default"
export WEBSITE_BUILDER_GOOGLE_API_KEY="AIzaSydefault"
export WEBSITE_BUILDER_MEM0_API_KEY="m0-shared"

# Helper function to load project keys
load_website_keys() {
  local project_name=$(basename "$PWD" | tr '[:lower:]' '[:upper:]' | tr '-' '_')

  # Try project-specific keys first
  export ANTHROPIC_API_KEY="${project_name}_ANTHROPIC_API_KEY"
  export GOOGLE_API_KEY="${project_name}_GOOGLE_API_KEY"
  export PUBLIC_SUPABASE_URL="${project_name}_SUPABASE_URL"
  export PUBLIC_SUPABASE_ANON_KEY="${project_name}_SUPABASE_ANON_KEY"
  export MEM0_API_KEY="${project_name}_MEM0_API_KEY"

  # Fallback to shared keys if project keys don't exist
  export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$WEBSITE_BUILDER_ANTHROPIC_API_KEY}"
  export GOOGLE_API_KEY="${GOOGLE_API_KEY:-$WEBSITE_BUILDER_GOOGLE_API_KEY}"
  export MEM0_API_KEY="${MEM0_API_KEY:-$WEBSITE_BUILDER_MEM0_API_KEY}"

  echo "✅ Loaded API keys for project: $project_name"
}
```

Then reload:
```bash
source ~/.bashrc
```

### Using Keys in a Project

1. **Navigate to project directory:**
   ```bash
   cd ~/projects/my-blog
   ```

2. **Run the setup script:**
   ```bash
   bash scripts/setup-env.sh
   ```

   This will:
   - Copy `.env.example` to `.env`
   - Attempt to load keys from `~/.bashrc` based on project name
   - Show what keys were found/missing

3. **Manually edit .env if needed:**
   ```bash
   nano .env
   ```

## Alternative Approach: MCP .mcp.json (Not Recommended for Git)

Some MCP servers store keys in `.mcp.json`:

```json
{
  "mcpServers": {
    "content-image-generation": {
      "command": "python",
      "args": ["-m", "content_image_generation"],
      "env": {
        "GOOGLE_API_KEY": "your-key-here",
        "ANTHROPIC_API_KEY": "your-key-here"
      }
    }
  }
}
```

**Problem:** This file should NOT be committed to Git.

**Solution:** Use `.mcp.json.example` instead:
- Commit `.mcp.json.example` with placeholder keys
- Copy to `.mcp.json` locally
- Add `.mcp.json` to `.gitignore` ✅ (already done)

## Getting API Keys

### Anthropic (Claude)
1. Go to: https://console.anthropic.com/settings/keys
2. Create new key
3. Copy: `sk-ant-api03-...`

### Google AI (Gemini, Imagen, Veo)
1. Go to: https://aistudio.google.com/app/apikey
2. Create API key
3. Copy: `AIzaSy...`

For production Imagen/Veo:
1. Create Google Cloud project: https://console.cloud.google.com
2. Enable Vertex AI API
3. Create service account
4. Download JSON credentials

### Supabase
1. Go to: https://app.supabase.com/
2. Select your project
3. Settings → API
4. Copy:
   - Project URL: `https://xxx.supabase.co`
   - Anon/Public key: `eyJxxx`
   - Service Role key: `eyJyyy` (keep secret!)

### Mem0
1. Go to: https://app.mem0.ai/dashboard/api-keys
2. Create new API key
3. Copy: `m0-...`

## Security Best Practices

### ✅ DO:
- Store keys in `~/.bashrc` per-project
- Use `.env` files locally (never commit)
- Add `.env` and `.mcp.json` to `.gitignore`
- Rotate keys regularly
- Use different keys per project for cost tracking
- Use service account keys for production

### ❌ DON'T:
- Commit `.env` files to Git
- Share keys in chat/email
- Use production keys in development
- Hard-code keys in source code
- Use same key across all projects

## Key Rotation

When you need to rotate a key:

1. **Generate new key** in provider console
2. **Update ~/.bashrc:**
   ```bash
   export MY_BLOG_ANTHROPIC_API_KEY="sk-ant-api03-NEW"
   ```
3. **Reload bashrc:**
   ```bash
   source ~/.bashrc
   ```
4. **Re-run setup in each project:**
   ```bash
   cd ~/projects/my-blog
   bash scripts/setup-env.sh
   ```
5. **Revoke old key** in provider console

## Troubleshooting

### "API key not found"

Check:
1. Is key in `~/.bashrc`?
2. Did you run `source ~/.bashrc`?
3. Is `.env` file present?
4. Does project name match pattern in bashrc?

### "Invalid API key"

Check:
1. Key copied correctly (no spaces/newlines)?
2. Key not revoked in provider console?
3. Using correct key for environment (dev vs prod)?

### "Keys keep disappearing"

Check:
1. Is `.env` in `.gitignore`? ✅
2. Did you commit `.env` accidentally?
3. Are you overwriting `.env` somehow?

## Example Workflow

### Initial Setup

```bash
# 1. Add keys to bashrc
nano ~/.bashrc
# Add project-specific keys (see template above)

# 2. Reload bashrc
source ~/.bashrc

# 3. Initialize new project
cd ~/projects/new-website
npx astro@latest init .

# 4. Setup environment
bash /path/to/website-builder/scripts/setup-env.sh

# 5. Verify keys loaded
cat .env | grep -v "^#"
```

### Daily Usage

```bash
# Just cd into project and start working
cd ~/projects/my-blog

# Keys are already in .env from initial setup
npm run dev
```

## Budget Tracking

With per-project keys, you can track costs:

1. **Anthropic Console:** View usage by API key
2. **Google Cloud:** Filter by project
3. **Supabase:** Check project usage dashboard

This helps you see which projects are costing the most!
