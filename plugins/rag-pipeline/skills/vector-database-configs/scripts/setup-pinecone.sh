#!/bin/bash
set -e

# Pinecone Setup Script
# Configures Pinecone vector database

# Default values
INDEX_NAME="documents"
DIMENSIONS="1536"
METRIC="cosine"  # or euclidean, dotproduct
CLOUD="aws"  # or gcp, azure
REGION="us-east-1"
SPEC_TYPE="serverless"  # or pod

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --index)
            INDEX_NAME="$2"
            shift 2
            ;;
        --dimensions)
            DIMENSIONS="$2"
            shift 2
            ;;
        --metric)
            METRIC="$2"
            shift 2
            ;;
        --cloud)
            CLOUD="$2"
            shift 2
            ;;
        --region)
            REGION="$2"
            shift 2
            ;;
        --spec)
            SPEC_TYPE="$2"
            shift 2
            ;;
        --api-key)
            export PINECONE_API_KEY="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --index NAME           Index name (default: documents)"
            echo "  --dimensions DIM       Vector dimensions (default: 1536)"
            echo "  --metric METRIC        Distance metric: cosine, euclidean, or dotproduct (default: cosine)"
            echo "  --cloud CLOUD          Cloud provider: aws, gcp, or azure (default: aws)"
            echo "  --region REGION        Cloud region (default: us-east-1)"
            echo "  --spec TYPE            Spec type: serverless or pod (default: serverless)"
            echo "  --api-key KEY          Pinecone API key (or set PINECONE_API_KEY env var)"
            echo "  --help                 Show this help message"
            echo ""
            echo "Get your API key from: https://app.pinecone.io/"
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
echo "Pinecone Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Index: $INDEX_NAME"
echo "  Dimensions: $DIMENSIONS"
echo "  Metric: $METRIC"
echo "  Cloud: $CLOUD"
echo "  Region: $REGION"
echo "  Spec: $SPEC_TYPE"
echo ""

# Check for API key
if [ -z "$PINECONE_API_KEY" ]; then
    echo "ERROR: PINECONE_API_KEY not set"
    echo ""
    echo "Set your API key:"
    echo "  export PINECONE_API_KEY='your-api-key'"
    echo "  or use --api-key flag"
    echo ""
    echo "Get your API key from: https://app.pinecone.io/"
    exit 1
fi
echo "✓ API key found"
echo ""

# Check Python installation
echo "Step 1: Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    echo "Install Python 3.8 or later"
    exit 1
fi
echo "✓ Python 3 found"
echo ""

# Install Pinecone client
echo "Step 2: Installing Pinecone client..."
if python3 -c "import pinecone" 2>/dev/null; then
    VERSION=$(python3 -c "import pinecone; print(pinecone.__version__)")
    echo "✓ Pinecone client already installed (version $VERSION)"
else
    echo "Installing pinecone-client package..."
    pip3 install pinecone-client --quiet
    echo "✓ Pinecone client installed"
fi
echo ""

# Create setup script
echo "Step 3: Creating Pinecone setup script..."
SETUP_SCRIPT="/tmp/setup_pinecone.py"
cat > "$SETUP_SCRIPT" << EOF
#!/usr/bin/env python3
"""
Pinecone setup and configuration script
"""
import os
import sys
from pinecone import Pinecone, ServerlessSpec, PodSpec

def init_client():
    """Initialize Pinecone client"""
    api_key = os.getenv("PINECONE_API_KEY")
    if not api_key:
        print("ERROR: PINECONE_API_KEY environment variable not set")
        sys.exit(1)

    print("Initializing Pinecone client...")
    pc = Pinecone(api_key=api_key)
    print("✓ Client initialized")
    return pc

def create_index(pc):
    """Create or verify index"""
    index_name = "$INDEX_NAME"
    dimensions = $DIMENSIONS
    metric = "$METRIC"
    spec_type = "$SPEC_TYPE"

    print(f"Creating index '{index_name}'...")

    # Check if index exists
    existing_indexes = pc.list_indexes()
    index_names = [idx.name for idx in existing_indexes]

    if index_name in index_names:
        print(f"✓ Index '{index_name}' already exists")
        index = pc.Index(index_name)

        # Verify configuration
        stats = index.describe_index_stats()
        print(f"  Current vector count: {stats.total_vector_count}")
        print(f"  Dimensions: {dimensions}")

        return index

    # Create spec based on type
    if spec_type == "serverless":
        spec = ServerlessSpec(
            cloud="$CLOUD",
            region="$REGION"
        )
        print(f"  Using serverless spec: $CLOUD/$REGION")
    else:
        # Pod-based spec
        spec = PodSpec(
            environment="$CLOUD-$REGION",
            pod_type="p1.x1",  # Smallest pod
            pods=1
        )
        print(f"  Using pod spec: $CLOUD-$REGION")

    # Create index
    try:
        pc.create_index(
            name=index_name,
            dimension=dimensions,
            metric=metric,
            spec=spec
        )
        print(f"✓ Index '{index_name}' created")
        print("  Note: Index may take a few moments to initialize")

        # Wait for index to be ready
        import time
        print("  Waiting for index to be ready...", end="", flush=True)
        for _ in range(30):
            try:
                index = pc.Index(index_name)
                index.describe_index_stats()
                print(" Ready!")
                break
            except:
                print(".", end="", flush=True)
                time.sleep(2)
        else:
            print(" Timeout!")
            print("  Index created but not yet ready. Try again in a few minutes.")

        return index

    except Exception as e:
        print(f"ERROR creating index: {e}")
        sys.exit(1)

def add_sample_data(index):
    """Add sample vectors to index"""
    print("")
    print("Adding sample data...")

    import random

    # Generate sample vectors
    sample_vectors = [
        {
            "id": f"vec{i}",
            "values": [random.random() for _ in range($DIMENSIONS)],
            "metadata": {
                "text": f"Sample document {i}",
                "source": "setup_script",
                "category": "sample"
            }
        }
        for i in range(1, 6)
    ]

    # Upsert vectors
    index.upsert(vectors=sample_vectors)
    print(f"✓ Inserted {len(sample_vectors)} sample vectors")

    # Query test
    print("")
    print("Testing query...")
    query_vector = [random.random() for _ in range($DIMENSIONS)]
    results = index.query(
        vector=query_vector,
        top_k=3,
        include_metadata=True
    )

    print("Sample query results:")
    for match in results['matches']:
        print(f"  - ID: {match['id']}, Score: {match['score']:.4f}")
        print(f"    Text: {match['metadata']['text']}")

def display_summary(pc, index):
    """Display setup summary"""
    print("")
    print("=" * 50)
    print("Pinecone Setup Complete!")
    print("=" * 50)
    print("")
    print(f"Index: $INDEX_NAME")
    print(f"Dimensions: $DIMENSIONS")
    print(f"Metric: $METRIC")
    print(f"Spec: $SPEC_TYPE ($CLOUD/$REGION)")
    print("")

    # Get stats
    stats = index.describe_index_stats()
    print(f"Current stats:")
    print(f"  Total vectors: {stats.total_vector_count}")
    print(f"  Namespaces: {len(stats.namespaces) if stats.namespaces else 0}")
    print("")

    print("Next steps:")
    print("1. Use index.upsert() to add vectors")
    print("2. Use index.query() to search")
    print("3. Use index.fetch() to retrieve by ID")
    print("4. See templates/pinecone-config.py for examples")
    print("")
    print("Dashboard: https://app.pinecone.io/")
    print("")

def main():
    # Initialize client
    pc = init_client()
    print("")

    # Create index
    index = create_index(pc)
    print("")

    # Add sample data
    add_sample_data(index)

    # Display summary
    display_summary(pc, index)

if __name__ == "__main__":
    main()
EOF

chmod +x "$SETUP_SCRIPT"
echo "✓ Setup script created: $SETUP_SCRIPT"
echo ""

# Run setup
echo "Step 4: Running Pinecone setup..."
python3 "$SETUP_SCRIPT"
echo ""

# Create usage example
echo "Creating usage example..."
cat > /tmp/pinecone_example.py << 'EOF'
#!/usr/bin/env python3
"""
Pinecone usage example
"""
import os
from pinecone import Pinecone

# Initialize
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("documents")

# Upsert vectors
index.upsert(vectors=[
    {
        "id": "doc1",
        "values": [0.1] * 1536,  # Replace with actual embedding
        "metadata": {"text": "Document 1", "source": "api"}
    }
])

# Query
results = index.query(
    vector=[0.1] * 1536,  # Replace with query embedding
    top_k=10,
    filter={"source": {"$eq": "api"}},  # Metadata filter
    include_metadata=True
)

# Process results
for match in results['matches']:
    print(f"ID: {match['id']}, Score: {match['score']:.4f}")
    print(f"Text: {match['metadata']['text']}")

# Delete vectors
# index.delete(ids=["doc1"])

# Delete all vectors in namespace
# index.delete(delete_all=True, namespace="")
EOF

chmod +x /tmp/pinecone_example.py
echo "✓ Usage example: /tmp/pinecone_example.py"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  - $SETUP_SCRIPT"
echo "  - /tmp/pinecone_example.py"
echo ""
echo "Environment variable required:"
echo "  PINECONE_API_KEY=$PINECONE_API_KEY"
echo ""
echo "See templates/pinecone-config.py for more examples"
echo "Dashboard: https://app.pinecone.io/"
echo ""
