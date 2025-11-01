#!/usr/bin/env python3
"""
Question Answering Example

Complete working example of a Q&A system using LlamaIndex.
Demonstrates document loading, indexing, and querying with citations.

Usage:
    python question-answering.py
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Check for OpenAI API key
if not os.getenv("OPENAI_API_KEY"):
    print("Error: OPENAI_API_KEY environment variable not set")
    print("Please set it in your .env file or export it:")
    print("  export OPENAI_API_KEY=your_key_here")
    sys.exit(1)

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Settings,
    Document,
)
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


def setup_sample_documents():
    """Create sample documents about LlamaIndex for testing."""
    data_dir = Path("./data")
    data_dir.mkdir(exist_ok=True)

    # Sample document about LlamaIndex
    content = """
    LlamaIndex Overview

    LlamaIndex is a data framework for LLM-based applications to ingest,
    structure, and access private or domain-specific data. It provides
    tools to connect data sources, create indices, and query information
    using natural language.

    Key Components:

    1. Data Connectors
    Data connectors (also called readers) ingest data from various sources:
    - Files (PDF, Word, Markdown, etc.)
    - APIs (Google Docs, Notion, Slack, etc.)
    - Databases (SQL, MongoDB, etc.)
    - Web pages and websites

    2. Data Indices
    Indices store data in a format optimized for LLM queries:
    - VectorStoreIndex: Most common, uses embeddings
    - TreeIndex: Hierarchical structure
    - ListIndex: Simple sequential storage
    - KeywordTableIndex: Keyword-based retrieval

    3. Query Engines
    Query engines provide interfaces for asking questions:
    - Retrieve relevant context from indices
    - Synthesize responses using LLMs
    - Support follow-up questions
    - Can cite sources

    4. Chat Engines
    Chat engines enable conversational interactions:
    - Maintain conversation history
    - Context-aware responses
    - Memory management
    - Streaming support

    Common Use Cases:

    Question Answering: Build systems that answer questions over
    your documents with citations and source attribution.

    Semantic Search: Find relevant information using natural language
    queries instead of keywords.

    Summarization: Generate summaries of documents or collections
    of documents on specific topics.

    Chatbots: Create conversational AI assistants with knowledge
    about your specific domain.

    Getting Started:

    1. Install: pip install llama-index
    2. Set API key: export OPENAI_API_KEY=your_key
    3. Load documents: documents = SimpleDirectoryReader('data').load_data()
    4. Create index: index = VectorStoreIndex.from_documents(documents)
    5. Query: response = index.as_query_engine().query("Your question")

    Best Practices:

    - Chunk documents appropriately (default 1024 tokens)
    - Use metadata for filtering and organization
    - Persist indices to avoid rebuilding
    - Configure embeddings based on use case
    - Monitor token usage and costs
    - Implement error handling and retries
    """

    doc_path = data_dir / "llamaindex-overview.txt"
    doc_path.write_text(content)

    print(f"Created sample document: {doc_path}")
    return data_dir


def question_answering_demo():
    """
    Demonstrate question answering with LlamaIndex.
    """
    print("=" * 60)
    print("LlamaIndex Question Answering Demo")
    print("=" * 60)

    # Configure LlamaIndex
    Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
    Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

    # Setup sample documents
    print("\n1. Setting up sample documents...")
    data_dir = setup_sample_documents()

    # Load documents
    print("\n2. Loading documents...")
    documents = SimpleDirectoryReader(str(data_dir)).load_data()
    print(f"   Loaded {len(documents)} document(s)")
    print(f"   Total characters: {sum(len(doc.text) for doc in documents):,}")

    # Create index
    print("\n3. Creating vector index...")
    index = VectorStoreIndex.from_documents(documents, show_progress=True)
    print("   Index created successfully!")

    # Create query engine
    query_engine = index.as_query_engine(
        similarity_top_k=3,  # Retrieve top 3 relevant chunks
        response_mode="compact",  # Compact response synthesis
    )

    # Example questions
    questions = [
        "What is LlamaIndex?",
        "What are the key components of LlamaIndex?",
        "How do I get started with LlamaIndex?",
        "What is a VectorStoreIndex?",
        "What are common use cases for LlamaIndex?",
        "What are the best practices when using LlamaIndex?",
    ]

    print("\n4. Question Answering:")
    print("=" * 60)

    for i, question in enumerate(questions, 1):
        print(f"\nQuestion {i}: {question}")
        print("-" * 60)

        # Query the index
        response = query_engine.query(question)

        print(f"Answer: {response}")

        # Show source information
        if hasattr(response, "source_nodes") and response.source_nodes:
            print(f"\nSources ({len(response.source_nodes)}):")
            for j, node in enumerate(response.source_nodes, 1):
                score = node.score if hasattr(node, "score") else "N/A"
                text_preview = node.node.text[:100].replace("\n", " ")
                print(f"  {j}. Score: {score}")
                print(f"     Preview: {text_preview}...")

        print()

    # Interactive mode
    print("\n" + "=" * 60)
    print("Interactive Mode")
    print("=" * 60)
    print("Ask your own questions (type 'exit' to quit)")

    while True:
        try:
            question = input("\nYour question: ").strip()

            if question.lower() in ["exit", "quit", "q"]:
                print("Goodbye!")
                break

            if not question:
                continue

            response = query_engine.query(question)
            print(f"\nAnswer: {response}")

            # Show sources
            if hasattr(response, "source_nodes") and response.source_nodes:
                print(f"\nCitations:")
                for j, node in enumerate(response.source_nodes, 1):
                    score = node.score if hasattr(node, "score") else "N/A"
                    print(f"  [{j}] Relevance: {score}")

        except KeyboardInterrupt:
            print("\n\nGoodbye!")
            break
        except Exception as e:
            print(f"\nError: {e}")
            print("Please try again.")


def advanced_qa_features():
    """
    Demonstrate advanced Q&A features.
    """
    print("\n" + "=" * 60)
    print("Advanced Features")
    print("=" * 60)

    Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
    Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

    # Create sample documents with metadata
    docs = [
        Document(
            text="Python is a high-level programming language.",
            metadata={"category": "programming", "difficulty": "beginner"},
        ),
        Document(
            text="Machine learning uses statistical techniques.",
            metadata={"category": "ai", "difficulty": "advanced"},
        ),
        Document(
            text="REST APIs use HTTP methods like GET and POST.",
            metadata={"category": "web", "difficulty": "intermediate"},
        ),
    ]

    index = VectorStoreIndex.from_documents(docs)

    # Configure query engine with custom settings
    query_engine = index.as_query_engine(
        similarity_top_k=2,
        response_mode="tree_summarize",  # Better for longer contexts
    )

    print("\n1. Metadata-aware queries:")
    response = query_engine.query("Tell me about programming")
    print(f"   Q: Tell me about programming")
    print(f"   A: {response}")

    print("\n2. Streaming responses:")
    print("   Q: What are the categories covered?")
    print("   A: ", end="", flush=True)

    streaming_engine = index.as_query_engine(streaming=True)
    streaming_response = streaming_engine.query("What are the categories covered?")

    # Stream the response
    for text in streaming_response.response_gen:
        print(text, end="", flush=True)
    print()


if __name__ == "__main__":
    try:
        # Run main demo
        question_answering_demo()

        # Show advanced features
        advanced_qa_features()

        print("\n" + "=" * 60)
        print("Demo completed successfully!")
        print("=" * 60)

    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
