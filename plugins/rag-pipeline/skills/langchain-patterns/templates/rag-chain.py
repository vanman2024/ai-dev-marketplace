"""
RAG Chain Template
==================

Basic RAG (Retrieval-Augmented Generation) chain implementation with
document loading, vector store creation, and retrieval.

Features:
- Multi-format document loading (PDF, TXT, CSV, MD)
- Configurable text splitting
- Vector store persistence
- Basic retrieval chain
- Optional conversation memory

Usage:
    from rag_chain import RAGChain

    # Initialize
    rag = RAGChain(
        documents_path="./docs",
        vectorstore_path="./vectorstore",
        chunk_size=1000,
        chunk_overlap=200
    )

    # Load and index documents
    rag.load_documents()

    # Query
    result = rag.query("What are the main features?")
    print(result)
"""

import os
from pathlib import Path
from typing import List, Optional, Dict, Any

from langchain_community.document_loaders import (
    DirectoryLoader,
    PDFLoader,
    TextLoader,
    CSVLoader,
    UnstructuredMarkdownLoader
)
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain.chains import RetrievalQA, ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from langchain_core.documents import Document


class RAGChain:
    """
    Basic RAG chain implementation.

    Handles document loading, text splitting, vector store creation,
    and retrieval-augmented generation.
    """

    def __init__(
        self,
        documents_path: str,
        vectorstore_path: str = "./vectorstore",
        chunk_size: int = 1000,
        chunk_overlap: int = 200,
        embedding_model: str = "text-embedding-3-small",
        llm_model: str = "gpt-4",
        temperature: float = 0,
        use_conversation_memory: bool = False
    ):
        """
        Initialize RAG chain.

        Args:
            documents_path: Path to documents directory or file
            vectorstore_path: Path to save/load vector store
            chunk_size: Size of text chunks
            chunk_overlap: Overlap between chunks
            embedding_model: OpenAI embedding model name
            llm_model: OpenAI LLM model name
            temperature: LLM temperature (0-1)
            use_conversation_memory: Enable conversation history
        """
        self.documents_path = Path(documents_path)
        self.vectorstore_path = Path(vectorstore_path)
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap

        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(model=embedding_model)

        # Initialize LLM
        self.llm = ChatOpenAI(model=llm_model, temperature=temperature)

        # Initialize components
        self.vectorstore: Optional[FAISS] = None
        self.chain: Optional[Any] = None
        self.memory: Optional[ConversationBufferMemory] = None
        self.use_conversation_memory = use_conversation_memory

        if use_conversation_memory:
            self.memory = ConversationBufferMemory(
                memory_key="chat_history",
                return_messages=True,
                output_key="answer"
            )

    def load_documents(self, force_reload: bool = False) -> int:
        """
        Load documents and create vector store.

        Args:
            force_reload: Force reload even if vectorstore exists

        Returns:
            Number of documents loaded
        """
        # Check if vectorstore already exists
        if self.vectorstore_path.exists() and not force_reload:
            print(f"Loading existing vector store from {self.vectorstore_path}")
            self.vectorstore = FAISS.load_local(
                str(self.vectorstore_path),
                self.embeddings,
                allow_dangerous_deserialization=True
            )
            print("✓ Vector store loaded")
            self._create_chain()
            return -1  # Unknown document count for existing store

        # Load documents
        documents = self._load_documents_from_path()
        print(f"✓ Loaded {len(documents)} documents")

        # Split documents
        chunks = self._split_documents(documents)
        print(f"✓ Created {len(chunks)} text chunks")

        # Create vector store
        self.vectorstore = FAISS.from_documents(chunks, self.embeddings)
        print("✓ Vector store created")

        # Save vector store
        self.vectorstore.save_local(str(self.vectorstore_path))
        print(f"✓ Vector store saved to {self.vectorstore_path}")

        # Create chain
        self._create_chain()

        return len(documents)

    def _load_documents_from_path(self) -> List[Document]:
        """Load documents from path (file or directory)."""
        documents = []

        if self.documents_path.is_file():
            # Single file
            loader = self._get_loader_for_file(self.documents_path)
            documents = loader.load()

        elif self.documents_path.is_dir():
            # Directory - load all supported formats
            loaders = [
                (PDFLoader, "**/*.pdf"),
                (TextLoader, "**/*.txt"),
                (UnstructuredMarkdownLoader, "**/*.md"),
                (CSVLoader, "**/*.csv")
            ]

            for loader_cls, glob_pattern in loaders:
                try:
                    dir_loader = DirectoryLoader(
                        str(self.documents_path),
                        glob=glob_pattern,
                        loader_cls=loader_cls
                    )
                    docs = dir_loader.load()
                    documents.extend(docs)
                except Exception as e:
                    print(f"Warning: Could not load {glob_pattern}: {e}")

        else:
            raise ValueError(f"Invalid path: {self.documents_path}")

        if not documents:
            raise ValueError("No documents loaded. Check the documents path.")

        return documents

    def _get_loader_for_file(self, file_path: Path):
        """Get appropriate loader for file type."""
        suffix = file_path.suffix.lower()

        loaders = {
            '.pdf': PDFLoader,
            '.txt': TextLoader,
            '.md': UnstructuredMarkdownLoader,
            '.csv': CSVLoader
        }

        loader_cls = loaders.get(suffix, TextLoader)
        return loader_cls(str(file_path))

    def _split_documents(self, documents: List[Document]) -> List[Document]:
        """Split documents into chunks."""
        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=self.chunk_size,
            chunk_overlap=self.chunk_overlap,
            length_function=len,
            is_separator_regex=False
        )
        return text_splitter.split_documents(documents)

    def _create_chain(self):
        """Create retrieval chain."""
        if self.vectorstore is None:
            raise ValueError("Vector store not initialized. Call load_documents() first.")

        retriever = self.vectorstore.as_retriever(
            search_kwargs={"k": 4}  # Retrieve top 4 documents
        )

        if self.use_conversation_memory and self.memory:
            # Conversational chain
            self.chain = ConversationalRetrievalChain.from_llm(
                llm=self.llm,
                retriever=retriever,
                memory=self.memory,
                return_source_documents=True
            )
        else:
            # Basic QA chain
            self.chain = RetrievalQA.from_chain_type(
                llm=self.llm,
                chain_type="stuff",
                retriever=retriever,
                return_source_documents=True
            )

        print("✓ Retrieval chain created")

    def query(
        self,
        question: str,
        return_sources: bool = True
    ) -> Dict[str, Any]:
        """
        Query the RAG chain.

        Args:
            question: Question to ask
            return_sources: Include source documents in response

        Returns:
            Dictionary with answer and optionally source documents
        """
        if self.chain is None:
            raise ValueError("Chain not initialized. Call load_documents() first.")

        if self.use_conversation_memory:
            result = self.chain({"question": question})
            answer = result["answer"]
        else:
            result = self.chain.invoke({"query": question})
            answer = result["result"]

        response = {"answer": answer}

        if return_sources and "source_documents" in result:
            response["sources"] = [
                {
                    "content": doc.page_content,
                    "metadata": doc.metadata
                }
                for doc in result["source_documents"]
            ]

        return response

    def similarity_search(
        self,
        query: str,
        k: int = 4
    ) -> List[Document]:
        """
        Perform similarity search without LLM.

        Args:
            query: Search query
            k: Number of results to return

        Returns:
            List of similar documents
        """
        if self.vectorstore is None:
            raise ValueError("Vector store not initialized. Call load_documents() first.")

        return self.vectorstore.similarity_search(query, k=k)


# Example usage
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="RAG Chain Example")
    parser.add_argument("--docs", required=True, help="Path to documents")
    parser.add_argument("--vectorstore", default="./vectorstore", help="Vector store path")
    parser.add_argument("--query", required=True, help="Query to ask")
    parser.add_argument("--conversational", action="store_true", help="Use conversation memory")
    parser.add_argument("--reload", action="store_true", help="Force reload documents")

    args = parser.parse_args()

    # Initialize RAG chain
    rag = RAGChain(
        documents_path=args.docs,
        vectorstore_path=args.vectorstore,
        use_conversation_memory=args.conversational
    )

    # Load documents
    print("Loading documents...")
    rag.load_documents(force_reload=args.reload)

    # Query
    print(f"\nQuery: {args.query}")
    print("-" * 50)
    result = rag.query(args.query)

    print("\nAnswer:")
    print(result["answer"])

    if "sources" in result:
        print(f"\n\nSources ({len(result['sources'])} documents):")
        for i, source in enumerate(result["sources"], 1):
            print(f"\n{i}. {source['content'][:200]}...")
            if source['metadata']:
                print(f"   Metadata: {source['metadata']}")
