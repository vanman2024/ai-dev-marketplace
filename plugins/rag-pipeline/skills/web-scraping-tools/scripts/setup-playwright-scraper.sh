#!/bin/bash
# Setup Playwright scraper environment with all dependencies

set -e  # Exit on error

echo "=== Playwright Scraper Setup ==="
echo ""

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
REQUIRED_VERSION="3.10"

echo "Checking Python version..."
if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "Error: Python $REQUIRED_VERSION or higher is required. Found: $PYTHON_VERSION"
    exit 1
fi
echo "✓ Python $PYTHON_VERSION detected"
echo ""

# Create virtual environment (optional but recommended)
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
echo "✓ Virtual environment activated"
echo ""

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip > /dev/null 2>&1
echo "✓ pip upgraded"
echo ""

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --quiet \
    playwright>=1.40.0 \
    beautifulsoup4>=4.12.0 \
    requests>=2.31.0 \
    lxml>=4.9.0 \
    aiohttp>=3.9.0 \
    markdownify>=0.11.0 \
    python-dateutil>=2.8.0 \
    tqdm>=4.66.0

echo "✓ Python packages installed"
echo ""

# Install Playwright browsers
echo "Installing Playwright browsers (this may take a few minutes)..."
playwright install chromium
echo "✓ Chromium browser installed"
echo ""

# Create output directories
echo "Creating output directories..."
mkdir -p scraped-docs
mkdir -p articles
mkdir -p cache
echo "✓ Output directories created"
echo ""

# Create rate limiter utility
echo "Creating rate limiter utility..."
cat > rate_limiter.py << 'EOF'
"""Rate limiting utility for respectful web scraping"""
import time
import random
from typing import Optional
from datetime import datetime, timedelta


class RateLimiter:
    """Enforce rate limits on requests"""

    def __init__(self, requests_per_second: float = 0.5, jitter: bool = True):
        """
        Initialize rate limiter

        Args:
            requests_per_second: Maximum requests per second (default: 0.5 = 2 sec delay)
            jitter: Add random jitter to delays (default: True)
        """
        self.delay = 1.0 / requests_per_second
        self.jitter = jitter
        self.last_request = None
        self.request_count = 0

    def wait(self):
        """Wait appropriate amount of time before next request"""
        if self.last_request is not None:
            elapsed = time.time() - self.last_request
            wait_time = self.delay - elapsed

            if wait_time > 0:
                # Add random jitter (±20%)
                if self.jitter:
                    jitter_factor = random.uniform(0.8, 1.2)
                    wait_time *= jitter_factor

                time.sleep(wait_time)

        self.last_request = time.time()
        self.request_count += 1

    def reset(self):
        """Reset rate limiter state"""
        self.last_request = None
        self.request_count = 0


class ExponentialBackoff:
    """Exponential backoff for retries"""

    def __init__(self, base_delay: float = 1.0, max_delay: float = 60.0, max_retries: int = 5):
        """
        Initialize exponential backoff

        Args:
            base_delay: Initial delay in seconds
            max_delay: Maximum delay in seconds
            max_retries: Maximum number of retries
        """
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.max_retries = max_retries
        self.retry_count = 0

    def wait(self):
        """Wait with exponential backoff"""
        if self.retry_count >= self.max_retries:
            raise Exception(f"Max retries ({self.max_retries}) exceeded")

        delay = min(self.base_delay * (2 ** self.retry_count), self.max_delay)

        # Add jitter
        jitter = random.uniform(0, delay * 0.1)
        total_delay = delay + jitter

        print(f"Retry {self.retry_count + 1}/{self.max_retries} - waiting {total_delay:.2f}s")
        time.sleep(total_delay)

        self.retry_count += 1

    def reset(self):
        """Reset retry counter"""
        self.retry_count = 0

    @property
    def should_retry(self) -> bool:
        """Check if should retry"""
        return self.retry_count < self.max_retries


if __name__ == "__main__":
    # Test rate limiter
    print("Testing rate limiter (0.5 req/sec = 2 sec delay)...")
    limiter = RateLimiter(requests_per_second=0.5)

    for i in range(3):
        start = time.time()
        limiter.wait()
        elapsed = time.time() - start
        print(f"Request {i+1}: waited {elapsed:.2f}s")

    print("\nTesting exponential backoff...")
    backoff = ExponentialBackoff(base_delay=1.0, max_retries=3)

    for i in range(3):
        backoff.wait()
EOF

echo "✓ Rate limiter utility created"
echo ""

# Test Playwright installation
echo "Testing Playwright installation..."
python3 -c "from playwright.sync_api import sync_playwright; print('✓ Playwright import successful')"
echo ""

echo "==================================="
echo "Setup Complete!"
echo ""
echo "Summary:"
echo "  - Virtual environment: venv/"
echo "  - Browser: Chromium (Playwright)"
echo "  - Output directories:"
echo "      scraped-docs/"
echo "      articles/"
echo "      cache/"
echo "  - Rate limiter: rate_limiter.py"
echo ""
echo "To activate the virtual environment:"
echo "  source venv/bin/activate"
echo ""
echo "To start scraping:"
echo "  python scripts/scrape-documentation.py --url https://docs.example.com"
echo "==================================="
