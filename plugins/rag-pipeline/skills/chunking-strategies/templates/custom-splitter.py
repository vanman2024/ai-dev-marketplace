#!/usr/bin/env python3
"""
Custom Chunking Splitter Template

Use this template to create your own custom chunking logic tailored
to your specific document types and requirements.
"""

from typing import List, Dict, Optional, Tuple
import re


class CustomChunker:
    """
    Template for implementing custom chunking strategies.

    Customize this class to handle your specific document format,
    structure, or chunking requirements.
    """

    def __init__(self, chunk_size: int = 1000, overlap: int = 200, **kwargs):
        """
        Initialize custom chunker.

        Args:
            chunk_size: Target chunk size in characters
            overlap: Overlap between chunks in characters
            **kwargs: Additional custom parameters
        """
        self.chunk_size = chunk_size
        self.overlap = overlap

        # Store custom configuration
        self.config = kwargs

    def chunk(self, text: str, metadata: Optional[Dict] = None) -> List[Dict]:
        """
        Main chunking method - implement your logic here.

        Args:
            text: Input text to chunk
            metadata: Optional metadata to include in chunks

        Returns:
            List of chunks with metadata:
            [
                {
                    "text": "chunk content",
                    "metadata": {
                        "chunk_id": 0,
                        "source": "document.txt",
                        "start_char": 0,
                        "end_char": 1000,
                        ... custom fields ...
                    }
                }
            ]
        """
        if metadata is None:
            metadata = {}

        # Example: Call your custom chunking logic
        raw_chunks = self._custom_split(text)

        # Format output with metadata
        result = []
        char_position = 0

        for i, chunk_text in enumerate(raw_chunks):
            chunk_metadata = {
                **metadata,
                "chunk_id": i,
                "chunk_size": len(chunk_text),
                "start_char": char_position,
                "end_char": char_position + len(chunk_text),
                "strategy": "custom",
            }

            # Add custom metadata fields
            chunk_metadata.update(self._extract_custom_metadata(chunk_text))

            result.append({
                "text": chunk_text.strip(),
                "metadata": chunk_metadata
            })

            char_position += len(chunk_text)

        return result

    def _custom_split(self, text: str) -> List[str]:
        """
        Implement your custom splitting logic here.

        Examples:
        - Split on custom markers or delimiters
        - Use regex patterns specific to your format
        - Apply domain-specific rules
        - Combine multiple splitting strategies

        Args:
            text: Text to split

        Returns:
            List of chunk texts
        """
        # EXAMPLE 1: Split on custom markers
        # chunks = self._split_on_markers(text, markers=["===", "---"])

        # EXAMPLE 2: Split by custom regex pattern
        # chunks = self._split_by_pattern(text, pattern=r'\n#{2,}\s+')

        # EXAMPLE 3: Combine multiple strategies
        # chunks = self._hybrid_split(text)

        # Default implementation (replace with your logic)
        return self._simple_paragraph_split(text)

    def _simple_paragraph_split(self, text: str) -> List[str]:
        """Example: Simple paragraph-based splitting."""
        paragraphs = re.split(r'\n\s*\n', text)
        chunks = []
        current_chunk = ""

        for para in paragraphs:
            para = para.strip()
            if not para:
                continue

            test_chunk = current_chunk + "\n\n" + para if current_chunk else para

            if len(test_chunk) <= self.chunk_size:
                current_chunk = test_chunk
            else:
                if current_chunk:
                    chunks.append(current_chunk)

                # Start new chunk with overlap
                overlap_text = self._get_overlap(current_chunk)
                current_chunk = overlap_text + "\n\n" + para if overlap_text else para

        if current_chunk:
            chunks.append(current_chunk)

        return chunks

    def _split_on_markers(self, text: str, markers: List[str]) -> List[str]:
        """
        Example: Split on custom markers/delimiters.

        Useful for documents with explicit section markers like:
        - "=== Section ==="
        - "--- Page Break ---"
        - Custom XML/HTML tags
        """
        # Create regex pattern from markers
        pattern = '|'.join(re.escape(marker) for marker in markers)

        # Split on any marker
        sections = re.split(f'({pattern})', text)

        # Group sections into chunks
        chunks = []
        current_chunk = ""

        for i, section in enumerate(sections):
            if section.strip() in markers:
                # Found a marker - complete current chunk
                if current_chunk:
                    chunks.append(current_chunk.strip())
                current_chunk = section + "\n"  # Include marker in new chunk
            else:
                current_chunk += section

        if current_chunk:
            chunks.append(current_chunk.strip())

        return chunks

    def _split_by_pattern(self, text: str, pattern: str) -> List[str]:
        """
        Example: Split using regex pattern.

        Useful for:
        - Markdown headers: r'\n#{1,6}\s+'
        - XML/HTML tags: r'<(?:section|div|article)>'
        - Custom formats: Your domain-specific pattern
        """
        sections = re.split(pattern, text)
        return [s.strip() for s in sections if s.strip()]

    def _hybrid_split(self, text: str) -> List[str]:
        """
        Example: Combine multiple splitting strategies.

        Use case: First split on major sections, then split large
        sections into smaller chunks.
        """
        # Step 1: Split on major boundaries
        major_sections = self._split_by_pattern(text, r'\n#{2}\s+')

        # Step 2: Further split large sections
        chunks = []
        for section in major_sections:
            if len(section) > self.chunk_size:
                # Section too large - split into smaller chunks
                sub_chunks = self._simple_paragraph_split(section)
                chunks.extend(sub_chunks)
            else:
                chunks.append(section)

        return chunks

    def _extract_custom_metadata(self, chunk_text: str) -> Dict:
        """
        Extract custom metadata from chunk content.

        Examples:
        - Extract headers/titles
        - Identify section types
        - Count special elements (code blocks, lists, etc.)
        - Detect language or domain
        """
        metadata = {}

        # Example: Extract markdown header
        header_match = re.match(r'^(#{1,6})\s+(.+)$', chunk_text, re.MULTILINE)
        if header_match:
            metadata["header_level"] = len(header_match.group(1))
            metadata["header_text"] = header_match.group(2)

        # Example: Detect code blocks
        code_blocks = re.findall(r'```[\s\S]*?```', chunk_text)
        if code_blocks:
            metadata["has_code"] = True
            metadata["code_block_count"] = len(code_blocks)

        # Example: Count lists
        list_items = re.findall(r'^\s*[-*+]\s+', chunk_text, re.MULTILINE)
        if list_items:
            metadata["has_list"] = True
            metadata["list_item_count"] = len(list_items)

        return metadata

    def _get_overlap(self, text: str) -> str:
        """Get overlap text from end of previous chunk."""
        if len(text) <= self.overlap:
            return text
        return text[-self.overlap:]

    def validate_chunks(self, chunks: List[Dict]) -> Tuple[bool, List[str]]:
        """
        Validate generated chunks.

        Returns:
            (is_valid, list_of_issues)
        """
        issues = []

        # Check chunk sizes
        for chunk in chunks:
            size = chunk["metadata"]["chunk_size"]
            if size > self.chunk_size * 1.5:
                issues.append(f"Chunk {chunk['metadata']['chunk_id']} exceeds max size: {size}")

            if size < 50:
                issues.append(f"Chunk {chunk['metadata']['chunk_id']} is very small: {size}")

        # Check for empty chunks
        empty_chunks = [c for c in chunks if not c["text"].strip()]
        if empty_chunks:
            issues.append(f"Found {len(empty_chunks)} empty chunks")

        # Check overlap
        if self.overlap > 0 and len(chunks) > 1:
            for i in range(1, len(chunks)):
                # Verify chunks have some overlap (simplified check)
                pass  # Implement overlap verification

        return len(issues) == 0, issues


# Example usage and testing
if __name__ == "__main__":
    import json

    # Sample document
    sample_text = """
# Introduction

This is a sample document to demonstrate custom chunking.

## Section 1

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

```python
def example():
    return "code block"
```

## Section 2

Ut enim ad minim veniam, quis nostrud exercitation ullamco
laboris nisi ut aliquip ex ea commodo consequat.

- List item 1
- List item 2
- List item 3
"""

    # Create chunker
    chunker = CustomChunker(
        chunk_size=500,
        overlap=100
    )

    # Chunk the document
    chunks = chunker.chunk(sample_text, metadata={"source": "sample.md"})

    # Validate
    is_valid, issues = chunker.validate_chunks(chunks)

    # Display results
    print(f"Generated {len(chunks)} chunks")
    print(f"Valid: {is_valid}")
    if issues:
        print("Issues:")
        for issue in issues:
            print(f"  - {issue}")

    print("\nChunks:")
    print(json.dumps(chunks, indent=2))
