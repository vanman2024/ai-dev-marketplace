# langchain-chain.py
# LCEL chain template with OpenRouter

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import ChatOpenAI
import os
from dotenv import load_dotenv

load_dotenv()

def create_chat_chain():
    """
    Create a simple chat chain using LCEL (LangChain Expression Language)

    This chain:
    1. Takes user input
    2. Formats it with a prompt template
    3. Sends to OpenRouter model
    4. Parses the response

    Returns:
        Runnable chain that can be invoked with {"input": "user message"}
    """
    # Configure OpenRouter
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.7,
        default_headers={
            "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL", "http://localhost"),
            "X-Title": os.getenv("OPENROUTER_SITE_NAME", "LangChain App"),
        },
    )

    # Define prompt template
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful AI assistant. Provide clear, accurate responses."),
        ("human", "{input}"),
    ])

    # Create chain using LCEL
    chain = prompt | llm | StrOutputParser()

    return chain


def create_chat_chain_with_history():
    """
    Create a chat chain that maintains conversation history

    This chain:
    1. Takes chat history and new input
    2. Formats with context-aware prompt
    3. Generates response with full context

    Returns:
        Runnable chain that can be invoked with {"history": [...], "input": "message"}
    """
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.7,
    )

    # Prompt template with history
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful AI assistant."),
        ("placeholder", "{history}"),
        ("human", "{input}"),
    ])

    chain = prompt | llm | StrOutputParser()

    return chain


def create_rag_chain(retriever):
    """
    Create a RAG (Retrieval Augmented Generation) chain

    Args:
        retriever: LangChain retriever instance (e.g., from vector store)

    Returns:
        Runnable chain that retrieves context and generates response
    """
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-3.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0.7,
    )

    # RAG prompt template
    prompt = ChatPromptTemplate.from_messages([
        ("system", """You are a helpful assistant. Use the following context to answer the question.
If you cannot answer based on the context, say so.

Context: {context}"""),
        ("human", "{question}"),
    ])

    # Format retrieved documents
    def format_docs(docs):
        return "\n\n".join(doc.page_content for doc in docs)

    # Create RAG chain
    chain = (
        {
            "context": retriever | format_docs,
            "question": RunnablePassthrough(),
        }
        | prompt
        | llm
        | StrOutputParser()
    )

    return chain


# Example usage
if __name__ == "__main__":
    # Simple chat
    print("=== Simple Chat ===")
    chain = create_chat_chain()
    response = chain.invoke({"input": "What is the capital of France?"})
    print(f"Response: {response}\n")

    # Chat with streaming
    print("=== Streaming Chat ===")
    for chunk in chain.stream({"input": "Count from 1 to 5"}):
        print(chunk, end="", flush=True)
    print("\n")

    # Batch processing
    print("=== Batch Processing ===")
    questions = [
        {"input": "What is 2+2?"},
        {"input": "What is the capital of Spain?"},
        {"input": "Who wrote Romeo and Juliet?"},
    ]
    responses = chain.batch(questions)
    for q, r in zip(questions, responses):
        print(f"Q: {q['input']}")
        print(f"A: {r}\n")
