#!/usr/bin/env python3
"""
Functional HTML parser for clean text extraction
Supports local files and URLs
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any


class HTMLParser:
    """HTML to clean text parser"""

    def __init__(self):
        try:
            from bs4 import BeautifulSoup
            import requests
            self.BeautifulSoup = BeautifulSoup
            self.requests = requests
        except ImportError as e:
            print(f"Error: Required package not installed: {e}")
            print("Run: pip install beautifulsoup4 lxml requests")
            sys.exit(1)

    def parse(
        self,
        source: str,
        preserve_links: bool = False,
        selector: Optional[str] = None,
        remove_scripts: bool = True,
        remove_styles: bool = True
    ) -> Dict[str, Any]:
        """
        Parse HTML from file or URL

        Args:
            source: File path or URL
            preserve_links: Keep link URLs in output
            selector: CSS selector to extract specific element
            remove_scripts: Remove script tags
            remove_styles: Remove style tags

        Returns:
            Dictionary with text and metadata
        """
        # Load HTML content
        if source.startswith("http://") or source.startswith("https://"):
            html_content = self._fetch_url(source)
            source_type = "url"
        else:
            html_content = self._read_file(source)
            source_type = "file"

        # Parse HTML
        soup = self.BeautifulSoup(html_content, "lxml")

        result = {
            "source": source,
            "source_type": source_type,
            "text": "",
            "links": [],
            "metadata": {}
        }

        # Extract metadata
        result["metadata"] = self._extract_metadata(soup)

        # Remove unwanted elements
        if remove_scripts:
            for script in soup(["script", "noscript"]):
                script.decompose()

        if remove_styles:
            for style in soup(["style"]):
                style.decompose()

        # Apply selector if provided
        if selector:
            selected = soup.select(selector)
            if not selected:
                print(f"Warning: Selector '{selector}' matched no elements", file=sys.stderr)
                soup = self.BeautifulSoup("", "lxml")
            else:
                # Create new soup with selected elements
                soup = self.BeautifulSoup(
                    "".join(str(el) for el in selected),
                    "lxml"
                )

        # Extract links if requested
        if preserve_links:
            for link in soup.find_all("a", href=True):
                result["links"].append({
                    "text": link.get_text(strip=True),
                    "href": link["href"]
                })

        # Extract clean text
        result["text"] = soup.get_text(separator="\n", strip=True)

        # Clean up extra whitespace
        lines = result["text"].split("\n")
        cleaned_lines = [line.strip() for line in lines if line.strip()]
        result["text"] = "\n".join(cleaned_lines)

        return result

    def _fetch_url(self, url: str) -> str:
        """Fetch HTML from URL"""
        try:
            response = self.requests.get(url, timeout=30)
            response.raise_for_status()
            return response.text
        except Exception as e:
            print(f"Error fetching URL: {e}", file=sys.stderr)
            sys.exit(1)

    def _read_file(self, filepath: str) -> str:
        """Read HTML from file"""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                return f.read()
        except FileNotFoundError:
            print(f"Error: File not found: {filepath}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error reading file: {e}", file=sys.stderr)
            sys.exit(1)

    def _extract_metadata(self, soup) -> Dict[str, str]:
        """Extract metadata from HTML"""
        metadata = {}

        # Title
        if soup.title:
            metadata["title"] = soup.title.string.strip()

        # Meta tags
        for meta in soup.find_all("meta"):
            name = meta.get("name") or meta.get("property")
            content = meta.get("content")

            if name and content:
                # Common metadata fields
                if name in ["description", "keywords", "author"]:
                    metadata[name] = content
                # Open Graph
                elif name.startswith("og:"):
                    metadata[name] = content
                # Twitter Card
                elif name.startswith("twitter:"):
                    metadata[name] = content

        return metadata


def format_text_output(result: Dict[str, Any], include_links: bool = False) -> str:
    """Format result as plain text"""
    output = ""

    # Add metadata
    if result.get("metadata"):
        metadata = result["metadata"]
        if metadata:
            output += "=== Metadata ===\n"
            for key, value in metadata.items():
                output += f"{key}: {value}\n"
            output += "\n"

    # Add content
    output += "=== Content ===\n"
    output += result["text"] + "\n"

    # Add links
    if include_links and result.get("links"):
        output += "\n=== Links ===\n"
        for link in result["links"]:
            output += f"[{link['text']}] {link['href']}\n"

    return output


def format_markdown_output(result: Dict[str, Any]) -> str:
    """Format result as Markdown"""
    output = ""

    # Add metadata
    if result.get("metadata") and result["metadata"].get("title"):
        output += f"# {result['metadata']['title']}\n\n"

        if result["metadata"].get("author"):
            output += f"**Author:** {result['metadata']['author']}  \n"
        if result["metadata"].get("description"):
            output += f"**Description:** {result['metadata']['description']}  \n"
        output += "\n"

    # Add content
    output += result["text"] + "\n"

    # Add links as markdown
    if result.get("links"):
        output += "\n## Links\n\n"
        for link in result["links"]:
            text = link["text"] or link["href"]
            output += f"- [{text}]({link['href']})\n"

    return output


def main():
    parser = argparse.ArgumentParser(
        description="Parse HTML to clean text from files or URLs"
    )
    parser.add_argument(
        "source",
        help="HTML file path or URL"
    )
    parser.add_argument(
        "--preserve-links",
        action="store_true",
        help="Preserve links in output"
    )
    parser.add_argument(
        "--selector",
        help="CSS selector to extract specific element (e.g., 'article.content')"
    )
    parser.add_argument(
        "--keep-scripts",
        action="store_true",
        help="Keep script tags (default: remove)"
    )
    parser.add_argument(
        "--keep-styles",
        action="store_true",
        help="Keep style tags (default: remove)"
    )
    parser.add_argument(
        "--output",
        help="Output file path (default: stdout)"
    )
    parser.add_argument(
        "--format",
        choices=["text", "json", "markdown"],
        default="text",
        help="Output format (default: text)"
    )

    args = parser.parse_args()

    # Parse HTML
    try:
        html_parser = HTMLParser()
        result = html_parser.parse(
            args.source,
            preserve_links=args.preserve_links,
            selector=args.selector,
            remove_scripts=not args.keep_scripts,
            remove_styles=not args.keep_styles
        )

        # Format output
        if args.format == "json":
            output = json.dumps(result, indent=2, ensure_ascii=False)
        elif args.format == "markdown":
            output = format_markdown_output(result)
        else:
            output = format_text_output(result, include_links=args.preserve_links)

        # Write output
        if args.output:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output)
            print(f"Output written to: {args.output}")
        else:
            print(output)

    except Exception as e:
        print(f"Error parsing HTML: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
