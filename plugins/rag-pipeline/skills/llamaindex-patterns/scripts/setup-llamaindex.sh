#!/bin/bash
# setup-llamaindex.sh - Install LlamaIndex dependencies with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== LlamaIndex Setup ===${NC}"

# Detect project type
PROJECT_TYPE=""
if [ -f "package.json" ]; then
    echo -e "${YELLOW}Warning: LlamaIndex is primarily a Python framework.${NC}"
    echo -e "${YELLOW}For TypeScript/JavaScript, consider LlamaIndex.TS${NC}"
    read -p "Continue with Python setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo -e "${GREEN}Found Python ${PYTHON_VERSION}${NC}"

# Check for virtual environment
if [ -z "$VIRTUAL_ENV" ] && [ ! -d "venv" ] && [ ! -d ".venv" ]; then
    echo -e "${YELLOW}No virtual environment detected${NC}"
    read -p "Create virtual environment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python3 -m venv venv
        echo -e "${GREEN}Virtual environment created at ./venv${NC}"
        echo -e "${YELLOW}Activate it with: source venv/bin/activate${NC}"
        source venv/bin/activate
    fi
fi

# Install core LlamaIndex
echo -e "${GREEN}Installing llama-index core...${NC}"
pip install -q llama-index

# Install optional but commonly used packages
echo -e "${GREEN}Installing common integrations...${NC}"

# Vector stores
pip install -q llama-index-vector-stores-chroma
pip install -q llama-index-vector-stores-pinecone
pip install -q llama-index-vector-stores-qdrant

# Embeddings
pip install -q llama-index-embeddings-openai
pip install -q llama-index-embeddings-huggingface

# LLMs
pip install -q llama-index-llms-openai
pip install -q llama-index-llms-anthropic

# Readers
pip install -q llama-index-readers-file

# Additional utilities
pip install -q python-dotenv
pip install -q tiktoken

echo -e "${GREEN}Installing development dependencies...${NC}"
pip install -q pytest pytest-asyncio black

# Verify installation
echo -e "${GREEN}Verifying installation...${NC}"
python3 -c "import llama_index; print(f'LlamaIndex version: {llama_index.__version__}')"

# Create .env template if it doesn't exist
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env template...${NC}"
    cat > .env << 'EOF'
# LlamaIndex Configuration

# OpenAI (for embeddings and LLM)
OPENAI_API_KEY=your_openai_api_key_here

# Anthropic (optional, for Claude models)
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Vector Store Configuration
# Pinecone
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_ENVIRONMENT=your_pinecone_environment_here

# Qdrant (if using cloud)
QDRANT_API_KEY=your_qdrant_api_key_here
QDRANT_URL=your_qdrant_url_here

# LlamaCloud (optional, for managed parsing)
LLAMA_CLOUD_API_KEY=your_llamacloud_api_key_here
EOF
    echo -e "${GREEN}.env template created${NC}"
    echo -e "${YELLOW}Please update .env with your actual API keys${NC}"
fi

# Create requirements.txt
echo -e "${YELLOW}Creating requirements.txt...${NC}"
cat > requirements.txt << 'EOF'
# Core LlamaIndex
llama-index>=0.10.0

# Vector Stores
llama-index-vector-stores-chroma
llama-index-vector-stores-pinecone
llama-index-vector-stores-qdrant

# Embeddings
llama-index-embeddings-openai
llama-index-embeddings-huggingface

# LLMs
llama-index-llms-openai
llama-index-llms-anthropic

# Readers
llama-index-readers-file

# Utilities
python-dotenv
tiktoken

# Development
pytest
pytest-asyncio
black
EOF

echo -e "${GREEN}requirements.txt created${NC}"

# Create storage directory
mkdir -p storage
mkdir -p data

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Update .env with your API keys"
echo -e "  2. Place documents in ./data directory"
echo -e "  3. Run: python examples/basic-rag.py"
echo -e ""
echo -e "${YELLOW}Installed packages:${NC}"
pip list | grep llama-index
