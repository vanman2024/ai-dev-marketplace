#!/bin/bash

# create-vectorstore.sh
# Create and populate a vector store from documents
# Usage: bash create-vectorstore.sh <store_type> <documents_path> <output_path>

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# Print header
echo "=================================="
echo "  Vector Store Creation Script"
echo "=================================="
echo ""

# Check arguments
if [ $# -lt 3 ]; then
    print_error "Usage: bash create-vectorstore.sh <store_type> <documents_path> <output_path>"
    echo ""
    echo "Store types: faiss, chroma, pinecone, qdrant"
    echo "Example: bash create-vectorstore.sh faiss ./docs ./vectorstore"
    exit 1
fi

STORE_TYPE="$1"
DOCUMENTS_PATH="$2"
OUTPUT_PATH="$3"

# Environment variables with defaults
EMBEDDING_MODEL="${EMBEDDING_MODEL:-text-embedding-3-small}"
CHUNK_SIZE="${CHUNK_SIZE:-1000}"
CHUNK_OVERLAP="${CHUNK_OVERLAP:-200}"

print_info "Configuration:"
echo "  Store Type: $STORE_TYPE"
echo "  Documents: $DOCUMENTS_PATH"
echo "  Output: $OUTPUT_PATH"
echo "  Embedding Model: $EMBEDDING_MODEL"
echo "  Chunk Size: $CHUNK_SIZE"
echo "  Chunk Overlap: $CHUNK_OVERLAP"
echo ""

# Check if documents path exists
if [ ! -e "$DOCUMENTS_PATH" ]; then
    print_error "Documents path does not exist: $DOCUMENTS_PATH"
    exit 1
fi

# Check API key
if [ -z "$OPENAI_API_KEY" ]; then
    print_error "OPENAI_API_KEY not set"
    print_info "Set with: export OPENAI_API_KEY='sk-...'"
    exit 1
fi
print_success "OpenAI API key found"

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    print_info "Activating virtual environment..."
    source venv/bin/activate
    print_success "Virtual environment activated"
fi

# Create Python script for vector store creation
TEMP_SCRIPT=$(mktemp /tmp/create_vectorstore_XXXXXX.py)

cat > "$TEMP_SCRIPT" <<'PYTHON_SCRIPT'
import os
import sys
from pathlib import Path

# Get parameters from environment
store_type = os.environ.get('STORE_TYPE')
documents_path = os.environ.get('DOCUMENTS_PATH')
output_path = os.environ.get('OUTPUT_PATH')
embedding_model = os.environ.get('EMBEDDING_MODEL', 'text-embedding-3-small')
chunk_size = int(os.environ.get('CHUNK_SIZE', '1000'))
chunk_overlap = int(os.environ.get('CHUNK_OVERLAP', '200'))

print(f"🔍 Loading documents from: {documents_path}")

# Import required packages
try:
    from langchain_community.document_loaders import (
        DirectoryLoader,
        PDFLoader,
        TextLoader,
        CSVLoader,
        UnstructuredMarkdownLoader
    )
    from langchain_text_splitters import RecursiveCharacterTextSplitter
    from langchain_openai import OpenAIEmbeddings
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("Run: bash scripts/setup-langchain.sh --all")
    sys.exit(1)

# Load documents
docs_path = Path(documents_path)
documents = []

if docs_path.is_file():
    # Single file
    print(f"  Loading single file: {docs_path.name}")
    if docs_path.suffix == '.pdf':
        loader = PDFLoader(str(docs_path))
    elif docs_path.suffix == '.txt':
        loader = TextLoader(str(docs_path))
    elif docs_path.suffix == '.csv':
        loader = CSVLoader(str(docs_path))
    elif docs_path.suffix == '.md':
        loader = UnstructuredMarkdownLoader(str(docs_path))
    else:
        print(f"⚠ Unsupported file type: {docs_path.suffix}, trying TextLoader")
        loader = TextLoader(str(docs_path))

    documents = loader.load()

elif docs_path.is_dir():
    # Directory of files
    print(f"  Loading directory: {docs_path}")

    # Try PDF files
    try:
        pdf_loader = DirectoryLoader(
            str(docs_path),
            glob="**/*.pdf",
            loader_cls=PDFLoader,
            show_progress=True
        )
        pdf_docs = pdf_loader.load()
        documents.extend(pdf_docs)
        print(f"  ✓ Loaded {len(pdf_docs)} PDF files")
    except Exception as e:
        print(f"  ⚠ No PDF files found or error: {e}")

    # Try text files
    try:
        txt_loader = DirectoryLoader(
            str(docs_path),
            glob="**/*.txt",
            loader_cls=TextLoader,
            show_progress=True
        )
        txt_docs = txt_loader.load()
        documents.extend(txt_docs)
        print(f"  ✓ Loaded {len(txt_docs)} text files")
    except Exception as e:
        print(f"  ⚠ No text files found or error: {e}")

    # Try markdown files
    try:
        md_loader = DirectoryLoader(
            str(docs_path),
            glob="**/*.md",
            loader_cls=UnstructuredMarkdownLoader,
            show_progress=True
        )
        md_docs = md_loader.load()
        documents.extend(md_docs)
        print(f"  ✓ Loaded {len(md_docs)} markdown files")
    except Exception as e:
        print(f"  ⚠ No markdown files found or error: {e}")

else:
    print(f"❌ Invalid path: {docs_path}")
    sys.exit(1)

if not documents:
    print("❌ No documents loaded. Check the documents path.")
    sys.exit(1)

print(f"✓ Loaded {len(documents)} documents")

# Split documents
print(f"📄 Splitting documents (size={chunk_size}, overlap={chunk_overlap})...")
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=chunk_size,
    chunk_overlap=chunk_overlap,
    length_function=len,
    is_separator_regex=False
)
chunks = text_splitter.split_documents(documents)
print(f"✓ Created {len(chunks)} text chunks")

# Create embeddings
print(f"🔢 Creating embeddings using {embedding_model}...")
embeddings = OpenAIEmbeddings(model=embedding_model)
print("✓ Embeddings model initialized")

# Create vector store
print(f"💾 Creating {store_type} vector store...")

if store_type == 'faiss':
    from langchain_community.vectorstores import FAISS
    vectorstore = FAISS.from_documents(chunks, embeddings)
    vectorstore.save_local(output_path)
    print(f"✓ FAISS vector store saved to: {output_path}")

elif store_type == 'chroma':
    from langchain_community.vectorstores import Chroma
    vectorstore = Chroma.from_documents(
        chunks,
        embeddings,
        persist_directory=output_path
    )
    print(f"✓ Chroma vector store saved to: {output_path}")

elif store_type == 'pinecone':
    try:
        from langchain_pinecone import PineconeVectorStore
        from pinecone import Pinecone

        # Initialize Pinecone
        pc = Pinecone(api_key=os.environ.get('PINECONE_API_KEY'))
        index_name = os.environ.get('PINECONE_INDEX', 'langchain-index')

        vectorstore = PineconeVectorStore.from_documents(
            chunks,
            embeddings,
            index_name=index_name
        )
        print(f"✓ Pinecone vector store created: {index_name}")

    except ImportError:
        print("❌ Pinecone not installed. Run: pip install pinecone-client langchain-pinecone")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Pinecone error: {e}")
        print("Make sure PINECONE_API_KEY is set and index exists")
        sys.exit(1)

elif store_type == 'qdrant':
    try:
        from langchain_qdrant import QdrantVectorStore
        from qdrant_client import QdrantClient

        client = QdrantClient(path=output_path)
        collection_name = "documents"

        vectorstore = QdrantVectorStore.from_documents(
            chunks,
            embeddings,
            client=client,
            collection_name=collection_name
        )
        print(f"✓ Qdrant vector store saved to: {output_path}")

    except ImportError:
        print("❌ Qdrant not installed. Run: pip install qdrant-client langchain-qdrant")
        sys.exit(1)

else:
    print(f"❌ Unknown store type: {store_type}")
    print("Supported: faiss, chroma, pinecone, qdrant")
    sys.exit(1)

# Test retrieval
print("")
print("🔍 Testing retrieval...")
retriever = vectorstore.as_retriever(search_kwargs={"k": 3})
test_query = "test query"
results = retriever.invoke(test_query)
print(f"✓ Retrieved {len(results)} documents for test query")

# Print statistics
print("")
print("=" * 50)
print("  Vector Store Created Successfully")
print("=" * 50)
print(f"  Documents loaded: {len(documents)}")
print(f"  Text chunks: {len(chunks)}")
print(f"  Store type: {store_type}")
print(f"  Output path: {output_path}")
print(f"  Embedding model: {embedding_model}")
print("=" * 50)

PYTHON_SCRIPT

# Export variables for Python script
export STORE_TYPE
export DOCUMENTS_PATH
export OUTPUT_PATH
export EMBEDDING_MODEL
export CHUNK_SIZE
export CHUNK_OVERLAP

# Run Python script
print_info "Running vector store creation..."
python3 "$TEMP_SCRIPT"

# Clean up
rm "$TEMP_SCRIPT"

echo ""
print_success "Vector store creation complete!"
echo ""
print_info "Next steps:"
echo "  1. Test retrieval: bash scripts/test-langchain.sh"
echo "  2. Use in your application:"
echo ""
echo "     from langchain_community.vectorstores import FAISS"
echo "     from langchain_openai import OpenAIEmbeddings"
echo ""
echo "     embeddings = OpenAIEmbeddings()"
echo "     vectorstore = FAISS.load_local('$OUTPUT_PATH', embeddings)"
echo "     retriever = vectorstore.as_retriever()"
echo ""
