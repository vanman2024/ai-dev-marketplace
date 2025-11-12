#!/usr/bin/env python3
"""
Google File Search Query Script

Execute semantic search queries against a file search store and display results
with grounding citations.

Usage:
    python search_query.py --store <store_id> --query "your question"
    python search_query.py --query "author=Einstein" --metadata-filter "year=1934"

Environment Variables:
    GOOGLE_API_KEY: Your Google AI API key
    GOOGLE_FILE_SEARCH_STORE_ID: Default store ID if not provided via --store
"""

import os
import sys
import argparse
import json
from google import genai
from google.genai import types


def format_grounding_metadata(grounding_metadata):
    """Format grounding metadata for display."""
    if not grounding_metadata:
        return "No grounding metadata available"

    output = []
    output.append("\n📚 Source Citations:")

    # Handle different metadata structures
    if hasattr(grounding_metadata, 'grounding_chunks'):
        for i, chunk in enumerate(grounding_metadata.grounding_chunks, 1):
            output.append(f"\n   [{i}] Chunk ID: {chunk.chunk_id if hasattr(chunk, 'chunk_id') else 'N/A'}")
            if hasattr(chunk, 'content'):
                snippet = chunk.content[:100] + "..." if len(chunk.content) > 100 else chunk.content
                output.append(f"       Snippet: {snippet}")

    if hasattr(grounding_metadata, 'retrieval_metadata'):
        output.append(f"\n   🔍 Retrieved documents: {len(grounding_metadata.retrieval_metadata.results) if hasattr(grounding_metadata.retrieval_metadata, 'results') else 'N/A'}")

    return "\n".join(output)


def search(client, store_id, query, model="gemini-2.5-flash", metadata_filter=None):
    """Execute search query against file search store."""
    print(f"🔍 Searching store: {store_id}")
    print(f"   Query: {query}")
    if metadata_filter:
        print(f"   Filter: {metadata_filter}")
    print()

    try:
        # Build file search tool
        file_search_tool = types.Tool(
            file_search=types.FileSearch(
                file_search_store_names=[store_id]
            )
        )

        # Add metadata filter if provided
        if metadata_filter:
            file_search_tool.file_search.metadata_filter = metadata_filter

        # Execute query
        response = client.models.generate_content(
            model=model,
            contents=query,
            config=types.GenerateContentConfig(
                tools=[file_search_tool]
            )
        )

        # Display results
        print("💬 Response:")
        print("─" * 80)
        print(response.text)
        print("─" * 80)

        # Display grounding metadata if available
        if response.candidates and len(response.candidates) > 0:
            candidate = response.candidates[0]
            if hasattr(candidate, 'grounding_metadata'):
                print(format_grounding_metadata(candidate.grounding_metadata))

        return response

    except Exception as e:
        print(f"❌ Error executing query: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Query Google File Search store")
    parser.add_argument("--store", help="File search store ID")
    parser.add_argument("--query", required=True, help="Search query")
    parser.add_argument("--metadata-filter", help="Metadata filter (e.g., 'author=Einstein')")
    parser.add_argument("--model", default="gemini-2.5-flash", help="Model to use")
    parser.add_argument("--output", help="Save response to JSON file")
    args = parser.parse_args()

    # Check for API key
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("❌ Error: GOOGLE_API_KEY environment variable not set")
        sys.exit(1)

    # Get store ID
    store_id = args.store or os.getenv("GOOGLE_FILE_SEARCH_STORE_ID")
    if not store_id:
        print("❌ Error: Store ID required (--store or GOOGLE_FILE_SEARCH_STORE_ID)")
        sys.exit(1)

    # Initialize client
    client = genai.Client(api_key=api_key)

    # Execute search
    response = search(client, store_id, args.query, args.model, args.metadata_filter)

    # Save to file if requested
    if args.output:
        output_data = {
            "query": args.query,
            "model": args.model,
            "response": response.text,
            "metadata_filter": args.metadata_filter
        }

        with open(args.output, "w") as f:
            json.dump(output_data, f, indent=2)

        print(f"\n💾 Response saved to: {args.output}")


if __name__ == "__main__":
    main()
