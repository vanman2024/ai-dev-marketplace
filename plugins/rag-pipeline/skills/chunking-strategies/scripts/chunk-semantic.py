#!/usr/bin/env python3
"""
Semantic Chunking Implementation

Chunks documents by semantic boundaries (paragraphs, sections) while
respecting maximum chunk size limits.
"""

import argparse
import json
import sys
from typing import List, Dict, Tuple
import re


class SemanticChunker:
    """Semantic document chunking that preserves natural boundaries."""

    def __init__(self, max_chunk_size: int = 1500, min_chunk_size: int = 200,
                 preserve_paragraphs: bool = True, add_headers: bool = True):
        """
        Initialize semantic chunker.

        Args:
            max_chunk_size: Maximum chunk size in characters
            min_chunk_size: Minimum chunk size (avoid tiny chunks)
            preserve_paragraphs: Keep paragraphs together when possible
            add_headers: Include section headers in chunks
        """
        self.max_chunk_size = max_chunk_size
        self.min_chunk_size = min_chunk_size
        self.preserve_paragraphs = preserve_paragraphs
        self.add_headers = add_headers

    def chunk(self, text: str, metadata: Dict = None) -> List[Dict]:
        """
        Split text by semantic boundaries.

        Args:
            text: Input text to chunk
            metadata: Optional metadata to include

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        # Detect document structure
        sections = self._split_into_sections(text)

        # Create chunks from sections
        chunks = []
        current_chunk = ""
        current_header = ""

        for section_type, section_header, section_content in sections:
            # Update current header context
            if section_type == "header":
                current_header = section_header

            # Build chunk with optional header
            chunk_text = section_content
            if self.add_headers and current_header:
                chunk_text = f"{current_header}\n\n{section_content}"

            # Check if we can add to current chunk
            combined = current_chunk + "\n\n" + chunk_text if current_chunk else chunk_text

            if len(combined) <= self.max_chunk_size:
                current_chunk = combined
            else:
                # Save current chunk if it meets minimum size
                if current_chunk and len(current_chunk) >= self.min_chunk_size:
                    chunks.append(current_chunk.strip())

                # Start new chunk
                current_chunk = chunk_text

                # If single section is too large, split it
                if len(current_chunk) > self.max_chunk_size:
                    split_chunks = self._split_large_section(current_chunk)
                    chunks.extend(split_chunks[:-1])
                    current_chunk = split_chunks[-1] if split_chunks else ""

        # Add final chunk
        if current_chunk and len(current_chunk) >= self.min_chunk_size:
            chunks.append(current_chunk.strip())

        # Format output with metadata
        result = []
        for i, chunk_text in enumerate(chunks):
            result.append({
                "text": chunk_text,
                "metadata": {
                    **metadata,
                    "chunk_id": i,
                    "chunk_size": len(chunk_text),
                    "strategy": "semantic",
                    "params": {
                        "max_chunk_size": self.max_chunk_size,
                        "min_chunk_size": self.min_chunk_size
                    }
                }
            })

        return result

    def _split_into_sections(self, text: str) -> List[Tuple[str, str, str]]:
        """
        Split text into semantic sections.

        Returns:
            List of (section_type, header, content) tuples
        """
        sections = []

        # Split on multiple newlines (paragraph boundaries)
        paragraphs = re.split(r'\n\s*\n', text)

        current_header = ""

        for para in paragraphs:
            para = para.strip()
            if not para:
                continue

            # Check if paragraph is a header (markdown-style)
            header_match = re.match(r'^(#{1,6})\s+(.+)$', para)
            if header_match:
                current_header = para
                sections.append(("header", current_header, para))
            else:
                # Regular content paragraph
                sections.append(("content", current_header, para))

        return sections

    def _split_large_section(self, text: str) -> List[str]:
        """Split a section that exceeds max_chunk_size."""
        chunks = []
        sentences = re.split(r'(?<=[.!?])\s+', text)

        current_chunk = ""

        for sentence in sentences:
            test_chunk = current_chunk + " " + sentence if current_chunk else sentence

            if len(test_chunk) <= self.max_chunk_size:
                current_chunk = test_chunk
            else:
                if current_chunk:
                    chunks.append(current_chunk.strip())
                current_chunk = sentence

        if current_chunk:
            chunks.append(current_chunk.strip())

        return chunks


def main():
    parser = argparse.ArgumentParser(
        description="Semantic document chunking with boundary preservation"
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
        "--max-chunk-size",
        type=int,
        default=1500,
        help="Maximum chunk size in characters (default: 1500)"
    )
    parser.add_argument(
        "--min-chunk-size",
        type=int,
        default=200,
        help="Minimum chunk size in characters (default: 200)"
    )
    parser.add_argument(
        "--no-preserve-paragraphs",
        action="store_true",
        help="Allow splitting paragraphs"
    )
    parser.add_argument(
        "--no-headers",
        action="store_true",
        help="Don't include section headers in chunks"
    )

    args = parser.parse_args()

    try:
        # Read input file
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()

        # Initialize chunker
        chunker = SemanticChunker(
            max_chunk_size=args.max_chunk_size,
            min_chunk_size=args.min_chunk_size,
            preserve_paragraphs=not args.no_preserve_paragraphs,
            add_headers=not args.no_headers
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
                "strategy": "semantic",
                "statistics": {
                    "avg_chunk_size": round(avg_size, 2),
                    "min_chunk_size": min(chunk_sizes) if chunk_sizes else 0,
                    "max_chunk_size": max(chunk_sizes) if chunk_sizes else 0
                },
                "config": {
                    "max_chunk_size": args.max_chunk_size,
                    "min_chunk_size": args.min_chunk_size,
                    "preserve_paragraphs": not args.no_preserve_paragraphs,
                    "add_headers": not args.no_headers
                }
            }, f, indent=2)

        print(f"✓ Created {len(chunks)} chunks")
        print(f"✓ Average chunk size: {avg_size:.0f} characters")
        print(f"✓ Output written to {args.output}")

    except FileNotFoundError:
        print(f"Error: Input file '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
