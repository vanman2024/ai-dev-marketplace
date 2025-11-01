#!/usr/bin/env python3
"""
Benchmark Retrieval Performance

Measures latency, throughput, and cost for different retrieval strategies.
Tests semantic search, hybrid search, and reranking performance.

Usage:
    python benchmark-retrieval.py \
        --strategies semantic,hybrid,reranking \
        --queries queries.jsonl \
        --num-runs 100 \
        --output benchmark-results.json

Requirements:
    pip install numpy scipy openai langchain langchain-community faiss-cpu rank-bm25
"""

import argparse
import json
import time
from pathlib import Path
from typing import List, Dict, Any
from dataclasses import dataclass, asdict
import statistics
import numpy as np


@dataclass
class BenchmarkResult:
    """Results from benchmarking a retrieval strategy"""
    strategy: str
    num_queries: int
    latency_p50: float  # milliseconds
    latency_p95: float
    latency_p99: float
    latency_mean: float
    latency_std: float
    throughput: float  # queries per second
    cost_per_query: float  # USD
    total_cost: float
    success_rate: float


class RetrieverBenchmark:
    """Benchmark different retrieval strategies"""

    def __init__(self, documents: List[str], embedding_model: str = "text-embedding-3-small"):
        """Initialize with documents and embedding model"""
        self.documents = documents
        self.embedding_model = embedding_model
        self.retrievers = {}

        # Cost per 1M tokens (adjust based on your models)
        self.costs = {
            "semantic": 0.02 / 1_000_000,  # OpenAI embedding cost
            "hybrid": 0.02 / 1_000_000,    # Same embedding, BM25 is free
            "reranking": 0.15 / 1_000_000  # Includes embedding + reranking
        }

    def setup_semantic_retriever(self):
        """Setup vector-only retriever"""
        try:
            from langchain_openai import OpenAIEmbeddings
            from langchain_community.vectorstores import FAISS
            from langchain.schema import Document

            # Convert to LangChain documents
            docs = [Document(page_content=text) for text in self.documents]

            # Create FAISS index
            embeddings = OpenAIEmbeddings(model=self.embedding_model)
            vectorstore = FAISS.from_documents(docs, embeddings)

            self.retrievers["semantic"] = vectorstore.as_retriever(
                search_kwargs={"k": 5}
            )
            return True
        except Exception as e:
            print(f"Error setting up semantic retriever: {e}")
            return False

    def setup_hybrid_retriever(self):
        """Setup hybrid (vector + BM25) retriever"""
        try:
            from langchain_openai import OpenAIEmbeddings
            from langchain_community.vectorstores import FAISS
            from langchain_community.retrievers import BM25Retriever
            from langchain.retrievers import EnsembleRetriever
            from langchain.schema import Document

            docs = [Document(page_content=text) for text in self.documents]

            # Vector retriever
            embeddings = OpenAIEmbeddings(model=self.embedding_model)
            vectorstore = FAISS.from_documents(docs, embeddings)
            vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 10})

            # BM25 retriever
            bm25_retriever = BM25Retriever.from_documents(docs)
            bm25_retriever.k = 10

            # Ensemble with equal weights
            self.retrievers["hybrid"] = EnsembleRetriever(
                retrievers=[vector_retriever, bm25_retriever],
                weights=[0.5, 0.5]
            )
            return True
        except Exception as e:
            print(f"Error setting up hybrid retriever: {e}")
            return False

    def setup_reranking_retriever(self):
        """Setup retrieval + reranking pipeline"""
        try:
            from langchain_openai import OpenAIEmbeddings, ChatOpenAI
            from langchain_community.vectorstores import FAISS
            from langchain.schema import Document

            docs = [Document(page_content=text) for text in self.documents]

            # Initial retriever (returns more candidates)
            embeddings = OpenAIEmbeddings(model=self.embedding_model)
            vectorstore = FAISS.from_documents(docs, embeddings)

            # Store vectorstore for reranking
            self.vectorstore_for_rerank = vectorstore
            self.llm_for_rerank = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)

            self.retrievers["reranking"] = "custom"  # Custom implementation
            return True
        except Exception as e:
            print(f"Error setting up reranking retriever: {e}")
            return False

    def rerank_results(self, query: str, initial_results: List[Any], top_k: int = 5) -> List[Any]:
        """Rerank results using LLM scoring"""
        if not initial_results:
            return []

        # Simple reranking: score each document
        scores = []
        for doc in initial_results:
            # Compute relevance score (simplified)
            score = self._compute_relevance_score(query, doc.page_content)
            scores.append((doc, score))

        # Sort by score and return top-k
        scores.sort(key=lambda x: x[1], reverse=True)
        return [doc for doc, _ in scores[:top_k]]

    def _compute_relevance_score(self, query: str, document: str) -> float:
        """Simple relevance scoring (can be replaced with LLM or cross-encoder)"""
        # Simple keyword overlap score (for demonstration)
        query_words = set(query.lower().split())
        doc_words = set(document.lower().split())
        overlap = len(query_words.intersection(doc_words))
        return overlap / max(len(query_words), 1)

    def benchmark_strategy(
        self,
        strategy: str,
        queries: List[str],
        num_runs: int = 1
    ) -> BenchmarkResult:
        """Benchmark a specific retrieval strategy"""

        latencies = []
        successes = 0
        total_tokens = 0

        for run in range(num_runs):
            for query in queries:
                start_time = time.time()

                try:
                    # Execute retrieval
                    if strategy == "reranking":
                        # Special handling for reranking
                        initial_retriever = self.vectorstore_for_rerank.as_retriever(
                            search_kwargs={"k": 20}
                        )
                        initial_results = initial_retriever.get_relevant_documents(query)
                        results = self.rerank_results(query, initial_results, top_k=5)
                    else:
                        retriever = self.retrievers.get(strategy)
                        if retriever:
                            results = retriever.get_relevant_documents(query)
                        else:
                            raise ValueError(f"Strategy {strategy} not initialized")

                    # Record latency
                    latency_ms = (time.time() - start_time) * 1000
                    latencies.append(latency_ms)

                    # Estimate tokens (query + results)
                    total_tokens += len(query.split()) * 1.3  # rough estimate
                    if hasattr(results, '__iter__'):
                        for doc in results:
                            if hasattr(doc, 'page_content'):
                                total_tokens += len(doc.page_content.split()) * 1.3

                    successes += 1

                except Exception as e:
                    print(f"Error during retrieval: {e}")
                    continue

        # Calculate statistics
        num_queries = len(queries) * num_runs

        if not latencies:
            return BenchmarkResult(
                strategy=strategy,
                num_queries=num_queries,
                latency_p50=0.0,
                latency_p95=0.0,
                latency_p99=0.0,
                latency_mean=0.0,
                latency_std=0.0,
                throughput=0.0,
                cost_per_query=0.0,
                total_cost=0.0,
                success_rate=0.0
            )

        latencies_sorted = sorted(latencies)
        p50 = latencies_sorted[int(len(latencies) * 0.50)]
        p95 = latencies_sorted[int(len(latencies) * 0.95)]
        p99 = latencies_sorted[int(len(latencies) * 0.99)]

        mean_latency = statistics.mean(latencies)
        std_latency = statistics.stdev(latencies) if len(latencies) > 1 else 0.0

        total_time_seconds = sum(latencies) / 1000
        throughput = num_queries / total_time_seconds if total_time_seconds > 0 else 0.0

        cost_per_token = self.costs.get(strategy, 0.0)
        total_cost = total_tokens * cost_per_token
        cost_per_query = total_cost / num_queries if num_queries > 0 else 0.0

        success_rate = successes / num_queries if num_queries > 0 else 0.0

        return BenchmarkResult(
            strategy=strategy,
            num_queries=num_queries,
            latency_p50=round(p50, 2),
            latency_p95=round(p95, 2),
            latency_p99=round(p99, 2),
            latency_mean=round(mean_latency, 2),
            latency_std=round(std_latency, 2),
            throughput=round(throughput, 2),
            cost_per_query=round(cost_per_query, 6),
            total_cost=round(total_cost, 4),
            success_rate=round(success_rate, 3)
        )


def load_queries(queries_file: Path) -> List[str]:
    """Load queries from JSONL file"""
    queries = []

    if not queries_file.exists():
        print(f"Warning: {queries_file} not found, using default queries")
        return [
            "What is machine learning?",
            "How does neural network training work?",
            "Explain transformer architecture",
            "What are RAG systems?",
            "How to optimize retrieval performance?"
        ]

    try:
        with open(queries_file, 'r') as f:
            for line in f:
                data = json.loads(line.strip())
                if 'query' in data:
                    queries.append(data['query'])
                elif 'text' in data:
                    queries.append(data['text'])
    except Exception as e:
        print(f"Error loading queries: {e}")

    return queries


def load_documents() -> List[str]:
    """Load sample documents for indexing"""
    # Default sample documents
    return [
        "Machine learning is a subset of artificial intelligence that enables systems to learn from data.",
        "Neural networks are computing systems inspired by biological neural networks that process information.",
        "The transformer architecture revolutionized natural language processing with self-attention mechanisms.",
        "RAG (Retrieval Augmented Generation) combines retrieval systems with language models for better responses.",
        "Vector databases enable efficient similarity search for semantic retrieval in AI applications.",
        "Hybrid search combines vector similarity with keyword-based search for improved recall.",
        "Reranking improves retrieval quality by scoring initial candidates with more powerful models.",
        "Embedding models convert text into dense vector representations for semantic search.",
        "BM25 is a probabilistic retrieval function used for keyword-based search.",
        "Reciprocal Rank Fusion combines results from multiple retrievers into a unified ranking."
    ]


def main():
    parser = argparse.ArgumentParser(description="Benchmark retrieval strategies")
    parser.add_argument(
        "--strategies",
        type=str,
        default="semantic,hybrid",
        help="Comma-separated list of strategies to benchmark (semantic,hybrid,reranking)"
    )
    parser.add_argument(
        "--queries",
        type=Path,
        default=Path("queries.jsonl"),
        help="Path to queries JSONL file"
    )
    parser.add_argument(
        "--num-runs",
        type=int,
        default=1,
        help="Number of times to run each query"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("benchmark-results.json"),
        help="Output file for results"
    )
    parser.add_argument(
        "--embedding-model",
        type=str,
        default="text-embedding-3-small",
        help="OpenAI embedding model to use"
    )

    args = parser.parse_args()

    # Load data
    print("Loading queries...")
    queries = load_queries(args.queries)
    print(f"Loaded {len(queries)} queries")

    print("Loading documents...")
    documents = load_documents()
    print(f"Loaded {len(documents)} documents")

    # Initialize benchmark
    benchmark = RetrieverBenchmark(documents, args.embedding_model)

    # Parse strategies
    strategies = [s.strip() for s in args.strategies.split(",")]

    # Setup retrievers
    print("\nSetting up retrievers...")
    setup_methods = {
        "semantic": benchmark.setup_semantic_retriever,
        "hybrid": benchmark.setup_hybrid_retriever,
        "reranking": benchmark.setup_reranking_retriever
    }

    for strategy in strategies:
        if strategy in setup_methods:
            print(f"  Setting up {strategy}...")
            success = setup_methods[strategy]()
            if not success:
                print(f"  Failed to setup {strategy}, skipping...")
                strategies.remove(strategy)

    # Run benchmarks
    print(f"\nRunning benchmarks ({args.num_runs} runs per query)...\n")
    results = {}

    for strategy in strategies:
        print(f"Benchmarking {strategy}...")
        result = benchmark.benchmark_strategy(strategy, queries, args.num_runs)
        results[strategy] = asdict(result)

        # Print summary
        print(f"  Latency p50: {result.latency_p50}ms")
        print(f"  Latency p95: {result.latency_p95}ms")
        print(f"  Throughput: {result.throughput} q/s")
        print(f"  Cost per query: ${result.cost_per_query}")
        print(f"  Success rate: {result.success_rate * 100}%")
        print()

    # Save results
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.output, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"Results saved to {args.output}")


if __name__ == "__main__":
    main()
