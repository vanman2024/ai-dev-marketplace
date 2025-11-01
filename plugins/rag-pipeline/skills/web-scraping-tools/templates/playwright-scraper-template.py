#!/usr/bin/env python3
"""
Playwright Scraper Template

Customize this template for your specific scraping needs:
1. Update TARGET_URL with your starting URL
2. Customize extract_data() for your target site's structure
3. Add authentication logic if needed
4. Configure rate limiting and concurrency
"""

import asyncio
from pathlib import Path
from typing import Dict, List, Optional
from datetime import datetime

from playwright.async_api import async_playwright, Page, Browser


class CustomScraper:
    """Customizable Playwright scraper template"""

    # CONFIGURATION - Update these for your needs
    TARGET_URL = "https://example.com"  # Starting URL
    OUTPUT_DIR = "./scraped-data"  # Output directory
    RATE_LIMIT = 2.0  # Seconds between requests
    MAX_CONCURRENT = 3  # Maximum concurrent pages
    HEADLESS = True  # Run browser in headless mode

    def __init__(self):
        self.output_dir = Path(self.OUTPUT_DIR)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.scraped_count = 0

    async def scrape(self):
        """Main scraping entry point"""
        print(f"Starting scraper: {self.TARGET_URL}")

        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=self.HEADLESS)

            try:
                # Option 1: Scrape single page
                # await self.scrape_single_page(browser)

                # Option 2: Scrape multiple pages
                # urls = await self.discover_urls(browser)
                # await self.scrape_multiple_pages(browser, urls)

                # Option 3: Scrape with pagination
                await self.scrape_with_pagination(browser)

            finally:
                await browser.close()

        print(f"\nScraping complete! Pages scraped: {self.scraped_count}")

    async def scrape_single_page(self, browser: Browser):
        """Scrape a single page"""
        page = await browser.new_page()

        try:
            await page.goto(self.TARGET_URL, wait_until="networkidle")

            # Extract data
            data = await self.extract_data(page)

            # Save data
            self.save_data(data, "single-page.json")
            self.scraped_count += 1

        finally:
            await page.close()

    async def scrape_multiple_pages(self, browser: Browser, urls: List[str]):
        """Scrape multiple pages with rate limiting"""
        for url in urls:
            page = await browser.new_page()

            try:
                await page.goto(url, wait_until="networkidle")

                # Extract data
                data = await self.extract_data(page)

                # Save data
                filename = f"page-{self.scraped_count}.json"
                self.save_data(data, filename)
                self.scraped_count += 1

                print(f"Scraped: {url}")

            except Exception as e:
                print(f"Error scraping {url}: {e}")

            finally:
                await page.close()

            # Rate limiting
            await asyncio.sleep(self.RATE_LIMIT)

    async def scrape_with_pagination(self, browser: Browser):
        """Scrape pages with pagination (next button clicking)"""
        page = await browser.new_page()

        try:
            await page.goto(self.TARGET_URL, wait_until="networkidle")

            while True:
                # Extract data from current page
                data = await self.extract_data(page)

                # Save data
                filename = f"page-{self.scraped_count}.json"
                self.save_data(data, filename)
                self.scraped_count += 1

                print(f"Scraped page {self.scraped_count}")

                # Try to find and click "Next" button
                # CUSTOMIZE: Update selector for your pagination button
                next_button = page.locator('a.next, button.next, [aria-label="Next"]')

                if await next_button.count() == 0:
                    print("No more pages (next button not found)")
                    break

                # Check if button is disabled
                is_disabled = await next_button.get_attribute("disabled")
                if is_disabled:
                    print("No more pages (next button disabled)")
                    break

                # Click next button
                await next_button.click()

                # Wait for page to load
                await page.wait_for_load_state("networkidle")

                # Rate limiting
                await asyncio.sleep(self.RATE_LIMIT)

        finally:
            await page.close()

    async def extract_data(self, page: Page) -> Dict:
        """
        Extract data from page - CUSTOMIZE THIS FOR YOUR TARGET SITE

        Example patterns for common data extraction:
        """
        data = {
            "url": page.url,
            "scraped_at": datetime.utcnow().isoformat(),
        }

        # Example 1: Extract text from specific elements
        try:
            title = await page.locator("h1").first.inner_text()
            data["title"] = title
        except Exception:
            data["title"] = None

        # Example 2: Extract all links
        try:
            link_elements = await page.locator("a[href]").all()
            links = []
            for element in link_elements:
                href = await element.get_attribute("href")
                text = await element.inner_text()
                links.append({"url": href, "text": text})
            data["links"] = links
        except Exception:
            data["links"] = []

        # Example 3: Extract list items
        try:
            items = []
            item_elements = await page.locator(".item, .product, .post").all()
            for element in item_elements:
                item = {
                    "text": await element.inner_text(),
                    "html": await element.inner_html(),
                }
                items.append(item)
            data["items"] = items
        except Exception:
            data["items"] = []

        # Example 4: Extract table data
        try:
            rows = []
            row_elements = await page.locator("table tr").all()
            for row_element in row_elements:
                cells = await row_element.locator("td, th").all()
                row = [await cell.inner_text() for cell in cells]
                rows.append(row)
            data["table"] = rows
        except Exception:
            data["table"] = []

        # Example 5: Extract metadata
        try:
            og_title = await page.locator('meta[property="og:title"]').get_attribute(
                "content"
            )
            description = await page.locator('meta[name="description"]').get_attribute(
                "content"
            )
            data["metadata"] = {
                "og_title": og_title,
                "description": description,
            }
        except Exception:
            data["metadata"] = {}

        return data

    async def discover_urls(self, browser: Browser) -> List[str]:
        """
        Discover URLs to scrape - CUSTOMIZE THIS

        Common patterns:
        - Extract links from sitemap
        - Crawl listing pages
        - Generate URLs from patterns
        """
        page = await browser.new_page()
        urls = []

        try:
            await page.goto(self.TARGET_URL, wait_until="networkidle")

            # Example: Extract all article links
            link_elements = await page.locator('a[href*="/article/"]').all()

            for element in link_elements:
                href = await element.get_attribute("href")
                if href:
                    # Make absolute URL
                    absolute_url = page.url if href.startswith("/") else href
                    if href.startswith("/"):
                        from urllib.parse import urljoin

                        absolute_url = urljoin(page.url, href)
                    urls.append(absolute_url)

        finally:
            await page.close()

        return urls

    def save_data(self, data: Dict, filename: str):
        """Save data to JSON file"""
        import json

        filepath = self.output_dir / filename

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

    async def authenticate(self, page: Page):
        """
        Add authentication logic if needed - CUSTOMIZE THIS

        Example: Login with username/password
        """
        # Navigate to login page
        await page.goto("https://example.com/login")

        # Fill in credentials
        await page.fill('input[name="username"]', "your-username")
        await page.fill('input[name="password"]', "your-password")

        # Submit form
        await page.click('button[type="submit"]')

        # Wait for redirect
        await page.wait_for_url("https://example.com/dashboard")

        print("Authentication successful")

    async def handle_cookies(self, page: Page):
        """
        Handle cookie consent banners - CUSTOMIZE THIS
        """
        try:
            # Click "Accept All" button if present
            accept_button = page.locator('button:has-text("Accept All")')
            if await accept_button.count() > 0:
                await accept_button.click()
                print("Accepted cookies")
        except Exception:
            pass


async def main():
    """Entry point"""
    scraper = CustomScraper()
    await scraper.scrape()


if __name__ == "__main__":
    asyncio.run(main())
