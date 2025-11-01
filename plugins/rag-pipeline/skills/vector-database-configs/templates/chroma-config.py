"""
Chroma Configuration Template
Vector database configuration for ChromaDB
"""

import chromadb
from chromadb.config import Settings
from chromadb.utils import embedding_functions
import os
from typing import List, Dict, Optional, Any

# ============================================
# Client Configuration
# ============================================

class ChromaConfig:
    """Chroma client configuration and management"""

    def __init__(
        self,
        mode: str = "persistent",  # "persistent", "memory", or "client-server"
        persist_directory: str = "./chroma_data",
        host: str = "localhost",
        port: int = 8000,
        api_key: Optional[str] = None
    ):
        self.mode = mode
        self.persist_directory = persist_directory
        self.host = host
        self.port = port
        self.api_key = api_key
        self.client = None

    def get_client(self) -> chromadb.Client:
        """Initialize and return Chroma client"""
        if self.client is not None:
            return self.client

        if self.mode == "persistent":
            # Persistent client - data saved to disk
            self.client = chromadb.PersistentClient(
                path=self.persist_directory,
                settings=Settings(
                    anonymized_telemetry=False,
                    allow_reset=True
                )
            )

        elif self.mode == "memory":
            # In-memory client - data not persisted
            self.client = chromadb.Client(
                settings=Settings(
                    anonymized_telemetry=False
                )
            )

        elif self.mode == "client-server":
            # Client connecting to Chroma server
            if self.api_key:
                self.client = chromadb.HttpClient(
                    host=self.host,
                    port=self.port,
                    settings=Settings(
                        chroma_client_auth_provider="token",
                        chroma_client_auth_credentials=self.api_key
                    )
                )
            else:
                self.client = chromadb.HttpClient(
                    host=self.host,
                    port=self.port,
                    settings=Settings(
                        anonymized_telemetry=False
                    )
                )

        else:
            raise ValueError(f"Unknown mode: {self.mode}")

        return self.client


# ============================================
# Collection Configuration
# ============================================

def create_collection(
    client: chromadb.Client,
    name: str = "documents",
    distance_metric: str = "cosine",  # "cosine", "l2", or "ip"
    embedding_function: Optional[Any] = None,
    metadata: Optional[Dict] = None
):
    """
    Create or get a collection

    Args:
        client: Chroma client instance
        name: Collection name
        distance_metric: Distance metric (cosine, l2, ip)
        embedding_function: Optional custom embedding function
        metadata: Optional collection metadata
    """
    collection_metadata = {
        "hnsw:space": distance_metric
    }
    if metadata:
        collection_metadata.update(metadata)

    return client.get_or_create_collection(
        name=name,
        embedding_function=embedding_function,
        metadata=collection_metadata
    )


# ============================================
# Embedding Functions
# ============================================

# Option 1: Default (Sentence Transformers)
default_ef = embedding_functions.DefaultEmbeddingFunction()

# Option 2: OpenAI Embeddings
openai_ef = embedding_functions.OpenAIEmbeddingFunction(
    api_key=os.getenv("OPENAI_API_KEY"),
    model_name="text-embedding-3-small"
)

# Option 3: Sentence Transformers (custom model)
sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(
    model_name="all-MiniLM-L6-v2"
)

# Option 4: Cohere Embeddings
cohere_ef = embedding_functions.CohereEmbeddingFunction(
    api_key=os.getenv("COHERE_API_KEY"),
    model_name="embed-english-v3.0"
)

# Option 5: Custom embedding function
class CustomEmbeddingFunction(embedding_functions.EmbeddingFunction):
    def __call__(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for texts
        Implement your custom logic here
        """
        # Example: Use your own embedding model
        embeddings = []
        for text in texts:
            # Your embedding logic here
            embedding = [0.0] * 1536  # Replace with actual embedding
            embeddings.append(embedding)
        return embeddings


# ============================================
# Basic Operations
# ============================================

class ChromaVectorStore:
    """Wrapper for common Chroma operations"""

    def __init__(
        self,
        config: ChromaConfig,
        collection_name: str = "documents",
        embedding_function: Optional[Any] = None
    ):
        self.config = config
        self.client = config.get_client()
        self.collection = create_collection(
            self.client,
            collection_name,
            embedding_function=embedding_function
        )

    def add_documents(
        self,
        documents: List[str],
        metadatas: Optional[List[Dict]] = None,
        ids: Optional[List[str]] = None
    ) -> List[str]:
        """
        Add documents to collection

        Args:
            documents: List of document texts
            metadatas: Optional list of metadata dicts
            ids: Optional list of document IDs (auto-generated if not provided)

        Returns:
            List of document IDs
        """
        if ids is None:
            # Generate IDs
            import uuid
            ids = [str(uuid.uuid4()) for _ in documents]

        self.collection.add(
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )

        return ids

    def add_embeddings(
        self,
        embeddings: List[List[float]],
        documents: List[str],
        metadatas: Optional[List[Dict]] = None,
        ids: Optional[List[str]] = None
    ) -> List[str]:
        """
        Add pre-computed embeddings

        Args:
            embeddings: List of embedding vectors
            documents: List of document texts
            metadatas: Optional list of metadata dicts
            ids: Optional list of document IDs

        Returns:
            List of document IDs
        """
        if ids is None:
            import uuid
            ids = [str(uuid.uuid4()) for _ in documents]

        self.collection.add(
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas,
            ids=ids
        )

        return ids

    def query(
        self,
        query_texts: Optional[List[str]] = None,
        query_embeddings: Optional[List[List[float]]] = None,
        n_results: int = 10,
        where: Optional[Dict] = None,
        where_document: Optional[Dict] = None
    ) -> Dict:
        """
        Query collection for similar documents

        Args:
            query_texts: Query texts (if using embedding function)
            query_embeddings: Pre-computed query embeddings
            n_results: Number of results to return
            where: Metadata filter
            where_document: Document content filter

        Returns:
            Query results dict
        """
        return self.collection.query(
            query_texts=query_texts,
            query_embeddings=query_embeddings,
            n_results=n_results,
            where=where,
            where_document=where_document
        )

    def get(
        self,
        ids: Optional[List[str]] = None,
        where: Optional[Dict] = None,
        limit: Optional[int] = None
    ) -> Dict:
        """
        Get documents by ID or filter

        Args:
            ids: List of document IDs
            where: Metadata filter
            limit: Max number of results

        Returns:
            Documents dict
        """
        return self.collection.get(
            ids=ids,
            where=where,
            limit=limit
        )

    def update(
        self,
        ids: List[str],
        documents: Optional[List[str]] = None,
        metadatas: Optional[List[Dict]] = None,
        embeddings: Optional[List[List[float]]] = None
    ):
        """Update existing documents"""
        self.collection.update(
            ids=ids,
            documents=documents,
            metadatas=metadatas,
            embeddings=embeddings
        )

    def delete(
        self,
        ids: Optional[List[str]] = None,
        where: Optional[Dict] = None
    ):
        """Delete documents by ID or filter"""
        self.collection.delete(
            ids=ids,
            where=where
        )

    def count(self) -> int:
        """Get total number of documents"""
        return self.collection.count()

    def peek(self, limit: int = 10) -> Dict:
        """Get first N documents"""
        return self.collection.peek(limit=limit)


# ============================================
# Metadata Filtering Examples
# ============================================

# Filter by exact match
where_exact = {"category": "ml"}

# Filter by multiple conditions (AND)
where_and = {
    "$and": [
        {"category": "ml"},
        {"source": "api"}
    ]
}

# Filter by OR condition
where_or = {
    "$or": [
        {"category": "ml"},
        {"category": "nlp"}
    ]
}

# Filter by comparison operators
where_comparison = {
    "rating": {"$gt": 4.0}  # $gt, $gte, $lt, $lte, $ne
}

# Filter by set membership
where_in = {
    "category": {"$in": ["ml", "nlp", "cv"]}
}

# Document content filter
where_document_contains = {
    "$contains": "machine learning"
}


# ============================================
# Usage Examples
# ============================================

if __name__ == "__main__":
    # Example 1: Persistent storage with auto-embeddings
    config = ChromaConfig(mode="persistent", persist_directory="./my_chroma_db")
    store = ChromaVectorStore(
        config=config,
        collection_name="documents",
        embedding_function=default_ef  # Auto-generate embeddings
    )

    # Add documents
    ids = store.add_documents(
        documents=[
            "Machine learning is a subset of AI",
            "Natural language processing enables text understanding",
            "Vector databases store embeddings efficiently"
        ],
        metadatas=[
            {"category": "ml", "source": "manual"},
            {"category": "nlp", "source": "manual"},
            {"category": "databases", "source": "manual"}
        ]
    )
    print(f"Added {len(ids)} documents")

    # Query by text
    results = store.query(
        query_texts=["artificial intelligence"],
        n_results=2,
        where={"category": "ml"}  # Filter by metadata
    )
    print(f"Found {len(results['documents'][0])} results")

    # Example 2: Pre-computed embeddings
    config2 = ChromaConfig(mode="memory")
    store2 = ChromaVectorStore(config=config2, collection_name="embeddings")

    # Add with embeddings (no embedding function needed)
    store2.add_embeddings(
        embeddings=[[0.1] * 1536, [0.2] * 1536],  # Your embeddings
        documents=["Doc 1", "Doc 2"],
        metadatas=[{"idx": 1}, {"idx": 2}]
    )

    # Query with embedding
    results2 = store2.query(
        query_embeddings=[[0.15] * 1536],
        n_results=1
    )

    # Example 3: Client-server mode
    # config3 = ChromaConfig(
    #     mode="client-server",
    #     host="localhost",
    #     port=8000
    # )
    # store3 = ChromaVectorStore(config=config3)

    # Example 4: Batch operations
    batch_docs = [f"Document {i}" for i in range(100)]
    batch_meta = [{"index": i, "batch": "1"} for i in range(100)]

    store.add_documents(
        documents=batch_docs,
        metadatas=batch_meta
    )

    # Get documents by metadata
    filtered = store.get(
        where={"batch": "1"},
        limit=10
    )
    print(f"Retrieved {len(filtered['ids'])} documents")

    # Update documents
    store.update(
        ids=ids[:1],
        metadatas=[{"category": "ml", "source": "updated"}]
    )

    # Delete by metadata
    store.delete(where={"batch": "1"})

    print(f"Total documents: {store.count()}")
