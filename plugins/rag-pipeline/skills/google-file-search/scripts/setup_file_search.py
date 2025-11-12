#!/usr/bin/env python3
"""
Google File Search Store Setup Script

Creates a new file search store for document indexing and retrieval.
Saves store information for use in other scripts.

Usage:
    python setup_file_search.py --name "My RAG Store" [--description "Store description"]

Environment Variables:
    GOOGLE_API_KEY: Your Google AI API key (get from https://aistudio.google.com/apikey)
"""

import os
import sys
import argparse
import json
from pathlib import Path
from google import genai
from google.genai import types


def main():
    parser = argparse.ArgumentParser(description="Create a Google File Search store")
    parser.add_argument("--name", required=True, help="Display name for the store")
    parser.add_argument("--description", help="Description of the store")
    parser.add_argument("--output", default=".env.file-search", help="Output file for store info")
    args = parser.parse_args()

    # Check for API key
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("❌ Error: GOOGLE_API_KEY environment variable not set")
        print("Get your API key from: https://aistudio.google.com/apikey")
        print("Then set it: export GOOGLE_API_KEY=your_google_api_key_here")
        sys.exit(1)

    print(f"🔄 Creating file search store: {args.name}")

    try:
        # Initialize client
        client = genai.Client(api_key=api_key)

        # Create store
        config = {"display_name": args.name}
        if args.description:
            config["description"] = args.description

        file_search_store = client.file_search_stores.create(config=config)

        print(f"✅ Store created successfully!")
        print(f"   Store ID: {file_search_store.name}")
        print(f"   Display Name: {file_search_store.display_name}")

        # Save store info to file
        store_info = {
            "GOOGLE_FILE_SEARCH_STORE_ID": file_search_store.name,
            "GOOGLE_FILE_SEARCH_STORE_NAME": file_search_store.display_name,
        }

        output_path = Path(args.output)
        with open(output_path, "w") as f:
            for key, value in store_info.items():
                f.write(f"{key}={value}\n")

        print(f"💾 Store info saved to: {output_path}")
        print(f"\nTo use this store, source the file:")
        print(f"   source {output_path}")

        return file_search_store

    except Exception as e:
        print(f"❌ Error creating store: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
