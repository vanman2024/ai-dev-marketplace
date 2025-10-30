# API Key Rotation Example

Best practices and implementation patterns for rotating ElevenLabs API keys without downtime.

## Overview

API key rotation is critical for:
- **Security**: Limit exposure if a key is compromised
- **Compliance**: Meet security audit requirements
- **Access control**: Revoke access for team members
- **Usage tracking**: Monitor different periods separately

## Rotation Strategies

### Strategy 1: Dual-Key Pattern (Zero Downtime)

Use two keys simultaneously during transition:

```typescript
// lib/elevenlabs-rotation.ts
import { ElevenLabsClient } from 'elevenlabs';

interface RotationConfig {
  primaryKey: string;
  secondaryKey?: string;
  rotationDate?: Date;
}

export function createRotatingClient(config: RotationConfig): ElevenLabsClient {
  const now = new Date();
  const useSecondary =
    config.secondaryKey &&
    config.rotationDate &&
    now >= config.rotationDate;

  const apiKey = useSecondary ? config.secondaryKey : config.primaryKey;

  console.log(`[ElevenLabs] Using ${useSecondary ? 'secondary' : 'primary'} key`);

  return new ElevenLabsClient({ apiKey });
}

// Usage
const client = createRotatingClient({
  primaryKey: process.env.ELEVENLABS_API_KEY_PRIMARY!,
  secondaryKey: process.env.ELEVENLABS_API_KEY_SECONDARY,
  rotationDate: new Date('2024-12-01T00:00:00Z'),
});
```

### Strategy 2: Graceful Fallback

Try primary key, fallback to secondary if it fails:

```typescript
// lib/elevenlabs-fallback.ts
import { ElevenLabsClient } from 'elevenlabs';

export async function createFallbackClient(): Promise<ElevenLabsClient> {
  const primaryKey = process.env.ELEVENLABS_API_KEY_PRIMARY;
  const secondaryKey = process.env.ELEVENLABS_API_KEY_SECONDARY;

  // Try primary key first
  if (primaryKey) {
    try {
      const client = new ElevenLabsClient({ apiKey: primaryKey });
      // Test the key
      await client.models.getAll();
      console.log('[ElevenLabs] Using primary key');
      return client;
    } catch (error) {
      console.warn('[ElevenLabs] Primary key failed, trying secondary');
    }
  }

  // Fallback to secondary
  if (secondaryKey) {
    const client = new ElevenLabsClient({ apiKey: secondaryKey });
    console.log('[ElevenLabs] Using secondary key');
    return client;
  }

  throw new Error('No valid ElevenLabs API keys available');
}
```

### Strategy 3: Time-Based Rotation

Automatically switch keys based on schedule:

```typescript
// lib/elevenlabs-scheduled.ts
import { ElevenLabsClient } from 'elevenlabs';

interface ScheduledKey {
  key: string;
  validFrom: Date;
  validUntil: Date;
}

export class ScheduledKeyManager {
  private keys: ScheduledKey[];

  constructor(keys: ScheduledKey[]) {
    this.keys = keys.sort((a, b) => a.validFrom.getTime() - b.validFrom.getTime());
  }

  getCurrentKey(): string {
    const now = new Date();

    for (const entry of this.keys) {
      if (now >= entry.validFrom && now < entry.validUntil) {
        return entry.key;
      }
    }

    throw new Error('No valid key for current date');
  }

  getNextRotation(): Date | null {
    const now = new Date();
    const future = this.keys.find(k => k.validFrom > now);
    return future ? future.validFrom : null;
  }

  createClient(): ElevenLabsClient {
    const apiKey = this.getCurrentKey();
    return new ElevenLabsClient({ apiKey });
  }
}

// Usage
const keyManager = new ScheduledKeyManager([
  {
    key: process.env.ELEVENLABS_API_KEY_Q1!,
    validFrom: new Date('2024-01-01'),
    validUntil: new Date('2024-04-01'),
  },
  {
    key: process.env.ELEVENLABS_API_KEY_Q2!,
    validFrom: new Date('2024-04-01'),
    validUntil: new Date('2024-07-01'),
  },
  {
    key: process.env.ELEVENLABS_API_KEY_Q3!,
    validFrom: new Date('2024-07-01'),
    validUntil: new Date('2024-10-01'),
  },
]);

const client = keyManager.createClient();
console.log('Next rotation:', keyManager.getNextRotation());
```

## Rotation Workflow

### Step-by-Step Process

#### Phase 1: Preparation (1 week before)

1. **Generate new key in ElevenLabs dashboard**
   - Go to Settings → API Keys
   - Create new key with descriptive name (e.g., "Production-2024-Q1")
   - Copy the key securely

2. **Add secondary key to environment**
   ```bash
   # In platform dashboard (Vercel, Railway, etc.)
   ELEVENLABS_API_KEY_SECONDARY=sk_new_key_here
   ```

3. **Test secondary key**
   ```bash
   # Test script
   curl 'https://api.elevenlabs.io/v1/models' \
     -H "xi-api-key: $ELEVENLABS_API_KEY_SECONDARY"
   ```

#### Phase 2: Cutover (Rotation day)

1. **Deploy dual-key configuration**
   ```typescript
   // Update config to use both keys
   const client = createRotatingClient({
     primaryKey: process.env.ELEVENLABS_API_KEY_PRIMARY!,
     secondaryKey: process.env.ELEVENLABS_API_KEY_SECONDARY!,
     rotationDate: new Date('2024-12-01T00:00:00Z'),
   });
   ```

2. **Monitor for errors**
   - Watch logs for authentication failures
   - Monitor error rates
   - Check API usage in ElevenLabs dashboard

3. **Switch keys**
   ```bash
   # In platform dashboard
   ELEVENLABS_API_KEY_PRIMARY=<new_key>
   ELEVENLABS_API_KEY_SECONDARY=<old_key>
   ```

#### Phase 3: Cleanup (1 week after)

1. **Verify new key is working**
   - Check all services are using new key
   - Verify no errors in logs
   - Confirm usage in dashboard

2. **Remove old key from environment**
   ```bash
   # Remove ELEVENLABS_API_KEY_SECONDARY
   ```

3. **Revoke old key in dashboard**
   - Go to ElevenLabs dashboard
   - Delete old API key
   - Document rotation in changelog

## Implementation Examples

### Next.js with Rotation

```typescript
// lib/elevenlabs.ts
import { ElevenLabsClient } from 'elevenlabs';
import { cache } from 'react';

interface KeyConfig {
  current: string;
  previous?: string;
  next?: string;
  switchDate?: Date;
}

function getKeyConfig(): KeyConfig {
  return {
    current: process.env.ELEVENLABS_API_KEY!,
    previous: process.env.ELEVENLABS_API_KEY_PREVIOUS,
    next: process.env.ELEVENLABS_API_KEY_NEXT,
    switchDate: process.env.ELEVENLABS_KEY_SWITCH_DATE
      ? new Date(process.env.ELEVENLABS_KEY_SWITCH_DATE)
      : undefined,
  };
}

export const createElevenLabsClient = cache((): ElevenLabsClient => {
  const config = getKeyConfig();

  // Check if we should use next key
  if (config.next && config.switchDate) {
    const now = new Date();
    if (now >= config.switchDate) {
      console.log('[ElevenLabs] Switching to next key');
      return new ElevenLabsClient({ apiKey: config.next });
    }
  }

  return new ElevenLabsClient({ apiKey: config.current });
});
```

### Python with Rotation

```python
# elevenlabs_rotation.py
import os
from datetime import datetime
from elevenlabs.client import ElevenLabs
from typing import Optional

class KeyRotationManager:
    def __init__(self):
        self.current_key = os.getenv("ELEVENLABS_API_KEY")
        self.previous_key = os.getenv("ELEVENLABS_API_KEY_PREVIOUS")
        self.next_key = os.getenv("ELEVENLABS_API_KEY_NEXT")

        switch_date = os.getenv("ELEVENLABS_KEY_SWITCH_DATE")
        self.switch_date = (
            datetime.fromisoformat(switch_date) if switch_date else None
        )

    def get_active_key(self) -> str:
        """Get the currently active API key"""
        if self.next_key and self.switch_date:
            now = datetime.now()
            if now >= self.switch_date:
                print(f"[ElevenLabs] Switching to next key at {now}")
                return self.next_key

        return self.current_key

    def create_client(self) -> ElevenLabs:
        """Create client with active key"""
        api_key = self.get_active_key()
        return ElevenLabs(api_key=api_key)

    def test_all_keys(self) -> dict[str, bool]:
        """Test all configured keys"""
        results = {}

        for name, key in [
            ("current", self.current_key),
            ("previous", self.previous_key),
            ("next", self.next_key),
        ]:
            if key:
                try:
                    client = ElevenLabs(api_key=key)
                    client.models.get_all()
                    results[name] = True
                except Exception:
                    results[name] = False

        return results

# Usage
manager = KeyRotationManager()
client = manager.create_client()

# Test all keys
print("Key status:", manager.test_all_keys())
```

## Monitoring & Alerts

### Key Usage Tracking

```typescript
// lib/key-monitor.ts
interface KeyUsageMetrics {
  keyId: string;
  requestCount: number;
  lastUsed: Date;
  errors: number;
}

export class KeyMonitor {
  private metrics: Map<string, KeyUsageMetrics> = new Map();

  trackRequest(keyId: string, success: boolean) {
    const existing = this.metrics.get(keyId) || {
      keyId,
      requestCount: 0,
      lastUsed: new Date(),
      errors: 0,
    };

    existing.requestCount++;
    existing.lastUsed = new Date();
    if (!success) existing.errors++;

    this.metrics.set(keyId, existing);
  }

  getMetrics(keyId: string): KeyUsageMetrics | undefined {
    return this.metrics.get(keyId);
  }

  getAllMetrics(): KeyUsageMetrics[] {
    return Array.from(this.metrics.values());
  }
}

export const keyMonitor = new KeyMonitor();
```

### Rotation Alerts

```typescript
// lib/rotation-alerts.ts
export async function sendRotationAlert(
  type: 'upcoming' | 'completed' | 'failed',
  details: { oldKey: string; newKey: string; date: Date }
) {
  // Send to monitoring service (e.g., Slack, PagerDuty, email)
  const message = {
    upcoming: `API key rotation scheduled for ${details.date}`,
    completed: `API key rotated successfully at ${details.date}`,
    failed: `API key rotation failed at ${details.date}`,
  }[type];

  // Example: Send to Slack
  await fetch(process.env.SLACK_WEBHOOK_URL!, {
    method: 'POST',
    body: JSON.stringify({ text: message }),
  });
}
```

## Automation

### Automated Rotation Script

```bash
#!/usr/bin/env bash
# rotate-elevenlabs-key.sh

set -euo pipefail

OLD_KEY="${ELEVENLABS_API_KEY}"
ENVIRONMENT="${1:-production}"

echo "Starting key rotation for $ENVIRONMENT..."

# 1. Generate new key (manual step - get from dashboard)
echo "Generate new key in ElevenLabs dashboard"
echo "Enter new key:"
read -s NEW_KEY

# 2. Test new key
echo "Testing new key..."
curl -s 'https://api.elevenlabs.io/v1/models' \
  -H "xi-api-key: $NEW_KEY" > /dev/null

if [ $? -eq 0 ]; then
  echo "✓ New key is valid"
else
  echo "✗ New key is invalid"
  exit 1
fi

# 3. Update environment (example with Vercel)
echo "Updating environment variables..."
vercel env rm ELEVENLABS_API_KEY_PREVIOUS $ENVIRONMENT -y
vercel env add ELEVENLABS_API_KEY_PREVIOUS $ENVIRONMENT <<< "$OLD_KEY"
vercel env rm ELEVENLABS_API_KEY $ENVIRONMENT -y
vercel env add ELEVENLABS_API_KEY $ENVIRONMENT <<< "$NEW_KEY"

# 4. Trigger deployment
echo "Triggering deployment..."
vercel deploy --prod

echo "✓ Rotation complete!"
```

## Best Practices

1. **Rotate regularly**: Every 90 days minimum
2. **Test before switching**: Validate new key works
3. **Keep overlap period**: Run both keys for 1 week
4. **Monitor actively**: Watch for auth failures
5. **Document rotations**: Keep rotation log
6. **Automate where possible**: Reduce human error

## References

- [ElevenLabs API Keys](https://elevenlabs.io/docs/api-reference/authentication)
- [Secret Rotation Best Practices](https://www.vaultproject.io/docs/secrets/dynamic)
