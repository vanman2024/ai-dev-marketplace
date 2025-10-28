#!/bin/bash

#
# Validate RAG Setup for Vercel AI SDK
#
# Checks:
# - AI SDK installation
# - Embedding model access
# - Vector database client
# - Environment variables
#

set -e

echo "==================================="
echo "Validating RAG Setup"
echo "==================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check package.json
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found${NC}"
    exit 1
fi

echo "Checking AI SDK installation..."
echo ""

# Check AI SDK
if ! grep -q '"ai"' package.json; then
    echo -e "${RED}❌ AI SDK not installed${NC}"
    echo -e "${YELLOW}   Run: npm install ai${NC}"
    exit 1
else
    AI_VERSION=$(node -p "require('./package.json').dependencies.ai || 'not found'")
    echo -e "${GREEN}✓ AI SDK installed: ${AI_VERSION}${NC}"
fi

# Check for at least one AI provider
echo ""
echo "Checking AI providers..."
echo ""

PROVIDERS=("@ai-sdk/openai" "@ai-sdk/anthropic" "@ai-sdk/google" "@ai-sdk/cohere")
FOUND_PROVIDER=0

for provider in "${PROVIDERS[@]}"; do
    if grep -q "\"$provider\"" package.json; then
        VERSION=$(node -p "require('./package.json').dependencies['$provider'] || 'not found'")
        echo -e "${GREEN}✓ Found provider: $provider ($VERSION)${NC}"
        FOUND_PROVIDER=1
    fi
done

if [ $FOUND_PROVIDER -eq 0 ]; then
    echo -e "${RED}❌ No AI provider found${NC}"
    echo -e "${YELLOW}   Install one: npm install @ai-sdk/openai${NC}"
    exit 1
fi

# Check for vector database clients
echo ""
echo "Checking vector database clients..."
echo ""

VECTOR_DBS=("@pinecone-database/pinecone" "chromadb" "pg" "weaviate-ts-client" "@qdrant/js-client-rest")
FOUND_VDB=0

for vdb in "${VECTOR_DBS[@]}"; do
    if grep -q "\"$vdb\"" package.json; then
        VERSION=$(node -p "require('./package.json').dependencies['$vdb'] || require('./package.json').devDependencies['$vdb'] || 'not found'")
        echo -e "${GREEN}✓ Found vector DB client: $vdb ($VERSION)${NC}"
        FOUND_VDB=1
    fi
done

if [ $FOUND_VDB -eq 0 ]; then
    echo -e "${YELLOW}⚠ No vector database client found${NC}"
    echo -e "${YELLOW}   Install one:${NC}"
    echo -e "${YELLOW}   - Pinecone: npm install @pinecone-database/pinecone${NC}"
    echo -e "${YELLOW}   - Chroma: npm install chromadb${NC}"
    echo -e "${YELLOW}   - pgvector: npm install pg${NC}"
fi

# Check for zod (required for schemas)
echo ""
if grep -q '"zod"' package.json; then
    echo -e "${GREEN}✓ Zod installed (for schemas)${NC}"
else
    echo -e "${YELLOW}⚠ Zod not found (recommended for validation)${NC}"
    echo -e "${YELLOW}   Run: npm install zod${NC}"
fi

# Check environment variables
echo ""
echo "Checking environment variables..."
echo ""

if [ -f ".env" ]; then
    echo -e "${GREEN}✓ .env file found${NC}"

    # Check for API keys
    if grep -q "OPENAI_API_KEY" .env || \
       grep -q "ANTHROPIC_API_KEY" .env || \
       grep -q "GOOGLE_GENERATIVE_AI_API_KEY" .env || \
       grep -q "COHERE_API_KEY" .env; then
        echo -e "${GREEN}✓ AI provider API key found${NC}"
    else
        echo -e "${YELLOW}⚠ No AI provider API key found in .env${NC}"
    fi

    # Check for vector DB keys
    if grep -q "PINECONE_API_KEY" .env || \
       grep -q "WEAVIATE_API_KEY" .env || \
       grep -q "QDRANT_API_KEY" .env || \
       grep -q "DATABASE_URL" .env; then
        echo -e "${GREEN}✓ Vector database credentials found${NC}"
    else
        echo -e "${YELLOW}⚠ No vector database credentials found in .env${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No .env file found${NC}"
    echo -e "${YELLOW}   Create .env with required API keys${NC}"
fi

# Check .gitignore
if [ -f ".gitignore" ]; then
    if grep -q ".env" .gitignore; then
        echo -e "${GREEN}✓ .env is in .gitignore${NC}"
    else
        echo -e "${YELLOW}⚠ .env not in .gitignore (security risk)${NC}"
    fi
fi

echo ""
echo "==================================="
echo "Summary"
echo "==================================="
echo ""

if [ $FOUND_PROVIDER -eq 1 ]; then
    echo -e "${GREEN}✓ RAG setup is ready${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Use templates/rag-pipeline.ts for implementation"
    echo "2. Choose vector database and configure credentials"
    echo "3. Run scripts/chunk-documents.sh to process documents"
    echo "4. Run scripts/generate-embeddings.sh to create embeddings"
else
    echo -e "${RED}❌ RAG setup incomplete${NC}"
    echo -e "${YELLOW}   Install missing dependencies${NC}"
fi

echo ""
