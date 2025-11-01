#!/usr/bin/env python3
"""
Article scraper with content extraction and rate limiting

Features:
- Extract article content (removes nav, ads, footers)
- Author and date detection
- Tag/category extraction
- Multiple output formats (markdown, json)
- Rate limiting
- Batch processing from URL list
"""

import asyncio
import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
from urllib.parse import urlparse

from playwright.async_api import async_playwright, Page
from markdownify import markdownify as md
from tqdm import tqdm


class ArticleScraper:
    """Scrape articles with content extraction"""

    def __init__(
        self,
        urls: List[str],
        output_dir: str,
        output_format: str = "markdown",
        rate_limit: float = 2.0,
    ):
        self.urls = urls
        self.output_dir = Path(output_dir)
        self.output_format = output_format
        self.rate_limit = rate_limit

        # Stats
        self.scraped_count = 0
        self.error_count = 0

        # Setup output
        self.output_dir.mkdir(parents=True, exist_ok=True)

    async def scrape_all(self):
        """Scrape all URLs"""
        print(f"Article Scraper")
        print(f"URLs to scrape: {len(self.urls)}")
        print(f"Output format: {self.output_format}")
        print(f"Rate limit: {self.rate_limit}s")
        print("")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)

            try:
                pbar = tqdm(self.urls, desc="Scraping articles", unit="article")

                for url in pbar:
                    try:
                        article_data = await self._scrape_article(browser, url)

                        if article_data:
                            self._save_article(article_data)
                            self.scraped_count += 1

                    except Exception as e:
                        print(f"\nError scraping {url}: {e}")
                        self.error_count += 1

                    # Rate limiting
                    await asyncio.sleep(self.rate_limit)

                pbar.close()

            finally:
                await browser.close()

        # Save index
        self._save_index()

        print("")
        print("=" * 50)
        print("Scraping complete!")
        print(f"Articles scraped: {self.scraped_count}")
        print(f"Errors: {self.error_count}")
        print(f"Output directory: {self.output_dir}")
        print("=" * 50)

    async def _scrape_article(self, browser, url: str) -> Optional[Dict]:
        """Scrape single article"""
        page = await browser.new_page()

        try:
            # Navigate to page
            response = await page.goto(url, wait_until="networkidle", timeout=30000)

            if response.status != 200:
                print(f"\nWarning: {url} returned status {response.status}")
                return None

            # Wait for content
            await page.wait_for_selector("body", timeout=10000)

            # Extract article data
            article_data = await self._extract_article_data(page, url)

            return article_data

        except Exception as e:
            print(f"\nError processing {url}: {e}")
            return None

        finally:
            await page.close()

    async def _extract_article_data(self, page: Page, url: str) -> Dict:
        """Extract article content and metadata"""
        # Try common article selectors
        article_selectors = [
            "article",
            "main article",
            '[role="main"]',
            ".post-content",
            ".article-content",
            ".entry-content",
            "#content article",
            "main",
        ]

        article_element = None
        for selector in article_selectors:
            try:
                article_element = page.locator(selector).first
                if await article_element.count() > 0:
                    break
            except Exception:
                continue

        # Fallback to body if no article found
        if not article_element or await article_element.count() == 0:
            article_element = page.locator("body")

        # Get HTML content
        html_content = await article_element.inner_html()

        # Convert to markdown
        markdown_content = md(html_content, heading_style="ATX")

        # Extract metadata
        title = await self._extract_title(page)
        author = await self._extract_author(page)
        date = await self._extract_date(page)
        tags = await self._extract_tags(page)
        description = await self._extract_description(page)

        # Build article data
        article_data = {
            "url": url,
            "title": title,
            "author": author,
            "date": date,
            "tags": tags,
            "description": description,
            "content": markdown_content,
            "html": html_content,
            "scraped_at": datetime.utcnow().isoformat(),
        }

        return article_data

    async def _extract_title(self, page: Page) -> str:
        """Extract article title"""
        # Try multiple selectors
        selectors = [
            "h1",
            "article h1",
            ".post-title",
            ".article-title",
            ".entry-title",
            '[property="og:title"]',
        ]

        for selector in selectors:
            try:
                if selector.startswith("["):
                    # Meta tag
                    element = page.locator(selector)
                    if await element.count() > 0:
                        return await element.get_attribute("content")
                else:
                    # Text element
                    element = page.locator(selector).first
                    if await element.count() > 0:
                        return await element.inner_text()
            except Exception:
                continue

        # Fallback to page title
        return await page.title()

    async def _extract_author(self, page: Page) -> Optional[str]:
        """Extract article author"""
        selectors = [
            '[rel="author"]',
            ".author",
            ".author-name",
            ".post-author",
            '[itemprop="author"]',
            '[property="article:author"]',
        ]

        for selector in selectors:
            try:
                element = page.locator(selector).first
                if await element.count() > 0:
                    if selector.startswith("[") and "property" in selector:
                        return await element.get_attribute("content")
                    else:
                        return await element.inner_text()
            except Exception:
                continue

        return None

    async def _extract_date(self, page: Page) -> Optional[str]:
        """Extract publication date"""
        selectors = [
            'time[datetime]',
            '[itemprop="datePublished"]',
            '[property="article:published_time"]',
            ".post-date",
            ".published",
        ]

        for selector in selectors:
            try:
                element = page.locator(selector).first
                if await element.count() > 0:
                    # Try datetime attribute first
                    datetime_attr = await element.get_attribute("datetime")
                    if datetime_attr:
                        return datetime_attr

                    # Try content attribute
                    content_attr = await element.get_attribute("content")
                    if content_attr:
                        return content_attr

                    # Fallback to text
                    return await element.inner_text()
            except Exception:
                continue

        return None

    async def _extract_tags(self, page: Page) -> List[str]:
        """Extract article tags/categories"""
        tags = []

        selectors = [
            '[rel="tag"]',
            ".tag",
            ".post-tag",
            ".article-tag",
            '[property="article:tag"]',
        ]

        for selector in selectors:
            try:
                elements = page.locator(selector)
                count = await elements.count()

                for i in range(count):
                    element = elements.nth(i)

                    if "property" in selector:
                        tag = await element.get_attribute("content")
                    else:
                        tag = await element.inner_text()

                    if tag:
                        tags.append(tag.strip())

            except Exception:
                continue

        return list(set(tags))  # Remove duplicates

    async def _extract_description(self, page: Page) -> Optional[str]:
        """Extract article description"""
        selectors = [
            '[name="description"]',
            '[property="og:description"]',
            '[name="twitter:description"]',
        ]

        for selector in selectors:
            try:
                element = page.locator(selector)
                if await element.count() > 0:
                    return await element.get_attribute("content")
            except Exception:
                continue

        return None

    def _save_article(self, article_data: Dict):
        """Save article to disk"""
        # Generate filename from title
        title = article_data["title"]
        filename = self._slugify(title)

        if self.output_format == "markdown":
            filepath = self.output_dir / f"{filename}.md"
            self._save_as_markdown(filepath, article_data)
        elif self.output_format == "json":
            filepath = self.output_dir / f"{filename}.json"
            self._save_as_json(filepath, article_data)
        else:
            # Save both
            md_path = self.output_dir / f"{filename}.md"
            json_path = self.output_dir / f"{filename}.json"
            self._save_as_markdown(md_path, article_data)
            self._save_as_json(json_path, article_data)

    def _save_as_markdown(self, filepath: Path, article_data: Dict):
        """Save article as markdown"""
        with open(filepath, "w", encoding="utf-8") as f:
            # Frontmatter
            f.write("---\n")
            f.write(f"title: {article_data['title']}\n")
            f.write(f"url: {article_data['url']}\n")
            if article_data["author"]:
                f.write(f"author: {article_data['author']}\n")
            if article_data["date"]:
                f.write(f"date: {article_data['date']}\n")
            if article_data["tags"]:
                f.write(f"tags: {', '.join(article_data['tags'])}\n")
            f.write(f"scraped_at: {article_data['scraped_at']}\n")
            f.write("---\n\n")

            # Content
            f.write(f"# {article_data['title']}\n\n")

            if article_data["author"]:
                f.write(f"**By {article_data['author']}**\n\n")

            if article_data["description"]:
                f.write(f"*{article_data['description']}*\n\n")

            f.write(article_data["content"])

    def _save_as_json(self, filepath: Path, article_data: Dict):
        """Save article as JSON"""
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(article_data, f, indent=2, ensure_ascii=False)

    def _save_index(self):
        """Save index of all articles"""
        articles = []

        # Collect all JSON files (or create from markdown files)
        for json_file in self.output_dir.glob("*.json"):
            with open(json_file, "r", encoding="utf-8") as f:
                data = json.load(f)
                articles.append(
                    {
                        "title": data["title"],
                        "url": data["url"],
                        "author": data.get("author"),
                        "date": data.get("date"),
                        "tags": data.get("tags", []),
                    }
                )

        # Save index
        index_path = self.output_dir / "index.json"
        with open(index_path, "w", encoding="utf-8") as f:
            json.dump(articles, f, indent=2, ensure_ascii=False)

    def _slugify(self, text: str) -> str:
        """Convert text to filename-safe slug"""
        import re

        # Lowercase and replace spaces with hyphens
        slug = text.lower().replace(" ", "-")

        # Remove special characters
        slug = re.sub(r"[^a-z0-9-]", "", slug)

        # Remove multiple hyphens
        slug = re.sub(r"-+", "-", slug)

        # Trim hyphens from ends
        slug = slug.strip("-")

        # Limit length
        return slug[:100]


async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Scrape articles from URLs")
    parser.add_argument(
        "--urls", required=True, help="File containing URLs (one per line)"
    )
    parser.add_argument(
        "--output-dir", default="./articles", help="Output directory"
    )
    parser.add_argument(
        "--format",
        choices=["markdown", "json", "both"],
        default="markdown",
        help="Output format",
    )
    parser.add_argument(
        "--rate-limit", type=float, default=2.0, help="Seconds between requests"
    )

    args = parser.parse_args()

    # Load URLs from file
    urls_file = Path(args.urls)
    if not urls_file.exists():
        print(f"Error: URL file not found: {args.urls}")
        return

    with open(urls_file, "r") as f:
        urls = [line.strip() for line in f if line.strip() and not line.startswith("#")]

    if not urls:
        print("Error: No URLs found in file")
        return

    # Create scraper
    scraper = ArticleScraper(
        urls=urls,
        output_dir=args.output_dir,
        output_format=args.format,
        rate_limit=args.rate_limit,
    )

    # Scrape
    await scraper.scrape_all()


if __name__ == "__main__":
    asyncio.run(main())
