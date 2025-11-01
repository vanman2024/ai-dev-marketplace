#!/usr/bin/env python3
"""
Evaluate Retrieval Quality

Measures retrieval quality metrics including precision, recall, MRR, NDCG, and hit rate.
Requires labeled test set with relevance judgments.

Usage:
    python evaluate-retrieval-quality.py \
        --strategy hybrid \
        --test-set labeled-queries.jsonl \
        --k-values 1,3,5,10 \
        --output quality-metrics.json

Test Set Format (JSONL):
    {"query": "What is ML?", "relevant_ids": ["doc1", "doc3", "doc7"]}
    {"query": "Explain RAG", "relevant_ids": ["doc2", "doc5"]}

Requirements:
    pip install numpy scipy openai langchain langchain-community faiss-cpu rank-bm25
"""

import argparse
import json
import math
from pathlib import Path
from typing import List, Dict, Any, Set
from dataclasses import dataclass, asdict
import statistics


@dataclass
class QualityMetrics:
    """Quality metrics for retrieval evaluation"""
    strategy: str
    num_queries: int
    precision: Dict[int, float]  # precision@k for different k values
    recall: Dict[int, float]      # recall@k
    mrr: float                    # Mean Reciprocal Rank
    ndcg: Dict[int, float]        # NDCG@k
    hit_rate: Dict[int, float]    # Hit rate@k


class RetrievalEvaluator:
    """Evaluate retrieval quality using standard metrics"""

    def __init__(self, documents: List[Dict[str, str]]):
        """
        Initialize evaluator with documents.

        Args:
            documents: List of dicts with 'id' and 'content' keys
        """
        self.documents = documents
        self.doc_map = {doc['id']: doc['content'] for doc in documents}
        self.retriever = None

    def setup_retriever(self, strategy: str):
        """Setup specified retrieval strategy"""

        if strategy == "semantic":
            return self._setup_semantic()
        elif strategy == "hybrid":
            return self._setup_hybrid()
        elif strategy == "reranking":
            return self._setup_reranking()
        else:
            raise ValueError(f"Unknown strategy: {strategy}")

    def _setup_semantic(self):
        """Setup semantic (vector-only) retriever"""
        try:
            from langchain_openai import OpenAIEmbeddings
            from langchain_community.vectorstores import FAISS
            from langchain.schema import Document

            # Convert to LangChain documents
            docs = [
                Document(
                    page_content=doc['content'],
                    metadata={'id': doc['id']}
                )
                for doc in self.documents
            ]

            # Create FAISS index
            embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
            vectorstore = FAISS.from_documents(docs, embeddings)

            self.retriever = vectorstore.as_retriever(
                search_kwargs={"k": 20}  # Retrieve more for evaluation
            )
            return True
        except Exception as e:
            print(f"Error setting up semantic retriever: {e}")
            return False

    def _setup_hybrid(self):
        """Setup hybrid (vector + BM25) retriever"""
        try:
            from langchain_openai import OpenAIEmbeddings
            from langchain_community.vectorstores import FAISS
            from langchain_community.retrievers import BM25Retriever
            from langchain.retrievers import EnsembleRetriever
            from langchain.schema import Document

            docs = [
                Document(
                    page_content=doc['content'],
                    metadata={'id': doc['id']}
                )
                for doc in self.documents
            ]

            # Vector retriever
            embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
            vectorstore = FAISS.from_documents(docs, embeddings)
            vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 20})

            # BM25 retriever
            bm25_retriever = BM25Retriever.from_documents(docs)
            bm25_retriever.k = 20

            # Ensemble with equal weights
            self.retriever = EnsembleRetriever(
                retrievers=[vector_retriever, bm25_retriever],
                weights=[0.5, 0.5]
            )
            return True
        except Exception as e:
            print(f"Error setting up hybrid retriever: {e}")
            return False

    def _setup_reranking(self):
        """Setup retrieval + reranking pipeline"""
        # Similar to hybrid but with reranking step
        # For simplicity, using hybrid as base
        return self._setup_hybrid()

    def retrieve(self, query: str, top_k: int = 10) -> List[str]:
        """
        Retrieve documents for a query.

        Args:
            query: Query string
            top_k: Number of results to return

        Returns:
            List of document IDs
        """
        try:
            results = self.retriever.get_relevant_documents(query)

            # Extract document IDs
            doc_ids = []
            for doc in results[:top_k]:
                if hasattr(doc, 'metadata') and 'id' in doc.metadata:
                    doc_ids.append(doc.metadata['id'])

            return doc_ids
        except Exception as e:
            print(f"Error during retrieval: {e}")
            return []

    def calculate_precision_at_k(
        self,
        retrieved: List[str],
        relevant: Set[str],
        k: int
    ) -> float:
        """
        Calculate Precision@k.

        Precision@k = (# relevant docs in top-k) / k
        """
        if k == 0:
            return 0.0

        retrieved_at_k = retrieved[:k]
        relevant_in_top_k = len(set(retrieved_at_k).intersection(relevant))

        return relevant_in_top_k / k

    def calculate_recall_at_k(
        self,
        retrieved: List[str],
        relevant: Set[str],
        k: int
    ) -> float:
        """
        Calculate Recall@k.

        Recall@k = (# relevant docs in top-k) / (total # relevant docs)
        """
        if len(relevant) == 0:
            return 0.0

        retrieved_at_k = retrieved[:k]
        relevant_in_top_k = len(set(retrieved_at_k).intersection(relevant))

        return relevant_in_top_k / len(relevant)

    def calculate_reciprocal_rank(
        self,
        retrieved: List[str],
        relevant: Set[str]
    ) -> float:
        """
        Calculate Reciprocal Rank.

        RR = 1 / rank_of_first_relevant_item
        Returns 0 if no relevant items found.
        """
        for i, doc_id in enumerate(retrieved, start=1):
            if doc_id in relevant:
                return 1.0 / i

        return 0.0

    def calculate_ndcg_at_k(
        self,
        retrieved: List[str],
        relevant: Set[str],
        k: int
    ) -> float:
        """
        Calculate Normalized Discounted Cumulative Gain at k.

        DCG@k = sum((2^rel_i - 1) / log2(i + 1)) for i in 1..k
        NDCG@k = DCG@k / IDCG@k

        Using binary relevance (relevant=1, not relevant=0).
        """
        if k == 0 or len(relevant) == 0:
            return 0.0

        # Calculate DCG
        dcg = 0.0
        for i, doc_id in enumerate(retrieved[:k], start=1):
            rel = 1 if doc_id in relevant else 0
            dcg += (2**rel - 1) / math.log2(i + 1)

        # Calculate IDCG (ideal DCG)
        # Ideal ranking: all relevant docs first
        ideal_ranking = [1] * min(len(relevant), k) + [0] * max(0, k - len(relevant))
        idcg = 0.0
        for i, rel in enumerate(ideal_ranking, start=1):
            idcg += (2**rel - 1) / math.log2(i + 1)

        if idcg == 0:
            return 0.0

        return dcg / idcg

    def calculate_hit_rate_at_k(
        self,
        retrieved: List[str],
        relevant: Set[str],
        k: int
    ) -> float:
        """
        Calculate Hit Rate@k (also called Success Rate).

        Hit Rate = 1 if at least one relevant doc in top-k, else 0
        """
        retrieved_at_k = retrieved[:k]
        has_relevant = len(set(retrieved_at_k).intersection(relevant)) > 0
        return 1.0 if has_relevant else 0.0

    def evaluate(
        self,
        test_set: List[Dict[str, Any]],
        k_values: List[int]
    ) -> QualityMetrics:
        """
        Evaluate retrieval quality on test set.

        Args:
            test_set: List of dicts with 'query' and 'relevant_ids' keys
            k_values: List of k values to evaluate (e.g., [1, 3, 5, 10])

        Returns:
            QualityMetrics object with aggregated metrics
        """
        max_k = max(k_values)

        # Store metrics for each query
        precision_scores = {k: [] for k in k_values}
        recall_scores = {k: [] for k in k_values}
        ndcg_scores = {k: [] for k in k_values}
        hit_rate_scores = {k: [] for k in k_values}
        rr_scores = []

        for item in test_set:
            query = item['query']
            relevant = set(item['relevant_ids'])

            # Retrieve documents
            retrieved = self.retrieve(query, top_k=max_k)

            # Calculate metrics for each k
            for k in k_values:
                precision = self.calculate_precision_at_k(retrieved, relevant, k)
                recall = self.calculate_recall_at_k(retrieved, relevant, k)
                ndcg = self.calculate_ndcg_at_k(retrieved, relevant, k)
                hit_rate = self.calculate_hit_rate_at_k(retrieved, relevant, k)

                precision_scores[k].append(precision)
                recall_scores[k].append(recall)
                ndcg_scores[k].append(ndcg)
                hit_rate_scores[k].append(hit_rate)

            # Calculate RR (only once per query)
            rr = self.calculate_reciprocal_rank(retrieved, relevant)
            rr_scores.append(rr)

        # Calculate mean metrics
        precision_at_k = {
            k: round(statistics.mean(scores), 4)
            for k, scores in precision_scores.items()
        }
        recall_at_k = {
            k: round(statistics.mean(scores), 4)
            for k, scores in recall_scores.items()
        }
        ndcg_at_k = {
            k: round(statistics.mean(scores), 4)
            for k, scores in ndcg_scores.items()
        }
        hit_rate_at_k = {
            k: round(statistics.mean(scores), 4)
            for k, scores in hit_rate_scores.items()
        }
        mrr = round(statistics.mean(rr_scores), 4)

        return QualityMetrics(
            strategy=self.retriever.__class__.__name__,
            num_queries=len(test_set),
            precision=precision_at_k,
            recall=recall_at_k,
            mrr=mrr,
            ndcg=ndcg_at_k,
            hit_rate=hit_rate_at_k
        )


def load_test_set(test_file: Path) -> List[Dict[str, Any]]:
    """Load test set from JSONL file"""
    test_set = []

    if not test_file.exists():
        print(f"Warning: {test_file} not found, using default test set")
        return [
            {
                "query": "What is machine learning?",
                "relevant_ids": ["doc1", "doc2"]
            },
            {
                "query": "Explain transformer architecture",
                "relevant_ids": ["doc3"]
            },
            {
                "query": "How do RAG systems work?",
                "relevant_ids": ["doc4", "doc5"]
            }
        ]

    try:
        with open(test_file, 'r') as f:
            for line in f:
                data = json.loads(line.strip())
                if 'query' in data and 'relevant_ids' in data:
                    test_set.append(data)
    except Exception as e:
        print(f"Error loading test set: {e}")

    return test_set


def load_documents() -> List[Dict[str, str]]:
    """Load sample documents"""
    return [
        {
            "id": "doc1",
            "content": "Machine learning is a subset of artificial intelligence that enables systems to learn from data."
        },
        {
            "id": "doc2",
            "content": "Neural networks are computing systems inspired by biological neural networks that process information."
        },
        {
            "id": "doc3",
            "content": "The transformer architecture revolutionized natural language processing with self-attention mechanisms."
        },
        {
            "id": "doc4",
            "content": "RAG (Retrieval Augmented Generation) combines retrieval systems with language models for better responses."
        },
        {
            "id": "doc5",
            "content": "Vector databases enable efficient similarity search for semantic retrieval in AI applications."
        },
        {
            "id": "doc6",
            "content": "Hybrid search combines vector similarity with keyword-based search for improved recall."
        },
        {
            "id": "doc7",
            "content": "Reranking improves retrieval quality by scoring initial candidates with more powerful models."
        },
        {
            "id": "doc8",
            "content": "Embedding models convert text into dense vector representations for semantic search."
        },
        {
            "id": "doc9",
            "content": "BM25 is a probabilistic retrieval function used for keyword-based search."
        },
        {
            "id": "doc10",
            "content": "Reciprocal Rank Fusion combines results from multiple retrievers into a unified ranking."
        }
    ]


def main():
    parser = argparse.ArgumentParser(description="Evaluate retrieval quality")
    parser.add_argument(
        "--strategy",
        type=str,
        default="hybrid",
        choices=["semantic", "hybrid", "reranking"],
        help="Retrieval strategy to evaluate"
    )
    parser.add_argument(
        "--test-set",
        type=Path,
        default=Path("labeled-queries.jsonl"),
        help="Path to test set JSONL file"
    )
    parser.add_argument(
        "--k-values",
        type=str,
        default="1,3,5,10",
        help="Comma-separated k values for evaluation"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("quality-metrics.json"),
        help="Output file for metrics"
    )

    args = parser.parse_args()

    # Parse k values
    k_values = [int(k.strip()) for k in args.k_values.split(",")]

    # Load data
    print("Loading test set...")
    test_set = load_test_set(args.test_set)
    print(f"Loaded {len(test_set)} test queries")

    print("Loading documents...")
    documents = load_documents()
    print(f"Loaded {len(documents)} documents")

    # Initialize evaluator
    evaluator = RetrievalEvaluator(documents)

    # Setup retriever
    print(f"\nSetting up {args.strategy} retriever...")
    success = evaluator.setup_retriever(args.strategy)
    if not success:
        print(f"Failed to setup {args.strategy} retriever")
        return

    # Evaluate
    print(f"\nEvaluating {args.strategy} on {len(test_set)} queries...\n")
    metrics = evaluator.evaluate(test_set, k_values)

    # Print results
    print(f"Results for {args.strategy}:")
    print(f"  Queries evaluated: {metrics.num_queries}")
    print(f"  MRR: {metrics.mrr}")
    print()

    for k in k_values:
        print(f"  Metrics @ {k}:")
        print(f"    Precision: {metrics.precision[k]}")
        print(f"    Recall: {metrics.recall[k]}")
        print(f"    NDCG: {metrics.ndcg[k]}")
        print(f"    Hit Rate: {metrics.hit_rate[k]}")
        print()

    # Save results
    args.output.parent.mkdir(parents=True, exist_ok=True)

    results = {
        "strategy": metrics.strategy,
        "num_queries": metrics.num_queries,
        "mrr": metrics.mrr,
        **{f"precision@{k}": v for k, v in metrics.precision.items()},
        **{f"recall@{k}": v for k, v in metrics.recall.items()},
        **{f"ndcg@{k}": v for k, v in metrics.ndcg.items()},
        **{f"hit_rate@{k}": v for k, v in metrics.hit_rate.items()}
    }

    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"Results saved to {args.output}")


if __name__ == "__main__":
    main()
