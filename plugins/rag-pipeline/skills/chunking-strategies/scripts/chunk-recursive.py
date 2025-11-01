#!/usr/bin/env python3
"""
Recursive Chunking Implementation

Recursively splits documents using a hierarchy of separators until
all chunks are within the target size. Excellent for structured documents.
"""

import argparse
import json
import sys
from typing import List, Dict
import re


class RecursiveChunker:
    """Recursive document chunking with hierarchical separators."""

    def __init__(self, chunk_size: int = 1000, overlap: int = 100,
                 separators: List[str] = None):
        """
        Initialize recursive chunker.

        Args:
            chunk_size: Target chunk size in characters
            overlap: Overlap between chunks in characters
            separators: List of separators in priority order
        """
        self.chunk_size = chunk_size
        self.overlap = overlap

        # Default separators (ordered by priority)
        if separators is None:
            separators = ["\n\n", "\n", ". ", " ", ""]

        self.separators = separators

    def chunk(self, text: str, metadata: Dict = None) -> List[Dict]:
        """
        Recursively split text using hierarchical separators.

        Args:
            text: Input text to chunk
            metadata: Optional metadata

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        # Perform recursive splitting
        chunks = self._recursive_split(text, self.separators)

        # Add overlap between chunks
        chunks_with_overlap = self._add_overlap(chunks)

        # Format output with metadata
        result = []
        for i, chunk_text in enumerate(chunks_with_overlap):
            result.append({
                "text": chunk_text.strip(),
                "metadata": {
                    **metadata,
                    "chunk_id": i,
                    "chunk_size": len(chunk_text),
                    "strategy": "recursive",
                    "params": {
                        "chunk_size": self.chunk_size,
                        "overlap": self.overlap,
                        "separators": self.separators
                    }
                }
            })

        return result

    def _recursive_split(self, text: str, separators: List[str]) -> List[str]:
        """
        Recursively split text using separator hierarchy.

        Args:
            text: Text to split
            separators: Remaining separators to try

        Returns:
            List of text chunks
        """
        # Base case: no more separators or text is small enough
        if not separators or len(text) <= self.chunk_size:
            return [text] if text else []

        # Get current separator
        separator = separators[0]
        remaining_separators = separators[1:]

        # Split on current separator
        if separator:
            splits = text.split(separator)
        else:
            # Empty separator means split by character
            return [text[i:i+self.chunk_size]
                    for i in range(0, len(text), self.chunk_size)]

        # Combine splits into chunks
        chunks = []
        current_chunk = ""

        for split in splits:
            # Test if we can add this split to current chunk
            test_chunk = current_chunk + separator + split if current_chunk else split

            if len(test_chunk) <= self.chunk_size:
                current_chunk = test_chunk
            else:
                # Current chunk is complete
                if current_chunk:
                    chunks.append(current_chunk)

                # Check if split itself is too large
                if len(split) > self.chunk_size:
                    # Recursively split this piece
                    sub_chunks = self._recursive_split(split, remaining_separators)
                    chunks.extend(sub_chunks)
                    current_chunk = ""
                else:
                    current_chunk = split

        # Add final chunk
        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    def _add_overlap(self, chunks: List[str]) -> List[str]:
        """Add overlap between consecutive chunks."""
        if not chunks or self.overlap == 0:
            return chunks

        overlapped = [chunks[0]]

        for i in range(1, len(chunks)):
            # Get overlap from previous chunk
            prev_chunk = chunks[i - 1]
            overlap_text = prev_chunk[-self.overlap:] if len(prev_chunk) > self.overlap else prev_chunk

            # Add to current chunk
            current_chunk = overlap_text + " " + chunks[i]
            overlapped.append(current_chunk)

        return overlapped


# Predefined separator sets for different document types
SEPARATOR_PRESETS = {
    "markdown": ["\n## ", "\n### ", "\n#### ", "\n\n", "\n", ". ", " ", ""],
    "python": ["\nclass ", "\ndef ", "\n\n", "\n", ". ", " ", ""],
    "javascript": ["\nfunction ", "\nconst ", "\nlet ", "\n\n", "\n", ". ", " ", ""],
    "text": ["\n\n", "\n", ". ", "! ", "? ", ", ", " ", ""],
    "code": ["\n\n", "\n", ";", " ", ""]
}


def main():
    parser = argparse.ArgumentParser(
        description="Recursive document chunking with hierarchical separators"
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
        help="Target chunk size in characters (default: 1000)"
    )
    parser.add_argument(
        "--overlap",
        type=int,
        default=100,
        help="Overlap between chunks in characters (default: 100)"
    )
    parser.add_argument(
        "--separators",
        type=str,
        help='Custom separators as JSON array, e.g., \'["\\n\\n", "\\n", " "]\''
    )
    parser.add_argument(
        "--preset",
        choices=list(SEPARATOR_PRESETS.keys()),
        help="Use predefined separator preset (markdown, python, javascript, text, code)"
    )

    args = parser.parse_args()

    try:
        # Determine separators
        separators = None
        if args.separators:
            separators = json.loads(args.separators)
        elif args.preset:
            separators = SEPARATOR_PRESETS[args.preset]

        # Read input file
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()

        # Initialize chunker
        chunker = RecursiveChunker(
            chunk_size=args.chunk_size,
            overlap=args.overlap,
            separators=separators
        )

        # Chunk the document
        chunks = chunker.chunk(text, metadata={"source": args.input})

        # Calculate statistics
        chunk_sizes = [c["metadata"]["chunk_size"] for c in chunks]
        avg_size = sum(chunk_sizes) / len(chunk_sizes) if chunk_sizes else 0

        # Write output
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump({
                "chunks": chunks,
                "total_chunks": len(chunks),
                "strategy": "recursive",
                "statistics": {
                    "avg_chunk_size": round(avg_size, 2),
                    "min_chunk_size": min(chunk_sizes) if chunk_sizes else 0,
                    "max_chunk_size": max(chunk_sizes) if chunk_sizes else 0
                },
                "config": {
                    "chunk_size": args.chunk_size,
                    "overlap": args.overlap,
                    "separators": chunker.separators,
                    "preset": args.preset
                }
            }, f, indent=2)

        print(f"✓ Created {len(chunks)} chunks")
        print(f"✓ Average chunk size: {avg_size:.0f} characters")
        print(f"✓ Separators used: {chunker.separators[:3]}...")
        print(f"✓ Output written to {args.output}")

    except FileNotFoundError:
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print("Error: Invalid JSON in --separators argument", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
