"""
LlamaCloud Integration Template

Demonstrates integration with LlamaCloud for managed parsing,
embedding, and indexing services.

LlamaCloud provides:
- Managed document parsing (LlamaParse)
- Hosted vector indices
- Production-ready infrastructure
- Enterprise features

Usage:
    export LLAMA_CLOUD_API_KEY=your_api_key
    python llamacloud-integration.py
"""

import os
from pathlib import Path
from typing import List, Optional
from dotenv import load_dotenv

load_dotenv()

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Settings,
    Document,
)
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


class LlamaCloudRAG:
    """
    RAG pipeline integrated with LlamaCloud services.

    This template shows the structure for LlamaCloud integration.
    Note: Some features require LlamaCloud API setup.
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "gpt-4o-mini",
    ):
        """
        Initialize LlamaCloud RAG.

        Args:
            api_key: LlamaCloud API key (or set LLAMA_CLOUD_API_KEY env var)
            model: LLM model to use
        """
        self.api_key = api_key or os.getenv("LLAMA_CLOUD_API_KEY")

        if not self.api_key:
            print("Warning: LLAMA_CLOUD_API_KEY not set")
            print("Some features require LlamaCloud API access")

        # Configure settings
        Settings.llm = OpenAI(model=model, temperature=0)
        Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

        self.index = None

    def parse_with_llamaparse(
        self, file_path: str, result_type: str = "markdown"
    ) -> List[Document]:
        """
        Parse documents using LlamaParse managed service.

        LlamaParse excels at:
        - Complex PDFs with tables and charts
        - Multi-column layouts
        - Scanned documents (OCR)
        - Academic papers

        Args:
            file_path: Path to document to parse
            result_type: Output format ("markdown" or "text")

        Returns:
            List of parsed Document objects

        Note:
            This is a template. Actual implementation requires:
            pip install llama-parse
        """
        print(f"Parsing {file_path} with LlamaParse...")

        # Template for LlamaParse integration
        # Uncomment and install llama-parse to use:
        #
        # from llama_parse import LlamaParse
        #
        # parser = LlamaParse(
        #     api_key=self.api_key,
        #     result_type=result_type,
        #     verbose=True,
        # )
        #
        # documents = parser.load_data(file_path)
        # return documents

        # Fallback: Use standard reader
        print("Using standard reader (LlamaParse not configured)")
        reader = SimpleDirectoryReader(input_files=[file_path])
        return reader.load_data()

    def create_managed_index(
        self, documents: List[Document], index_name: str = "my-index"
    ):
        """
        Create a managed index on LlamaCloud.

        Managed indices provide:
        - Automatic scaling
        - High availability
        - Built-in monitoring
        - Version control

        Args:
            documents: Documents to index
            index_name: Name for the managed index

        Note:
            This is a template. Actual implementation requires
            LlamaCloud account and proper setup.
        """
        print(f"Creating managed index: {index_name}")

        # Template for LlamaCloud managed index
        # Uncomment when LlamaCloud is configured:
        #
        # from llama_index.core import CloudIndex
        #
        # cloud_index = CloudIndex(
        #     name=index_name,
        #     api_key=self.api_key,
        #     project_name="my-project"
        # )
        #
        # cloud_index.insert_nodes(documents)
        # self.index = cloud_index

        # Fallback: Create local index
        print("Creating local index (LlamaCloud not configured)")
        self.index = VectorStoreIndex.from_documents(documents)

        return self.index

    def query_managed_index(
        self, index_name: str, query: str, top_k: int = 3
    ) -> str:
        """
        Query a managed LlamaCloud index.

        Args:
            index_name: Name of the managed index
            query: Query string
            top_k: Number of results to retrieve

        Returns:
            Query response
        """
        print(f"Querying managed index: {index_name}")

        # Template for querying LlamaCloud index
        # Uncomment when configured:
        #
        # from llama_index.core import CloudIndex
        #
        # cloud_index = CloudIndex.load(
        #     name=index_name,
        #     api_key=self.api_key
        # )
        #
        # query_engine = cloud_index.as_query_engine(
        #     similarity_top_k=top_k
        # )
        #
        # response = query_engine.query(query)
        # return str(response)

        # Fallback to local index
        if self.index is None:
            raise ValueError("No index available. Create one first.")

        query_engine = self.index.as_query_engine(similarity_top_k=top_k)
        response = query_engine.query(query)
        return str(response)


def production_deployment_template():
    """
    Template for production deployment with LlamaCloud.

    This demonstrates the recommended architecture for
    production RAG applications.
    """
    # Initialize with production settings
    rag = LlamaCloudRAG(model="gpt-4o")

    # 1. Document Processing Pipeline
    print("=== Document Processing ===")

    data_dir = Path("./data")
    if not data_dir.exists():
        print(f"Creating sample data directory: {data_dir}")
        data_dir.mkdir(exist_ok=True)

        # Create sample document
        sample_doc = data_dir / "sample.txt"
        sample_doc.write_text(
            """
            LlamaCloud Integration Guide

            LlamaCloud provides managed infrastructure for LlamaIndex applications.
            It includes LlamaParse for document processing and hosted vector indices.

            Key Features:
            - Automatic scaling and high availability
            - Built-in monitoring and observability
            - Enterprise security and compliance
            - Version control for indices

            Use Cases:
            - Production RAG applications
            - Document intelligence platforms
            - Enterprise search solutions
            - Knowledge management systems
            """
        )

    # Parse documents (with LlamaParse in production)
    documents = []
    for file_path in data_dir.glob("*.txt"):
        docs = rag.parse_with_llamaparse(str(file_path))
        documents.extend(docs)

    print(f"Processed {len(documents)} documents")

    # 2. Create Managed Index (hosted on LlamaCloud)
    print("\n=== Index Creation ===")
    index = rag.create_managed_index(documents, index_name="production-index")

    # 3. Query the Index
    print("\n=== Querying ===")
    queries = [
        "What is LlamaCloud?",
        "What are the key features?",
        "What are common use cases?",
    ]

    for query in queries:
        response = rag.query_managed_index("production-index", query)
        print(f"\nQ: {query}")
        print(f"A: {response}")

    # 4. Production Best Practices
    print("\n=== Production Checklist ===")
    checklist = [
        "Set up environment-specific API keys (dev/staging/prod)",
        "Configure monitoring and alerting",
        "Implement rate limiting and error handling",
        "Set up automated index updates",
        "Configure access controls and authentication",
        "Implement logging and observability",
        "Set up CI/CD for index versioning",
        "Configure backup and disaster recovery",
    ]

    for item in checklist:
        print(f"  ☐ {item}")


def llamaparse_advanced_example():
    """
    Advanced LlamaParse usage patterns.

    LlamaParse is optimized for complex documents like:
    - PDFs with tables and charts
    - Academic papers
    - Financial reports
    - Technical documentation
    """
    print("=== LlamaParse Advanced Patterns ===\n")

    # Configuration options (requires llama-parse package)
    config_examples = {
        "Markdown output with images": {
            "result_type": "markdown",
            "extract_images": True,
        },
        "Table extraction": {
            "result_type": "markdown",
            "preserve_tables": True,
        },
        "Multi-language support": {
            "result_type": "text",
            "language": "auto",  # Auto-detect language
        },
        "High-quality OCR": {
            "result_type": "markdown",
            "premium_mode": True,  # Higher quality, slower
        },
    }

    for name, config in config_examples.items():
        print(f"{name}:")
        for key, value in config.items():
            print(f"  {key}: {value}")
        print()


if __name__ == "__main__":
    print("LlamaCloud Integration Template\n")
    print("=" * 50)

    # Check for API key
    api_key = os.getenv("LLAMA_CLOUD_API_KEY")
    if not api_key:
        print("\nℹ️  LlamaCloud API key not found")
        print("Set LLAMA_CLOUD_API_KEY to use managed services")
        print("\nRunning with local fallbacks...\n")

    # Run production deployment template
    production_deployment_template()

    print("\n" + "=" * 50)
    print("\nFor full LlamaCloud integration:")
    print("1. Sign up at https://cloud.llamaindex.ai/")
    print("2. Get your API key")
    print("3. Install: pip install llama-parse")
    print("4. Set: export LLAMA_CLOUD_API_KEY=your_key")
