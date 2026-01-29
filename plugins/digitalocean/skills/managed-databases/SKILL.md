---
name: managed-databases
description: DigitalOcean Managed Database provisioning and connection patterns
---

# Managed Databases Skill

## PostgreSQL

### Provisioning

```bash
# Create production cluster
doctl databases create prod-pg \
  --engine pg \
  --version 16 \
  --region nyc1 \
  --size db-s-2vcpu-4gb \
  --num-nodes 2 \
  --private-network-uuid <vpc-id>
```

### Connection Patterns

**Node.js (pg):**

```typescript
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: true,
    ca: process.env.DATABASE_CA_CERT,
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Query
const { rows } = await pool.query('SELECT * FROM users WHERE id = $1', [id]);

// Transaction
const client = await pool.connect();
try {
  await client.query('BEGIN');
  await client.query('INSERT INTO users(name) VALUES($1)', ['John']);
  await client.query('COMMIT');
} catch (e) {
  await client.query('ROLLBACK');
  throw e;
} finally {
  client.release();
}
```

**Python (psycopg2):**

```python
import psycopg2
from psycopg2.extras import RealDictCursor

conn = psycopg2.connect(
    os.environ['DATABASE_URL'],
    sslmode='require',
    sslrootcert='ca-certificate.crt',
    cursor_factory=RealDictCursor
)

with conn.cursor() as cur:
    cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cur.fetchone()
```

**Prisma:**

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

**Drizzle:**

```typescript
import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: true },
});

export const db = drizzle(pool);
```

### Connection Pooling

```bash
# Create connection pool
doctl databases pool create <cluster-id> app-pool \
  --db myapp_production \
  --user app_user \
  --mode transaction \
  --size 25
```

## Redis/Valkey

### Provisioning

```bash
doctl databases create prod-cache \
  --engine valkey \
  --version 7 \
  --region nyc1 \
  --size db-s-1vcpu-2gb \
  --num-nodes 1
```

### Connection Patterns

**Node.js (ioredis):**

```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL, {
  tls: { rejectUnauthorized: true },
  maxRetriesPerRequest: 3,
  retryDelayOnFailover: 100,
});

// String operations
await redis.set('key', 'value', 'EX', 3600);
const value = await redis.get('key');

// Hash operations
await redis.hset('user:1', { name: 'John', email: 'john@example.com' });
const user = await redis.hgetall('user:1');

// Pub/Sub
redis.subscribe('events');
redis.on('message', (channel, message) => {
  console.log(channel, message);
});

// Caching pattern
async function getCached<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttl = 3600
): Promise<T> {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  const data = await fetcher();
  await redis.set(key, JSON.stringify(data), 'EX', ttl);
  return data;
}
```

**Python (redis-py):**

```python
import redis

r = redis.Redis.from_url(
    os.environ['REDIS_URL'],
    ssl_cert_reqs='required',
    decode_responses=True
)

r.set('key', 'value', ex=3600)
value = r.get('key')
```

## MongoDB

### Provisioning

```bash
doctl databases create prod-mongo \
  --engine mongodb \
  --version 7 \
  --region nyc1 \
  --size db-s-2vcpu-4gb \
  --num-nodes 3
```

### Connection Patterns

**Node.js:**

```typescript
import { MongoClient } from 'mongodb';

const client = new MongoClient(process.env.MONGODB_URL, {
  tls: true,
  tlsCAFile: 'ca-certificate.crt',
});

await client.connect();
const db = client.db('myapp');
const users = db.collection('users');

// CRUD
await users.insertOne({ name: 'John', email: 'john@example.com' });
const user = await users.findOne({ email: 'john@example.com' });
await users.updateOne({ _id: user._id }, { $set: { name: 'Jane' } });
await users.deleteOne({ _id: user._id });

// Aggregation
const results = await users
  .aggregate([
    { $match: { status: 'active' } },
    { $group: { _id: '$role', count: { $sum: 1 } } },
  ])
  .toArray();
```

## MySQL

### Provisioning

```bash
doctl databases create prod-mysql \
  --engine mysql \
  --version 8 \
  --region nyc1 \
  --size db-s-2vcpu-4gb \
  --num-nodes 2
```

### Connection Patterns

**Node.js (mysql2):**

```typescript
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  uri: process.env.DATABASE_URL,
  ssl: { ca: process.env.DATABASE_CA_CERT },
  waitForConnections: true,
  connectionLimit: 10,
});

const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [id]);
```

## Kafka

### Provisioning

```bash
doctl databases create prod-kafka \
  --engine kafka \
  --version 3.6 \
  --region nyc1 \
  --size db-s-2vcpu-4gb \
  --num-nodes 3
```

### Connection Patterns

**Node.js (kafkajs):**

```typescript
import { Kafka } from 'kafkajs';

const kafka = new Kafka({
  clientId: 'my-app',
  brokers: [process.env.KAFKA_BROKER],
  ssl: { ca: [process.env.KAFKA_CA_CERT] },
  sasl: {
    mechanism: 'scram-sha-256',
    username: process.env.KAFKA_USERNAME,
    password: process.env.KAFKA_PASSWORD,
  },
});

// Producer
const producer = kafka.producer();
await producer.connect();
await producer.send({
  topic: 'events',
  messages: [
    { key: 'key', value: JSON.stringify({ type: 'user.created', data: {} }) },
  ],
});

// Consumer
const consumer = kafka.consumer({ groupId: 'my-group' });
await consumer.connect();
await consumer.subscribe({ topic: 'events', fromBeginning: true });
await consumer.run({
  eachMessage: async ({ topic, partition, message }) => {
    console.log(JSON.parse(message.value.toString()));
  },
});
```

## Database Sizing Guide

| Use Case          | PostgreSQL      | Redis          | MongoDB         |
| ----------------- | --------------- | -------------- | --------------- |
| Development       | db-s-1vcpu-1gb  | db-s-1vcpu-1gb | db-s-1vcpu-1gb  |
| Small Production  | db-s-2vcpu-4gb  | db-s-1vcpu-2gb | db-s-2vcpu-4gb  |
| Medium Production | db-s-4vcpu-8gb  | db-s-2vcpu-4gb | db-s-4vcpu-8gb  |
| High Traffic      | db-s-8vcpu-16gb | db-s-4vcpu-8gb | db-s-8vcpu-16gb |
