#!/bin/bash

# test-langchain.sh
# Validate LangChain installation and configuration
# Usage: bash test-langchain.sh [--verbose]

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

# Verbose mode
VERBOSE=false
if [ "$1" = "--verbose" ]; then
    VERBOSE=true
fi

# Print header
echo "=================================="
echo "  LangChain Validation Tests"
echo "=================================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    print_info "Activating virtual environment..."
    source venv/bin/activate
    print_success "Virtual environment activated"
    echo ""
fi

# Test 1: Python version
echo "Test 1: Python Version"
echo "----------------------"
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    print_success "Python found: $PYTHON_VERSION"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    print_error "Python 3 not found"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test 2: LangChain Core
echo "Test 2: LangChain Core Installation"
echo "------------------------------------"
python3 -c "
import sys
try:
    import langchain
    import langchain_core
    print('✓ LangChain version:', langchain.__version__)
    sys.exit(0)
except ImportError as e:
    print('✗ Import failed:', e)
    sys.exit(1)
" && {
    print_success "LangChain core imports successful"
    TESTS_PASSED=$((TESTS_PASSED + 1))
} || {
    print_error "LangChain core import failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}
echo ""

# Test 3: LangChain Community
echo "Test 3: LangChain Community Installation"
echo "-----------------------------------------"
python3 -c "
import sys
try:
    import langchain_community
    from langchain_community.document_loaders import TextLoader
    from langchain_community.vectorstores import FAISS
    print('✓ LangChain community imports successful')
    sys.exit(0)
except ImportError as e:
    print('✗ Import failed:', e)
    sys.exit(1)
" && {
    print_success "LangChain community imports successful"
    TESTS_PASSED=$((TESTS_PASSED + 1))
} || {
    print_error "LangChain community import failed"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}
echo ""

# Test 4: OpenAI Integration
echo "Test 4: OpenAI Integration"
echo "--------------------------"
if [ -z "$OPENAI_API_KEY" ]; then
    print_warning "OPENAI_API_KEY not set - skipping OpenAI tests"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
else
    python3 -c "
import sys
import os
try:
    from langchain_openai import OpenAIEmbeddings, ChatOpenAI

    # Test embeddings
    embeddings = OpenAIEmbeddings(model='text-embedding-3-small')
    print('✓ OpenAI embeddings initialized')

    # Test LLM
    llm = ChatOpenAI(model='gpt-4', temperature=0)
    print('✓ OpenAI LLM initialized')

    # Test API connection
    if '$VERBOSE' == 'true':
        response = llm.invoke('Say hi')
        print('✓ OpenAI API connection verified:', response.content[:50])

    sys.exit(0)
except Exception as e:
    print('✗ OpenAI test failed:', e)
    sys.exit(1)
" && {
        print_success "OpenAI integration verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_error "OpenAI integration failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    }
fi
echo ""

# Test 5: Anthropic Integration
echo "Test 5: Anthropic Integration"
echo "-----------------------------"
if [ -z "$ANTHROPIC_API_KEY" ]; then
    print_warning "ANTHROPIC_API_KEY not set - skipping Anthropic tests"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
else
    python3 -c "
import sys
import os
try:
    from langchain_anthropic import ChatAnthropic

    # Test LLM
    llm = ChatAnthropic(model='claude-3-5-sonnet-20241022', temperature=0)
    print('✓ Anthropic LLM initialized')

    # Test API connection
    if '$VERBOSE' == 'true':
        response = llm.invoke('Say hi')
        print('✓ Anthropic API connection verified:', response.content[:50])

    sys.exit(0)
except ImportError:
    print('⚠ langchain-anthropic not installed')
    print('  Install with: pip install langchain-anthropic')
    sys.exit(1)
except Exception as e:
    print('✗ Anthropic test failed:', e)
    sys.exit(1)
" && {
        print_success "Anthropic integration verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_warning "Anthropic integration not available"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    }
fi
echo ""

# Test 6: Vector Store (FAISS)
echo "Test 6: FAISS Vector Store"
echo "--------------------------"
python3 -c "
import sys
try:
    from langchain_community.vectorstores import FAISS
    from langchain_openai import OpenAIEmbeddings
    from langchain_core.documents import Document

    # Create test documents
    docs = [
        Document(page_content='LangChain is a framework for building LLM applications.'),
        Document(page_content='Vector stores enable semantic search.')
    ]

    # Create embeddings
    embeddings = OpenAIEmbeddings(model='text-embedding-3-small')

    # Create vector store
    vectorstore = FAISS.from_documents(docs, embeddings)
    print('✓ FAISS vector store created')

    # Test retrieval
    results = vectorstore.similarity_search('What is LangChain?', k=1)
    print(f'✓ Retrieved {len(results)} documents')

    if '$VERBOSE' == 'true':
        print('  Result:', results[0].page_content[:60])

    sys.exit(0)
except ImportError as e:
    print('⚠ FAISS not installed:', e)
    print('  Install with: pip install faiss-cpu')
    sys.exit(1)
except Exception as e:
    print('✗ FAISS test failed:', e)
    sys.exit(1)
" && {
        print_success "FAISS vector store verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_warning "FAISS vector store not available"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    }
echo ""

# Test 7: Document Loaders
echo "Test 7: Document Loaders"
echo "------------------------"
python3 -c "
import sys
try:
    from langchain_community.document_loaders import (
        TextLoader,
        DirectoryLoader
    )
    print('✓ Text loaders available')

    try:
        from langchain_community.document_loaders import PDFLoader
        print('✓ PDF loader available')
    except ImportError:
        print('⚠ PDF loader not available (install pypdf)')

    sys.exit(0)
except ImportError as e:
    print('✗ Document loaders import failed:', e)
    sys.exit(1)
" && {
        print_success "Document loaders verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_error "Document loaders failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    }
echo ""

# Test 8: Text Splitters
echo "Test 8: Text Splitters"
echo "----------------------"
python3 -c "
import sys
try:
    from langchain_text_splitters import (
        RecursiveCharacterTextSplitter,
        CharacterTextSplitter
    )

    # Test splitter
    splitter = RecursiveCharacterTextSplitter(chunk_size=100, chunk_overlap=20)
    text = 'This is a test. ' * 20
    chunks = splitter.split_text(text)
    print(f'✓ Text splitter created {len(chunks)} chunks')

    sys.exit(0)
except ImportError as e:
    print('✗ Text splitter import failed:', e)
    sys.exit(1)
" && {
        print_success "Text splitters verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_error "Text splitters failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    }
echo ""

# Test 9: LangGraph
echo "Test 9: LangGraph (Optional)"
echo "----------------------------"
python3 -c "
import sys
try:
    from langgraph.graph import StateGraph, END
    print('✓ LangGraph available')
    sys.exit(0)
except ImportError:
    print('⚠ LangGraph not installed')
    print('  Install with: pip install langgraph')
    sys.exit(1)
" && {
        print_success "LangGraph verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_warning "LangGraph not available (optional)"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    }
echo ""

# Test 10: LangSmith
echo "Test 10: LangSmith (Optional)"
echo "-----------------------------"
if [ -z "$LANGSMITH_API_KEY" ]; then
    print_warning "LANGSMITH_API_KEY not set - skipping LangSmith tests"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
else
    python3 -c "
import sys
import os
try:
    from langsmith import Client

    # Create client
    client = Client()
    print('✓ LangSmith client created')

    if '$VERBOSE' == 'true':
        # Test connection
        client.list_datasets(limit=1)
        print('✓ LangSmith API connection verified')

    sys.exit(0)
except ImportError:
    print('⚠ LangSmith not installed')
    print('  Install with: pip install langsmith')
    sys.exit(1)
except Exception as e:
    print('✗ LangSmith test failed:', e)
    sys.exit(1)
" && {
        print_success "LangSmith verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_warning "LangSmith not available (optional)"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    }
fi
echo ""

# Test 11: Complete RAG Chain
echo "Test 11: Complete RAG Chain"
echo "---------------------------"
if [ -z "$OPENAI_API_KEY" ]; then
    print_warning "OPENAI_API_KEY not set - skipping RAG chain test"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
else
    python3 -c "
import sys
try:
    from langchain_community.vectorstores import FAISS
    from langchain_openai import OpenAIEmbeddings, ChatOpenAI
    from langchain_core.documents import Document
    from langchain.chains import RetrievalQA

    # Create test documents
    docs = [
        Document(page_content='LangChain is a framework for developing applications powered by language models.'),
        Document(page_content='RAG stands for Retrieval-Augmented Generation.')
    ]

    # Create vector store
    embeddings = OpenAIEmbeddings(model='text-embedding-3-small')
    vectorstore = FAISS.from_documents(docs, embeddings)
    print('✓ Vector store created')

    # Create LLM
    llm = ChatOpenAI(model='gpt-4', temperature=0)
    print('✓ LLM initialized')

    # Create RAG chain
    chain = RetrievalQA.from_chain_type(
        llm=llm,
        retriever=vectorstore.as_retriever()
    )
    print('✓ RAG chain created')

    # Test query
    if '$VERBOSE' == 'true':
        result = chain.invoke({'query': 'What is LangChain?'})
        print('✓ Query executed successfully')
        print('  Result:', result['result'][:100])

    sys.exit(0)
except Exception as e:
    print('✗ RAG chain test failed:', e)
    sys.exit(1)
" && {
        print_success "Complete RAG chain verified"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    } || {
        print_error "RAG chain test failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    }
fi
echo ""

# Summary
echo "=================================="
echo "  Test Results Summary"
echo "=================================="
echo ""
echo "  ✓ Passed:  $TESTS_PASSED"
echo "  ✗ Failed:  $TESTS_FAILED"
echo "  ⚠ Skipped: $TESTS_SKIPPED"
echo ""

# Exit code
if [ $TESTS_FAILED -gt 0 ]; then
    print_error "Some tests failed. Check configuration and API keys."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Run: source venv/bin/activate"
    echo "  2. Set API keys in .env or environment"
    echo "  3. Install missing packages: bash scripts/setup-langchain.sh --all"
    echo ""
    exit 1
else
    print_success "All tests passed! LangChain is ready to use."
    echo ""
    echo "Next steps:"
    echo "  1. Create vector store: bash scripts/create-vectorstore.sh faiss ./docs ./vectorstore"
    echo "  2. Use templates in templates/ directory"
    echo "  3. Run examples in examples/ directory"
    echo ""
    exit 0
fi
