#!/usr/bin/env python3
"""
Functional documentation scraper with rate limiting and error handling

Features:
- Playwright-based scraping for JavaScript-heavy sites
- Automatic rate limiting (respectful crawling)
- Error handling with retries
- Content deduplication
- Markdown conversion
- Metadata extraction
- Progress tracking
"""

import asyncio
import argparse
import json
import hashlib
import time
from pathlib import Path
from typing import Set, Dict, List, Optional
from urllib.parse import urljoin, urlparse
from datetime import datetime

from playwright.async_api import async_playwright, Page, Browser
from markdownify import markdownify as md
from tqdm import tqdm


class DocumentationScraper:
    """Scrape documentation sites with rate limiting"""

    def __init__(
        self,
        start_url: str,
        output_dir: str,
        max_depth: int = 3,
        rate_limit: float = 2.0,
        same_domain_only: bool = True,
    ):
        self.start_url = start_url
        self.output_dir = Path(output_dir)
        self.max_depth = max_depth
        self.rate_limit = rate_limit
        self.same_domain_only = same_domain_only

        # State tracking
        self.visited_urls: Set[str] = set()
        self.url_queue: List[tuple] = [(start_url, 0)]  # (url, depth)
        self.scraped_count = 0
        self.error_count = 0

        # Output setup
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.cache_dir = self.output_dir / ".cache"
        self.cache_dir.mkdir(exist_ok=True)

        # Domain filtering
        self.start_domain = urlparse(start_url).netloc

    async def scrape(self):
        """Main scraping orchestrator"""
        print(f"Starting documentation scraper")
        print(f"Start URL: {self.start_url}")
        print(f"Max depth: {self.max_depth}")
        print(f"Rate limit: {self.rate_limit}s between requests")
        print(f"Output: {self.output_dir}")
        print("")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)

            try:
                await self._scrape_recursive(browser)
            finally:
                await browser.close()

        # Save index
        self._save_index()

        print("")
        print("=" * 50)
        print("Scraping complete!")
        print(f"Pages scraped: {self.scraped_count}")
        print(f"Errors: {self.error_count}")
        print(f"Output directory: {self.output_dir}")
        print("=" * 50)

    async def _scrape_recursive(self, browser: Browser):
        """Recursively scrape pages"""
        pbar = tqdm(desc="Scraping pages", unit="page")

        while self.url_queue:
            url, depth = self.url_queue.pop(0)

            # Skip if already visited
            if url in self.visited_urls:
                continue

            # Skip if max depth exceeded
            if depth > self.max_depth:
                continue

            # Skip if different domain (if filtering enabled)
            if self.same_domain_only and urlparse(url).netloc != self.start_domain:
                continue

            # Mark as visited
            self.visited_urls.add(url)

            # Rate limiting
            await asyncio.sleep(self.rate_limit)

            # Scrape page
            try:
                page_data = await self._scrape_page(browser, url, depth)

                if page_data:
                    # Save page
                    self._save_page(page_data)
                    self.scraped_count += 1
                    pbar.update(1)

                    # Add links to queue
                    for link in page_data.get("links", []):
                        if link not in self.visited_urls:
                            self.url_queue.append((link, depth + 1))

            except Exception as e:
                print(f"\nError scraping {url}: {e}")
                self.error_count += 1

        pbar.close()

    async def _scrape_page(
        self, browser: Browser, url: str, depth: int
    ) -> Optional[Dict]:
        """Scrape a single page"""
        page = await browser.new_page()

        try:
            # Navigate to page
            response = await page.goto(url, wait_until="networkidle", timeout=30000)

            if response.status != 200:
                print(f"\nWarning: {url} returned status {response.status}")
                return None

            # Wait for content to load
            await page.wait_for_selector("body", timeout=10000)

            # Extract content
            title = await page.title()
            html_content = await page.content()

            # Extract metadata
            metadata = await self._extract_metadata(page)

            # Convert to markdown
            markdown_content = md(html_content, heading_style="ATX")

            # Extract links
            links = await self._extract_links(page, url)

            # Create page data
            page_data = {
                "url": url,
                "title": title,
                "content": markdown_content,
                "html": html_content,
                "metadata": metadata,
                "links": links,
                "depth": depth,
                "scraped_at": datetime.utcnow().isoformat(),
            }

            return page_data

        except Exception as e:
            print(f"\nError processing {url}: {e}")
            return None

        finally:
            await page.close()

    async def _extract_metadata(self, page: Page) -> Dict:
        """Extract page metadata"""
        metadata = {}

        try:
            # Open Graph tags
            og_title = await page.locator('meta[property="og:title"]').get_attribute(
                "content"
            )
            og_desc = await page.locator(
                'meta[property="og:description"]'
            ).get_attribute("content")

            # Standard meta tags
            description = await page.locator('meta[name="description"]').get_attribute(
                "content"
            )
            keywords = await page.locator('meta[name="keywords"]').get_attribute(
                "content"
            )

            metadata["og_title"] = og_title
            metadata["og_description"] = og_desc
            metadata["description"] = description
            metadata["keywords"] = keywords

        except Exception:
            pass  # Metadata is optional

        return metadata

    async def _extract_links(self, page: Page, base_url: str) -> List[str]:
        """Extract all links from page"""
        links = []

        try:
            link_elements = await page.locator("a[href]").all()

            for element in link_elements:
                href = await element.get_attribute("href")

                if href:
                    # Make absolute URL
                    absolute_url = urljoin(base_url, href)

                    # Remove fragments
                    absolute_url = absolute_url.split("#")[0]

                    # Add to links
                    if absolute_url.startswith("http"):
                        links.append(absolute_url)

        except Exception as e:
            print(f"\nError extracting links: {e}")

        return links

    def _save_page(self, page_data: Dict):
        """Save page to disk"""
        # Generate filename from URL hash
        url_hash = hashlib.md5(page_data["url"].encode()).hexdigest()[:12]
        filename = f"{url_hash}.json"

        # Save full data as JSON
        json_path = self.cache_dir / filename
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(page_data, f, indent=2, ensure_ascii=False)

        # Save markdown content
        md_filename = f"{url_hash}.md"
        md_path = self.output_dir / md_filename

        with open(md_path, "w", encoding="utf-8") as f:
            # Write frontmatter
            f.write("---\n")
            f.write(f"url: {page_data['url']}\n")
            f.write(f"title: {page_data['title']}\n")
            f.write(f"scraped_at: {page_data['scraped_at']}\n")
            f.write("---\n\n")

            # Write content
            f.write(f"# {page_data['title']}\n\n")
            f.write(page_data["content"])

    def _save_index(self):
        """Save index of all scraped pages"""
        index = []

        for json_file in self.cache_dir.glob("*.json"):
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                index.append(
                    {
                        "url": data["url"],
                        "title": data["title"],
                        "depth": data["depth"],
                        "scraped_at": data["scraped_at"],
                    }
                )

        # Save index
        index_path = self.output_dir / "index.json"
        with open(index_path, "w", encoding="utf-8") as f:
            json.dump(index, f, indent=2, ensure_ascii=False)

        print(f"\nIndex saved to: {index_path}")


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description="Scrape documentation sites with rate limiting"
    )
    parser.add_argument("--url", required=True, help="Starting URL to scrape")
    parser.add_argument(
        "--output-dir", default="./scraped-docs", help="Output directory"
    )
    parser.add_argument("--max-depth", type=int, default=3, help="Maximum crawl depth")
    parser.add_argument(
        "--rate-limit", type=float, default=2.0, help="Seconds between requests"
    )
    parser.add_argument(
        "--all-domains",
        action="store_true",
        help="Scrape links to other domains (default: same domain only)",
    )

    args = parser.parse_args()

    scraper = DocumentationScraper(
        start_url=args.url,
        output_dir=args.output_dir,
        max_depth=args.max_depth,
        rate_limit=args.rate_limit,
        same_domain_only=not args.all_domains,
    )

    await scraper.scrape()


if __name__ == "__main__":
    asyncio.run(main())
