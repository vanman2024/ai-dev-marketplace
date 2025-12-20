"""
Video analysis agent with ADK bidi-streaming.

Demonstrates:
- Video frame streaming
- Real-time video analysis
- Multimodal input (text + video)
- Frame rate control
- Context window compression

CRITICAL SECURITY: No hardcoded API keys.
Set GOOGLE_API_KEY environment variable before running.
"""

import os
import asyncio
import cv2
from google.adk.agents import Agent, LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode
from google.genai import types


async def main():
    """Run video analysis agent with bidi-streaming."""

    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError(
            "GOOGLE_API_KEY environment variable not set. "
            "Get your key from: https://aistudio.google.com/apikey"
        )

    # Create video analysis agent
    agent = Agent(
        name="video-analyst",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction=(
            "You analyze video content in real-time. "
            "Describe what you see, identify objects, actions, and scenes. "
            "Provide concise, accurate observations."
        )
    )

    # Configure for video streaming
    run_config = RunConfig(
        # TEXT output (video analysis descriptions)
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI,

        # Session management for long videos
        session_resumption=types.SessionResumptionConfig(),

        # Context compression (videos use many tokens)
        context_window_compression=types.ContextWindowCompressionConfig(
            trigger_tokens=100000,
            sliding_window=types.SlidingWindow(target_tokens=80000)
        ),

        # Save video for debugging/compliance
        save_live_blob=True,

        # Metadata
        custom_metadata={
            "analysis_type": "video",
            "version": "1.0.0"
        }
    )

    # Create request queue
    request_queue = LiveRequestQueue()

    # Video source (file or camera)
    video_source = "sample_video.mp4"  # Replace with your video path
    # Or use camera: video_source = 0

    # Send initial instruction
    await request_queue.put(
        "Please analyze this video and describe what you see. "
        "Identify objects, actions, and any notable events."
    )

    # Start video streaming task (background)
    video_task = asyncio.create_task(
        stream_video_frames(request_queue, video_source, fps=1)
    )

    print("🎥 Video Analysis Agent Started")
    print(f"Analyzing: {video_source}")
    print("Press Ctrl+C to stop\n")

    try:
        # Process agent responses
        async for event in agent.run_live(request_queue, run_config=run_config):
            # Handle errors
            if event.error:
                print(f"\n❌ Error: {event.error}")

            # Handle server content
            if event.server_content:
                if event.server_content.model_turn:
                    for part in event.server_content.model_turn.parts:
                        if part.text:
                            print(f"🤖 Analysis: {part.text}\n")

    except KeyboardInterrupt:
        print("\n\n👋 Stopping video analysis...")
    finally:
        # Clean up
        video_task.cancel()
        print("✅ Video analysis stopped")


async def stream_video_frames(
    queue: LiveRequestQueue,
    video_source,
    fps: int = 1
):
    """
    Stream video frames to queue.

    Args:
        queue: LiveRequestQueue for enqueueing frames
        video_source: Path to video file or camera device ID
        fps: Frames per second to send (default: 1)
    """
    try:
        print(f"📡 [Streaming video at {fps} FPS]")

        # Open video source
        cap = cv2.VideoCapture(video_source)

        if not cap.isOpened():
            print(f"❌ Failed to open video source: {video_source}")
            return

        frame_count = 0

        while True:
            # Capture frame
            ret, frame = cap.read()

            if not ret:
                print("📡 [End of video reached]")
                break

            frame_count += 1

            # Encode frame as JPEG
            _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
            frame_bytes = buffer.tobytes()

            # Create video input message
            video_input = types.LiveClientRealtimeInput(
                media_chunks=[
                    types.LiveClientRealtimeInputMediaChunk(
                        data=frame_bytes,
                        mime_type="image/jpeg"
                    )
                ]
            )

            # Enqueue frame
            await queue.put(video_input)

            print(f"📸 Frame {frame_count} sent ({len(frame_bytes)} bytes)")

            # Control frame rate
            await asyncio.sleep(1.0 / fps)

    except asyncio.CancelledError:
        print("📡 [Video streaming stopped]")
    finally:
        if 'cap' in locals():
            cap.release()


async def stream_camera_with_query(query: str):
    """
    Example: Stream camera with specific query.

    Args:
        query: Question about camera feed
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY not set")

    agent = Agent(
        name="camera-analyst",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Analyze camera feed and answer questions about it."
    )

    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    queue = LiveRequestQueue()

    # Send query
    await queue.put(query)

    # Stream camera (device 0)
    camera_task = asyncio.create_task(
        stream_video_frames(queue, 0, fps=2)  # 2 FPS for camera
    )

    async for event in agent.run_live(queue, run_config=config):
        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text:
                    print(f"🤖 {part.text}")


async def analyze_specific_moments(video_path: str, timestamps: list[float]):
    """
    Example: Analyze specific moments in a video.

    Args:
        video_path: Path to video file
        timestamps: List of timestamps (seconds) to analyze
    """
    # SECURITY: Read API key from environment
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise ValueError("GOOGLE_API_KEY not set")

    agent = Agent(
        name="moment-analyst",
        model="gemini-2.0-flash-multimodal-live",
        system_instruction="Analyze specific moments in video."
    )

    config = RunConfig(
        response_modalities=["TEXT"],
        streaming_mode=StreamingMode.BIDI
    )

    queue = LiveRequestQueue()

    # Open video
    cap = cv2.VideoCapture(video_path)
    fps_video = cap.get(cv2.CAP_PROP_FPS)

    # Send frames at specific timestamps
    for timestamp in timestamps:
        # Seek to timestamp
        frame_number = int(timestamp * fps_video)
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)

        # Read frame
        ret, frame = cap.read()
        if not ret:
            continue

        # Encode and send
        _, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()

        video_input = types.LiveClientRealtimeInput(
            media_chunks=[
                types.LiveClientRealtimeInputMediaChunk(
                    data=frame_bytes,
                    mime_type="image/jpeg"
                )
            ]
        )

        await queue.put(f"What's happening at {timestamp}s?")
        await queue.put(video_input)

    cap.release()

    # Get analysis
    async for event in agent.run_live(queue, run_config=config):
        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text:
                    print(f"🤖 {part.text}\n")


if __name__ == "__main__":
    asyncio.run(main())


# SETUP INSTRUCTIONS:
"""
1. Install dependencies:
   pip install google-adk opencv-python

2. Set API key:
   export GOOGLE_API_KEY=your_google_api_key_here

3. Prepare video:
   # Use your own video file
   # Or use camera (set video_source = 0)

4. Run:
   python video-agent.py

5. Platform selection (optional):
   export GOOGLE_GENAI_USE_VERTEXAI=FALSE  # AI Studio (default)
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE   # Vertex AI
"""


# FEATURES DEMONSTRATED:
"""
✅ Video file streaming
✅ Camera streaming
✅ Frame rate control (1-5 FPS recommended)
✅ JPEG encoding with quality control
✅ Real-time analysis
✅ Context window compression (for long videos)
✅ Session resumption
✅ Multimodal input (text queries + video)
✅ Specific moment analysis
✅ Production-ready configuration
"""


# BEST PRACTICES:
"""
1. Frame Rate:
   - Don't send all frames (too expensive)
   - 1-5 FPS sufficient for most analysis
   - Adjust based on video content dynamics

2. Image Quality:
   - JPEG quality 80-90 recommended
   - Balance quality vs. token usage
   - Resize large frames (e.g., 1280x720)

3. Token Usage:
   - Video consumes many tokens
   - Enable context compression
   - Monitor usage carefully

4. Error Handling:
   - Check video source opens successfully
   - Handle end-of-video gracefully
   - Implement retry logic for camera
"""
