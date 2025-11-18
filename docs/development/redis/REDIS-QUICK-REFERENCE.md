# Redis Quick Reference

> **Essential commands and patterns for RedAI developers**  
> **Quick lookup guide for common Redis operations**

---

## Table of Contents

1. [Installation](#installation)
2. [Connection](#connection)
3. [Common Commands](#common-commands)
4. [Data Types](#data-types)
5. [Caching Patterns](#caching-patterns)
6. [Session Management](#session-management)
7. [Celery Integration](#celery-integration)
8. [Performance Tips](#performance-tips)

---

## Installation

### Docker (Recommended for RedAI)

```bash
# Pull Redis image
docker pull redis:7-alpine

# Run Redis container
docker run -d \
  --name redis \
  -p 6379:6379 \
  redis:7-alpine redis-server --appendonly yes

# Verify Redis is running
docker exec -it redis redis-cli ping
# Expected output: PONG
```

### Ubuntu/Debian (APT)

```bash
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list
sudo apt-get update
sudo apt-get install redis-stack-server
```

### Python Client

```bash
pip install redis
```

---

## Connection

### Python (redis-py)

```python
import redis
from redis import ConnectionPool

# Simple connection
r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

# Connection pool (recommended)
pool = ConnectionPool(
    host='localhost',
    port=6379,
    db=0,
    max_connections=50,
    decode_responses=True
)
redis_client = redis.Redis(connection_pool=pool)

# Test connection
redis_client.ping()  # True if connected

# With password
r = redis.Redis(
    host='localhost',
    port=6379,
    password='your_password',
    db=0
)

# From URL
redis_url = "redis://localhost:6379/0"
r = redis.from_url(redis_url)
```

---

## Common Commands

### Key Operations

```bash
# Set a key
SET mykey "Hello"

# Get a key
GET mykey

# Check if key exists
EXISTS mykey

# Delete a key
DEL mykey

# Set key with expiration (seconds)
SET mykey "value" EX 3600

# Set key with expiration (milliseconds)
SET mykey "value" PX 3600000

# Set expiration on existing key
EXPIRE mykey 3600

# Get time to live
TTL mykey

# Remove expiration
PERSIST mykey

# Get all keys (use with caution in production!)
KEYS *

# Scan keys (better for production)
SCAN 0 MATCH user:* COUNT 100

# Get type of key
TYPE mykey

# Rename key
RENAME old_key new_key
```

### Python Examples

```python
# Set and get
redis_client.set('mykey', 'Hello')
value = redis_client.get('mykey')  # 'Hello'

# Set with expiration
redis_client.setex('session:123', 3600, 'user_data')

# Check existence
redis_client.exists('mykey')  # 1 if exists, 0 if not

# Delete
redis_client.delete('mykey')

# Multiple operations
redis_client.mset({'key1': 'value1', 'key2': 'value2'})
values = redis_client.mget('key1', 'key2')  # ['value1', 'value2']

# Increment
redis_client.set('counter', 0)
redis_client.incr('counter')  # 1
redis_client.incrby('counter', 5)  # 6

# Decrement
redis_client.decr('counter')  # 5
redis_client.decrby('counter', 3)  # 2
```

---

## Data Types

### Strings

```python
# Set string
redis_client.set('username', 'john_doe')

# Get string
username = redis_client.get('username')

# Append to string
redis_client.append('message', ' World')

# Get length
length = redis_client.strlen('message')

# Set if not exists
redis_client.setnx('lock:resource', 'locked')

# Get and set
old_value = redis_client.getset('counter', 0)
```

### Hashes (Dictionaries)

```python
# Set hash field
redis_client.hset('user:1000', 'name', 'John Doe')
redis_client.hset('user:1000', 'email', 'john@example.com')

# Set multiple fields
redis_client.hset('user:1000', mapping={
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30
})

# Get hash field
name = redis_client.hget('user:1000', 'name')

# Get all fields and values
user = redis_client.hgetall('user:1000')
# {'name': 'John Doe', 'email': 'john@example.com', 'age': '30'}

# Get multiple fields
fields = redis_client.hmget('user:1000', 'name', 'email')

# Check if field exists
redis_client.hexists('user:1000', 'age')

# Delete field
redis_client.hdel('user:1000', 'age')

# Get all keys
keys = redis_client.hkeys('user:1000')

# Get all values
values = redis_client.hvals('user:1000')

# Get number of fields
count = redis_client.hlen('user:1000')

# Increment field
redis_client.hincrby('user:1000', 'login_count', 1)
```

### Lists (Queues)

```python
# Push to left (front)
redis_client.lpush('tasks', 'task1', 'task2', 'task3')

# Push to right (back)
redis_client.rpush('tasks', 'task4')

# Pop from left
task = redis_client.lpop('tasks')

# Pop from right
task = redis_client.rpop('tasks')

# Blocking pop (wait until element available)
task = redis_client.blpop('tasks', timeout=5)

# Get list length
length = redis_client.llen('tasks')

# Get range
tasks = redis_client.lrange('tasks', 0, -1)  # All elements

# Get specific element
task = redis_client.lindex('tasks', 0)

# Trim list
redis_client.ltrim('tasks', 0, 99)  # Keep first 100 elements
```

### Sets (Unique Collections)

```python
# Add members
redis_client.sadd('tags', 'python', 'redis', 'fastapi')

# Get all members
tags = redis_client.smembers('tags')

# Check membership
redis_client.sismember('tags', 'python')  # True

# Remove member
redis_client.srem('tags', 'python')

# Get count
count = redis_client.scard('tags')

# Pop random member
tag = redis_client.spop('tags')

# Get random member (without removing)
tag = redis_client.srandmember('tags')

# Set operations
redis_client.sadd('set1', 'a', 'b', 'c')
redis_client.sadd('set2', 'b', 'c', 'd')

union = redis_client.sunion('set1', 'set2')  # {'a', 'b', 'c', 'd'}
intersection = redis_client.sinter('set1', 'set2')  # {'b', 'c'}
difference = redis_client.sdiff('set1', 'set2')  # {'a'}
```

### Sorted Sets (Leaderboards)

```python
# Add members with scores
redis_client.zadd('leaderboard', {
    'player1': 100,
    'player2': 200,
    'player3': 150
})

# Get rank (0-based, lowest score first)
rank = redis_client.zrank('leaderboard', 'player2')

# Get reverse rank (highest score first)
rank = redis_client.zrevrank('leaderboard', 'player2')

# Get score
score = redis_client.zscore('leaderboard', 'player2')

# Get range by rank
top_players = redis_client.zrange('leaderboard', 0, 9, withscores=True)

# Get range by score
players = redis_client.zrangebyscore('leaderboard', 100, 200, withscores=True)

# Get reverse range (highest to lowest)
top_players = redis_client.zrevrange('leaderboard', 0, 9, withscores=True)

# Increment score
redis_client.zincrby('leaderboard', 50, 'player1')

# Remove member
redis_client.zrem('leaderboard', 'player1')

# Get count
count = redis_client.zcard('leaderboard')
```

### JSON (RedisJSON module)

```python
import redis
import json

# Set JSON
redis_client.execute_command('JSON.SET', 'user:1000', '$', json.dumps({
    'name': 'John Doe',
    'email': 'john@example.com',
    'settings': {
        'theme': 'dark',
        'notifications': True
    }
}))

# Get JSON
user_json = redis_client.execute_command('JSON.GET', 'user:1000')
user = json.loads(user_json)

# Get specific path
theme = redis_client.execute_command('JSON.GET', 'user:1000', '$.settings.theme')

# Update field
redis_client.execute_command('JSON.SET', 'user:1000', '$.settings.theme', '"light"')
```

---

## Caching Patterns

### Simple Cache

```python
import json
from functools import wraps
from typing import Any, Callable

def cache_result(ttl: int = 3600):
    """Cache function result in Redis"""
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            # Create cache key
            cache_key = f"cache:{func.__name__}:{args}:{kwargs}"

            # Try to get from cache
            cached = redis_client.get(cache_key)
            if cached:
                return json.loads(cached)

            # Execute function
            result = func(*args, **kwargs)

            # Cache result
            redis_client.setex(
                cache_key,
                ttl,
                json.dumps(result)
            )

            return result
        return wrapper
    return decorator

# Usage
@cache_result(ttl=300)
def get_exam_questions(exam_id: int):
    # Expensive database query
    return query_database(exam_id)
```

### Cache-Aside Pattern

```python
def get_user(user_id: int):
    cache_key = f"user:{user_id}"

    # 1. Try cache first
    cached_user = redis_client.get(cache_key)
    if cached_user:
        return json.loads(cached_user)

    # 2. Cache miss - query database
    user = database.query(User).filter_by(id=user_id).first()
    if not user:
        return None

    # 3. Update cache
    redis_client.setex(
        cache_key,
        3600,  # 1 hour TTL
        json.dumps(user.to_dict())
    )

    return user
```

### Cache Invalidation

```python
def update_user(user_id: int, data: dict):
    # 1. Update database
    user = database.query(User).filter_by(id=user_id).first()
    user.update(data)
    database.commit()

    # 2. Invalidate cache
    cache_key = f"user:{user_id}"
    redis_client.delete(cache_key)

    # Or update cache immediately
    redis_client.setex(cache_key, 3600, json.dumps(user.to_dict()))
```

### Cache Warming

```python
def warm_cache():
    """Preload frequently accessed data"""
    popular_exams = database.query(Exam).filter_by(is_popular=True).all()

    for exam in popular_exams:
        cache_key = f"exam:{exam.id}"
        redis_client.setex(
            cache_key,
            7200,  # 2 hours
            json.dumps(exam.to_dict())
        )
```

---

## Session Management

### Session Storage

```python
import secrets
from datetime import timedelta

class RedisSessionManager:
    def __init__(self, redis_client, session_ttl: int = 86400):
        self.redis = redis_client
        self.session_ttl = session_ttl

    def create_session(self, user_id: int, user_data: dict) -> str:
        """Create new session"""
        session_id = secrets.token_urlsafe(32)
        session_key = f"session:{session_id}"

        session_data = {
            'user_id': user_id,
            **user_data
        }

        self.redis.setex(
            session_key,
            self.session_ttl,
            json.dumps(session_data)
        )

        return session_id

    def get_session(self, session_id: str) -> dict | None:
        """Get session data"""
        session_key = f"session:{session_id}"
        session_data = self.redis.get(session_key)

        if not session_data:
            return None

        # Refresh TTL on access
        self.redis.expire(session_key, self.session_ttl)

        return json.loads(session_data)

    def update_session(self, session_id: str, data: dict):
        """Update session data"""
        session_key = f"session:{session_id}"
        existing = self.get_session(session_id)

        if existing:
            existing.update(data)
            self.redis.setex(
                session_key,
                self.session_ttl,
                json.dumps(existing)
            )

    def delete_session(self, session_id: str):
        """Delete session (logout)"""
        session_key = f"session:{session_id}"
        self.redis.delete(session_key)

# Usage
session_manager = RedisSessionManager(redis_client, session_ttl=86400)

# Create session on login
session_id = session_manager.create_session(
    user_id=123,
    user_data={'email': 'user@example.com', 'role': 'student'}
)

# Get session
session = session_manager.get_session(session_id)

# Logout
session_manager.delete_session(session_id)
```

---

## Celery Integration

### Celery Configuration

```python
# backend/config/celery_config.py

# Redis as broker and result backend
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_RESULT_BACKEND = "redis://localhost:6379/1"

# Celery task serialization
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_ACCEPT_CONTENT = ['json']

# Task result expiration
CELERY_RESULT_EXPIRES = 3600

# Connection pool settings
BROKER_POOL_LIMIT = 10
BROKER_CONNECTION_MAX_RETRIES = 10

# Redis backend settings
CELERY_REDIS_MAX_CONNECTIONS = 50
```

### Monitor Celery Queue

```python
# Check queue length
queue_length = redis_client.llen('celery')

# View pending tasks
tasks = redis_client.lrange('celery', 0, -1)

# Get task result
task_id = "abc123..."
result_key = f"celery-task-meta-{task_id}"
result = redis_client.get(result_key)
```

---

## Performance Tips

### Connection Pooling

```python
# Use connection pool for better performance
pool = ConnectionPool(
    host='localhost',
    port=6379,
    max_connections=50,
    decode_responses=True
)
redis_client = redis.Redis(connection_pool=pool)
```

### Pipeline for Multiple Commands

```python
# Execute multiple commands in one round-trip
pipe = redis_client.pipeline()
pipe.set('key1', 'value1')
pipe.set('key2', 'value2')
pipe.get('key1')
pipe.get('key2')
results = pipe.execute()  # ['OK', 'OK', 'value1', 'value2']
```

### Use SCAN Instead of KEYS

```python
# Bad (blocks Redis for large key sets)
keys = redis_client.keys('user:*')

# Good (iterates without blocking)
cursor = 0
keys = []
while True:
    cursor, partial_keys = redis_client.scan(
        cursor,
        match='user:*',
        count=100
    )
    keys.extend(partial_keys)
    if cursor == 0:
        break
```

### Set Appropriate TTLs

```python
# Short-lived cache (API responses)
redis_client.setex('api:result', 300, data)  # 5 minutes

# Medium-lived cache (user profiles)
redis_client.setex('user:profile', 3600, data)  # 1 hour

# Long-lived cache (static content)
redis_client.setex('content:static', 86400, data)  # 24 hours
```

### Rate Limiting (Sliding Window)

```python
def rate_limit(user_id: int, max_requests: int = 100, window: int = 60) -> bool:
    """
    Rate limiting with sliding window
    Returns True if request is allowed
    """
    key = f"rate_limit:{user_id}"
    current_time = int(time.time())

    # Remove old entries
    redis_client.zremrangebyscore(key, 0, current_time - window)

    # Count requests in window
    request_count = redis_client.zcard(key)

    if request_count >= max_requests:
        return False

    # Add current request
    redis_client.zadd(key, {str(current_time): current_time})
    redis_client.expire(key, window)

    return True

# Usage
if not rate_limit(user_id=123, max_requests=100, window=60):
    raise HTTPException(status_code=429, detail="Rate limit exceeded")
```

### Distributed Lock

```python
import time
import uuid

class RedisLock:
    def __init__(self, redis_client, lock_name: str, timeout: int = 10):
        self.redis = redis_client
        self.lock_name = f"lock:{lock_name}"
        self.timeout = timeout
        self.identifier = str(uuid.uuid4())

    def acquire(self) -> bool:
        """Acquire lock"""
        return self.redis.set(
            self.lock_name,
            self.identifier,
            nx=True,
            ex=self.timeout
        )

    def release(self):
        """Release lock"""
        # Verify we own the lock before releasing
        pipe = self.redis.pipeline(True)
        while True:
            try:
                pipe.watch(self.lock_name)
                lock_value = pipe.get(self.lock_name)

                if lock_value and lock_value.decode() == self.identifier:
                    pipe.multi()
                    pipe.delete(self.lock_name)
                    pipe.execute()
                    return True

                pipe.unwatch()
                break
            except redis.WatchError:
                pass

        return False

    def __enter__(self):
        while not self.acquire():
            time.sleep(0.1)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()

# Usage
with RedisLock(redis_client, 'generate_questions'):
    # Critical section - only one process can execute
    generate_batch_questions()
```

---

## CLI Commands

### Start Redis CLI

```bash
redis-cli

# With authentication
redis-cli -a password

# Connect to specific host/port
redis-cli -h 127.0.0.1 -p 6379

# Select database
redis-cli -n 1
```

### Useful CLI Commands

```bash
# Monitor all commands in real-time
MONITOR

# Get server info
INFO

# Get memory usage
INFO MEMORY

# Get stats
INFO STATS

# Get connected clients
CLIENT LIST

# Flush current database
FLUSHDB

# Flush all databases (DANGEROUS!)
FLUSHALL

# Save database to disk
SAVE

# Background save
BGSAVE

# Get configuration
CONFIG GET *

# Set configuration
CONFIG SET maxmemory 2gb

# Shutdown server
SHUTDOWN
```

---

## Common Patterns Summary

### Caching

```python
redis_client.setex('cache:key', 3600, json.dumps(data))
```

### Session

```python
redis_client.setex(f'session:{session_id}', 86400, json.dumps(session_data))
```

### Queue

```python
redis_client.lpush('queue:tasks', task_data)
task = redis_client.brpop('queue:tasks', timeout=5)
```

### Counter

```python
redis_client.incr('counter:visits')
```

### Rate Limiting

```python
redis_client.incr(f'rate:{user_id}')
redis_client.expire(f'rate:{user_id}', 60)
```

### Distributed Lock

```python
redis_client.set('lock:resource', 'locked', nx=True, ex=10)
```

---

**See Also:**

- [REDIS-COMPREHENSIVE-DOCUMENTATION.md](./REDIS-COMPREHENSIVE-DOCUMENTATION.md) - Complete reference
- [REDIS-IMPLEMENTATION-CHECKLIST.md](./REDIS-IMPLEMENTATION-CHECKLIST.md) - Integration guide
