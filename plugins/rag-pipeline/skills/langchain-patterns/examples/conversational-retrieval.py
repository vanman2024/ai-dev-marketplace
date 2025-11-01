#!/usr/bin/env python3
"""
Conversational Retrieval Example
=================================

Complete conversational retrieval system with memory.

Features:
- Conversation history management
- Context-aware retrieval
- Follow-up question handling
- Source citation
- Streaming responses (optional)

Usage:
    python conversational-retrieval.py --docs ./docs --vectorstore ./vectorstore
    python conversational-retrieval.py --docs ./docs --query "Tell me about RAG" --follow-up "How does it work?"
"""

import argparse
from pathlib import Path
from typing import List, Dict, Any

from langchain_community.document_loaders import DirectoryLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
from langchain_community.vectorstores import FAISS
from langchain.chains import ConversationalRetrievalChain
from langchain.memory import ConversationBufferMemory
from langchain_core.messages import HumanMessage, AIMessage


class ConversationalRAG:
    """Conversational RAG system with memory."""

    def __init__(
        self,
        documents_path: str,
        vectorstore_path: str = "./vectorstore",
        model: str = "gpt-4",
        temperature: float = 0,
        k: int = 4
    ):
        """
        Initialize conversational RAG.

        Args:
            documents_path: Path to documents
            vectorstore_path: Path to vector store
            model: LLM model name
            temperature: LLM temperature
            k: Number of documents to retrieve
        """
        self.documents_path = Path(documents_path)
        self.vectorstore_path = Path(vectorstore_path)
        self.k = k

        # Initialize embeddings
        self.embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

        # Initialize LLM
        self.llm = ChatOpenAI(model=model, temperature=temperature)

        # Initialize memory
        self.memory = ConversationBufferMemory(
            memory_key="chat_history",
            return_messages=True,
            output_key="answer"
        )

        # Load or create vector store
        self.vectorstore = self._load_vectorstore()

        # Create chain
        self.chain = self._create_chain()

        print("✓ Conversational RAG initialized")

    def _load_vectorstore(self) -> FAISS:
        """Load or create vector store."""
        if self.vectorstore_path.exists():
            print(f"Loading vector store from {self.vectorstore_path}")
            vectorstore = FAISS.load_local(
                str(self.vectorstore_path),
                self.embeddings,
                allow_dangerous_deserialization=True
            )
            print("✓ Vector store loaded")
            return vectorstore

        # Create new vector store
        print(f"Creating vector store from {self.documents_path}")

        # Load documents
        loader = DirectoryLoader(
            str(self.documents_path),
            glob="**/*.txt",
            loader_cls=TextLoader
        )
        documents = loader.load()
        print(f"✓ Loaded {len(documents)} documents")

        # Split
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        chunks = splitter.split_documents(documents)
        print(f"✓ Created {len(chunks)} chunks")

        # Create vectorstore
        vectorstore = FAISS.from_documents(chunks, self.embeddings)
        vectorstore.save_local(str(self.vectorstore_path))
        print(f"✓ Vector store saved to {self.vectorstore_path}")

        return vectorstore

    def _create_chain(self) -> ConversationalRetrievalChain:
        """Create conversational retrieval chain."""
        chain = ConversationalRetrievalChain.from_llm(
            llm=self.llm,
            retriever=self.vectorstore.as_retriever(
                search_kwargs={"k": self.k}
            ),
            memory=self.memory,
            return_source_documents=True,
            verbose=False
        )
        return chain

    def query(self, question: str) -> Dict[str, Any]:
        """
        Ask a question with conversation context.

        Args:
            question: User question

        Returns:
            Dictionary with answer and source documents
        """
        result = self.chain({"question": question})

        return {
            "answer": result["answer"],
            "sources": [
                {
                    "content": doc.page_content,
                    "metadata": doc.metadata
                }
                for doc in result.get("source_documents", [])
            ]
        }

    def get_conversation_history(self) -> List[Dict[str, str]]:
        """
        Get conversation history.

        Returns:
            List of message dictionaries
        """
        messages = self.memory.chat_memory.messages
        history = []

        for msg in messages:
            if isinstance(msg, HumanMessage):
                history.append({"role": "user", "content": msg.content})
            elif isinstance(msg, AIMessage):
                history.append({"role": "assistant", "content": msg.content})

        return history

    def clear_history(self):
        """Clear conversation history."""
        self.memory.clear()
        print("✓ Conversation history cleared")

    def interactive_mode(self):
        """Run interactive conversation loop."""
        print("\n" + "=" * 60)
        print("  Conversational RAG - Interactive Mode")
        print("=" * 60)
        print("\nCommands:")
        print("  'quit' or 'exit' - Exit interactive mode")
        print("  'clear' - Clear conversation history")
        print("  'history' - Show conversation history")
        print("\n" + "=" * 60 + "\n")

        while True:
            try:
                question = input("\nYou: ").strip()

                if not question:
                    continue

                if question.lower() in ["quit", "exit"]:
                    print("\nGoodbye!")
                    break

                if question.lower() == "clear":
                    self.clear_history()
                    continue

                if question.lower() == "history":
                    history = self.get_conversation_history()
                    print("\n" + "-" * 60)
                    print("Conversation History:")
                    print("-" * 60)
                    for msg in history:
                        role = msg["role"].capitalize()
                        content = msg["content"]
                        print(f"\n{role}: {content}")
                    print("-" * 60)
                    continue

                # Query
                result = self.query(question)

                # Display answer
                print(f"\nAssistant: {result['answer']}")

                # Display sources
                if result["sources"]:
                    print(f"\n[Sources: {len(result['sources'])} documents]")

            except KeyboardInterrupt:
                print("\n\nGoodbye!")
                break
            except Exception as e:
                print(f"\nError: {e}")


def main():
    parser = argparse.ArgumentParser(
        description="Conversational Retrieval Example"
    )
    parser.add_argument(
        "--docs",
        required=True,
        help="Path to documents directory"
    )
    parser.add_argument(
        "--vectorstore",
        default="./vectorstore",
        help="Path to vector store"
    )
    parser.add_argument(
        "--query",
        help="Initial query"
    )
    parser.add_argument(
        "--follow-up",
        help="Follow-up query"
    )
    parser.add_argument(
        "--interactive",
        action="store_true",
        help="Run in interactive mode"
    )
    parser.add_argument(
        "--model",
        default="gpt-4",
        help="LLM model to use"
    )
    parser.add_argument(
        "--k",
        type=int,
        default=4,
        help="Number of documents to retrieve"
    )

    args = parser.parse_args()

    # Initialize conversational RAG
    rag = ConversationalRAG(
        documents_path=args.docs,
        vectorstore_path=args.vectorstore,
        model=args.model,
        k=args.k
    )

    # Interactive mode
    if args.interactive:
        rag.interactive_mode()
        return

    # Single query mode
    if args.query:
        print("\n" + "=" * 60)
        print("Query 1:")
        print("=" * 60)
        print(f"\nYou: {args.query}")

        result = rag.query(args.query)

        print(f"\nAssistant: {result['answer']}")

        if result["sources"]:
            print(f"\n\nSources ({len(result['sources'])} documents):")
            for i, source in enumerate(result["sources"], 1):
                print(f"\n{i}. {source['content'][:200]}...")

        # Follow-up query
        if args.follow_up:
            print("\n" + "=" * 60)
            print("Query 2 (Follow-up):")
            print("=" * 60)
            print(f"\nYou: {args.follow_up}")

            result2 = rag.query(args.follow_up)

            print(f"\nAssistant: {result2['answer']}")

            if result2["sources"]:
                print(f"\n\nSources ({len(result2['sources'])} documents):")
                for i, source in enumerate(result2["sources"], 1):
                    print(f"\n{i}. {source['content'][:200]}...")

        # Show conversation history
        print("\n" + "=" * 60)
        print("Conversation History:")
        print("=" * 60)
        history = rag.get_conversation_history()
        for msg in history:
            role = msg["role"].capitalize()
            print(f"\n{role}: {msg['content']}")

    else:
        print("\nNo query provided. Use --query or --interactive")
        print("Example: python conversational-retrieval.py --docs ./docs --interactive")


if __name__ == "__main__":
    main()
