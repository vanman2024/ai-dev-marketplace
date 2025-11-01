---
name: langchain-patterns
description: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# LangChain Patterns Skill

Comprehensive LangChain implementation patterns for building production-ready RAG (Retrieval-Augmented Generation) pipelines. This skill provides working scripts, templates, and examples for document loading, vector stores, retrieval chains, LangGraph workflows, and LangSmith observability.

## Use When

- Building RAG applications with LangChain
- Setting up vector stores and embeddings
- Implementing conversational retrieval systems
- Creating multi-step agent workflows with LangGraph
- Integrating LangSmith for tracing and evaluation
- Generating LangChain boilerplate code
- Validating LangChain implementations
- Need working examples of advanced retrieval patterns

## Core Capabilities

### 1. Environment Setup
- Install LangChain and dependencies
- Configure vector store backends (FAISS, Chroma, Pinecone)
- Set up API keys and environment variables
- Validate installation and connectivity

### 2. RAG Chain Patterns
- Document loaders (PDF, CSV, JSON, Web)
- Text splitting strategies
- Embedding models (OpenAI, HuggingFace, Cohere)
- Vector store integration
- Retrieval chains (basic, conversational, multi-query)
- Self-querying retrievers

### 3. LangGraph Workflows
- Stateful multi-actor applications
- Graph-based agent orchestration
- Conditional routing and loops
- State management patterns
- Human-in-the-loop workflows

### 4. LangSmith Integration
- Tracing and debugging
- Evaluation datasets
- Performance monitoring
- Production observability

## Directory Structure

```
langchain-patterns/
├── SKILL.md                          # This file
├── scripts/
│   ├── setup-langchain.sh            # Install dependencies
│   ├── create-vectorstore.sh         # Vector store setup
│   └── test-langchain.sh             # Validation tests
├── templates/
│   ├── rag-chain.py                  # Basic RAG chain template
│   ├── langgraph-workflow.py         # LangGraph agent workflow
│   └── langsmith-integration.py      # Observability template
└── examples/
    ├── conversational-retrieval.py   # Conversational RAG
    ├── multi-query-retrieval.py      # Multi-query retrieval
    └── self-querying-retrieval.py    # Self-querying retriever
```

## Scripts

### setup-langchain.sh

Installs LangChain and common dependencies for RAG applications.

**Usage:**
```bash
bash scripts/setup-langchain.sh [--all|--minimal|--vectorstore]
```

**Options:**
- `--all`: Install full suite (LangChain, LangGraph, LangSmith, all vector stores)
- `--minimal`: Core LangChain only
- `--vectorstore <name>`: Install specific vector store (faiss, chroma, pinecone, qdrant)

**Environment Variables:**
- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key
- `LANGSMITH_API_KEY`: LangSmith API key (optional)

### create-vectorstore.sh

Creates and populates a vector store from documents.

**Usage:**
```bash
bash scripts/create-vectorstore.sh <store_type> <documents_path> <output_path>
```

**Parameters:**
- `store_type`: Vector store type (faiss, chroma, pinecone, qdrant)
- `documents_path`: Path to documents directory or file
- `output_path`: Where to save the vector store

**Environment Variables:**
- `EMBEDDING_MODEL`: Embedding model to use (default: text-embedding-3-small)
- `CHUNK_SIZE`: Text chunk size (default: 1000)
- `CHUNK_OVERLAP`: Chunk overlap (default: 200)

### test-langchain.sh

Validates LangChain installation and configuration.

**Usage:**
```bash
bash scripts/test-langchain.sh [--verbose]
```

**Tests:**
- ✓ LangChain installation
- ✓ API key configuration
- ✓ Vector store connectivity
- ✓ Embedding model access
- ✓ LLM connectivity
- ✓ LangSmith connection (if configured)

## Templates

### rag-chain.py

Basic RAG chain template with document loading, vector store, and retrieval.

**Features:**
- Document loading from multiple formats
- Text splitting with configurable chunks
- Vector store creation and persistence
- Basic retrieval chain
- Conversation memory (optional)

**Usage:**
```python
from templates.rag_chain import RAGChain

# Initialize RAG chain
rag = RAGChain(
    documents_path="./docs",
    vectorstore_path="./vectorstore",
    chunk_size=1000,
    chunk_overlap=200
)

# Load and index documents
rag.load_documents()

# Query
result = rag.query("What are the main features?")
print(result)
```

### langgraph-workflow.py

LangGraph workflow template for multi-step agent orchestration.

**Features:**
- State management
- Conditional routing
- Tool integration
- Error handling and retries
- Human-in-the-loop approval

**Usage:**
```python
from templates.langgraph_workflow import create_workflow

# Create workflow
workflow = create_workflow(
    llm=llm,
    tools=tools,
    checkpointer=MemorySaver()
)

# Execute
result = workflow.invoke({
    "messages": [HumanMessage(content="Analyze this document")]
})
```

### langsmith-integration.py

LangSmith integration template for tracing and evaluation.

**Features:**
- Automatic tracing
- Custom run names and tags
- Evaluation datasets
- Feedback collection
- Performance metrics

**Usage:**
```python
from templates.langsmith_integration import LangSmithTracer

# Initialize tracer
tracer = LangSmithTracer(
    project_name="rag-pipeline",
    tags=["production", "v1"]
)

# Trace chain execution
with tracer.trace("rag-query"):
    result = chain.invoke({"query": "..."})
```

## Examples

### conversational-retrieval.py

Complete conversational retrieval system with memory.

**Features:**
- Conversation history management
- Context-aware retrieval
- Follow-up question handling
- Source citation

**Run:**
```bash
python examples/conversational-retrieval.py --docs ./docs --query "Tell me about RAG"
```

### multi-query-retrieval.py

Multi-query retrieval for better coverage.

**Features:**
- Query expansion from single question
- Parallel retrieval across queries
- Result deduplication
- Ranked fusion

**Run:**
```bash
python examples/multi-query-retrieval.py --docs ./docs --query "What is LangChain?"
```

### self-querying-retrieval.py

Self-querying retriever with metadata filtering.

**Features:**
- Natural language to structured query
- Metadata filter generation
- Semantic + metadata search
- Filter validation

**Run:**
```bash
python examples/self-querying-retrieval.py --docs ./docs --query "Recent papers about transformers"
```

## Common Patterns

### Pattern 1: Basic RAG Pipeline

```python
from langchain_community.document_loaders import DirectoryLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_openai import ChatOpenAI
from langchain.chains import RetrievalQA

# Load documents
loader = DirectoryLoader("./docs", glob="**/*.pdf")
documents = loader.load()

# Split
splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
chunks = splitter.split_documents(documents)

# Embed and store
embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
vectorstore = FAISS.from_documents(chunks, embeddings)

# Create chain
llm = ChatOpenAI(model="gpt-4", temperature=0)
chain = RetrievalQA.from_chain_type(
    llm=llm,
    retriever=vectorstore.as_retriever()
)

# Query
result = chain.invoke({"query": "What is RAG?"})
```

### Pattern 2: Conversational RAG

```python
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory

memory = ConversationBufferMemory(
    memory_key="chat_history",
    return_messages=True
)

chain = ConversationalRetrievalChain.from_llm(
    llm=llm,
    retriever=vectorstore.as_retriever(),
    memory=memory
)

# Chat
result1 = chain({"question": "What is LangChain?"})
result2 = chain({"question": "How do I use it?"})  # Uses context
```

### Pattern 3: LangGraph Agent

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated

class AgentState(TypedDict):
    messages: Annotated[list, "messages"]
    documents: list

def retrieve(state):
    docs = vectorstore.similarity_search(state["messages"][-1])
    return {"documents": docs}

def generate(state):
    response = llm.invoke(state["messages"] + state["documents"])
    return {"messages": state["messages"] + [response]}

workflow = StateGraph(AgentState)
workflow.add_node("retrieve", retrieve)
workflow.add_node("generate", generate)
workflow.set_entry_point("retrieve")
workflow.add_edge("retrieve", "generate")
workflow.add_edge("generate", END)

app = workflow.compile()
```

## Vector Store Comparison

| Store | Local | Cloud | Best For |
|-------|-------|-------|----------|
| FAISS | ✓ | ✗ | Development, single-machine |
| Chroma | ✓ | ✓ | Local development, small datasets |
| Pinecone | ✗ | ✓ | Production, large scale |
| Qdrant | ✓ | ✓ | Hybrid, metadata filtering |

## Troubleshooting

### Import Errors

```bash
# Use langchain_community for loaders and stores
from langchain_community.document_loaders import PDFLoader
from langchain_community.vectorstores import FAISS

# Use langchain_openai for OpenAI integrations
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
```

### API Key Issues

```bash
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export LANGSMITH_API_KEY="lsv2_pt_..."  # Optional
```

### Vector Store Persistence

```python
# Save
vectorstore.save_local("./my_vectorstore")

# Load
vectorstore = FAISS.load_local(
    "./my_vectorstore",
    embeddings,
    allow_dangerous_deserialization=True  # Only if you trust the source
)
```

## Best Practices

1. **Chunk Size**: Start with 1000 tokens, adjust based on domain
2. **Overlap**: 10-20% of chunk size for context continuity
3. **Embeddings**: Use OpenAI text-embedding-3-small for cost/performance balance
4. **Retrieval**: Start with k=4 documents, increase if needed
5. **Memory**: Use ConversationBufferWindowMemory for long conversations
6. **Tracing**: Always enable LangSmith in production
7. **Error Handling**: Wrap chains in try/except, log failures
8. **Caching**: Cache embeddings and vector stores to reduce API calls

## Resources

- **LangChain Docs**: https://docs.langchain.com/oss/python/langchain/overview
- **LangGraph Docs**: https://docs.langchain.com/oss/python/langgraph/
- **LangSmith Docs**: https://docs.langchain.com/langsmith/home
- **Cookbooks**: https://github.com/langchain-ai/langchain/tree/master/cookbook
- **Templates**: https://github.com/langchain-ai/langchain/tree/master/templates

## Implementation Workflow

When using this skill:

1. **Setup**: Run `setup-langchain.sh` to install dependencies
2. **Configure**: Set API keys in environment
3. **Choose Pattern**: Select template based on use case
4. **Load Documents**: Use appropriate document loaders
5. **Create Vector Store**: Run `create-vectorstore.sh` or use template
6. **Build Chain**: Implement retrieval logic
7. **Test**: Run `test-langchain.sh` to validate
8. **Iterate**: Adjust chunk size, retrieval params based on results
9. **Add Observability**: Integrate LangSmith for production
10. **Deploy**: Monitor with LangSmith, optimize based on metrics

## Advanced Features

### Multi-Modal RAG
- Image embeddings with CLIP
- Audio transcription with Whisper
- Video frame analysis

### Hybrid Search
- Combine semantic + keyword search
- BM25 + vector similarity
- Metadata filtering

### Agent Tools
- Web search integration
- API calls within chains
- Code execution tools

### Production Optimization
- Async operations for speed
- Batch processing for scale
- Caching strategies
- Rate limiting

This skill provides everything needed to build production-ready RAG applications with LangChain, from basic retrieval to advanced agent workflows with full observability.
