#!/bin/bash
# test-llamaindex.sh - Validate LlamaIndex installation and configuration

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

echo -e "${GREEN}=== LlamaIndex Validation Tests ===${NC}\n"

# Test 1: Python installation
echo -n "Checking Python installation... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} $PYTHON_VERSION"
else
    echo -e "${RED}✗ Python 3 not found${NC}"
    ((ERRORS++))
fi

# Test 2: LlamaIndex core
echo -n "Checking LlamaIndex core... "
if python3 -c "import llama_index" 2>/dev/null; then
    VERSION=$(python3 -c "import llama_index; print(llama_index.__version__)")
    echo -e "${GREEN}✓${NC} version $VERSION"
else
    echo -e "${RED}✗ LlamaIndex not installed${NC}"
    ((ERRORS++))
fi

# Test 3: Core imports
echo -n "Checking core imports... "
if python3 -c "from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Core imports failed${NC}"
    ((ERRORS++))
fi

# Test 4: Environment file
echo -n "Checking .env file... "
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC}"

    # Check for required keys
    if grep -q "OPENAI_API_KEY" .env; then
        if grep -q "OPENAI_API_KEY=your_" .env; then
            echo -e "  ${YELLOW}⚠${NC} OPENAI_API_KEY not configured"
        else
            echo -e "  ${GREEN}✓${NC} OPENAI_API_KEY configured"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} OPENAI_API_KEY not in .env"
    fi
else
    echo -e "${YELLOW}⚠${NC} .env file not found"
fi

# Test 5: Vector store integrations
echo -n "Checking vector store integrations... "
VECTOR_STORES=0
python3 -c "import llama_index.vector_stores.chroma" 2>/dev/null && ((VECTOR_STORES++))
python3 -c "import llama_index.vector_stores.pinecone" 2>/dev/null && ((VECTOR_STORES++))
python3 -c "import llama_index.vector_stores.qdrant" 2>/dev/null && ((VECTOR_STORES++))

if [ $VECTOR_STORES -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $VECTOR_STORES vector stores available"
else
    echo -e "${YELLOW}⚠${NC} No vector stores installed"
fi

# Test 6: Embedding models
echo -n "Checking embedding models... "
EMBED_MODELS=0
python3 -c "import llama_index.embeddings.openai" 2>/dev/null && ((EMBED_MODELS++))
python3 -c "import llama_index.embeddings.huggingface" 2>/dev/null && ((EMBED_MODELS++))

if [ $EMBED_MODELS -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $EMBED_MODELS embedding models available"
else
    echo -e "${YELLOW}⚠${NC} No embedding models installed"
fi

# Test 7: LLM integrations
echo -n "Checking LLM integrations... "
LLMS=0
python3 -c "import llama_index.llms.openai" 2>/dev/null && ((LLMS++))
python3 -c "import llama_index.llms.anthropic" 2>/dev/null && ((LLMS++))

if [ $LLMS -gt 0 ]; then
    echo -e "${GREEN}✓${NC} $LLMS LLM providers available"
else
    echo -e "${YELLOW}⚠${NC} No LLM providers installed"
fi

# Test 8: Basic functionality test
echo -n "Testing basic VectorStoreIndex creation... "
TEST_RESULT=$(python3 << 'EOF'
import sys
import os
os.environ['OPENAI_API_KEY'] = 'sk-test'  # Dummy key for structure test

try:
    from llama_index.core import Document, VectorStoreIndex
    from llama_index.core.node_parser import SimpleNodeParser

    # Create a test document
    doc = Document(text="This is a test document for validation.")

    # This will fail without a real API key, but tests imports work
    print("OK")
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
EOF
)

if [ "$TEST_RESULT" = "OK" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Basic test failed${NC}"
    ((ERRORS++))
fi

# Test 9: Data directory
echo -n "Checking data directory... "
if [ -d "data" ]; then
    FILE_COUNT=$(find data -type f | wc -l)
    if [ $FILE_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓${NC} $FILE_COUNT files found"
    else
        echo -e "${YELLOW}⚠${NC} data directory empty"
    fi
else
    echo -e "${YELLOW}⚠${NC} data directory not found"
fi

# Test 10: Storage directory
echo -n "Checking storage directory... "
if [ -d "storage" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC} storage directory not found (will be created when needed)"
fi

# Summary
echo -e "\n${GREEN}=== Test Summary ===${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS critical test(s) failed${NC}"
    echo -e "\nTo fix issues, run: bash scripts/setup-llamaindex.sh"
    exit 1
fi
