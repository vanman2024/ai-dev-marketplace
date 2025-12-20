"""
Multi-agent coordination with session handoff for ADK bidi-streaming.

Demonstrates:
- Session transfer between agents
- Context preservation across agents
- Seamless agent handoff
- Multi-agent workflow coordination

CRITICAL SECURITY: No hardcoded API keys.
Set GOOGLE_API_KEY environment variable before running.
"""

import os
import asyncio
from google.adk.agents import Agent, LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode
from google.genai import types


async def main():
    """
    Demonstrate multi-agent handoff with session transfer.

    Workflow:
    1. Customer service agent handles initial request
    2. Determines technical support needed
    3. Transfers to technical support agent
    4. Technical agent continues with full context
    """

    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError(
            "GOOGLE_API_KEY environment variable not set. "
            "Get your key from: https://aistudio.google.com/apikey"
        )

    # Agent 1: Customer Service
    customer_service_agent = Agent(
        name="customer-service",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction=(
            "You are a friendly customer service representative. "
            "Help customers with general inquiries. "
            "If a customer has a technical issue, acknowledge it and say "
            "'Let me transfer you to our technical support team.' "
            "Don't try to solve technical problems yourself."
        )
    )

    # Agent 2: Technical Support
    technical_support_agent = Agent(
        name="technical-support",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction=(
            "You are a technical support specialist. "
            "Help customers solve technical problems. "
            "You receive context from the previous agent, so don't ask the customer "
            "to repeat information. Start by acknowledging the issue and providing solutions."
        )
    )

    # Configure for session transfer
    run_config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI,

        # Enable session resumption (required for handoff)
        session_resumption=types.SessionResumptionConfig()
    )

    # Create request queue
    request_queue = LiveRequestQueue()

    # Customer initial request
    customer_request = (
        "Hi, I'm having trouble logging into my account. "
        "It keeps saying 'invalid password' even though I'm sure it's correct. "
        "This started happening yesterday after the system update."
    )

    print("🎯 Multi-Agent Handoff Demo\n")
    print("="*60)
    print("SCENARIO: Customer service → Technical support")
    print("="*60 + "\n")

    print(f"👤 Customer: {customer_request}\n")

    # Enqueue customer request
    await request_queue.put(customer_request)

    # PHASE 1: Customer Service Agent
    print("📞 Agent 1: Customer Service\n")

    session = None
    handoff_needed = False

    async for event in customer_service_agent.run_live(
        request_queue,
        run_config=run_config
    ):
        # Agent response
        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text:
                    print(f"🤖 Customer Service: {part.text}\n")

                    # Detect handoff trigger
                    if "technical support" in part.text.lower():
                        handoff_needed = True

        # Capture session for handoff
        if event.session:
            session = event.session

        # Turn complete
        if event.server_content and event.server_content.turn_complete:
            if handoff_needed:
                print("🔄 Transferring to Technical Support...\n")
                break

    # PHASE 2: Technical Support Agent (with session)
    if handoff_needed and session:
        print("="*60)
        print("🛠️  Agent 2: Technical Support\n")

        # Technical agent continues with full context
        # No need to repeat information!
        await request_queue.put(
            "Thank you. Please help me with my login issue."
        )

        async for event in technical_support_agent.run_live(
            request_queue,
            run_config=run_config,
            session=session  # ← Session transfer happens here!
        ):
            # Agent response
            if event.server_content and event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"🤖 Technical Support: {part.text}\n")

            # Turn complete
            if event.server_content and event.server_content.turn_complete:
                break

    print("="*60)
    print("✅ Handoff Complete\n")


async def example_specialist_routing():
    """
    Example: Route to different specialists based on issue type.

    Demonstrates routing logic with multiple potential agents.
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY not set")

    # Routing agent
    router = Agent(
        name="router",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction=(
            "You are a routing agent. Analyze customer issues and determine "
            "which specialist to route to: billing, technical, or account. "
            "Say exactly: 'ROUTE:billing', 'ROUTE:technical', or 'ROUTE:account'"
        )
    )

    # Specialist agents
    billing_agent = Agent(
        name="billing",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="You handle billing and payment issues."
    )

    technical_agent = Agent(
        name="technical",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="You handle technical problems."
    )

    account_agent = Agent(
        name="account",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="You handle account management issues."
    )

    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI,
        session_resumption=types.SessionResumptionConfig()
    )

    queue = LiveRequestQueue()

    # Customer issue
    customer_issue = "My credit card was charged twice this month"
    await queue.put(customer_issue)

    # Phase 1: Router determines specialist
    session = None
    route_to = None

    async for event in router.run_live(queue, run_config=config):
        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text and "ROUTE:" in part.text:
                    route_to = part.text.split("ROUTE:")[1].strip().lower()

        if event.session:
            session = event.session

        if event.server_content and event.server_content.turn_complete:
            break

    # Phase 2: Route to appropriate specialist
    specialists = {
        "billing": billing_agent,
        "technical": technical_agent,
        "account": account_agent
    }

    if route_to and route_to in specialists:
        specialist = specialists[route_to]
        print(f"Routed to: {route_to}")

        await queue.put(f"Please help with: {customer_issue}")

        async for event in specialist.run_live(
            queue,
            run_config=config,
            session=session
        ):
            if event.server_content and event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"{route_to.title()}: {part.text}")


async def example_escalation_chain():
    """
    Example: Multi-level escalation chain.

    Demonstrates cascading handoffs through multiple agents.
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY not set")

    # Define escalation chain
    tier1 = Agent(
        name="tier1",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Basic support. Escalate complex issues."
    )

    tier2 = Agent(
        name="tier2",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Advanced support. Escalate critical issues."
    )

    tier3 = Agent(
        name="tier3",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Expert support. Handle all issues."
    )

    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI,
        session_resumption=types.SessionResumptionConfig()
    )

    queue = LiveRequestQueue()

    # Complex issue requiring escalation
    await queue.put("Critical system outage affecting all users!")

    escalation_chain = [tier1, tier2, tier3]
    session = None

    for i, agent in enumerate(escalation_chain, 1):
        print(f"\nTier {i} Agent:")

        async for event in agent.run_live(
            queue,
            run_config=config,
            session=session
        ):
            if event.session:
                session = event.session

            if event.server_content and event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"  {part.text}")

                        # Check for escalation
                        if i < len(escalation_chain) and "escalate" in part.text.lower():
                            print(f"  → Escalating to Tier {i+1}")
                            break

            if event.server_content and event.server_content.turn_complete:
                break


if __name__ == "__main__":
    asyncio.run(main())

    # Uncomment to run other examples
    # asyncio.run(example_specialist_routing())
    # asyncio.run(example_escalation_chain())


# SETUP INSTRUCTIONS:
"""
1. Install dependencies:
   pip install google-adk

2. Set API key:
   export GOOGLE_API_KEY=your_google_api_key_here

3. Run:
   python multi-agent-handoff.py

4. Platform selection (optional):
   export GOOGLE_GENAI_USE_VERTEXAI=FALSE  # AI Studio (default)
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE   # Vertex AI
"""


# FEATURES DEMONSTRATED:
"""
✅ Session transfer between agents
✅ Context preservation (no information repetition)
✅ Seamless agent handoff
✅ Multi-agent workflow coordination
✅ Routing logic based on issue type
✅ Escalation chains
✅ Session resumption configuration
✅ Stateful conversation handoff
"""


# MULTI-AGENT BEST PRACTICES:
"""
1. Session Management:
   - Enable session_resumption in RunConfig
   - Capture session from events
   - Pass session to next agent via run_live()

2. Context Preservation:
   - Session includes full conversation history
   - Next agent knows everything previous agent knew
   - Customer doesn't repeat information

3. Handoff Triggers:
   - Define clear handoff conditions
   - Agent explicitly signals handoff
   - Use keywords or structured responses

4. Specialist Routing:
   - Use routing agent for complex workflows
   - Route based on issue classification
   - Support multiple specialist types

5. Escalation:
   - Support multi-level escalation
   - Preserve context through chain
   - Each tier adds expertise

6. Error Handling:
   - Validate session before transfer
   - Handle failed handoffs gracefully
   - Provide fallback paths
"""
