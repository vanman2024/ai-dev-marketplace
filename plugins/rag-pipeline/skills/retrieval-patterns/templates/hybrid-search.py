"""
Hybrid Search Template

Combines semantic (vector) search with keyword (BM25) search using Reciprocal Rank Fusion.
Provides best recall by leveraging both semantic understanding and exact keyword matching.

Best for:
- Production RAG systems (recommended default)
- Mixed query types (conceptual + factual)
- When you need high recall
- Queries with specific terms or names

Usage:
    retriever = HybridRetriever(documents)
    results = retriever.retrieve(query, top_k=5)
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class RetrievalResult:
    """Single retrieval result with score"""
    doc_id: str
    content: str
    score: float
    metadata: Dict[str, Any]
    source: str  # 'vector', 'bm25', or 'fusion'


class HybridRetriever:
    """Hybrid retriever combining vector search and BM25"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        embedding_model: str = "text-embedding-3-small",
        vector_weight: float = 0.5,
        bm25_weight: float = 0.5,
        rrf_k: int = 60
    ):
        """
        Initialize hybrid retriever.

        Args:
            documents: List of documents with 'id', 'content', and optional 'metadata'
            embedding_model: OpenAI embedding model name
            vector_weight: Weight for vector retriever in ensemble (0.0-1.0)
            bm25_weight: Weight for BM25 retriever in ensemble (0.0-1.0)
            rrf_k: Constant for Reciprocal Rank Fusion (default: 60)
        """
        self.documents = documents
        self.embedding_model = embedding_model
        self.vector_weight = vector_weight
        self.bm25_weight = bm25_weight
        self.rrf_k = rrf_k
        self.retriever = None

        self._setup_retriever()

    def _setup_retriever(self):
        """Setup hybrid retriever with vector and BM25 components"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain_community.retrievers import BM25Retriever
        from langchain.retrievers import EnsembleRetriever
        from langchain.schema import Document

        # Convert to LangChain documents
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        # Setup vector retriever
        embeddings = OpenAIEmbeddings(model=self.embedding_model)
        vectorstore = FAISS.from_documents(docs, embeddings)
        vector_retriever = vectorstore.as_retriever(
            search_type="similarity",
            search_kwargs={"k": 20}
        )

        # Setup BM25 retriever
        bm25_retriever = BM25Retriever.from_documents(docs)
        bm25_retriever.k = 20

        # Create ensemble retriever with RRF
        self.retriever = EnsembleRetriever(
            retrievers=[vector_retriever, bm25_retriever],
            weights=[self.vector_weight, self.bm25_weight]
        )

        # Store individual retrievers for analysis
        self.vector_retriever = vector_retriever
        self.bm25_retriever = bm25_retriever

    def retrieve(
        self,
        query: str,
        top_k: int = 5,
        return_source: bool = False
    ) -> List[RetrievalResult]:
        """
        Retrieve using hybrid search.

        Args:
            query: Search query
            top_k: Number of results to return
            return_source: Whether to include retrieval source in results

        Returns:
            List of RetrievalResult objects
        """
        # Update retriever top-k
        if hasattr(self.retriever.retrievers[0], 'search_kwargs'):
            self.retriever.retrievers[0].search_kwargs['k'] = max(top_k * 2, 20)
        self.retriever.retrievers[1].k = max(top_k * 2, 20)

        # Retrieve with ensemble
        docs = self.retriever.get_relevant_documents(query)

        # Convert to results
        results = []
        for i, doc in enumerate(docs[:top_k]):
            result = RetrievalResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=doc.metadata.get('score', 1.0 - (i * 0.05)),
                metadata=doc.metadata,
                source='fusion'
            )
            results.append(result)

        return results

    def retrieve_with_breakdown(
        self,
        query: str,
        top_k: int = 5
    ) -> Dict[str, List[RetrievalResult]]:
        """
        Retrieve with breakdown showing vector, BM25, and fusion results.

        Args:
            query: Search query
            top_k: Number of results per source

        Returns:
            Dict with 'vector', 'bm25', and 'fusion' result lists
        """
        # Vector results
        vector_docs = self.vector_retriever.get_relevant_documents(query)
        vector_results = [
            RetrievalResult(
                doc_id=doc.metadata.get('id', f'v_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                source='vector'
            )
            for i, doc in enumerate(vector_docs[:top_k])
        ]

        # BM25 results
        bm25_docs = self.bm25_retriever.get_relevant_documents(query)
        bm25_results = [
            RetrievalResult(
                doc_id=doc.metadata.get('id', f'b_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                source='bm25'
            )
            for i, doc in enumerate(bm25_docs[:top_k])
        ]

        # Fusion results
        fusion_results = self.retrieve(query, top_k=top_k)

        return {
            'vector': vector_results,
            'bm25': bm25_results,
            'fusion': fusion_results
        }

    def compute_rrf_score(
        self,
        doc_id: str,
        rankings: List[List[str]],
        k: int = 60
    ) -> float:
        """
        Compute Reciprocal Rank Fusion score for a document.

        RRF(d) = sum(1 / (k + rank_i(d))) for all rankings i

        Args:
            doc_id: Document ID
            rankings: List of ranked document ID lists from different retrievers
            k: RRF constant (default: 60)

        Returns:
            RRF score
        """
        score = 0.0

        for ranking in rankings:
            try:
                rank = ranking.index(doc_id) + 1  # 1-indexed
                score += 1.0 / (k + rank)
            except ValueError:
                # Document not in this ranking
                continue

        return score


# =======================
# Custom RRF Implementation
# =======================

class CustomHybridRetriever:
    """Hybrid retriever with explicit RRF implementation"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        embedding_model: str = "text-embedding-3-small"
    ):
        """Initialize with explicit RRF fusion"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain_community.retrievers import BM25Retriever
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        # Vector retriever
        embeddings = OpenAIEmbeddings(model=embedding_model)
        vectorstore = FAISS.from_documents(docs, embeddings)
        self.vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 20})

        # BM25 retriever
        self.bm25_retriever = BM25Retriever.from_documents(docs)
        self.bm25_retriever.k = 20

    def retrieve_with_rrf(
        self,
        query: str,
        top_k: int = 5,
        rrf_k: int = 60
    ) -> List[RetrievalResult]:
        """
        Retrieve using explicit Reciprocal Rank Fusion.

        Args:
            query: Search query
            top_k: Number of final results
            rrf_k: RRF constant

        Returns:
            List of fused and ranked results
        """
        # Get vector results
        vector_docs = self.vector_retriever.get_relevant_documents(query)
        vector_ranking = [doc.metadata.get('id', f'v_{i}') for i, doc in enumerate(vector_docs)]

        # Get BM25 results
        bm25_docs = self.bm25_retriever.get_relevant_documents(query)
        bm25_ranking = [doc.metadata.get('id', f'b_{i}') for i, doc in enumerate(bm25_docs)]

        # Collect all documents
        all_docs = {}
        for doc in vector_docs + bm25_docs:
            doc_id = doc.metadata.get('id', 'unknown')
            if doc_id not in all_docs:
                all_docs[doc_id] = doc

        # Compute RRF scores
        doc_scores = {}
        for doc_id in all_docs.keys():
            rrf_score = 0.0

            # Vector ranking contribution
            if doc_id in vector_ranking:
                rank = vector_ranking.index(doc_id) + 1
                rrf_score += 1.0 / (rrf_k + rank)

            # BM25 ranking contribution
            if doc_id in bm25_ranking:
                rank = bm25_ranking.index(doc_id) + 1
                rrf_score += 1.0 / (rrf_k + rank)

            doc_scores[doc_id] = rrf_score

        # Sort by RRF score
        sorted_doc_ids = sorted(doc_scores.keys(), key=lambda x: doc_scores[x], reverse=True)

        # Create results
        results = []
        for doc_id in sorted_doc_ids[:top_k]:
            doc = all_docs[doc_id]
            result = RetrievalResult(
                doc_id=doc_id,
                content=doc.page_content,
                score=doc_scores[doc_id],
                metadata=doc.metadata,
                source='rrf_fusion'
            )
            results.append(result)

        return results


# =======================
# Usage Examples
# =======================

if __name__ == "__main__":
    # Sample documents
    documents = [
        {
            "id": "doc1",
            "content": "Machine learning is a subset of AI that enables systems to learn from data.",
            "metadata": {"source": "ml_guide"}
        },
        {
            "id": "doc2",
            "content": "Neural networks process information using interconnected nodes similar to neurons.",
            "metadata": {"source": "ml_guide"}
        },
        {
            "id": "doc3",
            "content": "BM25 is a probabilistic ranking function for keyword search.",
            "metadata": {"source": "ir_guide"}
        },
        {
            "id": "doc4",
            "content": "RAG systems combine retrieval with generation for enhanced responses.",
            "metadata": {"source": "rag_guide"}
        }
    ]

    # Example 1: Basic hybrid search
    print("=== Hybrid Search ===")
    retriever = HybridRetriever(documents)
    results = retriever.retrieve("machine learning neural networks", top_k=3)

    for i, result in enumerate(results, 1):
        print(f"\n{i}. [{result.doc_id}] Score: {result.score:.3f}")
        print(f"   {result.content[:80]}...")

    # Example 2: Compare vector vs BM25 vs fusion
    print("\n=== Retrieval Breakdown ===")
    breakdown = retriever.retrieve_with_breakdown("neural networks", top_k=2)

    print("\nVector Results:")
    for r in breakdown['vector']:
        print(f"  {r.doc_id}: {r.content[:60]}...")

    print("\nBM25 Results:")
    for r in breakdown['bm25']:
        print(f"  {r.doc_id}: {r.content[:60]}...")

    print("\nFusion Results:")
    for r in breakdown['fusion']:
        print(f"  {r.doc_id}: {r.content[:60]}...")

    # Example 3: Custom RRF
    print("\n=== Custom RRF Implementation ===")
    custom_retriever = CustomHybridRetriever(documents)
    results = custom_retriever.retrieve_with_rrf("BM25 ranking", top_k=3, rrf_k=60)

    for result in results:
        print(f"\n[{result.doc_id}] RRF Score: {result.score:.4f}")
        print(f"{result.content}")
