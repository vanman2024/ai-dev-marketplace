"""
LiveRequestQueue patterns for ADK bidi-streaming.

Covers queue management, multimodal input enqueueing, and activity markers.

CRITICAL SECURITY: No hardcoded credentials.
"""

import asyncio
from google.adk.agents import LiveRequestQueue
from google.genai import types


# Pattern 1: Basic Text Queue
async def basic_text_queue_example():
    """Simple text message enqueueing."""
    queue = LiveRequestQueue()

    # Enqueue text messages
    await queue.put("Hello, agent!")
    await queue.put("What's the weather in San Francisco?")
    await queue.put("Thank you!")


# Pattern 2: Audio Stream Queue
async def audio_stream_queue_example():
    """Stream audio chunks to queue."""
    queue = LiveRequestQueue()

    # Send initial text context
    await queue.put("Please transcribe the following audio:")

    # Stream audio chunks as they arrive
    async for audio_chunk in microphone_stream():
        audio_input = types.LiveClientRealtimeInput(
            media_chunks=[
                types.LiveClientRealtimeInputMediaChunk(
                    data=audio_chunk,
                    mime_type="audio/pcm"
                )
            ]
        )
        await queue.put(audio_input)


# Pattern 3: Video Frame Queue
async def video_frame_queue_example():
    """Stream video frames to queue."""
    queue = LiveRequestQueue()

    # Send query about video
    await queue.put("What objects do you see in this video?")

    # Stream video frames
    for frame in video_frames():
        frame_bytes = encode_frame(frame)

        video_input = types.LiveClientRealtimeInput(
            media_chunks=[
                types.LiveClientRealtimeInputMediaChunk(
                    data=frame_bytes,
                    mime_type="image/jpeg"
                )
            ]
        )
        await queue.put(video_input)
        await asyncio.sleep(1.0)  # 1 FPS


# Pattern 4: Multimodal Queue
async def multimodal_queue_example():
    """Mix text, audio, and images in queue."""
    queue = LiveRequestQueue()

    # Start with text
    await queue.put("Here's a problem I need help with:")

    # Add image context
    image_bytes = read_image("screenshot.png")
    await queue.put(
        types.LiveClientRealtimeInput(
            media_chunks=[
                types.LiveClientRealtimeInputMediaChunk(
                    data=image_bytes,
                    mime_type="image/png"
                )
            ]
        )
    )

    # Add text explanation
    await queue.put("Can you explain what's happening in this image?")

    # Add audio clarification
    audio_bytes = record_audio()
    await queue.put(
        types.LiveClientRealtimeInput(
            media_chunks=[
                types.LiveClientRealtimeInputMediaChunk(
                    data=audio_bytes,
                    mime_type="audio/pcm"
                )
            ]
        )
    )


# Pattern 5: Activity Boundaries
async def activity_boundaries_example():
    """Use activity markers to segment conversation."""
    queue = LiveRequestQueue()

    # Activity 1: Weather query
    await queue.put("What's the weather?")
    # Activity end implied by next activity start

    # Activity 2: Stock query
    await queue.put("Check AAPL stock price")
    # Activity end implied

    # Activity 3: Complex task with explicit boundaries
    await queue.put("Start task: Analyze this data")
    # ... send data ...
    await queue.put("End task")


# Pattern 6: Interruption Pattern
async def interruption_pattern_example():
    """Handle user interruptions mid-response."""
    queue = LiveRequestQueue()

    # Initial query
    await queue.put("Tell me a long story about AI")

    # Wait for agent to start responding
    await asyncio.sleep(2)

    # User interrupts
    await queue.put("Actually, stop. Tell me about cats instead")
    # Agent should handle interruption and switch topics


# Pattern 7: Continuous Monitoring
async def continuous_monitoring_example():
    """Queue pattern for continuous data streams."""
    queue = LiveRequestQueue()

    # Initial instruction
    await queue.put("Monitor this data stream for anomalies")

    # Continuously feed data
    while monitoring_active():
        data_point = await get_next_data_point()
        await queue.put(f"Data: {data_point}")
        await asyncio.sleep(0.1)


# Pattern 8: Batch Processing
async def batch_processing_example():
    """Process multiple items in batches."""
    queue = LiveRequestQueue()

    items = ["item1", "item2", "item3", "item4", "item5"]
    batch_size = 2

    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]

        # Send batch context
        await queue.put(f"Processing batch {i // batch_size + 1}")

        # Send batch items
        for item in batch:
            await queue.put(f"Process: {item}")

        # Mark batch complete
        await queue.put(f"Batch {i // batch_size + 1} complete")


# Pattern 9: Error Recovery Queue
async def error_recovery_example():
    """Handle errors gracefully in queue."""
    queue = LiveRequestQueue()

    try:
        # Attempt operation
        await queue.put("Perform risky operation")

        # If error occurs during streaming...
        # Enqueue error context
        await queue.put("Error occurred. Please suggest solution.")

    except Exception as e:
        # Queue error message
        await queue.put(f"Error: {str(e)}")
        await queue.put("How should I handle this?")


# Pattern 10: Session Transfer Queue
async def session_transfer_example():
    """Transfer queue between agents."""
    # Agent 1 queue
    queue1 = LiveRequestQueue()
    await queue1.put("I need help with technical support")

    # ... Agent 1 processes, determines handoff needed ...

    # Create queue for Agent 2 (inherits context via session)
    queue2 = LiveRequestQueue()
    await queue2.put("Continuing from previous agent")

    # Session context maintained automatically by ADK


# Helper Functions (Placeholders)

async def microphone_stream():
    """Stream audio from microphone (placeholder)."""
    while True:
        # Capture audio chunk
        chunk = b"\x00" * 1024  # Placeholder
        yield chunk
        await asyncio.sleep(0.1)


def video_frames():
    """Generate video frames (placeholder)."""
    for i in range(10):
        # Generate dummy frame
        yield f"frame_{i}".encode()


def encode_frame(frame) -> bytes:
    """Encode frame to bytes (placeholder)."""
    return frame if isinstance(frame, bytes) else str(frame).encode()


def read_image(path: str) -> bytes:
    """Read image file (placeholder)."""
    with open(path, 'rb') as f:
        return f.read()


def record_audio() -> bytes:
    """Record audio (placeholder)."""
    return b"\x00" * 16000  # 1 second at 16kHz


def monitoring_active() -> bool:
    """Check if monitoring is active (placeholder)."""
    return False  # Stop after first iteration


async def get_next_data_point():
    """Get next data point (placeholder)."""
    await asyncio.sleep(0.1)
    return {"value": 42, "timestamp": "2025-01-01T00:00:00"}


# Complete Example: Multi-Source Queue
"""
from google.adk.agents import Agent, LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode

async def main():
    # Create agent
    agent = Agent(
        name="multimodal-assistant",
        model="gemini-2.0-flash-multimodal-live"
    )

    # Create queue
    queue = LiveRequestQueue()

    # Configure streaming
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    # Start background tasks for different input sources
    tasks = [
        asyncio.create_task(feed_text_inputs(queue)),
        asyncio.create_task(feed_audio_inputs(queue)),
        asyncio.create_task(feed_video_inputs(queue))
    ]

    # Process agent responses
    async for event in agent.run_live(queue, run_config=config):
        if event.server_content:
            handle_response(event)

    # Clean up
    for task in tasks:
        task.cancel()

asyncio.run(main())
"""


# BEST PRACTICES:
"""
1. Queue Management:
   - Enqueue items as they arrive (don't batch unnecessarily)
   - Use appropriate MIME types for media
   - Handle queue errors gracefully

2. Activity Segmentation:
   - Use clear markers for logical boundaries
   - Help agent understand task transitions
   - Improve context management

3. Multimodal Inputs:
   - Provide text context for media
   - Mix modalities naturally
   - Consider token usage

4. Interruptions:
   - Support natural conversation flow
   - Queue interruptions promptly
   - Agent handles interruption automatically

5. Error Handling:
   - Catch queue errors
   - Provide error context to agent
   - Implement retry logic where appropriate

6. Security:
   - Validate all inputs before enqueueing
   - Sanitize user data
   - No sensitive data in queue without encryption
"""
