---
description: Configure OpenRouter settings, API keys, and preferences
argument-hint: [setting-name] [value]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

**Arguments**: $ARGUMENTS

Goal: Manage OpenRouter configuration including API keys, preferences, monitoring settings, and environment variables.

Core Principles:
- Detect existing configuration files
- Validate settings before applying
- Secure API key storage
- Provide clear feedback

Phase 1: Discovery
Goal: Understand current configuration state

Actions:
- Load OpenRouter documentation:
  @plugins/openrouter/docs/OpenRouter_Documentation_Analysis.md
- Parse $ARGUMENTS for configuration action (set, get, list, reset)
- Detect environment files:
  !{bash ls -la .env .env.local .env.example 2>/dev/null || echo "No env files"}
- Check existing OpenRouter configuration:
  !{bash grep -r "OPENROUTER" .env .env.local 2>/dev/null || echo "No config"}
- Identify project type:
  !{bash test -f package.json && echo "Node.js" || test -f requirements.txt && echo "Python" || echo "Unknown"}

Phase 2: Configuration Action
Goal: Execute requested configuration change

Actions:

**If no arguments provided (interactive mode):**
- Use AskUserQuestion to gather:
  - What to configure? (API key, app name, site URL, preferences)
  - Current values if updating existing settings
  - Confirmation before making changes

**Setting API Key:**
- Add or update OPENROUTER_API_KEY in .env or .env.local
- Verify key format (sk-or-v1-...)
- Test key validity with API call if requested
- Ensure .env is in .gitignore

**Setting App Name:**
- Add or update OPENROUTER_APP_NAME for request tracking
- Used in X-Title header for monitoring
- Helps identify requests in OpenRouter dashboard

**Setting Site URL:**
- Add or update OPENROUTER_SITE_URL for attribution
- Used in HTTP-Referer header
- Important for analytics and credits

**Setting Base URL (advanced):**
- Default: https://openrouter.ai/api/v1
- Custom endpoints for enterprise/proxy setups

**Getting Configuration:**
- Display current settings (mask API key)
- Show which env file is being used
- List all OpenRouter-related variables

**Listing Available Settings:**
- OPENROUTER_API_KEY (required)
- OPENROUTER_APP_NAME (recommended for tracking)
- OPENROUTER_SITE_URL (recommended for attribution)
- OPENROUTER_BASE_URL (optional, default provided)
- Model preferences and routing config

**Resetting Configuration:**
- Remove OpenRouter variables from env files
- Optionally backup current configuration
- Confirm before deletion

Phase 3: Validation
Goal: Verify configuration is correct

Actions:
- Check environment file syntax:
  !{bash grep "^OPENROUTER" .env .env.local 2>/dev/null | grep -v "^#"}
- Validate API key format (if set):
  !{bash grep "OPENROUTER_API_KEY" .env .env.local 2>/dev/null | grep -o "sk-or-v1-"}
- Ensure .env is in .gitignore:
  !{bash grep -q "^\.env$" .gitignore 2>/dev/null && echo "✅ Protected" || echo "⚠️ Add .env to .gitignore"}
- Create .env.example if missing:
  !{bash test -f .env.example || echo "OPENROUTER_API_KEY=your-api-key-here" > .env.example}

Phase 4: Summary
Goal: Report configuration status

Actions:
- Display configuration summary:
  - ✅ API key configured (or ⚠️ Missing)
  - ✅ App name set (or ⚠️ Recommended)
  - ✅ Site URL set (or ⚠️ Recommended)
  - ✅ Environment secured (.gitignore)

- Configuration file location:
  - Using: .env or .env.local
  - Example: .env.example created

- Next steps:
  1. Get API key at: https://openrouter.ai/keys
  2. Test configuration with sample request
  3. Set up monitoring with app name and site URL
  4. Configure model routing preferences
  5. Review usage at: https://openrouter.ai/activity

- Security reminders:
  - Never commit .env files to git
  - Keep API keys secure and rotate regularly
  - Use read-only keys for client-side apps
  - Monitor usage for unexpected activity

- Available commands:
  - /openrouter:configure set api-key <key>
  - /openrouter:configure set app-name <name>
  - /openrouter:configure set site-url <url>
  - /openrouter:configure get
  - /openrouter:configure list
  - /openrouter:configure reset
