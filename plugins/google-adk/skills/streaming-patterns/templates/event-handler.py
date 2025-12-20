"""
Event handling patterns for ADK bidi-streaming.

Covers processing events from agent.run_live() including:
- Server content (agent responses)
- Tool calls
- Interruptions
- Turn completion

CRITICAL SECURITY: No hardcoded credentials.
"""

import asyncio
from google.adk.agents import Agent, LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode


# Pattern 1: Basic Event Handler
async def basic_event_handler(agent: Agent, queue: LiveRequestQueue):
    """Basic event processing pattern."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    async for event in agent.run_live(queue, run_config=config):
        # Server content (agent responses)
        if event.server_content:
            print("Received server content")

            # Model turn (agent's response)
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"Agent: {part.text}")

            # Turn complete (agent finished speaking)
            if event.server_content.turn_complete:
                print("Agent finished response")


# Pattern 2: Audio Event Handler
async def audio_event_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle audio streaming events."""
    config = RunConfig(
        response_modalities=["AUDIO"],
        streaming_mode=StreamingMode.BIDI
    )

    async for event in agent.run_live(queue, run_config=config):
        if event.server_content:
            # Process audio output
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    # Audio data
                    if part.inline_data:
                        audio_bytes = part.inline_data.data
                        play_audio(audio_bytes)

                    # Text (if transcription enabled)
                    if part.text:
                        print(f"Transcript: {part.text}")


# Pattern 3: Tool Call Event Handler
async def tool_call_event_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle tool execution events."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    async for event in agent.run_live(queue, run_config=config):
        # Tool call events
        if event.tool_call:
            print(f"Tool: {event.tool_call.name}")
            print(f"Args: {event.tool_call.args}")

            # ADK executes tools automatically
            # Result appears in subsequent events
            if event.tool_call.result:
                print(f"Result: {event.tool_call.result}")

        # Server content (includes tool results)
        if event.server_content:
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"Agent: {part.text}")


# Pattern 4: Interruption Handler
async def interruption_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle user interruptions."""
    config = RunConfig(
        response_modalities=["AUDIO"],
        streaming_mode=StreamingMode.BIDI
    )

    async for event in agent.run_live(queue, run_config=config):
        # Interruption detected
        if event.interrupted:
            print("⚠️  User interrupted agent")
            # Stop playing audio, prepare for new input
            stop_audio_playback()

        # Server content
        if event.server_content:
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.inline_data:
                        # Only play if not interrupted
                        if not event.interrupted:
                            play_audio(part.inline_data.data)


# Pattern 5: Transcription Handler
async def transcription_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle transcription events."""
    from google.genai import types

    config = RunConfig(
        response_modalities=["AUDIO"],
        streaming_mode=StreamingMode.BIDI,
        audio_transcription_config=types.AudioTranscriptionConfig(
            transcribe_input_audio=True,
            transcribe_output_audio=True
        )
    )

    async for event in agent.run_live(queue, run_config=config):
        if event.server_content:
            # Input transcription (user speech)
            if event.server_content.user_input_transcript:
                user_text = event.server_content.user_input_transcript.text
                print(f"User said: {user_text}")
                log_transcript("user", user_text)

            # Output transcription (agent speech)
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"Agent said: {part.text}")
                        log_transcript("agent", part.text)


# Pattern 6: Multi-Agent Handoff Handler
async def multi_agent_handler(
    agent1: Agent,
    agent2: Agent,
    queue: LiveRequestQueue
):
    """Handle multi-agent workflow with handoff."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI,
        session_resumption=types.SessionResumptionConfig()
    )

    # Agent 1 handles initial request
    session = None
    async for event in agent1.run_live(queue, run_config=config):
        if event.server_content:
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"Agent 1: {part.text}")

            # Check if handoff needed
            if should_handoff_to_agent2(event):
                session = event.session  # Capture session
                break

    # Transfer to Agent 2 with session context
    if session:
        print("Transferring to Agent 2...")
        await queue.put("Continuing from Agent 1")

        async for event in agent2.run_live(
            queue,
            run_config=config,
            session=session  # Transfer context
        ):
            if event.server_content:
                if event.server_content.model_turn:
                    for part in event.server_content.model_turn.parts:
                        if part.text:
                            print(f"Agent 2: {part.text}")


# Pattern 7: Streaming Tool Results Handler
async def streaming_tool_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle streaming tool results."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    async for event in agent.run_live(queue, run_config=config):
        # Tool call started
        if event.tool_call and not event.tool_call.result:
            print(f"Tool started: {event.tool_call.name}")

        # Streaming tool yielding results
        if event.tool_call and event.tool_call.result:
            # Each yield from streaming tool appears as separate event
            print(f"Tool update: {event.tool_call.result}")

        # Agent processes tool results
        if event.server_content:
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        print(f"Agent: {part.text}")


# Pattern 8: Error Handler
async def error_handler(agent: Agent, queue: LiveRequestQueue):
    """Handle errors in event stream."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    try:
        async for event in agent.run_live(queue, run_config=config):
            # Check for error signals
            if event.error:
                print(f"❌ Error: {event.error}")
                handle_error(event.error)

            # Normal processing
            if event.server_content:
                if event.server_content.model_turn:
                    for part in event.server_content.model_turn.parts:
                        if part.text:
                            print(f"Agent: {part.text}")

    except Exception as e:
        print(f"❌ Stream error: {e}")
        # Attempt recovery
        await recover_from_error(agent, queue, config)


# Pattern 9: Progress Tracking Handler
async def progress_tracking_handler(agent: Agent, queue: LiveRequestQueue):
    """Track progress through long-running tasks."""
    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    task_progress = {"current": 0, "total": 100}

    async for event in agent.run_live(queue, run_config=config):
        if event.server_content:
            if event.server_content.model_turn:
                for part in event.server_content.model_turn.parts:
                    if part.text:
                        # Parse progress from text
                        if "Progress:" in part.text:
                            update_progress(task_progress, part.text)
                            display_progress_bar(task_progress)

                        print(f"Agent: {part.text}")


# Pattern 10: Complete Production Handler
async def production_event_handler(agent: Agent, queue: LiveRequestQueue):
    """Production-ready event handler with all features."""
    from google.genai import types

    config = RunConfig(
        response_modalities=["AUDIO"],
        streaming_mode=StreamingMode.BIDI,
        session_resumption=types.SessionResumptionConfig(),
        audio_transcription_config=types.AudioTranscriptionConfig(
            transcribe_input_audio=True,
            transcribe_output_audio=True
        ),
        save_live_blob=True,
        custom_metadata={"environment": "production"}
    )

    try:
        async for event in agent.run_live(queue, run_config=config):
            # Error handling
            if event.error:
                log_error(event.error)
                alert_monitoring(event.error)

            # Interruption handling
            if event.interrupted:
                log_event("interruption")
                stop_audio_playback()

            # Tool execution
            if event.tool_call:
                log_tool_call(event.tool_call)
                monitor_tool_performance(event.tool_call)

            # Server content
            if event.server_content:
                # Transcriptions
                if event.server_content.user_input_transcript:
                    log_transcript("user", event.server_content.user_input_transcript.text)

                # Agent response
                if event.server_content.model_turn:
                    for part in event.server_content.model_turn.parts:
                        # Audio
                        if part.inline_data:
                            play_audio(part.inline_data.data)

                        # Text/transcript
                        if part.text:
                            log_transcript("agent", part.text)
                            display_text(part.text)

                # Turn completion
                if event.server_content.turn_complete:
                    log_event("turn_complete")
                    update_ui_state("ready")

    except Exception as e:
        log_exception(e)
        await recover_from_error(agent, queue, config)


# Helper Functions (Placeholders)

def play_audio(audio_bytes: bytes) -> None:
    """Play audio bytes (placeholder)."""
    pass


def stop_audio_playback() -> None:
    """Stop current audio playback (placeholder)."""
    pass


def log_transcript(speaker: str, text: str) -> None:
    """Log transcript (placeholder)."""
    print(f"[TRANSCRIPT] {speaker}: {text}")


def should_handoff_to_agent2(event) -> bool:
    """Determine if handoff needed (placeholder)."""
    return False


def handle_error(error) -> None:
    """Handle error (placeholder)."""
    print(f"Handling error: {error}")


async def recover_from_error(agent, queue, config) -> None:
    """Attempt error recovery (placeholder)."""
    print("Attempting recovery...")


def update_progress(progress_dict: dict, text: str) -> None:
    """Update progress from text (placeholder)."""
    pass


def display_progress_bar(progress_dict: dict) -> None:
    """Display progress bar (placeholder)."""
    pass


def log_error(error) -> None:
    """Log error (placeholder)."""
    print(f"[ERROR] {error}")


def alert_monitoring(error) -> None:
    """Alert monitoring system (placeholder)."""
    pass


def log_event(event_type: str) -> None:
    """Log event (placeholder)."""
    print(f"[EVENT] {event_type}")


def log_tool_call(tool_call) -> None:
    """Log tool call (placeholder)."""
    print(f"[TOOL] {tool_call.name}")


def monitor_tool_performance(tool_call) -> None:
    """Monitor tool performance (placeholder)."""
    pass


def display_text(text: str) -> None:
    """Display text to user (placeholder)."""
    print(f"[DISPLAY] {text}")


def update_ui_state(state: str) -> None:
    """Update UI state (placeholder)."""
    print(f"[UI] State: {state}")


def log_exception(e: Exception) -> None:
    """Log exception (placeholder)."""
    print(f"[EXCEPTION] {e}")


# BEST PRACTICES:
"""
1. Event Processing:
   - Process events as they arrive
   - Don't block event loop
   - Handle all event types

2. Error Handling:
   - Catch exceptions gracefully
   - Log errors for debugging
   - Implement recovery strategies

3. Audio Management:
   - Stop playback on interruption
   - Buffer audio appropriately
   - Handle audio errors

4. Transcription:
   - Log for compliance
   - Use for analytics
   - Display to user

5. Tool Execution:
   - Monitor performance
   - Log all tool calls
   - Handle streaming results

6. Production:
   - Add comprehensive logging
   - Monitor system health
   - Alert on errors
   - Track metrics
"""
