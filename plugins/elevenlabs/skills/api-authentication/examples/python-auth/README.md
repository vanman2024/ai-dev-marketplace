# Python ElevenLabs Authentication Example

Complete example of ElevenLabs authentication in Python applications including Flask, FastAPI, and standalone scripts.

## Project Structure

```
my-python-app/
├── .env                          # Environment variables (never commit!)
├── requirements.txt              # Python dependencies
├── src/
│   ├── elevenlabs_client.py     # ElevenLabs client
│   ├── main.py                  # Main application
│   └── examples/
│       ├── basic_usage.py       # Basic usage example
│       ├── async_usage.py       # Async usage example
│       └── flask_app.py         # Flask integration
└── tests/
    └── test_connection.py       # Connection tests
```

## Setup Instructions

### 1. Install Dependencies

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install packages
pip install elevenlabs python-dotenv
```

### 2. Configure Environment Variables

Create `.env`:

```env
ELEVENLABS_API_KEY=sk_your_api_key_here
ELEVENLABS_DEFAULT_VOICE_ID=21m00Tcm4TlvDq8ikWAM
ELEVENLABS_DEFAULT_MODEL_ID=eleven_monolingual_v1
```

### 3. Create ElevenLabs Client

Copy the Python template:

```bash
bash scripts/generate-client.sh python src/elevenlabs_client.py
```

Or manually create `src/elevenlabs_client.py` (see templates).

## Usage Examples

### Example 1: Basic Usage

```python
from elevenlabs_client import create_elevenlabs_client, text_to_speech

# Create client
client = create_elevenlabs_client()

# Generate speech
audio = text_to_speech("Hello world!", client=client)

# Save to file
with open("output.mp3", "wb") as f:
    for chunk in audio:
        f.write(chunk)

print("Audio saved to output.mp3")
```

### Example 2: Async Usage

```python
import asyncio
from elevenlabs_client import create_async_elevenlabs_client

async def main():
    # Create async client
    client = create_async_elevenlabs_client()

    # Generate speech
    audio = await client.generate(
        text="Hello world!"
        voice=os.getenv("ELEVENLABS_DEFAULT_VOICE_ID")
        model="eleven_monolingual_v1"
    )

    # Save to file
    with open("output.mp3", "wb") as f:
        async for chunk in audio:
            f.write(chunk)

    print("Audio saved to output.mp3")

if __name__ == "__main__":
    asyncio.run(main())
```

### Example 3: Flask Integration

```python
from flask import Flask, request, send_file, jsonify
from elevenlabs_client import create_elevenlabs_client, text_to_speech
import io

app = Flask(__name__)
client = create_elevenlabs_client()

@app.route("/api/tts", methods=["POST"])
def text_to_speech_endpoint():
    """Text-to-speech API endpoint"""
    data = request.json

    if not data or "text" not in data:
        return jsonify({"error": "Text is required"}), 400

    text = data["text"]
    voice_id = data.get("voice_id")

    try:
        # Generate speech
        audio = text_to_speech(text, voice_id=voice_id, client=client)

        # Create in-memory file
        audio_buffer = io.BytesIO()
        for chunk in audio:
            audio_buffer.write(chunk)
        audio_buffer.seek(0)

        return send_file(
            audio_buffer
            mimetype="audio/mpeg"
            as_attachment=True
            download_name="speech.mp3"
        )

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/voices", methods=["GET"])
def get_voices():
    """Get available voices"""
    try:
        voices = client.voices.get_all()
        return jsonify([
            {"voice_id": v.voice_id, "name": v.name}
            for v in voices.voices
        ])
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=5000)
```

### Example 4: FastAPI Integration

Use the FastAPI template for a complete implementation:

```bash
bash scripts/generate-client.sh python src/api.py
```

Then run:

```bash
pip install fastapi uvicorn
uvicorn src.api:app --reload
```

### Example 5: Command-Line Script

```python
#!/usr/bin/env python3
"""
Command-line text-to-speech tool
Usage: python tts.py "Text to convert" output.mp3
"""

import sys
import os
from elevenlabs_client import create_elevenlabs_client, text_to_speech

def main():
    if len(sys.argv) < 3:
        print("Usage: python tts.py 'text' output.mp3")
        sys.exit(1)

    text = sys.argv[1]
    output_file = sys.argv[2]

    print(f"Converting text to speech...")
    print(f"Text: {text}")
    print(f"Output: {output_file}")

    try:
        client = create_elevenlabs_client()
        audio = text_to_speech(text, client=client)

        with open(output_file, "wb") as f:
            for chunk in audio:
                f.write(chunk)

        print(f"✓ Audio saved to {output_file}")

    except Exception as e:
        print(f"✗ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

## Testing

Create `tests/test_connection.py`:

```python
import pytest
from elevenlabs_client import (
    create_elevenlabs_client
    test_connection
    validate_api_key
)

def test_api_key_validation():
    """Test API key validation"""
    assert validate_api_key("sk_" + "a" * 30) == True
    assert validate_api_key("invalid") == False
    assert validate_api_key("") == False

def test_client_creation():
    """Test client creation"""
    client = create_elevenlabs_client()
    assert client is not None

def test_connection():
    """Test API connection"""
    client = create_elevenlabs_client()
    connected = test_connection(client)
    assert connected == True

@pytest.mark.asyncio
async def test_async_connection():
    """Test async client connection"""
    from elevenlabs_client import (
        create_async_elevenlabs_client
        test_connection as async_test_connection
    )

    client = create_async_elevenlabs_client()
    connected = await async_test_connection(client)
    assert connected == True
```

Run tests:

```bash
pip install pytest pytest-asyncio
pytest tests/
```

## Error Handling

```python
from elevenlabs_client import ElevenLabsError

try:
    audio = text_to_speech("Hello world!")
except ElevenLabsError as e:
    if e.status_code == 401:
        print("Invalid API key")
    elif e.status_code == 429:
        print("Rate limit exceeded")
    else:
        print(f"Error: {e}")
except Exception as e:
    print(f"Unexpected error: {e}")
```

## Batch Processing

```python
import asyncio
from elevenlabs_client import batch_text_to_speech

async def process_multiple_texts():
    texts = [
        "First text to convert"
        "Second text to convert"
        "Third text to convert"
    ]

    # Process all texts concurrently (max 5 at a time)
    audios = await batch_text_to_speech(texts, max_concurrent=5)

    # Save all audio files
    for i, audio in enumerate(audios):
        with open(f"output_{i}.mp3", "wb") as f:
            f.write(audio)

    print(f"Generated {len(audios)} audio files")

if __name__ == "__main__":
    asyncio.run(process_multiple_texts())
```

## Production Deployment

### With Gunicorn (Flask/FastAPI)

```bash
# Install gunicorn
pip install gunicorn

# Run with workers
gunicorn -w 4 -k uvicorn.workers.UvicornWorker src.api:app
```

### With Docker

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

ENV ELEVENLABS_API_KEY=""

CMD ["uvicorn", "src.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:

```bash
docker build -t elevenlabs-api .
docker run -p 8000:8000 -e ELEVENLABS_API_KEY=sk_xxx elevenlabs-api
```

## Security Best Practices

1. **Use environment variables**
   ```python
   # ✓ Good
   api_key = os.getenv("ELEVENLABS_API_KEY")

   # ✗ Bad
   api_key = "sk_hardcoded_key"
   ```

2. **Add input validation**
   ```python
   MAX_TEXT_LENGTH = 5000

   def validate_text(text: str):
       if not text:
           raise ValueError("Text is required")
       if len(text) > MAX_TEXT_LENGTH:
           raise ValueError(f"Text too long (max {MAX_TEXT_LENGTH})")
       return text
   ```

3. **Implement rate limiting**
   ```python
   from flask_limiter import Limiter

   limiter = Limiter(
       app
       key_func=lambda: request.remote_addr
       default_limits=["100 per hour"]
   )
   ```

4. **Add logging**
   ```python
   import logging

   logging.basicConfig(level=logging.INFO)
   logger = logging.getLogger(__name__)

   logger.info("Generating speech for user")
   ```

## References

- [ElevenLabs Python SDK](https://github.com/elevenlabs/elevenlabs-python)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
