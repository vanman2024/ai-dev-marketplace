#!/usr/bin/env python3
"""
Multi-Document RAG Example

Advanced RAG implementation handling multiple documents with:
- Document segmentation and metadata
- Cross-document reasoning
- Source attribution
- Document-level filtering

Usage:
    python multi-document-rag.py
"""

import os
import sys
from pathlib import Path
from typing import List, Dict
from dotenv import load_dotenv

load_dotenv()

if not os.getenv("OPENAI_API_KEY"):
    print("Error: OPENAI_API_KEY not set")
    sys.exit(1)

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Settings,
    Document,
)
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.schema import MetadataMode
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


class MultiDocumentRAG:
    """
    RAG system for handling multiple documents with advanced features.
    """

    def __init__(self, model: str = "gpt-4o-mini"):
        """Initialize the multi-document RAG system."""
        Settings.llm = OpenAI(model=model, temperature=0)
        Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

        self.documents = []
        self.index = None

    def create_sample_documents(self) -> List[Document]:
        """
        Create sample documents from different domains.

        Returns:
            List of Document objects with metadata
        """
        docs_data = [
            {
                "title": "Python Programming Guide",
                "category": "programming",
                "difficulty": "beginner",
                "author": "Tech Academy",
                "year": 2024,
                "content": """
                    Python is a versatile programming language known for its simplicity.

                    Key Features:
                    - Easy to learn syntax
                    - Rich standard library
                    - Strong community support
                    - Extensive third-party packages

                    Common Use Cases:
                    - Web development (Django, Flask)
                    - Data science and machine learning
                    - Automation and scripting
                    - API development

                    Getting Started:
                    Install Python from python.org, then use pip to install packages.
                    Start with simple scripts and gradually build more complex applications.
                """,
            },
            {
                "title": "Machine Learning Fundamentals",
                "category": "ai",
                "difficulty": "intermediate",
                "author": "AI Research Lab",
                "year": 2024,
                "content": """
                    Machine Learning enables computers to learn from data without explicit programming.

                    Types of ML:
                    - Supervised Learning: Learn from labeled data
                    - Unsupervised Learning: Find patterns in unlabeled data
                    - Reinforcement Learning: Learn through trial and error

                    Popular Algorithms:
                    - Linear Regression
                    - Decision Trees
                    - Neural Networks
                    - Support Vector Machines

                    Tools and Frameworks:
                    - scikit-learn for traditional ML
                    - TensorFlow and PyTorch for deep learning
                    - Pandas for data manipulation
                    - NumPy for numerical computing
                """,
            },
            {
                "title": "REST API Design Best Practices",
                "category": "web",
                "difficulty": "intermediate",
                "author": "Web Dev Institute",
                "year": 2024,
                "content": """
                    REST APIs provide a standardized way for applications to communicate.

                    HTTP Methods:
                    - GET: Retrieve resources
                    - POST: Create new resources
                    - PUT: Update existing resources
                    - DELETE: Remove resources

                    Best Practices:
                    - Use meaningful resource names
                    - Version your API (/v1/, /v2/)
                    - Implement proper error handling
                    - Use appropriate status codes
                    - Document your endpoints

                    Authentication:
                    - API keys for simple auth
                    - OAuth 2.0 for delegated access
                    - JWT tokens for stateless auth

                    Rate Limiting:
                    Implement rate limits to prevent abuse and ensure fair usage.
                """,
            },
            {
                "title": "Cloud Computing Overview",
                "category": "infrastructure",
                "difficulty": "advanced",
                "author": "Cloud Architecture Team",
                "year": 2024,
                "content": """
                    Cloud computing delivers computing services over the internet.

                    Service Models:
                    - IaaS: Infrastructure as a Service (Virtual machines, storage)
                    - PaaS: Platform as a Service (Application hosting)
                    - SaaS: Software as a Service (Ready-to-use applications)

                    Major Providers:
                    - AWS (Amazon Web Services)
                    - Azure (Microsoft)
                    - GCP (Google Cloud Platform)

                    Key Benefits:
                    - Scalability and elasticity
                    - Pay-as-you-go pricing
                    - Global reach
                    - Disaster recovery

                    Common Services:
                    - Compute: EC2, Lambda (AWS)
                    - Storage: S3, Blob Storage
                    - Databases: RDS, DynamoDB
                    - Networking: VPC, Load Balancers
                """,
            },
        ]

        documents = []
        for doc_data in docs_data:
            doc = Document(
                text=doc_data["content"].strip(),
                metadata={
                    "title": doc_data["title"],
                    "category": doc_data["category"],
                    "difficulty": doc_data["difficulty"],
                    "author": doc_data["author"],
                    "year": doc_data["year"],
                },
            )
            documents.append(doc)

        return documents

    def build_index(self, documents: List[Document]):
        """
        Build index from documents with custom parsing.

        Args:
            documents: List of documents to index
        """
        print(f"Building index from {len(documents)} documents...")

        # Configure node parser with metadata
        node_parser = SentenceSplitter(
            chunk_size=512,
            chunk_overlap=50,
        )

        # Create index
        self.index = VectorStoreIndex.from_documents(
            documents,
            node_parser=node_parser,
            show_progress=True,
        )

        self.documents = documents
        print("Index built successfully!")

    def query_by_category(self, query: str, category: str) -> str:
        """
        Query documents filtered by category.

        Args:
            query: The question to ask
            category: Category to filter by

        Returns:
            Response from matching documents
        """
        query_engine = self.index.as_query_engine(
            similarity_top_k=3,
            filters={"category": category},
        )

        response = query_engine.query(query)
        return str(response)

    def cross_document_query(self, query: str) -> Dict:
        """
        Query across all documents with source attribution.

        Args:
            query: The question to ask

        Returns:
            Dict with response and sources by document
        """
        query_engine = self.index.as_query_engine(similarity_top_k=5)
        response = query_engine.query(query)

        # Group sources by document
        sources_by_doc = {}
        for node in response.source_nodes:
            title = node.node.metadata.get("title", "Unknown")
            if title not in sources_by_doc:
                sources_by_doc[title] = []

            sources_by_doc[title].append(
                {
                    "text": node.node.text[:150] + "...",
                    "score": node.score,
                    "category": node.node.metadata.get("category"),
                }
            )

        return {
            "response": str(response),
            "sources_by_document": sources_by_doc,
            "num_documents_used": len(sources_by_doc),
        }

    def compare_documents(self, query: str, doc_titles: List[str]) -> str:
        """
        Compare information across specific documents.

        Args:
            query: What to compare
            doc_titles: List of document titles to compare

        Returns:
            Comparative analysis
        """
        # Filter nodes by document titles
        all_nodes = self.index.docstore.docs

        comparison_prompt = f"""
        Compare the following topic across these documents: {', '.join(doc_titles)}

        Query: {query}

        Provide a structured comparison highlighting similarities and differences.
        """

        query_engine = self.index.as_query_engine()
        response = query_engine.query(comparison_prompt)

        return str(response)


def demo_multi_document_rag():
    """Demonstrate multi-document RAG capabilities."""
    print("=" * 70)
    print("Multi-Document RAG Demo")
    print("=" * 70)

    # Initialize system
    rag = MultiDocumentRAG()

    # Create and index documents
    print("\n1. Creating sample documents...")
    documents = rag.create_sample_documents()
    print(f"   Created {len(documents)} documents:")
    for doc in documents:
        print(f"   - {doc.metadata['title']} ({doc.metadata['category']})")

    print("\n2. Building index...")
    rag.build_index(documents)

    # Example 1: Category-filtered query
    print("\n3. Category-Filtered Query")
    print("-" * 70)
    query = "What are the key features?"
    category = "programming"
    print(f"Query: {query} (Category: {category})")

    response = rag.query_by_category(query, category)
    print(f"\nResponse: {response}")

    # Example 2: Cross-document query
    print("\n\n4. Cross-Document Query")
    print("-" * 70)
    query = "What tools and technologies are mentioned?"
    print(f"Query: {query}")

    result = rag.cross_document_query(query)
    print(f"\nResponse: {result['response']}")
    print(f"\nSources from {result['num_documents_used']} documents:")

    for doc_title, sources in result["sources_by_document"].items():
        print(f"\n  {doc_title}:")
        for source in sources:
            print(f"    - Score: {source['score']:.3f}")
            print(f"      Category: {source['category']}")
            print(f"      {source['text']}")

    # Example 3: Difficulty-based filtering
    print("\n\n5. Difficulty-Based Query")
    print("-" * 70)

    difficulties = ["beginner", "intermediate", "advanced"]
    query = "What should I learn?"

    for difficulty in difficulties:
        # Note: This is a simplified example
        # In production, implement proper metadata filtering
        print(f"\nFor {difficulty} level:")
        response = rag.cross_document_query(
            f"{query} (looking for {difficulty} level content)"
        )
        print(f"  {response['response'][:200]}...")

    # Example 4: Document comparison
    print("\n\n6. Document Comparison")
    print("-" * 70)

    comparison_query = "programming languages and frameworks"
    doc_titles = ["Python Programming Guide", "Machine Learning Fundamentals"]

    print(f"Comparing: {', '.join(doc_titles)}")
    print(f"Topic: {comparison_query}")

    comparison = rag.compare_documents(comparison_query, doc_titles)
    print(f"\nComparison:\n{comparison}")


def interactive_multi_doc_search():
    """Interactive multi-document search."""
    print("\n" + "=" * 70)
    print("Interactive Multi-Document Search")
    print("=" * 70)

    rag = MultiDocumentRAG()
    documents = rag.create_sample_documents()
    rag.build_index(documents)

    # Show available documents
    print("\nAvailable documents:")
    for i, doc in enumerate(documents, 1):
        print(
            f"  {i}. {doc.metadata['title']} "
            f"({doc.metadata['category']}, {doc.metadata['difficulty']})"
        )

    print("\nCommands:")
    print("  /categories - Show available categories")
    print("  /docs       - List documents")
    print("  /exit       - Exit")
    print("\nEnter your query:")

    while True:
        try:
            query = input("\nQuery: ").strip()

            if not query:
                continue

            if query == "/exit":
                print("Goodbye!")
                break

            if query == "/categories":
                categories = set(doc.metadata["category"] for doc in documents)
                print(f"Categories: {', '.join(categories)}")
                continue

            if query == "/docs":
                for i, doc in enumerate(documents, 1):
                    print(f"  {i}. {doc.metadata['title']}")
                continue

            # Perform cross-document search
            result = rag.cross_document_query(query)
            print(f"\nAnswer: {result['response']}")
            print(f"\nUsed {result['num_documents_used']} document(s):")
            for doc_title in result["sources_by_document"].keys():
                print(f"  - {doc_title}")

        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")


if __name__ == "__main__":
    try:
        # Run demo
        demo_multi_document_rag()

        # Start interactive mode
        interactive_multi_doc_search()

        print("\n" + "=" * 70)
        print("Demo completed!")
        print("=" * 70)

    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
