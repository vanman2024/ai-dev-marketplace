"""Pytest configuration and shared fixtures for Ayrshare MCP tests."""
import os
import pytest
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from project root
project_root = Path(__file__).parent.parent
env_path = project_root / ".env"
load_dotenv(env_path)

@pytest.fixture
def api_key():
    """Provide API key from environment."""
    return os.getenv("AYRSHARE_API_KEY")

@pytest.fixture
def mock_post_response():
    """Mock successful post response."""
    return {
        "status": "success",
        "id": "post_12345",
        "postIds": [
            {"platform": "facebook", "id": "fb_12345", "status": "success"},
            {"platform": "twitter", "id": "tw_12345", "status": "success"}
        ],
        "refId": "ref_12345",
        "errors": [],
        "warnings": []
    }
