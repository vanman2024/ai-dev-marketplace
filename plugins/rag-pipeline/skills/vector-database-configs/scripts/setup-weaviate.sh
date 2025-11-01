#!/bin/bash
set -e

# Weaviate Setup Script
# Installs and configures Weaviate vector database

# Default values
MODE="docker"  # or cloud
COLLECTION_NAME="Documents"
VECTORIZER="none"  # or text2vec-openai, text2vec-cohere, etc.
HOST="localhost"
PORT="8080"
GRPC_PORT="50051"

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
        --vectorizer)
            VECTORIZER="$2"
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
        --weaviate-url)
            WEAVIATE_URL="$2"
            shift 2
            ;;
        --weaviate-key)
            export WEAVIATE_API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --mode MODE            Deployment mode: docker or cloud (default: docker)"
            echo "  --collection NAME      Collection class name (default: Documents)"
            echo "  --vectorizer MODULE    Vectorizer module: none, text2vec-openai, etc. (default: none)"
            echo "  --host HOST            Host for Docker mode (default: localhost)"
            echo "  --port PORT            HTTP port for Docker mode (default: 8080)"
            echo "  --grpc-port PORT       gRPC port for Docker mode (default: 50051)"
            echo "  --weaviate-url URL     Weaviate cloud URL (for cloud mode)"
            echo "  --weaviate-key KEY     Weaviate API key (for cloud mode)"
            echo "  --help                 Show this help message"
            echo ""
            echo "For cloud setup, get credentials from: https://console.weaviate.cloud/"
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
echo "Weaviate Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Mode: $MODE"
echo "  Collection: $COLLECTION_NAME"
echo "  Vectorizer: $VECTORIZER"
if [ "$MODE" = "docker" ]; then
    echo "  Host: $HOST:$PORT"
else
    echo "  URL: ${WEAVIATE_URL:-not set}"
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

    echo "Step 2: Starting Weaviate with Docker Compose..."

    # Create docker-compose.yml
    COMPOSE_FILE="/tmp/weaviate-docker-compose.yml"
    cat > "$COMPOSE_FILE" << 'EOF'
version: '3.4'
services:
  weaviate:
    command:
      - --host
      - 0.0.0.0
      - --port
      - '8080'
      - --scheme
      - http
    image: cr.weaviate.io/semitechnologies/weaviate:1.24.0
    ports:
      - "8080:8080"
      - "50051:50051"
    restart: on-failure:0
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      ENABLE_MODULES: 'text2vec-openai,text2vec-cohere,text2vec-huggingface,generative-openai'
      CLUSTER_HOSTNAME: 'node1'
    volumes:
      - weaviate_data:/var/lib/weaviate

volumes:
  weaviate_data:
EOF

    echo "✓ Docker Compose file created: $COMPOSE_FILE"
    echo ""

    # Start Weaviate
    echo "Starting Weaviate container..."
    docker compose -f "$COMPOSE_FILE" up -d

    echo "✓ Weaviate started"
    echo "  Waiting for Weaviate to be ready..."

    # Wait for Weaviate to be ready
    for i in {1..30}; do
        if curl -sf "http://$HOST:$PORT/v1/.well-known/ready" > /dev/null 2>&1; then
            echo "✓ Weaviate is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "ERROR: Weaviate failed to start within 60 seconds"
            echo "Check logs: docker compose -f $COMPOSE_FILE logs"
            exit 1
        fi
        sleep 2
    done
    echo ""

    WEAVIATE_URL="http://$HOST:$PORT"

elif [ "$MODE" = "cloud" ]; then
    # Cloud-based setup
    if [ -z "$WEAVIATE_URL" ]; then
        echo "ERROR: --weaviate-url required for cloud mode"
        echo "Get your Weaviate Cloud URL from: https://console.weaviate.cloud/"
        exit 1
    fi

    echo "Step 1: Validating cloud connection..."
    if ! curl -sf "$WEAVIATE_URL/v1/.well-known/ready" > /dev/null 2>&1; then
        echo "ERROR: Cannot connect to Weaviate at $WEAVIATE_URL"
        echo "Check your URL and network connection"
        exit 1
    fi
    echo "✓ Connected to Weaviate Cloud"
    echo ""
fi

# Install Python client
echo "Step 3: Installing Weaviate Python client..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    exit 1
fi

if python3 -c "import weaviate" 2>/dev/null; then
    VERSION=$(python3 -c "import weaviate; print(weaviate.__version__)")
    echo "✓ Weaviate client already installed (version $VERSION)"
else
    echo "Installing weaviate-client package..."
    pip3 install weaviate-client --quiet
    echo "✓ Weaviate client installed"
fi
echo ""

# Create setup script
echo "Step 4: Creating schema setup script..."
SETUP_SCRIPT="/tmp/setup_weaviate.py"
cat > "$SETUP_SCRIPT" << EOF
#!/usr/bin/env python3
"""
Weaviate setup and schema configuration script
"""
import weaviate
from weaviate.classes.config import Configure, Property, DataType
import os
import sys

def init_client():
    """Initialize Weaviate client"""
    url = "$WEAVIATE_URL"
    api_key = os.getenv("WEAVIATE_API_KEY")

    print(f"Connecting to Weaviate at {url}...")

    try:
        if api_key:
            # Cloud with authentication
            client = weaviate.connect_to_weaviate_cloud(
                cluster_url=url,
                auth_credentials=weaviate.auth.AuthApiKey(api_key)
            )
        else:
            # Local without authentication
            client = weaviate.connect_to_local(
                host="$HOST",
                port=$PORT,
                grpc_port=$GRPC_PORT
            )

        # Test connection
        if not client.is_ready():
            print("ERROR: Weaviate is not ready")
            sys.exit(1)

        print("✓ Connected to Weaviate")
        return client

    except Exception as e:
        print(f"ERROR connecting to Weaviate: {e}")
        sys.exit(1)

def create_schema(client):
    """Create schema/collection"""
    collection_name = "$COLLECTION_NAME"

    print(f"Creating collection '{collection_name}'...")

    # Check if collection exists
    try:
        existing = client.collections.get(collection_name)
        print(f"✓ Collection '{collection_name}' already exists")
        return existing
    except:
        pass

    # Create collection
    try:
        # Configure vectorizer
        vectorizer = "$VECTORIZER"
        if vectorizer == "none":
            vectorizer_config = None
        elif vectorizer == "text2vec-openai":
            vectorizer_config = Configure.Vectorizer.text2vec_openai()
        elif vectorizer == "text2vec-cohere":
            vectorizer_config = Configure.Vectorizer.text2vec_cohere()
        else:
            vectorizer_config = None

        collection = client.collections.create(
            name=collection_name,
            description="Document collection for RAG pipeline",
            vectorizer_config=vectorizer_config,
            properties=[
                Property(
                    name="content",
                    data_type=DataType.TEXT,
                    description="Document content"
                ),
                Property(
                    name="source",
                    data_type=DataType.TEXT,
                    description="Document source"
                ),
                Property(
                    name="category",
                    data_type=DataType.TEXT,
                    description="Document category"
                ),
                Property(
                    name="metadata",
                    data_type=DataType.TEXT,
                    description="Additional metadata as JSON string"
                )
            ]
        )

        print(f"✓ Collection '{collection_name}' created")
        return collection

    except Exception as e:
        print(f"ERROR creating collection: {e}")
        sys.exit(1)

def add_sample_data(collection):
    """Add sample objects to collection"""
    print("")
    print("Adding sample data...")

    sample_data = [
        {
            "content": "Machine learning is a subset of artificial intelligence.",
            "source": "sample",
            "category": "ml",
            "metadata": '{"index": 1}'
        },
        {
            "content": "Natural language processing enables computers to understand human language.",
            "source": "sample",
            "category": "nlp",
            "metadata": '{"index": 2}'
        },
        {
            "content": "Vector databases store and retrieve high-dimensional embeddings.",
            "source": "sample",
            "category": "databases",
            "metadata": '{"index": 3}'
        }
    ]

    # Insert data
    with collection.batch.dynamic() as batch:
        for item in sample_data:
            batch.add_object(properties=item)

    print(f"✓ Added {len(sample_data)} sample objects")

    # Query test
    print("")
    print("Testing query...")
    response = collection.query.near_text(
        query="machine learning",
        limit=2
    )

    print("Sample query results:")
    for obj in response.objects:
        print(f"  - {obj.properties['content'][:60]}...")
        print(f"    Category: {obj.properties['category']}")

def display_summary(client, collection):
    """Display setup summary"""
    print("")
    print("=" * 50)
    print("Weaviate Setup Complete!")
    print("=" * 50)
    print("")
    print(f"Collection: $COLLECTION_NAME")
    print(f"Vectorizer: $VECTORIZER")
    print(f"URL: $WEAVIATE_URL")
    print("")

    # Get stats
    response = collection.aggregate.over_all(total_count=True)
    print(f"Current stats:")
    print(f"  Total objects: {response.total_count}")
    print("")

    print("Next steps:")
    print("1. Use collection.data.insert() to add objects")
    print("2. Use collection.query.near_vector() to search")
    print("3. Use collection.query.fetch_objects() to retrieve")
    print("4. See templates/weaviate-schema.py for examples")
    print("")
    if "$MODE" == "docker":
        print("GraphQL endpoint: http://$HOST:$PORT/v1/graphql")
        print("Stop: docker compose -f /tmp/weaviate-docker-compose.yml down")
    print("")

def main():
    # Initialize client
    client = init_client()
    print("")

    # Create schema
    collection = create_schema(client)
    print("")

    # Add sample data
    add_sample_data(collection)

    # Display summary
    display_summary(client, collection)

    # Close client
    client.close()

if __name__ == "__main__":
    main()
EOF

chmod +x "$SETUP_SCRIPT"
echo "✓ Setup script created: $SETUP_SCRIPT"
echo ""

# Run setup
echo "Step 5: Running Weaviate setup..."
python3 "$SETUP_SCRIPT"
echo ""

# Create usage example
echo "Creating usage example..."
cat > /tmp/weaviate_example.py << 'EOF'
#!/usr/bin/env python3
"""
Weaviate usage example
"""
import weaviate

# Connect to local Weaviate
client = weaviate.connect_to_local()

# Get collection
collection = client.collections.get("Documents")

# Insert object
collection.data.insert(
    properties={
        "content": "Document content here",
        "source": "api",
        "category": "test"
    }
)

# Query by vector similarity
response = collection.query.near_text(
    query="search query",
    limit=10,
    filters=weaviate.classes.query.Filter.by_property("category").equal("test")
)

# Process results
for obj in response.objects:
    print(f"Content: {obj.properties['content']}")
    print(f"Score: {obj.metadata.distance}")

client.close()
EOF

chmod +x /tmp/weaviate_example.py
echo "✓ Usage example: /tmp/weaviate_example.py"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
if [ "$MODE" = "docker" ]; then
    echo "Weaviate is running at: http://$HOST:$PORT"
    echo "GraphQL: http://$HOST:$PORT/v1/graphql"
    echo ""
    echo "Management:"
    echo "  Stop: docker compose -f $COMPOSE_FILE down"
    echo "  Logs: docker compose -f $COMPOSE_FILE logs -f"
    echo "  Restart: docker compose -f $COMPOSE_FILE restart"
fi
echo ""
echo "Files created:"
if [ "$MODE" = "docker" ]; then
    echo "  - $COMPOSE_FILE"
fi
echo "  - $SETUP_SCRIPT"
echo "  - /tmp/weaviate_example.py"
echo ""
echo "See templates/weaviate-schema.py for more examples"
echo ""
