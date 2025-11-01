# API Key Troubleshooting Guide

Common issues and solutions for OpenRouter API key problems.

## Issue 1: Invalid API Key Format

**Symptoms:**
- Authentication fails immediately
- Error: "Invalid API key format"
- Key doesn't match expected pattern

**Solution:**
```bash
# Valid format: sk-or-v1-{64 hex characters}
# Example: sk-or-v1-1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef

# Check your key format
echo $OPENROUTER_API_KEY | grep -E '^sk-or-v1-[a-f0-9]{64}$'

# If no output, your key format is incorrect
```

**Fix:**
1. Visit https://openrouter.ai/keys
2. Generate a new API key
3. Copy the entire key including `sk-or-v1-` prefix
4. Update your `.env` file

## Issue 2: 401 Unauthorized

**Symptoms:**
- HTTP 401 response
- Message: "Invalid authentication credentials"
- Requests fail with auth error

**Possible Causes:**
1. **Wrong API key**: Copy-paste error or truncated key
2. **Expired key**: Key was revoked or expired
3. **Wrong account**: Using key from different account

**Solutions:**

**Verify key is active:**
```bash
bash scripts/validate-api-key.sh $OPENROUTER_API_KEY
```

**Test connectivity:**
```bash
curl https://openrouter.ai/api/v1/auth/key \
  -H "Authorization: Bearer $OPENROUTER_API_KEY"
```

**Generate new key:**
1. Login to https://openrouter.ai
2. Go to Settings → API Keys
3. Generate new key
4. Delete old key (optional)
5. Update `.env` with new key

## Issue 3: API Key Not Found in Environment

**Symptoms:**
- Error: "OPENROUTER_API_KEY not set"
- Environment variable is empty
- Scripts can't find key

**Solution:**

**Check if key is set:**
```bash
echo $OPENROUTER_API_KEY
# Should output: sk-or-v1-...
```

**If empty, load from .env:**
```bash
source .env
echo $OPENROUTER_API_KEY
```

**Verify .env file exists:**
```bash
ls -la .env
# Should show: -rw------- .env
```

**Check .env contents:**
```bash
grep OPENROUTER_API_KEY .env
# Should show: OPENROUTER_API_KEY=sk-or-v1-...
```

**Fix:**
1. Create `.env` from template: `cp templates/.env.template .env`
2. Edit `.env` and add your API key
3. Load environment: `source .env`
4. Verify: `echo $OPENROUTER_API_KEY`

## Issue 4: 403 Forbidden

**Symptoms:**
- HTTP 403 response
- Message: "Access forbidden"
- Key appears valid but requests fail

**Possible Causes:**
1. **Key revoked**: You or someone deleted the key
2. **Account suspended**: Billing or terms violation
3. **IP restriction**: Key restricted to specific IPs
4. **Rate limited**: Too many requests (see rate limiting guide)

**Solutions:**

**Check key status:**
```bash
curl -i https://openrouter.ai/api/v1/auth/key \
  -H "Authorization: Bearer $OPENROUTER_API_KEY"
```

**Check account status:**
1. Login to https://openrouter.ai
2. Check for any warnings or notices
3. Verify billing is current
4. Check key status in Settings → API Keys

**Generate new key if needed:**
- Delete compromised key
- Create new key
- Update all applications

## Issue 5: Key Works in Browser but Not in Code

**Symptoms:**
- OpenRouter dashboard works fine
- API requests from code fail
- Same key behaves differently

**Possible Causes:**
1. **Environment not loaded**: `.env` not sourced
2. **Wrong variable name**: Typo in code
3. **Whitespace**: Extra spaces in key value
4. **Quote issues**: Key wrapped in quotes incorrectly

**Solutions:**

**Check for whitespace:**
```bash
# This will show any extra spaces
echo "[$OPENROUTER_API_KEY]"
# Should be: [sk-or-v1-...]
# NOT: [ sk-or-v1-...] or [sk-or-v1-... ]
```

**Trim whitespace:**
```bash
# In .env file, ensure no spaces:
OPENROUTER_API_KEY=sk-or-v1-...  # Wrong (trailing space)
OPENROUTER_API_KEY=sk-or-v1-...  # Correct
```

**Verify in code:**
```javascript
// Log the actual key value
console.log('Key length:', process.env.OPENROUTER_API_KEY?.length);
// Should be: 75 (11 chars prefix + 64 chars hex)
```

## Issue 6: Key Not Persisting Between Sessions

**Symptoms:**
- Key works in current terminal
- Doesn't work in new terminal
- Must re-source .env every time

**Solution:**

**Don't add to shell config** (security risk):
```bash
# ❌ WRONG - Never do this
echo "export OPENROUTER_API_KEY=..." >> ~/.bashrc
```

**Use .env file properly:**
```bash
# ✅ CORRECT - Load when needed
cd /path/to/project
source .env
```

**Use direnv (optional):**
```bash
# Install direnv
sudo apt install direnv  # or brew install direnv

# Add to ~/.bashrc
eval "$(direnv hook bash)"

# Create .envrc
echo "dotenv" > .envrc
direnv allow

# Now .env loads automatically when you cd into directory
```

## Issue 7: Multiple Keys for Different Environments

**Symptoms:**
- Need different keys for dev/staging/prod
- Keys getting mixed up
- Not sure which key is which

**Solution:**

**Use separate .env files:**
```bash
.env.development
.env.staging
.env.production
```

**Load appropriate file:**
```bash
# Development
source .env.development

# Production
source .env.production
```

**Use key labels:**
1. Go to https://openrouter.ai/keys
2. Label each key: "Dev", "Staging", "Prod"
3. Track which key is which
4. Rotate keys periodically

## Validation Checklist

Use this checklist to validate your API key setup:

- [ ] API key format is correct (sk-or-v1-{64 hex})
- [ ] Key works in validation script
- [ ] No extra whitespace around key
- [ ] .env file exists and is readable
- [ ] .env file has secure permissions (600)
- [ ] .env is in .gitignore
- [ ] Key is not hardcoded in source files
- [ ] Key is not committed to version control
- [ ] Key is documented (which environment/project)
- [ ] Backup copy stored securely (password manager)

## Quick Validation

Run the comprehensive validation script:

```bash
bash scripts/validate-api-key.sh
```

Expected output:
```
✅ Format is correct (sk-or-v1-*)
✅ API key is valid and active
✅ Validation complete - API key is functional
```

## Security Best Practices

1. **Never commit keys to version control**
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   echo ".env.*" >> .gitignore
   ```

2. **Use secure file permissions**
   ```bash
   chmod 600 .env
   ```

3. **Rotate keys periodically**
   - Generate new key
   - Update all applications
   - Delete old key
   - Do this every 90 days

4. **Use different keys for different environments**
   - Development
   - Staging
   - Production

5. **Monitor key usage**
   - Check https://openrouter.ai/settings/usage
   - Set up alerts for unusual activity
   - Review usage regularly

## Getting Help

If you're still having issues:

1. Run troubleshooting script:
   ```bash
   bash scripts/troubleshoot.sh
   ```

2. Check OpenRouter status:
   - Visit https://openrouter.ai/status
   - Check for service outages

3. Contact support:
   - Email: support@openrouter.ai
   - Include validation script output
   - Describe your issue clearly
   - Never share your actual API key
