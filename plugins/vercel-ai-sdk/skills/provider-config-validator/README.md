# Provider Configuration Validator

Autonomous Claude Code skill for validating and debugging Vercel AI SDK provider configurations.

## What This Skill Does

This skill **automatically activates** when Claude detects provider-related errors in your Vercel AI SDK project:

- ✅ **Validates API keys** - Checks format, existence, and security
- ✅ **Verifies packages** - Ensures provider SDKs are installed correctly
- ✅ **Checks models** - Validates model names are supported by provider
- ✅ **Tests connections** - Attempts real API calls to verify setup
- ✅ **Generates fixes** - Creates code snippets and configuration files
- ✅ **Handles errors** - Provides clear diagnostics and recovery steps

## When It Activates

Claude automatically uses this skill when you encounter:

- **Authentication errors** (401, 403)
- **Missing API key errors**
- **Package not found errors**
- **Invalid model name errors**
- **Rate limiting errors** (429)
- **Environment variable issues**
- **Import/require errors**
- **Connection failures**

You can also explicitly request validation:
- "Validate my OpenAI setup"
- "Check if my Anthropic configuration is correct"
- "Debug my Google Gemini connection"

## Scripts

### 1. `validate-provider.sh`
Main validation script that checks all aspects of provider configuration.

```bash
./scripts/validate-provider.sh <provider> [project-root]

# Examples:
./scripts/validate-provider.sh openai
./scripts/validate-provider.sh anthropic /path/to/project
```

**Checks:**
- Package installation and version
- Environment file (.env) exists
- API key is set and has correct format
- .env is in .gitignore
- Core SDK (ai) is installed

**Output:**
```
🔍 Validating openai provider configuration...

📦 Project type: node

🔧 Checking provider: openai
   Environment variable: OPENAI_API_KEY
   Package: @ai-sdk/openai

✅ Package @ai-sdk/openai is installed
✅ .env file exists
✅ OPENAI_API_KEY is set with correct prefix
✅ .env is in .gitignore
✅ Vercel AI SDK (ai) is installed

✅ All checks passed! Configuration is valid.
```

### 2. `check-model-compatibility.sh`
Validates if a model name is supported by the provider.

```bash
./scripts/check-model-compatibility.sh <provider> <model>

# Examples:
./scripts/check-model-compatibility.sh openai gpt-4o
./scripts/check-model-compatibility.sh anthropic claude-opus-4-20250514
```

**Output for valid model:**
```
✅ Model 'gpt-4o' is supported by openai

ℹ️  GPT-4o models support:
   - Text and vision
   - Function/tool calling
   - 128K context window
```

**Output for invalid model:**
```
❌ Model 'gpt-5' is NOT supported by openai

📋 Valid models for openai:
  • gpt-4o
  • gpt-4o-mini
  • gpt-4
  • gpt-4-turbo
  • gpt-3.5-turbo

💡 Did you mean?
  → gpt-4o
```

### 3. `generate-fix.sh`
Generates code snippets and configuration fixes.

```bash
./scripts/generate-fix.sh <issue-type> [provider] [project-root]

# Examples:
./scripts/generate-fix.sh missing-api-key openai
./scripts/generate-fix.sh rate-limiting anthropic
./scripts/generate-fix.sh import-error google
```

**Issue Types:**
- `missing-api-key` - Creates .env with proper structure
- `wrong-format` - Shows correct API key format
- `missing-package` - Generates install commands
- `model-compatibility` - Lists valid models
- `rate-limiting` - Adds retry logic with exponential backoff
- `import-error` - Fixes import statements

### 4. `test-provider-connection.sh`
Tests actual connection to provider API.

```bash
./scripts/test-provider-connection.sh <provider> [project-root]

# Examples:
./scripts/test-provider-connection.sh openai
./scripts/test-provider-connection.sh anthropic /path/to/project
```

**What it does:**
- Creates temporary test file
- Attempts real API call with minimal tokens
- Validates response
- Reports connection status
- Cleans up test file

**Output:**
```
🔌 Testing connection to openai...

🔄 Testing OpenAI connection...
✅ Connection successful!
Response: Connection successful!

✅ Provider connection test passed!
```

## Templates

### `env-template.txt`
Comprehensive .env template with all major providers and optional services:

```bash
# Use as starter template
cp templates/env-template.txt .env

# Then add your actual API keys
```

Includes configuration for:
- AI providers (OpenAI, Anthropic, Google, xAI, Groq, Mistral, Cohere, DeepSeek)
- Databases (PostgreSQL, MongoDB)
- Vector databases (Pinecone, Weaviate, Supabase)
- Rate limiting (Upstash Redis)
- Telemetry/Observability

### `gitignore-template.txt`
Security-focused .gitignore that prevents committing sensitive files:

```bash
# Add to existing .gitignore
cat templates/gitignore-template.txt >> .gitignore
```

### `error-handler-template.ts`
Production-ready error handler with retry logic:

```typescript
// Copy to your project
cp templates/error-handler-template.ts src/utils/errorHandler.ts

// Use in your code
import { handleProviderError } from './utils/errorHandler';

const result = await handleProviderError(
  () => generateText({
    model: openai('gpt-4')
    prompt: 'Hello'
  })
  { provider: 'openai' }
);
```

**Features:**
- Handles all common provider errors (401, 429, 404, network)
- Exponential backoff retry logic
- Helpful error messages with recovery steps
- Provider-specific diagnostics
- TypeScript types included

## Examples

See `examples/troubleshooting-guide.md` for comprehensive troubleshooting documentation covering:

1. Missing API Key Error
2. Invalid API Key Format
3. Package Not Installed
4. Invalid Model Name
5. Rate Limiting (429 Error)
6. Wrong Import Statements
7. Environment Variables Not Loading
8. CORS Errors (Browser)
9. Streaming Not Working
10. TypeScript Errors

Plus provider-specific issues for OpenAI, Anthropic, Google, and xAI.

## Supported Providers

- **OpenAI** - GPT-4, GPT-3.5
- **Anthropic** - Claude 3.5 Sonnet, Opus, Haiku
- **Google** - Gemini 1.5 Pro, Flash
- **xAI** - Grok Beta, Vision
- **Groq** - Llama, Mixtral
- **Mistral** - Mistral Large, Medium, Small
- **Cohere** - Command R+, Command
- **DeepSeek** - DeepSeek Chat, Coder

## Quick Reference

### Validate Everything
```bash
./scripts/validate-provider.sh openai
```

### Fix Specific Issue
```bash
./scripts/generate-fix.sh missing-api-key openai
```

### Check Model
```bash
./scripts/check-model-compatibility.sh anthropic claude-sonnet-4-5-20250929
```

### Test Connection
```bash
./scripts/test-provider-connection.sh google
```

### Full Diagnostic Workflow
```bash
# 1. Validate
./scripts/validate-provider.sh openai

# 2. Fix issues (if any)
./scripts/generate-fix.sh missing-api-key openai

# 3. Verify model
./scripts/check-model-compatibility.sh openai gpt-4o

# 4. Test connection
./scripts/test-provider-connection.sh openai

# 5. Run your app
npm run dev
```

## Integration with Commands

This skill works seamlessly with all Vercel AI SDK plugin commands:

- `/vercel-ai-sdk:new-app` - Validates provider setup after scaffolding
- `/vercel-ai-sdk:add-provider` - Checks new provider configuration
- `/vercel-ai-sdk:add-streaming` - Ensures provider is working before adding streaming
- All feature commands - Validates provider before implementing features

## Skill Metadata

**Name:** `provider-config-validator`

**Triggers on:**
- Provider errors (401, 403, 429, 404)
- API key issues
- Package installation errors
- Model compatibility problems
- Connection failures
- Environment variable issues

**Allowed Tools:**
- Read - Check configuration files
- Grep - Search for issues in code
- Glob - Find relevant files
- Bash - Run validation scripts

**Auto-invoked:** Yes, when provider errors are detected

**Manual invocation:** Ask Claude to "validate provider" or "check configuration"

## Contributing

This skill is part of the vercel-ai-sdk plugin. To improve it:

1. Add support for new providers in validation scripts
2. Enhance error detection patterns
3. Create additional fix templates
4. Improve diagnostic messages

## Version

**Version:** 1.0.0
**SDK Compatibility:** Vercel AI SDK 5+
**Last Updated:** January 2025
