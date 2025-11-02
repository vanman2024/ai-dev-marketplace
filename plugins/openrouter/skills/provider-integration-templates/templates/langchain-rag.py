# langchain-rag.py
# RAG (Retrieval Augmented Generation) implementation with OpenRouter

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import TextLoader
import os
from dotenv import load_dotenv

load_dotenv()


def create_vector_store(documents_path: str):
    """
    Create a vector store from documents

    Args:
        documents_path: Path to text file or directory of documents

    Returns:
        FAISS vector store with embedded documents
    """
    # Load documents
    loader = TextLoader(documents_path)
    documents = loader.load()

    # Split documents into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
    )
    splits = text_splitter.split_documents(documents)

    # Create embeddings
    # Note: Using OpenAI embeddings through OpenRouter
    embeddings = OpenAIEmbeddings(
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
    )

    # Create vector store
    vectorstore = FAISS.from_documents(splits, embeddings)

    return vectorstore


def create_rag_chain(vectorstore):
    """
    Create a RAG chain using LCEL

    Args:
        vectorstore: FAISS vector store with embedded documents

    Returns:
        Runnable RAG chain
    """
    # Configure OpenRouter LLM
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.3,  # Lower temperature for factual responses
        default_headers={
            "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL", "http://localhost"),
            "X-Title": os.getenv("OPENROUTER_SITE_NAME", "RAG App"),
        },
    )

    # Create retriever from vector store
    retriever = vectorstore.as_retriever(
        search_type="similarity",
        search_kwargs={"k": 4},  # Retrieve top 4 most similar chunks
    )

    # Create RAG prompt template
    prompt = ChatPromptTemplate.from_messages([
        ("system", """You are a helpful assistant that answers questions based on the provided context.
Use the following context to answer the question. If you cannot answer the question based on the context,
say "I don't have enough information to answer that question."

Context:
{context}"""),
        ("human", "{question}"),
    ])

    # Format retrieved documents
    def format_docs(docs):
        return "\n\n".join(doc.page_content for doc in docs)

    # Create RAG chain using LCEL
    rag_chain = (
        {
            "context": retriever | format_docs,
            "question": RunnablePassthrough(),
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    return rag_chain


def create_rag_chain_with_sources(vectorstore):
    """
    Create a RAG chain that includes source citations

    Args:
        vectorstore: FAISS vector store

    Returns:
        Runnable RAG chain that returns answer with sources
    """
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.3,
    )

    retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

    prompt = ChatPromptTemplate.from_messages([
        ("system", """Answer the question based on the context. Include specific quotes from the context
to support your answer. Format your response as:

Answer: [your answer]

Sources:
- [relevant quote 1]
- [relevant quote 2]

Context:
{context}"""),
        ("human", "{question}"),
    ])

    def format_docs(docs):
        return "\n\n".join(f"[Source {i+1}]: {doc.page_content}" for i, doc in enumerate(docs))

    rag_chain = (
        {
            "context": retriever | format_docs,
            "question": RunnablePassthrough(),
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    return rag_chain


def create_conversational_rag_chain(vectorstore):
    """
    Create a RAG chain with conversation history

    Args:
        vectorstore: FAISS vector store

    Returns:
        Runnable RAG chain with memory
    """
    from langchain.memory import ConversationBufferMemory
    from langchain_core.prompts import MessagesPlaceholder

    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.3,
    )

    retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

    # Create memory
    memory = ConversationBufferMemory(
        memory_key="chat_history",
        return_messages=True,
        output_key="answer",
    )

    # Prompt with conversation history
    prompt = ChatPromptTemplate.from_messages([
        ("system", """Answer questions based on the context and conversation history.

Context:
{context}"""),
        MessagesPlaceholder(variable_name="chat_history"),
        ("human", "{question}"),
    ])

    def format_docs(docs):
        return "\n\n".join(doc.page_content for doc in docs)

    rag_chain = (
        {
            "context": retriever | format_docs,
            "question": RunnablePassthrough(),
            "chat_history": lambda _: memory.load_memory_variables({})["chat_history"],
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    return rag_chain, memory


# Example usage
if __name__ == "__main__":
    # Create sample document
    with open("sample_doc.txt", "w") as f:
        f.write("""
OpenRouter provides access to multiple AI models through a single API.
It offers models from Anthropic, OpenAI, Meta, Google, and more.

Features include:
- Unified API for all models
- Automatic fallbacks
- Cost optimization
- Usage analytics
- Model comparison tools

Popular models available:
- Claude 3.5 Sonnet from Anthropic
- GPT-4 Turbo from OpenAI
- Llama 3.1 from Meta
- Gemini Pro from Google
        """)

    # Create vector store
    print("Creating vector store...")
    vectorstore = create_vector_store("sample_doc.txt")
    print("✅ Vector store created\n")

    # Create RAG chain
    rag_chain = create_rag_chain(vectorstore)

    # Ask questions
    print("=== RAG Chain Demo ===\n")

    questions = [
        "What models does OpenRouter support?",
        "What features does OpenRouter offer?",
        "Which model should I use for reasoning tasks?",
    ]

    for question in questions:
        print(f"Q: {question}")
        answer = rag_chain.invoke(question)
        print(f"A: {answer}\n")

    # Cleanup
    os.remove("sample_doc.txt")

    print("\n=== RAG with Sources Demo ===\n")

    # Recreate document and vector store for sources demo
    with open("sample_doc.txt", "w") as f:
        f.write("""
OpenRouter provides access to multiple AI models through a single API.
It offers models from Anthropic, OpenAI, Meta, Google, and more.
        """)

    vectorstore = create_vector_store("sample_doc.txt")
    rag_with_sources = create_rag_chain_with_sources(vectorstore)

    answer = rag_with_sources.invoke("What is OpenRouter?")
    print(answer)

    # Cleanup
    os.remove("sample_doc.txt")
