"""
Multi-Query Retrieval Template

Generates multiple query variations and fuses results for better recall.
Handles query ambiguity and different phrasings.

Best for:
- Complex or ambiguous queries
- When single query may miss relevant docs
- Exploration scenarios
- Improving recall over precision

Usage:
    retriever = MultiQueryRetriever(documents)
    results = retriever.retrieve(query, num_variations=3, top_k=5)
"""

from typing import List, Dict, Any, Optional, Set
from dataclasses import dataclass
import os


@dataclass
class RetrievalResult:
    """Single retrieval result"""
    doc_id: str
    content: str
    score: float
    metadata: Dict[str, Any]
    queries: List[str]  # Queries that retrieved this doc


# =======================
# LangChain MultiQueryRetriever
# =======================

class MultiQueryRetriever:
    """Multi-query retrieval using LangChain"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o-mini"
    ):
        """
        Initialize multi-query retriever.

        Args:
            documents: Document corpus
            llm_model: LLM for query generation
        """
        self.documents = documents
        self.llm_model = llm_model

        self._setup_retriever()

    def _setup_retriever(self):
        """Setup base retriever and LLM"""
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.retrievers.multi_query import MultiQueryRetriever as LCMultiQuery
        from langchain.schema import Document

        # Convert to documents
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        # Create vector store
        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)
        base_retriever = vectorstore.as_retriever(search_kwargs={"k": 5})

        # Create LLM for query generation
        llm = ChatOpenAI(model=self.llm_model, temperature=0.7)

        # Create multi-query retriever
        self.retriever = LCMultiQuery.from_llm(
            retriever=base_retriever,
            llm=llm
        )

    def retrieve(
        self,
        query: str,
        top_k: int = 5
    ) -> List[RetrievalResult]:
        """
        Retrieve using multiple query variations.

        Args:
            query: Original query
            top_k: Number of final results

        Returns:
            Deduplicated and fused results
        """
        # MultiQueryRetriever automatically generates variations and fuses
        docs = self.retriever.get_relevant_documents(query)

        # Convert to results
        results = []
        for i, doc in enumerate(docs[:top_k]):
            result = RetrievalResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata,
                queries=[query]  # LangChain doesn't expose which queries matched
            )
            results.append(result)

        return results


# =======================
# Custom Multi-Query Implementation
# =======================

class CustomMultiQueryRetriever:
    """Custom multi-query retrieval with explicit query generation"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o-mini"
    ):
        """Initialize custom multi-query retriever"""
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        # Setup base retriever
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)

        self.base_retriever = vectorstore.as_retriever(search_kwargs={"k": 10})
        self.llm = ChatOpenAI(model=llm_model, temperature=0.7)

    def generate_query_variations(
        self,
        query: str,
        num_variations: int = 3
    ) -> List[str]:
        """
        Generate query variations using LLM.

        Args:
            query: Original query
            num_variations: Number of variations to generate

        Returns:
            List of query variations (including original)
        """
        prompt = f"""Generate {num_variations} different variations of the following query.
Each variation should ask the same thing but use different words or phrasing.

Original query: {query}

Return only the variations, one per line, without numbering or bullet points."""

        response = self.llm.invoke(prompt)
        variations_text = response.content

        # Parse variations
        variations = [v.strip() for v in variations_text.split('\n') if v.strip()]

        # Include original query
        all_queries = [query] + variations[:num_variations]

        return all_queries

    def retrieve_with_query(
        self,
        query: str,
        top_k: int = 10
    ) -> List[tuple]:
        """Retrieve for a single query, returning (doc_id, doc, score) tuples"""
        docs = self.base_retriever.get_relevant_documents(query)

        results = []
        for i, doc in enumerate(docs[:top_k]):
            doc_id = doc.metadata.get('id', f'doc_{i}')
            score = 1.0 - (i * 0.05)  # Approximate score
            results.append((doc_id, doc, score))

        return results

    def fuse_results(
        self,
        all_results: Dict[str, List[tuple]],
        fusion_method: str = "rrf"
    ) -> List[tuple]:
        """
        Fuse results from multiple queries.

        Args:
            all_results: Dict mapping query -> [(doc_id, doc, score), ...]
            fusion_method: 'rrf' or 'score_average'

        Returns:
            Fused list of (doc_id, doc, fused_score) tuples
        """
        if fusion_method == "rrf":
            return self._fuse_rrf(all_results)
        elif fusion_method == "score_average":
            return self._fuse_score_average(all_results)
        else:
            raise ValueError(f"Unknown fusion method: {fusion_method}")

    def _fuse_rrf(
        self,
        all_results: Dict[str, List[tuple]],
        k: int = 60
    ) -> List[tuple]:
        """Fuse using Reciprocal Rank Fusion"""

        # Collect all unique docs
        all_docs = {}

        # Calculate RRF scores
        doc_scores = {}

        for query, results in all_results.items():
            for rank, (doc_id, doc, _) in enumerate(results, start=1):
                # Store doc
                if doc_id not in all_docs:
                    all_docs[doc_id] = doc

                # Accumulate RRF score
                if doc_id not in doc_scores:
                    doc_scores[doc_id] = 0.0

                doc_scores[doc_id] += 1.0 / (k + rank)

        # Sort by RRF score
        sorted_docs = sorted(
            doc_scores.keys(),
            key=lambda x: doc_scores[x],
            reverse=True
        )

        # Return fused results
        return [(doc_id, all_docs[doc_id], doc_scores[doc_id]) for doc_id in sorted_docs]

    def _fuse_score_average(
        self,
        all_results: Dict[str, List[tuple]]
    ) -> List[tuple]:
        """Fuse by averaging scores"""

        all_docs = {}
        doc_scores = {}
        doc_counts = {}

        for query, results in all_results.items():
            for doc_id, doc, score in results:
                if doc_id not in all_docs:
                    all_docs[doc_id] = doc
                    doc_scores[doc_id] = 0.0
                    doc_counts[doc_id] = 0

                doc_scores[doc_id] += score
                doc_counts[doc_id] += 1

        # Calculate averages
        avg_scores = {
            doc_id: doc_scores[doc_id] / doc_counts[doc_id]
            for doc_id in doc_scores.keys()
        }

        # Sort by average score
        sorted_docs = sorted(
            avg_scores.keys(),
            key=lambda x: avg_scores[x],
            reverse=True
        )

        return [(doc_id, all_docs[doc_id], avg_scores[doc_id]) for doc_id in sorted_docs]

    def retrieve(
        self,
        query: str,
        num_variations: int = 3,
        top_k: int = 5,
        fusion_method: str = "rrf"
    ) -> List[RetrievalResult]:
        """
        Full multi-query retrieval pipeline.

        Args:
            query: Original query
            num_variations: Number of query variations
            top_k: Number of final results
            fusion_method: 'rrf' or 'score_average'

        Returns:
            Fused and ranked results
        """
        # Generate variations
        queries = self.generate_query_variations(query, num_variations)

        print(f"Generated queries: {queries}")

        # Retrieve for each query
        all_results = {}
        for q in queries:
            results = self.retrieve_with_query(q, top_k=10)
            all_results[q] = results

        # Fuse results
        fused = self.fuse_results(all_results, fusion_method=fusion_method)

        # Track which queries retrieved each doc
        doc_queries = {}
        for q, results in all_results.items():
            for doc_id, _, _ in results:
                if doc_id not in doc_queries:
                    doc_queries[doc_id] = []
                doc_queries[doc_id].append(q)

        # Convert to RetrievalResult
        final_results = []
        for doc_id, doc, score in fused[:top_k]:
            result = RetrievalResult(
                doc_id=doc_id,
                content=doc.page_content,
                score=score,
                metadata=doc.metadata,
                queries=doc_queries.get(doc_id, [query])
            )
            final_results.append(result)

        return final_results


# =======================
# Query Decomposition
# =======================

class QueryDecompositionRetriever:
    """Break complex queries into sub-queries"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o"
    ):
        """Initialize query decomposition retriever"""
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)

        self.base_retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
        self.llm = ChatOpenAI(model=llm_model, temperature=0)

    def decompose_query(self, query: str) -> List[str]:
        """Decompose complex query into simpler sub-queries"""

        prompt = f"""Break down the following complex query into 2-4 simpler sub-queries.
Each sub-query should address a distinct aspect of the original query.

Complex query: {query}

Return only the sub-queries, one per line."""

        response = self.llm.invoke(prompt)
        sub_queries = [q.strip() for q in response.content.split('\n') if q.strip()]

        return sub_queries

    def retrieve(
        self,
        query: str,
        top_k: int = 5
    ) -> List[RetrievalResult]:
        """Retrieve by decomposing query"""

        # Decompose
        sub_queries = self.decompose_query(query)

        print(f"Sub-queries: {sub_queries}")

        # Retrieve for each sub-query
        all_docs = {}
        doc_queries = {}

        for sub_q in sub_queries:
            docs = self.base_retriever.get_relevant_documents(sub_q)

            for doc in docs:
                doc_id = doc.metadata.get('id', 'unknown')
                if doc_id not in all_docs:
                    all_docs[doc_id] = doc
                    doc_queries[doc_id] = []
                doc_queries[doc_id].append(sub_q)

        # Score by number of sub-queries that retrieved each doc
        doc_scores = {
            doc_id: len(queries)
            for doc_id, queries in doc_queries.items()
        }

        # Sort by score
        sorted_docs = sorted(
            doc_scores.keys(),
            key=lambda x: doc_scores[x],
            reverse=True
        )

        # Create results
        results = []
        for doc_id in sorted_docs[:top_k]:
            result = RetrievalResult(
                doc_id=doc_id,
                content=all_docs[doc_id].page_content,
                score=float(doc_scores[doc_id]),
                metadata=all_docs[doc_id].metadata,
                queries=doc_queries[doc_id]
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
            "content": "Deep learning uses neural networks with multiple layers.",
            "metadata": {"source": "ml_guide"}
        },
        {
            "id": "doc3",
            "content": "RAG combines retrieval and generation for better responses.",
            "metadata": {"source": "rag_guide"}
        }
    ]

    # Example 1: LangChain MultiQueryRetriever
    print("=== LangChain Multi-Query ===")
    retriever = MultiQueryRetriever(documents)
    results = retriever.retrieve("machine learning", top_k=3)

    for result in results:
        print(f"\n[{result.doc_id}] {result.content[:60]}...")

    # Example 2: Custom with explicit variations
    print("\n=== Custom Multi-Query with RRF ===")
    custom = CustomMultiQueryRetriever(documents)
    results = custom.retrieve("AI and neural networks", num_variations=2, top_k=3)

    for result in results:
        print(f"\n[{result.doc_id}] Score: {result.score:.3f}")
        print(f"Queries: {result.queries}")
        print(f"{result.content[:60]}...")

    # Example 3: Query decomposition
    print("\n=== Query Decomposition ===")
    decomp = QueryDecompositionRetriever(documents)
    results = decomp.retrieve("How do machine learning and deep learning relate to AI?", top_k=3)

    for result in results:
        print(f"\n[{result.doc_id}] Score: {result.score}")
        print(f"Sub-queries: {result.queries}")
        print(f"{result.content}")
