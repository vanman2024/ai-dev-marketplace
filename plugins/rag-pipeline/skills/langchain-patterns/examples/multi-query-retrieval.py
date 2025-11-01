#!/usr/bin/env python3
"""
Multi-Query Retrieval Example
==============================

Multi-query retrieval for better coverage.

Features:
- Query expansion from single question
- Parallel retrieval across queries
- Result deduplication
- Ranked fusion of results
- Improved recall

Usage:
    python multi-query-retrieval.py --docs ./docs --query "What is LangChain?"
    python multi-query-retrieval.py --docs ./docs --query "Explain RAG" --num-queries 5
"""

import argparse
from pathlib import Path
from typing import List, Set
from collections import defaultdict

from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain.retrievers.multi_query import MultiQueryRetriever
from langchain_core.documents import Document
from langchain.chains import RetrievalQA


class MultiQueryRAG:
    """Multi-query retrieval RAG system."""

    def __init__(
        self,
        documents_path: str,
        vectorstore_path: str = "./vectorstore",
        model: str = "gpt-4",
        num_queries: int = 3,
        k: int = 4
    ):
        """
        Initialize multi-query RAG.

        Args:
            documents_path: Path to documents
            vectorstore_path: Path to vector store
            model: LLM model name
            num_queries: Number of queries to generate
            k: Number of documents to retrieve per query
        """
        self.documents_path = Path(documents_path)
        self.vectorstore_path = Path(vectorstore_path)
        self.num_queries = num_queries
        self.k = k

        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

        # Initialize LLM
        self.llm = ChatOpenAI(model=model, temperature=0)

        # Load or create vector store
        self.vectorstore = self._load_vectorstore()

        # Create multi-query retriever
        self.retriever = self._create_retriever()

        # Create QA chain
        self.chain = self._create_chain()

        print("✓ Multi-query RAG initialized")

    def _load_vectorstore(self) -> FAISS:
        """Load or create vector store."""
        if self.vectorstore_path.exists():
            print(f"Loading vector store from {self.vectorstore_path}")
            vectorstore = FAISS.load_local(
                str(self.vectorstore_path),
                self.embeddings,
                allow_dangerous_deserialization=True
            )
            print("✓ Vector store loaded")
            return vectorstore

        # Create new vector store
        print(f"Creating vector store from {self.documents_path}")

        # Load documents
        loader = DirectoryLoader(
            str(self.documents_path),
            glob="**/*.txt",
            loader_cls=TextLoader
        )
        documents = loader.load()
        print(f"✓ Loaded {len(documents)} documents")

        # Split
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        chunks = splitter.split_documents(documents)
        print(f"✓ Created {len(chunks)} chunks")

        # Create vectorstore
        vectorstore = FAISS.from_documents(chunks, self.embeddings)
        vectorstore.save_local(str(self.vectorstore_path))
        print(f"✓ Vector store saved to {self.vectorstore_path}")

        return vectorstore

    def _create_retriever(self) -> MultiQueryRetriever:
        """Create multi-query retriever."""
        base_retriever = self.vectorstore.as_retriever(
            search_kwargs={"k": self.k}
        )

        retriever = MultiQueryRetriever.from_llm(
            retriever=base_retriever,
            llm=self.llm
        )

        return retriever

    def _create_chain(self) -> RetrievalQA:
        """Create QA chain."""
        chain = RetrievalQA.from_chain_type(
            llm=self.llm,
            chain_type="stuff",
            retriever=self.retriever,
            return_source_documents=True
        )
        return chain

    def generate_queries(self, question: str) -> List[str]:
        """
        Generate alternative queries from a single question.

        Args:
            question: Original question

        Returns:
            List of alternative queries
        """
        prompt = f"""You are an AI assistant helping to improve search results.
Generate {self.num_queries} different versions of the following question to retrieve relevant documents from a vector database.
Provide these alternative questions separated by newlines.

Original question: {question}

Alternative questions:"""

        response = self.llm.invoke(prompt)
        queries = [q.strip() for q in response.content.split('\n') if q.strip()]

        # Add original question
        all_queries = [question] + queries[:self.num_queries - 1]

        return all_queries

    def retrieve_with_queries(self, queries: List[str]) -> List[Document]:
        """
        Retrieve documents using multiple queries.

        Args:
            queries: List of queries

        Returns:
            Deduplicated list of documents
        """
        all_docs = []
        seen_content: Set[str] = set()

        print(f"\n🔍 Retrieving with {len(queries)} queries:")
        for i, query in enumerate(queries, 1):
            print(f"  {i}. {query}")

            # Retrieve
            docs = self.vectorstore.similarity_search(query, k=self.k)

            # Deduplicate
            for doc in docs:
                content_hash = hash(doc.page_content)
                if content_hash not in seen_content:
                    seen_content.add(content_hash)
                    all_docs.append(doc)

        print(f"\n✓ Retrieved {len(all_docs)} unique documents")
        return all_docs

    def ranked_fusion(
        self,
        queries: List[str],
        k: int = 60
    ) -> List[Document]:
        """
        Reciprocal Rank Fusion for combining results.

        Args:
            queries: List of queries
            k: RRF constant (default: 60)

        Returns:
            Ranked list of documents
        """
        # Get results for each query
        query_results = []
        for query in queries:
            docs = self.vectorstore.similarity_search(query, k=self.k)
            query_results.append(docs)

        # Calculate RRF scores
        doc_scores = defaultdict(float)
        doc_objects = {}

        for docs in query_results:
            for rank, doc in enumerate(docs, 1):
                doc_id = hash(doc.page_content)
                doc_scores[doc_id] += 1 / (k + rank)
                doc_objects[doc_id] = doc

        # Sort by score
        sorted_docs = sorted(
            doc_scores.items(),
            key=lambda x: x[1],
            reverse=True
        )

        # Return documents
        return [doc_objects[doc_id] for doc_id, _ in sorted_docs]

    def query(
        self,
        question: str,
        use_fusion: bool = True,
        show_queries: bool = True
    ):
        """
        Query with multi-query retrieval.

        Args:
            question: User question
            use_fusion: Use ranked fusion
            show_queries: Show generated queries

        Returns:
            Dictionary with answer and sources
        """
        # Generate queries
        queries = self.generate_queries(question)

        if show_queries:
            print("\n" + "=" * 60)
            print("Generated Queries:")
            print("=" * 60)
            for i, q in enumerate(queries, 1):
                print(f"{i}. {q}")
            print("=" * 60)

        # Retrieve documents
        if use_fusion:
            docs = self.ranked_fusion(queries)
        else:
            docs = self.retrieve_with_queries(queries)

        # Generate answer using retrieved docs
        context = "\n\n".join([doc.page_content for doc in docs[:4]])

        prompt = f"""Use the following context to answer the question.
If you cannot answer based on the context, say so.

Context:
{context}

Question: {question}

Answer:"""

        response = self.llm.invoke(prompt)

        return {
            "answer": response.content,
            "queries": queries,
            "sources": [
                {
                    "content": doc.page_content,
                    "metadata": doc.metadata
                }
                for doc in docs[:4]
            ]
        }


def main():
    parser = argparse.ArgumentParser(
        description="Multi-Query Retrieval Example"
    )
    parser.add_argument(
        "--docs",
        required=True,
        help="Path to documents directory"
    )
    parser.add_argument(
        "--vectorstore",
        default="./vectorstore",
        help="Path to vector store"
    )
    parser.add_argument(
        "--query",
        required=True,
        help="Query to ask"
    )
    parser.add_argument(
        "--model",
        default="gpt-4",
        help="LLM model to use"
    )
    parser.add_argument(
        "--num-queries",
        type=int,
        default=3,
        help="Number of queries to generate"
    )
    parser.add_argument(
        "--k",
        type=int,
        default=4,
        help="Number of documents to retrieve per query"
    )
    parser.add_argument(
        "--no-fusion",
        action="store_true",
        help="Disable ranked fusion"
    )

    args = parser.parse_args()

    # Initialize multi-query RAG
    rag = MultiQueryRAG(
        documents_path=args.docs,
        vectorstore_path=args.vectorstore,
        model=args.model,
        num_queries=args.num_queries,
        k=args.k
    )

    # Query
    print("\n" + "=" * 60)
    print("Original Query:")
    print("=" * 60)
    print(f"\n{args.query}\n")

    result = rag.query(
        args.query,
        use_fusion=not args.no_fusion,
        show_queries=True
    )

    print("\n" + "=" * 60)
    print("Answer:")
    print("=" * 60)
    print(f"\n{result['answer']}\n")

    print("=" * 60)
    print(f"Sources ({len(result['sources'])} documents):")
    print("=" * 60)
    for i, source in enumerate(result["sources"], 1):
        print(f"\n{i}. {source['content'][:300]}...")
        if source["metadata"]:
            print(f"   Metadata: {source['metadata']}")


if __name__ == "__main__":
    main()
