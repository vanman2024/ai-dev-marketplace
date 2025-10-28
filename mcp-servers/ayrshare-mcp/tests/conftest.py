"""Pytest configuration and shared fixtures."""
import os
import sys
import pytest
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

@pytest.fixture
def api_key():
    """Get API key from environment."""
    from dotenv import load_dotenv
    load_dotenv()
    return os.getenv("AYRSHARE_API_KEY")
