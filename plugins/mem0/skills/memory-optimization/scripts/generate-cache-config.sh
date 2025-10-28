#!/bin/bash
# Generate caching configuration for Mem0
# Usage: ./generate-cache-config.sh [cache_type] [ttl_seconds]

CACHE_TYPE="${1:-redis}"
TTL="${2:-300}"

echo "Generating $CACHE_TYPE cache configuration (TTL: ${TTL}s)..."
echo ""

if [ "$CACHE_TYPE" = "redis" ]; then
    cat > cache_config_redis.py << 'PYEOF'
import redis
import json
import hashlib
from typing import Optional, List, Dict, Any
from functools import wraps
from datetime import datetime, timedelta

class Mem0CacheLayer:
    """Redis caching layer for Mem0 operations"""
    
    def __init__(self, host='localhost', port=6379, db=0, default_ttl=300):
        self.redis_client = redis.Redis(
            host=host,
            port=port,
            db=db,
            decode_responses=True
        )
        self.default_ttl = default_ttl
        self.stats = {'hits': 0, 'misses': 0}
    
    def _generate_cache_key(self, query: str, user_id: str = None, 
                           agent_id: str = None, filters: Dict = None) -> str:
        """Generate consistent cache key"""
        key_parts = ['mem0', 'search']
        
        if user_id:
            key_parts.append(f'user:{user_id}')
        if agent_id:
            key_parts.append(f'agent:{agent_id}')
        
        # Hash query and filters
        query_hash = hashlib.md5(query.encode()).hexdigest()[:8]
        key_parts.append(query_hash)
        
        if filters:
            filter_hash = hashlib.md5(json.dumps(filters, sort_keys=True).encode()).hexdigest()[:8]
            key_parts.append(filter_hash)
        
        return ':'.join(key_parts)
    
    def get(self, cache_key: str) -> Optional[List[Dict]]:
        """Get cached results"""
        try:
            cached = self.redis_client.get(cache_key)
            if cached:
                self.stats['hits'] += 1
                return json.loads(cached)
            self.stats['misses'] += 1
            return None
        except Exception as e:
            print(f"Cache get error: {e}")
            return None
    
    def set(self, cache_key: str, value: List[Dict], ttl: int = None):
        """Cache results with TTL"""
        try:
            ttl = ttl or self.default_ttl
            self.redis_client.setex(
                cache_key,
                ttl,
                json.dumps(value)
            )
        except Exception as e:
            print(f"Cache set error: {e}")
    
    def invalidate_user(self, user_id: str):
        """Invalidate all cache entries for a user"""
        pattern = f"mem0:search:user:{user_id}:*"
        for key in self.redis_client.scan_iter(match=pattern):
            self.redis_client.delete(key)
    
    def invalidate_agent(self, agent_id: str):
        """Invalidate all cache entries for an agent"""
        pattern = f"mem0:search:agent:{agent_id}:*"
        for key in self.redis_client.scan_iter(match=pattern):
            self.redis_client.delete(key)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total = self.stats['hits'] + self.stats['misses']
        hit_rate = (self.stats['hits'] / total * 100) if total > 0 else 0
        
        return {
            'hits': self.stats['hits'],
            'misses': self.stats['misses'],
            'hit_rate': f"{hit_rate:.1f}%",
            'total_keys': self.redis_client.dbsize()
        }

# Usage Example
cache = Mem0CacheLayer(default_ttl=TTLSECONDS)

def cached_search(memory, query: str, user_id: str = None, 
                 agent_id: str = None, filters: Dict = None, 
                 limit: int = 5) -> List[Dict]:
    """Cached memory search"""
    
    # Generate cache key
    cache_key = cache._generate_cache_key(query, user_id, agent_id, filters)
    
    # Check cache
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
    
    # Cache result
    cache.set(cache_key, result)
    
    return result

# Invalidation on updates
def add_with_cache_invalidation(memory, message: str, user_id: str = None, **kwargs):
    """Add memory and invalidate cache"""
    result = memory.add(message, user_id=user_id, **kwargs)
    
    # Invalidate user's cache
    if user_id:
        cache.invalidate_user(user_id)
    
    return result

# Print statistics
print(cache.get_stats())
PYEOF
    sed -i "s/TTLSECONDS/$TTL/g" cache_config_redis.py
    echo "✓ Redis cache configuration created: cache_config_redis.py"
    
elif [ "$CACHE_TYPE" = "memory" ]; then
    cat > cache_config_memory.py << 'PYEOF'
from functools import lru_cache, wraps
from typing import Dict, List, Any
import hashlib
import time

class InMemoryCache:
    """Simple in-memory LRU cache for Mem0"""
    
    def __init__(self, maxsize=1000, ttl_seconds=TTLSECONDS):
        self.maxsize = maxsize
        self.ttl_seconds = ttl_seconds
        self.cache = {}
        self.timestamps = {}
        self.stats = {'hits': 0, 'misses': 0}
    
    def _is_expired(self, key: str) -> bool:
        """Check if cache entry is expired"""
        if key not in self.timestamps:
            return True
        age = time.time() - self.timestamps[key]
        return age > self.ttl_seconds
    
    def get(self, key: str) -> Any:
        """Get cached value"""
        if key in self.cache and not self._is_expired(key):
            self.stats['hits'] += 1
            return self.cache[key]
        
        self.stats['misses'] += 1
        if key in self.cache:
            del self.cache[key]
            del self.timestamps[key]
        return None
    
    def set(self, key: str, value: Any):
        """Set cache value"""
        # Evict oldest if at capacity
        if len(self.cache) >= self.maxsize:
            oldest = min(self.timestamps.items(), key=lambda x: x[1])
            del self.cache[oldest[0]]
            del self.timestamps[oldest[0]]
        
        self.cache[key] = value
        self.timestamps[key] = time.time()
    
    def invalidate_pattern(self, pattern: str):
        """Invalidate keys matching pattern"""
        keys_to_delete = [k for k in self.cache.keys() if pattern in k]
        for key in keys_to_delete:
            del self.cache[key]
            del self.timestamps[key]
    
    def get_stats(self) -> Dict:
        """Get cache statistics"""
        total = self.stats['hits'] + self.stats['misses']
        hit_rate = (self.stats['hits'] / total * 100) if total > 0 else 0
        return {
            'hits': self.stats['hits'],
            'misses': self.stats['misses'],
            'hit_rate': f"{hit_rate:.1f}%",
            'size': len(self.cache)
        }

# Global cache instance
memory_cache = InMemoryCache(maxsize=1000, ttl_seconds=TTLSECONDS)

def cached_search(memory, query: str, user_id: str = None, **kwargs):
    """Cache memory search results"""
    # Generate cache key
    cache_key = f"{user_id}:{hashlib.md5(query.encode()).hexdigest()}"
    
    # Check cache
    cached = memory_cache.get(cache_key)
    if cached is not None:
        return cached
    
    # Cache miss
    result = memory.search(query, user_id=user_id, **kwargs)
    memory_cache.set(cache_key, result)
    
    return result

# Usage
# result = cached_search(memory, "user preferences", user_id="user_123")
PYEOF
    sed -i "s/TTLSECONDS/$TTL/g" cache_config_memory.py
    echo "✓ In-memory cache configuration created: cache_config_memory.py"
fi

echo ""
echo "Configuration Details:"
echo "  Cache Type: $CACHE_TYPE"
echo "  TTL: ${TTL} seconds"
echo "  Max Size: 1000 entries"
echo ""
echo "Next Steps:"
echo "  1. Review generated configuration file"
echo "  2. Adjust TTL and size as needed"
echo "  3. Integrate with your Mem0 application"
echo "  4. Monitor cache hit rate"
echo ""
