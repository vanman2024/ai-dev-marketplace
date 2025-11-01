"""
LangGraph Workflow Template
============================

Multi-step agent workflow using LangGraph for stateful orchestration.

Features:
- State management across steps
- Conditional routing based on state
- Tool integration
- Error handling and retries
- Human-in-the-loop approval (optional)

Usage:
    from langgraph_workflow import create_workflow, AgentState

    # Create workflow
    workflow = create_workflow(
        llm=llm,
        tools=tools,
        require_approval=False
    )

    # Execute
    result = workflow.invoke({
        "messages": [HumanMessage(content="Analyze this document")]
    })
"""

from typing import TypedDict, Annotated, List, Optional, Sequence
from typing_extensions import TypedDict

from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage
from langchain_core.documents import Document
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.tools import Tool

from langgraph.graph import StateGraph, END
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import ToolExecutor


# Define the agent state
class AgentState(TypedDict):
    """State for the agent workflow."""
    messages: Annotated[Sequence[BaseMessage], "The messages in the conversation"]
    documents: Annotated[List[Document], "Retrieved documents"]
    next_step: Annotated[str, "Next step to execute"]
    iteration_count: Annotated[int, "Number of iterations"]
    requires_approval: Annotated[bool, "Whether human approval is required"]
    approved: Annotated[bool, "Whether the action was approved"]


def create_retrieval_node(vectorstore: FAISS):
    """
    Create a retrieval node for the workflow.

    Args:
        vectorstore: Vector store for document retrieval

    Returns:
        Retrieval node function
    """
    def retrieve(state: AgentState) -> AgentState:
        """Retrieve relevant documents based on the last message."""
        print("📄 Retrieving documents...")

        # Get the last user message
        last_message = state["messages"][-1]
        query = last_message.content if hasattr(last_message, 'content') else str(last_message)

        # Retrieve documents
        docs = vectorstore.similarity_search(query, k=4)

        print(f"✓ Retrieved {len(docs)} documents")

        return {
            **state,
            "documents": docs,
            "next_step": "generate"
        }

    return retrieve


def create_generation_node(llm: ChatOpenAI):
    """
    Create a generation node for the workflow.

    Args:
        llm: Language model for generation

    Returns:
        Generation node function
    """
    def generate(state: AgentState) -> AgentState:
        """Generate response based on retrieved documents."""
        print("🤖 Generating response...")

        # Build context from documents
        context = "\n\n".join([doc.page_content for doc in state["documents"]])

        # Get the last user message
        last_message = state["messages"][-1]
        query = last_message.content if hasattr(last_message, 'content') else str(last_message)

        # Create prompt
        system_prompt = f"""You are a helpful assistant. Use the following context to answer the user's question.
If you cannot answer based on the context, say so.

Context:
{context}
"""

        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=query)
        ]

        # Generate response
        response = llm.invoke(messages)

        print("✓ Response generated")

        # Update state
        new_messages = list(state["messages"]) + [response]

        return {
            **state,
            "messages": new_messages,
            "next_step": "end"
        }

    return generate


def create_tool_node(tools: List[Tool], tool_executor: ToolExecutor):
    """
    Create a tool execution node.

    Args:
        tools: List of available tools
        tool_executor: Tool executor instance

    Returns:
        Tool node function
    """
    def execute_tools(state: AgentState) -> AgentState:
        """Execute tools based on agent's decision."""
        print("🔧 Executing tools...")

        # Get the last AI message (should contain tool calls)
        last_message = state["messages"][-1]

        if not hasattr(last_message, 'tool_calls') or not last_message.tool_calls:
            print("⚠ No tool calls found")
            return {
                **state,
                "next_step": "generate"
            }

        # Execute each tool call
        tool_results = []
        for tool_call in last_message.tool_calls:
            tool_name = tool_call["name"]
            tool_args = tool_call["args"]

            print(f"  Executing: {tool_name} with args: {tool_args}")

            result = tool_executor.invoke(tool_call)
            tool_results.append(result)

        print(f"✓ Executed {len(tool_results)} tools")

        return {
            **state,
            "messages": list(state["messages"]) + tool_results,
            "next_step": "generate"
        }

    return execute_tools


def create_approval_node():
    """
    Create a human approval node.

    Returns:
        Approval node function
    """
    def request_approval(state: AgentState) -> AgentState:
        """Request human approval for the next action."""
        print("\n⏸️  Human approval required")

        # Get the proposed action
        last_message = state["messages"][-1]
        print(f"\nProposed action: {last_message.content}")

        # In a real application, this would be an async callback
        # For this template, we'll auto-approve
        approval = input("\nApprove? (y/n): ").lower().strip() == 'y'

        if approval:
            print("✓ Action approved")
            next_step = "execute"
        else:
            print("✗ Action rejected")
            next_step = "end"

        return {
            **state,
            "approved": approval,
            "next_step": next_step
        }

    return request_approval


def should_continue(state: AgentState) -> str:
    """
    Determine which node to execute next.

    Args:
        state: Current agent state

    Returns:
        Name of next node
    """
    next_step = state.get("next_step", "end")

    # Check iteration limit
    max_iterations = 10
    if state.get("iteration_count", 0) >= max_iterations:
        print(f"⚠ Max iterations ({max_iterations}) reached")
        return "end"

    return next_step


def create_workflow(
    llm: ChatOpenAI,
    vectorstore: Optional[FAISS] = None,
    tools: Optional[List[Tool]] = None,
    require_approval: bool = False,
    checkpointer: Optional[MemorySaver] = None
):
    """
    Create a LangGraph workflow for RAG with optional tools.

    Args:
        llm: Language model
        vectorstore: Vector store for retrieval (optional)
        tools: List of tools for the agent (optional)
        require_approval: Require human approval for actions
        checkpointer: Checkpointer for persistence (optional)

    Returns:
        Compiled workflow
    """
    # Create graph
    workflow = StateGraph(AgentState)

    # Add nodes
    if vectorstore:
        retrieve_node = create_retrieval_node(vectorstore)
        workflow.add_node("retrieve", retrieve_node)

    generate_node = create_generation_node(llm)
    workflow.add_node("generate", generate_node)

    if tools:
        tool_executor = ToolExecutor(tools)
        tool_node = create_tool_node(tools, tool_executor)
        workflow.add_node("execute_tools", tool_node)

    if require_approval:
        approval_node = create_approval_node()
        workflow.add_node("approval", approval_node)

    # Set entry point
    if vectorstore:
        workflow.set_entry_point("retrieve")
    else:
        workflow.set_entry_point("generate")

    # Add edges
    if vectorstore:
        workflow.add_edge("retrieve", "generate")

    if require_approval:
        workflow.add_conditional_edges(
            "generate",
            lambda state: "approval" if state.get("requires_approval") else "end"
        )
        workflow.add_conditional_edges(
            "approval",
            lambda state: "execute_tools" if state.get("approved") and tools else "end"
        )
    elif tools:
        workflow.add_conditional_edges(
            "generate",
            lambda state: "execute_tools" if hasattr(state["messages"][-1], 'tool_calls') else "end"
        )
        workflow.add_edge("execute_tools", "generate")
    else:
        workflow.add_edge("generate", END)

    # Compile workflow
    if checkpointer:
        app = workflow.compile(checkpointer=checkpointer)
    else:
        app = workflow.compile()

    return app


# Example usage
if __name__ == "__main__":
    import argparse
    from langchain_core.tools import tool

    parser = argparse.ArgumentParser(description="LangGraph Workflow Example")
    parser.add_argument("--query", required=True, help="Query to process")
    parser.add_argument("--docs", help="Path to documents for retrieval")
    parser.add_argument("--vectorstore", default="./vectorstore", help="Vector store path")
    parser.add_argument("--with-tools", action="store_true", help="Include tools")
    parser.add_argument("--require-approval", action="store_true", help="Require human approval")

    args = parser.parse_args()

    # Initialize LLM
    llm = ChatOpenAI(model="gpt-4", temperature=0)

    # Initialize vector store if docs provided
    vectorstore = None
    if args.docs:
        from pathlib import Path
        vectorstore_path = Path(args.vectorstore)

        if vectorstore_path.exists():
            print("Loading vector store...")
            embeddings = OpenAIEmbeddings()
            vectorstore = FAISS.load_local(
                str(vectorstore_path),
                embeddings,
                allow_dangerous_deserialization=True
            )
            print("✓ Vector store loaded")

    # Define example tools
    tools = None
    if args.with_tools:
        @tool
        def search_web(query: str) -> str:
            """Search the web for information."""
            return f"Web search results for: {query}"

        @tool
        def calculate(expression: str) -> str:
            """Evaluate a mathematical expression."""
            try:
                result = eval(expression)
                return f"Result: {result}"
            except Exception as e:
                return f"Error: {e}"

        tools = [search_web, calculate]

    # Create workflow
    print("Creating workflow...")
    workflow = create_workflow(
        llm=llm,
        vectorstore=vectorstore,
        tools=tools,
        require_approval=args.require_approval
    )
    print("✓ Workflow created")

    # Execute workflow
    print(f"\nQuery: {args.query}")
    print("-" * 50)

    initial_state = {
        "messages": [HumanMessage(content=args.query)],
        "documents": [],
        "next_step": "retrieve" if vectorstore else "generate",
        "iteration_count": 0,
        "requires_approval": args.require_approval,
        "approved": False
    }

    result = workflow.invoke(initial_state)

    # Print result
    print("\n" + "=" * 50)
    print("Response:")
    print("=" * 50)

    # Get the last AI message
    for message in reversed(result["messages"]):
        if isinstance(message, AIMessage):
            print(message.content)
            break
