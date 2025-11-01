#!/usr/bin/env python3
"""
Markdown-Specific Chunking

Specialized chunking for Markdown documents that preserves:
- Heading hierarchy
- Code blocks
- Lists
- Blockquotes
- Link references
"""

import argparse
import json
import sys
import re
from typing import List, Dict, Tuple


class MarkdownChunker:
    """Markdown-aware document chunking."""

    def __init__(self, max_chunk_size: int = 1500, preserve_code_blocks: bool = True,
                 add_parent_headers: bool = True):
        """
        Initialize Markdown chunker.

        Args:
            max_chunk_size: Maximum chunk size in characters
            preserve_code_blocks: Keep code blocks intact
            add_parent_headers: Include parent section headers
        """
        self.max_chunk_size = max_chunk_size
        self.preserve_code_blocks = preserve_code_blocks
        self.add_parent_headers = add_parent_headers

    def chunk(self, text: str, metadata: Dict = None) -> List[Dict]:
        """
        Chunk Markdown document.

        Args:
            text: Markdown text
            metadata: Optional metadata

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        # Parse document structure
        sections = self._parse_markdown_structure(text)

        # Create chunks from sections
        chunks = self._create_chunks_from_sections(sections)

        # Format output
        result = []
        for i, (chunk_text, chunk_meta) in enumerate(chunks):
            result.append({
                "text": chunk_text.strip(),
                "metadata": {
                    **metadata,
                    **chunk_meta,
                    "chunk_id": i,
                    "chunk_size": len(chunk_text),
                    "strategy": "markdown"
                }
            })

        return result

    def _parse_markdown_structure(self, text: str) -> List[Tuple[int, str, str, int]]:
        """
        Parse Markdown into structured sections.

        Returns:
            List of (level, header, content, start_pos) tuples
        """
        sections = []
        lines = text.split('\n')

        current_section = {
            'level': 0,
            'header': '',
            'content': [],
            'start_line': 0
        }

        in_code_block = False
        code_fence = None

        for i, line in enumerate(lines):
            # Track code blocks
            if line.strip().startswith('```') or line.strip().startswith('~~~'):
                if not in_code_block:
                    in_code_block = True
                    code_fence = line.strip()[:3]
                elif line.strip().startswith(code_fence):
                    in_code_block = False

            # Don't parse headers inside code blocks
            if not in_code_block:
                # Check for ATX headers (# Header)
                header_match = re.match(r'^(#{1,6})\s+(.+)$', line)
                if header_match:
                    # Save previous section
                    if current_section['content']:
                        sections.append((
                            current_section['level'],
                            current_section['header'],
                            '\n'.join(current_section['content']),
                            current_section['start_line']
                        ))

                    # Start new section
                    level = len(header_match.group(1))
                    header = header_match.group(2).strip()

                    current_section = {
                        'level': level,
                        'header': line,
                        'content': [line],
                        'start_line': i
                    }
                    continue

            # Add line to current section
            current_section['content'].append(line)

        # Add final section
        if current_section['content']:
            sections.append((
                current_section['level'],
                current_section['header'],
                '\n'.join(current_section['content']),
                current_section['start_line']
            ))

        return sections

    def _create_chunks_from_sections(self, sections: List[Tuple]) -> List[Tuple[str, Dict]]:
        """
        Create chunks from parsed sections.

        Returns:
            List of (chunk_text, chunk_metadata) tuples
        """
        chunks = []
        current_chunk = []
        current_size = 0
        header_stack = []  # Track parent headers

        for level, header, content, start_line in sections:
            # Update header stack (remove headers at same or deeper level)
            header_stack = [h for h in header_stack if h[0] < level]
            if header:
                header_stack.append((level, header))

            # Prepare section text
            section_text = content

            # Add parent headers if enabled
            if self.add_parent_headers and len(header_stack) > 1:
                parent_headers = '\n'.join(h[1] for h in header_stack[:-1])
                section_text = f"{parent_headers}\n\n{content}"

            # Check if we need to start a new chunk
            section_size = len(section_text)

            if current_size + section_size <= self.max_chunk_size:
                # Add to current chunk
                current_chunk.append(section_text)
                current_size += section_size
            else:
                # Save current chunk
                if current_chunk:
                    chunk_text = '\n\n'.join(current_chunk)
                    chunks.append((chunk_text, {
                        "header_context": [h[1] for h in header_stack[:-1]] if header_stack else [],
                        "section_header": header
                    }))

                # Start new chunk
                if section_size > self.max_chunk_size:
                    # Section is too large - split it
                    split_chunks = self._split_large_section(section_text, header_stack)
                    chunks.extend(split_chunks)
                    current_chunk = []
                    current_size = 0
                else:
                    current_chunk = [section_text]
                    current_size = section_size

        # Add final chunk
        if current_chunk:
            chunk_text = '\n\n'.join(current_chunk)
            chunks.append((chunk_text, {
                "header_context": [h[1] for h in header_stack],
                "section_header": header_stack[-1][1] if header_stack else ""
            }))

        return chunks

    def _split_large_section(self, text: str, header_stack: List) -> List[Tuple[str, Dict]]:
        """Split a section that's too large."""
        chunks = []

        # Try to preserve code blocks
        if self.preserve_code_blocks:
            parts = self._split_preserving_code_blocks(text)
        else:
            # Simple paragraph split
            parts = re.split(r'\n\s*\n', text)

        current_chunk = []
        current_size = 0

        for part in parts:
            part_size = len(part)

            if current_size + part_size <= self.max_chunk_size:
                current_chunk.append(part)
                current_size += part_size
            else:
                # Save current chunk
                if current_chunk:
                    chunk_text = '\n\n'.join(current_chunk)
                    chunks.append((chunk_text, {
                        "header_context": [h[1] for h in header_stack],
                        "section_header": header_stack[-1][1] if header_stack else ""
                    }))

                current_chunk = [part]
                current_size = part_size

        # Add final chunk
        if current_chunk:
            chunk_text = '\n\n'.join(current_chunk)
            chunks.append((chunk_text, {
                "header_context": [h[1] for h in header_stack],
                "section_header": header_stack[-1][1] if header_stack else ""
            }))

        return chunks

    def _split_preserving_code_blocks(self, text: str) -> List[str]:
        """Split text while keeping code blocks intact."""
        parts = []
        current_part = []
        in_code_block = False

        for line in text.split('\n'):
            # Detect code block boundaries
            if line.strip().startswith('```') or line.strip().startswith('~~~'):
                in_code_block = not in_code_block

            if not in_code_block and not line.strip():
                # Empty line outside code block - potential split point
                if current_part:
                    parts.append('\n'.join(current_part))
                    current_part = []
            else:
                current_part.append(line)

        # Add final part
        if current_part:
            parts.append('\n'.join(current_part))

        return [p for p in parts if p.strip()]


def main():
    parser = argparse.ArgumentParser(
        description="Markdown-specific document chunking"
    )
    parser.add_argument(
        "input",
        help="Input Markdown file"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output JSON file (default: stdout)"
    )
    parser.add_argument(
        "--max-chunk-size",
        type=int,
        default=1500,
        help="Maximum chunk size (default: 1500)"
    )
    parser.add_argument(
        "--no-preserve-code",
        action="store_true",
        help="Allow splitting code blocks"
    )
    parser.add_argument(
        "--no-parent-headers",
        action="store_true",
        help="Don't include parent headers"
    )

    args = parser.parse_args()

    try:
        # Read input
        with open(args.input, 'r', encoding='utf-8') as f:
            text = f.read()

        # Create chunker
        chunker = MarkdownChunker(
            max_chunk_size=args.max_chunk_size,
            preserve_code_blocks=not args.no_preserve_code,
            add_parent_headers=not args.no_parent_headers
        )

        # Chunk document
        chunks = chunker.chunk(text, metadata={"source": args.input})

        # Prepare output
        output = {
            "chunks": chunks,
            "total_chunks": len(chunks),
            "strategy": "markdown",
            "config": {
                "max_chunk_size": args.max_chunk_size,
                "preserve_code_blocks": not args.no_preserve_code,
                "add_parent_headers": not args.no_parent_headers
            }
        }

        # Write output
        output_json = json.dumps(output, indent=2)

        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output_json)
            print(f"✓ Created {len(chunks)} chunks")
            print(f"✓ Output written to {args.output}")
        else:
            print(output_json)

    except FileNotFoundError:
        print(f"Error: File '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
