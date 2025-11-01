#!/bin/bash
#
# Setup HuggingFace Embeddings
#
# Downloads and configures sentence-transformers models locally.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

echo "=================================================="
echo "HuggingFace Embeddings Setup"
echo "=================================================="

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not installed."
    exit 1
fi

# Install sentence-transformers
echo ""
echo "Installing sentence-transformers library..."
pip3 install --quiet sentence-transformers torch

# Ask which model to download
echo ""
echo "Available models:"
echo "  1) all-MiniLM-L6-v2 (384 dims, 80MB, fastest)"
echo "  2) all-mpnet-base-v2 (768 dims, 420MB, high quality)"
echo "  3) bge-base-en-v1.5 (768 dims, 420MB, excellent retrieval)"
echo "  4) bge-large-en-v1.5 (1024 dims, 1.2GB, top performance)"
echo "  5) multi-qa-mpnet-base-dot-v1 (768 dims, 420MB, Q&A optimized)"
echo "  6) paraphrase-multilingual-mpnet-base-v2 (768 dims, multilingual)"
echo "  7) All of the above"
echo ""
read -p "Select model to download [1-7, default=1]: " model_choice

case ${model_choice:-1} in
    1) models=("all-MiniLM-L6-v2") ;;
    2) models=("all-mpnet-base-v2") ;;
    3) models=("BAAI/bge-base-en-v1.5") ;;
    4) models=("BAAI/bge-large-en-v1.5") ;;
    5) models=("multi-qa-mpnet-base-dot-v1") ;;
    6) models=("paraphrase-multilingual-mpnet-base-v2") ;;
    7) models=("all-MiniLM-L6-v2" "all-mpnet-base-v2" "BAAI/bge-base-en-v1.5" "BAAI/bge-large-en-v1.5" "multi-qa-mpnet-base-dot-v1" "paraphrase-multilingual-mpnet-base-v2") ;;
    *) echo "Invalid choice, defaulting to all-MiniLM-L6-v2"; models=("all-MiniLM-L6-v2") ;;
esac

# Download models
for model in "${models[@]}"; do
    echo ""
    echo "Downloading model: $model"
    python3 << EOF
from sentence_transformers import SentenceTransformer
import sys

try:
    print(f"Loading {sys.argv[1]}...")
    model = SentenceTransformer('$model')

    # Test the model
    embeddings = model.encode(["This is a test sentence"])
    print(f"✓ Model loaded successfully")
    print(f"✓ Embedding dimensions: {len(embeddings[0])}")
    print(f"✓ Model cached for offline use")
except Exception as e:
    print(f"✗ Error loading model: {e}", file=sys.stderr)
    sys.exit(1)
EOF
done

echo ""
echo "=================================================="
echo "HuggingFace Embeddings Setup Complete"
echo "=================================================="
echo ""
echo "Models are cached in: ~/.cache/huggingface/hub/"
echo ""
echo "Configuration template:"
echo "  templates/huggingface-embedding-config.py"
echo ""
echo "Quick test:"
echo "  python3 -c \"from sentence_transformers import SentenceTransformer; model = SentenceTransformer('all-MiniLM-L6-v2'); print(model.encode(['Hello world']))\""
echo ""
