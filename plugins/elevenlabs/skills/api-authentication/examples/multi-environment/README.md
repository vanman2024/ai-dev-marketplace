# Multi-Environment Configuration Example

Best practices for managing ElevenLabs API keys across development, staging, and production environments.

## Environment Strategy

### Three-Tier Approach

```
Development   → Local .env file with dev API key
Staging       → Staging platform env vars with staging API key
Production    → Production platform env vars with prod API key
```

## Configuration Files

### 1. Development (.env.local)

For local development:

```env
# .env.local (never commit!)
ELEVENLABS_API_KEY=sk_dev_xxxxxxxxxxxxx
ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
ELEVENLABS_DEFAULT_MODEL_ID=eleven_monolingual_v1

# Development-specific settings
ELEVENLABS_TIMEOUT=30000
ELEVENLABS_DEBUG=true
ELEVENLABS_LOG_LEVEL=debug
```

### 2. Staging (.env.staging)

For staging environment (template only, actual values in platform):

```env
# .env.staging (template only)
ELEVENLABS_API_KEY=sk_staging_xxxxxxxxxxxxx
ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
ELEVENLABS_DEFAULT_MODEL_ID=eleven_monolingual_v1

# Staging-specific settings
ELEVENLABS_TIMEOUT=30000
ELEVENLABS_LOG_LEVEL=info
ELEVENLABS_RATE_LIMIT=100
```

### 3. Production (.env.production)

For production environment (template only):

```env
# .env.production (template only)
ELEVENLABS_API_KEY=sk_prod_xxxxxxxxxxxxx
ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
ELEVENLABS_DEFAULT_MODEL_ID=eleven_turbo_v2

# Production-specific settings
ELEVENLABS_TIMEOUT=10000
ELEVENLABS_LOG_LEVEL=error
ELEVENLABS_RATE_LIMIT=1000
ELEVENLABS_ENABLE_CACHE=true
ELEVENLABS_CACHE_TTL=3600
```

## Environment Detection

### TypeScript/Next.js

```typescript
// lib/config.ts
export const config = {
  elevenlabs: {
    apiKey: process.env.ELEVENLABS_API_KEY!
    voiceId: process.env.ELEVENLABS_DEFAULT_VOICE_ID!
    modelId: process.env.ELEVENLABS_DEFAULT_MODEL_ID || 'eleven_monolingual_v1'
    timeout: parseInt(process.env.ELEVENLABS_TIMEOUT || '30000')
    debug: process.env.ELEVENLABS_DEBUG === 'true'
    environment: process.env.NODE_ENV || 'development'
  }
};

// Environment-specific behavior
export const isProduction = config.elevenlabs.environment === 'production';
export const isStaging = config.elevenlabs.environment === 'staging';
export const isDevelopment = config.elevenlabs.environment === 'development';

// Validation
if (!config.elevenlabs.apiKey) {
  throw new Error(
    `ELEVENLABS_API_KEY not set for ${config.elevenlabs.environment} environment`
  );
}

if (isProduction && config.elevenlabs.apiKey.includes('dev')) {
  throw new Error('Production environment must not use dev API key!');
}
```

### Python/FastAPI

```python
# config.py
import os
from typing import Literal
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Environment
    environment: Literal["development", "staging", "production"] = "development"

    # ElevenLabs
    elevenlabs_api_key: str
    elevenlabs_default_voice_id: str = "21m00Tcm4TlvDq8ikWAM"
    elevenlabs_default_model_id: str = "eleven_monolingual_v1"
    elevenlabs_timeout: int = 30000
    elevenlabs_debug: bool = False
    elevenlabs_rate_limit: int = 100

    class Config:
        env_file = f".env.{os.getenv('ENVIRONMENT', 'development')}"
        case_sensitive = False

    def validate_production(self):
        """Validate production-specific requirements"""
        if self.environment == "production":
            if not self.elevenlabs_api_key.startswith("sk_prod_"):
                raise ValueError("Production must use prod API key!")
            if self.elevenlabs_debug:
                raise ValueError("Debug mode not allowed in production!")

settings = Settings()
settings.validate_production()
```

## Platform-Specific Configuration

### Vercel

Set environment variables in Vercel dashboard for each environment:

```bash
# Production
vercel env add ELEVENLABS_API_KEY production
vercel env add ELEVENLABS_DEFAULT_VOICE_ID production

# Preview (Staging)
vercel env add ELEVENLABS_API_KEY preview
vercel env add ELEVENLABS_DEFAULT_VOICE_ID preview

# Development
vercel env add ELEVENLABS_API_KEY development
```

### Railway

Create environment-specific services:

```toml
# railway.toml
[environments.production]
ELEVENLABS_API_KEY = "${{ secrets.ELEVENLABS_API_KEY_PROD }}"

[environments.staging]
ELEVENLABS_API_KEY = "${{ secrets.ELEVENLABS_API_KEY_STAGING }}"
```

### Fly.io

Use `fly.toml` with secrets:

```bash
# Set secrets per app
fly secrets set ELEVENLABS_API_KEY=sk_prod_xxx -a myapp-production
fly secrets set ELEVENLABS_API_KEY=sk_staging_xxx -a myapp-staging
```

### Docker

Use docker-compose with environment files:

```yaml
# docker-compose.yml
version: '3.8'

services:
  app-dev:
    image: myapp:latest
    env_file:
      - .env.development

  app-staging:
    image: myapp:latest
    env_file:
      - .env.staging

  app-prod:
    image: myapp:latest
    env_file:
      - .env.production
```

## API Key Management

### Key Naming Convention

Use consistent naming:

```
sk_dev_xxxxxxxxxxxxx      → Development
sk_staging_xxxxxxxxxxxxx  → Staging
sk_prod_xxxxxxxxxxxxx     → Production
```

### Key Configuration in ElevenLabs Dashboard

For each environment, configure:

1. **Endpoint restrictions**:
   - Dev: All endpoints
   - Staging: All endpoints
   - Prod: Only necessary endpoints

2. **Credit quotas**:
   - Dev: Low quota (testing)
   - Staging: Medium quota (integration testing)
   - Prod: High quota (production traffic)

3. **Rate limits**:
   - Dev: Lenient (100/hour)
   - Staging: Moderate (500/hour)
   - Prod: Production (10000/hour)

## Environment-Specific Behavior

### Development

```typescript
// lib/elevenlabs-dev.ts
import { createElevenLabsClient } from './elevenlabs';

export function createDevClient() {
  const client = createElevenLabsClient();

  // Enable debug logging in development
  if (process.env.ELEVENLABS_DEBUG === 'true') {
    console.log('[ElevenLabs] Debug mode enabled');
    console.log('[ElevenLabs] API Key:', process.env.ELEVENLABS_API_KEY?.slice(0, 10) + '...');
  }

  return client;
}
```

### Staging

```typescript
// lib/elevenlabs-staging.ts
import { createElevenLabsClient } from './elevenlabs';

export function createStagingClient() {
  const client = createElevenLabsClient();

  // Add request logging in staging
  console.info('[ElevenLabs] Staging environment');

  return client;
}
```

### Production

```typescript
// lib/elevenlabs-prod.ts
import { createElevenLabsClient } from './elevenlabs';

export function createProdClient() {
  const client = createElevenLabsClient();

  // Minimal logging in production
  // Enable monitoring/telemetry
  // Enable caching

  return client;
}
```

## Testing Across Environments

### Environment-Specific Tests

```typescript
// tests/integration.test.ts
import { config, isProduction, isStaging } from '@/lib/config';

describe('ElevenLabs Integration', () => {
  it('should use correct API key format', () => {
    if (isProduction) {
      expect(config.elevenlabs.apiKey).toMatch(/^sk_prod_/);
    } else if (isStaging) {
      expect(config.elevenlabs.apiKey).toMatch(/^sk_staging_/);
    } else {
      expect(config.elevenlabs.apiKey).toMatch(/^sk_dev_/);
    }
  });

  it('should have appropriate rate limits', () => {
    if (isProduction) {
      expect(config.elevenlabs.rateLimit).toBeGreaterThan(1000);
    }
  });
});
```

## Security Best Practices

1. **Never commit API keys**
   ```gitignore
   .env
   .env.local
   .env.*.local
   .env.development
   .env.staging
   .env.production
   ```

2. **Use different keys per environment**
   - Prevents dev errors from affecting production
   - Allows separate monitoring and quotas
   - Enables easy key rotation

3. **Rotate keys regularly**
   ```bash
   # Rotate production key
   1. Generate new key in ElevenLabs dashboard
   2. Update production environment variables
   3. Test with new key
   4. Revoke old key
   ```

4. **Audit key usage**
   - Monitor API usage per environment
   - Set up alerts for unusual patterns
   - Review logs regularly

## Troubleshooting

### Wrong Environment Key

```typescript
// Add environment validation
if (process.env.NODE_ENV === 'production') {
  if (!process.env.ELEVENLABS_API_KEY?.startsWith('sk_prod_')) {
    throw new Error(
      'Production environment must use production API key (sk_prod_*)'
    );
  }
}
```

### Missing Environment Variables

```typescript
// Check all required variables
const required = [
  'ELEVENLABS_API_KEY'
  'ELEVENLABS_DEFAULT_VOICE_ID'
];

for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}
```

## References

- [The Twelve-Factor App](https://12factor.net/config)
- [Next.js Environment Variables](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)
- [Vercel Environment Variables](https://vercel.com/docs/concepts/projects/environment-variables)
