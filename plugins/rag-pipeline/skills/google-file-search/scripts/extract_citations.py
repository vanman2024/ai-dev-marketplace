#!/usr/bin/env python3
"""
Google File Search Citation Extraction Script

Extracts and formats grounding citations from File Search responses to help
verify AI-generated content against source documents.

Usage:
    python extract_citations.py --response response.json
    python extract_citations.py --store <store_id> --query "your question" --extract
"""

import os
import sys
import argparse
import json
from pathlib import Path
from google import genai
from google.genai import types


def extract_citations_from_response(response):
    """Extract citation information from a response object."""
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
            citation = {
                "chunk_id": getattr(chunk, 'chunk_id', None),
                "content": getattr(chunk, 'content', None),
                "score": getattr(chunk, 'score', None)
            }
            citations.append(citation)

    # Extract from retrieval metadata
    if hasattr(grounding_metadata, 'retrieval_metadata'):
        retrieval_metadata = grounding_metadata.retrieval_metadata
        if hasattr(retrieval_metadata, 'results'):
            for result in retrieval_metadata.results:
                citation = {
                    "document_id": getattr(result, 'document_id', None),
                    "title": getattr(result, 'title', None),
                    "uri": getattr(result, 'uri', None),
                    "relevance_score": getattr(result, 'relevance_score', None)
                }
                citations.append(citation)

    return citations


def format_citations(citations):
    """Format citations for display."""
    if not citations:
        return "No citations found"

    output = []
    output.append("📚 Grounding Citations:\n")

    for i, citation in enumerate(citations, 1):
        output.append(f"[{i}] Citation:")

        for key, value in citation.items():
            if value is not None:
                if key == "content" and len(str(value)) > 150:
                    value = str(value)[:150] + "..."
                output.append(f"    {key}: {value}")

        output.append("")  # Blank line between citations

    return "\n".join(output)


def query_and_extract(client, store_id, query, model="gemini-2.5-flash"):
    """Query the store and extract citations."""
    print(f"🔍 Querying store for citations...")
    print(f"   Query: {query}\n")

    try:
        # Build file search tool
        file_search_tool = types.Tool(
            file_search=types.FileSearch(
                file_search_store_names=[store_id]
            )
        )

        # Execute query
        response = client.models.generate_content(
            model=model,
            contents=query,
            config=types.GenerateContentConfig(
                tools=[file_search_tool]
            )
        )

        return response

    except Exception as e:
        print(f"❌ Error executing query: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Extract citations from File Search responses")
    parser.add_argument("--response", help="Path to response JSON file")
    parser.add_argument("--store", help="File search store ID (for live queries)")
    parser.add_argument("--query", help="Search query (for live queries)")
    parser.add_argument("--extract", action="store_true", help="Extract citations from live query")
    parser.add_argument("--model", default="gemini-2.5-flash", help="Model to use for queries")
    parser.add_argument("--output", help="Save citations to JSON file")
    parser.add_argument("--format", choices=["json", "text", "markdown"], default="text", help="Output format")
    args = parser.parse_args()

    citations = []

    # Extract from file
    if args.response:
        response_path = Path(args.response)
        if not response_path.exists():
            print(f"❌ Error: Response file not found: {args.response}")
            sys.exit(1)

        with open(response_path, "r") as f:
            response_data = json.load(f)

        # If the file contains raw response object data, parse it
        # Otherwise, assume it's already formatted
        print(f"📄 Loading response from: {args.response}")
        if "grounding_metadata" in response_data:
            citations = response_data.get("grounding_metadata", [])
        else:
            print("⚠️  No grounding metadata found in response file")

    # Extract from live query
    elif args.extract and args.store and args.query:
        api_key = os.getenv("GOOGLE_API_KEY")
        if not api_key:
            print("❌ Error: GOOGLE_API_KEY environment variable not set")
            sys.exit(1)

        client = genai.Client(api_key=api_key)
        response = query_and_extract(client, args.store, args.query, args.model)
        citations = extract_citations_from_response(response)
    else:
        print("❌ Error: Either --response or --extract with --store and --query required")
        parser.print_help()
        sys.exit(1)

    # Format output
    if args.format == "json":
        output = json.dumps(citations, indent=2)
    elif args.format == "markdown":
        output = format_citations(citations).replace("📚", "##").replace("[", "**[").replace("]", "]**")
    else:  # text
        output = format_citations(citations)

    # Display
    print(output)

    # Save to file
    if args.output:
        output_path = Path(args.output)
        with open(output_path, "w") as f:
            if args.format == "json":
                json.dump(citations, f, indent=2)
            else:
                f.write(output)
        print(f"\n💾 Citations saved to: {output_path}")

    # Summary
    print(f"\n📊 Summary: {len(citations)} citation(s) extracted")


if __name__ == "__main__":
    main()
