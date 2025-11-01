#!/bin/bash
set -e

# Qdrant Setup Script
# Installs and configures Qdrant vector database

# Default values
MODE="docker"  # or cloud, local
COLLECTION_NAME="documents"
VECTOR_SIZE="1536"
DISTANCE_METRIC="Cosine"  # or Euclid, Dot
HOST="localhost"
PORT="6333"
GRPC_PORT="6334"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --collection)
            COLLECTION_NAME="$2"
            shift 2
            ;;
        --vector-size)
            VECTOR_SIZE="$2"
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
        --grpc-port)
            GRPC_PORT="$2"
            shift 2
            ;;
        --url)
            QDRANT_URL="$2"
            shift 2
            ;;
        --api-key)
            export QDRANT_API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mode MODE            Deployment mode: docker, local, or cloud (default: docker)"
            echo "  --collection NAME      Collection name (default: documents)"
            echo "  --vector-size SIZE     Vector dimensions (default: 1536)"
            echo "  --distance METRIC      Distance metric: Cosine, Euclid, or Dot (default: Cosine)"
            echo "  --host HOST            Host for Docker/local mode (default: localhost)"
            echo "  --port PORT            HTTP port (default: 6333)"
            echo "  --grpc-port PORT       gRPC port (default: 6334)"
            echo "  --url URL              Qdrant cloud URL (for cloud mode)"
            echo "  --api-key KEY          Qdrant API key (for cloud mode)"
            echo "  --help                 Show this help message"
            echo ""
            echo "For cloud setup, get credentials from: https://cloud.qdrant.io/"
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
echo "Qdrant Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Mode: $MODE"
echo "  Collection: $COLLECTION_NAME"
echo "  Vector Size: $VECTOR_SIZE"
echo "  Distance: $DISTANCE_METRIC"
if [ "$MODE" = "docker" ] || [ "$MODE" = "local" ]; then
    echo "  Host: $HOST:$PORT"
else
    echo "  URL: ${QDRANT_URL:-not set}"
fi
echo ""

if [ "$MODE" = "docker" ]; then
    # Docker-based setup
    echo "Step 1: Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker not found"
        echo "Install Docker from: https://docs.docker.com/get-docker/"
        exit 1
    fi
    echo "✓ Docker found"
    echo ""

    echo "Step 2: Starting Qdrant with Docker..."

    # Check if container already exists
    if docker ps -a --format '{{.Names}}' | grep -q "^qdrant$"; then
        echo "Qdrant container already exists"
        if docker ps --format '{{.Names}}' | grep -q "^qdrant$"; then
            echo "✓ Qdrant is already running"
        else
            echo "Starting existing container..."
            docker start qdrant
            echo "✓ Qdrant started"
        fi
    else
        echo "Creating and starting Qdrant container..."
        docker run -d \
            --name qdrant \
            -p $PORT:6333 \
            -p $GRPC_PORT:6334 \
            -v qdrant_storage:/qdrant/storage \
            qdrant/qdrant:latest

        echo "✓ Qdrant container created and started"
    fi

    echo "  Waiting for Qdrant to be ready..."
    for i in {1..30}; do
        if curl -sf "http://$HOST:$PORT/healthz" > /dev/null 2>&1; then
            echo "✓ Qdrant is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "ERROR: Qdrant failed to start within 60 seconds"
            echo "Check logs: docker logs qdrant"
            exit 1
        fi
        sleep 2
    done
    echo ""

    QDRANT_URL="http://$HOST:$PORT"

elif [ "$MODE" = "local" ]; then
    # Local binary setup
    echo "Step 1: Checking for Qdrant binary..."

    if ! command -v qdrant &> /dev/null; then
        echo "Qdrant binary not found. Installing..."
        echo ""
        echo "For Linux (x86_64):"
        QDRANT_VERSION="v1.7.4"
        wget "https://github.com/qdrant/qdrant/releases/download/${QDRANT_VERSION}/qdrant-x86_64-unknown-linux-musl.tar.gz" -O /tmp/qdrant.tar.gz
        tar -xzf /tmp/qdrant.tar.gz -C /tmp/
        sudo mv /tmp/qdrant /usr/local/bin/
        rm /tmp/qdrant.tar.gz
        echo "✓ Qdrant binary installed"
    else
        echo "✓ Qdrant binary found"
    fi
    echo ""

    echo "Step 2: Starting Qdrant..."
    # Start in background
    nohup qdrant --uri "http://$HOST:$PORT" > /tmp/qdrant.log 2>&1 &
    QDRANT_PID=$!
    echo "✓ Qdrant started (PID: $QDRANT_PID)"
    echo "  Logs: /tmp/qdrant.log"

    # Wait for ready
    echo "  Waiting for Qdrant to be ready..."
    for i in {1..30}; do
        if curl -sf "http://$HOST:$PORT/healthz" > /dev/null 2>&1; then
            echo "✓ Qdrant is ready"
            break
        fi
        sleep 2
    done
    echo ""

    QDRANT_URL="http://$HOST:$PORT"

elif [ "$MODE" = "cloud" ]; then
    # Cloud-based setup
    if [ -z "$QDRANT_URL" ]; then
        echo "ERROR: --url required for cloud mode"
        echo "Get your Qdrant Cloud URL from: https://cloud.qdrant.io/"
        exit 1
    fi

    echo "Step 1: Validating cloud connection..."
    if ! curl -sf "$QDRANT_URL/healthz" > /dev/null 2>&1; then
        echo "ERROR: Cannot connect to Qdrant at $QDRANT_URL"
        echo "Check your URL and network connection"
        exit 1
    fi
    echo "✓ Connected to Qdrant Cloud"
    echo ""
fi

# Install Python client
echo "Step 3: Installing Qdrant Python client..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    exit 1
fi

if python3 -c "import qdrant_client" 2>/dev/null; then
    VERSION=$(python3 -c "import qdrant_client; print(qdrant_client.__version__)")
    echo "✓ Qdrant client already installed (version $VERSION)"
else
    echo "Installing qdrant-client package..."
    pip3 install qdrant-client --quiet
    echo "✓ Qdrant client installed"
fi
echo ""

# Create setup script
echo "Step 4: Creating collection setup script..."
SETUP_SCRIPT="/tmp/setup_qdrant.py"
cat > "$SETUP_SCRIPT" << EOF
#!/usr/bin/env python3
"""
Qdrant setup and collection configuration script
"""
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
import os
import sys
import random

def init_client():
    """Initialize Qdrant client"""
    url = "$QDRANT_URL"
    api_key = os.getenv("QDRANT_API_KEY")

    print(f"Connecting to Qdrant at {url}...")

    try:
        if api_key:
            client = QdrantClient(url=url, api_key=api_key)
        else:
            client = QdrantClient(url=url)

        # Test connection
        client.get_collections()
        print("✓ Connected to Qdrant")
        return client

    except Exception as e:
        print(f"ERROR connecting to Qdrant: {e}")
        sys.exit(1)

def create_collection(client):
    """Create or verify collection"""
    collection_name = "$COLLECTION_NAME"
    vector_size = $VECTOR_SIZE

    # Map distance metric
    distance_map = {
        "Cosine": Distance.COSINE,
        "Euclid": Distance.EUCLID,
        "Dot": Distance.DOT
    }
    distance = distance_map.get("$DISTANCE_METRIC", Distance.COSINE)

    print(f"Creating collection '{collection_name}'...")

    # Check if collection exists
    collections = client.get_collections().collections
    collection_names = [c.name for c in collections]

    if collection_name in collection_names:
        print(f"✓ Collection '{collection_name}' already exists")
        info = client.get_collection(collection_name)
        print(f"  Vectors count: {info.points_count}")
        return

    # Create collection
    try:
        client.create_collection(
            collection_name=collection_name,
            vectors_config=VectorParams(
                size=vector_size,
                distance=distance
            )
        )
        print(f"✓ Collection '{collection_name}' created")
        print(f"  Vector size: {vector_size}")
        print(f"  Distance metric: $DISTANCE_METRIC")

    except Exception as e:
        print(f"ERROR creating collection: {e}")
        sys.exit(1)

def add_sample_data(client):
    """Add sample vectors to collection"""
    collection_name = "$COLLECTION_NAME"
    vector_size = $VECTOR_SIZE

    print("")
    print("Adding sample data...")

    # Generate sample points
    points = [
        PointStruct(
            id=i,
            vector=[random.random() for _ in range(vector_size)],
            payload={
                "text": f"Sample document {i}",
                "source": "setup_script",
                "category": "sample"
            }
        )
        for i in range(1, 6)
    ]

    # Upsert points
    client.upsert(
        collection_name=collection_name,
        points=points
    )
    print(f"✓ Inserted {len(points)} sample points")

    # Query test
    print("")
    print("Testing search...")
    query_vector = [random.random() for _ in range(vector_size)]
    results = client.search(
        collection_name=collection_name,
        query_vector=query_vector,
        limit=3
    )

    print("Sample search results:")
    for result in results:
        print(f"  - ID: {result.id}, Score: {result.score:.4f}")
        print(f"    Text: {result.payload['text']}")

def create_payload_index(client):
    """Create payload indexes for faster filtering"""
    collection_name = "$COLLECTION_NAME"

    print("")
    print("Creating payload indexes...")

    # Create index on category field
    client.create_payload_index(
        collection_name=collection_name,
        field_name="category",
        field_schema="keyword"
    )
    print("✓ Created keyword index on 'category'")

    # Create index on source field
    client.create_payload_index(
        collection_name=collection_name,
        field_name="source",
        field_schema="keyword"
    )
    print("✓ Created keyword index on 'source'")

def display_summary(client):
    """Display setup summary"""
    collection_name = "$COLLECTION_NAME"

    print("")
    print("=" * 50)
    print("Qdrant Setup Complete!")
    print("=" * 50)
    print("")
    print(f"Collection: {collection_name}")
    print(f"Vector Size: $VECTOR_SIZE")
    print(f"Distance: $DISTANCE_METRIC")
    print(f"URL: $QDRANT_URL")
    print("")

    # Get collection info
    info = client.get_collection(collection_name)
    print(f"Current stats:")
    print(f"  Points count: {info.points_count}")
    print(f"  Indexed vectors: {info.vectors_count}")
    print("")

    print("Next steps:")
    print("1. Use client.upsert() to add vectors")
    print("2. Use client.search() for vector search")
    print("3. Use client.retrieve() to get by ID")
    print("4. See templates/qdrant-config.py for examples")
    print("")
    if "$MODE" == "docker":
        print("Dashboard: http://$HOST:$PORT/dashboard")
        print("Stop: docker stop qdrant")
    print("")

def main():
    # Initialize client
    client = init_client()
    print("")

    # Create collection
    create_collection(client)
    print("")

    # Add sample data
    add_sample_data(client)

    # Create indexes
    create_payload_index(client)

    # Display summary
    display_summary(client)

if __name__ == "__main__":
    main()
EOF

chmod +x "$SETUP_SCRIPT"
echo "✓ Setup script created: $SETUP_SCRIPT"
echo ""

# Run setup
echo "Step 5: Running Qdrant setup..."
python3 "$SETUP_SCRIPT"
echo ""

# Create usage example
echo "Creating usage example..."
cat > /tmp/qdrant_example.py << 'EOF'
#!/usr/bin/env python3
"""
Qdrant usage example
"""
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue

# Initialize client
client = QdrantClient(url="http://localhost:6333")

# Upsert points
client.upsert(
    collection_name="documents",
    points=[
        PointStruct(
            id=1,
            vector=[0.1] * 1536,  # Replace with actual embedding
            payload={"text": "Document 1", "category": "ml"}
        )
    ]
)

# Search with filter
results = client.search(
    collection_name="documents",
    query_vector=[0.1] * 1536,  # Replace with query embedding
    query_filter=Filter(
        must=[
            FieldCondition(
                key="category",
                match=MatchValue(value="ml")
            )
        ]
    ),
    limit=10
)

# Process results
for result in results:
    print(f"ID: {result.id}, Score: {result.score:.4f}")
    print(f"Text: {result.payload['text']}")

# Delete points
# client.delete(collection_name="documents", points_selector=[1, 2, 3])
EOF

chmod +x /tmp/qdrant_example.py
echo "✓ Usage example: /tmp/qdrant_example.py"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
if [ "$MODE" = "docker" ]; then
    echo "Qdrant is running at: http://$HOST:$PORT"
    echo "Dashboard: http://$HOST:$PORT/dashboard"
    echo ""
    echo "Management:"
    echo "  Stop: docker stop qdrant"
    echo "  Start: docker start qdrant"
    echo "  Logs: docker logs qdrant"
    echo "  Remove: docker rm -f qdrant"
fi
echo ""
echo "Files created:"
echo "  - $SETUP_SCRIPT"
echo "  - /tmp/qdrant_example.py"
echo ""
echo "See templates/qdrant-config.py for more examples"
echo ""
