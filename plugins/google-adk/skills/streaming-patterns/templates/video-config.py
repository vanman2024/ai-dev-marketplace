"""
Video configuration templates for ADK bidi-streaming.

Covers video frame processing, image inputs, and multimodal streaming.

CRITICAL SECURITY: No hardcoded credentials.
Use environment variables for all API keys.
"""

from google.adk.agents import LiveRequestQueue
from google.adk.agents.run_config import RunConfig, StreamingMode
from google.genai import types
import base64


# Pattern 1: Video Frame Streaming
# Send video frames to agent for analysis
async def stream_video_frames(
    request_queue: LiveRequestQueue,
    video_source: str
) -> None:
    """
    Stream video frames to agent.

    Args:
        request_queue: LiveRequestQueue for enqueueing frames
        video_source: Path to video file or camera device
    """
    # Open video source (placeholder - use cv2, PIL, etc.)
    for frame in read_video_frames(video_source):
        # Convert frame to bytes (JPEG or PNG)
        frame_bytes = encode_frame_to_jpeg(frame)

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
        await request_queue.put(video_input)

        # Control frame rate (e.g., 1 frame per second)
        await asyncio.sleep(1.0)


# Pattern 2: Image Input Streaming
# Send individual images for analysis
async def stream_image(
    request_queue: LiveRequestQueue,
    image_path: str
) -> None:
    """
    Send image to agent for analysis.

    Args:
        request_queue: LiveRequestQueue
        image_path: Path to image file
    """
    # Read image file
    with open(image_path, 'rb') as f:
        image_bytes = f.read()

    # Determine MIME type
    mime_type = get_image_mime_type(image_path)

    # Create image input
    image_input = types.LiveClientRealtimeInput(
        media_chunks=[
            types.LiveClientRealtimeInputMediaChunk(
                data=image_bytes,
                mime_type=mime_type
            )
        ]
    )

    # Enqueue image
    await request_queue.put(image_input)


# Pattern 3: Multimodal Input (Text + Video)
# Combine text query with video frames
async def stream_text_with_video(
    request_queue: LiveRequestQueue,
    text_query: str,
    video_source: str
) -> None:
    """
    Send text query along with video frames.

    Args:
        request_queue: LiveRequestQueue
        text_query: Text question about video
        video_source: Video source
    """
    # Send text query first
    await request_queue.put(text_query)

    # Then stream video frames
    await stream_video_frames(request_queue, video_source)


# Pattern 4: Camera Stream Processing
# Real-time camera input processing
async def process_camera_stream(
    request_queue: LiveRequestQueue,
    camera_device: int = 0,
    fps: int = 1
) -> None:
    """
    Process live camera stream.

    Args:
        request_queue: LiveRequestQueue
        camera_device: Camera device ID
        fps: Frames per second to send
    """
    import cv2

    # Open camera
    cap = cv2.VideoCapture(camera_device)

    try:
        while True:
            # Capture frame
            ret, frame = cap.read()
            if not ret:
                break

            # Encode frame as JPEG
            _, buffer = cv2.imencode('.jpg', frame)
            frame_bytes = buffer.tobytes()

            # Send to agent
            video_input = types.LiveClientRealtimeInput(
                media_chunks=[
                    types.LiveClientRealtimeInputMediaChunk(
                        data=frame_bytes,
                        mime_type="image/jpeg"
                    )
                ]
            )

            await request_queue.put(video_input)

            # Control frame rate
            await asyncio.sleep(1.0 / fps)

    finally:
        cap.release()


# Pattern 5: Batch Image Processing
# Process multiple images in sequence
async def process_image_batch(
    request_queue: LiveRequestQueue,
    image_paths: list[str],
    context: str
) -> None:
    """
    Process batch of images with context.

    Args:
        request_queue: LiveRequestQueue
        image_paths: List of image file paths
        context: Context/question about images
    """
    # Send context first
    await request_queue.put(context)

    # Send each image
    for image_path in image_paths:
        await stream_image(request_queue, image_path)

        # Optional: Add brief delay between images
        await asyncio.sleep(0.5)


# Complete RunConfig for Video/Image Streaming
video_streaming_config = RunConfig(
    # Use TEXT for video analysis (AUDIO not typically needed)
    response_modalities=["TEXT"],
    streaming_mode=StreamingMode.BIDI,

    # Session management for long video streams
    session_resumption=types.SessionResumptionConfig(),

    # Context compression for long video analysis
    context_window_compression=types.ContextWindowCompressionConfig(
        trigger_tokens=100000,
        sliding_window=types.SlidingWindow(target_tokens=80000)
    ),

    # Save video for debugging/compliance
    save_live_blob=True,

    # Metadata for tracking
    custom_metadata={
        "modality": "video",
        "analysis_type": "real_time"
    }
)


# Helper Functions (Placeholders)

def read_video_frames(source: str):
    """Read frames from video source (placeholder)."""
    # Replace with actual video reading (cv2, etc.)
    import cv2
    cap = cv2.VideoCapture(source)
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        yield frame
    cap.release()


def encode_frame_to_jpeg(frame) -> bytes:
    """Encode video frame to JPEG bytes (placeholder)."""
    import cv2
    _, buffer = cv2.imencode('.jpg', frame)
    return buffer.tobytes()


def get_image_mime_type(path: str) -> str:
    """Get MIME type from image path."""
    ext = path.lower().split('.')[-1]
    mime_types = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'gif': 'image/gif',
        'webp': 'image/webp'
    }
    return mime_types.get(ext, 'image/jpeg')


# Example: Complete Video Analysis Agent
"""
from google.adk.agents import Agent, LiveRequestQueue
import asyncio

# Create video analysis agent
agent = Agent(
    name="video-analyst",
    model="gemini-2.0-flash-multimodal-live",
    system_instruction="You analyze video content in real-time."
)

# Create request queue
request_queue = LiveRequestQueue()

# Run video streaming in background
async def main():
    # Start video streaming task
    video_task = asyncio.create_task(
        stream_video_frames(request_queue, "video.mp4")
    )

    # Process agent responses
    async for event in agent.run_live(
        request_queue,
        run_config=video_streaming_config
    ):
        if event.server_content and event.server_content.model_turn:
            for part in event.server_content.model_turn.parts:
                if part.text:
                    print(f"Analysis: {part.text}")

    await video_task

asyncio.run(main())
"""


# Supported Image Formats:
"""
ADK supports these image formats:

- JPEG (.jpg, .jpeg) - Recommended for photos
- PNG (.png) - Recommended for screenshots
- GIF (.gif) - Animated images supported
- WebP (.webp) - Modern format

MIME types:
- image/jpeg
- image/png
- image/gif
- image/webp
"""


# Video Processing Best Practices:
"""
1. Frame Rate:
   - Don't send all frames (too much data)
   - 1-5 FPS usually sufficient for analysis
   - Adjust based on video content dynamics

2. Image Quality:
   - Balance quality vs. size
   - JPEG quality 80-90 recommended
   - Resize frames if too large (e.g., 1280x720)

3. Context Management:
   - Provide text context with video
   - Ask specific questions about content
   - Use timestamps for video navigation

4. Resource Management:
   - Monitor token usage with video streams
   - Use context compression for long videos
   - Close video sources properly

5. Security:
   - No sensitive content in video streams
   - Comply with privacy regulations
   - Secure video storage if saving blobs
   - Encrypt video data in transit
"""


# CRITICAL NOTES:
"""
1. Token Usage:
   - Images/video consume significant tokens
   - Monitor usage to avoid quota exhaustion
   - Use context compression for long streams

2. Response Modality:
   - VIDEO output not currently supported
   - Use TEXT modality for video analysis
   - Agent provides text analysis of video

3. Platform Differences:
   - AI Studio vs Vertex AI may differ
   - Test on target platform
   - Check model capabilities

4. Security:
   - No API keys in code (use environment)
   - Secure video streams
   - Comply with data privacy laws
"""
