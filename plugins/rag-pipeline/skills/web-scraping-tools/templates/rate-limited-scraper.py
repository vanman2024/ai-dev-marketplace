#!/usr/bin/env python3
"""
Rate-Limited Scraper Template

Features:
- Configurable request delays
- Exponential backoff on errors
- Request queue management
- robots.txt respect
- User-agent rotation
- Request logging
"""

import asyncio
import time
import random
import logging
from pathlib import Path
from typing import List, Dict, Optional
from datetime import datetime
from urllib.parse import urlparse, urljoin
from urllib.robotparser import RobotFileParser

import aiohttp
from bs4 import BeautifulSoup


# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class RateLimiter:
    """Rate limiter with configurable delays and jitter"""

    def __init__(self, requests_per_second: float = 0.5, jitter: bool = True):
        self.delay = 1.0 / requests_per_second
        self.jitter = jitter
        self.last_request = None

    async def wait(self):
        """Wait before making next request"""
        if self.last_request is not None:
            elapsed = time.time() - self.last_request
            wait_time = self.delay - elapsed

            if wait_time > 0:
                # Add random jitter (±20%)
                if self.jitter:
                    jitter_factor = random.uniform(0.8, 1.2)
                    wait_time *= jitter_factor

                await asyncio.sleep(wait_time)

        self.last_request = time.time()


class ExponentialBackoff:
    """Exponential backoff for retries"""

    def __init__(self, base_delay: float = 1.0, max_delay: float = 60.0, max_retries: int = 5):
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.max_retries = max_retries
        self.retry_count = 0

    async def wait(self):
        """Wait with exponential backoff"""
        if self.retry_count >= self.max_retries:
            raise Exception(f"Max retries ({self.max_retries}) exceeded")

        delay = min(self.base_delay * (2 ** self.retry_count), self.max_delay)

        # Add jitter
        jitter = random.uniform(0, delay * 0.1)
        total_delay = delay + jitter

        logger.info(f"Retry {self.retry_count + 1}/{self.max_retries} - waiting {total_delay:.2f}s")
        await asyncio.sleep(total_delay)

        self.retry_count += 1

    def reset(self):
        """Reset retry counter"""
        self.retry_count = 0

    @property
    def should_retry(self) -> bool:
        """Check if should retry"""
        return self.retry_count < self.max_retries


class RobotsTxtChecker:
    """Check robots.txt compliance"""

    def __init__(self):
        self.parsers = {}  # Cache parsers by domain

    async def can_fetch(self, url: str, user_agent: str = "*") -> bool:
        """Check if URL can be fetched according to robots.txt"""
        parsed = urlparse(url)
        domain = f"{parsed.scheme}://{parsed.netloc}"

        # Get or create parser for this domain
        if domain not in self.parsers:
            parser = RobotFileParser()
            robots_url = urljoin(domain, "/robots.txt")

            try:
                # Fetch robots.txt
                async with aiohttp.ClientSession() as session:
                    async with session.get(robots_url, timeout=5) as response:
                        if response.status == 200:
                            content = await response.text()
                            parser.parse(content.splitlines())
                        else:
                            # No robots.txt = allow all
                            return True
            except Exception as e:
                logger.warning(f"Error fetching robots.txt for {domain}: {e}")
                return True  # Allow on error

            self.parsers[domain] = parser

        # Check if allowed
        parser = self.parsers[domain]
        return parser.can_fetch(user_agent, url)

    async def get_crawl_delay(self, url: str, user_agent: str = "*") -> Optional[float]:
        """Get crawl delay from robots.txt"""
        parsed = urlparse(url)
        domain = f"{parsed.scheme}://{parsed.netloc}"

        if domain in self.parsers:
            parser = self.parsers[domain]
            return parser.crawl_delay(user_agent)

        return None


class RateLimitedScraper:
    """Scraper with rate limiting and respectful crawling"""

    # User agents to rotate
    USER_AGENTS = [
        "Mozilla/5.0 (compatible; MyCrawler/1.0; +http://example.com/bot)",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    ]

    def __init__(
        self,
        urls: List[str],
        output_dir: str = "./scraped-data",
        requests_per_second: float = 0.5,
        respect_robots: bool = True,
        max_retries: int = 3,
    ):
        self.urls = urls
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Rate limiting
        self.rate_limiter = RateLimiter(requests_per_second=requests_per_second)
        self.respect_robots = respect_robots
        self.robots_checker = RobotsTxtChecker() if respect_robots else None
        self.max_retries = max_retries

        # Stats
        self.scraped_count = 0
        self.error_count = 0
        self.skipped_count = 0

    async def scrape_all(self):
        """Scrape all URLs"""
        logger.info(f"Starting scraper - {len(self.urls)} URLs")
        logger.info(f"Rate limit: {self.rate_limiter.delay:.2f}s between requests")
        logger.info(f"Respect robots.txt: {self.respect_robots}")

        async with aiohttp.ClientSession() as session:
            for url in self.urls:
                try:
                    await self.scrape_url(session, url)
                except Exception as e:
                    logger.error(f"Failed to scrape {url}: {e}")
                    self.error_count += 1

        logger.info("\n" + "=" * 50)
        logger.info(f"Scraping complete!")
        logger.info(f"Scraped: {self.scraped_count}")
        logger.info(f"Skipped: {self.skipped_count}")
        logger.info(f"Errors: {self.error_count}")
        logger.info("=" * 50)

    async def scrape_url(self, session: aiohttp.ClientSession, url: str):
        """Scrape a single URL with retries"""
        # Check robots.txt
        if self.respect_robots:
            can_fetch = await self.robots_checker.can_fetch(url)
            if not can_fetch:
                logger.warning(f"Skipping {url} (blocked by robots.txt)")
                self.skipped_count += 1
                return

            # Use crawl delay from robots.txt if specified
            crawl_delay = await self.robots_checker.get_crawl_delay(url)
            if crawl_delay and crawl_delay > self.rate_limiter.delay:
                logger.info(f"Using crawl delay from robots.txt: {crawl_delay}s")
                await asyncio.sleep(crawl_delay)

        # Rate limiting
        await self.rate_limiter.wait()

        # Retry logic
        backoff = ExponentialBackoff(max_retries=self.max_retries)

        while backoff.should_retry:
            try:
                # Fetch page
                html = await self.fetch_page(session, url)

                if html:
                    # Parse and extract data
                    data = self.extract_data(url, html)

                    # Save data
                    self.save_data(url, data)

                    self.scraped_count += 1
                    logger.info(f"✓ Scraped: {url}")
                    return

            except aiohttp.ClientResponseError as e:
                if e.status == 429:  # Too Many Requests
                    logger.warning(f"Rate limited (429) - backing off")
                    await backoff.wait()
                elif e.status >= 500:  # Server error
                    logger.warning(f"Server error ({e.status}) - retrying")
                    await backoff.wait()
                else:
                    logger.error(f"HTTP error {e.status}: {url}")
                    break

            except aiohttp.ClientError as e:
                logger.warning(f"Network error: {e} - retrying")
                await backoff.wait()

            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                break

        # Failed after retries
        self.error_count += 1

    async def fetch_page(self, session: aiohttp.ClientSession, url: str) -> Optional[str]:
        """Fetch page HTML"""
        headers = {
            "User-Agent": random.choice(self.USER_AGENTS),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
        }

        async with session.get(url, headers=headers, timeout=30) as response:
            response.raise_for_status()
            return await response.text()

    def extract_data(self, url: str, html: str) -> Dict:
        """
        Extract data from HTML - CUSTOMIZE THIS

        This is a template - update for your specific needs
        """
        soup = BeautifulSoup(html, "lxml")

        data = {
            "url": url,
            "scraped_at": datetime.utcnow().isoformat(),
        }

        # Example 1: Extract title
        title_tag = soup.find("h1")
        data["title"] = title_tag.get_text(strip=True) if title_tag else None

        # Example 2: Extract all paragraphs
        paragraphs = [p.get_text(strip=True) for p in soup.find_all("p")]
        data["content"] = "\n\n".join(paragraphs)

        # Example 3: Extract links
        links = []
        for a in soup.find_all("a", href=True):
            links.append({"url": a["href"], "text": a.get_text(strip=True)})
        data["links"] = links

        # Example 4: Extract metadata
        og_title = soup.find("meta", property="og:title")
        description = soup.find("meta", attrs={"name": "description"})

        data["metadata"] = {
            "og_title": og_title["content"] if og_title else None,
            "description": description["content"] if description else None,
        }

        return data

    def save_data(self, url: str, data: Dict):
        """Save scraped data"""
        import json
        import hashlib

        # Generate filename from URL
        url_hash = hashlib.md5(url.encode()).hexdigest()[:12]
        filename = f"{url_hash}.json"
        filepath = self.output_dir / filename

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)


async def main():
    """Example usage"""
    # CUSTOMIZE: Add your URLs here
    urls = [
        "https://example.com/page1",
        "https://example.com/page2",
        "https://example.com/page3",
    ]

    scraper = RateLimitedScraper(
        urls=urls,
        output_dir="./scraped-data",
        requests_per_second=0.5,  # 2 seconds between requests
        respect_robots=True,
        max_retries=3,
    )

    await scraper.scrape_all()


if __name__ == "__main__":
    asyncio.run(main())
