"""
Mem0 Client Configuration Examples
Different configurations for hosted and self-hosted setups
"""

from mem0 import Memory, AsyncMemory, MemoryClient
from mem0.configs.base import MemoryConfig
from pydantic_settings import BaseSettings
from typing import Optional
import os


class MemorySettings(BaseSettings):
    """Settings for Mem0 memory client"""

    # Hosted Mem0 Platform
    MEM0_API_KEY: Optional[str] = None
    MEM0_HOST: Optional[str] = None

    # Self-Hosted Configuration
    QDRANT_HOST: str = "localhost"
    QDRANT_PORT: int = 6333
    QDRANT_API_KEY: Optional[str] = None

    # LLM Configuration
    OPENAI_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None

    # Default LLM Provider
    LLM_PROVIDER: str = "openai"
    LLM_MODEL: str = "gpt-4"

    # Embeddings Configuration
    EMBEDDER_PROVIDER: str = "openai"
    EMBEDDER_MODEL: str = "text-embedding-3-small"

    class Config:
        env_file = ".env"
        case_sensitive = True


# Example 1: Hosted Mem0 Platform
def create_hosted_client(api_key: str) -> MemoryClient:
    """
    Create a hosted Mem0 client.

    Args:
        api_key: Mem0 API key

    Returns:
        MemoryClient instance
    """
    return MemoryClient(api_key=api_key)


# Example 2: Self-Hosted with Qdrant
def create_self_hosted_qdrant(settings: MemorySettings) -> AsyncMemory:
    """
    Create self-hosted Mem0 client with Qdrant vector database.

    Args:
        settings: Memory configuration settings

    Returns:
        AsyncMemory instance
    """
    config = MemoryConfig(
        vector_store={
            "provider": "qdrant",
            "config": {
                "host": settings.QDRANT_HOST,
                "port": settings.QDRANT_PORT,
                "api_key": settings.QDRANT_API_KEY,
            },
        },
        llm={
            "provider": settings.LLM_PROVIDER,
            "config": {
                "model": settings.LLM_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
        embedder={
            "provider": settings.EMBEDDER_PROVIDER,
            "config": {
                "model": settings.EMBEDDER_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
    )
    return AsyncMemory(config)


# Example 3: Self-Hosted with Pinecone
def create_self_hosted_pinecone(
    settings: MemorySettings, pinecone_api_key: str, pinecone_environment: str
) -> AsyncMemory:
    """
    Create self-hosted Mem0 client with Pinecone vector database.

    Args:
        settings: Memory configuration settings
        pinecone_api_key: Pinecone API key
        pinecone_environment: Pinecone environment

    Returns:
        AsyncMemory instance
    """
    config = MemoryConfig(
        vector_store={
            "provider": "pinecone",
            "config": {
                "api_key": pinecone_api_key,
                "environment": pinecone_environment,
            },
        },
        llm={
            "provider": settings.LLM_PROVIDER,
            "config": {
                "model": settings.LLM_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
        embedder={
            "provider": settings.EMBEDDER_PROVIDER,
            "config": {
                "model": settings.EMBEDDER_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
    )
    return AsyncMemory(config)


# Example 4: Self-Hosted with Chroma (Local)
def create_self_hosted_chroma(settings: MemorySettings) -> AsyncMemory:
    """
    Create self-hosted Mem0 client with Chroma vector database.

    Args:
        settings: Memory configuration settings

    Returns:
        AsyncMemory instance
    """
    config = MemoryConfig(
        vector_store={
            "provider": "chroma",
            "config": {
                "host": "localhost",
                "port": 8000,
            },
        },
        llm={
            "provider": settings.LLM_PROVIDER,
            "config": {
                "model": settings.LLM_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
        embedder={
            "provider": settings.EMBEDDER_PROVIDER,
            "config": {
                "model": settings.EMBEDDER_MODEL,
                "api_key": settings.OPENAI_API_KEY,
            },
        },
    )
    return AsyncMemory(config)


# Example 5: Auto-detect configuration
def create_memory_client_auto(settings: MemorySettings):
    """
    Auto-detect and create appropriate memory client.

    Args:
        settings: Memory configuration settings

    Returns:
        MemoryClient or AsyncMemory instance
    """
    if settings.MEM0_API_KEY:
        # Use hosted platform
        return create_hosted_client(settings.MEM0_API_KEY)
    else:
        # Use self-hosted with Qdrant as default
        return create_self_hosted_qdrant(settings)


# Example 6: With Anthropic LLM
def create_with_anthropic(settings: MemorySettings) -> AsyncMemory:
    """
    Create Mem0 client with Anthropic Claude.

    Args:
        settings: Memory configuration settings

    Returns:
        AsyncMemory instance
    """
    config = MemoryConfig(
        vector_store={
            "provider": "qdrant",
            "config": {
                "host": settings.QDRANT_HOST,
                "port": settings.QDRANT_PORT,
                "api_key": settings.QDRANT_API_KEY,
            },
        },
        llm={
            "provider": "anthropic",
            "config": {
                "model": "claude-sonnet-4-5-20250929",
                "api_key": settings.ANTHROPIC_API_KEY,
            },
        },
        embedder={
            "provider": "openai",
            "config": {
                "model": "text-embedding-3-small",
                "api_key": settings.OPENAI_API_KEY,
            },
        },
    )
    return AsyncMemory(config)


# Usage Examples
if __name__ == "__main__":
    # Load settings
    settings = MemorySettings()

    # Example: Create hosted client
    if settings.MEM0_API_KEY:
        hosted_client = create_hosted_client(settings.MEM0_API_KEY)
        print("Created hosted Mem0 client")

    # Example: Create self-hosted client
    elif settings.QDRANT_HOST and settings.OPENAI_API_KEY:
        self_hosted_client = create_self_hosted_qdrant(settings)
        print("Created self-hosted Mem0 client with Qdrant")

    # Example: Auto-detect
    auto_client = create_memory_client_auto(settings)
    print(f"Auto-created client: {type(auto_client).__name__}")
