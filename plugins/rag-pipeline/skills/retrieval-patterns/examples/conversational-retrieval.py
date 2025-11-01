"""
Conversational Retrieval Example

Demonstrates context-aware retrieval for chatbot and multi-turn conversation scenarios.
Handles chat history compression, query rewriting, and follow-up questions.

Use cases:
- Chatbots with memory
- Multi-turn Q&A systems
- Customer support with context
- Document exploration interfaces

Features:
- Chat history management
- Contextual query rewriting
- Follow-up question handling
- Source citation tracking
"""

from typing import List, Dict, Any, Tuple
from dataclasses import dataclass


@dataclass
class ChatMessage:
    """Single chat message"""
    role: str  # 'user' or 'assistant'
    content: str


@dataclass
class ConversationalResult:
    """Result with conversational context"""
    answer: str
    sources: List[Dict[str, Any]]
    standalone_query: str  # Rewritten query with context
    chat_history: List[ChatMessage]


# =======================
# LangChain Conversational Retrieval
# =======================

class ConversationalRetriever:
    """Conversational retrieval chain with chat history"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o-mini"
    ):
        """
        Initialize conversational retriever.

        Args:
            documents: Document corpus
            llm_model: LLM for response generation
        """
        self.documents = documents
        self.llm_model = llm_model
        self.chat_history = []

        self._setup_chain()

    def _setup_chain(self):
        """Setup conversational retrieval chain"""
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.chains import ConversationalRetrievalChain
        from langchain.schema import Document

        # Convert to documents
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(self.documents)
        ]

        # Create vector store
        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)

        # Create LLM
        llm = ChatOpenAI(model=self.llm_model, temperature=0)

        # Create conversational chain
        self.chain = ConversationalRetrievalChain.from_llm(
            llm=llm,
            retriever=vectorstore.as_retriever(search_kwargs={"k": 5}),
            return_source_documents=True,
            verbose=False
        )

    def ask(
        self,
        question: str,
        return_context: bool = True
    ) -> ConversationalResult:
        """
        Ask a question with conversational context.

        Args:
            question: User question
            return_context: Whether to include context in response

        Returns:
            ConversationalResult with answer and sources
        """
        # Invoke chain with chat history
        result = self.chain.invoke({
            "question": question,
            "chat_history": [
                (msg.content if msg.role == "user" else "",
                 msg.content if msg.role == "assistant" else "")
                for msg in self.chat_history
            ]
        })

        # Extract answer and sources
        answer = result["answer"]
        source_docs = result.get("source_documents", [])

        sources = [
            {
                "id": doc.metadata.get("id", "unknown"),
                "content": doc.page_content,
                "metadata": doc.metadata
            }
            for doc in source_docs
        ]

        # Update chat history
        self.chat_history.append(ChatMessage(role="user", content=question))
        self.chat_history.append(ChatMessage(role="assistant", content=answer))

        return ConversationalResult(
            answer=answer,
            sources=sources,
            standalone_query=question,  # Chain handles rewriting internally
            chat_history=self.chat_history.copy()
        )

    def reset_history(self):
        """Clear chat history"""
        self.chat_history = []


# =======================
# Custom Query Rewriting
# =======================

class ContextualQueryRewriter:
    """Rewrite queries using chat history for context"""

    def __init__(
        self,
        llm_model: str = "gpt-4o-mini"
    ):
        """Initialize query rewriter"""
        from langchain_openai import ChatOpenAI

        self.llm = ChatOpenAI(model=llm_model, temperature=0)

    def rewrite_query(
        self,
        current_query: str,
        chat_history: List[ChatMessage]
    ) -> str:
        """
        Rewrite query to include conversational context.

        Args:
            current_query: Current user question
            chat_history: Previous conversation

        Returns:
            Standalone query with context
        """
        if not chat_history:
            # No context, return original
            return current_query

        # Build conversation context
        context = "\n".join([
            f"{msg.role.capitalize()}: {msg.content}"
            for msg in chat_history[-6:]  # Last 3 turns
        ])

        # Rewrite prompt
        prompt = f"""Given the conversation history below, rewrite the follow-up question to be a standalone question that includes all necessary context.

Conversation History:
{context}

Follow-up Question: {current_query}

Standalone Question:"""

        response = self.llm.invoke(prompt)
        standalone_query = response.content.strip()

        return standalone_query


# =======================
# Custom Conversational RAG
# =======================

class CustomConversationalRAG:
    """Custom conversational RAG with explicit control"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o-mini"
    ):
        """Initialize custom conversational RAG"""
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        # Setup retriever
        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)

        self.retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
        self.llm = ChatOpenAI(model=llm_model, temperature=0)
        self.query_rewriter = ContextualQueryRewriter(llm_model)

        self.chat_history = []

    def ask(
        self,
        question: str,
        include_sources: bool = True
    ) -> ConversationalResult:
        """
        Ask question with conversational context.

        Pipeline:
        1. Rewrite query using chat history
        2. Retrieve relevant documents
        3. Generate answer with context
        4. Update chat history

        Args:
            question: User question
            include_sources: Whether to cite sources

        Returns:
            ConversationalResult
        """
        # Step 1: Rewrite query
        standalone_query = self.query_rewriter.rewrite_query(
            question,
            self.chat_history
        )

        print(f"Standalone query: {standalone_query}")

        # Step 2: Retrieve documents
        source_docs = self.retriever.get_relevant_documents(standalone_query)

        sources = [
            {
                "id": doc.metadata.get("id", "unknown"),
                "content": doc.page_content,
                "metadata": doc.metadata
            }
            for doc in source_docs
        ]

        # Step 3: Generate answer
        context = "\n\n".join([doc.page_content for doc in source_docs])

        # Build conversation context
        conv_context = ""
        if self.chat_history:
            recent_history = self.chat_history[-4:]  # Last 2 turns
            conv_context = "Previous conversation:\n" + "\n".join([
                f"{msg.role.capitalize()}: {msg.content}"
                for msg in recent_history
            ]) + "\n\n"

        prompt = f"""{conv_context}Answer the following question based on the provided context. If the answer is not in the context, say so.

Context:
{context}

Question: {question}

Answer:"""

        response = self.llm.invoke(prompt)
        answer = response.content.strip()

        # Step 4: Update history
        self.chat_history.append(ChatMessage(role="user", content=question))
        self.chat_history.append(ChatMessage(role="assistant", content=answer))

        return ConversationalResult(
            answer=answer,
            sources=sources if include_sources else [],
            standalone_query=standalone_query,
            chat_history=self.chat_history.copy()
        )

    def reset(self):
        """Reset conversation"""
        self.chat_history = []


# =======================
# Chat History Compression
# =======================

class CompressingConversationalRAG:
    """Conversational RAG with chat history compression"""

    def __init__(
        self,
        documents: List[Dict[str, Any]],
        llm_model: str = "gpt-4o-mini",
        max_history_tokens: int = 500
    ):
        """
        Initialize with history compression.

        Args:
            documents: Document corpus
            llm_model: LLM model
            max_history_tokens: Max tokens for history (approximate)
        """
        from langchain_openai import OpenAIEmbeddings, ChatOpenAI
        from langchain_community.vectorstores import FAISS
        from langchain.schema import Document

        docs = [
            Document(
                page_content=doc['content'],
                metadata={'id': doc.get('id', f"doc_{i}"), **doc.get('metadata', {})}
            )
            for i, doc in enumerate(documents)
        ]

        embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
        vectorstore = FAISS.from_documents(docs, embeddings)

        self.retriever = vectorstore.as_retriever(search_kwargs={"k": 5})
        self.llm = ChatOpenAI(model=llm_model, temperature=0)
        self.max_history_tokens = max_history_tokens

        self.chat_history = []

    def compress_history(
        self,
        chat_history: List[ChatMessage]
    ) -> str:
        """
        Compress chat history to summary.

        Args:
            chat_history: Full chat history

        Returns:
            Compressed summary
        """
        if not chat_history:
            return ""

        # Convert to text
        history_text = "\n".join([
            f"{msg.role.capitalize()}: {msg.content}"
            for msg in chat_history
        ])

        # Check if compression needed (rough token estimate)
        estimated_tokens = len(history_text.split()) * 1.3

        if estimated_tokens <= self.max_history_tokens:
            return history_text

        # Compress using LLM
        prompt = f"""Summarize the following conversation history concisely while preserving key context:

{history_text}

Summary:"""

        response = self.llm.invoke(prompt)
        summary = response.content.strip()

        return summary

    def ask(self, question: str) -> ConversationalResult:
        """Ask with compressed history"""

        # Compress history if needed
        compressed_history = self.compress_history(self.chat_history)

        # Rewrite query
        standalone_query = question
        if compressed_history:
            prompt = f"""Given this conversation summary, rewrite the follow-up question:

Summary: {compressed_history}

Question: {question}

Standalone Question:"""

            response = self.llm.invoke(prompt)
            standalone_query = response.content.strip()

        # Retrieve and generate (similar to CustomConversationalRAG)
        source_docs = self.retriever.get_relevant_documents(standalone_query)

        sources = [
            {"id": doc.metadata.get("id"), "content": doc.page_content}
            for doc in source_docs
        ]

        context = "\n\n".join([doc.page_content for doc in source_docs])

        prompt = f"""Answer based on context:

Context: {context}

Question: {question}

Answer:"""

        response = self.llm.invoke(prompt)
        answer = response.content.strip()

        # Update history
        self.chat_history.append(ChatMessage(role="user", content=question))
        self.chat_history.append(ChatMessage(role="assistant", content=answer))

        return ConversationalResult(
            answer=answer,
            sources=sources,
            standalone_query=standalone_query,
            chat_history=self.chat_history.copy()
        )


# =======================
# Usage Examples
# =======================

if __name__ == "__main__":
    # Sample documents
    documents = [
        {
            "id": "doc1",
            "content": "Machine learning is a subset of AI that enables systems to learn from data without explicit programming.",
            "metadata": {"source": "ml_intro"}
        },
        {
            "id": "doc2",
            "content": "Supervised learning uses labeled training data. Examples include classification and regression.",
            "metadata": {"source": "ml_types"}
        },
        {
            "id": "doc3",
            "content": "Neural networks consist of layers of interconnected nodes that process information.",
            "metadata": {"source": "neural_nets"}
        }
    ]

    # Example 1: LangChain conversational retrieval
    print("=== LangChain Conversational Retrieval ===")
    chatbot = ConversationalRetriever(documents)

    # First question
    result1 = chatbot.ask("What is machine learning?")
    print(f"\nQ: What is machine learning?")
    print(f"A: {result1.answer}")

    # Follow-up question (uses context)
    result2 = chatbot.ask("What are some examples?")
    print(f"\nQ: What are some examples?")
    print(f"Standalone: {result2.standalone_query}")
    print(f"A: {result2.answer}")

    # Example 2: Custom conversational RAG
    print("\n\n=== Custom Conversational RAG ===")
    custom_rag = CustomConversationalRAG(documents)

    result1 = custom_rag.ask("Tell me about neural networks")
    print(f"\nQ: Tell me about neural networks")
    print(f"A: {result1.answer}")

    result2 = custom_rag.ask("How do they process data?")
    print(f"\nQ: How do they process data?")
    print(f"Standalone: {result2.standalone_query}")
    print(f"A: {result2.answer}")
    print(f"Sources: {[s['id'] for s in result2.sources]}")
