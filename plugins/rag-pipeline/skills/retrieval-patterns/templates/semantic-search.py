"""
Semantic Search Template

Pure vector similarity search for RAG retrieval.
Uses embedding models to find semantically similar documents.

Best for:
- Natural language queries
- Conceptual similarity
- Multi-lingual scenarios
- When context/meaning matters more than exact keywords

Usage:
    retriever = SemanticRetriever(documents, embedding_model="text-embedding-3-small")
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


class SemanticRetriever:
    """Vector-based semantic search retriever"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        embedding_model: str = "text-embedding-3-small",
        index_type: str = "faiss"
    ):
        """
        Initialize semantic retriever.

        Args:
            documents: List of documents with 'id', 'content', and optional 'metadata'
            embedding_model: OpenAI embedding model name
            index_type: Vector index type ('faiss', 'chroma', 'pinecone', etc.)
        """
        self.documents = documents
        self.embedding_model = embedding_model
        self.index_type = index_type
        self.retriever = None

        self._setup_retriever()

    def _setup_retriever(self):
        """Setup vector store and retriever"""

        if self.index_type == "faiss":
            self._setup_faiss()
        elif self.index_type == "chroma":
            self._setup_chroma()
        elif self.index_type == "pinecone":
            self._setup_pinecone()
        else:
            raise ValueError(f"Unsupported index type: {self.index_type}")

    def _setup_faiss(self):
        """Setup FAISS vector store (local, in-memory)"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        # Convert to LangChain documents
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        # Create embeddings
        embeddings = OpenAIEmbeddings(model=self.embedding_model)

        # Create FAISS index
        vectorstore = FAISS.from_documents(docs, embeddings)

        # Create retriever
        self.retriever = vectorstore.as_retriever(
            search_type="similarity",
            search_kwargs={"k": 20}  # Retrieve more, filter later
        )

    def _setup_chroma(self):
        """Setup Chroma vector store (persistent, local)"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_community.vectorstores import Chroma
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        embeddings = OpenAIEmbeddings(model=self.embedding_model)

        # Create Chroma collection
        vectorstore = Chroma.from_documents(
            documents=docs,
            embedding=embeddings,
            collection_name="rag_collection",
            persist_directory="./chroma_db"
        )

        self.retriever = vectorstore.as_retriever(
            search_type="similarity",
            search_kwargs={"k": 20}
        )

    def _setup_pinecone(self):
        """Setup Pinecone vector store (cloud, managed)"""
        from langchain_openai import OpenAIEmbeddings
        from langchain_pinecone import PineconeVectorStore
        from langchain.schema import Document
        import os

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        embeddings = OpenAIEmbeddings(model=self.embedding_model)

        # Create Pinecone vector store
        # Requires PINECONE_API_KEY environment variable
        index_name = os.getenv("PINECONE_INDEX_NAME", "rag-index")

        vectorstore = PineconeVectorStore.from_documents(
            documents=docs,
            embedding=embeddings,
            index_name=index_name
        )

        self.retriever = vectorstore.as_retriever(
            search_type="similarity",
            search_kwargs={"k": 20}
        )

    def retrieve(
        self,
        query: str,
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[RetrievalResult]:
        """
        Retrieve semantically similar documents.

        Args:
            query: Search query
            top_k: Number of results to return
            filters: Optional metadata filters

        Returns:
            List of RetrievalResult objects
        """
        # Update search kwargs if needed
        if hasattr(self.retriever, 'search_kwargs'):
            self.retriever.search_kwargs['k'] = max(top_k, 20)

            if filters:
                self.retriever.search_kwargs['filter'] = filters

        # Retrieve documents
        docs = self.retriever.get_relevant_documents(query)

        # Convert to RetrievalResult objects
        results = []
        for i, doc in enumerate(docs[:top_k]):
            result = RetrievalResult(
                doc_id=doc.metadata.get('id', f'doc_{i}'),
                content=doc.page_content,
                score=doc.metadata.get('score', 1.0 - (i * 0.05)),  # Approximate score
                metadata=doc.metadata
            )
            results.append(result)

        return results

    def retrieve_with_scores(
        self,
        query: str,
        top_k: int = 5
    ) -> List[RetrievalResult]:
        """
        Retrieve with explicit similarity scores.

        Args:
            query: Search query
            top_k: Number of results to return

        Returns:
            List of RetrievalResult objects with similarity scores
        """
        # Access vectorstore for similarity search with scores
        vectorstore = self.retriever.vectorstore

        # Perform similarity search with scores
        docs_with_scores = vectorstore.similarity_search_with_score(query, k=top_k)

        results = []
        for doc, score in docs_with_scores:
            result = RetrievalResult(
                doc_id=doc.metadata.get('id', 'unknown'),
                content=doc.page_content,
                score=float(score),
                metadata=doc.metadata
            )
            results.append(result)

        return results


# =======================
# LlamaIndex Implementation
# =======================

class LlamaIndexSemanticRetriever:
    """Semantic retriever using LlamaIndex"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        embedding_model: str = "text-embedding-3-small"
    ):
        """
        Initialize LlamaIndex semantic retriever.

        Args:
            documents: List of documents
            embedding_model: Embedding model name
        """
        from llama_index.core import VectorStoreIndex, Document
        from llama_index.embeddings.openai import OpenAIEmbedding

        # Convert to LlamaIndex documents
        llama_docs = [
            Document(
                text=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        # Setup embedding model
        embed_model = OpenAIEmbedding(model=embedding_model)

        # Create index
        self.index = VectorStoreIndex.from_documents(
            llama_docs,
            embed_model=embed_model
        )

        # Create retriever
        self.retriever = self.index.as_retriever(similarity_top_k=10)

    def retrieve(self, query: str, top_k: int = 5) -> List[RetrievalResult]:
        """Retrieve semantically similar documents"""
        # Update top_k
        self.retriever.similarity_top_k = top_k

        # Retrieve
        nodes = self.retriever.retrieve(query)

        # Convert to results
        results = []
        for node in nodes:
            result = RetrievalResult(
                doc_id=node.metadata.get('id', node.node_id),
                content=node.get_content(),
                score=node.score if hasattr(node, 'score') else 0.0,
                metadata=node.metadata
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
            "metadata": {"source": "ml_guide", "category": "intro"}
        },
        {
            "id": "doc2",
            "content": "Neural networks are inspired by biological neural networks in the brain.",
            "metadata": {"source": "ml_guide", "category": "deep_learning"}
        },
        {
            "id": "doc3",
            "content": "RAG combines retrieval systems with language models for better responses.",
            "metadata": {"source": "rag_guide", "category": "rag"}
        }
    ]

    # Example 1: LangChain FAISS retriever
    print("=== LangChain Semantic Search ===")
    retriever = SemanticRetriever(documents, index_type="faiss")
    results = retriever.retrieve("What is machine learning?", top_k=2)

    for i, result in enumerate(results, 1):
        print(f"\n{i}. [{result.doc_id}] Score: {result.score:.3f}")
        print(f"   {result.content[:100]}...")

    # Example 2: With metadata filtering
    print("\n=== With Metadata Filtering ===")
    results = retriever.retrieve(
        "neural networks",
        top_k=2,
        filters={"category": "deep_learning"}
    )

    for result in results:
        print(f"\n[{result.doc_id}] {result.content}")

    # Example 3: LlamaIndex retriever
    print("\n=== LlamaIndex Semantic Search ===")
    llama_retriever = LlamaIndexSemanticRetriever(documents)
    results = llama_retriever.retrieve("RAG systems", top_k=2)

    for result in results:
        print(f"\n[{result.doc_id}] Score: {result.score:.3f}")
        print(f"{result.content}")
