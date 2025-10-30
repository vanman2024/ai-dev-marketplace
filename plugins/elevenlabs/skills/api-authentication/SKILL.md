---
name: api-authentication
description: API authentication patterns, SDK installation scripts, environment variable management, and connection testing for ElevenLabs. Use when setting up ElevenLabs authentication, installing ElevenLabs SDK, configuring API keys, testing ElevenLabs connection, or when user mentions ElevenLabs authentication, xi-api-key, ELEVENLABS_API_KEY, or ElevenLabs setup.
allowed-tools: Bash, Read, Write, Edit
---

# ElevenLabs API Authentication

Comprehensive authentication setup for ElevenLabs voice AI platform including SDK installation, API key management, environment configuration, and connection testing.

## Overview

This skill provides:
- Automated SDK installation for TypeScript and Python
- Secure API key configuration with environment variables
- Connection testing and validation scripts
- Production-ready client templates
- Complete authentication examples for Next.js and Python projects

## Authentication Method

ElevenLabs uses API key authentication via HTTP headers:
```
xi-api-key: YOUR_ELEVENLABS_API_KEY
```

**Security Requirements:**
- API keys must be stored in environment variables (never hardcoded)
- Keys should never be exposed in client-side code
- Each key can have endpoint restrictions and credit quotas

## Scripts

All scripts are fully functional and production-ready:

### 1. setup-auth.sh
Configures ELEVENLABS_API_KEY in .env file with validation.
```bash
bash scripts/setup-auth.sh [api-key]
```

### 2. test-connection.sh
Tests API connectivity using curl and validates credentials.
```bash
bash scripts/test-connection.sh
```

### 3. install-sdk.sh
Installs @elevenlabs/elevenlabs-js (TypeScript) or elevenlabs (Python) SDK.
```bash
bash scripts/install-sdk.sh [typescript|python]
```

### 4. validate-env.sh
Validates .env file has required ELEVENLABS_API_KEY.
```bash
bash scripts/validate-env.sh
```

### 5. generate-client.sh
Generates API client boilerplate from templates.
```bash
bash scripts/generate-client.sh [typescript|python] [output-path]
```

## Templates

All templates are production-ready and fully implemented:

### Environment Configuration
- `templates/.env.template` - Environment variable template with all required keys

### TypeScript Templates
- `templates/api-client.ts.template` - ElevenLabs client with error handling
- `templates/api-client-nextjs.ts.template` - Next.js server-side client
- `templates/api-client-edge.ts.template` - Edge runtime compatible client

### Python Templates
- `templates/api-client.py.template` - ElevenLabs client with error handling
- `templates/api-client-async.py.template` - Async client with connection pooling
- `templates/api-client-fastapi.py.template` - FastAPI integration client

## Examples

All examples include complete README.md files with step-by-step instructions:

### Basic Usage Examples
- `examples/nextjs-auth/README.md` - Complete Next.js authentication example
  - Environment setup
  - Server action implementation
  - API route handler
  - Error handling patterns

- `examples/python-auth/README.md` - Complete Python authentication example
  - Environment configuration
  - Client initialization
  - Error handling
  - Connection testing

- `examples/edge-runtime/README.md` - Edge runtime authentication example
  - Vercel Edge Functions setup
  - Cloudflare Workers setup
  - Deno Deploy setup
  - Environment variable access

### Advanced Examples
- `examples/multi-environment/README.md` - Multi-environment configuration (dev, staging, prod)
  - Environment-specific API keys
  - Configuration management
  - Platform-specific setup (Vercel, Railway, Fly.io)

- `examples/api-key-rotation/README.md` - API key rotation patterns
  - Zero-downtime rotation strategies
  - Dual-key pattern implementation
  - Automated rotation scripts

## Usage Instructions

### Initial Setup

1. **Install SDK**:
   ```bash
   # For TypeScript projects
   bash scripts/install-sdk.sh typescript

   # For Python projects
   bash scripts/install-sdk.sh python
   ```

2. **Configure API Key**:
   ```bash
   # Interactive setup
   bash scripts/setup-auth.sh

   # Or provide key directly
   bash scripts/setup-auth.sh sk_your_api_key_here
   ```

3. **Test Connection**:
   ```bash
   bash scripts/test-connection.sh
   ```

4. **Generate Client**:
   ```bash
   # TypeScript
   bash scripts/generate-client.sh typescript src/lib/elevenlabs.ts

   # Python
   bash scripts/generate-client.sh python src/elevenlabs_client.py
   ```

### Integration Workflow

For **Next.js projects**:
1. Run `bash scripts/install-sdk.sh typescript`
2. Run `bash scripts/setup-auth.sh`
3. Read `examples/nextjs-auth/README.md` for integration guide
4. Generate client: `bash scripts/generate-client.sh typescript src/lib/elevenlabs.ts`

For **Python projects**:
1. Run `bash scripts/install-sdk.sh python`
2. Run `bash scripts/setup-auth.sh`
3. Read `examples/python-auth/README.md` for integration guide
4. Generate client: `bash scripts/generate-client.sh python src/elevenlabs_client.py`

For **FastAPI projects**:
1. Run `bash scripts/install-sdk.sh python`
2. Run `bash scripts/setup-auth.sh`
3. Use template: `templates/api-client-fastapi.py.template`

## Validation

Validate your setup:
```bash
# Check environment variables
bash scripts/validate-env.sh

# Test API connection
bash scripts/test-connection.sh
```

## Security Best Practices

1. **Never commit .env files** - Add to .gitignore
2. **Use environment-specific keys** - Different keys for dev/staging/prod
3. **Rotate keys regularly** - Follow key rotation patterns in examples
4. **Set endpoint restrictions** - Configure in ElevenLabs dashboard
5. **Monitor credit usage** - Set custom credit quotas per key

## Troubleshooting

**API Key Not Found**:
- Run `bash scripts/validate-env.sh`
- Ensure .env file exists in project root
- Check environment variable is loaded (dotenv)

**Connection Failed**:
- Run `bash scripts/test-connection.sh` for detailed diagnostics
- Verify API key is valid in ElevenLabs dashboard
- Check network connectivity and firewall rules

**SDK Installation Failed**:
- Ensure Node.js/npm (for TypeScript) or Python/pip (for Python) is installed
- Check package.json or requirements.txt exists
- Run with verbose flag: `bash -x scripts/install-sdk.sh typescript`

## References

- [ElevenLabs Authentication Docs](https://elevenlabs.io/docs/api-reference/authentication)
- [ElevenLabs Quickstart](https://elevenlabs.io/docs/quickstart)
- [TypeScript SDK Docs](https://github.com/elevenlabs/elevenlabs-js)
- [Python SDK Docs](https://github.com/elevenlabs/elevenlabs-python)
