#!/usr/bin/env python3
"""
GitHub Documentation Scraper

Scrapes README, Wiki, and Docs folder from GitHub repositories

Features:
- Scrapes repository documentation
- Downloads README and Wiki pages
- Extracts code examples
- Creates structured markdown
- Builds navigation index

Usage:
    python scrape-github-docs.py --repo "microsoft/playwright" --output "./docs"
"""

import asyncio
import argparse
import json
import re
from pathlib import Path
from typing import Dict, List
from datetime import datetime

from playwright.async_api import async_playwright, Browser, Page


class GitHubDocsScraper:
    """Scrape GitHub repository documentation"""

    def __init__(self, repo: str, output_dir: str, include_wiki: bool = True):
        self.repo = repo  # Format: "owner/repo"
        self.output_dir = Path(output_dir)
        self.include_wiki = include_wiki

        # URLs
        self.base_url = f"https://github.com/{repo}"
        self.readme_url = f"{self.base_url}#readme"
        self.wiki_url = f"{self.base_url}/wiki"
        self.docs_url = f"{self.base_url}/tree/main/docs"

        # State
        self.scraped_pages = []
        self.output_dir.mkdir(parents=True, exist_ok=True)

    async def scrape(self):
        """Main scraping entry point"""
        print(f"GitHub Docs Scraper")
        print(f"Repository: {self.repo}")
        print(f"Output: {self.output_dir}")
        print("")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)

            try:
                # Scrape README
                print("Scraping README...")
                await self.scrape_readme(browser)

                # Scrape Wiki
                if self.include_wiki:
                    print("Scraping Wiki...")
                    await self.scrape_wiki(browser)

                # Scrape Docs folder
                print("Scraping Docs folder...")
                await self.scrape_docs_folder(browser)

            finally:
                await browser.close()

        # Save index
        self.save_index()

        print("")
        print("=" * 50)
        print(f"Complete! Pages scraped: {len(self.scraped_pages)}")
        print(f"Output: {self.output_dir}")
        print("=" * 50)

    async def scrape_readme(self, browser: Browser):
        """Scrape repository README"""
        page = await browser.new_page()

        try:
            await page.goto(self.readme_url, wait_until="networkidle")

            # Wait for README to load
            readme = page.locator("article.markdown-body")

            if await readme.count() > 0:
                # Extract content
                title = f"{self.repo} - README"
                html = await readme.inner_html()
                markdown = await self.html_to_markdown(html)

                # Save README
                readme_path = self.output_dir / "README.md"
                with open(readme_path, "w", encoding="utf-8") as f:
                    f.write(f"# {title}\n\n")
                    f.write(markdown)

                self.scraped_pages.append(
                    {
                        "title": title,
                        "url": self.readme_url,
                        "file": "README.md",
                        "type": "readme",
                    }
                )

                print(f"  ✓ README saved")

        finally:
            await page.close()

    async def scrape_wiki(self, browser: Browser):
        """Scrape repository Wiki"""
        page = await browser.new_page()

        try:
            response = await page.goto(self.wiki_url, wait_until="networkidle")

            # Check if Wiki exists
            if response.status == 404:
                print("  No Wiki found")
                return

            # Get all Wiki pages from sidebar
            sidebar_links = await page.locator('#wiki-pages-box a[href*="/wiki/"]').all()

            wiki_urls = []
            for link in sidebar_links:
                href = await link.get_attribute("href")
                if href:
                    wiki_urls.append(f"https://github.com{href}")

            print(f"  Found {len(wiki_urls)} Wiki pages")

            # Scrape each Wiki page
            for i, url in enumerate(wiki_urls, 1):
                await page.goto(url, wait_until="networkidle")

                # Extract content
                wiki_content = page.locator("#wiki-body")

                if await wiki_content.count() > 0:
                    title_elem = await page.locator("#wiki-wrapper h1").first.inner_text()
                    html = await wiki_content.inner_html()
                    markdown = await self.html_to_markdown(html)

                    # Save Wiki page
                    filename = f"wiki-{self.slugify(title_elem)}.md"
                    filepath = self.output_dir / filename

                    with open(filepath, "w", encoding="utf-8") as f:
                        f.write(f"# {title_elem}\n\n")
                        f.write(markdown)

                    self.scraped_pages.append(
                        {
                            "title": title_elem,
                            "url": url,
                            "file": filename,
                            "type": "wiki",
                        }
                    )

                    print(f"  ✓ [{i}/{len(wiki_urls)}] {title_elem}")

                # Rate limiting
                await asyncio.sleep(1)

        except Exception as e:
            print(f"  Error scraping Wiki: {e}")

        finally:
            await page.close()

    async def scrape_docs_folder(self, browser: Browser):
        """Scrape docs folder if it exists"""
        page = await browser.new_page()

        try:
            # Try common doc paths
            doc_paths = [
                f"{self.base_url}/tree/main/docs",
                f"{self.base_url}/tree/master/docs",
                f"{self.base_url}/tree/main/documentation",
                f"{self.base_url}/tree/main/doc",
            ]

            docs_url = None
            for path in doc_paths:
                response = await page.goto(path, wait_until="networkidle", timeout=10000)
                if response.status == 200:
                    docs_url = path
                    break

            if not docs_url:
                print("  No docs folder found")
                return

            # Get all markdown files in docs
            file_links = await page.locator('a[href*=".md"]').all()

            doc_urls = []
            for link in file_links:
                href = await link.get_attribute("href")
                if href and "/blob/" in href:
                    # Convert to raw URL
                    raw_url = href.replace("/blob/", "/raw/")
                    doc_urls.append(f"https://github.com{raw_url}")

            print(f"  Found {len(doc_urls)} documentation files")

            # Scrape each doc file
            for i, url in enumerate(doc_urls, 1):
                await page.goto(url)

                # Get markdown content
                content = await page.locator("body").inner_text()

                # Extract title from content
                title_match = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
                title = title_match.group(1) if title_match else f"Doc {i}"

                # Save doc
                filename = f"doc-{self.slugify(title)}.md"
                filepath = self.output_dir / filename

                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(content)

                self.scraped_pages.append(
                    {
                        "title": title,
                        "url": url,
                        "file": filename,
                        "type": "docs",
                    }
                )

                print(f"  ✓ [{i}/{len(doc_urls)}] {title}")

                # Rate limiting
                await asyncio.sleep(1)

        except Exception as e:
            print(f"  Error scraping docs folder: {e}")

        finally:
            await page.close()

    async def html_to_markdown(self, html: str) -> str:
        """Convert HTML to markdown"""
        from markdownify import markdownify

        return markdownify(html, heading_style="ATX")

    def slugify(self, text: str) -> str:
        """Convert text to filename-safe slug"""
        slug = text.lower().replace(" ", "-")
        slug = re.sub(r"[^a-z0-9-]", "", slug)
        slug = re.sub(r"-+", "-", slug)
        return slug.strip("-")[:100]

    def save_index(self):
        """Save index of all scraped pages"""
        index_path = self.output_dir / "index.json"

        with open(index_path, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "repository": self.repo,
                    "scraped_at": datetime.utcnow().isoformat(),
                    "pages": self.scraped_pages,
                },
                f,
                indent=2,
            )

        # Create navigation markdown
        nav_path = self.output_dir / "NAVIGATION.md"

        with open(nav_path, "w", encoding="utf-8") as f:
            f.write(f"# {self.repo} Documentation\n\n")

            # Group by type
            for doc_type in ["readme", "wiki", "docs"]:
                pages = [p for p in self.scraped_pages if p["type"] == doc_type]

                if pages:
                    f.write(f"## {doc_type.title()}\n\n")
                    for page in pages:
                        f.write(f"- [{page['title']}]({page['file']})\n")
                    f.write("\n")


async def main():
    """Entry point"""
    parser = argparse.ArgumentParser(description="Scrape GitHub repository documentation")
    parser.add_argument("--repo", required=True, help='Repository (format: "owner/repo")')
    parser.add_argument("--output", default="./github-docs", help="Output directory")
    parser.add_argument("--no-wiki", action="store_true", help="Skip Wiki scraping")

    args = parser.parse_args()

    scraper = GitHubDocsScraper(
        repo=args.repo, output_dir=args.output, include_wiki=not args.no_wiki
    )

    await scraper.scrape()


if __name__ == "__main__":
    asyncio.run(main())
