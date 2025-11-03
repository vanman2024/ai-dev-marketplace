# Security Rules for AI Dev Marketplace Plugins

## 🚨 CRITICAL: No Hardcoded API Keys or Secrets

**This is the MOST IMPORTANT security rule for all plugins in this marketplace.**

### Absolute Prohibitions

❌ **NEVER** hardcode API keys in:
- Agent prompts
- Slash command prompts
- Skill documentation
- Example code
- Templates
- Scripts
- Configuration files committed to git

❌ **NEVER** include actual values for:
- API keys (Anthropic, OpenAI, Supabase, etc.)
- Database passwords
- Authentication tokens
- OAuth client secrets
- Webhook secrets
- Service account credentials
- Any sensitive credentials

### Required Practices

✅ **ALWAYS** use placeholders:
```bash
# CORRECT - Placeholder format
ANTHROPIC_API_KEY=your_anthropic_key_here
SUPABASE_URL=your_supabase_url_here
OPENAI_API_KEY=your_openai_key_here
```

✅ **ALWAYS** provide `.env.example` templates:
```bash
# .env.example - Safe to commit
ANTHROPIC_API_KEY=your_key_here
SUPABASE_URL=https://your-project.supabase.co
```

✅ **ALWAYS** reference environment variables in code:
```python
# CORRECT - Read from environment
import os
api_key = os.getenv("ANTHROPIC_API_KEY")
```

✅ **ALWAYS** protect `.env` files in `.gitignore`:
```bash
# .gitignore
.env
.env.local
.env.development
.env.staging
.env.production
!.env.example
```

✅ **ALWAYS** document how to obtain keys:
```markdown
## Setup

1. Get your Anthropic API key: https://console.anthropic.com/settings/keys
2. Copy `.env.example` to `.env`
3. Fill in your actual API key in `.env`
```

### Agent Instructions

**ALL agents that generate code MUST include:**

```markdown
**SECURITY: API Key Handling**

When generating configuration files:

❌ **NEVER** hardcode actual API keys
❌ **NEVER** include real credentials
❌ **NEVER** commit secrets to git

✅ **ALWAYS** use placeholders: `your_service_key_here`
✅ **ALWAYS** create `.env.example` with placeholders
✅ **ALWAYS** add `.env` to `.gitignore`
✅ **ALWAYS** read from environment variables in code
✅ **ALWAYS** document how to obtain keys

**Example placeholders:**
- `ANTHROPIC_API_KEY=your_anthropic_key_here`
- `SUPABASE_URL=https://your-project.supabase.co`
- `OPENAI_API_KEY=your_openai_key_here`
```

### Command Instructions

**ALL commands that handle environment setup MUST include:**

```markdown
**SECURITY CRITICAL:**

When creating environment files or configuration:

1. Use placeholders for ALL sensitive values
2. Format: `{service}_{env}_your_key_here`
3. Never generate or include actual API keys
4. Always protect with `.gitignore`
5. Always create `.env.example` template
6. Document key acquisition in setup guides
```

### Skill Instructions

**ALL skills that provide code examples MUST:**

```markdown
## Security Requirements

All code examples and templates in this skill follow strict security rules:

- Placeholders only, never real credentials
- Environment variable references in code
- `.gitignore` protection for secrets
- Setup documentation for key acquisition
```

### Examples

#### ❌ WRONG - Hardcoded Key

```python
# NEVER DO THIS
anthropic_client = Anthropic(
    api_key="sk-ant-api03-abc123xyz..."  # WRONG!
)
```

#### ✅ CORRECT - Environment Variable

```python
# ALWAYS DO THIS
import os
from anthropic import Anthropic

api_key = os.getenv("ANTHROPIC_API_KEY")
if not api_key:
    raise ValueError("ANTHROPIC_API_KEY environment variable not set")

anthropic_client = Anthropic(api_key=api_key)
```

#### ❌ WRONG - Hardcoded in .env Template

```bash
# NEVER COMMIT THIS
ANTHROPIC_API_KEY=sk-ant-api03-abc123xyz...
SUPABASE_URL=https://xyzproject.supabase.co
```

#### ✅ CORRECT - Placeholder in .env.example

```bash
# SAFE TO COMMIT
ANTHROPIC_API_KEY=your_anthropic_key_here
SUPABASE_URL=https://your-project.supabase.co
```

### Multi-Environment Best Practices

When generating multi-environment configurations:

```bash
# .env.development
ANTHROPIC_API_KEY=project_dev_your_key_here
SUPABASE_URL=https://project-dev.supabase.co
SUPABASE_ANON_KEY=project_dev_anon_key

# .env.staging
ANTHROPIC_API_KEY=project_staging_your_key_here
SUPABASE_URL=https://project-staging.supabase.co
SUPABASE_ANON_KEY=project_staging_anon_key

# .env.production
ANTHROPIC_API_KEY=project_prod_your_key_here
SUPABASE_URL=https://project-prod.supabase.co
SUPABASE_ANON_KEY=project_prod_anon_key
```

### Validation Checklist

Before committing ANY plugin component:

- [ ] No hardcoded API keys in prompts
- [ ] No real credentials in examples
- [ ] All examples use placeholders
- [ ] `.env.example` provided with placeholders
- [ ] `.gitignore` protects secret files
- [ ] Documentation explains how to get keys
- [ ] Code reads from environment variables
- [ ] Setup guides reference placeholder format

### Enforcement

**Plugin Validator Agent** will check for:
- Patterns matching API key formats (sk-ant-, sk-, Bearer, etc.)
- Hardcoded URLs with credentials
- Missing `.gitignore` entries
- Missing `.env.example` templates

**Violations = Build Failure**

### Common Violations to Avoid

1. **Example code with real keys**
   - Use `your_key_here` placeholders

2. **Setup instructions that assume keys exist**
   - Always document where to obtain keys

3. **Configuration files without .gitignore**
   - Always protect secret files

4. **Documentation showing real project URLs**
   - Use generic `your-project.service.co` format

### Education for Plugin Builders

When building plugins that generate code:

1. **Assume the code will be committed to public repos**
2. **Assume users will copy-paste without modification**
3. **Make placeholders obvious and self-documenting**
4. **Provide clear setup instructions for every service**

### Reporting Security Issues

If you find hardcoded credentials in any plugin:

1. Do NOT commit the fix publicly yet
2. Replace credentials immediately in your local copy
3. Notify plugin maintainer
4. Rotate the exposed credentials immediately
5. Review git history to ensure credentials never existed

## Summary

**The Golden Rule:** If it's sensitive, it's a placeholder or environment variable. NEVER hardcode. NEVER commit. ALWAYS protect.

This rule applies to:
- ✅ All agents in all plugins
- ✅ All commands in all plugins
- ✅ All skills in all plugins
- ✅ All templates and examples
- ✅ All documentation and guides

**No exceptions. Ever.**
