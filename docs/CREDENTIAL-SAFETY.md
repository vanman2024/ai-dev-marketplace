# Credential Safety Guide

## 🚨 Critical Rule: NEVER Commit Real Credentials

All API keys, tokens, and secrets must use placeholders in:
- ✅ Documentation files (`.md`, `.mdx`, `.txt`)
- ✅ Example files (`.example`, `.sample`, `.template`)
- ✅ Configuration files committed to git
- ✅ Scripts and code examples

## How We Got Breached

**November 2025**: Production Google API key was exposed in:
- `docs/doppler/environment-setup.md`
- `docs/doppler/integration-guide.md`
- Public repo: `dev-lifecycle-marketplace`

**Root cause**: Documentation generation scripts read from real `.env` files and inserted live credentials.

## Prevention Measures Now in Place

### 1. Strict Gitleaks Configuration

`.gitleaks.toml` now catches:
- Google API keys in docs: `AIza[0-9A-Za-z\-_]{35}`
- Any API key pattern in docs
- Supabase JWT tokens in docs
- Clerk/Stripe keys in docs

Test it:
```bash
# Check all files
gitleaks detect --verbose

# Check staged files before commit
gitleaks protect --staged
```

### 2. Environment Variable Sanitization Script

**For documentation authors and doc-generating agents:**

```bash
# Source the sanitization script
source scripts/sanitize-env-for-docs.sh

# Use sanitized variables in docs
echo "GOOGLE_API_KEY=$SANITIZED_GOOGLE_API_KEY"
# Output: GOOGLE_API_KEY=your_google_api_key_here
```

**Never use:**
```bash
❌ echo "GOOGLE_API_KEY=$GOOGLE_API_KEY"  # Real credential!
```

**Always use:**
```bash
✅ echo "GOOGLE_API_KEY=your_google_api_key_here"
✅ echo "GOOGLE_API_KEY=$SANITIZED_GOOGLE_API_KEY"
```

### 3. Pre-Commit Hook

Git hook at `.git/hooks/pre-commit` runs Gitleaks on every commit.

**If secrets detected:**
```
❌ Gitleaks found secrets in staged files!
Fix the issues above or use 'git commit --no-verify' to bypass (not recommended)
```

**Never bypass the hook** unless you're 100% certain it's a false positive.

### 4. Security Scanning in CI/CD

`.github/workflows/security-scan.yml` runs Gitleaks on every push.

## For AI Agents & Doc Generators

When generating documentation that includes environment variables:

**DO:**
- ✅ Use `scripts/sanitize-env-for-docs.sh` to get safe placeholders
- ✅ Use patterns like `your_*_key_here`
- ✅ Use test keys for Stripe/Clerk: `sk_test_*`, `whsec_test_*`

**DON'T:**
- ❌ Read directly from `.env` files
- ❌ Use `os.getenv()` or `process.env` for documentation
- ❌ Insert any value that looks like a real credential

## Emergency Response Checklist

If you discover exposed credentials:

1. **Immediately invalidate the key** (Google Cloud Console, Stripe Dashboard, etc.)
2. **Find all occurrences**: `gh search code "KEY_VALUE" --owner vanman2024`
3. **Replace with placeholders**: `sed -i 's/REAL_KEY/your_key_here/g' files`
4. **Commit fix to all repos** (public repos first!)
5. **Generate new keys** and update `.env` files (never commit these!)
6. **Review deployment configs** to ensure new keys are deployed

## Testing

Verify the protection works:

```bash
# Try to commit a fake Google API key
echo "GOOGLE_API_KEY=AIzaSyDOTGETBLOCKEDBYGITLEAKS" > test.md
git add test.md
git commit -m "test"
# Should be BLOCKED by gitleaks

# Clean up
rm test.md
git reset HEAD test.md
```

## Resources

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
