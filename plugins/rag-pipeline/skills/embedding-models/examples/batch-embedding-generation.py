"""
Batch Embedding Generation Example

Efficiently process large document collections with batching,
progress tracking, and error recovery.
"""

import os
import json
import time
from typing import List, Dict, Any, Optional
from pathlib import Path
import numpy as np


class BatchEmbeddingGenerator:
    """
    Generate embeddings for large document collections efficiently.

    Features:
    - Automatic batching
    - Progress tracking
    - Error recovery and retry
    - Checkpoint saving
    - Memory-efficient processing
    """

    def __init__(
        self,
        embedder,
        batch_size: int = 100,
        checkpoint_dir: Optional[str] = None,
        save_interval: int = 1000
    ):
        """
        Initialize batch embedding generator.

        Args:
            embedder: Embedding model instance (OpenAI, HuggingFace, etc.)
            batch_size: Number of documents per batch
            checkpoint_dir: Directory to save checkpoints
            save_interval: Save checkpoint every N documents
        """
        self.embedder = embedder
        self.batch_size = batch_size
        self.checkpoint_dir = Path(checkpoint_dir) if checkpoint_dir else None
        self.save_interval = save_interval

        if self.checkpoint_dir:
            self.checkpoint_dir.mkdir(parents=True, exist_ok=True)

    def generate(
        self,
        documents: List[str],
        doc_ids: Optional[List[str]] = None,
        resume_from_checkpoint: bool = True,
        show_progress: bool = True
    ) -> Dict[str, List[float]]:
        """
        Generate embeddings for all documents.

        Args:
            documents: List of text documents
            doc_ids: Optional list of document IDs (uses indices if None)
            resume_from_checkpoint: Whether to resume from saved checkpoint
            show_progress: Show progress information

        Returns:
            Dictionary mapping doc_id to embedding vector
        """
        if doc_ids is None:
            doc_ids = [str(i) for i in range(len(documents))]

        if len(documents) != len(doc_ids):
            raise ValueError("documents and doc_ids must have same length")

        # Try to load checkpoint
        embeddings = {}
        start_idx = 0

        if resume_from_checkpoint and self.checkpoint_dir:
            embeddings, start_idx = self._load_checkpoint()
            if start_idx > 0 and show_progress:
                print(f"Resuming from document {start_idx}/{len(documents)}")

        # Process remaining documents
        total = len(documents)
        processed = start_idx

        for i in range(start_idx, total, self.batch_size):
            batch_end = min(i + self.batch_size, total)
            batch_docs = documents[i:batch_end]
            batch_ids = doc_ids[i:batch_end]

            if show_progress:
                elapsed = processed / total * 100 if total > 0 else 0
                print(f"Processing {i}-{batch_end}/{total} ({elapsed:.1f}%)")

            # Generate embeddings for batch
            try:
                batch_embeddings = self.embedder.embed(batch_docs)

                # Store results
                for doc_id, embedding in zip(batch_ids, batch_embeddings):
                    embeddings[doc_id] = embedding

                processed = batch_end

                # Save checkpoint periodically
                if self.checkpoint_dir and processed % self.save_interval == 0:
                    self._save_checkpoint(embeddings, processed)
                    if show_progress:
                        print(f"Checkpoint saved at {processed} documents")

            except Exception as e:
                print(f"Error processing batch {i}-{batch_end}: {e}")
                # Save checkpoint before raising
                if self.checkpoint_dir:
                    self._save_checkpoint(embeddings, i)
                raise

        # Final checkpoint
        if self.checkpoint_dir:
            self._save_checkpoint(embeddings, total)

        if show_progress:
            print(f"Complete: {len(embeddings)} embeddings generated")

        return embeddings

    def _save_checkpoint(self, embeddings: Dict[str, List[float]], position: int):
        """Save checkpoint to disk."""
        checkpoint_file = self.checkpoint_dir / "checkpoint.json"

        checkpoint = {
            'position': position,
            'embeddings': embeddings,
            'timestamp': time.time()
        }

        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint, f)

    def _load_checkpoint(self) -> tuple:
        """Load checkpoint from disk."""
        checkpoint_file = self.checkpoint_dir / "checkpoint.json"

        if not checkpoint_file.exists():
            return {}, 0

        try:
            with open(checkpoint_file, 'r') as f:
                checkpoint = json.load(f)

            embeddings = checkpoint.get('embeddings', {})
            position = checkpoint.get('position', 0)

            return embeddings, position

        except Exception as e:
            print(f"Error loading checkpoint: {e}")
            return {}, 0

    def save_embeddings(
        self,
        embeddings: Dict[str, List[float]],
        output_file: str,
        format: str = 'json'
    ):
        """
        Save embeddings to file.

        Args:
            embeddings: Dictionary of embeddings
            output_file: Output file path
            format: 'json' or 'npy' or 'npz'
        """
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        if format == 'json':
            with open(output_path, 'w') as f:
                json.dump(embeddings, f)

        elif format == 'npy':
            # Save as numpy array (loses doc_ids)
            vectors = np.array(list(embeddings.values()))
            np.save(output_path, vectors)

        elif format == 'npz':
            # Save with doc_ids preserved
            doc_ids = list(embeddings.keys())
            vectors = np.array(list(embeddings.values()))
            np.savez(output_path, doc_ids=doc_ids, embeddings=vectors)

        else:
            raise ValueError(f"Unsupported format: {format}")

        print(f"Saved {len(embeddings)} embeddings to {output_path}")


# Example usage
if __name__ == "__main__":
    # Example with OpenAI
    from openai import OpenAI

    class SimpleEmbedder:
        def __init__(self):
            self.client = OpenAI()

        def embed(self, texts):
            response = self.client.embeddings.create(
                model="text-embedding-3-small",
                input=texts
            )
            return [item.embedding for item in response.data]

    # Create sample documents
    documents = [
        f"This is document number {i} about topic {i % 10}"
        for i in range(500)
    ]

    doc_ids = [f"doc_{i}" for i in range(len(documents))]

    # Initialize generator
    embedder = SimpleEmbedder()
    generator = BatchEmbeddingGenerator(
        embedder=embedder,
        batch_size=100,
        checkpoint_dir="./checkpoints",
        save_interval=200
    )

    # Generate embeddings
    print("Generating embeddings...")
    embeddings = generator.generate(
        documents=documents,
        doc_ids=doc_ids,
        show_progress=True
    )

    # Save results
    generator.save_embeddings(
        embeddings,
        "embeddings.npz",
        format='npz'
    )

    print(f"\nGenerated {len(embeddings)} embeddings")
    print(f"Embedding dimensions: {len(list(embeddings.values())[0])}")
