#!/usr/bin/env python3
"""
Blog Post Scraper

Scrapes blog posts from a blog site with automatic article discovery

Features:
- Automatic post discovery from blog homepage/category pages
- Article content extraction
- Metadata extraction (author, date, tags)
- Featured image download (optional)
- Index generation

Usage:
    python scrape-blog-posts.py --blog-url "https://blog.example.com" --max-posts 50
"""

import asyncio
import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime
from urllib.parse import urljoin, urlparse

from playwright.async_api import async_playwright, Browser, Page
from markdownify import markdownify as md


class BlogPostScraper:
    """Scrape blog posts with automatic discovery"""

    def __init__(
        self,
        blog_url: str,
        output_dir: str,
        category: Optional[str] = None,
        max_posts: int = 50,
        download_images: bool = False,
    ):
        self.blog_url = blog_url
        self.output_dir = Path(output_dir)
        self.category = category
        self.max_posts = max_posts
        self.download_images = download_images

        # State
        self.scraped_posts = []
        self.output_dir.mkdir(parents=True, exist_ok=True)

        if self.download_images:
            self.images_dir = self.output_dir / "images"
            self.images_dir.mkdir(exist_ok=True)

    async def scrape(self):
        """Main scraping entry point"""
        print(f"Blog Post Scraper")
        print(f"Blog URL: {self.blog_url}")
        if self.category:
            print(f"Category: {self.category}")
        print(f"Max posts: {self.max_posts}")
        print("")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)

            try:
                # Discover post URLs
                print("Discovering blog posts...")
                post_urls = await self.discover_posts(browser)
                print(f"Found {len(post_urls)} posts")

                # Limit to max_posts
                post_urls = post_urls[: self.max_posts]

                # Scrape each post
                print(f"\nScraping {len(post_urls)} posts...")
                for i, url in enumerate(post_urls, 1):
                    try:
                        post_data = await self.scrape_post(browser, url)

                        if post_data:
                            self.save_post(post_data)
                            self.scraped_posts.append(post_data)
                            print(f"  ✓ [{i}/{len(post_urls)}] {post_data['title']}")

                        # Rate limiting
                        await asyncio.sleep(2)

                    except Exception as e:
                        print(f"  ✗ [{i}/{len(post_urls)}] Error: {e}")

            finally:
                await browser.close()

        # Save index
        self.save_index()

        print("")
        print("=" * 50)
        print(f"Complete! Posts scraped: {len(self.scraped_posts)}")
        print(f"Output: {self.output_dir}")
        print("=" * 50)

    async def discover_posts(self, browser: Browser) -> List[str]:
        """Discover blog post URLs from homepage/category page"""
        page = await browser.new_page()
        post_urls = []

        try:
            # Navigate to blog or category page
            if self.category:
                # Try common category URL patterns
                category_urls = [
                    f"{self.blog_url}/category/{self.category}",
                    f"{self.blog_url}/categories/{self.category}",
                    f"{self.blog_url}/tag/{self.category}",
                    f"{self.blog_url}/{self.category}",
                ]

                url = None
                for cat_url in category_urls:
                    response = await page.goto(cat_url, wait_until="networkidle", timeout=10000)
                    if response.status == 200:
                        url = cat_url
                        break

                if not url:
                    print(f"Warning: Could not find category '{self.category}', using homepage")
                    await page.goto(self.blog_url, wait_until="networkidle")
            else:
                await page.goto(self.blog_url, wait_until="networkidle")

            # Try common article link selectors
            article_selectors = [
                'article a[href*="/blog/"], article a[href*="/post/"]',
                'article h2 a, article h3 a',
                '.post-title a, .entry-title a',
                'a[href*="/blog/"], a[href*="/post/"], a[href*="/article/"]',
                'article a',
            ]

            for selector in article_selectors:
                links = await page.locator(selector).all()

                if links:
                    for link in links:
                        href = await link.get_attribute("href")

                        if href:
                            # Make absolute URL
                            absolute_url = urljoin(page.url, href)

                            # Filter out non-article URLs
                            if self.is_article_url(absolute_url):
                                post_urls.append(absolute_url)

                    if post_urls:
                        break  # Found articles, stop trying selectors

            # Remove duplicates
            post_urls = list(dict.fromkeys(post_urls))

            # Try pagination if not enough posts
            if len(post_urls) < self.max_posts:
                await self.scrape_pagination(page, post_urls)

        finally:
            await page.close()

        return post_urls

    async def scrape_pagination(self, page: Page, post_urls: List[str]):
        """Scrape additional pages if pagination exists"""
        max_pages = 5  # Limit pagination scraping

        for page_num in range(2, max_pages + 1):
            try:
                # Try to find and click "Next" button
                next_button = page.locator('a.next, a[rel="next"], button.next')

                if await next_button.count() == 0:
                    break  # No more pages

                await next_button.click()
                await page.wait_for_load_state("networkidle")

                # Extract URLs from this page
                links = await page.locator('article a').all()

                for link in links:
                    href = await link.get_attribute("href")

                    if href:
                        absolute_url = urljoin(page.url, href)

                        if self.is_article_url(absolute_url) and absolute_url not in post_urls:
                            post_urls.append(absolute_url)

                if len(post_urls) >= self.max_posts:
                    break

            except Exception:
                break  # No more pages or error

    def is_article_url(self, url: str) -> bool:
        """Check if URL looks like an article"""
        # Filter out common non-article patterns
        excluded = ["/tag/", "/category/", "/author/", "/page/", "#", "?"]

        for pattern in excluded:
            if pattern in url:
                return False

        # Must have article-like path
        article_patterns = ["/blog/", "/post/", "/article/", "/tutorial/", "/guide/"]

        for pattern in article_patterns:
            if pattern in url:
                return True

        return False

    async def scrape_post(self, browser: Browser, url: str) -> Optional[Dict]:
        """Scrape a single blog post"""
        page = await browser.new_page()

        try:
            await page.goto(url, wait_until="networkidle")

            # Extract article content
            article_selectors = [
                "article",
                '[role="main"] article',
                ".post-content",
                ".entry-content",
                ".article-content",
            ]

            article_element = None
            for selector in article_selectors:
                element = page.locator(selector).first

                if await element.count() > 0:
                    article_element = element
                    break

            if not article_element:
                article_element = page.locator("main")

            # Extract content
            html = await article_element.inner_html()
            markdown = md(html, heading_style="ATX")

            # Extract metadata
            title = await self.extract_title(page)
            author = await self.extract_author(page)
            date = await self.extract_date(page)
            tags = await self.extract_tags(page)
            featured_image = await self.extract_featured_image(page)

            # Download featured image if enabled
            image_path = None
            if self.download_images and featured_image:
                image_path = await self.download_image(page, featured_image)

            post_data = {
                "url": url,
                "title": title,
                "author": author,
                "date": date,
                "tags": tags,
                "featured_image": featured_image,
                "image_path": image_path,
                "content": markdown,
                "scraped_at": datetime.utcnow().isoformat(),
            }

            return post_data

        finally:
            await page.close()

    async def extract_title(self, page: Page) -> str:
        """Extract post title"""
        selectors = ["h1", "article h1", ".post-title", ".entry-title"]

        for selector in selectors:
            element = page.locator(selector).first

            if await element.count() > 0:
                return await element.inner_text()

        return await page.title()

    async def extract_author(self, page: Page) -> Optional[str]:
        """Extract author"""
        selectors = ['.author-name', '.author', '[rel="author"]', '[itemprop="author"]']

        for selector in selectors:
            element = page.locator(selector).first

            if await element.count() > 0:
                return await element.inner_text()

        return None

    async def extract_date(self, page: Page) -> Optional[str]:
        """Extract publication date"""
        selectors = ['time[datetime]', '.post-date', '[itemprop="datePublished"]']

        for selector in selectors:
            element = page.locator(selector).first

            if await element.count() > 0:
                datetime_attr = await element.get_attribute("datetime")
                if datetime_attr:
                    return datetime_attr

                return await element.inner_text()

        return None

    async def extract_tags(self, page: Page) -> List[str]:
        """Extract tags"""
        tags = []
        selectors = ['.tag', '.post-tag', '[rel="tag"]']

        for selector in selectors:
            elements = page.locator(selector)
            count = await elements.count()

            for i in range(count):
                tag = await elements.nth(i).inner_text()
                tags.append(tag.strip())

        return list(set(tags))

    async def extract_featured_image(self, page: Page) -> Optional[str]:
        """Extract featured image URL"""
        selectors = [
            'meta[property="og:image"]',
            '.featured-image img',
            'article img',
            'img.wp-post-image',
        ]

        for selector in selectors:
            element = page.locator(selector).first

            if await element.count() > 0:
                if selector.startswith("meta"):
                    return await element.get_attribute("content")
                else:
                    return await element.get_attribute("src")

        return None

    async def download_image(self, page: Page, image_url: str) -> Optional[str]:
        """Download featured image"""
        try:
            # Make absolute URL
            absolute_url = urljoin(page.url, image_url)

            # Get filename from URL
            filename = Path(urlparse(absolute_url).path).name

            if not filename:
                filename = f"image-{len(self.scraped_posts)}.jpg"

            filepath = self.images_dir / filename

            # Download image
            import aiohttp

            async with aiohttp.ClientSession() as session:
                async with session.get(absolute_url) as response:
                    if response.status == 200:
                        content = await response.read()

                        with open(filepath, "wb") as f:
                            f.write(content)

                        return f"images/{filename}"

        except Exception as e:
            print(f"    Error downloading image: {e}")

        return None

    def save_post(self, post_data: Dict):
        """Save post to disk"""
        # Generate filename
        slug = self.slugify(post_data["title"])
        filename = f"{slug}.md"
        filepath = self.output_dir / filename

        with open(filepath, "w", encoding="utf-8") as f:
            # Frontmatter
            f.write("---\n")
            f.write(f"title: {post_data['title']}\n")
            f.write(f"url: {post_data['url']}\n")
            if post_data["author"]:
                f.write(f"author: {post_data['author']}\n")
            if post_data["date"]:
                f.write(f"date: {post_data['date']}\n")
            if post_data["tags"]:
                f.write(f"tags: [{', '.join(post_data['tags'])}]\n")
            f.write(f"scraped_at: {post_data['scraped_at']}\n")
            f.write("---\n\n")

            # Content
            f.write(f"# {post_data['title']}\n\n")

            if post_data["author"]:
                f.write(f"*By {post_data['author']}*\n\n")

            if post_data["image_path"]:
                f.write(f"![Featured Image]({post_data['image_path']})\n\n")

            f.write(post_data["content"])

    def save_index(self):
        """Save index of all posts"""
        index_path = self.output_dir / "index.json"

        with open(index_path, "w", encoding="utf-8") as f:
            json.dump(
                {
                    "blog_url": self.blog_url,
                    "category": self.category,
                    "scraped_at": datetime.utcnow().isoformat(),
                    "posts": [
                        {
                            "title": p["title"],
                            "url": p["url"],
                            "author": p["author"],
                            "date": p["date"],
                            "tags": p["tags"],
                        }
                        for p in self.scraped_posts
                    ],
                },
                f,
                indent=2,
            )

    def slugify(self, text: str) -> str:
        """Convert to slug"""
        slug = text.lower().replace(" ", "-")
        slug = re.sub(r"[^a-z0-9-]", "", slug)
        slug = re.sub(r"-+", "-", slug)
        return slug.strip("-")[:100]


async def main():
    """Entry point"""
    parser = argparse.ArgumentParser(description="Scrape blog posts")
    parser.add_argument("--blog-url", required=True, help="Blog homepage URL")
    parser.add_argument("--output", default="./blog-posts", help="Output directory")
    parser.add_argument("--category", help="Specific category to scrape")
    parser.add_argument("--max-posts", type=int, default=50, help="Maximum posts to scrape")
    parser.add_argument("--download-images", action="store_true", help="Download featured images")

    args = parser.parse_args()

    scraper = BlogPostScraper(
        blog_url=args.blog_url,
        output_dir=args.output,
        category=args.category,
        max_posts=args.max_posts,
        download_images=args.download_images,
    )

    await scraper.scrape()


if __name__ == "__main__":
    asyncio.run(main())
