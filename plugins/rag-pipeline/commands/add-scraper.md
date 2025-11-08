---
description: Add web scraping capability (Playwright, Selenium, BeautifulSoup, Scrapy)
argument-hint: [scraper-type]
---
## Available Skills

This commands has access to the following skills from the rag-pipeline plugin:

- **chunking-strategies**: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.
- **document-parsers**: Multi-format document parsing tools for PDF, DOCX, HTML, and Markdown with support for LlamaParse, Unstructured.io, PyPDF2, PDFPlumber, and python-docx. Use when parsing documents, extracting text from PDFs, processing Word documents, converting HTML to text, extracting tables from documents, building RAG pipelines, chunking documents, or when user mentions document parsing, PDF extraction, DOCX processing, table extraction, OCR, LlamaParse, Unstructured.io, or document ingestion.
- **embedding-models**: Embedding model configurations and cost calculators
- **langchain-patterns**: LangChain implementation patterns with templates, scripts, and examples for RAG pipelines
- **llamaindex-patterns**: LlamaIndex implementation patterns with templates, scripts, and examples for building RAG applications. Use when implementing LlamaIndex, building RAG pipelines, creating vector indices, setting up query engines, implementing chat engines, integrating LlamaCloud, or when user mentions LlamaIndex, RAG, VectorStoreIndex, document indexing, semantic search, or question answering systems.
- **retrieval-patterns**: Search and retrieval strategies including semantic, hybrid, and reranking for RAG systems. Use when implementing retrieval mechanisms, optimizing search performance, comparing retrieval approaches, or when user mentions semantic search, hybrid search, reranking, BM25, or retrieval optimization.
- **vector-database-configs**: Vector database configuration and setup for pgvector, Chroma, Pinecone, Weaviate, Qdrant, and FAISS with comparison guide and migration helpers
- **web-scraping-tools**: Web scraping templates, scripts, and patterns for documentation and content collection using Playwright, BeautifulSoup, and Scrapy. Includes rate limiting, error handling, and extraction patterns. Use when scraping documentation, collecting web content, extracting structured data, building RAG knowledge bases, harvesting articles, crawling websites, or when user mentions web scraping, documentation collection, content extraction, Playwright scraping, BeautifulSoup parsing, or Scrapy spiders.

**To use a skill:**
```
!{skill skill-name}
```

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---



## Security Requirements

**CRITICAL:** All generated files must follow security rules:

@docs/security/SECURITY-RULES.md

**Key requirements:**
- Never hardcode API keys or secrets
- Use placeholders: `your_service_key_here`
- Protect `.env` files with `.gitignore`
- Create `.env.example` with placeholders only
- Document key acquisition for users

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
