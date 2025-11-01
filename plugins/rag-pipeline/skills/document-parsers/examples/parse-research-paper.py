#!/usr/bin/env python3
"""
Research Paper Parser Example
Extracts structured information from academic papers
"""

import sys
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict


@dataclass
class ResearchPaper:
    """Structured research paper data"""
    filepath: str
    title: str = ""
    authors: List[str] = None
    abstract: str = ""
    sections: Dict[str, str] = None
    citations: List[str] = None
    tables: List[Dict] = None
    figures: List[Dict] = None
    metadata: Dict[str, Any] = None

    def __post_init__(self):
        if self.authors is None:
            self.authors = []
        if self.sections is None:
            self.sections = {}
        if self.citations is None:
            self.citations = []
        if self.tables is None:
            self.tables = []
        if self.figures is None:
            self.figures = []
        if self.metadata is None:
            self.metadata = {}

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return asdict(self)

    def to_json(self, indent: int = 2) -> str:
        """Convert to JSON"""
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)


class ResearchPaperParser:
    """
    Parser for academic research papers

    Extracts:
    - Title and authors
    - Abstract
    - Section structure (Introduction, Methods, Results, Discussion, Conclusion)
    - Citations and references
    - Tables and figures with captions
    - Metadata (DOI, publication date, journal)
    """

    # Common section headers in research papers
    SECTION_PATTERNS = [
        r'\b(?:I+\.?\s+)?Introduction\b',
        r'\b(?:I+\.?\s+)?Background\b',
        r'\b(?:I+\.?\s+)?Related Work\b',
        r'\b(?:I+\.?\s+)?Literature Review\b',
        r'\b(?:I+\.?\s+)?Methods?\b',
        r'\b(?:I+\.?\s+)?Methodology\b',
        r'\b(?:I+\.?\s+)?Approach\b',
        r'\b(?:I+\.?\s+)?Materials and Methods\b',
        r'\b(?:I+\.?\s+)?Experimental Setup\b',
        r'\b(?:I+\.?\s+)?Results?\b',
        r'\b(?:I+\.?\s+)?Findings\b',
        r'\b(?:I+\.?\s+)?Discussion\b',
        r'\b(?:I+\.?\s+)?Analysis\b',
        r'\b(?:I+\.?\s+)?Conclusion\b',
        r'\b(?:I+\.?\s+)?Future Work\b',
        r'\b(?:I+\.?\s+)?References?\b',
        r'\b(?:I+\.?\s+)?Bibliography\b',
    ]

    def __init__(self, use_llamaparse: bool = False, api_key: Optional[str] = None):
        """
        Initialize parser

        Args:
            use_llamaparse: Use LlamaParse for better accuracy
            api_key: LlamaParse API key
        """
        self.use_llamaparse = use_llamaparse
        self.api_key = api_key

    def parse(self, filepath: str) -> ResearchPaper:
        """
        Parse research paper

        Args:
            filepath: Path to PDF file

        Returns:
            ResearchPaper object with extracted data
        """
        # Import parser based on strategy
        if self.use_llamaparse and self.api_key:
            return self._parse_with_llamaparse(filepath)
        else:
            return self._parse_with_local(filepath)

    def _parse_with_llamaparse(self, filepath: str) -> ResearchPaper:
        """Parse using LlamaParse (AI-powered)"""
        try:
            from llama_parse import LlamaParse

            parser = LlamaParse(
                api_key=self.api_key,
                result_type="markdown",
                verbose=False
            )

            documents = parser.load_data(filepath)
            text = "\n\n".join(doc.text for doc in documents)

            return self._extract_structure(filepath, text)

        except ImportError:
            print("Error: LlamaParse not installed. Run: pip install llama-parse")
            sys.exit(1)

    def _parse_with_local(self, filepath: str) -> ResearchPaper:
        """Parse using local PDF parser"""
        try:
            import pdfplumber

            text_parts = []
            tables = []

            with pdfplumber.open(filepath) as pdf:
                for page_num, page in enumerate(pdf.pages, 1):
                    # Extract text
                    page_text = page.extract_text() or ""
                    text_parts.append(page_text)

                    # Extract tables
                    page_tables = page.extract_tables()
                    for table_idx, table_data in enumerate(page_tables):
                        tables.append({
                            "page": page_num,
                            "table_index": table_idx + 1,
                            "data": table_data,
                            "caption": self._extract_table_caption(page_text, table_idx)
                        })

            text = "\n\n".join(text_parts)
            paper = self._extract_structure(filepath, text)
            paper.tables = tables

            return paper

        except ImportError:
            print("Error: pdfplumber not installed. Run: pip install pdfplumber")
            sys.exit(1)

    def _extract_structure(self, filepath: str, text: str) -> ResearchPaper:
        """Extract paper structure from text"""
        paper = ResearchPaper(filepath=filepath)

        # Extract title (usually first significant text)
        paper.title = self._extract_title(text)

        # Extract authors
        paper.authors = self._extract_authors(text)

        # Extract abstract
        paper.abstract = self._extract_abstract(text)

        # Extract sections
        paper.sections = self._extract_sections(text)

        # Extract citations
        paper.citations = self._extract_citations(text)

        # Extract figures
        paper.figures = self._extract_figures(text)

        # Extract metadata
        paper.metadata = self._extract_metadata(text)

        return paper

    def _extract_title(self, text: str) -> str:
        """Extract paper title"""
        lines = text.split("\n")

        # Title is typically in first few lines, all caps or title case
        for i, line in enumerate(lines[:10]):
            line = line.strip()
            if len(line) > 20 and len(line) < 200:
                # Check if it looks like a title (not abstract, not author line)
                if not line.lower().startswith(('abstract', 'author', 'email', 'department')):
                    return line

        return ""

    def _extract_authors(self, text: str) -> List[str]:
        """Extract author names"""
        authors = []

        # Look for author patterns in first page
        first_page = "\n".join(text.split("\n")[:50])

        # Pattern: Name (possibly with initials), possibly with affiliations
        author_patterns = [
            r'([A-Z][a-z]+ [A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)',  # First Middle Last
            r'([A-Z]\.\s*[A-Z]\.\s*[A-Z][a-z]+)',  # F. M. Last
        ]

        for pattern in author_patterns:
            matches = re.findall(pattern, first_page)
            authors.extend(matches)

        # Remove duplicates while preserving order
        seen = set()
        unique_authors = []
        for author in authors:
            if author not in seen:
                seen.add(author)
                unique_authors.append(author)

        return unique_authors[:10]  # Limit to 10 authors

    def _extract_abstract(self, text: str) -> str:
        """Extract abstract"""
        # Find abstract section
        abstract_pattern = r'(?i)abstract\s*[:\-]?\s*(.*?)(?=\n\s*(?:introduction|keywords|1\.|I\.|\Z))'
        match = re.search(abstract_pattern, text, re.DOTALL | re.IGNORECASE)

        if match:
            abstract = match.group(1).strip()
            # Clean up
            abstract = re.sub(r'\s+', ' ', abstract)
            return abstract

        return ""

    def _extract_sections(self, text: str) -> Dict[str, str]:
        """Extract paper sections"""
        sections = {}

        # Find all section headers
        section_positions = []
        for pattern in self.SECTION_PATTERNS:
            for match in re.finditer(pattern, text, re.IGNORECASE):
                section_name = match.group(0).strip()
                section_name = re.sub(r'^[IVX]+\.?\s*', '', section_name)  # Remove numbering
                section_positions.append((match.start(), section_name))

        # Sort by position
        section_positions.sort()

        # Extract text for each section
        for i, (start, name) in enumerate(section_positions):
            # Find end of section (start of next section or end of text)
            if i < len(section_positions) - 1:
                end = section_positions[i + 1][0]
            else:
                end = len(text)

            section_text = text[start:end].strip()

            # Remove section header from text
            section_text = re.sub(r'^' + re.escape(name) + r'\s*', '', section_text, flags=re.IGNORECASE)

            # Clean up
            section_text = re.sub(r'\s+', ' ', section_text)

            sections[name] = section_text[:5000]  # Limit section length

        return sections

    def _extract_citations(self, text: str) -> List[str]:
        """Extract citations/references"""
        citations = []

        # Find references section
        ref_pattern = r'(?i)references?\s*[:\-]?\s*(.*?)(?=\Z)'
        match = re.search(ref_pattern, text, re.DOTALL)

        if match:
            ref_section = match.group(1)

            # Pattern for citations (numbered or author-year)
            citation_patterns = [
                r'\[\d+\]\s*([^\[\]]+?)(?=\[\d+\]|\Z)',  # [1] Author et al...
                r'\d+\.\s*([^\n]+)',  # 1. Author et al...
            ]

            for pattern in citation_patterns:
                matches = re.findall(pattern, ref_section)
                citations.extend([m.strip() for m in matches if len(m.strip()) > 20])

        return citations[:100]  # Limit to 100 citations

    def _extract_figures(self, text: str) -> List[Dict]:
        """Extract figure references and captions"""
        figures = []

        # Pattern for figure captions
        fig_pattern = r'(?i)(Figure|Fig\.?)\s+(\d+)[:\.]?\s*([^\n]+)'

        for match in re.finditer(fig_pattern, text):
            figures.append({
                "number": match.group(2),
                "caption": match.group(3).strip()
            })

        return figures

    def _extract_table_caption(self, text: str, table_idx: int) -> str:
        """Extract caption for a table"""
        # Pattern for table captions
        table_pattern = r'(?i)Table\s+(\d+)[:\.]?\s*([^\n]+)'

        matches = list(re.finditer(table_pattern, text))
        if table_idx < len(matches):
            return matches[table_idx].group(2).strip()

        return ""

    def _extract_metadata(self, text: str) -> Dict[str, str]:
        """Extract metadata (DOI, journal, etc.)"""
        metadata = {}

        # DOI
        doi_pattern = r'(?i)DOI[:\s]*(10\.\d{4,}/[^\s]+)'
        doi_match = re.search(doi_pattern, text)
        if doi_match:
            metadata["doi"] = doi_match.group(1)

        # arXiv ID
        arxiv_pattern = r'arXiv:(\d{4}\.\d{4,5})'
        arxiv_match = re.search(arxiv_pattern, text)
        if arxiv_match:
            metadata["arxiv_id"] = arxiv_match.group(1)

        # Keywords
        keywords_pattern = r'(?i)keywords?[:\-]?\s*([^\n]+)'
        keywords_match = re.search(keywords_pattern, text)
        if keywords_match:
            metadata["keywords"] = keywords_match.group(1).strip()

        return metadata


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Parse academic research papers"
    )
    parser.add_argument(
        "filepath",
        help="Path to PDF file"
    )
    parser.add_argument(
        "--llamaparse",
        action="store_true",
        help="Use LlamaParse for better accuracy"
    )
    parser.add_argument(
        "--api-key",
        help="LlamaParse API key"
    )
    parser.add_argument(
        "--output",
        help="Output JSON file (default: stdout)"
    )

    args = parser.parse_args()

    # Parse paper
    paper_parser = ResearchPaperParser(
        use_llamaparse=args.llamaparse,
        api_key=args.api_key
    )

    print(f"Parsing research paper: {args.filepath}")
    paper = paper_parser.parse(args.filepath)

    # Output results
    output = paper.to_json(indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"\nResults saved to: {args.output}")
    else:
        print("\n" + output)

    # Print summary
    print("\n=== Summary ===")
    print(f"Title: {paper.title}")
    print(f"Authors: {', '.join(paper.authors[:3])}{'...' if len(paper.authors) > 3 else ''}")
    print(f"Sections: {len(paper.sections)}")
    print(f"Citations: {len(paper.citations)}")
    print(f"Tables: {len(paper.tables)}")
    print(f"Figures: {len(paper.figures)}")


if __name__ == "__main__":
    main()
