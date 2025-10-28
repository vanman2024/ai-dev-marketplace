#!/bin/bash
# Suggest optimal vector database for use case
echo "Vector Database Selection Advisor"
echo "================================="
echo ""
read -p "Project size (small/medium/large/enterprise): " SIZE
read -p "Primary use case (chat/rag/knowledge-base/all): " USE_CASE
echo ""
case $SIZE in
    small) echo "Recommended: Chroma (easy setup, good for <100k vectors)";;
    medium) echo "Recommended: Qdrant (best performance, production-ready)";;
    large) echo "Recommended: Qdrant or pgvector (scalable, proven)";;
    enterprise) echo "Recommended: Milvus (handles billions, distributed)";;
esac
echo ""
echo "See templates/vector-db-optimization/ for specific configs"
