#!/usr/bin/env python3
"""
Google File Search Python Client Template

Complete Python implementation for Google File Search API with store management,
document upload, semantic search, and citation extraction.

Security Note:
    NEVER hardcode API keys in this file. Always use environment variables:
    GOOGLE_API_KEY=your_google_api_key_here

Installation:
    pip install google-genai

Usage:
    python python-client.py
"""

import os
import sys
import time
from pathlib import Path
from google import genai
from google.genai import types


class GoogleFileSearchClient:
    """
    Client for Google File Search API operations.

    Features:
        - Store creation and management
        - Document upload with chunking configuration
        - Semantic search with metadata filtering
        - Citation extraction and grounding
    """

    def __init__(self, api_key=None):
        """
        Initialize the File Search client.

        Args:
            api_key: Google AI API key. If None, reads from GOOGLE_API_KEY env var.
        """
        self.api_key = api_key or os.getenv("GOOGLE_API_KEY")
        if not self.api_key:
            raise ValueError(
                "API key required. Set GOOGLE_API_KEY environment variable or pass api_key parameter.\n"
                "Get your key from: https://aistudio.google.com/apikey"
            )

        self.client = genai.Client(api_key=self.api_key)
        self.current_store = None

    def create_store(self, display_name, description=None):
        """
        Create a new file search store.

        Args:
            display_name: Human-readable name for the store
            description: Optional description

        Returns:
            Store object with name (ID) and metadata
        """
        config = {"display_name": display_name}
        if description:
            config["description"] = description

        store = self.client.file_search_stores.create(config=config)
        self.current_store = store

        print(f"✅ Store created: {display_name}")
        print(f"   Store ID: {store.name}")

        return store

    def list_stores(self):
        """
        List all file search stores.

        Returns:
            List of store objects
        """
        stores = list(self.client.file_search_stores.list())

        print(f"📚 Found {len(stores)} store(s):")
        for store in stores:
            print(f"   • {store.display_name} ({store.name})")

        return stores

    def get_store(self, store_id):
        """
        Retrieve a specific store by ID.

        Args:
            store_id: Store identifier (name field)

        Returns:
            Store object
        """
        store = self.client.file_search_stores.get(name=store_id)
        self.current_store = store
        return store

    def upload_document(
        self,
        file_path,
        store_id=None,
        chunking_config=None,
        metadata=None,
        wait_for_completion=True
    ):
        """
        Upload and index a document to a file search store.

        Args:
            file_path: Path to the document file
            store_id: Target store ID. Uses current_store if None.
            chunking_config: Dict with chunking configuration
            metadata: List of dicts with 'key' and 'string_value' or 'numeric_value'
            wait_for_completion: Whether to wait for indexing to complete

        Returns:
            Operation object
        """
        store_name = store_id or (self.current_store.name if self.current_store else None)
        if not store_name:
            raise ValueError("Store ID required. Create or select a store first.")

        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"File not found: {file_path}")

        # Build configuration
        config = {"display_name": path.name}

        if chunking_config:
            config["chunking_config"] = chunking_config

        if metadata:
            config["custom_metadata"] = metadata

        # Upload and index
        print(f"📤 Uploading: {path.name}")
        operation = self.client.file_search_stores.upload_to_file_search_store(
            file=str(path),
            file_search_store_name=store_name,
            config=config
        )

        # Wait for completion if requested
        if wait_for_completion:
            print(f"   ⏳ Indexing...")
            while not operation.done:
                time.sleep(2)
                operation = self.client.operations.get(operation)
            print(f"   ✅ Indexed: {path.name}")

        return operation

    def search(self, query, store_id=None, metadata_filter=None, model="gemini-2.5-flash"):
        """
        Execute semantic search query.

        Args:
            query: Natural language search query
            store_id: Target store ID. Uses current_store if None.
            metadata_filter: Optional AIP-160 filter expression
            model: Gemini model to use

        Returns:
            Response object with text and grounding metadata
        """
        store_name = store_id or (self.current_store.name if self.current_store else None)
        if not store_name:
            raise ValueError("Store ID required. Create or select a store first.")

        # Build file search tool
        file_search = types.FileSearch(file_search_store_names=[store_name])

        if metadata_filter:
            file_search.metadata_filter = metadata_filter

        tool = types.Tool(file_search=file_search)

        # Execute search
        print(f"🔍 Searching: {query}")
        response = self.client.models.generate_content(
            model=model,
            contents=query,
            config=types.GenerateContentConfig(tools=[tool])
        )

        print(f"✅ Response generated")
        return response

    def extract_citations(self, response):
        """
        Extract grounding citations from a response.

        Args:
            response: Response object from search()

        Returns:
            List of citation dictionaries
        """
        citations = []

        if not response.candidates or len(response.candidates) == 0:
            return citations

        candidate = response.candidates[0]
        if not hasattr(candidate, 'grounding_metadata'):
            return citations

        grounding_metadata = candidate.grounding_metadata

        # Extract from grounding chunks
        if hasattr(grounding_metadata, 'grounding_chunks'):
            for chunk in grounding_metadata.grounding_chunks:
                citations.append({
                    "chunk_id": getattr(chunk, 'chunk_id', None),
                    "content": getattr(chunk, 'content', None),
                    "score": getattr(chunk, 'score', None)
                })

        return citations

    def delete_store(self, store_id=None, force=True):
        """
        Delete a file search store.

        Args:
            store_id: Store ID to delete. Uses current_store if None.
            force: Force deletion even if store contains files
        """
        store_name = store_id or (self.current_store.name if self.current_store else None)
        if not store_name:
            raise ValueError("Store ID required")

        config = {"force": force} if force else None
        self.client.file_search_stores.delete(name=store_name, config=config)

        print(f"🗑️  Store deleted: {store_name}")

        if self.current_store and self.current_store.name == store_name:
            self.current_store = None


# Example usage
def main():
    """
    Example workflow demonstrating File Search capabilities.
    """
    print("🚀 Google File Search Example\n")

    # Initialize client
    client = GoogleFileSearchClient()

    # Create a store
    store = client.create_store(
        display_name="Example RAG Store",
        description="Demo store for File Search"
    )

    # Upload a document (replace with actual file path)
    # client.upload_document(
    #     file_path="./document.pdf",
    #     chunking_config={
    #         "white_space_config": {
    #             "max_tokens_per_chunk": 200,
    #             "max_overlap_tokens": 20
    #         }
    #     },
    #     metadata=[
    #         {"key": "author", "string_value": "Example Author"},
    #         {"key": "year", "numeric_value": 2024}
    #     ]
    # )

    # Search the store
    # response = client.search(
    #     query="What are the main features?",
    #     metadata_filter="year=2024"
    # )
    # print(f"\n💬 Response:\n{response.text}\n")

    # Extract citations
    # citations = client.extract_citations(response)
    # print(f"📚 Found {len(citations)} citation(s)")

    # List all stores
    client.list_stores()

    # Clean up (uncomment to delete)
    # client.delete_store()

    print("\n✅ Example complete!")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
