#!/bin/bash
set -e

# FAISS Setup Script
# Installs and configures FAISS for vector search

# Default values
INDEX_TYPE="Flat"  # or IVFFlat, HNSW, IVF_PQ
DIMENSIONS="1536"
METRIC="L2"  # or IP (inner product)
NLIST="100"  # For IVF indices
M="32"  # For HNSW
PERSIST_PATH="./faiss_index"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --index-type)
            INDEX_TYPE="$2"
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
        --nlist)
            NLIST="$2"
            shift 2
            ;;
        --m)
            M="$2"
            shift 2
            ;;
        --persist-path)
            PERSIST_PATH="$2"
            shift 2
            ;;
        --use-gpu)
            USE_GPU="true"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --index-type TYPE      Index type: Flat, IVFFlat, HNSW, IVF_PQ (default: Flat)"
            echo "  --dimensions DIM       Vector dimensions (default: 1536)"
            echo "  --metric METRIC        Distance metric: L2 or IP (default: L2)"
            echo "  --nlist N              Number of clusters for IVF (default: 100)"
            echo "  --m M                  Number of connections for HNSW (default: 32)"
            echo "  --persist-path PATH    Path to save index (default: ./faiss_index)"
            echo "  --use-gpu              Use GPU acceleration if available"
            echo "  --help                 Show this help message"
            echo ""
            echo "Index types:"
            echo "  Flat       - Exact search, best for < 10K vectors"
            echo "  IVFFlat    - Approximate search, good for 10K-10M vectors"
            echo "  HNSW       - Fast approximate search, good for most cases"
            echo "  IVF_PQ     - Memory efficient, good for 10M+ vectors"
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
echo "FAISS Setup Script"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Index Type: $INDEX_TYPE"
echo "  Dimensions: $DIMENSIONS"
echo "  Metric: $METRIC"
if [ "$INDEX_TYPE" = "IVFFlat" ] || [ "$INDEX_TYPE" = "IVF_PQ" ]; then
    echo "  Clusters (nlist): $NLIST"
fi
if [ "$INDEX_TYPE" = "HNSW" ]; then
    echo "  Connections (M): $M"
fi
echo "  Persist Path: $PERSIST_PATH"
if [ "$USE_GPU" = "true" ]; then
    echo "  GPU: Enabled"
fi
echo ""

# Check Python installation
echo "Step 1: Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python 3 not found"
    echo "Install Python 3.8 or later"
    exit 1
fi
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "✓ Python $PYTHON_VERSION found"
echo ""

# Check for conda (recommended for FAISS)
echo "Step 2: Checking installation method..."
INSTALL_METHOD="pip"

if command -v conda &> /dev/null; then
    echo "✓ Conda found - will use conda for installation (recommended)"
    INSTALL_METHOD="conda"
else
    echo "! Conda not found - will use pip"
    echo "  Note: conda is recommended for FAISS installation"
    echo "  Install Miniconda: https://docs.conda.io/en/latest/miniconda.html"
fi
echo ""

# Install FAISS
echo "Step 3: Installing FAISS..."

if python3 -c "import faiss" 2>/dev/null; then
    VERSION=$(python3 -c "import faiss; print(faiss.__version__)")
    echo "✓ FAISS already installed (version $VERSION)"
else
    echo "Installing FAISS..."

    if [ "$INSTALL_METHOD" = "conda" ]; then
        if [ "$USE_GPU" = "true" ]; then
            echo "Installing faiss-gpu via conda..."
            conda install -c pytorch faiss-gpu -y
        else
            echo "Installing faiss-cpu via conda..."
            conda install -c pytorch faiss-cpu -y
        fi
    else
        if [ "$USE_GPU" = "true" ]; then
            echo "Installing faiss-gpu via pip..."
            pip3 install faiss-gpu
        else
            echo "Installing faiss-cpu via pip..."
            pip3 install faiss-cpu
        fi
    fi

    echo "✓ FAISS installed"
fi
echo ""

# Install NumPy if needed
echo "Step 4: Checking NumPy..."
if python3 -c "import numpy" 2>/dev/null; then
    echo "✓ NumPy found"
else
    echo "Installing NumPy..."
    pip3 install numpy
    echo "✓ NumPy installed"
fi
echo ""

# Create setup script
echo "Step 5: Creating FAISS setup script..."
SETUP_SCRIPT="/tmp/setup_faiss.py"
cat > "$SETUP_SCRIPT" << EOF
#!/usr/bin/env python3
"""
FAISS setup and index creation script
"""
import faiss
import numpy as np
import os
import sys

def create_index():
    """Create FAISS index based on configuration"""
    dimensions = $DIMENSIONS
    index_type = "$INDEX_TYPE"
    metric = "$METRIC"
    use_gpu = $([[ "$USE_GPU" = "true" ]] && echo "True" || echo "False")

    print(f"Creating {index_type} index...")
    print(f"  Dimensions: {dimensions}")
    print(f"  Metric: {metric}")

    # Create base index based on metric
    if metric == "L2":
        # L2 (Euclidean) distance
        if index_type == "Flat":
            index = faiss.IndexFlatL2(dimensions)
            print("✓ Created Flat L2 index (exact search)")

        elif index_type == "IVFFlat":
            nlist = $NLIST
            quantizer = faiss.IndexFlatL2(dimensions)
            index = faiss.IndexIVFFlat(quantizer, dimensions, nlist)
            print(f"✓ Created IVFFlat L2 index (nlist={nlist})")
            print("  Note: Index needs training before use")

        elif index_type == "HNSW":
            M = $M
            index = faiss.IndexHNSWFlat(dimensions, M)
            print(f"✓ Created HNSW L2 index (M={M})")

        elif index_type == "IVF_PQ":
            nlist = $NLIST
            m = 8  # Number of sub-quantizers
            quantizer = faiss.IndexFlatL2(dimensions)
            index = faiss.IndexIVFPQ(quantizer, dimensions, nlist, m, 8)
            print(f"✓ Created IVF_PQ L2 index (nlist={nlist}, m={m})")
            print("  Note: Index needs training before use")

        else:
            print(f"ERROR: Unknown index type: {index_type}")
            sys.exit(1)

    elif metric == "IP":
        # Inner Product (for normalized vectors, equivalent to cosine)
        if index_type == "Flat":
            index = faiss.IndexFlatIP(dimensions)
            print("✓ Created Flat IP index (exact search)")

        elif index_type == "IVFFlat":
            nlist = $NLIST
            quantizer = faiss.IndexFlatIP(dimensions)
            index = faiss.IndexIVFFlat(quantizer, dimensions, nlist, faiss.METRIC_INNER_PRODUCT)
            print(f"✓ Created IVFFlat IP index (nlist={nlist})")
            print("  Note: Index needs training before use")

        elif index_type == "HNSW":
            M = $M
            index = faiss.IndexHNSWFlat(dimensions, M, faiss.METRIC_INNER_PRODUCT)
            print(f"✓ Created HNSW IP index (M={M})")

        else:
            print(f"ERROR: {index_type} not supported with IP metric")
            sys.exit(1)

    else:
        print(f"ERROR: Unknown metric: {metric}")
        sys.exit(1)

    # Move to GPU if requested
    if use_gpu:
        if not hasattr(faiss, 'StandardGpuResources'):
            print("WARNING: GPU support not available in this FAISS installation")
        else:
            print("Moving index to GPU...")
            res = faiss.StandardGpuResources()
            index = faiss.index_cpu_to_gpu(res, 0, index)
            print("✓ Index moved to GPU")

    return index

def train_index_if_needed(index, training_data):
    """Train index if it requires training"""
    index_type = "$INDEX_TYPE"

    if index_type in ["IVFFlat", "IVF_PQ"]:
        print("")
        print("Training index...")
        print(f"  Training samples: {len(training_data)}")

        if not index.is_trained:
            index.train(training_data)
            print("✓ Index trained")
        else:
            print("✓ Index already trained")

def add_sample_data(index):
    """Add sample vectors to index"""
    dimensions = $DIMENSIONS

    print("")
    print("Generating sample data...")

    # Generate random vectors
    n_vectors = 1000
    vectors = np.random.random((n_vectors, dimensions)).astype('float32')

    # Normalize for IP metric if needed
    if "$METRIC" == "IP":
        faiss.normalize_L2(vectors)
        print("✓ Vectors normalized for IP metric")

    # Train if needed
    train_index_if_needed(index, vectors)

    # Add vectors
    print(f"Adding {n_vectors} vectors to index...")
    index.add(vectors)
    print(f"✓ Vectors added (total: {index.ntotal})")

    return vectors

def test_search(index, vectors):
    """Test search functionality"""
    print("")
    print("Testing search...")

    # Use first vector as query
    query = vectors[:1]

    # Search
    k = 5  # Number of nearest neighbors
    distances, indices = index.search(query, k)

    print(f"Query returned {len(indices[0])} results:")
    for i, (dist, idx) in enumerate(zip(distances[0], indices[0])):
        print(f"  {i+1}. Index: {idx}, Distance: {dist:.4f}")

def save_index(index):
    """Save index to disk"""
    persist_path = "$PERSIST_PATH"

    print("")
    print(f"Saving index to {persist_path}...")

    # Create directory if needed
    os.makedirs(os.path.dirname(persist_path) if os.path.dirname(persist_path) else ".", exist_ok=True)

    # Save index
    # Note: GPU indices must be moved to CPU before saving
    if hasattr(faiss, 'StandardGpuResources') and "$USE_GPU" == "true":
        print("  Moving index to CPU for saving...")
        index = faiss.index_gpu_to_cpu(index)

    faiss.write_index(index, persist_path)
    print(f"✓ Index saved to {persist_path}")

    # Create metadata file
    metadata_path = persist_path + ".meta"
    with open(metadata_path, 'w') as f:
        f.write(f"index_type=$INDEX_TYPE\n")
        f.write(f"dimensions=$DIMENSIONS\n")
        f.write(f"metric=$METRIC\n")
        f.write(f"ntotal={index.ntotal}\n")
    print(f"✓ Metadata saved to {metadata_path}")

def display_summary(index):
    """Display setup summary"""
    print("")
    print("=" * 50)
    print("FAISS Setup Complete!")
    print("=" * 50)
    print("")
    print(f"Index Type: $INDEX_TYPE")
    print(f"Dimensions: $DIMENSIONS")
    print(f"Metric: $METRIC")
    print(f"Vectors: {index.ntotal}")
    print(f"Trained: {index.is_trained}")
    print("")
    print("Next steps:")
    print("1. Load index: index = faiss.read_index('$PERSIST_PATH')")
    print("2. Add vectors: index.add(vectors)")
    print("3. Search: distances, indices = index.search(query, k)")
    print("4. See templates/faiss-config.py for examples")
    print("")
    print("Performance tips:")
    if "$INDEX_TYPE" == "Flat":
        print("  - Flat index is exact but slow for large datasets")
        print("  - Consider IVFFlat or HNSW for > 10K vectors")
    elif "$INDEX_TYPE" == "IVFFlat":
        print("  - Adjust nprobe for accuracy/speed tradeoff")
        print("  - index.nprobe = 10  # Higher = more accurate, slower")
    elif "$INDEX_TYPE" == "HNSW":
        print("  - Adjust efSearch for accuracy/speed tradeoff")
        print("  - index.hnsw.efSearch = 64  # Higher = more accurate")
    print("")

def main():
    # Create index
    index = create_index()
    print("")

    # Add sample data
    vectors = add_sample_data(index)

    # Test search
    test_search(index, vectors)

    # Save index
    save_index(index)

    # Display summary
    display_summary(index)

if __name__ == "__main__":
    main()
EOF

chmod +x "$SETUP_SCRIPT"
echo "✓ Setup script created: $SETUP_SCRIPT"
echo ""

# Run setup
echo "Step 6: Running FAISS setup..."
python3 "$SETUP_SCRIPT"
echo ""

# Create usage example
echo "Creating usage example..."
cat > /tmp/faiss_example.py << 'EOF'
#!/usr/bin/env python3
"""
FAISS usage example
"""
import faiss
import numpy as np

# Load existing index
index = faiss.read_index("./faiss_index")

# Or create new index
# dimensions = 1536
# index = faiss.IndexFlatL2(dimensions)

# Add vectors
vectors = np.random.random((100, index.d)).astype('float32')
index.add(vectors)

# Search
query = np.random.random((1, index.d)).astype('float32')
k = 10  # Number of results
distances, indices = index.search(query, k)

# Process results
for dist, idx in zip(distances[0], indices[0]):
    print(f"Index: {idx}, Distance: {dist:.4f}")

# Save index
faiss.write_index(index, "./faiss_index")

# For IVF indices, adjust search parameters
# index.nprobe = 10  # Check 10 clusters (higher = more accurate)

# For HNSW indices
# index.hnsw.efSearch = 64  # Search effort (higher = more accurate)
EOF

chmod +x /tmp/faiss_example.py
echo "✓ Usage example: /tmp/faiss_example.py"
echo ""

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Index saved to: $PERSIST_PATH"
echo ""
echo "Files created:"
echo "  - $SETUP_SCRIPT"
echo "  - /tmp/faiss_example.py"
echo ""
echo "Index types guide:"
echo "  Flat     - Exact search, best for < 10K vectors"
echo "  IVFFlat  - Approximate, 10K-10M vectors"
echo "  HNSW     - Fast approximate, good for most cases"
echo "  IVF_PQ   - Memory efficient, 10M+ vectors"
echo ""
echo "See templates/faiss-config.py for more examples"
echo "Documentation: https://faiss.ai/"
echo ""
