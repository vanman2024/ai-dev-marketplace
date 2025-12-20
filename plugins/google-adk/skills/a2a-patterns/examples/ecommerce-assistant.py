"""
E-Commerce Assistant - Multi-Agent Customer Service System

This example demonstrates a hierarchical multi-agent system for e-commerce
using A2A protocol for service-oriented architecture.

Architecture:
- Customer Agent: Front-facing customer interaction
- Inventory Agent: Product availability and stock management
- Pricing Agent: Price calculations, discounts, promotions
- Payment Agent: Payment processing and transactions
"""

from adk import Agent
from a2a import A2ACardResolver, send_task
import asyncio
import os


# Inventory Agent (deployed as microservice)
inventory_agent = Agent(
    name="inventory-agent",
    instructions="""
    You manage product inventory and availability.

    Capabilities:
    1. Check product stock levels
    2. Reserve items for orders
    3. Track inventory across warehouses
    4. Estimate delivery times based on location
    5. Suggest alternatives for out-of-stock items

    Response format:
    {
        "product_id": "...",
        "in_stock": true/false,
        "quantity_available": number,
        "warehouse_location": "...",
        "estimated_delivery": "...",
        "alternatives": [...]
    }
    """,
    tools=[],  # Add inventory database tools
    model="gemini-2.0-flash-exp"
)


# Pricing Agent (deployed as microservice)
pricing_agent = Agent(
    name="pricing-agent",
    instructions="""
    You calculate prices, discounts, and promotions.

    Capabilities:
    1. Calculate base prices
    2. Apply discounts and promotions
    3. Calculate taxes and shipping
    4. Verify coupon codes
    5. Calculate total order cost

    Response format:
    {
        "base_price": number,
        "discounts": [...],
        "tax": number,
        "shipping": number,
        "total": number,
        "savings": number
    }
    """,
    tools=[],  # Add pricing database tools
    model="gemini-2.0-flash-exp"
)


# Payment Agent (deployed as microservice)
payment_agent = Agent(
    name="payment-agent",
    instructions="""
    You handle payment processing securely.

    Capabilities:
    1. Process credit card payments
    2. Handle digital wallets (PayPal, Apple Pay, etc.)
    3. Verify payment security
    4. Process refunds
    5. Track transaction status

    Response format:
    {
        "transaction_id": "...",
        "status": "success/pending/failed",
        "payment_method": "...",
        "amount": number,
        "confirmation": "..."
    }
    """,
    tools=[],  # Add payment gateway tools
    model="gemini-2.0-flash-exp"
)


async def setup_ecommerce_agents():
    """Set up A2A connections to e-commerce service agents."""

    if os.getenv("USE_REMOTE_AGENTS", "false").lower() == "true":
        resolver = A2ACardResolver()

        inventory_card = await resolver.resolve(
            os.getenv("INVENTORY_AGENT_URL", "https://inventory.example.com")
        )
        pricing_card = await resolver.resolve(
            os.getenv("PRICING_AGENT_URL", "https://pricing.example.com")
        )
        payment_card = await resolver.resolve(
            os.getenv("PAYMENT_AGENT_URL", "https://payment.example.com")
        )

        session_id = f"ecommerce-{os.urandom(8).hex()}"

        return {
            "inventory": send_task(
                agent_url=inventory_card.endpoint,
                session_id=session_id
            ),
            "pricing": send_task(
                agent_url=pricing_card.endpoint,
                session_id=session_id
            ),
            "payment": send_task(
                agent_url=payment_card.endpoint,
                session_id=session_id
            )
        }

    return {}


async def create_customer_agent():
    """Create customer-facing agent with access to backend services."""

    service_tools = await setup_ecommerce_agents()

    customer_agent = Agent(
        name="customer-agent",
        instructions="""
        You are a helpful e-commerce customer service assistant.

        You have access to backend services:
        - Inventory Agent: Check stock and availability
        - Pricing Agent: Calculate prices and discounts
        - Payment Agent: Process payments

        Customer Service Workflow:
        1. Greet customer warmly
        2. Understand their needs
        3. Check inventory for requested items
        4. Calculate pricing with any applicable discounts
        5. Process payment securely
        6. Confirm order and provide tracking info

        Always:
        - Be friendly and professional
        - Explain pricing clearly
        - Confirm important details
        - Provide order summaries
        """,
        tools=list(service_tools.values()) if service_tools else [],
        model="gemini-2.0-flash-exp"
    )

    return customer_agent


async def handle_customer_inquiry(inquiry: str):
    """
    Handle a customer inquiry through the multi-agent system.

    Args:
        inquiry: Customer's question or request

    Returns:
        Agent's response
    """

    agent = await create_customer_agent()
    response = await agent.run(inquiry)
    return response


async def process_order(order_details: dict):
    """
    Process a complete order through multiple agents.

    Args:
        order_details: Dictionary with items, quantities, customer info

    Returns:
        Order confirmation
    """

    service_tools = await setup_ecommerce_agents()

    # Step 1: Check inventory
    if "inventory" in service_tools:
        inventory_check = await service_tools["inventory"](
            f"Check availability for: {order_details['items']}"
        )
        print(f"Inventory: {inventory_check}")

    # Step 2: Calculate pricing
    if "pricing" in service_tools:
        pricing = await service_tools["pricing"](
            f"Calculate total for: {order_details['items']} "
            f"with coupon: {order_details.get('coupon', 'none')}"
        )
        print(f"Pricing: {pricing}")

    # Step 3: Process payment
    if "payment" in service_tools:
        payment = await service_tools["payment"](
            f"Process payment of {order_details.get('total', '0')} "
            f"using {order_details.get('payment_method', 'credit_card')}"
        )
        print(f"Payment: {payment}")

    return {
        "status": "confirmed",
        "order_id": f"ORD-{os.urandom(4).hex()}",
        "inventory": inventory_check if "inventory" in service_tools else {},
        "pricing": pricing if "pricing" in service_tools else {},
        "payment": payment if "payment" in service_tools else {}
    }


async def handle_customer_support(issue: str):
    """
    Handle customer support issues with appropriate routing.

    Args:
        issue: Customer's support request

    Returns:
        Resolution
    """

    service_tools = await setup_ecommerce_agents()

    support_agent = Agent(
        name="support-agent",
        instructions="""
        You handle customer support issues.

        Common issues:
        - Order status inquiries → Check inventory agent
        - Pricing questions → Contact pricing agent
        - Payment issues → Contact payment agent
        - Refunds → Contact payment agent
        - Product availability → Contact inventory agent

        Always:
        1. Acknowledge the issue
        2. Investigate using appropriate service
        3. Provide clear resolution
        4. Follow up if needed
        """,
        tools=list(service_tools.values()) if service_tools else [],
        model="gemini-2.0-flash-exp"
    )

    resolution = await support_agent.run(issue)
    return resolution


if __name__ == "__main__":
    print("E-Commerce Assistant Examples\n")

    # Example 1: Customer inquiry
    print("Example 1: Customer Inquiry")
    result = asyncio.run(
        handle_customer_inquiry(
            "I'm looking for a laptop under $1000 with fast shipping"
        )
    )
    print(f"Response: {result}\n")

    # Example 2: Process order
    print("\nExample 2: Process Order")
    order = {
        "items": [
            {"product": "laptop-123", "quantity": 1},
            {"product": "mouse-456", "quantity": 1}
        ],
        "coupon": "SAVE20",
        "payment_method": "credit_card",
        "total": 899.99
    }
    result = asyncio.run(process_order(order))
    print(f"Order Result: {result}\n")

    # Example 3: Customer support
    print("\nExample 3: Customer Support")
    result = asyncio.run(
        handle_customer_support(
            "I ordered 3 days ago but haven't received shipping confirmation"
        )
    )
    print(f"Support Resolution: {result}")
