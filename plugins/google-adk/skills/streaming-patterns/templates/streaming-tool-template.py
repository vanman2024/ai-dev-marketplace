"""
Streaming tool template for ADK bidi-streaming.

Streaming tools yield intermediate results over time,
enabling real-time monitoring, analysis, and continuous processing.

CRITICAL SECURITY: No hardcoded API keys or credentials.
Use environment variables: os.getenv("YOUR_API_KEY")
"""

import asyncio
import os
from typing import AsyncIterator
from google.adk.agents import streaming_tool


# Pattern 1: Basic Streaming Tool
# Yields multiple results over time
@streaming_tool
async def monitor_stock_price(symbol: str) -> AsyncIterator[str]:
    """
    Stream real-time stock price updates.

    Args:
        symbol: Stock ticker symbol (e.g., "AAPL")

    Yields:
        Price updates as they arrive
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("STOCK_API_KEY", "your_stock_api_key_here")

    while True:
        # Fetch current price (placeholder - replace with actual API)
        price = await fetch_stock_price(symbol, api_key)
        yield f"Current price of {symbol}: ${price:.2f}"

        # Wait before next update
        await asyncio.sleep(1)


# Pattern 2: Streaming Analysis Tool
# Processes data stream and yields insights
@streaming_tool
async def analyze_log_stream(log_file: str) -> AsyncIterator[str]:
    """
    Stream analysis of log file as new entries arrive.

    Args:
        log_file: Path to log file

    Yields:
        Analysis results for each log entry
    """
    with open(log_file, 'r') as f:
        # Follow file like 'tail -f'
        f.seek(0, 2)  # Go to end of file

        while True:
            line = f.readline()
            if not line:
                await asyncio.sleep(0.1)
                continue

            # Analyze log entry
            if "ERROR" in line:
                yield f"⚠️  Error detected: {line.strip()}"
            elif "WARNING" in line:
                yield f"⚡ Warning: {line.strip()}"


# Pattern 3: Streaming Progress Tool
# Reports progress on long-running tasks
@streaming_tool
async def process_large_dataset(
    dataset_path: str,
    batch_size: int = 100
) -> AsyncIterator[str]:
    """
    Process large dataset with progress updates.

    Args:
        dataset_path: Path to dataset
        batch_size: Items per batch

    Yields:
        Progress updates
    """
    # Load dataset (placeholder)
    total_items = 10000  # Replace with actual count
    processed = 0

    while processed < total_items:
        # Process batch
        batch_results = await process_batch(
            dataset_path,
            processed,
            batch_size
        )

        processed += batch_size
        progress = (processed / total_items) * 100

        yield f"Progress: {progress:.1f}% ({processed}/{total_items} items)"

        # Yield batch results
        yield f"Batch results: {batch_results}"


# Pattern 4: Streaming Search Tool
# Searches and yields results as found
@streaming_tool
async def search_documents(query: str) -> AsyncIterator[str]:
    """
    Search documents and stream results as they're found.

    Args:
        query: Search query

    Yields:
        Document matches as they're found
    """
    # SECURITY: Read search API credentials from environment
    api_key = os.getenv("SEARCH_API_KEY", "your_search_api_key_here")

    # Search multiple sources concurrently
    sources = ["database", "file_system", "external_api"]

    for source in sources:
        results = await search_source(source, query, api_key)

        for result in results:
            yield f"Found in {source}: {result['title']}"
            yield f"  Snippet: {result['snippet']}"


# Pattern 5: Streaming Monitoring Tool
# Continuous monitoring with alerts
@streaming_tool
async def monitor_server_health(
    server_url: str,
    interval_seconds: int = 5
) -> AsyncIterator[str]:
    """
    Monitor server health continuously.

    Args:
        server_url: Server URL to monitor
        interval_seconds: Check interval

    Yields:
        Health status updates
    """
    consecutive_failures = 0
    max_failures = 3

    while True:
        try:
            # Check server health
            is_healthy = await check_health(server_url)

            if is_healthy:
                consecutive_failures = 0
                yield f"✅ {server_url} is healthy"
            else:
                consecutive_failures += 1
                yield f"⚠️  {server_url} health check failed ({consecutive_failures}/{max_failures})"

                if consecutive_failures >= max_failures:
                    yield f"🚨 ALERT: {server_url} has failed {max_failures} consecutive checks!"

        except Exception as e:
            yield f"❌ Error checking {server_url}: {str(e)}"

        await asyncio.sleep(interval_seconds)


# Helper Functions (Placeholders)
# Replace with actual implementations

async def fetch_stock_price(symbol: str, api_key: str) -> float:
    """Fetch current stock price (placeholder)."""
    # Replace with actual stock API call
    await asyncio.sleep(0.1)
    return 150.00 + (asyncio.get_event_loop().time() % 10)


async def process_batch(path: str, offset: int, size: int) -> dict:
    """Process batch of data (placeholder)."""
    await asyncio.sleep(0.5)
    return {"processed": size, "errors": 0}


async def search_source(source: str, query: str, api_key: str) -> list:
    """Search a source (placeholder)."""
    await asyncio.sleep(0.2)
    return [
        {"title": f"Result from {source}", "snippet": f"Match for '{query}'"}
    ]


async def check_health(url: str) -> bool:
    """Check server health (placeholder)."""
    await asyncio.sleep(0.1)
    return True


# Example Usage in Agent:
"""
from google.adk.agents import Agent, LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode

# Define agent with streaming tools
agent = Agent(
    name="monitoring-agent",
    model="gemini-2.0-flash-multimodal-live",
    tools=[
        monitor_stock_price,
        monitor_server_health,
        process_large_dataset
    ]
)

# Configure for streaming
run_config = RunConfig(
    response_modalities=["TEXT"],
    streaming_mode=StreamingMode.BIDI
)

# Run agent
request_queue = LiveRequestQueue()
await request_queue.put("Monitor AAPL stock price")

async for event in agent.run_live(request_queue, run_config=run_config):
    if event.tool_call:
        # ADK executes streaming tool automatically
        # Results appear in event stream as they're yielded
        print(f"Tool: {event.tool_call.name}")
        print(f"Result: {event.tool_call.result}")
"""


# BEST PRACTICES:
"""
1. Yield Frequently:
   - Yield intermediate results to keep stream active
   - Don't accumulate too much before yielding
   - User sees progress in real-time

2. Error Handling:
   - Catch exceptions within tool
   - Yield error messages as results
   - Continue streaming when possible

3. Resource Management:
   - Use async/await for I/O operations
   - Clean up resources properly
   - Monitor memory usage in long-running tools

4. User Experience:
   - Provide clear progress indicators
   - Use emojis for visual clarity
   - Format results consistently

5. Security:
   - No hardcoded credentials
   - Read from environment variables
   - Validate all inputs
   - Sanitize outputs
"""
