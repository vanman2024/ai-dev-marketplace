"""
Reranking Template

Reranks initial retrieval results using more powerful models (cross-encoders or LLMs).
Significantly improves relevance by scoring query-document pairs.

Best for:
- Quality-critical applications
- When precision matters more than latency
- Production systems with quality requirements
- After initial hybrid search

Usage:
    # Initial retrieval
    initial_results = hybrid_retriever.retrieve(query, top_k=20)

    # Rerank
    reranker = CohereReranker(api_key=api_key)
    final_results = reranker.rerank(query, initial_results, top_n=5)
"""

from typing import List, Dict, Any, Optional
from dataclasses import dataclass
import os


@dataclass
class RetrievalResult:
    """Single retrieval result"""
    doc_id: str
    content: str
    score: float
    metadata: Dict[str, Any]


# =======================
# Cohere Reranker
# =======================

class CohereReranker:
    """Rerank using Cohere's rerank API"""

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "rerank-english-v3.0"
    ):
        """
        Initialize Cohere reranker.

        Args:
            api_key: Cohere API key (or set COHERE_API_KEY env var)
            model: Rerank model name
        """
        import cohere

        self.api_key = api_key or os.getenv("COHERE_API_KEY")
        self.model = model
        self.client = cohere.Client(self.api_key)

    def rerank(
        self,
        query: str,
        results: List[RetrievalResult],
        top_n: int = 5
    ) -> List[RetrievalResult]:
        """
        Rerank results using Cohere.

        Args:
            query: Search query
            results: Initial retrieval results
            top_n: Number of top results to return

        Returns:
            Reranked results with updated scores
        """
        if not results:
            return []

        # Prepare documents for reranking
        documents = [r.content for r in results]

        # Call Cohere rerank API
        rerank_response = self.client.rerank(
            query=query,
            documents=documents,
            top_n=top_n,
            model=self.model
        )

        # Map reranked results back to original
        reranked = []
        for result in rerank_response.results:
            original = results[result.index]
            reranked_result = RetrievalResult(
                doc_id=original.doc_id,
                content=original.content,
                score=result.relevance_score,  # Cohere relevance score (0-1)
                metadata={**original.metadata, 'rerank_score': result.relevance_score}
            )
            reranked.append(reranked_result)

        return reranked


# =======================
# LlamaIndex Reranker
# =======================

class LlamaIndexReranker:
    """Rerank using LlamaIndex postprocessor"""

    def __init__(
        self,
        reranker_type: str = "cohere",
        api_key: Optional[str] = None
    ):
        """
        Initialize LlamaIndex reranker.

        Args:
            reranker_type: 'cohere' or 'sentence-transformers'
            api_key: API key for Cohere (if using cohere)
        """
        self.reranker_type = reranker_type

        if reranker_type == "cohere":
            from llama_index.postprocessor.cohere_rerank import CohereRerank
            self.reranker = CohereRerank(
                api_key=api_key or os.getenv("COHERE_API_KEY"),
                top_n=10
            )
        elif reranker_type == "sentence-transformers":
            from llama_index.postprocessor import SentenceTransformerRerank
            self.reranker = SentenceTransformerRerank(
                model="cross-encoder/ms-marco-MiniLM-L-2-v2",
                top_n=10
            )
        else:
            raise ValueError(f"Unknown reranker type: {reranker_type}")

    def rerank(
        self,
        query: str,
        results: List[RetrievalResult],
        top_n: int = 5
    ) -> List[RetrievalResult]:
        """Rerank using LlamaIndex postprocessor"""
        from llama_index.core.schema import NodeWithScore, TextNode

        # Convert to LlamaIndex nodes
        nodes = []
        for result in results:
            node = TextNode(
                text=result.content,
                metadata={**result.metadata, 'id': result.doc_id}
            )
            node_with_score = NodeWithScore(node=node, score=result.score)
            nodes.append(node_with_score)

        # Update top_n
        self.reranker.top_n = top_n

        # Rerank
        reranked_nodes = self.reranker.postprocess_nodes(nodes, query_str=query)

        # Convert back to results
        reranked = []
        for node_with_score in reranked_nodes:
            node = node_with_score.node
            reranked_result = RetrievalResult(
                doc_id=node.metadata.get('id', node.node_id),
                content=node.get_content(),
                score=node_with_score.score,
                metadata=node.metadata
            )
            reranked.append(reranked_result)

        return reranked


# =======================
# Cross-Encoder Reranker
# =======================

class CrossEncoderReranker:
    """Rerank using sentence-transformers cross-encoder"""

    def __init__(
        self,
        model_name: str = "cross-encoder/ms-marco-MiniLM-L-6-v2"
    ):
        """
        Initialize cross-encoder reranker.

        Args:
            model_name: Hugging Face cross-encoder model name

        Popular models:
        - cross-encoder/ms-marco-MiniLM-L-6-v2 (fast, 80MB)
        - cross-encoder/ms-marco-MiniLM-L-12-v2 (balanced, 120MB)
        - cross-encoder/ms-marco-TinyBERT-L-2-v2 (tiny, 17MB)
        """
        from sentence_transformers import CrossEncoder

        self.model = CrossEncoder(model_name)

    def rerank(
        self,
        query: str,
        results: List[RetrievalResult],
        top_n: int = 5
    ) -> List[RetrievalResult]:
        """
        Rerank using cross-encoder.

        Args:
            query: Search query
            results: Initial results
            top_n: Number of top results

        Returns:
            Reranked results
        """
        if not results:
            return []

        # Prepare query-document pairs
        pairs = [[query, r.content] for r in results]

        # Score with cross-encoder
        scores = self.model.predict(pairs)

        # Combine results with scores
        scored_results = [
            (results[i], float(scores[i]))
            for i in range(len(results))
        ]

        # Sort by score (descending)
        scored_results.sort(key=lambda x: x[1], reverse=True)

        # Create reranked results
        reranked = []
        for result, score in scored_results[:top_n]:
            reranked_result = RetrievalResult(
                doc_id=result.doc_id,
                content=result.content,
                score=score,
                metadata={**result.metadata, 'cross_encoder_score': score}
            )
            reranked.append(reranked_result)

        return reranked


# =======================
# LLM-Based Reranker
# =======================

class LLMReranker:
    """Rerank using LLM (GPT-4, Claude, etc.)"""

    def __init__(
        self,
        model: str = "gpt-4o-mini",
        provider: str = "openai"
    ):
        """
        Initialize LLM-based reranker.

        Args:
            model: Model name
            provider: 'openai' or 'anthropic'
        """
        self.model = model
        self.provider = provider

        if provider == "openai":
            from openai import OpenAI
            self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        elif provider == "anthropic":
            import anthropic
            self.client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
        else:
            raise ValueError(f"Unknown provider: {provider}")

    def rerank(
        self,
        query: str,
        results: List[RetrievalResult],
        top_n: int = 5
    ) -> List[RetrievalResult]:
        """
        Rerank using LLM relevance scoring.

        Args:
            query: Search query
            results: Initial results
            top_n: Number of top results

        Returns:
            Reranked results
        """
        if not results:
            return []

        # Create prompt
        docs_text = "\n\n".join([
            f"[{i}] {r.content}"
            for i, r in enumerate(results)
        ])

        prompt = f"""Given the query and documents below, rank the documents by relevance to the query.
Return ONLY a JSON array of document indices in order of relevance (most relevant first).

Query: {query}

Documents:
{docs_text}

Output format: [0, 3, 1, 2, ...]
"""

        # Call LLM
        if self.provider == "openai":
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a relevance ranking expert."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0
            )
            ranking_text = response.choices[0].message.content
        else:  # anthropic
            response = self.client.messages.create(
                model=self.model,
                max_tokens=1024,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            ranking_text = response.content[0].text

        # Parse ranking
        import json
        try:
            ranking = json.loads(ranking_text)
        except:
            # Fallback: extract numbers
            import re
            ranking = [int(x) for x in re.findall(r'\d+', ranking_text)]

        # Rerank based on LLM output
        reranked = []
        for rank, idx in enumerate(ranking[:top_n]):
            if 0 <= idx < len(results):
                result = results[idx]
                reranked_result = RetrievalResult(
                    doc_id=result.doc_id,
                    content=result.content,
                    score=1.0 - (rank * 0.1),  # Decreasing score
                    metadata={**result.metadata, 'llm_rank': rank}
                )
                reranked.append(reranked_result)

        return reranked


# =======================
# Reranking Pipeline
# =======================

class RerankingPipeline:
    """Complete retrieval + reranking pipeline"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        reranker_type: str = "cohere"
    ):
        """
        Initialize pipeline.

        Args:
            documents: Document corpus
            reranker_type: 'cohere', 'cross-encoder', or 'llm'
        """
        self.documents = documents
        self.reranker_type = reranker_type

        # Setup retriever (hybrid search)
        self._setup_retriever()

        # Setup reranker
        self._setup_reranker()

    def _setup_retriever(self):
        """Setup hybrid retriever"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain_community.retrievers import BM25Retriever
        from langchain.retrievers import EnsembleRetriever
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        # Hybrid retriever
        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)
        vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 20})

        bm25_retriever = BM25Retriever.from_documents(docs)
        bm25_retriever.k = 20

        self.retriever = EnsembleRetriever(
            retrievers=[vector_retriever, bm25_retriever],
            weights=[0.5, 0.5]
        )

    def _setup_reranker(self):
        """Setup reranker"""
        if self.reranker_type == "cohere":
            self.reranker = CohereReranker()
        elif self.reranker_type == "cross-encoder":
            self.reranker = CrossEncoderReranker()
        elif self.reranker_type == "llm":
            self.reranker = LLMReranker()
        else:
            raise ValueError(f"Unknown reranker: {self.reranker_type}")

    def retrieve_and_rerank(
        self,
        query: str,
        initial_k: int = 20,
        final_k: int = 5
    ) -> List[RetrievalResult]:
        """
        Full pipeline: retrieve → rerank.

        Args:
            query: Search query
            initial_k: Number of candidates from initial retrieval
            final_k: Number of final results after reranking

        Returns:
            Reranked results
        """
        # Step 1: Initial retrieval
        docs = self.retriever.get_relevant_documents(query)

        # Convert to results
        initial_results = [
            RetrievalResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=1.0 - (i * 0.05),
                metadata=doc.metadata
            )
            for i, doc in enumerate(docs[:initial_k])
        ]

        # Step 2: Rerank
        reranked_results = self.reranker.rerank(
            query,
            initial_results,
            top_n=final_k
        )

        return reranked_results


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
            "content": "Deep learning uses neural networks with multiple layers for complex pattern recognition.",
            "metadata": {"source": "ml_guide"}
        },
        {
            "id": "doc3",
            "content": "RAG systems combine retrieval with generation for contextual responses.",
            "metadata": {"source": "rag_guide"}
        }
    ]

    # Example 1: Cross-encoder reranking
    print("=== Cross-Encoder Reranking ===")

    # Initial results (simulated)
    initial_results = [
        RetrievalResult("doc3", documents[2]["content"], 0.95, documents[2]["metadata"]),
        RetrievalResult("doc1", documents[0]["content"], 0.90, documents[0]["metadata"]),
        RetrievalResult("doc2", documents[1]["content"], 0.85, documents[1]["metadata"])
    ]

    reranker = CrossEncoderReranker()
    reranked = reranker.rerank("deep learning neural networks", initial_results, top_n=2)

    for i, result in enumerate(reranked, 1):
        print(f"\n{i}. [{result.doc_id}] Score: {result.score:.3f}")
        print(f"   {result.content[:80]}...")

    # Example 2: Full pipeline with Cohere (requires API key)
    # print("\n=== Full Pipeline with Cohere ===")
    # pipeline = RerankingPipeline(documents, reranker_type="cohere")
    # results = pipeline.retrieve_and_rerank("machine learning", initial_k=10, final_k=3)
    #
    # for result in results:
    #     print(f"\n[{result.doc_id}] Score: {result.score:.3f}")
    #     print(f"{result.content}")

    print("\nNote: Cohere and LLM reranking examples commented out (require API keys)")
