"""
Audio configuration templates for ADK bidi-streaming.

Covers speech configuration, audio transcription, and voice settings.

CRITICAL SECURITY: No hardcoded API keys.
Use environment variables for all credentials.
"""

from google.adk.agents.run_config import RunConfig, StreamingMode
from google.genai import types


# Pattern 1: Basic Audio Configuration
# Default audio settings for voice agents
basic_audio = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Speech configuration (voice characteristics)
    speech_config=types.SpeechConfig(
        # Voice selection (varies by model)
        # Options: "Puck", "Charon", "Kore", "Fenrir", "Aoede"
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                voice_name="Puck"  # Default voice
            )
        )
    )
)


# Pattern 2: Audio with Input Transcription
# Transcribe user audio input to text
audio_with_input_transcription = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Enable input audio transcription
    audio_transcription_config=types.AudioTranscriptionConfig(
        # Transcribe user's audio input
        transcribe_input_audio=True
    )
)


# Pattern 3: Audio with Output Transcription
# Transcribe agent audio output to text
audio_with_output_transcription = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Enable output audio transcription
    audio_transcription_config=types.AudioTranscriptionConfig(
        # Transcribe agent's audio responses
        transcribe_output_audio=True
    )
)


# Pattern 4: Full Audio Transcription
# Transcribe both input and output audio
full_transcription = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Transcribe both directions
    audio_transcription_config=types.AudioTranscriptionConfig(
        transcribe_input_audio=True,
        transcribe_output_audio=True
    ),

    # Voice configuration
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                voice_name="Aoede"  # Female voice
            )
        )
    )
)


# Pattern 5: Production Audio Configuration
# Complete audio setup for production voice agents
production_audio = RunConfig(
    response_modalities=["AUDIO"],
    streaming_mode=StreamingMode.BIDI,

    # Session management
    session_resumption=types.SessionResumptionConfig(),
    context_window_compression=types.ContextWindowCompressionConfig(
        trigger_tokens=100000,
        sliding_window=types.SlidingWindow(target_tokens=80000)
    ),

    # Audio configuration
    speech_config=types.SpeechConfig(
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                voice_name="Puck"  # Male voice
            )
        )
    ),

    # Full transcription
    audio_transcription_config=types.AudioTranscriptionConfig(
        transcribe_input_audio=True,
        transcribe_output_audio=True
    ),

    # Save audio for quality assurance
    save_live_blob=True,

    # Production metadata
    custom_metadata={
        "environment": "production",
        "audio_quality": "high",
        "transcription_enabled": "true"
    }
)


# Available Voice Options:
"""
Prebuilt voices (model-dependent):

- "Puck": Default male voice
- "Charon": Alternative male voice
- "Kore": Female voice
- "Fenrir": Male voice
- "Aoede": Female voice

Note: Available voices may vary by model and platform.
Check documentation for current voice options.
"""


# Audio Input Formats:
"""
Supported audio input formats:

- PCM16 (16-bit linear PCM)
- Sample rate: 16000 Hz (recommended)
- Channels: Mono (1 channel)
- Encoding: Linear PCM

Example audio chunk structure:

from google.genai import types

audio_input = types.LiveClientRealtimeInput(
    media_chunks=[
        types.LiveClientRealtimeInputMediaChunk(
            data=audio_bytes,  # PCM16 audio data
            mime_type="audio/pcm"
        )
    ]
)
"""


# Transcription Event Handling:
"""
When transcription is enabled, events include text transcripts:

async for event in agent.run_live(request_queue, run_config=config):
    # Input transcription (user speech)
    if event.server_content and event.server_content.user_input_transcript:
        user_text = event.server_content.user_input_transcript.text
        print(f"User said: {user_text}")

    # Output transcription (agent speech)
    if event.server_content and event.server_content.model_turn:
        for part in event.server_content.model_turn.parts:
            if part.text:
                print(f"Agent said: {part.text}")
"""


# Example: Complete Audio Agent
"""
from google.adk.agents import Agent, LiveRequestQueue

# Create voice agent
agent = Agent(
    name="voice-assistant",
    model="gemini-2.0-flash-multimodal-live",  # Native audio model
    system_instruction="You are a helpful voice assistant. Speak naturally."
)

# Configure audio streaming
config = production_audio

# Create request queue
request_queue = LiveRequestQueue()

# Handle audio input
async def handle_audio_stream():
    # Enqueue audio chunks as they arrive
    async for audio_chunk in microphone_stream():
        await request_queue.put(
            types.LiveClientRealtimeInput(
                media_chunks=[
                    types.LiveClientRealtimeInputMediaChunk(
                        data=audio_chunk,
                        mime_type="audio/pcm"
                    )
                ]
            )
        )

# Run agent
async for event in agent.run_live(request_queue, run_config=config):
    if event.server_content:
        # Handle audio response
        if event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.inline_data:
                    # Audio output
                    play_audio(part.inline_data.data)
                if part.text:
                    # Transcription
                    print(f"Agent: {part.text}")
"""


# BEST PRACTICES:
"""
1. Voice Selection:
   - Test different voices for your use case
   - Consider audience and brand identity
   - Match voice personality to agent role

2. Transcription:
   - Enable for debugging and compliance
   - Log transcripts for quality monitoring
   - Use for analytics and improvement

3. Audio Quality:
   - Use recommended sample rate (16000 Hz)
   - Ensure clean audio input (noise reduction)
   - Test with various audio sources

4. Error Handling:
   - Handle audio processing errors gracefully
   - Provide fallback to text when audio fails
   - Log audio-related issues for debugging

5. Security:
   - No API keys in code
   - Secure audio storage if saving blobs
   - Comply with privacy regulations for recordings
   - Encrypt audio data in transit and at rest
"""
