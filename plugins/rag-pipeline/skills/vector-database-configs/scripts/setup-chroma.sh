#!/bin/bash
set -e

# Chroma Setup Script
# Installs and configures Chroma vector database

# Default values
PERSIST_DIR="./chroma_data"
COLLECTION_NAME="documents"
DISTANCE_METRIC="cosine"  # or l2, ip
HOST="localhost"
PORT="8000"
MODE="persistent"  # or client-server

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --persist-dir)
            PERSIST_DIR="$2"
            shift 2
            ;;
        --collection)
            COLLECTION_NAME="$2"
            shift 2
            ;;
        --distance)
            DISTANCE_METRIC="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --persist-dir DIR      Directory for persistent storage (default: ./chroma_data)"
            echo "  --collection NAME      Collection name (default: documents)"
            echo "  --distance METRIC      Distance metric: cosine, l2, or ip (default: cosine)"
            echo "  --mode MODE            Mode: persistent or client-server (default: persistent)"
            echo "  --host HOST            Server host for client-server mode (default: localhost)"
            echo "  --port PORT            Server port for client-server mode (default: 8000)"
            echo "  --help                 Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "Chroma Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Mode: $MODE"
echo "  Persist Directory: $PERSIST_DIR"
echo "  Collection: $COLLECTION_NAME"
echo "  Distance Metric: $DISTANCE_METRIC"
if [ "$MODE" = "client-server" ]; then
    echo "  Server: $HOST:$PORT"
fi
echo ""

# Check Python installation
echo "Step 1: Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    echo "Install Python 3.8 or later:"
    echo "  Ubuntu/Debian: sudo apt-get install python3 python3-pip"
    echo "  macOS: brew install python3"
    echo "  Or download from: https://www.python.org/downloads/"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "✓ Python $PYTHON_VERSION found"
echo ""

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "ERROR: pip3 not found"
    echo "Install pip: python3 -m ensurepip --upgrade"
    exit 1
fi
echo "✓ pip3 found"
echo ""

# Install Chroma
echo "Step 2: Installing ChromaDB..."
if python3 -c "import chromadb" 2>/dev/null; then
    INSTALLED_VERSION=$(python3 -c "import chromadb; print(chromadb.__version__)")
    echo "✓ ChromaDB already installed (version $INSTALLED_VERSION)"
else
    echo "Installing chromadb package..."
    pip3 install chromadb --quiet
    echo "✓ ChromaDB installed"
fi
echo ""

# Create persistence directory
if [ "$MODE" = "persistent" ]; then
    echo "Step 3: Creating persistence directory..."
    mkdir -p "$PERSIST_DIR"
    echo "✓ Directory created: $PERSIST_DIR"
    echo ""
fi

# Create initialization script
echo "Step 4: Creating initialization script..."
INIT_SCRIPT="/tmp/init_chroma.py"
cat > "$INIT_SCRIPT" << EOF
#!/usr/bin/env python3
"""
Chroma initialization script
"""
import chromadb
from chromadb.config import Settings
import sys

def init_persistent():
    """Initialize persistent Chroma client"""
    print("Initializing persistent Chroma client...")

    client = chromadb.PersistentClient(
        path="$PERSIST_DIR",
        settings=Settings(
            anonymized_telemetry=False,
            allow_reset=True
        )
    )

    print(f"✓ Client initialized with persistence at: $PERSIST_DIR")
    return client

def init_client_server():
    """Initialize Chroma client connecting to server"""
    print("Initializing Chroma client (client-server mode)...")

    try:
        client = chromadb.HttpClient(
            host="$HOST",
            port=$PORT,
            settings=Settings(
                anonymized_telemetry=False
            )
        )
        # Test connection
        client.heartbeat()
        print(f"✓ Connected to Chroma server at $HOST:$PORT")
        return client
    except Exception as e:
        print(f"ERROR: Cannot connect to Chroma server at $HOST:$PORT")
        print(f"Error: {e}")
        print("")
        print("To start Chroma server:")
        print("  chroma run --host $HOST --port $PORT")
        sys.exit(1)

def create_collection(client):
    """Create or get collection"""
    print(f"Creating collection '$COLLECTION_NAME'...")

    # Check if collection exists
    existing = client.list_collections()
    collection_names = [c.name for c in existing]

    if "$COLLECTION_NAME" in collection_names:
        print(f"✓ Collection '$COLLECTION_NAME' already exists")
        collection = client.get_collection(name="$COLLECTION_NAME")
    else:
        # Map distance metric to Chroma's format
        distance_map = {
            "cosine": "cosine",
            "l2": "l2",
            "ip": "ip"
        }

        collection = client.create_collection(
            name="$COLLECTION_NAME",
            metadata={
                "hnsw:space": distance_map.get("$DISTANCE_METRIC", "cosine"),
                "description": "Document embeddings collection"
            }
        )
        print(f"✓ Collection '$COLLECTION_NAME' created")

    # Display collection info
    count = collection.count()
    print(f"  Documents in collection: {count}")

    return collection

def add_sample_data(collection):
    """Add sample data to collection"""
    print("")
    print("Adding sample documents...")

    sample_docs = [
        "This is the first sample document about machine learning.",
        "The second document discusses natural language processing.",
        "Document three covers vector databases and embeddings."
    ]

    sample_metadata = [
        {"source": "sample", "category": "ml", "index": 1},
        {"source": "sample", "category": "nlp", "index": 2},
        {"source": "sample", "category": "databases", "index": 3}
    ]

    sample_ids = ["doc1", "doc2", "doc3"]

    # Chroma will auto-generate embeddings if embedding_function is set
    # For now, we'll let the default embedding function handle it
    collection.add(
        documents=sample_docs,
        metadatas=sample_metadata,
        ids=sample_ids
    )

    print(f"✓ Added {len(sample_docs)} sample documents")
    print("")
    print("Sample query:")
    results = collection.query(
        query_texts=["machine learning algorithms"],
        n_results=2
    )

    print("Query: 'machine learning algorithms'")
    print(f"Top result: {results['documents'][0][0][:60]}...")
    print(f"Distance: {results['distances'][0][0]:.4f}")

def main():
    # Initialize client
    if "$MODE" == "persistent":
        client = init_persistent()
    else:
        client = init_client_server()

    print("")

    # Create collection
    collection = create_collection(client)

    # Add sample data
    add_sample_data(collection)

    print("")
    print("========================================")
    print("Chroma Setup Complete!")
    print("========================================")
    print("")
    print(f"Mode: $MODE")
    if "$MODE" == "persistent":
        print(f"Data directory: $PERSIST_DIR")
    else:
        print(f"Server: $HOST:$PORT")
    print(f"Collection: $COLLECTION_NAME")
    print(f"Distance metric: $DISTANCE_METRIC")
    print("")
    print("Next steps:")
    print("1. See templates/chroma-config.py for integration examples")
    print("2. Use collection.add() to insert documents")
    print("3. Use collection.query() to search")
    print("4. See Chroma docs: https://docs.trychroma.com/")

if __name__ == "__main__":
    main()
EOF

chmod +x "$INIT_SCRIPT"
echo "✓ Initialization script created: $INIT_SCRIPT"
echo ""

# Run initialization
echo "Step 5: Running initialization..."
python3 "$INIT_SCRIPT"
echo ""

# Create systemd service file for server mode
if [ "$MODE" = "client-server" ]; then
    echo "Step 6: Creating server startup script..."

    cat > /tmp/start_chroma_server.sh << 'EOF'
#!/bin/bash
# Chroma server startup script

# Install Chroma if not installed
if ! command -v chroma &> /dev/null; then
    echo "Installing Chroma server..."
    pip3 install chromadb
fi

# Start server
echo "Starting Chroma server..."
chroma run --host localhost --port 8000
EOF

    chmod +x /tmp/start_chroma_server.sh
    echo "✓ Server startup script: /tmp/start_chroma_server.sh"
    echo ""
    echo "To start server: bash /tmp/start_chroma_server.sh"
    echo "Or run directly: chroma run --host $HOST --port $PORT"
fi

# Create Python usage example
echo "Creating usage example..."
cat > /tmp/chroma_example.py << 'EOF'
#!/usr/bin/env python3
"""
Chroma usage example
"""
import chromadb

# Initialize client
client = chromadb.PersistentClient(path="./chroma_data")

# Get or create collection
collection = client.get_or_create_collection(
    name="documents",
    metadata={"hnsw:space": "cosine"}
)

# Add documents
collection.add(
    documents=["Document 1 content", "Document 2 content"],
    metadatas=[{"source": "api"}, {"source": "upload"}],
    ids=["id1", "id2"]
)

# Query
results = collection.query(
    query_texts=["search query"],
    n_results=10,
    where={"source": "api"}  # Filter by metadata
)

print(f"Found {len(results['documents'][0])} results")
for doc, distance in zip(results['documents'][0], results['distances'][0]):
    print(f"  - {doc[:50]}... (distance: {distance:.4f})")
EOF

chmod +x /tmp/chroma_example.py
echo "✓ Usage example: /tmp/chroma_example.py"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - $INIT_SCRIPT"
echo "  - /tmp/chroma_example.py"
if [ "$MODE" = "client-server" ]; then
    echo "  - /tmp/start_chroma_server.sh"
fi
echo ""
echo "See templates/chroma-config.py for more examples"
echo ""
