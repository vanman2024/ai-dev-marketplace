#!/bin/bash
# create-index.sh - Create a LlamaIndex VectorStoreIndex from documents

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
DATA_DIR="${1:-./data}"
STORAGE_DIR="${2:-./storage}"
INDEX_NAME="${3:-default_index}"

echo -e "${GREEN}=== Creating LlamaIndex ===${NC}"
echo -e "Data directory: ${DATA_DIR}"
echo -e "Storage directory: ${STORAGE_DIR}"
echo -e "Index name: ${INDEX_NAME}"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo -e "${RED}Error: Data directory not found: ${DATA_DIR}${NC}"
    exit 1
fi

# Check if data directory has files
FILE_COUNT=$(find "$DATA_DIR" -type f | wc -l)
if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No files found in ${DATA_DIR}${NC}"
    exit 1
fi

echo -e "${GREEN}Found ${FILE_COUNT} files to index${NC}"

# Create storage directory
mkdir -p "$STORAGE_DIR"

# Create Python script to build index
SCRIPT=$(cat << 'PYTHON_SCRIPT'
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import LlamaIndex
from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    StorageContext,
    Settings,
)
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI

# Configure settings
Settings.llm = OpenAI(model="gpt-4o-mini", temperature=0)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

# Get arguments
data_dir = sys.argv[1] if len(sys.argv) > 1 else "./data"
storage_dir = sys.argv[2] if len(sys.argv) > 2 else "./storage"
index_name = sys.argv[3] if len(sys.argv) > 3 else "default_index"

print(f"Loading documents from {data_dir}...")

# Load documents
try:
    documents = SimpleDirectoryReader(
        data_dir,
        recursive=True,
        required_exts=[".txt", ".pdf", ".md", ".csv", ".json", ".html"]
    ).load_data()

    print(f"Loaded {len(documents)} documents")

    # Show document stats
    total_chars = sum(len(doc.text) for doc in documents)
    print(f"Total characters: {total_chars:,}")

except Exception as e:
    print(f"Error loading documents: {e}", file=sys.stderr)
    sys.exit(1)

print("Creating vector index...")

try:
    # Create index
    index = VectorStoreIndex.from_documents(
        documents,
        show_progress=True,
    )

    print("Index created successfully!")

    # Persist index
    index_path = Path(storage_dir) / index_name
    index.storage_context.persist(persist_dir=str(index_path))

    print(f"Index persisted to {index_path}")

    # Test query
    print("\nTesting index with sample query...")
    query_engine = index.as_query_engine()
    response = query_engine.query("What is this document about?")
    print(f"Sample response: {response}")

except Exception as e:
    print(f"Error creating index: {e}", file=sys.stderr)
    sys.exit(1)

print("\nIndex creation complete!")
print(f"To use this index:")
print(f'  from llama_index.core import load_index_from_storage, StorageContext')
print(f'  storage_context = StorageContext.from_defaults(persist_dir="{index_path}")')
print(f'  index = load_index_from_storage(storage_context)')
PYTHON_SCRIPT
)

# Run the Python script
echo "$SCRIPT" | python3 - "$DATA_DIR" "$STORAGE_DIR" "$INDEX_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== Index Created Successfully ===${NC}"
    echo -e "Index location: ${STORAGE_DIR}/${INDEX_NAME}"
else
    echo -e "${RED}=== Index Creation Failed ===${NC}"
    exit 1
fi
