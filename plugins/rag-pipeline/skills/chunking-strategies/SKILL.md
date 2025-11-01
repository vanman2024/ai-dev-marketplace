---
name: chunking-strategies
description: Document chunking implementations and benchmarking tools for RAG pipelines including fixed-size, semantic, recursive, and sentence-based strategies. Use when implementing document processing, optimizing chunk sizes, comparing chunking approaches, benchmarking retrieval performance, or when user mentions chunking, text splitting, document segmentation, RAG optimization, or chunk evaluation.
allowed-tools: Read, Write, Bash, Glob, Grep, Edit
---

# Chunking Strategies

**Purpose:** Provide production-ready document chunking implementations, benchmarking tools, and strategy selection guidance for RAG pipelines.

**Activation Triggers:**
- Implementing document chunking for RAG
- Optimizing chunk size and overlap
- Comparing different chunking strategies
- Benchmarking chunking performance
- Processing different document types (markdown, code, PDFs)
- Evaluating retrieval quality with different chunk strategies

**Key Resources:**
- `scripts/chunk-fixed-size.py` - Fixed-size chunking implementation
- `scripts/chunk-semantic.py` - Semantic chunking with paragraph preservation
- `scripts/chunk-recursive.py` - Recursive chunking for hierarchical documents
- `scripts/benchmark-chunking.py` - Benchmark and compare chunking strategies
- `templates/chunking-config.yaml` - Chunking configuration template
- `templates/custom-splitter.py` - Template for custom chunking logic
- `examples/chunk-markdown.py` - Markdown-specific chunking
- `examples/chunk-code.py` - Source code chunking
- `examples/chunk-pdf.py` - PDF document chunking

## Chunking Strategy Overview

### Strategy Selection Guide

**Fixed-Size Chunking:**
- Best for: Uniform documents, simple content, consistent structure
- Pros: Fast, predictable, simple implementation
- Cons: May split semantic units, no context awareness
- Use when: Speed matters more than semantic coherence

**Semantic Chunking:**
- Best for: Natural language documents, articles, books
- Pros: Preserves semantic boundaries, better context
- Cons: Slower, variable chunk sizes
- Use when: Content has clear paragraph/section structure

**Recursive Chunking:**
- Best for: Hierarchical documents, technical docs, code
- Pros: Preserves structure, handles nested content
- Cons: Most complex, requires structure detection
- Use when: Documents have clear hierarchical organization

**Sentence-Based Chunking:**
- Best for: Q&A pairs, chatbots, precise retrieval
- Pros: Natural boundaries, good for citations
- Cons: Small chunks may lack context
- Use when: Need precise attribution and citations

## Implementation Scripts

### 1. Fixed-Size Chunking

**Script:** `scripts/chunk-fixed-size.py`

**Usage:**
```bash
python scripts/chunk-fixed-size.py \
  --input document.txt \
  --chunk-size 1000 \
  --overlap 200 \
  --output chunks.json
```

**Parameters:**
- `chunk-size`: Number of characters per chunk (default: 1000)
- `overlap`: Character overlap between chunks (default: 200)
- `split-on`: Split on sentences, words, or characters (default: sentences)

**Best Practices:**
- Use 500-1000 character chunks for most RAG applications
- Set overlap to 10-20% of chunk size
- Split on sentences for better coherence

### 2. Semantic Chunking

**Script:** `scripts/chunk-semantic.py`

**Usage:**
```bash
python scripts/chunk-semantic.py \
  --input document.txt \
  --max-chunk-size 1500 \
  --output chunks.json
```

**How it works:**
1. Detects natural boundaries (paragraphs, headings, line breaks)
2. Groups content while respecting max chunk size
3. Preserves semantic units (paragraphs stay together)
4. Adds context headers for nested sections

**Best for:** Articles, blog posts, documentation, books

### 3. Recursive Chunking

**Script:** `scripts/chunk-recursive.py`

**Usage:**
```bash
python scripts/chunk-recursive.py \
  --input document.md \
  --chunk-size 1000 \
  --separators '["\\n## ", "\\n### ", "\\n\\n", "\\n", " "]' \
  --output chunks.json
```

**How it works:**
1. Tries to split on first separator (e.g., ## headings)
2. If chunks still too large, recursively splits on next separator
3. Continues until all chunks are within size limit
4. Preserves hierarchical context

**Separator hierarchy examples:**
- **Markdown:** `["\\n## ", "\\n### ", "\\n\\n", "\\n", " "]`
- **Python:** `["\\nclass ", "\\ndef ", "\\n\\n", "\\n", " "]`
- **General:** `["\\n\\n", "\\n", ". ", " "]`

**Best for:** Structured documents, source code, technical manuals

### 4. Benchmark Chunking Strategies

**Script:** `scripts/benchmark-chunking.py`

**Usage:**
```bash
python scripts/benchmark-chunking.py \
  --input document.txt \
  --strategies fixed,semantic,recursive \
  --chunk-sizes 500,1000,1500 \
  --output benchmark-results.json
```

**Metrics Evaluated:**
- **Processing time:** Speed of chunking
- **Chunk count:** Total chunks generated
- **Chunk size variance:** Consistency of chunk sizes
- **Context preservation:** Semantic unit integrity (scored)
- **Retrieval quality:** Simulated query performance

**Output:**
```json
{
  "fixed-1000": {
    "time_ms": 45,
    "chunk_count": 127,
    "avg_size": 982,
    "size_variance": 12.3,
    "context_score": 0.72
  },
  "semantic-1000": {
    "time_ms": 156,
    "chunk_count": 114,
    "avg_size": 1087,
    "size_variance": 234.5,
    "context_score": 0.91
  }
}
```

## Configuration Template

**Template:** `templates/chunking-config.yaml`

**Complete configuration:**
```yaml
chunking:
  # Global defaults
  default_strategy: semantic
  default_chunk_size: 1000
  default_overlap: 200

  # Strategy-specific configs
  strategies:
    fixed_size:
      chunk_size: 1000
      overlap: 200
      split_on: sentence  # sentence, word, character

    semantic:
      max_chunk_size: 1500
      min_chunk_size: 200
      preserve_paragraphs: true
      add_headers: true  # Include section headers

    recursive:
      chunk_size: 1000
      overlap: 100
      separators:
        markdown: ["\\n## ", "\\n### ", "\\n\\n", "\\n", " "]
        code: ["\\nclass ", "\\ndef ", "\\n\\n", "\\n", " "]
        text: ["\\n\\n", ". ", " "]

  # Document type mappings
  document_types:
    ".md": semantic
    ".py": recursive
    ".txt": fixed_size
    ".pdf": semantic
```

## Custom Splitter Template

**Template:** `templates/custom-splitter.py`

**Create your own chunking logic:**
```python
from typing import List, Dict
import re

class CustomChunker:
    def __init__(self, chunk_size: int = 1000, overlap: int = 200):
        self.chunk_size = chunk_size
        self.overlap = overlap

    def chunk(self, text: str, metadata: Dict = None) -> List[Dict]:
        """
        Implement custom chunking logic here.

        Returns:
            List of chunks with metadata:
            [
                {
                    "text": "chunk content",
                    "metadata": {
                        "chunk_id": 0,
                        "source": "document.txt",
                        "start_char": 0,
                        "end_char": 1000
                    }
                }
            ]
        """
        chunks = []

        # Your custom chunking logic here
        # Example: Split on custom pattern
        sections = self._split_sections(text)

        for i, section in enumerate(sections):
            chunks.append({
                "text": section,
                "metadata": {
                    "chunk_id": i,
                    "source": metadata.get("source", "unknown"),
                    "chunk_size": len(section)
                }
            })

        return chunks

    def _split_sections(self, text: str) -> List[str]:
        # Implement your splitting logic
        pass
```

## Document-Specific Examples

### Markdown Chunking

**Example:** `examples/chunk-markdown.py`

**Features:**
- Preserves heading hierarchy
- Keeps code blocks together
- Maintains list structure
- Adds parent section context to chunks

**Usage:**
```bash
python examples/chunk-markdown.py README.md --output readme-chunks.json
```

### Code Chunking

**Example:** `examples/chunk-code.py`

**Features:**
- Splits on class and function boundaries
- Preserves complete functions
- Includes docstrings with implementations
- Language-aware separator selection

**Supported languages:** Python, JavaScript, TypeScript, Java, Go

**Usage:**
```bash
python examples/chunk-code.py src/main.py --language python --output code-chunks.json
```

### PDF Chunking

**Example:** `examples/chunk-pdf.py`

**Features:**
- Extracts text from PDF
- Preserves page boundaries
- Maintains formatting clues
- Handles multi-column layouts

**Dependencies:** `pypdf`, `pdfminer.six`

**Usage:**
```bash
python examples/chunk-pdf.py research-paper.pdf --strategy semantic --output pdf-chunks.json
```

## Optimization Guidelines

### Chunk Size Selection

**General recommendations:**
| Content Type | Chunk Size | Overlap | Strategy |
|--------------|------------|---------|----------|
| Q&A / FAQs | 200-400 | 50 | Sentence |
| Articles | 500-1000 | 100-200 | Semantic |
| Documentation | 1000-1500 | 200-300 | Recursive |
| Books | 1000-2000 | 300-400 | Semantic |
| Source code | 500-1000 | 100 | Recursive |

**Test with your data:** Use `benchmark-chunking.py` to find optimal settings

### Overlap Strategies

**Why overlap matters:**
- Prevents information loss at boundaries
- Improves retrieval of cross-boundary information
- Balances redundancy vs. coverage

**Overlap guidelines:**
- **10-15%**: Minimal overlap for speed
- **15-20%**: Standard overlap for most use cases
- **20-30%**: High overlap for critical applications

### Performance Optimization

**Fast chunking (large documents):**
```bash
# Use fixed-size for speed
python scripts/chunk-fixed-size.py --input large-doc.txt --chunk-size 1000
```

**Quality chunking (smaller documents):**
```bash
# Use semantic for better context
python scripts/chunk-semantic.py --input article.txt --max-chunk-size 1500
```

**Batch processing:**
```bash
# Process multiple files
for file in documents/*.txt; do
  python scripts/chunk-semantic.py --input "$file" --output "chunks/$(basename $file .txt).json"
done
```

## Evaluation Workflow

### Step 1: Benchmark Strategies

```bash
python scripts/benchmark-chunking.py \
  --input sample-document.txt \
  --strategies fixed,semantic,recursive \
  --chunk-sizes 500,1000,1500
```

### Step 2: Analyze Results

**Review metrics:**
- Processing time (prefer < 100ms per document)
- Context preservation score (target > 0.85)
- Chunk size variance (lower is more predictable)

### Step 3: A/B Test Retrieval

**Compare retrieval quality:**
1. Chunk same corpus with different strategies
2. Run identical test queries against each
3. Measure precision@k and recall@k
4. Select strategy with best retrieval metrics

### Step 4: Production Deployment

**Use configuration file:**
```python
import yaml
from chunking_strategies import get_chunker

config = yaml.safe_load(open('chunking-config.yaml'))
chunker = get_chunker(config['chunking']['default_strategy'], config)

chunks = chunker.chunk(document_text)
```

## Common Issues & Solutions

**Issue: Chunks too small/large**
- Adjust `chunk_size` parameter
- Check document structure (may need different strategy)
- Verify separator selection for recursive chunking

**Issue: Lost context at boundaries**
- Increase overlap
- Switch to semantic chunking
- Add parent context to metadata

**Issue: Slow processing**
- Use fixed-size chunking for large batches
- Reduce overlap
- Process files in parallel

**Issue: Poor retrieval quality**
- Benchmark different strategies
- Increase chunk size
- Try hybrid approach (semantic + fixed fallback)

## Dependencies

**Core libraries:**
```bash
pip install tiktoken  # Token counting
pip install nltk      # Sentence splitting
pip install spacy     # Advanced NLP (optional)
```

**For PDF support:**
```bash
pip install pypdf pdfminer.six
```

**For benchmarking:**
```bash
pip install pandas numpy scikit-learn
```

## Best Practices Summary

1. Start with semantic chunking for most documents
2. Use recursive chunking for structured/hierarchical content
3. Benchmark on your actual data before production
4. Set overlap to 15-20% of chunk size
5. Include metadata (source, page, section) in chunks
6. Test retrieval quality, not just chunking speed
7. Use appropriate chunk size for your embedding model token limit
8. Document your chunking strategy choice and parameters

---

**Supported Strategies:** Fixed-Size, Semantic, Recursive, Sentence-Based, Custom
**Output Format:** JSON with text and metadata
**Version:** 1.0.0
