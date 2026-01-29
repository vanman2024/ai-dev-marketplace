# conftest.py - DeepEval pytest configuration
import pytest
import os

@pytest.fixture(scope="session")
def openai_api_key():
    return os.getenv("OPENAI_API_KEY")
