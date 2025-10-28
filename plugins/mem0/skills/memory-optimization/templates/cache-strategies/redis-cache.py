"""
Production Redis caching layer for Mem0
Implements intelligent caching with TTL, invalidation, and monitoring
"""

import redis
import json
import hashlib
from typing import Optional, List, Dict, Any, Callable
from functools import wraps
from datetime import datetime
import time

class Mem0RedisCache:
    """Enterprise-grade Redis caching for Mem0"""

    def __init__(
        self,
        host: str = 'localhost',
        port: int = 6379,
        db: int = 0,
        password: Optional[str] = None,
        default_ttl: int = 300,  # 5 minutes
        key_prefix: str = 'mem0'
    ):
        self.redis_client = redis.Redis(
            host=host,
            port=port,
            db=db,
            password=password,
            decode_responses=True,
            socket_connect_timeout=5,
            socket_keepalive=True,
        )
        self.default_ttl = default_ttl
        self.key_prefix = key_prefix
        self.stats = {
            'hits': 0,
            'misses': 0,
            'sets': 0,
            'invalidations': 0
        }

    def _generate_key(
        self,
        query: str,
        user_id: Optional[str] = None,
        agent_id: Optional[str] = None,
        filters: Optional[Dict] = None,
        limit: int = 10
    ) -> str:
        """Generate consistent cache key"""
        parts = [self.key_prefix, 'search']

        if user_id:
            parts.append(f'u:{user_id}')
        if agent_id:
            parts.append(f'a:{agent_id}')

        # Hash query for consistent key
        query_hash = hashlib.sha256(query.encode()).hexdigest()[:16]
        parts.append(query_hash)

        # Include filters and limit in key
        if filters:
            filter_str = json.dumps(filters, sort_keys=True)
            filter_hash = hashlib.md5(filter_str.encode()).hexdigest()[:8]
            parts.append(filter_hash)

        parts.append(f'l:{limit}')

        return ':'.join(parts)

    def get(self, cache_key: str) -> Optional[List[Dict]]:
        """Get cached search results"""
        try:
            cached = self.redis_client.get(cache_key)
            if cached:
                self.stats['hits'] += 1
                return json.loads(cached)

            self.stats['misses'] += 1
            return None

        except redis.RedisError as e:
            print(f"Redis get error: {e}")
            self.stats['misses'] += 1
            return None

    def set(
        self,
        cache_key: str,
        value: List[Dict],
        ttl: Optional[int] = None
    ) -> bool:
        """Cache search results with TTL"""
        try:
            ttl = ttl or self.default_ttl
            self.redis_client.setex(
                cache_key,
                ttl,
                json.dumps(value)
            )
            self.stats['sets'] += 1
            return True

        except redis.RedisError as e:
            print(f"Redis set error: {e}")
            return False

    def invalidate_user(self, user_id: str) -> int:
        """Invalidate all cache for a specific user"""
        pattern = f"{self.key_prefix}:search:u:{user_id}:*"
        count = 0

        try:
            for key in self.redis_client.scan_iter(match=pattern, count=100):
                self.redis_client.delete(key)
                count += 1

            self.stats['invalidations'] += count
            return count

        except redis.RedisError as e:
            print(f"Redis invalidation error: {e}")
            return 0

    def invalidate_agent(self, agent_id: str) -> int:
        """Invalidate all cache for a specific agent"""
        pattern = f"{self.key_prefix}:search:a:{agent_id}:*"
        count = 0

        try:
            for key in self.redis_client.scan_iter(match=pattern, count=100):
                self.redis_client.delete(key)
                count += 1

            self.stats['invalidations'] += count
            return count

        except redis.RedisError as e:
            print(f"Redis invalidation error: {e}")
            return 0

    def invalidate_all(self) -> int:
        """Clear all Mem0 cache entries"""
        pattern = f"{self.key_prefix}:*"
        count = 0

        try:
            for key in self.redis_client.scan_iter(match=pattern, count=100):
                self.redis_client.delete(key)
                count += 1

            self.stats['invalidations'] += count
            return count

        except redis.RedisError as e:
            print(f"Redis flush error: {e}")
            return 0

    def get_stats(self) -> Dict[str, Any]:
        """Get cache performance statistics"""
        total_requests = self.stats['hits'] + self.stats['misses']
        hit_rate = (self.stats['hits'] / total_requests * 100) if total_requests > 0 else 0

        try:
            cache_size = self.redis_client.dbsize()
            memory_info = self.redis_client.info('memory')
            memory_used = memory_info.get('used_memory_human', 'N/A')
        except:
            cache_size = 0
            memory_used = 'N/A'

        return {
            'hits': self.stats['hits'],
            'misses': self.stats['misses'],
            'hit_rate': f"{hit_rate:.2f}%",
            'sets': self.stats['sets'],
            'invalidations': self.stats['invalidations'],
            'total_keys': cache_size,
            'memory_used': memory_used,
        }

    def reset_stats(self):
        """Reset statistics counters"""
        self.stats = {
            'hits': 0,
            'misses': 0,
            'sets': 0,
            'invalidations': 0
        }

# Global cache instance
cache = Mem0RedisCache(default_ttl=300)

def cached_search(
    memory,
    query: str,
    user_id: Optional[str] = None,
    agent_id: Optional[str] = None,
    run_id: Optional[str] = None,
    filters: Optional[Dict] = None,
    limit: int = 5,
    ttl: Optional[int] = None,
    force_refresh: bool = False
) -> List[Dict]:
    """
    Cached memory search with automatic invalidation

    Args:
        memory: Mem0 Memory instance
        query: Search query
        user_id: User identifier
        agent_id: Agent identifier
        run_id: Session/run identifier (not cached)
        filters: Additional search filters
        limit: Maximum results
        ttl: Custom TTL in seconds (None = use default)
        force_refresh: Skip cache and refresh

    Returns:
        List of memory results
    """

    # Don't cache session-specific queries
    if run_id:
        return memory.search(
            query,
            user_id=user_id,
            agent_id=agent_id,
            run_id=run_id,
            filters=filters,
            limit=limit
        )

    # Generate cache key
    cache_key = cache._generate_key(query, user_id, agent_id, filters, limit)

    # Check cache (unless force refresh)
    if not force_refresh:
        cached_result = cache.get(cache_key)
        if cached_result is not None:
            return cached_result

    # Cache miss - query Mem0
    result = memory.search(
        query,
        user_id=user_id,
        agent_id=agent_id,
        filters=filters,
        limit=limit
    )

    # Cache the result
    cache.set(cache_key, result, ttl)

    return result

def cached_add(
    memory,
    messages,
    user_id: Optional[str] = None,
    agent_id: Optional[str] = None,
    **kwargs
):
    """Add memory and invalidate related cache"""

    result = memory.add(messages, user_id=user_id, agent_id=agent_id, **kwargs)

    # Invalidate caches
    if user_id:
        cache.invalidate_user(user_id)
    if agent_id:
        cache.invalidate_agent(agent_id)

    return result

def cached_update(memory, memory_id: str, data: Dict):
    """Update memory and invalidate cache"""

    result = memory.update(memory_id, data)

    # Get memory details to invalidate specific caches
    # In practice, you'd fetch user_id/agent_id from memory
    # For now, invalidate all
    cache.invalidate_all()

    return result

def cached_delete(memory, memory_id: str):
    """Delete memory and invalidate cache"""

    result = memory.delete(memory_id)

    # Invalidate all since we don't know which user/agent
    cache.invalidate_all()

    return result

# Decorator for automatic caching
def mem0_cache(ttl: int = 300):
    """Decorator to cache function results"""

    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Generate cache key from function name and args
            key_data = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            cache_key = f"{cache.key_prefix}:func:{hashlib.md5(key_data.encode()).hexdigest()}"

            # Check cache
            cached = cache.get(cache_key)
            if cached is not None:
                return cached

            # Call function
            result = func(*args, **kwargs)

            # Cache result
            cache.set(cache_key, result, ttl)

            return result

        return wrapper
    return decorator

# Example usage with different TTLs
@mem0_cache(ttl=900)  # 15 minutes
def get_user_preferences(user_id: str):
    """Long-lived cache for stable preferences"""
    return cached_search(memory, "preferences", user_id=user_id, limit=3)

@mem0_cache(ttl=60)  # 1 minute
def get_recent_context(user_id: str):
    """Short-lived cache for recent interactions"""
    return cached_search(memory, "recent context", user_id=user_id, limit=5)
