#!/usr/bin/env python3
"""
Chatbot with Memory Example

Complete implementation of a conversational AI chatbot using LlamaIndex
with memory management and context-aware responses.

Features:
- Conversation history tracking
- Context-aware responses
- Memory summarization
- Session management

Usage:
    python chatbot-with-memory.py
"""

import os
import sys
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Check for API key
if not os.getenv("OPENAI_API_KEY"):
    print("Error: OPENAI_API_KEY not set")
    sys.exit(1)

from llama_index.core import (
    VectorStoreIndex,
    SimpleDirectoryReader,
    Settings,
    Document,
)
from llama_index.core.chat_engine import CondensePlusContextChatEngine
from llama_index.core.memory import ChatMemoryBuffer
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI


class ConversationalChatbot:
    """
    A chatbot with conversation memory and context awareness.
    """

    def __init__(
        self,
        data_dir: str = "./data",
        model: str = "gpt-4o-mini",
        memory_token_limit: int = 3000,
    ):
        """
        Initialize the chatbot.

        Args:
            data_dir: Directory with knowledge base documents
            model: LLM model to use
            memory_token_limit: Max tokens to keep in memory
        """
        self.data_dir = Path(data_dir)
        self.model = model
        self.memory_token_limit = memory_token_limit

        # Configure settings
        Settings.llm = OpenAI(model=model, temperature=0.7)
        Settings.embed_model = OpenAIEmbedding(model="text-embedding-3-small")

        self.index = None
        self.chat_engine = None
        self.conversation_history = []

    def load_knowledge_base(self):
        """Load and index the knowledge base."""
        print(f"Loading knowledge base from {self.data_dir}...")

        if not self.data_dir.exists():
            print(f"Creating sample knowledge base...")
            self._create_sample_kb()

        # Load documents
        documents = SimpleDirectoryReader(str(self.data_dir)).load_data()
        print(f"Loaded {len(documents)} documents")

        # Create index
        self.index = VectorStoreIndex.from_documents(documents)
        print("Knowledge base indexed!")

    def _create_sample_kb(self):
        """Create sample knowledge base about a fictional company."""
        self.data_dir.mkdir(exist_ok=True)

        kb_content = {
            "company_info.txt": """
                Acme Corporation

                Founded: 2020
                Industry: Technology
                Employees: 500+

                Acme Corporation is a leading provider of cloud-based solutions
                for enterprise customers. We specialize in AI-powered analytics
                and data management platforms.

                Our mission is to make data accessible and actionable for
                businesses of all sizes.
            """,
            "products.txt": """
                Products and Services

                1. Acme Analytics Platform
                   - Real-time data analytics
                   - Machine learning insights
                   - Custom dashboards
                   - Price: Starting at $99/month

                2. Acme Data Warehouse
                   - Scalable cloud storage
                   - Automated backups
                   - 99.9% uptime SLA
                   - Price: Starting at $299/month

                3. Acme AI Assistant
                   - Natural language queries
                   - Automated reporting
                   - Integration with major platforms
                   - Price: Starting at $199/month
            """,
            "support.txt": """
                Customer Support

                Support Hours: 24/7
                Response Time: Under 1 hour for critical issues

                Contact Methods:
                - Email: support@acme.example.com
                - Phone: 1-800-ACME-HELP
                - Live Chat: Available on our website
                - Slack Connect: For enterprise customers

                Common Issues:
                - Login problems: Reset password at acme.example.com/reset
                - Integration issues: Check our API documentation
                - Billing questions: Contact billing@acme.example.com
            """,
        }

        for filename, content in kb_content.items():
            file_path = self.data_dir / filename
            file_path.write_text(content.strip())

        print(f"Created sample knowledge base in {self.data_dir}")

    def initialize_chat_engine(self):
        """Initialize the chat engine with memory."""
        if self.index is None:
            self.load_knowledge_base()

        # Create memory buffer
        memory = ChatMemoryBuffer.from_defaults(
            token_limit=self.memory_token_limit
        )

        # Create chat engine
        self.chat_engine = self.index.as_chat_engine(
            chat_mode="condense_plus_context",
            memory=memory,
            system_prompt=(
                "You are a helpful customer service assistant for Acme Corporation. "
                "Use the provided context to answer questions accurately. "
                "If you don't know the answer, say so - don't make up information. "
                "Be friendly, professional, and concise."
            ),
        )

        print("Chat engine initialized with memory!")

    def chat(self, message: str) -> str:
        """
        Send a message and get a response.

        Args:
            message: User message

        Returns:
            Chatbot response
        """
        if self.chat_engine is None:
            self.initialize_chat_engine()

        # Get response
        response = self.chat_engine.chat(message)

        # Track conversation
        self.conversation_history.append(
            {"timestamp": datetime.now(), "user": message, "bot": str(response)}
        )

        return str(response)

    def reset_conversation(self):
        """Reset the conversation memory."""
        if self.chat_engine:
            self.chat_engine.reset()
        self.conversation_history = []
        print("Conversation reset!")

    def get_conversation_summary(self) -> str:
        """Get a summary of the conversation."""
        if not self.conversation_history:
            return "No conversation yet."

        summary = f"Conversation Summary ({len(self.conversation_history)} exchanges):\n\n"

        for i, exchange in enumerate(self.conversation_history, 1):
            summary += f"{i}. User: {exchange['user'][:50]}...\n"
            summary += f"   Bot: {exchange['bot'][:50]}...\n\n"

        return summary

    def interactive_mode(self):
        """Run interactive chat mode."""
        print("\n" + "=" * 60)
        print("Acme Corporation Customer Service Chatbot")
        print("=" * 60)
        print("\nCommands:")
        print("  /help    - Show this help")
        print("  /reset   - Reset conversation")
        print("  /summary - Show conversation summary")
        print("  /exit    - Exit chatbot")
        print("\nType your question to start chatting...")
        print("=" * 60)

        while True:
            try:
                user_input = input("\nYou: ").strip()

                if not user_input:
                    continue

                # Handle commands
                if user_input.startswith("/"):
                    if user_input == "/exit":
                        print("\nThank you for using Acme support! Goodbye!")
                        break
                    elif user_input == "/reset":
                        self.reset_conversation()
                        continue
                    elif user_input == "/summary":
                        print("\n" + self.get_conversation_summary())
                        continue
                    elif user_input == "/help":
                        print("\nAvailable commands:")
                        print("  /help    - Show this help")
                        print("  /reset   - Reset conversation")
                        print("  /summary - Show conversation summary")
                        print("  /exit    - Exit chatbot")
                        continue
                    else:
                        print("Unknown command. Type /help for available commands.")
                        continue

                # Get chatbot response
                response = self.chat(user_input)
                print(f"\nBot: {response}")

            except KeyboardInterrupt:
                print("\n\nGoodbye!")
                break
            except Exception as e:
                print(f"\nError: {e}")
                print("Please try again.")


def demo_conversation_flow():
    """Demonstrate a multi-turn conversation."""
    print("=" * 60)
    print("Demo: Multi-turn Conversation with Memory")
    print("=" * 60)

    chatbot = ConversationalChatbot()
    chatbot.initialize_chat_engine()

    # Simulate a conversation
    conversation = [
        "What products does Acme offer?",
        "How much does the Analytics Platform cost?",
        "What about the AI Assistant?",  # References previous context
        "How can I contact support?",
        "What are your support hours?",
    ]

    for i, message in enumerate(conversation, 1):
        print(f"\n{i}. User: {message}")
        response = chatbot.chat(message)
        print(f"   Bot: {response}")

    # Show conversation summary
    print("\n" + "=" * 60)
    print(chatbot.get_conversation_summary())


def demo_memory_management():
    """Demonstrate memory management features."""
    print("\n" + "=" * 60)
    print("Demo: Memory Management")
    print("=" * 60)

    chatbot = ConversationalChatbot(memory_token_limit=500)
    chatbot.initialize_chat_engine()

    # Send several messages
    messages = [
        "Tell me about Acme Corporation",
        "What products do you offer?",
        "How can I get support?",
    ]

    for msg in messages:
        response = chatbot.chat(msg)
        print(f"\nUser: {msg}")
        print(f"Bot: {response}")

    print(f"\nConversation history: {len(chatbot.conversation_history)} exchanges")

    # Reset and continue
    print("\nResetting conversation...")
    chatbot.reset_conversation()

    response = chatbot.chat("What products do you have?")
    print(f"\nAfter reset - User: What products do you have?")
    print(f"Bot: {response}")


if __name__ == "__main__":
    try:
        # Run demos
        demo_conversation_flow()
        demo_memory_management()

        # Start interactive mode
        print("\n" + "=" * 60)
        print("Starting Interactive Mode")
        print("=" * 60)

        chatbot = ConversationalChatbot()
        chatbot.interactive_mode()

    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
