"""
Complete RunConfig patterns for ADK bidi-streaming.

CRITICAL SECURITY: This template uses PLACEHOLDERS only.
Replace with actual values from environment variables.
"""

from google.adk.agents.run_config import RunConfig, StreamingMode
from google.genai import types


# Pattern 1: Basic Audio Streaming
# Use for: Voice agents, audio-based interactions
basic_audio_config = RunConfig(
    response_modalities=["AUDIO"],  # CRITICAL: Only ONE modality per session
    streaming_mode=StreamingMode.BIDI
)


# Pattern 2: Basic Text Streaming
# Use for: Chat agents, text-based interactions
basic_text_config = RunConfig(
    response_modalities=["TEXT"],  # CRITICAL: Only ONE modality per session
    streaming_mode=StreamingMode.BIDI
)


# Pattern 3: Audio with Session Resumption
# Use for: Long-running voice agents that need reconnection
audio_with_resumption = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,
    session_resumption=types.SessionResumptionConfig()
    # Enables automatic reconnection across ~10-minute timeout
)


# Pattern 4: Unlimited Session with Context Compression
# Use for: Extended conversations, long-running agents
unlimited_session_config = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,
    session_resumption=types.SessionResumptionConfig(),
    context_window_compression=types.ContextWindowCompressionConfig(
        trigger_tokens=100000,  # Start compression at 100K tokens
        sliding_window=types.SlidingWindow(
            target_tokens=80000  # Compress to 80K tokens
        )
    )
)


# Pattern 5: Production-Ready Configuration
# Use for: Production deployments with all features enabled
production_config = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Enable session resumption
    session_resumption=types.SessionResumptionConfig(),

    # Enable context compression for long sessions
    context_window_compression=types.ContextWindowCompressionConfig(
        trigger_tokens=100000,
        sliding_window=types.SlidingWindow(target_tokens=80000)
    ),

    # Save audio/video for debugging and compliance
    save_live_blob=True,

    # Add custom metadata for tracking
    custom_metadata={
        "environment": "production",
        "version": "1.0.0",
        "feature_flags": "streaming_v2"
    },

    # Enable compositional function calling (Gemini 2.x)
    support_cfc=True
)


# Pattern 6: Development/Testing Configuration
# Use for: Local development, testing, debugging
dev_config = RunConfig(
    response_modalities=["TEXT"],  # Easier debugging with text
    streaming_mode=StreamingMode.BIDI,

    # Save blobs for debugging
    save_live_blob=True,

    # Development metadata
    custom_metadata={
        "environment": "development",
        "developer": "your_name_here",
        "debug": "true"
    }
)


# Example Usage:
"""
from google.adk.agents import Agent, LiveRequestQueue

# Initialize agent
agent = Agent(
    name="voice-assistant",
    model="gemini-2.0-flash-multimodal-live",
    system_instruction="You are a helpful voice assistant."
)

# Create request queue
request_queue = LiveRequestQueue()

# Run with chosen configuration
async for event in agent.run_live(
    request_queue,
    run_config=production_config  # Choose appropriate config
):
    if event.server_content:
        handle_response(event)
"""


# IMPORTANT NOTES:
"""
1. Response Modality Rules:
   - Only ONE modality per session (TEXT or AUDIO)
   - Cannot switch modality mid-session
   - Native audio models default to AUDIO modality

2. Session Resumption:
   - Handles ~10-minute connection timeouts automatically
   - Maintains conversation context across reconnections
   - Recommended for production deployments

3. Context Window Compression:
   - Removes session duration limits
   - Prevents token exhaustion in long conversations
   - Configure trigger_tokens based on expected session length

4. Platform Selection:
   - Set via environment variable (no code changes needed)
   - GOOGLE_GENAI_USE_VERTEXAI=FALSE → AI Studio (Gemini Live API)
   - GOOGLE_GENAI_USE_VERTEXAI=TRUE → Vertex AI (Live API)

5. Security:
   - No hardcoded API keys in this template
   - Use environment variables for all credentials
   - Read from os.getenv() in actual code
"""
