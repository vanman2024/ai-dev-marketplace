#!/usr/bin/env python3
"""
PDF Document Chunking

Specialized chunking for PDF documents with:
- Text extraction
- Page boundary preservation
- Multi-column layout handling
- Metadata extraction (title, author, page numbers)
"""

import argparse
import json
import sys
from typing import List, Dict, Optional

# PDF libraries
try:
    from pypdf import PdfReader
    PYPDF_AVAILABLE = True
except ImportError:
    PYPDF_AVAILABLE = False


class PDFChunker:
    """PDF document chunking with text extraction."""

    def __init__(self, chunk_size: int = 1500, preserve_pages: bool = True,
                 merge_pages: bool = False):
        """
        Initialize PDF chunker.

        Args:
            chunk_size: Maximum chunk size in characters
            preserve_pages: Keep page boundaries
            merge_pages: Merge pages into larger chunks
        """
        if not PYPDF_AVAILABLE:
            raise ImportError(
                "pypdf is required for PDF chunking. Install with: pip install pypdf"
            )

        self.chunk_size = chunk_size
        self.preserve_pages = preserve_pages
        self.merge_pages = merge_pages

    def chunk(self, pdf_path: str, metadata: Optional[Dict] = None) -> List[Dict]:
        """
        Extract and chunk PDF document.

        Args:
            pdf_path: Path to PDF file
            metadata: Optional additional metadata

        Returns:
            List of chunks with metadata
        """
        if metadata is None:
            metadata = {}

        # Extract text and metadata from PDF
        pages, pdf_metadata = self._extract_pdf_content(pdf_path)

        # Combine metadata
        combined_metadata = {**metadata, **pdf_metadata, "source": pdf_path}

        # Create chunks based on strategy
        if self.preserve_pages and not self.merge_pages:
            chunks = self._chunk_by_pages(pages, combined_metadata)
        else:
            chunks = self._chunk_merged_pages(pages, combined_metadata)

        return chunks

    def _extract_pdf_content(self, pdf_path: str) -> tuple[List[Dict], Dict]:
        """
        Extract text and metadata from PDF.

        Returns:
            (pages, metadata) tuple
        """
        reader = PdfReader(pdf_path)

        # Extract metadata
        metadata = {
            "total_pages": len(reader.pages),
            "pdf_metadata": {}
        }

        if reader.metadata:
            if reader.metadata.title:
                metadata["pdf_metadata"]["title"] = reader.metadata.title
            if reader.metadata.author:
                metadata["pdf_metadata"]["author"] = reader.metadata.author
            if reader.metadata.subject:
                metadata["pdf_metadata"]["subject"] = reader.metadata.subject
            if reader.metadata.creator:
                metadata["pdf_metadata"]["creator"] = reader.metadata.creator

        # Extract text from each page
        pages = []
        for i, page in enumerate(reader.pages):
            text = page.extract_text()

            # Clean up text
            text = self._clean_pdf_text(text)

            pages.append({
                "page_number": i + 1,
                "text": text,
                "char_count": len(text)
            })

        return pages, metadata

    def _clean_pdf_text(self, text: str) -> str:
        """Clean up extracted PDF text."""
        # Remove excessive whitespace
        import re
        text = re.sub(r'\s+', ' ', text)

        # Remove page numbers (simple heuristic)
        text = re.sub(r'\n\s*\d+\s*\n', '\n', text)

        # Normalize line breaks
        text = re.sub(r'\n+', '\n\n', text)

        return text.strip()

    def _chunk_by_pages(self, pages: List[Dict], metadata: Dict) -> List[Dict]:
        """Chunk PDF preserving page boundaries."""
        chunks = []

        for page in pages:
            page_text = page["text"]

            # If page is too large, split it
            if len(page_text) > self.chunk_size:
                sub_chunks = self._split_large_page(page_text, page["page_number"])

                for i, chunk_text in enumerate(sub_chunks):
                    chunks.append({
                        "text": chunk_text,
                        "metadata": {
                            **metadata,
                            "chunk_id": len(chunks),
                            "page_number": page["page_number"],
                            "sub_chunk": i,
                            "chunk_size": len(chunk_text),
                            "strategy": "pdf_page"
                        }
                    })
            else:
                # Page fits in one chunk
                chunks.append({
                    "text": page_text,
                    "metadata": {
                        **metadata,
                        "chunk_id": len(chunks),
                        "page_number": page["page_number"],
                        "chunk_size": len(page_text),
                        "strategy": "pdf_page"
                    }
                })

        return chunks

    def _chunk_merged_pages(self, pages: List[Dict], metadata: Dict) -> List[Dict]:
        """Merge pages into larger chunks."""
        chunks = []
        current_chunk = []
        current_size = 0
        start_page = 1

        for page in pages:
            page_text = page["text"]
            page_size = len(page_text)

            if current_size + page_size <= self.chunk_size:
                # Add page to current chunk
                current_chunk.append(page_text)
                current_size += page_size
            else:
                # Save current chunk
                if current_chunk:
                    chunk_text = '\n\n'.join(current_chunk)
                    chunks.append({
                        "text": chunk_text,
                        "metadata": {
                            **metadata,
                            "chunk_id": len(chunks),
                            "page_range": f"{start_page}-{page['page_number']-1}",
                            "chunk_size": len(chunk_text),
                            "strategy": "pdf_merged"
                        }
                    })

                # Start new chunk
                current_chunk = [page_text]
                current_size = page_size
                start_page = page["page_number"]

        # Add final chunk
        if current_chunk:
            chunk_text = '\n\n'.join(current_chunk)
            chunks.append({
                "text": chunk_text,
                "metadata": {
                    **metadata,
                    "chunk_id": len(chunks),
                    "page_range": f"{start_page}-{pages[-1]['page_number']}",
                    "chunk_size": len(chunk_text),
                    "strategy": "pdf_merged"
                }
            })

        return chunks

    def _split_large_page(self, text: str, page_number: int) -> List[str]:
        """Split a page that's too large."""
        import re

        # Try to split on paragraphs
        paragraphs = re.split(r'\n\s*\n', text)

        chunks = []
        current_chunk = ""

        for para in paragraphs:
            test_chunk = current_chunk + "\n\n" + para if current_chunk else para

            if len(test_chunk) <= self.chunk_size:
                current_chunk = test_chunk
            else:
                if current_chunk:
                    chunks.append(current_chunk)

                # If single paragraph is too large, split on sentences
                if len(para) > self.chunk_size:
                    sentences = re.split(r'(?<=[.!?])\s+', para)
                    temp_chunk = ""
                    for sent in sentences:
                        if len(temp_chunk) + len(sent) <= self.chunk_size:
                            temp_chunk += " " + sent if temp_chunk else sent
                        else:
                            if temp_chunk:
                                chunks.append(temp_chunk)
                            temp_chunk = sent

                    current_chunk = temp_chunk
                else:
                    current_chunk = para

        if current_chunk:
            chunks.append(current_chunk)

        return chunks


def main():
    parser = argparse.ArgumentParser(
        description="PDF document chunking with text extraction"
    )
    parser.add_argument(
        "input",
        help="Input PDF file"
    )
    parser.add_argument(
        "--output", "-o",
        help="Output JSON file (default: stdout)"
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1500,
        help="Maximum chunk size (default: 1500)"
    )
    parser.add_argument(
        "--merge-pages",
        action="store_true",
        help="Merge pages into larger chunks"
    )
    parser.add_argument(
        "--no-preserve-pages",
        action="store_true",
        help="Don't preserve page boundaries"
    )

    args = parser.parse_args()

    if not PYPDF_AVAILABLE:
        print("Error: pypdf library not found", file=sys.stderr)
        print("Install with: pip install pypdf", file=sys.stderr)
        sys.exit(1)

    try:
        # Create chunker
        chunker = PDFChunker(
            chunk_size=args.chunk_size,
            preserve_pages=not args.no_preserve_pages,
            merge_pages=args.merge_pages
        )

        # Chunk PDF
        chunks = chunker.chunk(args.input)

        # Prepare output
        output = {
            "chunks": chunks,
            "total_chunks": len(chunks),
            "strategy": "pdf",
            "config": {
                "chunk_size": args.chunk_size,
                "preserve_pages": not args.no_preserve_pages,
                "merge_pages": args.merge_pages
            }
        }

        # Write output
        output_json = json.dumps(output, indent=2, ensure_ascii=False)

        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(output_json)
            print(f"✓ Extracted {chunks[0]['metadata']['total_pages']} pages")
            print(f"✓ Created {len(chunks)} chunks")
            print(f"✓ Output written to {args.output}")
        else:
            print(output_json)

    except FileNotFoundError:
        print(f"Error: File '{args.input}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
