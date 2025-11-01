"""
Pinecone Configuration Template
Cloud-native vector database configuration
"""

import os
from pinecone import Pinecone, ServerlessSpec, PodSpec
from typing import List, Dict, Optional, Any

# ============================================
# Client Configuration
# ============================================

class PineconeConfig:
    """Pinecone client configuration"""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("PINECONE_API_KEY")
        if not self.api_key:
            raise ValueError("PINECONE_API_KEY not set")
        self.pc = Pinecone(api_key=self.api_key)

    def create_serverless_index(
        self,
        name: str,
        dimension: int = 1536,
        metric: str = "cosine",  # cosine, euclidean, dotproduct
        cloud: str = "aws",
        region: str = "us-east-1"
    ):
        """Create serverless index (recommended)"""
        if name not in [idx.name for idx in self.pc.list_indexes()]:
            self.pc.create_index(
                name=name,
                dimension=dimension,
                metric=metric,
                spec=ServerlessSpec(cloud=cloud, region=region)
            )
        return self.pc.Index(name)

    def create_pod_index(
        self,
        name: str,
        dimension: int = 1536,
        metric: str = "cosine",
        environment: str = "gcp-starter",
        pod_type: str = "p1.x1",
        pods: int = 1
    ):
        """Create pod-based index"""
        if name not in [idx.name for idx in self.pc.list_indexes()]:
            self.pc.create_index(
                name=name,
                dimension=dimension,
                metric=metric,
                spec=PodSpec(
                    environment=environment,
                    pod_type=pod_type,
                    pods=pods
                )
            )
        return self.pc.Index(name)


# ============================================
# Vector Store Operations
# ============================================

class PineconeVectorStore:
    """Pinecone vector store wrapper"""

    def __init__(self, index_name: str, api_key: Optional[str] = None):
        config = PineconeConfig(api_key)
        self.pc = config.pc
        self.index = self.pc.Index(index_name)

    def upsert(
        self,
        vectors: List[Dict[str, Any]],
        namespace: str = "",
        batch_size: int = 100
    ):
        """
        Upsert vectors in batches

        Args:
            vectors: List of dicts with 'id', 'values', 'metadata'
            namespace: Namespace for organization
            batch_size: Batch size for upserting
        """
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i + batch_size]
            self.index.upsert(vectors=batch, namespace=namespace)

    def upsert_documents(
        self,
        ids: List[str],
        embeddings: List[List[float]],
        documents: List[str],
        metadatas: Optional[List[Dict]] = None,
        namespace: str = ""
    ):
        """Upsert documents with embeddings"""
        vectors = []
        for i, (id_, embedding, doc) in enumerate(zip(ids, embeddings, documents)):
            metadata = metadatas[i] if metadatas else {}
            metadata["text"] = doc  # Store text in metadata
            vectors.append({
                "id": id_,
                "values": embedding,
                "metadata": metadata
            })
        self.upsert(vectors, namespace)

    def query(
        self,
        vector: List[float],
        top_k: int = 10,
        filter: Optional[Dict] = None,
        namespace: str = "",
        include_metadata: bool = True,
        include_values: bool = False
    ) -> Dict:
        """
        Query similar vectors

        Args:
            vector: Query embedding
            top_k: Number of results
            filter: Metadata filter
            namespace: Namespace to query
            include_metadata: Include metadata in results
            include_values: Include vector values in results

        Returns:
            Query results
        """
        return self.index.query(
            vector=vector,
            top_k=top_k,
            filter=filter,
            namespace=namespace,
            include_metadata=include_metadata,
            include_values=include_values
        )

    def fetch(
        self,
        ids: List[str],
        namespace: str = ""
    ) -> Dict:
        """Fetch vectors by IDs"""
        return self.index.fetch(ids=ids, namespace=namespace)

    def delete(
        self,
        ids: Optional[List[str]] = None,
        filter: Optional[Dict] = None,
        namespace: str = "",
        delete_all: bool = False
    ):
        """Delete vectors by IDs or filter"""
        self.index.delete(
            ids=ids,
            filter=filter,
            namespace=namespace,
            delete_all=delete_all
        )

    def describe_stats(self, namespace: str = "") -> Dict:
        """Get index statistics"""
        return self.index.describe_index_stats()


# ============================================
# Metadata Filtering
# ============================================

# Exact match
filter_exact = {"category": "ml"}

# Multiple conditions (AND)
filter_and = {
    "$and": [
        {"category": "ml"},
        {"source": "api"}
    ]
}

# OR conditions
filter_or = {
    "$or": [
        {"category": "ml"},
        {"category": "nlp"}
    ]
}

# Comparison operators
filter_comparison = {
    "rating": {"$gt": 4.0}  # $gt, $gte, $lt, $lte, $eq, $ne
}

# Set membership
filter_in = {
    "category": {"$in": ["ml", "nlp", "cv"]}
}

# Combined filters
filter_complex = {
    "$and": [
        {"category": {"$in": ["ml", "nlp"]}},
        {"rating": {"$gte": 4.0}},
        {"source": {"$ne": "test"}}
    ]
}


# ============================================
# Usage Examples
# ============================================

if __name__ == "__main__":
    # Initialize
    config = PineconeConfig()

    # Create serverless index
    index = config.create_serverless_index(
        name="documents",
        dimension=1536,
        metric="cosine",
        cloud="aws",
        region="us-east-1"
    )

    # Create vector store
    store = PineconeVectorStore("documents")

    # Upsert vectors
    vectors = [
        {
            "id": "doc1",
            "values": [0.1] * 1536,  # Replace with actual embedding
            "metadata": {
                "text": "Machine learning document",
                "category": "ml",
                "rating": 4.5
            }
        },
        {
            "id": "doc2",
            "values": [0.2] * 1536,
            "metadata": {
                "text": "NLP document",
                "category": "nlp",
                "rating": 4.8
            }
        }
    ]
    store.upsert(vectors)

    # Query with filter
    results = store.query(
        vector=[0.15] * 1536,
        top_k=5,
        filter={"category": "ml", "rating": {"$gte": 4.0}},
        include_metadata=True
    )

    for match in results['matches']:
        print(f"ID: {match['id']}, Score: {match['score']:.4f}")
        print(f"Text: {match['metadata']['text']}")

    # Fetch by ID
    fetched = store.fetch(ids=["doc1", "doc2"])

    # Delete with filter
    store.delete(filter={"category": "test"})

    # Get stats
    stats = store.describe_stats()
    print(f"Total vectors: {stats.total_vector_count}")
