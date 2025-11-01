"""
Custom Retriever Template

Demonstrates how to build custom retrievers with advanced filtering,
reranking, and hybrid search capabilities.

Usage:
    python custom-retriever.py
"""

import os
from typing import List, Optional
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Settings,
    QueryBundle,
)
from llama_index.core.retrievers import BaseRetriever, VectorIndexRetriever
from llama_index.core.schema import NodeWithScore
from llama_index.core.node_parser import SentenceSplitter
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


class MetadataFilteredRetriever(BaseRetriever):
    """
    Custom retriever that filters results based on metadata.

    Useful for multi-tenant applications, document versioning,
    or access control.
    """

    def __init__(
        self,
        index: VectorStoreIndex,
        similarity_top_k: int = 10,
        metadata_filters: Optional[dict] = None,
    ):
        """
        Initialize the filtered retriever.

        Args:
            index: The vector index to retrieve from
            similarity_top_k: Number of initial results to retrieve
            metadata_filters: Dict of metadata key-value pairs to filter by
        """
        self._index = index
        self._similarity_top_k = similarity_top_k
        self._metadata_filters = metadata_filters or {}

    def _retrieve(self, query_bundle: QueryBundle) -> List[NodeWithScore]:
        """
        Retrieve nodes with metadata filtering.

        Args:
            query_bundle: The query to retrieve documents for

        Returns:
            List of NodeWithScore objects that match filters
        """
        # Get base retriever
        retriever = VectorIndexRetriever(
            index=self._index,
            similarity_top_k=self._similarity_top_k,
        )

        # Retrieve nodes
        nodes = retriever.retrieve(query_bundle)

        # Filter by metadata
        filtered_nodes = []
        for node in nodes:
            matches = True
            for key, value in self._metadata_filters.items():
                if key not in node.node.metadata:
                    matches = False
                    break
                if node.node.metadata[key] != value:
                    matches = False
                    break

            if matches:
                filtered_nodes.append(node)

        return filtered_nodes


class HybridRetriever(BaseRetriever):
    """
    Hybrid retriever combining semantic search with keyword matching.

    Provides better results by combining vector similarity with
    exact keyword matches.
    """

    def __init__(
        self,
        vector_retriever: BaseRetriever,
        similarity_top_k: int = 5,
        keyword_weight: float = 0.3,
    ):
        """
        Initialize hybrid retriever.

        Args:
            vector_retriever: The vector-based retriever
            similarity_top_k: Number of results to return
            keyword_weight: Weight for keyword matching (0-1)
        """
        self._vector_retriever = vector_retriever
        self._similarity_top_k = similarity_top_k
        self._keyword_weight = keyword_weight
        self._vector_weight = 1.0 - keyword_weight

    def _retrieve(self, query_bundle: QueryBundle) -> List[NodeWithScore]:
        """
        Retrieve using hybrid approach.

        Args:
            query_bundle: The query bundle

        Returns:
            Reranked list of nodes
        """
        # Get vector search results
        vector_nodes = self._vector_retriever.retrieve(query_bundle)

        # Extract keywords from query (simple tokenization)
        keywords = set(query_bundle.query_str.lower().split())

        # Rerank based on keyword matching
        reranked_nodes = []
        for node in vector_nodes:
            # Calculate keyword match score
            node_text = node.node.text.lower()
            keyword_matches = sum(
                1 for keyword in keywords if keyword in node_text
            )
            keyword_score = keyword_matches / max(len(keywords), 1)

            # Combine scores
            vector_score = node.score if node.score else 0.5
            hybrid_score = (
                self._vector_weight * vector_score
                + self._keyword_weight * keyword_score
            )

            # Create new node with hybrid score
            reranked_nodes.append(
                NodeWithScore(node=node.node, score=hybrid_score)
            )

        # Sort by hybrid score and return top k
        reranked_nodes.sort(key=lambda x: x.score, reverse=True)
        return reranked_nodes[: self._similarity_top_k]


class RerankedRetriever(BaseRetriever):
    """
    Retriever with reranking based on custom scoring logic.

    Retrieves more candidates initially, then reranks them
    using a more sophisticated scoring mechanism.
    """

    def __init__(
        self,
        base_retriever: BaseRetriever,
        initial_top_k: int = 20,
        final_top_k: int = 5,
        recency_weight: float = 0.2,
    ):
        """
        Initialize reranked retriever.

        Args:
            base_retriever: The base retriever to use
            initial_top_k: Number of candidates to retrieve initially
            final_top_k: Number of results to return after reranking
            recency_weight: Weight for document recency (0-1)
        """
        self._base_retriever = base_retriever
        self._initial_top_k = initial_top_k
        self._final_top_k = final_top_k
        self._recency_weight = recency_weight

    def _retrieve(self, query_bundle: QueryBundle) -> List[NodeWithScore]:
        """
        Retrieve and rerank nodes.

        Args:
            query_bundle: The query bundle

        Returns:
            Reranked list of top nodes
        """
        # Retrieve more candidates
        nodes = self._base_retriever.retrieve(query_bundle)

        # Rerank based on custom logic
        reranked = []
        for node in nodes:
            base_score = node.score if node.score else 0.5

            # Calculate recency score if creation_date exists
            recency_score = 0.5  # Default
            if "creation_date" in node.node.metadata:
                # Simplified recency calculation
                # In production, use actual date comparison
                recency_score = 0.7

            # Calculate document length score (prefer comprehensive docs)
            length_score = min(len(node.node.text) / 1000, 1.0)

            # Combine scores
            final_score = (
                base_score * (1 - self._recency_weight)
                + recency_score * self._recency_weight * 0.5
                + length_score * 0.1
            )

            reranked.append(NodeWithScore(node=node.node, score=final_score))

        # Sort and return top k
        reranked.sort(key=lambda x: x.score, reverse=True)
        return reranked[: self._final_top_k]


def create_custom_retriever_example():
    """
    Example demonstrating custom retrievers.
    """
    # Configure settings
    Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
    Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

    # Load documents
    print("Loading documents...")
    documents = SimpleDirectoryReader("./data", recursive=True).load_data()

    # Add metadata to documents (example)
    for i, doc in enumerate(documents):
        doc.metadata["doc_type"] = "technical" if i % 2 == 0 else "general"
        doc.metadata["priority"] = "high" if i % 3 == 0 else "medium"

    # Create index
    print("Creating index...")
    index = VectorStoreIndex.from_documents(documents)

    # Example 1: Metadata-filtered retriever
    print("\n=== Metadata Filtered Retriever ===")
    filtered_retriever = MetadataFilteredRetriever(
        index=index,
        similarity_top_k=10,
        metadata_filters={"doc_type": "technical"},
    )

    query = "What are the technical specifications?"
    nodes = filtered_retriever.retrieve(query)
    print(f"Found {len(nodes)} technical documents")
    for node in nodes[:3]:
        print(f"  - Score: {node.score:.3f}, Type: {node.node.metadata.get('doc_type')}")

    # Example 2: Hybrid retriever
    print("\n=== Hybrid Retriever ===")
    base_retriever = VectorIndexRetriever(index=index, similarity_top_k=10)
    hybrid_retriever = HybridRetriever(
        vector_retriever=base_retriever,
        similarity_top_k=5,
        keyword_weight=0.3,
    )

    nodes = hybrid_retriever.retrieve(query)
    print(f"Found {len(nodes)} results with hybrid search")
    for node in nodes:
        print(f"  - Score: {node.score:.3f}")

    # Example 3: Reranked retriever
    print("\n=== Reranked Retriever ===")
    reranked_retriever = RerankedRetriever(
        base_retriever=base_retriever,
        initial_top_k=20,
        final_top_k=5,
        recency_weight=0.2,
    )

    nodes = reranked_retriever.retrieve(query)
    print(f"Found {len(nodes)} reranked results")
    for node in nodes:
        print(f"  - Score: {node.score:.3f}")

    # Use custom retriever in query engine
    print("\n=== Using Custom Retriever in Query Engine ===")
    query_engine = index.as_query_engine(retriever=hybrid_retriever)
    response = query_engine.query(query)
    print(f"Response: {response}")


if __name__ == "__main__":
    create_custom_retriever_example()
