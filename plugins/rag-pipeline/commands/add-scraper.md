---
description: Add web scraping capability (Playwright, Selenium, BeautifulSoup, Scrapy)
argument-hint: [scraper-type]
allowed-tools: Task, Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion, mcp__playwright
---

**Arguments**: $ARGUMENTS

Goal: Add web scraping capability to RAG pipeline with polite scraping practices (rate limiting, robots.txt)

Core Principles:
- Recommend Playwright for dynamic content, BeautifulSoup for static HTML
- Always implement rate limiting and respect robots.txt
- Generate production-ready scraping scripts with error handling
- Test with sample URL before deployment

Phase 1: Discovery & Requirements
Goal: Determine scraper type and gather requirements

Actions:
- Parse $ARGUMENTS to check if scraper type specified
- If not specified, use AskUserQuestion to ask:
  - What type of content are you scraping? (dynamic JS-heavy sites, static HTML, API endpoints)
  - Do you need JavaScript execution? (Yes = Playwright/Selenium, No = BeautifulSoup/Scrapy)
  - What's the scale? (Few pages = BeautifulSoup, Large scale = Scrapy, Browser automation = Playwright)
  - Sample URL to test?
- Detect project structure:
  - !{bash ls -la | grep -E "requirements.txt|pyproject.toml|package.json"}
  - @requirements.txt (if exists)
  - @package.json (if exists)

Recommendations:
- Playwright: Modern, reliable, great for JS-heavy sites, built-in anti-detection
- BeautifulSoup: Simple, lightweight, perfect for static HTML
- Scrapy: Industrial-scale crawling, async, powerful middleware
- Selenium: Mature, wide browser support, but slower than Playwright

Phase 2: Validation
Goal: Verify environment and prerequisites

Actions:
- Check Python version: !{bash python3 --version}
- Check if virtual environment exists: !{bash ls -la venv .venv 2>/dev/null}
- Identify existing dependencies
- Validate sample URL if provided

Phase 3: Implementation
Goal: Install scraper and generate script with polite scraping practices

Actions:

Task(description="Install scraper and generate script", subagent_type="rag-pipeline:web-scraper-agent", prompt="You are the web-scraper-agent. Add web scraping capability for $ARGUMENTS.

Scraper Selection: Based on Phase 1 discovery, install the recommended scraper.

Installation Tasks:
1. Install scraper package:
   - Playwright: pip install playwright && playwright install
   - BeautifulSoup: pip install beautifulsoup4 requests lxml
   - Scrapy: pip install scrapy
   - Selenium: pip install selenium webdriver-manager

2. Create scraping script at scripts/scraper.py with:
   - Polite scraping practices (rate limiting, delays)
   - Robots.txt checking
   - User-Agent headers
   - Error handling and retries
   - Progress logging
   - Data extraction logic

3. For Playwright specifically:
   - Configure browser settings (headless, viewport)
   - Add stealth plugins if needed
   - Set up screenshots for debugging
   - Use mcp__playwright tool if available

4. Include configuration file (scraper_config.yaml) with:
   - Rate limits (requests per second)
   - Retry settings (max retries, backoff)
   - User-Agent string
   - Robots.txt compliance toggle
   - Output format (JSON, CSV, etc.)

Documentation References:
- Playwright: https://playwright.dev/python/
- BeautifulSoup: https://www.crummy.com/software/BeautifulSoup/bs4/doc/
- Scrapy: https://docs.scrapy.org/
- Selenium: https://selenium-python.readthedocs.io/

Best Practices:
- Always check robots.txt before scraping
- Implement exponential backoff on errors
- Use appropriate delays between requests (1-2 seconds minimum)
- Set descriptive User-Agent with contact info
- Handle pagination gracefully
- Save intermediate results (checkpoint system)

Deliverable: Production-ready scraping script with polite scraping configuration")

Phase 4: Configuration Review
Goal: Ensure polite scraping settings are appropriate

Actions:
- Review generated configuration file
- Check rate limiting settings (should be conservative)
- Verify robots.txt compliance is enabled by default
- Confirm User-Agent includes contact information
- Display configuration to user for approval

Phase 5: Testing
Goal: Validate scraper works with sample URL

Actions:
- If sample URL provided, run test:
  - !{bash python3 scripts/scraper.py --url "SAMPLE_URL" --limit 1}
- Check for errors or warnings
- Verify output format
- Display sample scraped data

Phase 6: Summary
Goal: Document what was added and next steps

Actions:
- Summarize installation:
  - Scraper type installed
  - Dependencies added
  - Script location
  - Configuration file location
- Provide usage examples:
  - How to run scraper
  - How to adjust rate limits
  - How to modify selectors
- Highlight polite scraping features:
  - Rate limiting: X requests per second
  - Robots.txt: Enabled
  - User-Agent: Configured
  - Retry logic: Exponential backoff
- Suggest next steps:
  - Integrate with document loader
  - Add to data ingestion pipeline
  - Set up scheduling (cron/celery)
  - Monitor scraping metrics
