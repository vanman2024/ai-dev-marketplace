# Advanced Chunking Strategies

Optimize document chunking for different content types and use cases.

## Overview

Chunking strategy significantly impacts:
- **Search Quality**: Better chunks = more relevant results
- **Context Preservation**: Overlap prevents information loss
- **Performance**: Optimal sizes improve retrieval speed
- **Costs**: Larger chunks = more tokens = higher indexing costs

## Understanding Chunking

### What is Chunking?

File Search automatically splits documents into smaller segments (chunks) for indexing:

```
Document: 5000 tokens
         ↓ (chunking)
Chunks: [200] [200] [200] [200] [200] ... (25 chunks)
```

Each chunk:
- Has max token limit (configurable)
- Overlaps with adjacent chunks (configurable)
- Gets its own embedding vector
- Is independently searchable

### Why Overlap Matters

Overlap preserves context across boundaries:

```
Chunk 1: [tokens 1-200]
Overlap: [tokens 181-200]
Chunk 2: [tokens 181-380]
```

Without overlap, information spanning chunk boundaries would be lost.

## Chunking Presets

Use `configure_chunking.py` to generate configurations:

```bash
python scripts/configure_chunking.py --list-presets
```

Output:
```
📋 Available Presets:

  small                - Small chunks for code and structured data
                         Max tokens: 100, Overlap: 10

  medium               - Medium chunks for general content
                         Max tokens: 200, Overlap: 20

  large                - Large chunks for technical documentation
                         Max tokens: 500, Overlap: 50

  technical-docs       - Optimized for technical documentation
                         Max tokens: 400, Overlap: 40

  legal                - Precise boundaries for legal documents
                         Max tokens: 300, Overlap: 30

  code                 - Function-level chunks for code
                         Max tokens: 150, Overlap: 15

  scientific           - Section-based chunks for scientific papers
                         Max tokens: 500, Overlap: 75
```

## Strategy 1: Code Repositories

**Challenge**: Code has natural boundaries (functions, classes) that should be preserved.

**Solution**: Small chunks with minimal overlap

```bash
python scripts/configure_chunking.py \
    --preset code \
    --output chunking-code.json
```

Configuration:
```json
{
  "chunking_config": {
    "white_space_config": {
      "max_tokens_per_chunk": 150,
      "max_overlap_tokens": 15
    }
  }
}
```

**Use for:**
- Source code files (.py, .js, .ts, .java)
- API implementations
- Configuration files
- Script collections

**Upload example:**
```bash
python scripts/upload_documents.py \
    --dir ./src \
    --chunking-config chunking-code.json \
    --metadata language=python project=api-server
```

## Strategy 2: Technical Documentation

**Challenge**: Technical docs have dense information requiring more context.

**Solution**: Larger chunks with significant overlap

```bash
python scripts/configure_chunking.py \
    --max-tokens 400 \
    --overlap 40 \
    --output chunking-techdocs.json
```

Configuration:
```json
{
  "chunking_config": {
    "white_space_config": {
      "max_tokens_per_chunk": 400,
      "max_overlap_tokens": 40
    }
  }
}
```

**Use for:**
- API documentation
- Technical specifications
- Architecture guides
- Installation manuals

**Benefits:**
- Captures complete concepts
- Preserves technical context
- Better for detailed queries

## Strategy 3: Legal Documents

**Challenge**: Legal text requires precise boundaries and citation accuracy.

**Solution**: Medium chunks with moderate overlap

```bash
python scripts/configure_chunking.py \
    --preset legal \
    --output chunking-legal.json
```

Configuration:
```json
{
  "chunking_config": {
    "white_space_config": {
      "max_tokens_per_chunk": 300,
      "max_overlap_tokens": 30
    }
  }
}
```

**Use for:**
- Contracts and agreements
- Legal opinions
- Compliance documents
- Terms of service

**Upload with metadata:**
```bash
python scripts/upload_documents.py \
    --file contract.pdf \
    --chunking-config chunking-legal.json \
    --metadata \
        document_type=contract \
        party_a="Company Inc" \
        effective_date=2024-01-01 \
        jurisdiction=NY
```

## Strategy 4: Scientific Papers

**Challenge**: Scientific papers have logical sections (abstract, methods, results) that should stay together.

**Solution**: Large chunks with high overlap

```bash
python scripts/configure_chunking.py \
    --preset scientific \
    --output chunking-science.json
```

Configuration:
```json
{
  "chunking_config": {
    "white_space_config": {
      "max_tokens_per_chunk": 500,
      "max_overlap_tokens": 75
    }
  }
}
```

**Use for:**
- Research papers
- Academic articles
- Study reports
- Literature reviews

**Upload with metadata:**
```bash
python scripts/upload_documents.py \
    --file paper.pdf \
    --chunking-config chunking-science.json \
    --metadata \
        authors="Smith et al." \
        year=2024 \
        field=machine-learning \
        peer_reviewed=true
```

## Strategy 5: General Content (Blogs, Articles)

**Challenge**: Varied content structure, mixed topics.

**Solution**: Medium chunks (default settings work well)

```bash
python scripts/configure_chunking.py \
    --preset medium \
    --output chunking-general.json
```

Configuration:
```json
{
  "chunking_config": {
    "white_space_config": {
      "max_tokens_per_chunk": 200,
      "max_overlap_tokens": 20
    }
  }
}
```

**Use for:**
- Blog posts
- News articles
- Marketing content
- General documentation

**Good for:** Most use cases when unsure of optimal settings.

## Custom Chunking for Mixed Content

If you have documents of varying types in one store:

### Approach 1: Conservative Middle Ground
```bash
python scripts/configure_chunking.py \
    --max-tokens 250 \
    --overlap 25 \
    --output chunking-mixed.json
```

Balances between code (small) and documents (large).

### Approach 2: Multiple Stores
Create separate stores with optimized chunking for each type:

```bash
# Code store
python scripts/setup_file_search.py --name "Code Repository Store"
python scripts/upload_documents.py --dir ./src --chunking-config chunking-code.json

# Docs store
python scripts/setup_file_search.py --name "Documentation Store"
python scripts/upload_documents.py --dir ./docs --chunking-config chunking-techdocs.json
```

## Measuring Chunking Effectiveness

### Test Your Configuration

1. **Upload sample documents:**
```bash
python scripts/upload_documents.py \
    --file sample.pdf \
    --chunking-config your-config.json
```

2. **Run test queries:**
```bash
python scripts/search_query.py --query "specific technical term"
```

3. **Evaluate results:**
   - Are relevant passages retrieved?
   - Is context preserved?
   - Are citations accurate?

### Iterate and Adjust

If results are poor:

**Problem**: Results too fragmented
- **Solution**: Increase max_tokens_per_chunk
- **Try**: +50-100 tokens at a time

**Problem**: Missing context across boundaries
- **Solution**: Increase overlap
- **Try**: 15-20% of chunk size

**Problem**: Irrelevant results
- **Solution**: Decrease max_tokens_per_chunk
- **Try**: Smaller, more focused chunks

**Problem**: High costs
- **Solution**: Reduce chunk size or overlap
- **Trade-off**: May reduce quality

## Complete Example: Multi-Content Project

Project structure:
```
project/
├── docs/           # Technical docs (400 tokens)
├── src/            # Source code (150 tokens)
├── papers/         # Research papers (500 tokens)
└── blog/           # Blog posts (200 tokens)
```

Setup script (`setup_chunking.sh`):
```bash
#!/bin/bash

# Generate configs for each content type
python scripts/configure_chunking.py --preset code --output chunking-code.json
python scripts/configure_chunking.py --preset technical-docs --output chunking-docs.json
python scripts/configure_chunking.py --preset scientific --output chunking-papers.json
python scripts/configure_chunking.py --preset medium --output chunking-blog.json

# Create separate stores
python scripts/setup_file_search.py --name "Code Store"
CODE_STORE_ID=$(grep STORE_ID .env.file-search | cut -d'=' -f2)

python scripts/setup_file_search.py --name "Docs Store"
DOCS_STORE_ID=$(grep STORE_ID .env.file-search | cut -d'=' -f2)

# Upload with appropriate configs
python scripts/upload_documents.py --dir ./src --chunking-config chunking-code.json
python scripts/upload_documents.py --dir ./docs --chunking-config chunking-docs.json
python scripts/upload_documents.py --dir ./papers --chunking-config chunking-papers.json
python scripts/upload_documents.py --dir ./blog --chunking-config chunking-blog.json

echo "✅ All content uploaded with optimized chunking"
```

## Best Practices

1. **Start with presets** - Use built-in presets as starting points
2. **Test and iterate** - Measure quality with real queries
3. **Document your choices** - Record which config works for which content
4. **Monitor costs** - Larger chunks = higher indexing costs
5. **Separate by type** - Use different stores for vastly different content
6. **Overlap is key** - Don't skip overlap; it preserves context
7. **Think token-wise** - 1 token ≈ 4 characters or 0.75 words

## Troubleshooting

### Chunks Too Small
**Symptoms:**
- Fragmented search results
- Missing context in responses
- Many citations for simple queries

**Fix:**
```bash
# Increase chunk size by 50-100 tokens
python scripts/configure_chunking.py --max-tokens 300 --overlap 30
```

### Chunks Too Large
**Symptoms:**
- Irrelevant results in searches
- Citations include unrelated content
- High indexing costs

**Fix:**
```bash
# Decrease chunk size
python scripts/configure_chunking.py --max-tokens 150 --overlap 15
```

### Lost Context
**Symptoms:**
- Incomplete answers
- References to "earlier sections" that aren't present
- Broken concept continuity

**Fix:**
```bash
# Increase overlap percentage
python scripts/configure_chunking.py --max-tokens 200 --overlap 40  # 20% overlap
```

## Reference Table

| Content Type | Max Tokens | Overlap | Preset |
|-------------|-----------|---------|--------|
| Code | 150 | 15 (10%) | `code` |
| Blog Posts | 200 | 20 (10%) | `medium` |
| API Docs | 400 | 40 (10%) | `technical-docs` |
| Legal Docs | 300 | 30 (10%) | `legal` |
| Research Papers | 500 | 75 (15%) | `scientific` |
| General Docs | 200 | 20 (10%) | `medium` |

## Next Steps

- **[Metadata Filtering](./metadata-filtering.md)** - Combine chunking with metadata
- **[Grounding Citations](./grounding-citations.md)** - Verify chunk retrieval
- **[Multi-Store Management](./multi-store.md)** - Organize by content type

---

Effective chunking is the foundation of high-quality RAG systems. Experiment with different strategies to find what works best for your content!
