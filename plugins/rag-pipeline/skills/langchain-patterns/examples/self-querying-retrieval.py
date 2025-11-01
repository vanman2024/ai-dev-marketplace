#!/usr/bin/env python3
"""
Self-Querying Retrieval Example
================================

Self-querying retriever with metadata filtering.

Features:
- Natural language to structured query
- Metadata filter generation
- Semantic + metadata search
- Filter validation
- Complex query support

Usage:
    python self-querying-retrieval.py --docs ./docs --query "Recent papers about transformers"
    python self-querying-retrieval.py --docs ./docs --query "Documents from 2024 about RAG"
"""

import argparse
from pathlib import Path
from typing import List, Dict, Any, Optional
from datetime import datetime

from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import Chroma
from langchain.retrievers.self_query.base import SelfQueryRetriever
from langchain.chains.query_constructor.base import AttributeInfo
from langchain_core.documents import Document


class SelfQueryingRAG:
    """Self-querying retrieval RAG system."""

    def __init__(
        self,
        documents_path: str,
        vectorstore_path: str = "./chroma_db",
        model: str = "gpt-4",
        k: int = 4
    ):
        """
        Initialize self-querying RAG.

        Args:
            documents_path: Path to documents
            vectorstore_path: Path to vector store
            model: LLM model name
            k: Number of documents to retrieve
        """
        self.documents_path = Path(documents_path)
        self.vectorstore_path = Path(vectorstore_path)
        self.k = k

        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

        # Initialize LLM
        self.llm = ChatOpenAI(model=model, temperature=0)

        # Define metadata schema
        self.metadata_field_info = self._define_metadata_schema()

        # Document description for the retriever
        self.document_content_description = "Technical documentation and articles"

        # Load or create vector store
        self.vectorstore = self._load_vectorstore()

        # Create self-query retriever
        self.retriever = self._create_retriever()

        print("✓ Self-querying RAG initialized")

    def _define_metadata_schema(self) -> List[AttributeInfo]:
        """
        Define metadata schema for self-querying.

        Returns:
            List of attribute information
        """
        return [
            AttributeInfo(
                name="source",
                description="The source file path of the document",
                type="string"
            ),
            AttributeInfo(
                name="title",
                description="The title of the document",
                type="string"
            ),
            AttributeInfo(
                name="author",
                description="The author of the document",
                type="string"
            ),
            AttributeInfo(
                name="date",
                description="The publication date of the document in YYYY-MM-DD format",
                type="string"
            ),
            AttributeInfo(
                name="category",
                description="The category or topic of the document (e.g., 'tutorial', 'reference', 'blog')",
                type="string"
            ),
            AttributeInfo(
                name="tags",
                description="Tags or keywords associated with the document",
                type="list[string]"
            ),
            AttributeInfo(
                name="year",
                description="The year the document was published",
                type="integer"
            )
        ]

    def _load_vectorstore(self) -> Chroma:
        """Load or create vector store."""
        if self.vectorstore_path.exists() and any(self.vectorstore_path.iterdir()):
            print(f"Loading vector store from {self.vectorstore_path}")
            vectorstore = Chroma(
                persist_directory=str(self.vectorstore_path),
                embedding_function=self.embeddings
            )
            print("✓ Vector store loaded")
            return vectorstore

        # Create new vector store
        print(f"Creating vector store from {self.documents_path}")

        # Load documents with metadata
        documents = self._load_documents_with_metadata()
        print(f"✓ Loaded {len(documents)} documents")

        # Split
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        chunks = splitter.split_documents(documents)
        print(f"✓ Created {len(chunks)} chunks")

        # Create vectorstore
        vectorstore = Chroma.from_documents(
            chunks,
            self.embeddings,
            persist_directory=str(self.vectorstore_path)
        )
        print(f"✓ Vector store saved to {self.vectorstore_path}")

        return vectorstore

    def _load_documents_with_metadata(self) -> List[Document]:
        """
        Load documents and enrich with metadata.

        Returns:
            List of documents with metadata
        """
        # Load documents
        loader = DirectoryLoader(
            str(self.documents_path),
            glob="**/*.txt",
            loader_cls=TextLoader
        )
        documents = loader.load()

        # Enrich with metadata (in real app, extract from doc or filename)
        for doc in documents:
            # Extract filename
            source_path = Path(doc.metadata.get("source", ""))
            filename = source_path.stem

            # Add metadata (example enrichment)
            doc.metadata.update({
                "title": filename.replace("_", " ").title(),
                "author": "Unknown",  # Would extract from document
                "date": datetime.now().strftime("%Y-%m-%d"),  # Would extract from document
                "category": "documentation",  # Would classify from content
                "tags": ["langchain", "rag"],  # Would extract from document
                "year": datetime.now().year  # Would extract from document
            })

        return documents

    def _create_retriever(self) -> SelfQueryRetriever:
        """Create self-query retriever."""
        retriever = SelfQueryRetriever.from_llm(
            llm=self.llm,
            vectorstore=self.vectorstore,
            document_contents=self.document_content_description,
            metadata_field_info=self.metadata_field_info,
            verbose=True
        )

        return retriever

    def query(
        self,
        question: str,
        show_filter: bool = True
    ) -> Dict[str, Any]:
        """
        Query with self-querying retrieval.

        Args:
            question: Natural language query (may include filters)
            show_filter: Show generated filter

        Returns:
            Dictionary with answer and sources
        """
        print(f"\n🔍 Processing query: {question}")

        # Retrieve documents (filter is auto-generated)
        docs = self.retriever.get_relevant_documents(question)

        print(f"✓ Retrieved {len(docs)} documents")

        # Generate answer
        if docs:
            context = "\n\n".join([doc.page_content for doc in docs])

            prompt = f"""Use the following context to answer the question.
If you cannot answer based on the context, say so.

Context:
{context}

Question: {question}

Answer:"""

            response = self.llm.invoke(prompt)
            answer = response.content
        else:
            answer = "No relevant documents found matching the query criteria."

        return {
            "answer": answer,
            "sources": [
                {
                    "content": doc.page_content,
                    "metadata": doc.metadata
                }
                for doc in docs
            ]
        }

    def manual_filter_query(
        self,
        question: str,
        filter_dict: Dict[str, Any]
    ) -> List[Document]:
        """
        Query with manual metadata filter.

        Args:
            question: Search query
            filter_dict: Metadata filter dictionary

        Returns:
            List of documents
        """
        # Perform similarity search with filter
        docs = self.vectorstore.similarity_search(
            question,
            k=self.k,
            filter=filter_dict
        )

        return docs


def main():
    parser = argparse.ArgumentParser(
        description="Self-Querying Retrieval Example"
    )
    parser.add_argument(
        "--docs",
        required=True,
        help="Path to documents directory"
    )
    parser.add_argument(
        "--vectorstore",
        default="./chroma_db",
        help="Path to vector store"
    )
    parser.add_argument(
        "--query",
        required=True,
        help="Natural language query (can include metadata filters)"
    )
    parser.add_argument(
        "--model",
        default="gpt-4",
        help="LLM model to use"
    )
    parser.add_argument(
        "--k",
        type=int,
        default=4,
        help="Number of documents to retrieve"
    )
    parser.add_argument(
        "--manual-filter",
        help="Manual filter as JSON string (e.g., '{\"year\": 2024}')"
    )

    args = parser.parse_args()

    # Initialize self-querying RAG
    rag = SelfQueryingRAG(
        documents_path=args.docs,
        vectorstore_path=args.vectorstore,
        model=args.model,
        k=args.k
    )

    print("\n" + "=" * 60)
    print("Self-Querying Retrieval")
    print("=" * 60)

    # Manual filter mode
    if args.manual_filter:
        import json
        filter_dict = json.loads(args.manual_filter)

        print(f"\nQuery: {args.query}")
        print(f"Filter: {filter_dict}")
        print("-" * 60)

        docs = rag.manual_filter_query(args.query, filter_dict)

        print(f"\n✓ Retrieved {len(docs)} documents")

        for i, doc in enumerate(docs, 1):
            print(f"\n{i}. {doc.page_content[:200]}...")
            print(f"   Metadata: {doc.metadata}")

    # Self-querying mode
    else:
        print(f"\nQuery: {args.query}")
        print("\nNote: The query can include metadata filters in natural language")
        print("Examples:")
        print("  - 'Recent documents about transformers'")
        print("  - 'Papers from 2024 about RAG'")
        print("  - 'Tutorial documents by John Doe'")
        print("-" * 60)

        result = rag.query(args.query)

        print("\n" + "=" * 60)
        print("Answer:")
        print("=" * 60)
        print(f"\n{result['answer']}\n")

        if result["sources"]:
            print("=" * 60)
            print(f"Sources ({len(result['sources'])} documents):")
            print("=" * 60)
            for i, source in enumerate(result["sources"], 1):
                print(f"\n{i}. {source['content'][:300]}...")
                print(f"   Metadata:")
                for key, value in source["metadata"].items():
                    print(f"     {key}: {value}")
        else:
            print("\nNo sources found matching the criteria.")


if __name__ == "__main__":
    main()
