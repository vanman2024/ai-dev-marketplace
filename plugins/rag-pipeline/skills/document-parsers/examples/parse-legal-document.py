#!/usr/bin/env python3
"""
Legal Document Parser Example
Extracts structured information from legal documents (contracts, agreements, etc.)
"""

import sys
import json
import re
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict, field
from datetime import datetime


@dataclass
class Party:
    """Party in a legal document"""
    name: str
    role: str = ""  # e.g., "Disclosing Party", "Client", "Vendor"
    address: str = ""
    email: str = ""


@dataclass
class Clause:
    """Legal clause or section"""
    number: str
    title: str
    content: str
    subsections: List['Clause'] = field(default_factory=list)


@dataclass
class LegalDocument:
    """Structured legal document data"""
    filepath: str
    document_type: str = ""  # Contract, Agreement, NDA, etc.
    title: str = ""
    parties: List[Party] = field(default_factory=list)
    effective_date: str = ""
    expiration_date: str = ""
    clauses: List[Clause] = field(default_factory=list)
    definitions: Dict[str, str] = field(default_factory=dict)
    signature_blocks: List[Dict[str, str]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return asdict(self)

    def to_json(self, indent: int = 2) -> str:
        """Convert to JSON"""
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)


class LegalDocumentParser:
    """
    Parser for legal documents

    Extracts:
    - Document type (contract, agreement, NDA, etc.)
    - Parties involved (names, roles, addresses)
    - Effective and expiration dates
    - Numbered clauses and sections
    - Definitions section
    - Signature blocks
    - Deadlines and important dates
    """

    # Common legal document types
    DOCUMENT_TYPES = [
        'Non-Disclosure Agreement',
        'Confidentiality Agreement',
        'Service Agreement',
        'Employment Agreement',
        'License Agreement',
        'Purchase Agreement',
        'Lease Agreement',
        'Settlement Agreement',
        'Merger Agreement',
        'Partnership Agreement',
        'Operating Agreement',
        'Consulting Agreement',
        'Master Service Agreement',
        'Software License Agreement',
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

    def parse(self, filepath: str) -> LegalDocument:
        """
        Parse legal document

        Args:
            filepath: Path to PDF file

        Returns:
            LegalDocument object with extracted data
        """
        # Import parser based on strategy
        if self.use_llamaparse and self.api_key:
            return self._parse_with_llamaparse(filepath)
        else:
            return self._parse_with_local(filepath)

    def _parse_with_llamaparse(self, filepath: str) -> LegalDocument:
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

    def _parse_with_local(self, filepath: str) -> LegalDocument:
        """Parse using local PDF parser"""
        try:
            import pdfplumber

            text_parts = []

            with pdfplumber.open(filepath) as pdf:
                for page in pdf.pages:
                    page_text = page.extract_text() or ""
                    text_parts.append(page_text)

            text = "\n\n".join(text_parts)
            return self._extract_structure(filepath, text)

        except ImportError:
            print("Error: pdfplumber not installed. Run: pip install pdfplumber")
            sys.exit(1)

    def _extract_structure(self, filepath: str, text: str) -> LegalDocument:
        """Extract document structure from text"""
        doc = LegalDocument(filepath=filepath)

        # Extract document type
        doc.document_type = self._extract_document_type(text)

        # Extract title
        doc.title = self._extract_title(text)

        # Extract parties
        doc.parties = self._extract_parties(text)

        # Extract dates
        doc.effective_date = self._extract_effective_date(text)
        doc.expiration_date = self._extract_expiration_date(text)

        # Extract definitions
        doc.definitions = self._extract_definitions(text)

        # Extract clauses
        doc.clauses = self._extract_clauses(text)

        # Extract signature blocks
        doc.signature_blocks = self._extract_signature_blocks(text)

        # Extract metadata
        doc.metadata = self._extract_metadata(text)

        return doc

    def _extract_document_type(self, text: str) -> str:
        """Identify document type"""
        # Check first page for document type keywords
        first_page = "\n".join(text.split("\n")[:50])

        for doc_type in self.DOCUMENT_TYPES:
            if doc_type.lower() in first_page.lower():
                return doc_type

        # Try common abbreviations
        if re.search(r'\bNDA\b', first_page, re.IGNORECASE):
            return "Non-Disclosure Agreement"
        if re.search(r'\bMSA\b', first_page, re.IGNORECASE):
            return "Master Service Agreement"

        return "Legal Agreement"

    def _extract_title(self, text: str) -> str:
        """Extract document title"""
        lines = text.split("\n")

        # Title is typically in first few lines, often in caps
        for line in lines[:10]:
            line = line.strip()
            if len(line) > 10 and len(line) < 150:
                # Check if looks like a title
                if any(keyword in line.lower() for keyword in ['agreement', 'contract', 'nda', 'license']):
                    return line

        return ""

    def _extract_parties(self, text: str) -> List[Party]:
        """Extract parties involved in the agreement"""
        parties = []

        # Pattern for party definitions
        # e.g., "between ABC Corp ('Client') and XYZ Inc ('Vendor')"
        party_pattern = r'(?:between|by and among)\s+(.+?)(?=\n|whereas|recitals|background)'

        match = re.search(party_pattern, text, re.IGNORECASE | re.DOTALL)
        if match:
            party_text = match.group(1)

            # Extract individual parties
            # Pattern: Company Name (optional "Role")
            party_regex = r'([A-Z][A-Za-z\s&,\.]+(?:Inc|LLC|Corp|Ltd|Company|Corporation)?)\s*(?:\(["\']?([^)]+)["\']?\))?'

            for match in re.finditer(party_regex, party_text):
                name = match.group(1).strip()
                role = match.group(2).strip() if match.group(2) else ""

                # Skip if name is too short or common words
                if len(name) > 5 and not name.lower() in ['this agreement', 'the parties']:
                    parties.append(Party(name=name, role=role))

        # Alternative: Look for signature blocks
        if not parties:
            sig_pattern = r'(?:Signed by|For and on behalf of)[:\s]+([A-Z][A-Za-z\s&,\.]+(?:Inc|LLC|Corp|Ltd)?)'
            for match in re.finditer(sig_pattern, text):
                name = match.group(1).strip()
                parties.append(Party(name=name))

        # Remove duplicates
        seen = set()
        unique_parties = []
        for party in parties:
            if party.name not in seen:
                seen.add(party.name)
                unique_parties.append(party)

        return unique_parties[:10]  # Limit to 10 parties

    def _extract_effective_date(self, text: str) -> str:
        """Extract effective date"""
        patterns = [
            r'(?:effective|dated|entered into)[:\s]+(?:as of\s+)?([A-Z][a-z]+\s+\d{1,2},?\s+\d{4})',
            r'(?:this\s+\d+(?:st|nd|rd|th)\s+day\s+of\s+)([A-Z][a-z]+,?\s+\d{4})',
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return ""

    def _extract_expiration_date(self, text: str) -> str:
        """Extract expiration or termination date"""
        patterns = [
            r'(?:expires?|expiration|terminat(?:e|ion))[:\s]+(?:on\s+)?([A-Z][a-z]+\s+\d{1,2},?\s+\d{4})',
            r'(?:term|duration)[:\s]+(?:of\s+)?(\d+)\s+(year|month|day)s?',
        ]

        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(0).strip()

        return ""

    def _extract_definitions(self, text: str) -> Dict[str, str]:
        """Extract definitions section"""
        definitions = {}

        # Find definitions section
        def_pattern = r'(?i)definitions?\s*[:\-]?\s*(.*?)(?=\n\s*\d+\.|ARTICLE|SECTION|\Z)'
        match = re.search(def_pattern, text, re.DOTALL)

        if match:
            def_section = match.group(1)

            # Pattern for definitions: "Term" means...
            term_pattern = r'["\']?([A-Z][A-Za-z\s]+)["\']?\s+(?:means?|shall mean|is defined as)\s+([^\.]+\.)'

            for match in re.finditer(term_pattern, def_section):
                term = match.group(1).strip()
                definition = match.group(2).strip()
                definitions[term] = definition

        return definitions

    def _extract_clauses(self, text: str) -> List[Clause]:
        """Extract numbered clauses and sections"""
        clauses = []

        # Pattern for numbered sections/clauses
        # Matches: "1.", "1.1", "Article 1", "Section 1"
        clause_patterns = [
            r'(?:^|\n)\s*(\d+(?:\.\d+)*)\.\s+([A-Z][^\n]+)\n(.*?)(?=\n\s*\d+(?:\.\d+)*\.|\Z)',
            r'(?:^|\n)\s*(?:ARTICLE|SECTION)\s+(\d+)\.\s+([A-Z][^\n]+)\n(.*?)(?=\n\s*(?:ARTICLE|SECTION)\s+\d+\.|\Z)',
        ]

        for pattern in clause_patterns:
            for match in re.finditer(pattern, text, re.DOTALL | re.MULTILINE):
                number = match.group(1)
                title = match.group(2).strip()
                content = match.group(3).strip()

                # Clean up content
                content = re.sub(r'\s+', ' ', content)[:2000]  # Limit length

                clauses.append(Clause(
                    number=number,
                    title=title,
                    content=content
                ))

        return clauses[:50]  # Limit to 50 clauses

    def _extract_signature_blocks(self, text: str) -> List[Dict[str, str]]:
        """Extract signature blocks"""
        signatures = []

        # Find signature section (usually at end)
        sig_section_pattern = r'(?i)(?:IN WITNESS WHEREOF|EXECUTED|SIGNED)(.*?)$'
        match = re.search(sig_section_pattern, text, re.DOTALL)

        if match:
            sig_section = match.group(1)

            # Pattern for signature blocks
            sig_pattern = r'(?:By|Signed by|For)[:\s]+_+\s*\n\s*(?:Name|Print Name)[:\s]+([^\n]+)\n\s*(?:Title|Position)[:\s]+([^\n]+)'

            for match in re.finditer(sig_pattern, sig_section):
                signatures.append({
                    "name": match.group(1).strip(),
                    "title": match.group(2).strip()
                })

        return signatures

    def _extract_metadata(self, text: str) -> Dict[str, Any]:
        """Extract additional metadata"""
        metadata = {}

        # Extract jurisdiction/governing law
        jurisdiction_pattern = r'(?i)(?:governed by|jurisdiction|governing law)[:\s]+(?:the laws of\s+)?([A-Z][A-Za-z\s,]+)'
        match = re.search(jurisdiction_pattern, text)
        if match:
            metadata["jurisdiction"] = match.group(1).strip()

        # Extract notice addresses
        notice_pattern = r'(?i)notice[s]?[:\s]+(?:to|at)[:\s]+([^\n]+)'
        matches = re.findall(notice_pattern, text)
        if matches:
            metadata["notice_addresses"] = [m.strip() for m in matches[:5]]

        # Count pages (approximate)
        page_breaks = text.count("\f") + text.count("Page ")
        if page_breaks > 0:
            metadata["estimated_pages"] = page_breaks

        return metadata


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Parse legal documents (contracts, agreements, etc.)"
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

    # Parse document
    legal_parser = LegalDocumentParser(
        use_llamaparse=args.llamaparse,
        api_key=args.api_key
    )

    print(f"Parsing legal document: {args.filepath}")
    document = legal_parser.parse(args.filepath)

    # Output results
    output = document.to_json(indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"\nResults saved to: {args.output}")
    else:
        print("\n" + output)

    # Print summary
    print("\n=== Summary ===")
    print(f"Document Type: {document.document_type}")
    print(f"Title: {document.title}")
    print(f"Parties: {len(document.parties)}")
    for party in document.parties:
        print(f"  - {party.name} ({party.role})" if party.role else f"  - {party.name}")
    print(f"Effective Date: {document.effective_date}")
    print(f"Clauses: {len(document.clauses)}")
    print(f"Definitions: {len(document.definitions)}")
    print(f"Signatures: {len(document.signature_blocks)}")


if __name__ == "__main__":
    main()
