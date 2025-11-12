#!/usr/bin/env python3
"""
Google File Search Document Upload Script

Uploads and indexes documents to a file search store with optional chunking
and metadata configuration.

Usage:
    python upload_documents.py --store <store_id> --file <path> [--metadata key=value]
    python upload_documents.py --store <store_id> --dir <directory>

Environment Variables:
    GOOGLE_API_KEY: Your Google AI API key
    GOOGLE_FILE_SEARCH_STORE_ID: Default store ID if not provided via --store
"""

import os
import sys
import argparse
import json
import time
from pathlib import Path
from google import genai
from google.genai import types


# Supported file types and size limits
MAX_FILE_SIZE_MB = 100
SUPPORTED_EXTENSIONS = {
    ".pdf", ".docx", ".odt", ".pptx", ".xlsx", ".csv", ".txt", ".md",
    ".py", ".js", ".ts", ".java", ".go", ".rs", ".sql", ".json", ".xml",
    ".yaml", ".yml", ".html", ".c", ".cpp", ".h", ".hpp"
}


def parse_metadata(metadata_args):
    """Parse metadata key=value pairs into structured format."""
    metadata = []
    if not metadata_args:
        return metadata

    for item in metadata_args:
        if "=" not in item:
            print(f"⚠️  Warning: Skipping invalid metadata format: {item}")
            continue

        key, value = item.split("=", 1)

        # Try to parse as numeric
        try:
            numeric_value = float(value)
            metadata.append({"key": key, "numeric_value": numeric_value})
        except ValueError:
            metadata.append({"key": key, "string_value": value})

    return metadata


def validate_file(file_path):
    """Validate file type and size."""
    path = Path(file_path)

    if not path.exists():
        return False, f"File not found: {file_path}"

    if path.suffix.lower() not in SUPPORTED_EXTENSIONS:
        return False, f"Unsupported file type: {path.suffix}"

    size_mb = path.stat().st_size / (1024 * 1024)
    if size_mb > MAX_FILE_SIZE_MB:
        return False, f"File too large: {size_mb:.1f}MB (max: {MAX_FILE_SIZE_MB}MB)"

    return True, None


def upload_file(client, store_name, file_path, chunking_config=None, metadata=None):
    """Upload and index a single file."""
    path = Path(file_path)

    # Validate file
    is_valid, error_msg = validate_file(path)
    if not is_valid:
        return False, error_msg

    print(f"📤 Uploading: {path.name}")

    try:
        # Build config
        config = {"display_name": path.name}

        if chunking_config:
            config["chunking_config"] = chunking_config

        if metadata:
            config["custom_metadata"] = metadata

        # Upload and index
        operation = client.file_search_stores.upload_to_file_search_store(
            file=str(path),
            file_search_store_name=store_name,
            config=config
        )

        # Wait for completion
        print(f"   ⏳ Indexing...")
        while not operation.done:
            time.sleep(2)
            operation = client.operations.get(operation)

        print(f"   ✅ Uploaded and indexed: {path.name}")
        return True, operation

    except Exception as e:
        error_msg = f"Failed to upload {path.name}: {e}"
        print(f"   ❌ {error_msg}")
        return False, error_msg


def main():
    parser = argparse.ArgumentParser(description="Upload documents to Google File Search")
    parser.add_argument("--store", help="File search store ID")
    parser.add_argument("--file", help="Single file to upload")
    parser.add_argument("--dir", help="Directory of files to upload")
    parser.add_argument("--metadata", nargs="+", help="Metadata as key=value pairs")
    parser.add_argument("--chunking-config", help="Path to chunking config JSON file")
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

    # Validate inputs
    if not args.file and not args.dir:
        print("❌ Error: Either --file or --dir required")
        sys.exit(1)

    # Initialize client
    client = genai.Client(api_key=api_key)

    # Load chunking config if provided
    chunking_config = None
    if args.chunking_config:
        with open(args.chunking_config, "r") as f:
            chunking_config = json.load(f)

    # Parse metadata
    metadata = parse_metadata(args.metadata)

    # Collect files to upload
    files_to_upload = []
    if args.file:
        files_to_upload.append(Path(args.file))
    elif args.dir:
        dir_path = Path(args.dir)
        if not dir_path.is_dir():
            print(f"❌ Error: Not a directory: {args.dir}")
            sys.exit(1)
        files_to_upload = [
            f for f in dir_path.rglob("*")
            if f.is_file() and f.suffix.lower() in SUPPORTED_EXTENSIONS
        ]

    if not files_to_upload:
        print("❌ No valid files found to upload")
        sys.exit(1)

    print(f"📦 Found {len(files_to_upload)} file(s) to upload")
    print(f"🎯 Target store: {store_id}\n")

    # Upload files
    success_count = 0
    failure_count = 0

    for file_path in files_to_upload:
        success, result = upload_file(client, store_id, file_path, chunking_config, metadata)
        if success:
            success_count += 1
        else:
            failure_count += 1

    # Summary
    print(f"\n📊 Upload Summary:")
    print(f"   ✅ Successful: {success_count}")
    print(f"   ❌ Failed: {failure_count}")
    print(f"   📈 Total: {len(files_to_upload)}")


if __name__ == "__main__":
    main()
