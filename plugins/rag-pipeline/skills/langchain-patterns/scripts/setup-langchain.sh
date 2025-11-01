#!/bin/bash

# setup-langchain.sh
# Install LangChain and dependencies for RAG applications
# Usage: bash setup-langchain.sh [--all|--minimal|--vectorstore <name>]

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
echo "  LangChain Setup Script"
echo "=================================="
echo ""

# Parse arguments
INSTALL_MODE="${1:---all}"
VECTORSTORE="${2}"

# Check Python version
print_info "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3.9 or higher."
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Python $PYTHON_VERSION found"

# Check pip
print_info "Checking pip..."
if ! command -v pip3 &> /dev/null; then
    print_error "pip3 is not installed. Please install pip."
    exit 1
fi
print_success "pip found"

# Create virtual environment (recommended)
if [ ! -d "venv" ]; then
    print_info "Creating virtual environment..."
    python3 -m venv venv
    print_success "Virtual environment created"
else
    print_warning "Virtual environment already exists"
fi

# Activate virtual environment
print_info "Activating virtual environment..."
source venv/bin/activate
print_success "Virtual environment activated"

# Upgrade pip
print_info "Upgrading pip..."
pip install --upgrade pip --quiet
print_success "pip upgraded"

# Install core LangChain
print_info "Installing LangChain core..."
pip install langchain langchain-core --quiet
print_success "LangChain core installed"

# Install LangChain community packages
print_info "Installing LangChain community packages..."
pip install langchain-community --quiet
print_success "LangChain community installed"

# Install based on mode
case $INSTALL_MODE in
    --minimal)
        print_info "Minimal installation selected"
        pip install langchain-openai --quiet
        print_success "LangChain OpenAI integration installed"
        ;;

    --vectorstore)
        if [ -z "$VECTORSTORE" ]; then
            print_error "Vector store name required. Use: --vectorstore <faiss|chroma|pinecone|qdrant>"
            exit 1
        fi

        print_info "Installing vector store: $VECTORSTORE"
        case $VECTORSTORE in
            faiss)
                pip install faiss-cpu langchain-openai --quiet
                print_success "FAISS vector store installed"
                ;;
            chroma)
                pip install chromadb langchain-openai --quiet
                print_success "Chroma vector store installed"
                ;;
            pinecone)
                pip install pinecone-client langchain-pinecone langchain-openai --quiet
                print_success "Pinecone vector store installed"
                ;;
            qdrant)
                pip install qdrant-client langchain-qdrant langchain-openai --quiet
                print_success "Qdrant vector store installed"
                ;;
            *)
                print_error "Unknown vector store: $VECTORSTORE"
                print_error "Supported: faiss, chroma, pinecone, qdrant"
                exit 1
                ;;
        esac
        ;;

    --all|*)
        print_info "Full installation selected"

        # LLM providers
        print_info "Installing LLM integrations..."
        pip install langchain-openai langchain-anthropic --quiet
        print_success "OpenAI and Anthropic integrations installed"

        # Vector stores
        print_info "Installing vector stores..."
        pip install faiss-cpu chromadb --quiet
        print_success "FAISS and Chroma installed"

        # Document loaders
        print_info "Installing document loaders..."
        pip install pypdf unstructured --quiet
        print_success "PDF and unstructured loaders installed"

        # Text splitters
        print_info "Installing text splitters..."
        pip install tiktoken --quiet
        print_success "Text splitters installed"

        # LangGraph (for agent workflows)
        print_info "Installing LangGraph..."
        pip install langgraph --quiet
        print_success "LangGraph installed"

        # LangSmith (for observability)
        print_info "Installing LangSmith..."
        pip install langsmith --quiet
        print_success "LangSmith installed"

        # Additional utilities
        print_info "Installing utilities..."
        pip install python-dotenv requests beautifulsoup4 --quiet
        print_success "Utilities installed"
        ;;
esac

# Check API keys
echo ""
print_info "Checking API key configuration..."

if [ -z "$OPENAI_API_KEY" ]; then
    print_warning "OPENAI_API_KEY not set"
    print_info "Set with: export OPENAI_API_KEY='sk-...'"
else
    print_success "OPENAI_API_KEY is set"
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    print_warning "ANTHROPIC_API_KEY not set"
    print_info "Set with: export ANTHROPIC_API_KEY='sk-ant-...'"
else
    print_success "ANTHROPIC_API_KEY is set"
fi

if [ -z "$LANGSMITH_API_KEY" ]; then
    print_warning "LANGSMITH_API_KEY not set (optional)"
    print_info "Set with: export LANGSMITH_API_KEY='lsv2_pt_...'"
else
    print_success "LANGSMITH_API_KEY is set"
fi

# Create .env template if it doesn't exist
if [ ! -f ".env" ]; then
    print_info "Creating .env template..."
    cat > .env <<EOF
# LangChain Environment Variables

# OpenAI API Key (required for OpenAI models and embeddings)
OPENAI_API_KEY=sk-your-key-here

# Anthropic API Key (required for Claude models)
ANTHROPIC_API_KEY=sk-ant-your-key-here

# LangSmith API Key (optional, for tracing and evaluation)
LANGSMITH_API_KEY=lsv2_pt_your-key-here
LANGSMITH_PROJECT=rag-pipeline
LANGSMITH_TRACING=true

# Vector Store Configuration
EMBEDDING_MODEL=text-embedding-3-small
CHUNK_SIZE=1000
CHUNK_OVERLAP=200

# Model Configuration
MODEL_NAME=gpt-4
MODEL_TEMPERATURE=0
MAX_TOKENS=2000
EOF
    print_success ".env template created"
    print_warning "Please update .env with your actual API keys"
else
    print_info ".env file already exists"
fi

# Test installation
echo ""
print_info "Testing installation..."

python3 -c "
import langchain
import langchain_community
import langchain_openai
print('✓ LangChain imports successful')
" 2>/dev/null && print_success "LangChain imports verified" || print_error "Import test failed"

# Create requirements.txt
print_info "Generating requirements.txt..."
pip freeze > requirements.txt
print_success "requirements.txt created"

# Summary
echo ""
echo "=================================="
echo "  Installation Complete"
echo "=================================="
echo ""
print_success "LangChain setup completed successfully!"
echo ""
echo "Next steps:"
echo "  1. Activate virtual environment: source venv/bin/activate"
echo "  2. Configure API keys in .env file"
echo "  3. Run test script: bash scripts/test-langchain.sh"
echo "  4. Create vector store: bash scripts/create-vectorstore.sh"
echo ""
print_info "Installation mode: $INSTALL_MODE"
print_info "Python version: $PYTHON_VERSION"
print_info "Virtual environment: ./venv"
echo ""
