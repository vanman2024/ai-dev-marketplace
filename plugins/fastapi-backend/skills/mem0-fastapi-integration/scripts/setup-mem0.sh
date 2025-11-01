#!/bin/bash
# Setup Mem0 for FastAPI integration

set -e

echo "🚀 Setting up Mem0 for FastAPI..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Python version
echo "📋 Checking Python version..."
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
REQUIRED_VERSION="3.9"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo -e "${RED}❌ Python 3.9+ required. Found: $PYTHON_VERSION${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python version: $PYTHON_VERSION${NC}"

# Install Mem0
echo -e "\n📦 Installing Mem0 and dependencies..."
pip install mem0ai>=0.1.0 --quiet
echo -e "${GREEN}✓ Mem0 installed${NC}"

# Install additional dependencies
echo -e "\n📦 Installing additional dependencies..."
pip install openai>=1.0.0 --quiet
pip install qdrant-client>=1.7.0 --quiet
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create environment template if it doesn't exist
ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "\n📄 Creating environment configuration..."
    cat > "$ENV_EXAMPLE" << 'EOF'
# Mem0 Configuration
# Choose one: Hosted Mem0 OR Self-Hosted

# Option 1: Hosted Mem0 Platform (Recommended for getting started)
MEM0_API_KEY=your_mem0_api_key_here

# Option 2: Self-Hosted Configuration
# Uncomment and configure if using self-hosted setup

# Vector Database (Qdrant)
# QDRANT_HOST=localhost
# QDRANT_PORT=6333
# QDRANT_API_KEY=your_qdrant_api_key

# LLM Provider
# OPENAI_API_KEY=your_openai_api_key

# Embeddings Provider
# OPENAI_API_KEY=your_openai_api_key  # Can be same as LLM

# Memory Settings
MEMORY_CACHE_TTL_SECONDS=300
MEMORY_SEARCH_LIMIT_DEFAULT=5
MEMORY_SEARCH_LIMIT_MAX=20
EOF
    echo -e "${GREEN}✓ Created $ENV_EXAMPLE${NC}"
    echo -e "${YELLOW}⚠️  Copy $ENV_EXAMPLE to $ENV_FILE and add your API keys${NC}"
else
    echo -e "${YELLOW}⚠️  $ENV_FILE already exists, skipping template creation${NC}"
fi

# Check if vector database is needed (self-hosted)
echo -e "\n🔍 Checking vector database setup..."
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Docker found${NC}"
    echo -e "${YELLOW}💡 To run Qdrant locally with Docker:${NC}"
    echo "   docker run -p 6333:6333 -p 6334:6334 \\"
    echo "       -v \$(pwd)/qdrant_storage:/qdrant/storage:z \\"
    echo "       qdrant/qdrant"
else
    echo -e "${YELLOW}⚠️  Docker not found. Install Docker to run vector databases locally${NC}"
fi

# Create memory service template location
TEMPLATES_DIR="app/services"
if [ -d "$TEMPLATES_DIR" ]; then
    echo -e "\n📁 Services directory found: $TEMPLATES_DIR"
    echo -e "${YELLOW}💡 Copy memory service template:${NC}"
    echo "   cp skills/mem0-fastapi-integration/templates/memory_service.py $TEMPLATES_DIR/"
else
    echo -e "${YELLOW}⚠️  Create $TEMPLATES_DIR directory for memory service${NC}"
fi

# Verify installation
echo -e "\n🧪 Verifying Mem0 installation..."
python3 -c "import mem0; print(f'Mem0 version: {mem0.__version__}')" 2>/dev/null && \
    echo -e "${GREEN}✓ Mem0 verified${NC}" || \
    echo -e "${RED}❌ Mem0 verification failed${NC}"

# Summary
echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Mem0 setup complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"

echo -e "\n📋 Next steps:"
echo "1. Configure environment variables in $ENV_FILE"
echo "2. Choose hosted Mem0 or self-hosted setup"
echo "3. If self-hosted, start vector database (Qdrant)"
echo "4. Copy templates to your FastAPI project"
echo "5. Run test script: ./scripts/test-memory.sh"

echo -e "\n📚 Documentation:"
echo "- Mem0 Docs: https://docs.mem0.ai"
echo "- Hosted Platform: https://docs.mem0.ai/platform/quickstart"
echo "- Self-Hosted: https://docs.mem0.ai/open-source/overview"

echo -e "\n${GREEN}Happy coding! 🎉${NC}"
