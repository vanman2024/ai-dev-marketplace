# LangChain RAG Example

Complete guide to building RAG (Retrieval Augmented Generation) applications with LangChain and OpenRouter.

## What is RAG?

RAG combines:
- **Retrieval**: Finding relevant information from a knowledge base
- **Augmented**: Adding that information to the prompt
- **Generation**: Using an LLM to generate a response

Benefits:
- Answers based on your specific data
- Reduces hallucinations
- Always up-to-date information
- Citations and sources

## Setup

### Python

```bash
pip install langchain langchain-openai langchain-community faiss-cpu python-dotenv
```

### Environment Variables

```bash
OPENROUTER_API_KEY=sk-or-v1-your-key-here
OPENROUTER_MODEL=anthropic/claude-3.5-sonnet
```

## Basic RAG Implementation

### Step 1: Load Documents

```python
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Load documents
loader = TextLoader("knowledge_base.txt")
documents = loader.load()

# Split into chunks
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
)
splits = text_splitter.split_documents(documents)

print(f"Split into {len(splits)} chunks")
```

### Step 2: Create Vector Store

```python
from langchain_openai import OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
import os

# Create embeddings
embeddings = OpenAIEmbeddings(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
)

# Create vector store
vectorstore = FAISS.from_documents(splits, embeddings)

# Save for later use
vectorstore.save_local("vectorstore")
```

### Step 3: Create RAG Chain

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import ChatOpenAI

# Configure LLM
llm = ChatOpenAI(
    model=os.getenv("OPENROUTER_MODEL"),
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
    temperature=0.3,
)

# Create retriever
retriever = vectorstore.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 4},
)

# Define prompt
prompt = ChatPromptTemplate.from_messages([
    ("system", """Answer based on the following context. If you cannot answer, say so.

Context:
{context}"""),
    ("human", "{question}"),
])

# Format documents
def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

# Create chain
rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

# Use the chain
answer = rag_chain.invoke("What is OpenRouter?")
print(answer)
```

## Advanced: RAG with Sources

```python
from langchain_core.runnables import RunnableParallel

# Chain that returns both answer and source documents
rag_with_sources = RunnableParallel(
    {
        "context": retriever,
        "question": RunnablePassthrough(),
    }
).assign(
    answer=lambda x: (
        prompt
        | llm
        | StrOutputParser()
    ).invoke({
        "context": format_docs(x["context"]),
        "question": x["question"],
    })
)

result = rag_with_sources.invoke("What is OpenRouter?")

print("Answer:", result["answer"])
print("\nSources:")
for i, doc in enumerate(result["context"], 1):
    print(f"{i}. {doc.page_content[:100]}...")
```

## RAG with Different Document Loaders

### PDF Documents

```python
from langchain_community.document_loaders import PyPDFLoader

loader = PyPDFLoader("document.pdf")
pages = loader.load_and_split()

vectorstore = FAISS.from_documents(pages, embeddings)
```

### Web Pages

```python
from langchain_community.document_loaders import WebBaseLoader

loader = WebBaseLoader([
    "https://example.com/page1",
    "https://example.com/page2",
])
docs = loader.load()

vectorstore = FAISS.from_documents(docs, embeddings)
```

### CSV Files

```python
from langchain_community.document_loaders import CSVLoader

loader = CSVLoader("data.csv")
docs = loader.load()

vectorstore = FAISS.from_documents(docs, embeddings)
```

### Multiple Sources

```python
from langchain_community.document_loaders import DirectoryLoader

# Load all text files in a directory
loader = DirectoryLoader(
    "documents/",
    glob="**/*.txt",
    loader_cls=TextLoader,
)
docs = loader.load()

vectorstore = FAISS.from_documents(docs, embeddings)
```

## RAG with Metadata Filtering

```python
# Add metadata to documents
documents = [
    Document(
        page_content="Information about product A",
        metadata={"source": "products", "category": "electronics"},
    ),
    Document(
        page_content="Information about product B",
        metadata={"source": "products", "category": "clothing"},
    ),
]

vectorstore = FAISS.from_documents(documents, embeddings)

# Retrieve with metadata filter
retriever = vectorstore.as_retriever(
    search_kwargs={
        "k": 4,
        "filter": {"category": "electronics"},
    }
)
```

## RAG with Reranking

```python
from langchain.retrievers import ContextualCompressionRetriever
from langchain.retrievers.document_compressors import LLMChainExtractor

# Create compressor
compressor = LLMChainExtractor.from_llm(llm)

# Wrap retriever
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=retriever,
)

# Use in chain
rag_chain = (
    {"context": compression_retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)
```

## Conversational RAG

```python
from langchain.memory import ConversationBufferMemory
from langchain_core.prompts import MessagesPlaceholder

# Create memory
memory = ConversationBufferMemory(
    memory_key="chat_history",
    return_messages=True,
)

# Prompt with history
conversational_prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer based on context and conversation history.\n\nContext:\n{context}"),
    MessagesPlaceholder(variable_name="chat_history"),
    ("human", "{question}"),
])

# Conversational RAG chain
conversational_rag = (
    {
        "context": retriever | format_docs,
        "question": RunnablePassthrough(),
        "chat_history": lambda _: memory.load_memory_variables({})["chat_history"],
    }
    | conversational_prompt
    | llm
    | StrOutputParser()
)

# Multi-turn conversation
question1 = "What is OpenRouter?"
answer1 = conversational_rag.invoke(question1)
memory.save_context({"input": question1}, {"output": answer1})

question2 = "What models does it support?"
answer2 = conversational_rag.invoke(question2)  # Uses context from previous question
memory.save_context({"input": question2}, {"output": answer2})
```

## Best Practices

### 1. Chunk Size Optimization

```python
# Experiment with different chunk sizes
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,   # Smaller chunks for precise retrieval
    chunk_overlap=50, # Overlap to maintain context
)
```

### 2. Multiple Retrievers

```python
from langchain.retrievers import EnsembleRetriever
from langchain_community.retrievers import BM25Retriever

# Combine semantic and keyword search
bm25_retriever = BM25Retriever.from_documents(documents)
faiss_retriever = vectorstore.as_retriever()

ensemble_retriever = EnsembleRetriever(
    retrievers=[bm25_retriever, faiss_retriever],
    weights=[0.3, 0.7],  # Favor semantic search
)
```

### 3. Custom Prompts

```python
# Prompt for specific use cases
customer_support_prompt = ChatPromptTemplate.from_messages([
    ("system", """You are a helpful customer support agent.
Use the following documentation to answer customer questions.
If the answer isn't in the documentation, apologize and offer to escalate.

Documentation:
{context}"""),
    ("human", "{question}"),
])
```

### 4. Evaluation

```python
# Test RAG system
test_questions = [
    ("What is OpenRouter?", "expected answer..."),
    ("How do I get an API key?", "expected answer..."),
]

for question, expected in test_questions:
    answer = rag_chain.invoke(question)
    print(f"Q: {question}")
    print(f"A: {answer}")
    print(f"Expected: {expected}\n")
```

## Production Considerations

### 1. Persistent Vector Store

```python
# Save vector store
vectorstore.save_local("vectorstore")

# Load later
from langchain_community.vectorstores import FAISS
vectorstore = FAISS.load_local("vectorstore", embeddings)
```

### 2. Incremental Updates

```python
# Add new documents
new_docs = loader.load()
vectorstore.add_documents(new_docs)
vectorstore.save_local("vectorstore")
```

### 3. Error Handling

```python
try:
    answer = rag_chain.invoke(question)
except Exception as e:
    answer = "I'm having trouble accessing the knowledge base. Please try again."
    logger.error(f"RAG error: {e}")
```

### 4. Caching

```python
from langchain.cache import SQLiteCache
from langchain.globals import set_llm_cache

set_llm_cache(SQLiteCache(database_path=".langchain.db"))
```

## Complete Example

```python
import os
from dotenv import load_dotenv
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough

load_dotenv()

# 1. Load and split documents
loader = TextLoader("knowledge_base.txt")
documents = loader.load()
text_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
splits = text_splitter.split_documents(documents)

# 2. Create embeddings and vector store
embeddings = OpenAIEmbeddings(
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
)
vectorstore = FAISS.from_documents(splits, embeddings)

# 3. Create LLM and retriever
llm = ChatOpenAI(
    model=os.getenv("OPENROUTER_MODEL"),
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    openai_api_base="https://openrouter.ai/api/v1",
)
retriever = vectorstore.as_retriever()

# 4. Create RAG chain
prompt = ChatPromptTemplate.from_messages([
    ("system", "Answer based on context:\n\n{context}"),
    ("human", "{question}"),
])

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)

# 5. Use the chain
answer = rag_chain.invoke("Your question here")
print(answer)
```

## Resources

- LangChain RAG Tutorial: https://python.langchain.com/docs/tutorials/rag/
- Vector Store Guide: https://python.langchain.com/docs/integrations/vectorstores/
- OpenRouter Models: https://openrouter.ai/models
