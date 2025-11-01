#!/usr/bin/env python3
"""
Functional PDF parser with multiple backend support
Supports: PyPDF2, PDFPlumber, LlamaParse
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any


class PDFParser:
    """Multi-backend PDF parser"""

    def __init__(self, backend: str = "pypdf2", api_key: Optional[str] = None):
        self.backend = backend.lower()
        self.api_key = api_key or os.getenv("LLAMA_CLOUD_API_KEY")
        self._validate_backend()

    def _validate_backend(self):
        """Validate backend is available"""
        if self.backend == "pypdf2":
            try:
                import PyPDF2
            except ImportError:
                print("Error: PyPDF2 not installed. Run: pip install pypdf2")
                sys.exit(1)

        elif self.backend == "pdfplumber":
            try:
                import pdfplumber
            except ImportError:
                print("Error: pdfplumber not installed. Run: pip install pdfplumber")
                sys.exit(1)

        elif self.backend == "llamaparse":
            try:
                from llama_parse import LlamaParse
            except ImportError:
                print("Error: llama-parse not installed. Run: ./scripts/setup-llamaparse.sh")
                sys.exit(1)

            if not self.api_key:
                print("Error: LlamaParse requires API key")
                print("Set LLAMA_CLOUD_API_KEY environment variable or use --api-key")
                sys.exit(1)

        else:
            print(f"Error: Unknown backend '{self.backend}'")
            print("Available backends: pypdf2, pdfplumber, llamaparse")
            sys.exit(1)

    def parse(
        self,
        filepath: str,
        extract_tables: bool = False,
        extract_metadata: bool = True,
        page_range: Optional[tuple] = None
    ) -> Dict[str, Any]:
        """
        Parse PDF file

        Args:
            filepath: Path to PDF file
            extract_tables: Extract tables from PDF
            extract_metadata: Extract document metadata
            page_range: Tuple of (start_page, end_page) or None for all pages

        Returns:
            Dictionary with text, tables, and metadata
        """
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")

        if self.backend == "pypdf2":
            return self._parse_pypdf2(filepath, extract_metadata, page_range)
        elif self.backend == "pdfplumber":
            return self._parse_pdfplumber(filepath, extract_tables, extract_metadata, page_range)
        elif self.backend == "llamaparse":
            return self._parse_llamaparse(filepath, extract_metadata)

    def _parse_pypdf2(
        self,
        filepath: str,
        extract_metadata: bool,
        page_range: Optional[tuple]
    ) -> Dict[str, Any]:
        """Parse using PyPDF2"""
        from PyPDF2 import PdfReader

        reader = PdfReader(filepath)
        result = {
            "backend": "pypdf2",
            "filepath": filepath,
            "text": "",
            "pages": [],
            "metadata": {},
            "tables": []
        }

        # Extract metadata
        if extract_metadata and reader.metadata:
            result["metadata"] = {
                "title": reader.metadata.get("/Title", ""),
                "author": reader.metadata.get("/Author", ""),
                "subject": reader.metadata.get("/Subject", ""),
                "creator": reader.metadata.get("/Creator", ""),
                "producer": reader.metadata.get("/Producer", ""),
                "creation_date": str(reader.metadata.get("/CreationDate", "")),
            }

        # Determine page range
        start_page = page_range[0] if page_range else 0
        end_page = page_range[1] if page_range else len(reader.pages)

        # Extract text from pages
        for i in range(start_page, min(end_page, len(reader.pages))):
            page = reader.pages[i]
            page_text = page.extract_text()
            result["pages"].append({
                "page_number": i + 1,
                "text": page_text
            })
            result["text"] += page_text + "\n\n"

        result["total_pages"] = len(reader.pages)
        return result

    def _parse_pdfplumber(
        self,
        filepath: str,
        extract_tables: bool,
        extract_metadata: bool,
        page_range: Optional[tuple]
    ) -> Dict[str, Any]:
        """Parse using PDFPlumber"""
        import pdfplumber

        result = {
            "backend": "pdfplumber",
            "filepath": filepath,
            "text": "",
            "pages": [],
            "metadata": {},
            "tables": []
        }

        with pdfplumber.open(filepath) as pdf:
            # Extract metadata
            if extract_metadata and pdf.metadata:
                result["metadata"] = {
                    k.replace("/", ""): v for k, v in pdf.metadata.items()
                }

            # Determine page range
            start_page = page_range[0] if page_range else 0
            end_page = page_range[1] if page_range else len(pdf.pages)

            # Extract text and tables from pages
            for i in range(start_page, min(end_page, len(pdf.pages))):
                page = pdf.pages[i]
                page_text = page.extract_text() or ""

                page_data = {
                    "page_number": i + 1,
                    "text": page_text
                }

                # Extract tables if requested
                if extract_tables:
                    tables = page.extract_tables()
                    if tables:
                        page_data["tables"] = tables
                        result["tables"].extend([
                            {
                                "page": i + 1,
                                "table_index": idx,
                                "data": table
                            }
                            for idx, table in enumerate(tables)
                        ])

                result["pages"].append(page_data)
                result["text"] += page_text + "\n\n"

            result["total_pages"] = len(pdf.pages)

        return result

    def _parse_llamaparse(
        self,
        filepath: str,
        extract_metadata: bool
    ) -> Dict[str, Any]:
        """Parse using LlamaParse"""
        from llama_parse import LlamaParse

        parser = LlamaParse(
            api_key=self.api_key,
            result_type="markdown",
            verbose=False
        )

        result = {
            "backend": "llamaparse",
            "filepath": filepath,
            "text": "",
            "pages": [],
            "metadata": {},
            "tables": []
        }

        # Parse document
        documents = parser.load_data(filepath)

        # Combine all document text
        for doc in documents:
            result["text"] += doc.text + "\n\n"

        # Extract metadata if available
        if extract_metadata and documents:
            result["metadata"] = documents[0].metadata if hasattr(documents[0], 'metadata') else {}

        return result


def main():
    parser = argparse.ArgumentParser(
        description="Parse PDF files with multiple backend support"
    )
    parser.add_argument(
        "filepath",
        help="Path to PDF file"
    )
    parser.add_argument(
        "--backend",
        choices=["pypdf2", "pdfplumber", "llamaparse"],
        default="pypdf2",
        help="Parser backend to use (default: pypdf2)"
    )
    parser.add_argument(
        "--api-key",
        help="LlamaParse API key (for llamaparse backend)"
    )
    parser.add_argument(
        "--tables",
        action="store_true",
        help="Extract tables from PDF (pdfplumber only)"
    )
    parser.add_argument(
        "--tables-only",
        action="store_true",
        help="Extract only tables, skip text"
    )
    parser.add_argument(
        "--no-metadata",
        action="store_true",
        help="Skip metadata extraction"
    )
    parser.add_argument(
        "--pages",
        help="Page range to extract (e.g., '1-5' or '3-')"
    )
    parser.add_argument(
        "--output",
        help="Output file path (default: stdout)"
    )
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)"
    )

    args = parser.parse_args()

    # Parse page range
    page_range = None
    if args.pages:
        if "-" in args.pages:
            parts = args.pages.split("-")
            start = int(parts[0]) - 1 if parts[0] else 0
            end = int(parts[1]) if parts[1] else None
            page_range = (start, end)
        else:
            page_num = int(args.pages) - 1
            page_range = (page_num, page_num + 1)

    # Parse PDF
    try:
        pdf_parser = PDFParser(backend=args.backend, api_key=args.api_key)
        result = pdf_parser.parse(
            args.filepath,
            extract_tables=args.tables or args.tables_only,
            extract_metadata=not args.no_metadata,
            page_range=page_range
        )

        # Format output
        if args.format == "json":
            output = json.dumps(result, indent=2, ensure_ascii=False)
        else:
            if args.tables_only:
                # Output only tables
                if result["tables"]:
                    output = f"Found {len(result['tables'])} tables:\n\n"
                    for table_info in result["tables"]:
                        output += f"Page {table_info['page']}, Table {table_info['table_index'] + 1}:\n"
                        for row in table_info['data']:
                            output += " | ".join(str(cell) for cell in row) + "\n"
                        output += "\n"
                else:
                    output = "No tables found in document"
            else:
                # Output text
                output = result["text"]
                if result.get("metadata") and not args.no_metadata:
                    output = f"=== Metadata ===\n{json.dumps(result['metadata'], indent=2)}\n\n=== Content ===\n{output}"

        # Write output
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output)
            print(f"Output written to: {args.output}")
        else:
            print(output)

    except Exception as e:
        print(f"Error parsing PDF: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
