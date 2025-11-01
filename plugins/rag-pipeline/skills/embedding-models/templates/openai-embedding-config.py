"""
OpenAI Embedding Configuration Template

Production-ready configuration for OpenAI embeddings with retry logic,
batching, and error handling.
"""

import os
import time
from typing import List, Optional
from openai import OpenAI, RateLimitError, APIError


class OpenAIEmbeddings:
    """
    OpenAI Embedding client with retry logic and batching.

    Usage:
        embedder = OpenAIEmbeddings(api_key="your-key")
        embeddings = embedder.embed(["text1", "text2"])
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = "text-embedding-3-small",
        max_retries: int = 3,
        retry_delay: float = 1.0,
        batch_size: int = 100
    ):
        """
        Initialize OpenAI embeddings client.

        Args:
            api_key: OpenAI API key (defaults to OPENAI_API_KEY env var)
            model: Embedding model to use
            max_retries: Maximum retry attempts on failures
            retry_delay: Delay between retries in seconds
            batch_size: Maximum texts per API call
        """
        self.api_key = api_key or os.environ.get('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("OpenAI API key required")

        self.client = OpenAI(api_key=self.api_key)
        self.model = model
        self.max_retries = max_retries
        self.retry_delay = retry_delay
        self.batch_size = batch_size

    def embed(
        self,
        texts: List[str],
        show_progress: bool = False
    ) -> List[List[float]]:
        """
        Generate embeddings for a list of texts.

        Args:
            texts: List of text strings to embed
            show_progress: Print progress information

        Returns:
            List of embedding vectors
        """
        if not texts:
            return []

        all_embeddings = []

        # Process in batches
        for i in range(0, len(texts), self.batch_size):
            batch = texts[i:i + self.batch_size]

            if show_progress:
                print(f"Processing batch {i//self.batch_size + 1}/{(len(texts)-1)//self.batch_size + 1}")

            # Retry logic
            for attempt in range(self.max_retries):
                try:
                    response = self.client.embeddings.create(
                        model=self.model,
                        input=batch
                    )

                    # Extract embeddings in correct order
                    batch_embeddings = [item.embedding for item in response.data]
                    all_embeddings.extend(batch_embeddings)
                    break

                except RateLimitError as e:
                    if attempt < self.max_retries - 1:
                        wait_time = self.retry_delay * (2 ** attempt)
                        print(f"Rate limit hit, retrying in {wait_time}s...")
                        time.sleep(wait_time)
                    else:
                        raise

                except APIError as e:
                    if attempt < self.max_retries - 1:
                        wait_time = self.retry_delay * (2 ** attempt)
                        print(f"API error, retrying in {wait_time}s...")
                        time.sleep(wait_time)
                    else:
                        raise

        return all_embeddings

    def embed_single(self, text: str) -> List[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Text string to embed

        Returns:
            Embedding vector
        """
        embeddings = self.embed([text])
        return embeddings[0] if embeddings else []

    def get_dimensions(self) -> int:
        """Get the dimensionality of embeddings for this model."""
        dimensions = {
            'text-embedding-3-small': 1536,
            'text-embedding-3-large': 3072,
            'text-embedding-ada-002': 1536
        }
        return dimensions.get(self.model, 1536)


# Example usage
if __name__ == "__main__":
    # Initialize embedder
    embedder = OpenAIEmbeddings(
        model="text-embedding-3-small",
        max_retries=3,
        batch_size=100
    )

    # Single embedding
    text = "This is a test sentence."
    embedding = embedder.embed_single(text)
    print(f"Embedding dimensions: {len(embedding)}")

    # Batch embeddings
    texts = [
        "First document",
        "Second document",
        "Third document"
    ]
    embeddings = embedder.embed(texts, show_progress=True)
    print(f"Generated {len(embeddings)} embeddings")
