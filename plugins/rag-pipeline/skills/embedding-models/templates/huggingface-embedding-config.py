"""
HuggingFace Embedding Configuration Template

Production-ready configuration for HuggingFace sentence-transformers
with GPU support, batching, and normalization.
"""

import os
from typing import List, Optional, Union
import numpy as np
from sentence_transformers import SentenceTransformer
import torch


class HuggingFaceEmbeddings:
    """
    HuggingFace Sentence Transformers client with GPU support.

    Usage:
        embedder = HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")
        embeddings = embedder.embed(["text1", "text2"])
    """

    def __init__(
        self,
        model_name: str = "all-MiniLM-L6-v2",
        device: Optional[str] = None,
        batch_size: int = 32,
        normalize_embeddings: bool = True,
        cache_folder: Optional[str] = None
    ):
        """
        Initialize HuggingFace embeddings.

        Args:
            model_name: Name of the sentence-transformers model
            device: Device to use ('cuda', 'cpu', or None for auto-detect)
            batch_size: Batch size for encoding
            normalize_embeddings: Whether to normalize embeddings to unit length
            cache_folder: Custom cache folder for models
        """
        # Auto-detect device if not specified
        if device is None:
            device = 'cuda' if torch.cuda.is_available() else 'cpu'

        self.model_name = model_name
        self.device = device
        self.batch_size = batch_size
        self.normalize_embeddings = normalize_embeddings

        # Load model
        self.model = SentenceTransformer(
            model_name,
            device=device,
            cache_folder=cache_folder
        )

        print(f"Loaded {model_name} on {device}")
        if device == 'cuda':
            print(f"GPU: {torch.cuda.get_device_name(0)}")

    def embed(
        self,
        texts: List[str],
        show_progress: bool = False,
        convert_to_numpy: bool = True
    ) -> Union[np.ndarray, List[List[float]]]:
        """
        Generate embeddings for a list of texts.

        Args:
            texts: List of text strings to embed
            show_progress: Show progress bar
            convert_to_numpy: Return numpy array instead of list

        Returns:
            Embeddings as numpy array or list of lists
        """
        if not texts:
            return np.array([]) if convert_to_numpy else []

        # Encode texts
        embeddings = self.model.encode(
            texts,
            batch_size=self.batch_size,
            show_progress_bar=show_progress,
            normalize_embeddings=self.normalize_embeddings,
            convert_to_numpy=convert_to_numpy
        )

        return embeddings

    def embed_single(self, text: str) -> List[float]:
        """
        Generate embedding for a single text.

        Args:
            text: Text string to embed

        Returns:
            Embedding vector as list
        """
        embedding = self.model.encode(
            [text],
            normalize_embeddings=self.normalize_embeddings,
            convert_to_numpy=True
        )
        return embedding[0].tolist()

    def similarity(self, text1: str, text2: str) -> float:
        """
        Calculate cosine similarity between two texts.

        Args:
            text1: First text
            text2: Second text

        Returns:
            Similarity score between -1 and 1
        """
        from sentence_transformers.util import cos_sim

        embeddings = self.embed([text1, text2], convert_to_numpy=False)
        similarity = cos_sim(embeddings[0], embeddings[1])
        return float(similarity[0][0])

    def get_dimensions(self) -> int:
        """Get the dimensionality of embeddings for this model."""
        return self.model.get_sentence_embedding_dimension()

    def get_max_seq_length(self) -> int:
        """Get maximum sequence length the model can handle."""
        return self.model.max_seq_length


# Popular model presets
MODELS = {
    'small': 'all-MiniLM-L6-v2',           # 384 dims, fast
    'medium': 'all-mpnet-base-v2',         # 768 dims, balanced
    'large': 'BAAI/bge-large-en-v1.5',     # 1024 dims, high quality
    'multilingual': 'paraphrase-multilingual-mpnet-base-v2',  # 768 dims
    'qa': 'multi-qa-mpnet-base-dot-v1',    # 768 dims, Q&A optimized
}


def get_embedder(
    size: str = 'small',
    use_gpu: bool = True
) -> HuggingFaceEmbeddings:
    """
    Convenience function to get a pre-configured embedder.

    Args:
        size: Model size ('small', 'medium', 'large', 'multilingual', 'qa')
        use_gpu: Whether to use GPU if available

    Returns:
        Configured HuggingFaceEmbeddings instance
    """
    model_name = MODELS.get(size, MODELS['small'])
    device = 'cuda' if (use_gpu and torch.cuda.is_available()) else 'cpu'

    return HuggingFaceEmbeddings(
        model_name=model_name,
        device=device
    )


# Example usage
if __name__ == "__main__":
    # Initialize with small model
    embedder = HuggingFaceEmbeddings(
        model_name="all-MiniLM-L6-v2",
        batch_size=32
    )

    # Single embedding
    text = "This is a test sentence."
    embedding = embedder.embed_single(text)
    print(f"Embedding dimensions: {len(embedding)}")
    print(f"Max sequence length: {embedder.get_max_seq_length()}")

    # Batch embeddings
    texts = [
        "First document",
        "Second document",
        "Third document"
    ]
    embeddings = embedder.embed(texts, show_progress=True)
    print(f"Generated embeddings shape: {embeddings.shape}")

    # Similarity
    similarity = embedder.similarity("Hello world", "Hi there")
    print(f"Similarity: {similarity:.3f}")

    # Using preset
    large_embedder = get_embedder('large')
    print(f"Large model dimensions: {large_embedder.get_dimensions()}")
