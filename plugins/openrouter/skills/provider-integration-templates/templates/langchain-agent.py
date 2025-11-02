# langchain-agent.py
# Agent template with tools using OpenRouter

from langchain.agents import AgentExecutor, create_openai_functions_agent
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
import os
from dotenv import load_dotenv

load_dotenv()


# Define tools
@tool
def calculate(operation: str) -> str:
    """
    Perform basic calculations. Use this when you need to do math.

    Args:
        operation: A mathematical expression like "2 + 2" or "10 * 5"

    Returns:
        The result of the calculation as a string
    """
    try:
        # Safety: Only allow basic operations
        allowed_chars = set("0123456789+-*/() .")
        if not all(c in allowed_chars for c in operation):
            return "Error: Invalid characters in operation"

        result = eval(operation)
        return f"The result is: {result}"
    except Exception as e:
        return f"Error calculating: {str(e)}"


@tool
def search_knowledge(query: str) -> str:
    """
    Search a knowledge base. Use this to look up factual information.

    Args:
        query: The search query

    Returns:
        Relevant information from the knowledge base
    """
    # This is a mock implementation
    # In production, replace with actual vector store or API search
    knowledge_base = {
        "python": "Python is a high-level programming language known for readability.",
        "langchain": "LangChain is a framework for building LLM applications.",
        "openrouter": "OpenRouter provides unified access to multiple LLM providers.",
    }

    # Simple keyword matching
    query_lower = query.lower()
    for key, value in knowledge_base.items():
        if key in query_lower:
            return value

    return "No relevant information found in knowledge base."


def create_agent():
    """
    Create an agent with tools using OpenRouter

    The agent can:
    - Perform calculations
    - Search a knowledge base
    - Reason about which tools to use

    Returns:
        AgentExecutor that can be invoked with {"input": "user message"}
    """
    # Configure OpenRouter LLM
    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0,
        default_headers={
            "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL", "http://localhost"),
            "X-Title": os.getenv("OPENROUTER_SITE_NAME", "LangChain Agent"),
        },
    )

    # Define tools
    tools = [calculate, search_knowledge]

    # Create prompt template
    prompt = ChatPromptTemplate.from_messages([
        ("system", """You are a helpful AI assistant with access to tools.
Use the tools when needed to answer questions accurately.
Always explain your reasoning."""),
        ("human", "{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ])

    # Create agent
    agent = create_openai_functions_agent(llm, tools, prompt)

    # Create agent executor
    agent_executor = AgentExecutor(
        agent=agent,
        tools=tools,
        verbose=True,
        handle_parsing_errors=True,
        max_iterations=5,
    )

    return agent_executor


def create_agent_with_memory():
    """
    Create an agent with conversation memory

    This agent remembers previous interactions in the conversation.

    Returns:
        AgentExecutor with memory
    """
    from langchain.memory import ConversationBufferMemory

    llm = ChatOpenAI(
        model=os.getenv("OPENROUTER_MODEL", "anthropic/claude-4.5-sonnet"),
        openai_api_key=os.getenv("OPENROUTER_API_KEY"),
        openai_api_base="https://openrouter.ai/api/v1",
        temperature=0,
    )

    tools = [calculate, search_knowledge]

    # Create memory
    memory = ConversationBufferMemory(
        memory_key="chat_history",
        return_messages=True,
    )

    # Prompt with memory
    prompt = ChatPromptTemplate.from_messages([
        ("system", "You are a helpful AI assistant with access to tools."),
        MessagesPlaceholder(variable_name="chat_history"),
        ("human", "{input}"),
        MessagesPlaceholder(variable_name="agent_scratchpad"),
    ])

    agent = create_openai_functions_agent(llm, tools, prompt)

    agent_executor = AgentExecutor(
        agent=agent,
        tools=tools,
        memory=memory,
        verbose=True,
    )

    return agent_executor


# Example usage
if __name__ == "__main__":
    print("=== Agent with Tools ===\n")

    agent = create_agent()

    # Test calculation tool
    print("Question: What is 15 multiplied by 7?")
    response = agent.invoke({"input": "What is 15 multiplied by 7?"})
    print(f"Answer: {response['output']}\n")

    # Test knowledge base tool
    print("Question: What is LangChain?")
    response = agent.invoke({"input": "What is LangChain?"})
    print(f"Answer: {response['output']}\n")

    # Test reasoning without tools
    print("Question: Why is the sky blue?")
    response = agent.invoke({"input": "Why is the sky blue?"})
    print(f"Answer: {response['output']}\n")

    # Test agent with memory
    print("=== Agent with Memory ===\n")
    agent_with_memory = create_agent_with_memory()

    print("First question: What is 10 + 5?")
    response = agent_with_memory.invoke({"input": "What is 10 + 5?"})
    print(f"Answer: {response['output']}\n")

    print("Second question: What was the previous calculation?")
    response = agent_with_memory.invoke({"input": "What was the previous calculation?"})
    print(f"Answer: {response['output']}\n")
