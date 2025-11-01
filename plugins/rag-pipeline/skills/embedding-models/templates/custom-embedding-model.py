"""
Custom Embedding Model Template

Unified interface for any embedding model with consistent API.
Supports OpenAI, Cohere, HuggingFace, and custom models.
"""

from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional
from enum import Enum


class EmbeddingProvider(Enum):
    """Supported embedding providers."""
    OPENAI = "openai"
    COHERE = "cohere"
    HUGGINGFACE = "huggingface"
    CUSTOM = "custom"


class BaseEmbedding(ABC):
    """
    Abstract base class for embedding models.

    All embedding implementations should inherit from this class
    and implement the required methods.
    """

    def __init__(self, model_name: str, **kwargs):
        """Initialize embedding model."""
        self.model_name = model_name
        self.config = kwargs

    @abstractmethod
    def embed(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for multiple texts.

        Args:
            texts: List of text strings

        Returns:
            List of embedding vectors
        """
        pass

    @abstractmethod
    def embed_single(self, text: str) -> List[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Text string

        Returns:
            Embedding vector
        """
        pass

    @abstractmethod
    def get_dimensions(self) -> int:
        """Get embedding dimensionality."""
        pass

    def get_provider(self) -> str:
        """Get provider name."""
        return self.__class__.__name__


class OpenAIEmbedding(BaseEmbedding):
    """OpenAI embedding implementation."""

    def __init__(self, model_name: str = "text-embedding-3-small", **kwargs):
        super().__init__(model_name, **kwargs)
        from openai import OpenAI
        import os

        api_key = kwargs.get('api_key') or os.environ.get('OPENAI_API_KEY')
        self.client = OpenAI(api_key=api_key)
        self.batch_size = kwargs.get('batch_size', 100)

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using OpenAI API."""
        all_embeddings = []

        for i in range(0, len(texts), self.batch_size):
            batch = texts[i:i + self.batch_size]
            response = self.client.embeddings.create(
                model=self.model_name,
                input=batch
            )
            batch_embeddings = [item.embedding for item in response.data]
            all_embeddings.extend(batch_embeddings)

        return all_embeddings

    def embed_single(self, text: str) -> List[float]:
        """Generate single embedding."""
        return self.embed([text])[0]

    def get_dimensions(self) -> int:
        """Get embedding dimensions."""
        dims = {
            'text-embedding-3-small': 1536,
            'text-embedding-3-large': 3072,
            'text-embedding-ada-002': 1536
        }
        return dims.get(self.model_name, 1536)


class CohereEmbedding(BaseEmbedding):
    """Cohere embedding implementation."""

    def __init__(self, model_name: str = "embed-english-v3.0", **kwargs):
        super().__init__(model_name, **kwargs)
        import cohere
        import os

        api_key = kwargs.get('api_key') or os.environ.get('COHERE_API_KEY')
        self.client = cohere.Client(api_key)
        self.input_type = kwargs.get('input_type', 'search_document')

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using Cohere API."""
        response = self.client.embed(
            texts=texts,
            model=self.model_name,
            input_type=self.input_type
        )
        return response.embeddings

    def embed_single(self, text: str) -> List[float]:
        """Generate single embedding."""
        return self.embed([text])[0]

    def get_dimensions(self) -> int:
        """Get embedding dimensions."""
        dims = {
            'embed-english-v3.0': 1024,
            'embed-english-light-v3.0': 384,
            'embed-multilingual-v3.0': 1024
        }
        return dims.get(self.model_name, 1024)


class HuggingFaceEmbedding(BaseEmbedding):
    """HuggingFace embedding implementation."""

    def __init__(self, model_name: str = "all-MiniLM-L6-v2", **kwargs):
        super().__init__(model_name, **kwargs)
        from sentence_transformers import SentenceTransformer

        device = kwargs.get('device', None)
        self.model = SentenceTransformer(model_name, device=device)
        self.batch_size = kwargs.get('batch_size', 32)

    def embed(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings using HuggingFace model."""
        embeddings = self.model.encode(
            texts,
            batch_size=self.batch_size,
            normalize_embeddings=True,
            convert_to_numpy=True
        )
        return embeddings.tolist()

    def embed_single(self, text: str) -> List[float]:
        """Generate single embedding."""
        embedding = self.model.encode(
            [text],
            normalize_embeddings=True,
            convert_to_numpy=True
        )
        return embedding[0].tolist()

    def get_dimensions(self) -> int:
        """Get embedding dimensions."""
        return self.model.get_sentence_embedding_dimension()


class EmbeddingFactory:
    """
    Factory class for creating embedding instances.

    Usage:
        embedder = EmbeddingFactory.create(
            provider=EmbeddingProvider.OPENAI,
            model_name="text-embedding-3-small"
        )
    """

    @staticmethod
    def create(
        provider: EmbeddingProvider,
        model_name: Optional[str] = None,
        **kwargs
    ) -> BaseEmbedding:
        """
        Create an embedding instance.

        Args:
            provider: Embedding provider
            model_name: Model name (uses default if None)
            **kwargs: Additional configuration

        Returns:
            BaseEmbedding instance
        """
        if provider == EmbeddingProvider.OPENAI:
            model = model_name or "text-embedding-3-small"
            return OpenAIEmbedding(model, **kwargs)

        elif provider == EmbeddingProvider.COHERE:
            model = model_name or "embed-english-v3.0"
            return CohereEmbedding(model, **kwargs)

        elif provider == EmbeddingProvider.HUGGINGFACE:
            model = model_name or "all-MiniLM-L6-v2"
            return HuggingFaceEmbedding(model, **kwargs)

        else:
            raise ValueError(f"Unsupported provider: {provider}")

    @staticmethod
    def from_config(config: Dict[str, Any]) -> BaseEmbedding:
        """
        Create embedding from configuration dictionary.

        Args:
            config: Configuration with 'provider', 'model_name', etc.

        Returns:
            BaseEmbedding instance
        """
        provider_str = config.get('provider', 'openai')
        provider = EmbeddingProvider(provider_str.lower())
        model_name = config.get('model_name')

        # Remove provider and model_name from kwargs
        kwargs = {k: v for k, v in config.items()
                  if k not in ['provider', 'model_name']}

        return EmbeddingFactory.create(provider, model_name, **kwargs)


# Example usage
if __name__ == "__main__":
    # Create embeddings from factory
    openai_embedder = EmbeddingFactory.create(
        provider=EmbeddingProvider.OPENAI,
        model_name="text-embedding-3-small"
    )

    hf_embedder = EmbeddingFactory.create(
        provider=EmbeddingProvider.HUGGINGFACE,
        model_name="all-MiniLM-L6-v2"
    )

    # Create from config
    config = {
        'provider': 'openai',
        'model_name': 'text-embedding-3-small',
        'batch_size': 100
    }
    embedder = EmbeddingFactory.from_config(config)

    # Use consistent interface
    texts = ["Hello world", "How are you?"]
    embeddings = embedder.embed(texts)

    print(f"Provider: {embedder.get_provider()}")
    print(f"Model: {embedder.model_name}")
    print(f"Dimensions: {embedder.get_dimensions()}")
    print(f"Embeddings shape: {len(embeddings)} x {len(embeddings[0])}")
