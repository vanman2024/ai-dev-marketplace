"""
Metadata Filtering Example

Demonstrates filtered retrieval using document metadata for access control,
temporal queries, and categorical filtering.

Use cases:
- Multi-tenant applications with data isolation
- Time-based filtering (recent documents)
- Category/tag-based retrieval
- Access control and permissions
- Source-specific searches

Features:
- Pre-filtering before vector search
- Hybrid metadata + semantic filtering
- Dynamic filter construction
- Complex filter expressions
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class FilteredResult:
    """Retrieval result with filter info"""
    doc_id: str
    content: str
    score: float
    metadata: Dict[str, Any]
    matched_filters: List[str]  # Which filters matched


# =======================
# LangChain Metadata Filtering
# =======================

class MetadataFilteredRetriever:
    """Retriever with metadata filtering support"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        vectorstore_type: str = "faiss"
    ):
        """
        Initialize filtered retriever.

        Args:
            documents: Documents with metadata
            vectorstore_type: 'faiss', 'chroma', or 'pinecone'
        """
        self.documents = documents
        self.vectorstore_type = vectorstore_type

        self._setup_retriever()

    def _setup_retriever(self):
        """Setup vector store with metadata support"""
        from langchain_openai import OpenAIEmbeddings
        from langchain.schema import Document

        # Convert to LangChain documents
        docs = [
            Document(
                page_content=doc['content'],
                metadata={
                    'id': doc.get('id', f"doc_{i}"),
                    **doc.get('metadata', {})
                }
            )
            for i, doc in enumerate(self.documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

        if self.vectorstore_type == "faiss":
            from langchain_community.vectorstores import FAISS
            self.vectorstore = FAISS.from_documents(docs, embeddings)

        elif self.vectorstore_type == "chroma":
            from langchain_community.vectorstores import Chroma
            self.vectorstore = Chroma.from_documents(
                documents=docs,
                embedding=embeddings,
                collection_name="filtered_collection"
            )

        elif self.vectorstore_type == "pinecone":
            from langchain_pinecone import PineconeVectorStore
            import os
            index_name = os.getenv("PINECONE_INDEX_NAME", "rag-index")
            self.vectorstore = PineconeVectorStore.from_documents(
                documents=docs,
                embedding=embeddings,
                index_name=index_name
            )

        else:
            raise ValueError(f"Unknown vectorstore: {self.vectorstore_type}")

    def retrieve_with_filter(
        self,
        query: str,
        filter_dict: Optional[Dict[str, Any]] = None,
        top_k: int = 5
    ) -> List[FilteredResult]:
        """
        Retrieve with metadata filtering.

        Args:
            query: Search query
            filter_dict: Metadata filters (e.g., {"category": "ml", "source": "docs"})
            top_k: Number of results

        Returns:
            Filtered results
        """
        # Chroma and Pinecone support native filtering
        if self.vectorstore_type in ["chroma", "pinecone"] and filter_dict:
            docs = self.vectorstore.similarity_search(
                query,
                k=top_k,
                filter=filter_dict
            )
        else:
            # FAISS doesn't support filtering, so post-filter
            docs = self.vectorstore.similarity_search(query, k=top_k * 3)

            if filter_dict:
                filtered_docs = []
                for doc in docs:
                    if self._matches_filter(doc.metadata, filter_dict):
                        filtered_docs.append(doc)
                    if len(filtered_docs) >= top_k:
                        break
                docs = filtered_docs

        # Convert to results
        results = []
        for i, doc in enumerate(docs[:top_k]):
            result = FilteredResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                matched_filters=list(filter_dict.keys()) if filter_dict else []
            )
            results.append(result)

        return results

    def _matches_filter(
        self,
        metadata: Dict[str, Any],
        filter_dict: Dict[str, Any]
    ) -> bool:
        """Check if metadata matches all filter conditions"""
        for key, value in filter_dict.items():
            if metadata.get(key) != value:
                return False
        return True


# =======================
# LlamaIndex Metadata Filtering
# =======================

class LlamaIndexMetadataRetriever:
    """LlamaIndex retriever with metadata filters"""

    def __init__(
        self,
        documents: List[Dict[str, Any]]
    ):
        """Initialize LlamaIndex retriever with metadata"""
        from llama_index.core import VectorStoreIndex, Document
        from llama_index.embeddings.openai import OpenAIEmbedding

        # Convert to LlamaIndex documents
        llama_docs = [
            Document(
                text=doc['content'],
                metadata={
                    'id': doc.get('id', f"doc_{i}"),
                    **doc.get('metadata', {})
                }
            )
            for i, doc in enumerate(documents)
        ]

        # Create index
        embed_model = OpenAIEmbedding(model="text-embedding-3-small")
        self.index = VectorStoreIndex.from_documents(
            llama_docs,
            embed_model=embed_model
        )

    def retrieve_with_filter(
        self,
        query: str,
        filters: Optional[List[Dict[str, Any]]] = None,
        top_k: int = 5
    ) -> List[FilteredResult]:
        """
        Retrieve with LlamaIndex metadata filters.

        Args:
            query: Search query
            filters: List of filter dicts (e.g., [{"key": "category", "value": "ml"}])
            top_k: Number of results

        Returns:
            Filtered results
        """
        from llama_index.core.vector_stores import MetadataFilters, ExactMatchFilter

        # Build metadata filters
        if filters:
            metadata_filters = MetadataFilters(
                filters=[
                    ExactMatchFilter(key=f["key"], value=f["value"])
                    for f in filters
                ]
            )

            retriever = self.index.as_retriever(
                similarity_top_k=top_k,
                filters=metadata_filters
            )
        else:
            retriever = self.index.as_retriever(similarity_top_k=top_k)

        # Retrieve
        nodes = retriever.retrieve(query)

        # Convert to results
        results = []
        for node in nodes:
            result = FilteredResult(
                doc_id=node.metadata.get('id', node.node_id),
                content=node.get_content(),
                score=node.score if hasattr(node, 'score') else 0.0,
                metadata=node.metadata,
                matched_filters=[f["key"] for f in filters] if filters else []
            )
            results.append(result)

        return results


# =======================
# Temporal Filtering
# =======================

class TemporalRetriever:
    """Retriever with time-based filtering"""

    def __init__(
        self,
        documents: List[Dict[str, Any]]
    ):
        """
        Initialize temporal retriever.

        Documents should have 'timestamp' in metadata (ISO format string or datetime)
        """
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        # Convert and parse timestamps
        docs = []
        for i, doc in enumerate(documents):
            metadata = doc.get('metadata', {}).copy()
            metadata['id'] = doc.get('id', f"doc_{i}")

            # Parse timestamp if string
            if 'timestamp' in metadata and isinstance(metadata['timestamp'], str):
                try:
                    metadata['timestamp'] = datetime.fromisoformat(metadata['timestamp'])
                except:
                    pass

            docs.append(Document(
                page_content=doc['content'],
                metadata=metadata
            ))

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        self.vectorstore = FAISS.from_documents(docs, embeddings)

    def retrieve_recent(
        self,
        query: str,
        days: int = 7,
        top_k: int = 5
    ) -> List[FilteredResult]:
        """
        Retrieve documents from the last N days.

        Args:
            query: Search query
            days: Number of days to look back
            top_k: Number of results

        Returns:
            Recent documents matching query
        """
        # Get candidates
        docs = self.vectorstore.similarity_search(query, k=top_k * 3)

        # Filter by timestamp
        cutoff = datetime.now() - timedelta(days=days)
        recent_docs = []

        for doc in docs:
            timestamp = doc.metadata.get('timestamp')
            if timestamp and isinstance(timestamp, datetime) and timestamp >= cutoff:
                recent_docs.append(doc)

            if len(recent_docs) >= top_k:
                break

        # Convert to results
        results = []
        for i, doc in enumerate(recent_docs):
            result = FilteredResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                matched_filters=['timestamp']
            )
            results.append(result)

        return results

    def retrieve_date_range(
        self,
        query: str,
        start_date: datetime,
        end_date: datetime,
        top_k: int = 5
    ) -> List[FilteredResult]:
        """Retrieve documents within date range"""

        docs = self.vectorstore.similarity_search(query, k=top_k * 3)

        filtered_docs = []
        for doc in docs:
            timestamp = doc.metadata.get('timestamp')
            if (timestamp and isinstance(timestamp, datetime) and
                start_date <= timestamp <= end_date):
                filtered_docs.append(doc)

            if len(filtered_docs) >= top_k:
                break

        results = []
        for i, doc in enumerate(filtered_docs):
            result = FilteredResult(
                doc_id=doc.metadata.get('id'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                matched_filters=['date_range']
            )
            results.append(result)

        return results


# =======================
# Multi-Tenant Filtering
# =======================

class MultiTenantRetriever:
    """Retriever with tenant isolation"""

    def __init__(
        self,
        documents: List[Dict[str, Any]]
    ):
        """
        Initialize multi-tenant retriever.

        Documents should have 'tenant_id' in metadata.
        """
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={
                    'id': doc.get('id', f"doc_{i}"),
                    **doc.get('metadata', {})
                }
            )
            for i, doc in enumerate(documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        self.vectorstore = FAISS.from_documents(docs, embeddings)

    def retrieve_for_tenant(
        self,
        query: str,
        tenant_id: str,
        top_k: int = 5
    ) -> List[FilteredResult]:
        """
        Retrieve documents for specific tenant only.

        Args:
            query: Search query
            tenant_id: Tenant identifier
            top_k: Number of results

        Returns:
            Tenant-specific results
        """
        # Retrieve candidates
        docs = self.vectorstore.similarity_search(query, k=top_k * 3)

        # Filter by tenant
        tenant_docs = [
            doc for doc in docs
            if doc.metadata.get('tenant_id') == tenant_id
        ][:top_k]

        results = []
        for i, doc in enumerate(tenant_docs):
            result = FilteredResult(
                doc_id=doc.metadata.get('id'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                matched_filters=['tenant_id']
            )
            results.append(result)

        return results


# =======================
# Usage Examples
# =======================

if __name__ == "__main__":
    # Sample documents with metadata
    documents = [
        {
            "id": "doc1",
            "content": "Machine learning introduction for beginners",
            "metadata": {
                "category": "ml",
                "source": "tutorial",
                "timestamp": "2025-01-15T10:00:00",
                "tenant_id": "tenant_a"
            }
        },
        {
            "id": "doc2",
            "content": "Advanced neural network architectures",
            "metadata": {
                "category": "ml",
                "source": "research",
                "timestamp": "2025-01-20T15:30:00",
                "tenant_id": "tenant_a"
            }
        },
        {
            "id": "doc3",
            "content": "RAG system deployment guide",
            "metadata": {
                "category": "rag",
                "source": "tutorial",
                "timestamp": "2025-01-25T09:00:00",
                "tenant_id": "tenant_b"
            }
        }
    ]

    # Example 1: Category filtering
    print("=== Category Filtering ===")
    retriever = MetadataFilteredRetriever(documents, vectorstore_type="faiss")

    results = retriever.retrieve_with_filter(
        "machine learning",
        filter_dict={"category": "ml"},
        top_k=2
    )

    for result in results:
        print(f"\n[{result.doc_id}] {result.content}")
        print(f"Metadata: {result.metadata}")

    # Example 2: Temporal filtering
    print("\n\n=== Temporal Filtering (Recent) ===")
    temporal = TemporalRetriever(documents)

    recent_results = temporal.retrieve_recent(
        "neural networks",
        days=30,
        top_k=3
    )

    for result in recent_results:
        print(f"\n[{result.doc_id}] {result.metadata.get('timestamp')}")
        print(f"{result.content}")

    # Example 3: Multi-tenant filtering
    print("\n\n=== Multi-Tenant Filtering ===")
    multi_tenant = MultiTenantRetriever(documents)

    tenant_a_results = multi_tenant.retrieve_for_tenant(
        "machine learning",
        tenant_id="tenant_a",
        top_k=3
    )

    print("\nTenant A Results:")
    for result in tenant_a_results:
        print(f"  [{result.doc_id}] {result.content[:50]}...")
