# Mobile Auth Setup Example

## Install Dependencies

```bash
./scripts/setup-auth.sh
```

## Copy Templates

```bash
cp templates/auth-context.tsx contexts/AuthContext.tsx
cp templates/secure-storage.ts lib/storage.ts
```

## Usage

```typescript
import { useAuth } from '@/contexts/AuthContext';

function LoginScreen() {
  const { signIn, isLoading } = useAuth();

  const handleLogin = async () => {
    await signIn(email, password);
  };
}
```
