"""
Qdrant Configuration Template
High-performance vector database with advanced filtering
"""

from qdrant_client import QdrantClient
from qdrant_client.models import (
    Distance, VectorParams, PointStruct,
    Filter, FieldCondition, MatchValue, MatchAny, Range,
    SearchRequest, ScrollRequest
)
import os
from typing import List, Dict, Optional, Any
from uuid import uuid4

# ============================================
# Client Configuration
# ============================================

class QdrantConfig:
    """Qdrant client configuration"""

    @staticmethod
    def connect_local(
        url: str = "http://localhost:6333",
        api_key: Optional[str] = None
    ):
        """Connect to local Qdrant instance"""
        return QdrantClient(url=url, api_key=api_key)

    @staticmethod
    def connect_cloud(
        url: str,
        api_key: Optional[str] = None
    ):
        """Connect to Qdrant Cloud"""
        api_key = api_key or os.getenv("QDRANT_API_KEY")
        return QdrantClient(url=url, api_key=api_key)

    @staticmethod
    def create_collection(
        client: QdrantClient,
        collection_name: str,
        vector_size: int = 1536,
        distance: str = "Cosine"  # Cosine, Euclid, Dot
    ):
        """Create collection with vector configuration"""
        distance_map = {
            "Cosine": Distance.COSINE,
            "Euclid": Distance.EUCLID,
            "Dot": Distance.DOT
        }

        client.create_collection(
            collection_name=collection_name,
            vectors_config=VectorParams(
                size=vector_size,
                distance=distance_map[distance]
            )
        )


# ============================================
# Vector Store Operations
# ============================================

class QdrantVectorStore:
    """Qdrant vector store wrapper"""

    def __init__(
        self,
        client: QdrantClient,
        collection_name: str
    ):
        self.client = client
        self.collection_name = collection_name

    def upsert(
        self,
        points: List[PointStruct],
        wait: bool = True
    ):
        """
        Upsert points

        Args:
            points: List of PointStruct objects
            wait: Wait for operation to complete
        """
        return self.client.upsert(
            collection_name=self.collection_name,
            points=points,
            wait=wait
        )

    def upsert_documents(
        self,
        ids: Optional[List[str]] = None,
        vectors: List[List[float]] = None,
        documents: List[str] = None,
        metadatas: Optional[List[Dict]] = None
    ) -> List[str]:
        """
        Upsert documents with vectors

        Args:
            ids: Document IDs (auto-generated if None)
            vectors: Embedding vectors
            documents: Document texts
            metadatas: Document metadata

        Returns:
            List of point IDs
        """
        if ids is None:
            ids = [str(uuid4()) for _ in range(len(vectors))]

        points = []
        for i, (id_, vector, doc) in enumerate(zip(ids, vectors, documents)):
            payload = metadatas[i] if metadatas else {}
            payload["text"] = doc  # Store text in payload

            points.append(
                PointStruct(
                    id=id_,
                    vector=vector,
                    payload=payload
                )
            )

        self.upsert(points)
        return ids

    def search(
        self,
        query_vector: List[float],
        limit: int = 10,
        query_filter: Optional[Filter] = None,
        score_threshold: Optional[float] = None,
        with_payload: bool = True,
        with_vectors: bool = False
    ):
        """
        Search for similar vectors

        Args:
            query_vector: Query embedding
            limit: Number of results
            query_filter: Payload filter
            score_threshold: Minimum score threshold
            with_payload: Include payload in results
            with_vectors: Include vectors in results

        Returns:
            Search results
        """
        return self.client.search(
            collection_name=self.collection_name,
            query_vector=query_vector,
            limit=limit,
            query_filter=query_filter,
            score_threshold=score_threshold,
            with_payload=with_payload,
            with_vectors=with_vectors
        )

    def search_batch(
        self,
        requests: List[SearchRequest]
    ):
        """Batch search for multiple queries"""
        return self.client.search_batch(
            collection_name=self.collection_name,
            requests=requests
        )

    def retrieve(
        self,
        ids: List[str],
        with_payload: bool = True,
        with_vectors: bool = False
    ):
        """Retrieve points by IDs"""
        return self.client.retrieve(
            collection_name=self.collection_name,
            ids=ids,
            with_payload=with_payload,
            with_vectors=with_vectors
        )

    def scroll(
        self,
        scroll_filter: Optional[Filter] = None,
        limit: int = 10,
        with_payload: bool = True,
        with_vectors: bool = False
    ):
        """Scroll through points (pagination)"""
        return self.client.scroll(
            collection_name=self.collection_name,
            scroll_filter=scroll_filter,
            limit=limit,
            with_payload=with_payload,
            with_vectors=with_vectors
        )

    def update_payload(
        self,
        points: List[str],
        payload: Dict[str, Any],
        wait: bool = True
    ):
        """Update payload for points"""
        self.client.set_payload(
            collection_name=self.collection_name,
            payload=payload,
            points=points,
            wait=wait
        )

    def delete_payload(
        self,
        points: List[str],
        keys: List[str],
        wait: bool = True
    ):
        """Delete payload keys from points"""
        self.client.delete_payload(
            collection_name=self.collection_name,
            keys=keys,
            points=points,
            wait=wait
        )

    def delete(
        self,
        points_selector: Optional[List[str]] = None,
        query_filter: Optional[Filter] = None,
        wait: bool = True
    ):
        """Delete points by IDs or filter"""
        if points_selector:
            self.client.delete(
                collection_name=self.collection_name,
                points_selector=points_selector,
                wait=wait
            )
        elif query_filter:
            self.client.delete(
                collection_name=self.collection_name,
                points_selector=query_filter,
                wait=wait
            )

    def count(self, count_filter: Optional[Filter] = None) -> int:
        """Count points with optional filter"""
        result = self.client.count(
            collection_name=self.collection_name,
            count_filter=count_filter
        )
        return result.count

    def create_payload_index(
        self,
        field_name: str,
        field_schema: str = "keyword"  # keyword, integer, float, geo, text
    ):
        """Create index on payload field for faster filtering"""
        self.client.create_payload_index(
            collection_name=self.collection_name,
            field_name=field_name,
            field_schema=field_schema
        )


# ============================================
# Filtering Examples
# ============================================

# Exact match
filter_exact = Filter(
    must=[
        FieldCondition(
            key="category",
            match=MatchValue(value="ml")
        )
    ]
)

# Multiple conditions (AND)
filter_and = Filter(
    must=[
        FieldCondition(key="category", match=MatchValue(value="ml")),
        FieldCondition(key="source", match=MatchValue(value="api"))
    ]
)

# Any match (OR)
filter_or = Filter(
    should=[
        FieldCondition(key="category", match=MatchValue(value="ml")),
        FieldCondition(key="category", match=MatchValue(value="nlp"))
    ]
)

# NOT condition
filter_not = Filter(
    must_not=[
        FieldCondition(key="category", match=MatchValue(value="test"))
    ]
)

# Range filter
filter_range = Filter(
    must=[
        FieldCondition(
            key="rating",
            range=Range(gte=4.0, lte=5.0)
        )
    ]
)

# Match any from list
filter_match_any = Filter(
    must=[
        FieldCondition(
            key="category",
            match=MatchAny(any=["ml", "nlp", "cv"])
        )
    ]
)

# Complex nested filter
filter_complex = Filter(
    must=[
        FieldCondition(key="category", match=MatchAny(any=["ml", "nlp"]))
    ],
    should=[
        FieldCondition(key="rating", range=Range(gte=4.5)),
        FieldCondition(key="source", match=MatchValue(value="premium"))
    ],
    must_not=[
        FieldCondition(key="status", match=MatchValue(value="draft"))
    ]
)


# ============================================
# Usage Examples
# ============================================

if __name__ == "__main__":
    # Connect to Qdrant
    client = QdrantConfig.connect_local()

    # Create collection
    collection_name = "documents"
    try:
        QdrantConfig.create_collection(
            client=client,
            collection_name=collection_name,
            vector_size=1536,
            distance="Cosine"
        )
    except:
        pass  # Collection already exists

    # Initialize store
    store = QdrantVectorStore(client, collection_name)

    # Upsert documents
    ids = store.upsert_documents(
        vectors=[[0.1] * 1536, [0.2] * 1536],  # Your embeddings
        documents=[
            "Machine learning powers modern AI",
            "Natural language processing enables text understanding"
        ],
        metadatas=[
            {"category": "ml", "source": "blog", "rating": 4.5},
            {"category": "nlp", "source": "blog", "rating": 4.8}
        ]
    )
    print(f"Inserted {len(ids)} documents")

    # Create payload indexes for faster filtering
    store.create_payload_index("category", "keyword")
    store.create_payload_index("source", "keyword")
    store.create_payload_index("rating", "float")

    # Search with filter
    results = store.search(
        query_vector=[0.15] * 1536,
        limit=5,
        query_filter=Filter(
            must=[
                FieldCondition(key="category", match=MatchValue(value="ml")),
                FieldCondition(key="rating", range=Range(gte=4.0))
            ]
        ),
        score_threshold=0.5
    )

    for result in results:
        print(f"ID: {result.id}, Score: {result.score:.4f}")
        print(f"Text: {result.payload['text']}")
        print(f"Category: {result.payload['category']}")

    # Batch search
    batch_results = store.search_batch([
        SearchRequest(
            vector=[0.1] * 1536,
            limit=3,
            filter=Filter(must=[
                FieldCondition(key="category", match=MatchValue(value="ml"))
            ])
        ),
        SearchRequest(
            vector=[0.2] * 1536,
            limit=3,
            filter=Filter(must=[
                FieldCondition(key="category", match=MatchValue(value="nlp"))
            ])
        )
    ])

    # Retrieve by IDs
    points = store.retrieve(ids=ids[:2])

    # Scroll with filter
    scrolled, _ = store.scroll(
        scroll_filter=Filter(must=[
            FieldCondition(key="source", match=MatchValue(value="blog"))
        ]),
        limit=10
    )

    # Update payload
    store.update_payload(
        points=[ids[0]],
        payload={"rating": 5.0, "featured": True}
    )

    # Delete payload key
    store.delete_payload(
        points=[ids[0]],
        keys=["featured"]
    )

    # Count with filter
    count = store.count(
        count_filter=Filter(must=[
            FieldCondition(key="category", match=MatchValue(value="ml"))
        ])
    )
    print(f"ML documents: {count}")

    # Delete by filter
    store.delete(
        query_filter=Filter(must=[
            FieldCondition(key="category", match=MatchValue(value="test"))
        ])
    )

    # Get total count
    total = store.count()
    print(f"Total documents: {total}")
