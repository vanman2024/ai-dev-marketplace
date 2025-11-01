#!/usr/bin/env python3
"""
Table Extraction Template
Specialized table extraction with multiple strategies and fallbacks
"""

import os
from typing import List, Dict, Optional, Any, Union
from pathlib import Path
from dataclasses import dataclass
import json


@dataclass
class Table:
    """Extracted table with metadata"""
    data: List[List[str]]
    page: Optional[int] = None
    table_index: int = 0
    confidence: float = 1.0
    source: str = ""

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "data": self.data,
            "page": self.page,
            "table_index": self.table_index,
            "confidence": self.confidence,
            "source": self.source
        }

    def to_csv(self) -> str:
        """Convert to CSV format"""
        lines = []
        for row in self.data:
            # Escape commas and quotes
            escaped = [f'"{cell}"' if ',' in cell or '"' in cell else cell for cell in row]
            lines.append(",".join(escaped))
        return "\n".join(lines)

    def to_markdown(self) -> str:
        """Convert to Markdown table"""
        if not self.data:
            return ""

        lines = []

        # Header row
        lines.append("| " + " | ".join(self.data[0]) + " |")
        lines.append("| " + " | ".join(["---"] * len(self.data[0])) + " |")

        # Data rows
        for row in self.data[1:]:
            lines.append("| " + " | ".join(row) + " |")

        return "\n".join(lines)

    def to_json(self) -> str:
        """Convert to JSON format"""
        if not self.data or len(self.data) < 2:
            return json.dumps(self.data)

        # Use first row as headers
        headers = self.data[0]
        rows = []

        for row_data in self.data[1:]:
            row_dict = {}
            for i, header in enumerate(headers):
                row_dict[header] = row_data[i] if i < len(row_data) else ""
            rows.append(row_dict)

        return json.dumps(rows, indent=2)

    def to_dataframe(self):
        """Convert to pandas DataFrame (requires pandas)"""
        try:
            import pandas as pd

            if not self.data or len(self.data) < 2:
                return pd.DataFrame()

            return pd.DataFrame(self.data[1:], columns=self.data[0])
        except ImportError:
            raise ImportError("pandas is required for DataFrame conversion. Run: pip install pandas")


class TableExtractor:
    """
    Multi-strategy table extraction from documents

    Supports:
    - LlamaParse (AI-powered, most accurate)
    - PDFPlumber (coordinate-based, good for PDFs)
    - python-docx (for Word documents)
    - Unstructured.io (multi-format)

    Features:
    - Automatic strategy selection
    - Fallback mechanisms
    - Table validation
    - Format conversion
    """

    def __init__(
        self,
        llamaparse_api_key: Optional[str] = None,
        prefer_llamaparse: bool = True,
        fallback_to_pdfplumber: bool = True,
        min_confidence: float = 0.5
    ):
        """
        Initialize table extractor

        Args:
            llamaparse_api_key: API key for LlamaParse
            prefer_llamaparse: Try LlamaParse first if available
            fallback_to_pdfplumber: Fall back to PDFPlumber if primary fails
            min_confidence: Minimum confidence threshold for tables
        """
        self.llamaparse_api_key = llamaparse_api_key or os.getenv("LLAMA_CLOUD_API_KEY")
        self.prefer_llamaparse = prefer_llamaparse and self.llamaparse_api_key
        self.fallback_to_pdfplumber = fallback_to_pdfplumber
        self.min_confidence = min_confidence

    def extract_tables(
        self,
        filepath: Union[str, Path],
        page_range: Optional[tuple] = None
    ) -> List[Table]:
        """
        Extract all tables from document

        Args:
            filepath: Path to document (PDF, DOCX)
            page_range: Tuple of (start_page, end_page) or None for all pages

        Returns:
            List of Table objects
        """
        filepath = str(filepath)

        if not os.path.exists(filepath):
            raise FileNotFoundError(f"File not found: {filepath}")

        # Detect format
        ext = Path(filepath).suffix.lower()

        if ext == '.pdf':
            return self._extract_from_pdf(filepath, page_range)
        elif ext == '.docx':
            return self._extract_from_docx(filepath)
        else:
            raise ValueError(f"Unsupported format: {ext}")

    def _extract_from_pdf(
        self,
        filepath: str,
        page_range: Optional[tuple] = None
    ) -> List[Table]:
        """Extract tables from PDF"""

        # Strategy 1: LlamaParse (if available and preferred)
        if self.prefer_llamaparse and self.llamaparse_api_key:
            try:
                tables = self._extract_with_llamaparse(filepath)
                if tables:
                    print(f"✓ Extracted {len(tables)} tables with LlamaParse")
                    return tables
            except Exception as e:
                print(f"LlamaParse failed: {e}")

        # Strategy 2: PDFPlumber (fallback)
        if self.fallback_to_pdfplumber:
            try:
                tables = self._extract_with_pdfplumber(filepath, page_range)
                if tables:
                    print(f"✓ Extracted {len(tables)} tables with PDFPlumber")
                    return tables
            except Exception as e:
                print(f"PDFPlumber failed: {e}")

        # Strategy 3: Unstructured.io (final fallback)
        try:
            tables = self._extract_with_unstructured(filepath)
            if tables:
                print(f"✓ Extracted {len(tables)} tables with Unstructured.io")
                return tables
        except Exception as e:
            print(f"Unstructured.io failed: {e}")

        return []

    def _extract_from_docx(self, filepath: str) -> List[Table]:
        """Extract tables from DOCX"""
        try:
            from docx import Document

            doc = Document(filepath)
            tables = []

            for table_idx, table in enumerate(doc.tables):
                table_data = []
                for row in table.rows:
                    row_data = [cell.text.strip() for cell in row.cells]
                    table_data.append(row_data)

                if table_data and self._validate_table(table_data):
                    tables.append(Table(
                        data=table_data,
                        table_index=table_idx,
                        confidence=1.0,
                        source="python-docx"
                    ))

            return tables

        except ImportError:
            raise ImportError("python-docx not installed. Run: pip install python-docx")

    def _extract_with_llamaparse(self, filepath: str) -> List[Table]:
        """Extract tables using LlamaParse"""
        from llama_parse import LlamaParse

        parser = LlamaParse(
            api_key=self.llamaparse_api_key,
            result_type="markdown",
            verbose=False
        )

        documents = parser.load_data(filepath)
        tables = []

        # Parse markdown tables from result
        for doc in documents:
            markdown_tables = self._parse_markdown_tables(doc.text)
            for idx, table_data in enumerate(markdown_tables):
                if self._validate_table(table_data):
                    tables.append(Table(
                        data=table_data,
                        table_index=idx,
                        confidence=0.95,  # High confidence for LlamaParse
                        source="llamaparse"
                    ))

        return tables

    def _extract_with_pdfplumber(
        self,
        filepath: str,
        page_range: Optional[tuple] = None
    ) -> List[Table]:
        """Extract tables using PDFPlumber"""
        import pdfplumber

        tables = []

        with pdfplumber.open(filepath) as pdf:
            start_page = page_range[0] if page_range else 0
            end_page = page_range[1] if page_range else len(pdf.pages)

            table_idx = 0
            for i in range(start_page, min(end_page, len(pdf.pages))):
                page = pdf.pages[i]
                page_tables = page.extract_tables()

                for table_data in page_tables:
                    if table_data and self._validate_table(table_data):
                        tables.append(Table(
                            data=table_data,
                            page=i + 1,
                            table_index=table_idx,
                            confidence=0.85,  # Good confidence for PDFPlumber
                            source="pdfplumber"
                        ))
                        table_idx += 1

        return tables

    def _extract_with_unstructured(self, filepath: str) -> List[Table]:
        """Extract tables using Unstructured.io"""
        from unstructured.partition.auto import partition

        elements = partition(filepath)
        tables = []
        table_idx = 0

        for element in elements:
            if element.category == "Table":
                # Parse table from text representation
                table_data = self._parse_text_table(element.text)
                if table_data and self._validate_table(table_data):
                    tables.append(Table(
                        data=table_data,
                        table_index=table_idx,
                        confidence=0.75,  # Moderate confidence
                        source="unstructured"
                    ))
                    table_idx += 1

        return tables

    def _parse_markdown_tables(self, text: str) -> List[List[List[str]]]:
        """Parse markdown tables from text"""
        tables = []
        current_table = []
        in_table = False

        for line in text.split("\n"):
            line = line.strip()

            # Check if line is part of markdown table
            if "|" in line:
                # Skip separator lines (e.g., | --- | --- |)
                if set(line.replace("|", "").replace("-", "").replace(" ", "")) == set():
                    continue

                # Extract cells
                cells = [cell.strip() for cell in line.split("|")]
                # Remove empty cells from start/end
                cells = [c for c in cells if c]

                current_table.append(cells)
                in_table = True
            elif in_table:
                # End of table
                if current_table:
                    tables.append(current_table)
                    current_table = []
                in_table = False

        # Add last table if exists
        if current_table:
            tables.append(current_table)

        return tables

    def _parse_text_table(self, text: str) -> List[List[str]]:
        """Parse table from plain text representation"""
        # Simple implementation - split by lines and tabs/spaces
        lines = text.strip().split("\n")
        table_data = []

        for line in lines:
            # Try tab-separated first
            if "\t" in line:
                cells = [cell.strip() for cell in line.split("\t")]
            else:
                # Try multiple spaces
                cells = [cell.strip() for cell in line.split("  ") if cell.strip()]

            if cells:
                table_data.append(cells)

        return table_data

    def _validate_table(self, table_data: List[List[str]]) -> bool:
        """
        Validate table structure

        Checks:
        - Has at least 2 rows (header + data)
        - Has at least 2 columns
        - Rows have consistent column counts
        """
        if not table_data or len(table_data) < 2:
            return False

        # Check minimum columns
        if not table_data[0] or len(table_data[0]) < 2:
            return False

        # Check consistent column count (allow some variation)
        col_counts = [len(row) for row in table_data]
        if max(col_counts) - min(col_counts) > 2:  # Allow 2 column variation
            return False

        return True


# Example usage
if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python table-extraction.py <file.pdf>")
        sys.exit(1)

    filepath = sys.argv[1]

    # Initialize extractor
    extractor = TableExtractor(
        prefer_llamaparse=True,
        fallback_to_pdfplumber=True
    )

    # Extract tables
    print(f"Extracting tables from: {filepath}")
    tables = extractor.extract_tables(filepath)

    print(f"\nFound {len(tables)} tables:")
    for table in tables:
        print(f"\nTable {table.table_index + 1} (Page {table.page}, Confidence: {table.confidence}, Source: {table.source}):")
        print(table.to_markdown())
        print()

    # Export tables
    for idx, table in enumerate(tables):
        # Save as CSV
        with open(f"table_{idx + 1}.csv", "w") as f:
            f.write(table.to_csv())

        # Save as JSON
        with open(f"table_{idx + 1}.json", "w") as f:
            f.write(table.to_json())

    print(f"Exported {len(tables)} tables to CSV and JSON")
