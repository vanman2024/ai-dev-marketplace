"""
FAISS Configuration Template
High-performance vector search library from Meta
"""

import faiss
import numpy as np
import pickle
from typing import List, Dict, Optional, Any
from pathlib import Path

# ============================================
# Index Factory
# ============================================

class FAISSIndexFactory:
    """Factory for creating FAISS indexes"""

    @staticmethod
    def create_flat(dimensions: int, metric: str = "L2"):
        """
        Flat (exact) index - best for < 10K vectors

        Args:
            dimensions: Vector dimensions
            metric: L2 or IP (inner product)
        """
        if metric == "L2":
            return faiss.IndexFlatL2(dimensions)
        elif metric == "IP":
            return faiss.IndexFlatIP(dimensions)
        else:
            raise ValueError(f"Unknown metric: {metric}")

    @staticmethod
    def create_ivfflat(
        dimensions: int,
        nlist: int = 100,
        metric: str = "L2"
    ):
        """
        IVFFlat index - best for 10K-10M vectors

        Args:
            dimensions: Vector dimensions
            nlist: Number of clusters (sqrt(N) is good starting point)
            metric: L2 or IP
        """
        if metric == "L2":
            quantizer = faiss.IndexFlatL2(dimensions)
            index = faiss.IndexIVFFlat(quantizer, dimensions, nlist)
        elif metric == "IP":
            quantizer = faiss.IndexFlatIP(dimensions)
            index = faiss.IndexIVFFlat(
                quantizer, dimensions, nlist,
                faiss.METRIC_INNER_PRODUCT
            )
        else:
            raise ValueError(f"Unknown metric: {metric}")

        return index

    @staticmethod
    def create_hnsw(dimensions: int, M: int = 32, metric: str = "L2"):
        """
        HNSW index - fast approximate search

        Args:
            dimensions: Vector dimensions
            M: Number of connections per layer (higher = better recall)
            metric: L2 or IP
        """
        if metric == "L2":
            index = faiss.IndexHNSWFlat(dimensions, M)
        elif metric == "IP":
            index = faiss.IndexHNSWFlat(dimensions, M, faiss.METRIC_INNER_PRODUCT)
        else:
            raise ValueError(f"Unknown metric: {metric}")

        return index

    @staticmethod
    def create_ivf_pq(
        dimensions: int,
        nlist: int = 100,
        m: int = 8,
        nbits: int = 8
    ):
        """
        IVF + Product Quantization - memory efficient for 10M+ vectors

        Args:
            dimensions: Vector dimensions
            nlist: Number of clusters
            m: Number of sub-quantizers
            nbits: Bits per sub-quantizer
        """
        quantizer = faiss.IndexFlatL2(dimensions)
        index = faiss.IndexIVFPQ(quantizer, dimensions, nlist, m, nbits)
        return index

    @staticmethod
    def create_from_string(dimensions: int, index_string: str):
        """
        Create index from factory string

        Examples:
            "Flat" - Exact search
            "IVF100,Flat" - IVF with 100 clusters
            "IVF100,PQ8" - IVF with PQ compression
            "HNSW32" - HNSW with M=32
        """
        return faiss.index_factory(dimensions, index_string)


# ============================================
# Vector Store Implementation
# ============================================

class FAISSVectorStore:
    """FAISS vector store wrapper"""

    def __init__(
        self,
        dimensions: int,
        index_type: str = "Flat",
        metric: str = "L2",
        **kwargs
    ):
        """
        Initialize FAISS vector store

        Args:
            dimensions: Vector dimensions
            index_type: Index type (Flat, IVFFlat, HNSW, IVF_PQ)
            metric: Distance metric (L2, IP)
            **kwargs: Additional arguments for index creation
        """
        self.dimensions = dimensions
        self.metric = metric
        self.index_type = index_type

        # Create index
        factory = FAISSIndexFactory()
        if index_type == "Flat":
            self.index = factory.create_flat(dimensions, metric)
        elif index_type == "IVFFlat":
            nlist = kwargs.get("nlist", 100)
            self.index = factory.create_ivfflat(dimensions, nlist, metric)
        elif index_type == "HNSW":
            M = kwargs.get("M", 32)
            self.index = factory.create_hnsw(dimensions, M, metric)
        elif index_type == "IVF_PQ":
            nlist = kwargs.get("nlist", 100)
            m = kwargs.get("m", 8)
            self.index = factory.create_ivf_pq(dimensions, nlist, m)
        else:
            raise ValueError(f"Unknown index type: {index_type}")

        # Metadata storage (FAISS doesn't store metadata natively)
        self.id_to_metadata: Dict[int, Dict] = {}
        self.external_id_to_internal: Dict[str, int] = {}
        self.next_id = 0

    def train(self, vectors: np.ndarray):
        """
        Train index (required for IVF indices)

        Args:
            vectors: Training vectors (numpy array)
        """
        if not self.index.is_trained:
            print(f"Training index with {len(vectors)} vectors...")
            self.index.train(vectors)
            print("Training complete")

    def add(
        self,
        vectors: np.ndarray,
        ids: Optional[List[str]] = None,
        metadatas: Optional[List[Dict]] = None
    ) -> List[int]:
        """
        Add vectors to index

        Args:
            vectors: Numpy array of vectors
            ids: Optional external IDs
            metadatas: Optional metadata dicts

        Returns:
            List of internal IDs
        """
        # Ensure vectors are float32
        if vectors.dtype != np.float32:
            vectors = vectors.astype('float32')

        # Normalize for IP metric
        if self.metric == "IP":
            faiss.normalize_L2(vectors)

        # Train if needed
        if not self.index.is_trained:
            self.train(vectors)

        # Add to index
        start_id = self.next_id
        self.index.add(vectors)

        # Store metadata
        internal_ids = list(range(start_id, start_id + len(vectors)))
        for i, internal_id in enumerate(internal_ids):
            if metadatas:
                self.id_to_metadata[internal_id] = metadatas[i]
            if ids:
                self.external_id_to_internal[ids[i]] = internal_id

        self.next_id = start_id + len(vectors)
        return internal_ids

    def search(
        self,
        query_vectors: np.ndarray,
        k: int = 10,
        nprobe: Optional[int] = None
    ) -> tuple:
        """
        Search for similar vectors

        Args:
            query_vectors: Query vectors (numpy array)
            k: Number of results
            nprobe: Number of clusters to search (IVF only)

        Returns:
            Tuple of (distances, indices)
        """
        # Ensure float32
        if query_vectors.dtype != np.float32:
            query_vectors = query_vectors.astype('float32')

        # Normalize for IP
        if self.metric == "IP":
            faiss.normalize_L2(query_vectors)

        # Set nprobe for IVF indices
        if nprobe and hasattr(self.index, 'nprobe'):
            self.index.nprobe = nprobe

        # Search
        distances, indices = self.index.search(query_vectors, k)
        return distances, indices

    def search_with_metadata(
        self,
        query_vectors: np.ndarray,
        k: int = 10,
        nprobe: Optional[int] = None
    ) -> List[List[Dict]]:
        """
        Search and return results with metadata

        Returns:
            List of result lists, each containing dicts with:
                - id: Internal ID
                - distance: Distance/score
                - metadata: Associated metadata
        """
        distances, indices = self.search(query_vectors, k, nprobe)

        results = []
        for query_distances, query_indices in zip(distances, indices):
            query_results = []
            for dist, idx in zip(query_distances, query_indices):
                if idx != -1:  # Valid result
                    result = {
                        "id": int(idx),
                        "distance": float(dist),
                        "metadata": self.id_to_metadata.get(int(idx), {})
                    }
                    query_results.append(result)
            results.append(query_results)

        return results

    def save(self, path: str):
        """
        Save index and metadata to disk

        Args:
            path: Path to save (without extension)
        """
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)

        # Save index
        faiss.write_index(self.index, str(path) + ".index")

        # Save metadata
        metadata = {
            "id_to_metadata": self.id_to_metadata,
            "external_id_to_internal": self.external_id_to_internal,
            "next_id": self.next_id,
            "dimensions": self.dimensions,
            "metric": self.metric,
            "index_type": self.index_type
        }
        with open(str(path) + ".meta", "wb") as f:
            pickle.dump(metadata, f)

        print(f"Saved to {path}.index and {path}.meta")

    @classmethod
    def load(cls, path: str):
        """
        Load index and metadata from disk

        Args:
            path: Path to load (without extension)

        Returns:
            FAISSVectorStore instance
        """
        path = Path(path)

        # Load index
        index = faiss.read_index(str(path) + ".index")

        # Load metadata
        with open(str(path) + ".meta", "rb") as f:
            metadata = pickle.load(f)

        # Create instance
        store = cls.__new__(cls)
        store.index = index
        store.id_to_metadata = metadata["id_to_metadata"]
        store.external_id_to_internal = metadata["external_id_to_internal"]
        store.next_id = metadata["next_id"]
        store.dimensions = metadata["dimensions"]
        store.metric = metadata["metric"]
        store.index_type = metadata["index_type"]

        print(f"Loaded from {path}")
        return store

    def get_stats(self) -> Dict:
        """Get index statistics"""
        return {
            "total_vectors": self.index.ntotal,
            "is_trained": self.index.is_trained,
            "dimensions": self.dimensions,
            "metric": self.metric,
            "index_type": self.index_type
        }


# ============================================
# GPU Support
# ============================================

def move_to_gpu(index: faiss.Index, gpu_id: int = 0):
    """
    Move index to GPU

    Args:
        index: FAISS index
        gpu_id: GPU device ID

    Returns:
        GPU index
    """
    if not hasattr(faiss, 'StandardGpuResources'):
        raise RuntimeError("GPU support not available")

    res = faiss.StandardGpuResources()
    return faiss.index_cpu_to_gpu(res, gpu_id, index)


# ============================================
# Usage Examples
# ============================================

if __name__ == "__main__":
    # Example 1: Flat index (exact search)
    print("Example 1: Flat Index")
    store = FAISSVectorStore(
        dimensions=128,
        index_type="Flat",
        metric="L2"
    )

    # Generate sample data
    vectors = np.random.random((1000, 128)).astype('float32')
    metadatas = [{"id": i, "text": f"Document {i}"} for i in range(1000)]

    # Add vectors
    store.add(vectors, metadatas=metadatas)
    print(f"Added {store.index.ntotal} vectors")

    # Search
    query = np.random.random((1, 128)).astype('float32')
    results = store.search_with_metadata(query, k=5)

    print("Top 5 results:")
    for result in results[0]:
        print(f"  ID: {result['id']}, Distance: {result['distance']:.4f}")
        print(f"  Metadata: {result['metadata']}")

    # Save
    store.save("./faiss_index")

    # Example 2: IVFFlat index (approximate search)
    print("\nExample 2: IVFFlat Index")
    store2 = FAISSVectorStore(
        dimensions=128,
        index_type="IVFFlat",
        metric="L2",
        nlist=10  # Number of clusters
    )

    # Train and add
    store2.add(vectors, metadatas=metadatas)

    # Search with nprobe
    results2 = store2.search_with_metadata(query, k=5, nprobe=3)

    # Example 3: HNSW index
    print("\nExample 3: HNSW Index")
    store3 = FAISSVectorStore(
        dimensions=128,
        index_type="HNSW",
        metric="L2",
        M=16
    )
    store3.add(vectors[:500])  # Add half the data

    # Example 4: Load saved index
    print("\nExample 4: Load Index")
    loaded_store = FAISSVectorStore.load("./faiss_index")
    print(f"Loaded index stats: {loaded_store.get_stats()}")

    # Example 5: Cosine similarity (using IP with normalized vectors)
    print("\nExample 5: Cosine Similarity")
    store5 = FAISSVectorStore(
        dimensions=128,
        index_type="Flat",
        metric="IP"  # Inner product with normalized vectors = cosine
    )
    # Vectors are auto-normalized in add() when metric="IP"
    store5.add(vectors[:100])

    # Search (query is also normalized automatically)
    results5 = store5.search_with_metadata(query, k=3)
    print("Cosine similarity results (higher score = more similar)")
    for result in results5[0]:
        print(f"  Score: {result['distance']:.4f}")
