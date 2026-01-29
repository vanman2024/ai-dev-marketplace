#!/bin/bash
# Initialize LangGraph project
# Usage: ./init-langgraph.sh [python|js]

LANG=${1:-python}

echo "📦 Initializing LangGraph ($LANG)..."

if [ "$LANG" = "python" ]; then
    pip install langgraph langchain-openai
    mkdir -p workflows/nodes
else
    npm install @langchain/langgraph @langchain/openai
    mkdir -p src/workflows/nodes
fi

echo "✅ LangGraph initialized"
