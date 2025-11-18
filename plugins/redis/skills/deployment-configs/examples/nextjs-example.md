# Next.js Redis Example

## Redis Client

```typescript
// lib/redis.ts
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL!);

export default redis;
```

## API Route

```typescript
// app/api/cache/route.ts
import redis from '@/lib/redis';
import { NextResponse } from 'next/server';

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const key = searchParams.get('key');
  
  const value = await redis.get(key!);
  return NextResponse.json({ value });
}

export async function POST(request: Request) {
  const { key, value } = await request.json();
  await redis.set(key, value, 'EX', 3600);
  return NextResponse.json({ status: 'ok' });
}
```
