"""
Basic RAG Pipeline Template

A complete implementation of a Retrieval-Augmented Generation pipeline
using LlamaIndex with best practices.

Usage:
    python basic-rag-pipeline.py
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    StorageContext,
    load_index_from_storage,
    Settings,
)
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


class BasicRAGPipeline:
    """
    A simple RAG pipeline implementation with document ingestion,
    indexing, and querying capabilities.
    """

    def __init__(
        self,
        data_dir: str = "./data",
        storage_dir: str = "./storage",
        model: str = "gpt-4o-mini",
        embed_model: str = "text-embedding-3-small",
        temperature: float = 0,
    ):
        """
        Initialize the RAG pipeline.

        Args:
            data_dir: Directory containing documents to index
            storage_dir: Directory to persist the index
            model: LLM model to use for generation
            embed_model: Embedding model for vectorization
            temperature: LLM temperature (0 = deterministic)
        """
        self.data_dir = Path(data_dir)
        self.storage_dir = Path(storage_dir)

        # Configure LlamaIndex settings globally
        Settings.llm = OpenAI(model=model, temperature=temperature)
        Settings.embed_model = OpenAIEmbedding(model=embed_model)

        self.index = None

    def load_or_create_index(self) -> VectorStoreIndex:
        """
        Load existing index or create new one from documents.

        Returns:
            VectorStoreIndex: The loaded or newly created index
        """
        # Try to load existing index
        if self.storage_dir.exists():
            try:
                print(f"Loading existing index from {self.storage_dir}...")
                storage_context = StorageContext.from_defaults(
                    persist_dir=str(self.storage_dir)
                )
                self.index = load_index_from_storage(storage_context)
                print("Index loaded successfully!")
                return self.index
            except Exception as e:
                print(f"Could not load index: {e}")
                print("Creating new index...")

        # Create new index from documents
        if not self.data_dir.exists():
            raise ValueError(f"Data directory not found: {self.data_dir}")

        print(f"Loading documents from {self.data_dir}...")
        documents = SimpleDirectoryReader(
            str(self.data_dir),
            recursive=True,
            required_exts=[".txt", ".pdf", ".md", ".csv", ".json"],
        ).load_data()

        if not documents:
            raise ValueError(f"No documents found in {self.data_dir}")

        print(f"Loaded {len(documents)} documents")
        print("Creating vector index...")

        self.index = VectorStoreIndex.from_documents(
            documents, show_progress=True
        )

        # Persist the index
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        self.index.storage_context.persist(persist_dir=str(self.storage_dir))
        print(f"Index persisted to {self.storage_dir}")

        return self.index

    def query(self, question: str, similarity_top_k: int = 3) -> str:
        """
        Query the index with a question.

        Args:
            question: The question to ask
            similarity_top_k: Number of relevant chunks to retrieve

        Returns:
            str: The generated answer
        """
        if self.index is None:
            self.load_or_create_index()

        query_engine = self.index.as_query_engine(
            similarity_top_k=similarity_top_k
        )

        print(f"\nQuery: {question}")
        response = query_engine.query(question)

        return str(response)

    def query_with_sources(self, question: str, similarity_top_k: int = 3):
        """
        Query the index and return both answer and source documents.

        Args:
            question: The question to ask
            similarity_top_k: Number of relevant chunks to retrieve

        Returns:
            dict: Contains 'response', 'sources', and 'metadata'
        """
        if self.index is None:
            self.load_or_create_index()

        query_engine = self.index.as_query_engine(
            similarity_top_k=similarity_top_k
        )

        print(f"\nQuery: {question}")
        response = query_engine.query(question)

        # Extract source nodes
        sources = []
        for node in response.source_nodes:
            sources.append(
                {
                    "text": node.node.text[:200] + "...",  # First 200 chars
                    "score": node.score,
                    "metadata": node.node.metadata,
                }
            )

        return {
            "response": str(response),
            "sources": sources,
            "num_sources": len(sources),
        }

    def chat(self):
        """
        Interactive chat interface for querying the index.
        """
        if self.index is None:
            self.load_or_create_index()

        chat_engine = self.index.as_chat_engine()

        print("\n=== Interactive Chat ===")
        print("Type 'exit' to quit\n")

        while True:
            try:
                user_input = input("You: ").strip()

                if user_input.lower() in ["exit", "quit", "q"]:
                    print("Goodbye!")
                    break

                if not user_input:
                    continue

                response = chat_engine.chat(user_input)
                print(f"Assistant: {response}\n")

            except KeyboardInterrupt:
                print("\nGoodbye!")
                break
            except Exception as e:
                print(f"Error: {e}\n")


def main():
    """
    Example usage of the BasicRAGPipeline.
    """
    # Initialize pipeline
    pipeline = BasicRAGPipeline(
        data_dir="./data",
        storage_dir="./storage",
        model="gpt-4o-mini",
    )

    # Load or create index
    pipeline.load_or_create_index()

    # Example queries
    examples = [
        "What is the main topic of these documents?",
        "Can you summarize the key points?",
        "What are the most important details?",
    ]

    for question in examples:
        result = pipeline.query_with_sources(question)
        print(f"\nQuestion: {question}")
        print(f"Answer: {result['response']}")
        print(f"\nSources used ({result['num_sources']}):")
        for i, source in enumerate(result["sources"], 1):
            print(f"  {i}. Score: {source['score']:.3f}")
            print(f"     {source['text']}\n")

    # Start interactive chat (optional)
    # pipeline.chat()


if __name__ == "__main__":
    main()
