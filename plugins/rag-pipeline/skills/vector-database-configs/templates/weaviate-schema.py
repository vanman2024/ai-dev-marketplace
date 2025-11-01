"""
Weaviate Schema Configuration Template
GraphQL-based vector database with modules
"""

import weaviate
from weaviate.classes.config import Configure, Property, DataType
from weaviate.classes.query import Filter
import os
from typing import List, Dict, Optional, Any

# ============================================
# Client Configuration
# ============================================

class WeaviateConfig:
    """Weaviate client configuration"""

    @staticmethod
    def connect_local(
        host: str = "localhost",
        port: int = 8080,
        grpc_port: int = 50051
    ):
        """Connect to local Weaviate instance"""
        return weaviate.connect_to_local(
            host=host,
            port=port,
            grpc_port=grpc_port
        )

    @staticmethod
    def connect_cloud(
        cluster_url: str,
        api_key: Optional[str] = None
    ):
        """Connect to Weaviate Cloud"""
        api_key = api_key or os.getenv("WEAVIATE_API_KEY")
        if api_key:
            return weaviate.connect_to_weaviate_cloud(
                cluster_url=cluster_url,
                auth_credentials=weaviate.auth.AuthApiKey(api_key)
            )
        return weaviate.connect_to_weaviate_cloud(cluster_url=cluster_url)


# ============================================
# Schema Definition
# ============================================

def create_document_collection(
    client: weaviate.Client,
    collection_name: str = "Documents",
    vectorizer: str = "none"  # none, text2vec-openai, text2vec-cohere, etc.
):
    """
    Create document collection with schema

    Args:
        client: Weaviate client
        collection_name: Name of collection (class)
        vectorizer: Vectorizer module to use
    """
    # Configure vectorizer
    if vectorizer == "none":
        vectorizer_config = None
    elif vectorizer == "text2vec-openai":
        vectorizer_config = Configure.Vectorizer.text2vec_openai(
            model="text-embedding-3-small"
        )
    elif vectorizer == "text2vec-cohere":
        vectorizer_config = Configure.Vectorizer.text2vec_cohere(
            model="embed-english-v3.0"
        )
    elif vectorizer == "text2vec-huggingface":
        vectorizer_config = Configure.Vectorizer.text2vec_huggingface(
            model="sentence-transformers/all-MiniLM-L6-v2"
        )
    else:
        vectorizer_config = None

    # Create collection
    collection = client.collections.create(
        name=collection_name,
        description="Document collection for RAG pipeline",
        vectorizer_config=vectorizer_config,
        properties=[
            Property(
                name="content",
                data_type=DataType.TEXT,
                description="Document content",
                vectorize_property_name=True  # Include property in vectorization
            ),
            Property(
                name="title",
                data_type=DataType.TEXT,
                description="Document title",
                vectorize_property_name=True
            ),
            Property(
                name="source",
                data_type=DataType.TEXT,
                description="Document source",
                vectorize_property_name=False  # Don't vectorize metadata
            ),
            Property(
                name="category",
                data_type=DataType.TEXT,
                description="Document category",
                vectorize_property_name=False
            ),
            Property(
                name="rating",
                data_type=DataType.NUMBER,
                description="Document rating"
            ),
            Property(
                name="tags",
                data_type=DataType.TEXT_ARRAY,
                description="Document tags"
            ),
            Property(
                name="metadata",
                data_type=DataType.TEXT,
                description="Additional metadata as JSON string"
            )
        ]
    )

    return collection


# ============================================
# Vector Store Operations
# ============================================

class WeaviateVectorStore:
    """Weaviate vector store wrapper"""

    def __init__(
        self,
        client: weaviate.Client,
        collection_name: str = "Documents"
    ):
        self.client = client
        self.collection = client.collections.get(collection_name)

    def insert(
        self,
        properties: Dict[str, Any],
        vector: Optional[List[float]] = None,
        uuid: Optional[str] = None
    ) -> str:
        """
        Insert single object

        Args:
            properties: Object properties
            vector: Optional custom vector
            uuid: Optional object UUID

        Returns:
            Object UUID
        """
        return self.collection.data.insert(
            properties=properties,
            vector=vector,
            uuid=uuid
        )

    def insert_many(
        self,
        objects: List[Dict[str, Any]],
        vectors: Optional[List[List[float]]] = None
    ) -> List[str]:
        """
        Batch insert objects

        Args:
            objects: List of property dicts
            vectors: Optional list of vectors

        Returns:
            List of UUIDs
        """
        uuids = []
        with self.collection.batch.dynamic() as batch:
            for i, obj in enumerate(objects):
                vector = vectors[i] if vectors else None
                uuid = batch.add_object(
                    properties=obj,
                    vector=vector
                )
                uuids.append(uuid)
        return uuids

    def query_near_vector(
        self,
        vector: List[float],
        limit: int = 10,
        filters: Optional[Filter] = None,
        return_properties: Optional[List[str]] = None,
        return_metadata: bool = True
    ):
        """
        Query by vector similarity

        Args:
            vector: Query vector
            limit: Max results
            filters: Property filters
            return_properties: Properties to return
            return_metadata: Include metadata

        Returns:
            Query response
        """
        query = self.collection.query.near_vector(
            near_vector=vector,
            limit=limit,
            filters=filters,
            return_properties=return_properties,
            return_metadata=["distance"] if return_metadata else None
        )
        return query

    def query_near_text(
        self,
        query: str,
        limit: int = 10,
        filters: Optional[Filter] = None
    ):
        """Query by text (requires vectorizer)"""
        return self.collection.query.near_text(
            query=query,
            limit=limit,
            filters=filters
        )

    def fetch_objects(
        self,
        limit: Optional[int] = 10,
        filters: Optional[Filter] = None
    ):
        """Fetch objects with optional filters"""
        return self.collection.query.fetch_objects(
            limit=limit,
            filters=filters
        )

    def get_by_id(self, uuid: str):
        """Get object by UUID"""
        return self.collection.query.fetch_object_by_id(uuid)

    def update(
        self,
        uuid: str,
        properties: Dict[str, Any],
        vector: Optional[List[float]] = None
    ):
        """Update object"""
        self.collection.data.update(
            uuid=uuid,
            properties=properties,
            vector=vector
        )

    def delete_by_id(self, uuid: str):
        """Delete by UUID"""
        self.collection.data.delete_by_id(uuid)

    def delete_many(self, filters: Filter):
        """Delete by filter"""
        self.collection.data.delete_many(where=filters)

    def aggregate(self):
        """Get aggregate statistics"""
        return self.collection.aggregate.over_all(
            total_count=True
        )


# ============================================
# Filtering Examples
# ============================================

# Equal filter
filter_equal = Filter.by_property("category").equal("ml")

# Comparison filters
filter_gt = Filter.by_property("rating").greater_than(4.0)
filter_gte = Filter.by_property("rating").greater_or_equal(4.0)
filter_lt = Filter.by_property("rating").less_than(5.0)

# Contains filter
filter_contains = Filter.by_property("tags").contains_any(["ml", "nlp"])

# AND filter
filter_and = Filter.by_property("category").equal("ml") & \
             Filter.by_property("rating").greater_than(4.0)

# OR filter
filter_or = Filter.by_property("category").equal("ml") | \
            Filter.by_property("category").equal("nlp")

# Complex nested filter
filter_complex = (
    Filter.by_property("category").equal("ml") &
    (
        Filter.by_property("rating").greater_than(4.5) |
        Filter.by_property("source").equal("premium")
    )
)


# ============================================
# Hybrid Search
# ============================================

def hybrid_search(
    collection,
    query: str,
    vector: Optional[List[float]] = None,
    alpha: float = 0.5,  # 0 = keyword only, 1 = vector only
    limit: int = 10
):
    """
    Hybrid keyword + vector search

    Args:
        collection: Weaviate collection
        query: Text query
        vector: Optional query vector
        alpha: Balance between keyword (0) and vector (1)
        limit: Max results

    Returns:
        Search results
    """
    return collection.query.hybrid(
        query=query,
        vector=vector,
        alpha=alpha,
        limit=limit
    )


# ============================================
# Usage Examples
# ============================================

if __name__ == "__main__":
    # Connect to Weaviate
    client = WeaviateConfig.connect_local()

    # Create collection (if not exists)
    try:
        collection = create_document_collection(
            client,
            collection_name="Documents",
            vectorizer="none"  # Use "text2vec-openai" for auto-vectorization
        )
    except:
        pass  # Collection already exists

    # Initialize store
    store = WeaviateVectorStore(client, "Documents")

    # Insert single object
    uuid = store.insert(
        properties={
            "content": "Machine learning is transforming AI",
            "title": "ML Advances",
            "source": "blog",
            "category": "ml",
            "rating": 4.5,
            "tags": ["ml", "ai"],
            "metadata": "{}"
        },
        vector=[0.1] * 1536  # Your embedding
    )
    print(f"Inserted: {uuid}")

    # Batch insert
    objects = [
        {
            "content": f"Document {i}",
            "title": f"Title {i}",
            "source": "api",
            "category": "test",
            "rating": 4.0 + i * 0.1,
            "tags": ["test"],
            "metadata": "{}"
        }
        for i in range(10)
    ]
    uuids = store.insert_many(objects)

    # Query by vector
    results = store.query_near_vector(
        vector=[0.15] * 1536,
        limit=5,
        filters=Filter.by_property("category").equal("ml")
    )

    for obj in results.objects:
        print(f"Content: {obj.properties['content']}")
        print(f"Distance: {obj.metadata.distance}")

    # Query by text (if vectorizer enabled)
    # results = store.query_near_text(
    #     query="artificial intelligence",
    #     limit=5
    # )

    # Fetch with filter
    filtered = store.fetch_objects(
        limit=10,
        filters=Filter.by_property("rating").greater_than(4.0)
    )

    # Update object
    store.update(
        uuid=uuid,
        properties={"rating": 5.0}
    )

    # Delete by filter
    store.delete_many(
        filters=Filter.by_property("category").equal("test")
    )

    # Get stats
    stats = store.aggregate()
    print(f"Total objects: {stats.total_count}")

    # Close connection
    client.close()
