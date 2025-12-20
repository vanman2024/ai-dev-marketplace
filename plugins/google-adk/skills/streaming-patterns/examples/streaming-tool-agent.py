"""
Agent with streaming tools for ADK bidi-streaming.

Demonstrates:
- Streaming tool definition
- Real-time monitoring tools
- Progress reporting
- Intermediate result streaming
- Tool result event handling

CRITICAL SECURITY: No hardcoded API keys.
Set GOOGLE_API_KEY environment variable before running.
"""

import os
import asyncio
import random
from typing import AsyncIterator
from google.adk.agents import Agent, LiveRequestQueue, streaming_tool
from google.adk.agents.run_config import RunConfig, StreamingMode


# Streaming Tool 1: Stock Price Monitor
@streaming_tool
async def monitor_stock_price(symbol: str, duration_seconds: int = 10) -> AsyncIterator[str]:
    """
    Monitor stock price in real-time.

    Args:
        symbol: Stock ticker symbol (e.g., "AAPL")
        duration_seconds: How long to monitor

    Yields:
        Price updates as they arrive
    """
    start_time = asyncio.get_event_loop().time()
    base_price = 150.00

    while asyncio.get_event_loop().time() - start_time < duration_seconds:
        # Simulate price fluctuation
        price_change = random.uniform(-2.0, 2.0)
        current_price = base_price + price_change

        yield f"📈 {symbol}: ${current_price:.2f}"

        # Update every second
        await asyncio.sleep(1.0)

    yield f"✅ Monitoring complete for {symbol}"


# Streaming Tool 2: Server Health Monitor
@streaming_tool
async def monitor_server_health(
    server_url: str,
    check_interval: int = 5
) -> AsyncIterator[str]:
    """
    Monitor server health continuously.

    Args:
        server_url: Server URL to monitor
        check_interval: Seconds between checks

    Yields:
        Health status updates
    """
    consecutive_failures = 0
    check_count = 0

    while check_count < 5:  # Monitor 5 times
        check_count += 1

        # Simulate health check
        is_healthy = random.random() > 0.2  # 80% success rate

        if is_healthy:
            consecutive_failures = 0
            yield f"✅ {server_url} is healthy (check {check_count})"
        else:
            consecutive_failures += 1
            yield f"⚠️  {server_url} health check failed ({consecutive_failures}/3)"

            if consecutive_failures >= 3:
                yield f"🚨 ALERT: {server_url} has failed 3 consecutive checks!"

        await asyncio.sleep(check_interval)

    yield f"✅ Health monitoring complete for {server_url}"


# Streaming Tool 3: Data Processing Progress
@streaming_tool
async def process_large_dataset(
    dataset_name: str,
    total_items: int = 100
) -> AsyncIterator[str]:
    """
    Process large dataset with progress updates.

    Args:
        dataset_name: Name of dataset
        total_items: Number of items to process

    Yields:
        Progress updates
    """
    batch_size = 10
    processed = 0

    yield f"🔄 Starting processing of {dataset_name}"

    while processed < total_items:
        # Simulate batch processing
        await asyncio.sleep(1.0)

        processed += batch_size
        progress = (processed / total_items) * 100

        yield f"Progress: {progress:.0f}% ({processed}/{total_items} items)"

        # Simulate occasional issues
        if random.random() < 0.1:
            yield f"⚠️  Warning: Slow processing detected at {processed} items"

    yield f"✅ Processing complete! Processed {total_items} items from {dataset_name}"


# Streaming Tool 4: Log Analyzer
@streaming_tool
async def analyze_logs(log_level: str = "ERROR") -> AsyncIterator[str]:
    """
    Analyze log stream for issues.

    Args:
        log_level: Log level to filter (ERROR, WARNING, INFO)

    Yields:
        Analysis results as logs arrive
    """
    log_types = ["ERROR", "WARNING", "INFO"]
    error_count = 0
    warning_count = 0

    yield f"🔍 Analyzing logs for {log_level} level entries"

    for i in range(10):  # Analyze 10 log entries
        # Simulate log entry
        entry_type = random.choice(log_types)
        timestamp = f"2025-01-01T00:00:{i:02d}"

        if entry_type == "ERROR":
            error_count += 1
            yield f"❌ {timestamp} - ERROR: Database connection failed"
        elif entry_type == "WARNING":
            warning_count += 1
            yield f"⚠️  {timestamp} - WARNING: High memory usage detected"
        else:
            yield f"ℹ️  {timestamp} - INFO: Request processed successfully"

        await asyncio.sleep(0.5)

    # Summary
    yield f"\n📊 Analysis Summary:"
    yield f"   Errors: {error_count}"
    yield f"   Warnings: {warning_count}"
    yield f"   Total entries analyzed: 10"


async def main():
    """Run agent with streaming tools."""

    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError(
            "GOOGLE_API_KEY environment variable not set. "
            "Get your key from: https://aistudio.google.com/apikey"
        )

    # Create agent with streaming tools
    agent = Agent(
        name="monitoring-agent",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction=(
            "You are a monitoring and analysis assistant. "
            "Use your streaming tools to provide real-time updates. "
            "Explain what the tools report and highlight important information."
        ),
        tools=[
            monitor_stock_price,
            monitor_server_health,
            process_large_dataset,
            analyze_logs
        ]
    )

    # Configure for streaming
    run_config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    # Create request queue
    request_queue = LiveRequestQueue()

    # Example queries to demonstrate streaming tools
    queries = [
        "Monitor AAPL stock price for 10 seconds",
        # "Check server health for https://api.example.com",
        # "Process the sales dataset with 100 items",
        # "Analyze logs for ERROR level entries"
    ]

    print("🤖 Streaming Tool Agent Started\n")

    for query in queries:
        print(f"📝 Query: {query}\n")

        # Send query
        await request_queue.put(query)

        # Process agent responses
        async for event in agent.run_live(request_queue, run_config=run_config):
            # Tool execution
            if event.tool_call:
                if event.tool_call.name:
                    print(f"🔧 Tool: {event.tool_call.name}")

                # Streaming tool results
                if event.tool_call.result:
                    print(f"   {event.tool_call.result}")

            # Agent responses
            if event.server_content and event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"\n🤖 Agent: {part.text}\n")

            # Turn complete (ready for next query)
            if event.server_content and event.server_content.turn_complete:
                break

        print("\n" + "="*60 + "\n")


async def example_parallel_monitoring():
    """
    Example: Run multiple streaming tools in parallel.

    Demonstrates agent coordinating multiple real-time data sources.
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY not set")

    agent = Agent(
        name="parallel-monitor",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Monitor multiple systems simultaneously.",
        tools=[
            monitor_stock_price,
            monitor_server_health,
            analyze_logs
        ]
    )

    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    queue = LiveRequestQueue()

    # Request parallel monitoring
    await queue.put(
        "Please monitor AAPL stock, check server health for api.example.com, "
        "and analyze ERROR logs - all at the same time."
    )

    async for event in agent.run_live(queue, run_config=config):
        if event.tool_call and event.tool_call.result:
            print(f"[{event.tool_call.name}] {event.tool_call.result}")

        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text:
                    print(f"\n🤖 {part.text}\n")


if __name__ == "__main__":
    asyncio.run(main())

    # Uncomment to run parallel monitoring example
    # asyncio.run(example_parallel_monitoring())


# SETUP INSTRUCTIONS:
"""
1. Install dependencies:
   pip install google-adk

2. Set API key:
   export GOOGLE_API_KEY=your_google_api_key_here

3. Run:
   python streaming-tool-agent.py

4. Platform selection (optional):
   export GOOGLE_GENAI_USE_VERTEXAI=FALSE  # AI Studio (default)
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE   # Vertex AI
"""


# FEATURES DEMONSTRATED:
"""
✅ Streaming tool definition (@streaming_tool decorator)
✅ Real-time progress reporting
✅ Continuous monitoring
✅ Intermediate result streaming
✅ Error detection and alerts
✅ Multiple streaming tools in one agent
✅ Tool result event handling
✅ Agent coordination of streaming data
"""


# STREAMING TOOL BEST PRACTICES:
"""
1. Yield Frequently:
   - Keep user informed with regular updates
   - Don't accumulate too much before yielding
   - Balance frequency vs. noise

2. Progress Reporting:
   - Use percentages for long tasks
   - Provide ETAs when possible
   - Show current state clearly

3. Error Handling:
   - Yield error messages as results
   - Continue streaming when possible
   - Provide actionable error info

4. Resource Management:
   - Use async/await for I/O
   - Clean up resources properly
   - Monitor memory in long-running tools

5. User Experience:
   - Use emojis for visual clarity (✅ ⚠️  ❌ 📈 🔍)
   - Format output consistently
   - Provide summaries at end
"""
