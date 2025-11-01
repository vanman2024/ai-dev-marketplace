#!/usr/bin/env python3
"""
Fixed-Size Chunking Implementation

Splits documents into fixed-size chunks with configurable overlap.
Fast and predictable chunking for uniform content.
"""

import argparse
import json
import sys
from typing import List, Dict
import re


class FixedSizeChunker:
    """Fixed-size document chunking with overlap support."""

    def __init__(self, chunk_size: int = 1000, overlap: int = 200, split_on: str = "sentence"):
        """
        Initialize fixed-size chunker.

        Args:
            chunk_size: Target chunk size in characters
            overlap: Character overlap between consecutive chunks
            split_on: Split on 'sentence', 'word', or 'character'
        """
        self.chunk_size = chunk_size
        self.overlap = overlap
        self.split_on = split_on

        if overlap >= chunk_size:
            raise ValueError("Overlap must be less than chunk_size")

    def chunk(self, text: str, metadata: Dict = None) -> List[Dict]:
        """
        Split text into fixed-size chunks.

        Args:
            text: Input text to chunk
            metadata: Optional metadata to include in chunks

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        chunks = []

        if self.split_on == "sentence":
            chunks = self._chunk_by_sentence(text)
        elif self.split_on == "word":
            chunks = self._chunk_by_word(text)
        else:  # character
            chunks = self._chunk_by_character(text)

        # Add metadata
        result = []
        for i, chunk_text in enumerate(chunks):
            result.append({
                "text": chunk_text.strip(),
                "metadata": {
                    **metadata,
                    "chunk_id": i,
                    "chunk_size": len(chunk_text),
                    "strategy": "fixed_size",
                    "params": {
                        "chunk_size": self.chunk_size,
                        "overlap": self.overlap,
                        "split_on": self.split_on
                    }
                }
            })

        return result

    def _chunk_by_sentence(self, text: str) -> List[str]:
        """Chunk by complete sentences."""
        # Simple sentence splitting (can be improved with nltk)
        sentences = re.split(r'(?<=[.!?])\s+', text)

        chunks = []
        current_chunk = ""
        overlap_buffer = ""

        for sentence in sentences:
            # Add sentence to current chunk
            test_chunk = current_chunk + " " + sentence if current_chunk else sentence

            if len(test_chunk) <= self.chunk_size:
                current_chunk = test_chunk
            else:
                # Current chunk is full, save it
                if current_chunk:
                    chunks.append(current_chunk)

                    # Prepare overlap for next chunk
                    overlap_buffer = self._get_overlap_text(current_chunk, self.overlap)

                # Start new chunk with overlap + current sentence
                current_chunk = overlap_buffer + " " + sentence if overlap_buffer else sentence

        # Add final chunk
        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    def _chunk_by_word(self, text: str) -> List[str]:
        """Chunk by complete words."""
        words = text.split()
        chunks = []
        current_chunk = []
        current_size = 0

        for word in words:
            word_size = len(word) + 1  # +1 for space
            if current_size + word_size <= self.chunk_size:
                current_chunk.append(word)
                current_size += word_size
            else:
                # Save current chunk
                if current_chunk:
                    chunks.append(" ".join(current_chunk))

                # Calculate overlap words
                overlap_words = self._get_overlap_words(current_chunk, self.overlap)

                # Start new chunk with overlap
                current_chunk = overlap_words + [word]
                current_size = sum(len(w) + 1 for w in current_chunk)

        # Add final chunk
        if current_chunk:
            chunks.append(" ".join(current_chunk))

        return chunks

    def _chunk_by_character(self, text: str) -> List[str]:
        """Chunk by fixed character count."""
        chunks = []
        start = 0

        while start < len(text):
            end = min(start + self.chunk_size, len(text))
            chunks.append(text[start:end])
            start += self.chunk_size - self.overlap

        return chunks

    def _get_overlap_text(self, text: str, overlap_size: int) -> str:
        """Get overlap text from end of chunk."""
        if len(text) <= overlap_size:
            return text
        return text[-overlap_size:]

    def _get_overlap_words(self, words: List[str], overlap_size: int) -> List[str]:
        """Get overlap words based on character size."""
        overlap_words = []
        current_size = 0

        for word in reversed(words):
            word_size = len(word) + 1
            if current_size + word_size <= overlap_size:
                overlap_words.insert(0, word)
                current_size += word_size
            else:
                break

        return overlap_words


def main():
    parser = argparse.ArgumentParser(
        description="Fixed-size document chunking with overlap"
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Input file path"
    )
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Output JSON file path"
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1000,
        help="Chunk size in characters (default: 1000)"
    )
    parser.add_argument(
        "--overlap",
        type=int,
        default=200,
        help="Overlap size in characters (default: 200)"
    )
    parser.add_argument(
        "--split-on",
        choices=["sentence", "word", "character"],
        default="sentence",
        help="Split on sentences, words, or characters (default: sentence)"
    )

    args = parser.parse_args()

    try:
        # Read input file
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()

        # Initialize chunker
        chunker = FixedSizeChunker(
            chunk_size=args.chunk_size,
            overlap=args.overlap,
            split_on=args.split_on
        )

        # Chunk the document
        chunks = chunker.chunk(text, metadata={"source": args.input})

        # Write output
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump({
                "chunks": chunks,
                "total_chunks": len(chunks),
                "strategy": "fixed_size",
                "config": {
                    "chunk_size": args.chunk_size,
                    "overlap": args.overlap,
                    "split_on": args.split_on
                }
            }, f, indent=2)

        print(f"✓ Created {len(chunks)} chunks")
        print(f"✓ Output written to {args.output}")

    except FileNotFoundError:
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
