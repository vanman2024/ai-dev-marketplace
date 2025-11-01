"""
Embedding Cache Example

Avoid redundant API calls by caching embeddings with LRU and persistent storage.
"""

import hashlib
import json
import pickle
from pathlib import Path
from typing import List, Dict, Optional, Any
from functools import lru_cache
import time


class EmbeddingCache:
    """
    Cache embeddings to avoid redundant API calls.

    Features:
    - In-memory LRU cache for fast access
    - Persistent disk cache for long-term storage
    - Content-based hashing for cache keys
    - Automatic cache invalidation
    - Cache statistics and monitoring
    """

    def __init__(
        self,
        embedder,
        cache_dir: str = ".embedding_cache",
        max_memory_size: int = 10000,
        use_disk_cache: bool = True,
        ttl_seconds: Optional[int] = None
    ):
        """
        Initialize embedding cache.

        Args:
            embedder: Embedding model instance
            cache_dir: Directory for disk cache
            max_memory_size: Maximum number of embeddings in memory
            use_disk_cache: Whether to use persistent disk cache
            ttl_seconds: Time-to-live for cache entries (None = no expiration)
        """
        self.embedder = embedder
        self.cache_dir = Path(cache_dir)
        self.max_memory_size = max_memory_size
        self.use_disk_cache = use_disk_cache
        self.ttl_seconds = ttl_seconds

        # In-memory cache
        self.memory_cache: Dict[str, tuple] = {}  # hash -> (embedding, timestamp)

        # Cache statistics
        self.stats = {
            'hits': 0,
            'misses': 0,
            'api_calls': 0,
            'total_requests': 0
        }

        if self.use_disk_cache:
            self.cache_dir.mkdir(parents=True, exist_ok=True)

    def _hash_text(self, text: str) -> str:
        """Generate hash for text content."""
        return hashlib.sha256(text.encode('utf-8')).hexdigest()

    def _is_valid(self, timestamp: float) -> bool:
        """Check if cache entry is still valid."""
        if self.ttl_seconds is None:
            return True
        return (time.time() - timestamp) < self.ttl_seconds

    def _get_from_memory(self, text_hash: str) -> Optional[List[float]]:
        """Get embedding from memory cache."""
        if text_hash in self.memory_cache:
            embedding, timestamp = self.memory_cache[text_hash]
            if self._is_valid(timestamp):
                self.stats['hits'] += 1
                return embedding
            else:
                # Expired, remove from cache
                del self.memory_cache[text_hash]
        return None

    def _get_from_disk(self, text_hash: str) -> Optional[List[float]]:
        """Get embedding from disk cache."""
        if not self.use_disk_cache:
            return None

        cache_file = self.cache_dir / f"{text_hash}.pkl"
        if not cache_file.exists():
            return None

        try:
            with open(cache_file, 'rb') as f:
                data = pickle.load(f)
                embedding = data['embedding']
                timestamp = data['timestamp']

                if self._is_valid(timestamp):
                    # Add to memory cache
                    self._add_to_memory(text_hash, embedding, timestamp)
                    self.stats['hits'] += 1
                    return embedding
                else:
                    # Expired, remove from disk
                    cache_file.unlink()
                    return None

        except Exception as e:
            print(f"Error reading cache file: {e}")
            return None

    def _add_to_memory(self, text_hash: str, embedding: List[float], timestamp: float):
        """Add embedding to memory cache with LRU eviction."""
        # Evict oldest if at capacity
        if len(self.memory_cache) >= self.max_memory_size:
            # Remove oldest entry
            oldest_hash = min(
                self.memory_cache.keys(),
                key=lambda h: self.memory_cache[h][1]
            )
            del self.memory_cache[oldest_hash]

        self.memory_cache[text_hash] = (embedding, timestamp)

    def _add_to_disk(self, text_hash: str, embedding: List[float], timestamp: float):
        """Add embedding to disk cache."""
        if not self.use_disk_cache:
            return

        cache_file = self.cache_dir / f"{text_hash}.pkl"
        data = {
            'embedding': embedding,
            'timestamp': timestamp
        }

        try:
            with open(cache_file, 'wb') as f:
                pickle.dump(data, f)
        except Exception as e:
            print(f"Error writing cache file: {e}")

    def get_embedding(self, text: str) -> List[float]:
        """
        Get embedding for text, using cache if available.

        Args:
            text: Text to embed

        Returns:
            Embedding vector
        """
        self.stats['total_requests'] += 1
        text_hash = self._hash_text(text)

        # Try memory cache
        embedding = self._get_from_memory(text_hash)
        if embedding is not None:
            return embedding

        # Try disk cache
        embedding = self._get_from_disk(text_hash)
        if embedding is not None:
            return embedding

        # Cache miss - generate embedding
        self.stats['misses'] += 1
        self.stats['api_calls'] += 1

        embedding = self.embedder.embed_single(text)
        timestamp = time.time()

        # Add to caches
        self._add_to_memory(text_hash, embedding, timestamp)
        self._add_to_disk(text_hash, embedding, timestamp)

        return embedding

    def get_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """
        Get embeddings for multiple texts, using cache when possible.

        Args:
            texts: List of texts to embed

        Returns:
            List of embedding vectors
        """
        embeddings = []
        uncached_texts = []
        uncached_indices = []

        # Check cache for each text
        for i, text in enumerate(texts):
            self.stats['total_requests'] += 1
            text_hash = self._hash_text(text)

            # Try memory then disk
            embedding = self._get_from_memory(text_hash)
            if embedding is None:
                embedding = self._get_from_disk(text_hash)

            if embedding is not None:
                embeddings.append(embedding)
            else:
                # Need to generate this one
                uncached_texts.append(text)
                uncached_indices.append(i)
                embeddings.append(None)  # Placeholder

        # Generate embeddings for uncached texts
        if uncached_texts:
            self.stats['misses'] += len(uncached_texts)
            self.stats['api_calls'] += 1  # One batch API call

            new_embeddings = self.embedder.embed(uncached_texts)
            timestamp = time.time()

            # Add to cache and fill in results
            for text, embedding, idx in zip(uncached_texts, new_embeddings, uncached_indices):
                text_hash = self._hash_text(text)
                self._add_to_memory(text_hash, embedding, timestamp)
                self._add_to_disk(text_hash, embedding, timestamp)
                embeddings[idx] = embedding

        return embeddings

    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics."""
        total = self.stats['total_requests']
        hits = self.stats['hits']
        hit_rate = (hits / total * 100) if total > 0 else 0

        return {
            **self.stats,
            'hit_rate': hit_rate,
            'memory_cache_size': len(self.memory_cache),
            'disk_cache_size': len(list(self.cache_dir.glob('*.pkl'))) if self.use_disk_cache else 0
        }

    def clear_cache(self, clear_disk: bool = False):
        """
        Clear cache.

        Args:
            clear_disk: Whether to also clear disk cache
        """
        self.memory_cache.clear()

        if clear_disk and self.use_disk_cache:
            for cache_file in self.cache_dir.glob('*.pkl'):
                cache_file.unlink()

        print("Cache cleared")

    def print_stats(self):
        """Print cache statistics."""
        stats = self.get_stats()
        print("\n=== Embedding Cache Statistics ===")
        print(f"Total Requests: {stats['total_requests']}")
        print(f"Cache Hits: {stats['hits']}")
        print(f"Cache Misses: {stats['misses']}")
        print(f"Hit Rate: {stats['hit_rate']:.1f}%")
        print(f"API Calls: {stats['api_calls']}")
        print(f"Memory Cache Size: {stats['memory_cache_size']}")
        print(f"Disk Cache Size: {stats['disk_cache_size']}")

        # Calculate savings
        if stats['api_calls'] > 0:
            calls_saved = stats['total_requests'] - stats['api_calls']
            print(f"\nAPI Calls Saved: {calls_saved}")
        print("==================================\n")


# Example usage
if __name__ == "__main__":
    from openai import OpenAI

    class SimpleEmbedder:
        def __init__(self):
            self.client = OpenAI()

        def embed_single(self, text):
            response = self.client.embeddings.create(
                model="text-embedding-3-small",
                input=[text]
            )
            return response.data[0].embedding

        def embed(self, texts):
            response = self.client.embeddings.create(
                model="text-embedding-3-small",
                input=texts
            )
            return [item.embedding for item in response.data]

    # Initialize cached embedder
    embedder = SimpleEmbedder()
    cached_embedder = EmbeddingCache(
        embedder=embedder,
        cache_dir=".embedding_cache",
        max_memory_size=1000,
        use_disk_cache=True,
        ttl_seconds=86400  # 24 hours
    )

    # Example texts (with duplicates)
    texts = [
        "What is machine learning?",
        "How does AI work?",
        "What is machine learning?",  # Duplicate - will hit cache
        "Explain neural networks",
        "How does AI work?",  # Duplicate - will hit cache
    ]

    # First request - all cache misses
    print("First batch:")
    embeddings = cached_embedder.get_embeddings_batch(texts)
    cached_embedder.print_stats()

    # Second request - all cache hits
    print("Second batch (same texts):")
    embeddings = cached_embedder.get_embeddings_batch(texts)
    cached_embedder.print_stats()

    # Individual requests
    print("Individual requests:")
    for text in texts[:3]:
        embedding = cached_embedder.get_embedding(text)
        print(f"Got embedding for: '{text[:30]}...'")

    cached_embedder.print_stats()
