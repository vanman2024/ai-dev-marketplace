# Chunking Strategies Skill

Complete, production-ready document chunking implementations for RAG pipelines.

## Overview

This skill provides functional chunking implementations, benchmarking tools, and configuration templates for processing documents in RAG (Retrieval Augmented Generation) systems.

## Features

- **4 Production-Ready Chunking Strategies**
  - Fixed-size chunking with configurable overlap
  - Semantic chunking preserving paragraph boundaries
  - Recursive chunking for hierarchical documents
  - Benchmarking tool to compare strategies

- **3 Document-Specific Implementations**
  - Markdown chunking (preserves headers, code blocks, lists)
  - Source code chunking (preserves functions, classes, imports)
  - PDF chunking (extracts text, preserves pages)

- **Configuration Templates**
  - Complete YAML configuration template
  - Custom splitter template for implementing your own logic

## Quick Start

### Basic Usage

```bash
# Fixed-size chunking
python scripts/chunk-fixed-size.py \
  --input document.txt \
  --chunk-size 1000 \
  --overlap 200 \
  --output chunks.json

# Semantic chunking
python scripts/chunk-semantic.py \
  --input article.txt \
  --max-chunk-size 1500 \
  --output chunks.json

# Recursive chunking
python scripts/chunk-recursive.py \
  --input README.md \
  --chunk-size 1000 \
  --preset markdown \
  --output chunks.json
```

### Benchmark Strategies

```bash
python scripts/benchmark-chunking.py \
  --input document.txt \
  --strategies fixed,semantic,recursive \
  --chunk-sizes 500,1000,1500 \
  --output benchmark-results.json
```

Output includes:
- Processing time for each strategy
- Chunk count and size statistics
- Context preservation score
- Recommended best strategy

### Document-Specific Chunking

```bash
# Markdown documents
python examples/chunk-markdown.py README.md --output readme-chunks.json

# Source code
python examples/chunk-code.py src/main.py --language python --output code-chunks.json

# PDF documents
python examples/chunk-pdf.py research-paper.pdf --output pdf-chunks.json
```

## File Structure

```
chunking-strategies/
├── SKILL.md                      # Skill documentation
├── README.md                     # This file
├── scripts/
│   ├── chunk-fixed-size.py      # Fixed-size chunking
│   ├── chunk-semantic.py        # Semantic chunking
│   ├── chunk-recursive.py       # Recursive chunking
│   └── benchmark-chunking.py    # Benchmark tool
├── templates/
│   ├── chunking-config.yaml     # Configuration template
│   └── custom-splitter.py       # Custom logic template
└── examples/
    ├── chunk-markdown.py        # Markdown chunking
    ├── chunk-code.py            # Code chunking
    └── chunk-pdf.py             # PDF chunking
```

## Strategy Selection Guide

### Fixed-Size Chunking

**When to use:**
- Uniform documents with consistent structure
- Speed is priority
- Simple content without hierarchy

**Best for:** Plain text articles, basic documentation

**Configuration:**
```bash
python scripts/chunk-fixed-size.py \
  --input doc.txt \
  --chunk-size 1000 \
  --overlap 200 \
  --split-on sentence
```

### Semantic Chunking

**When to use:**
- Natural language documents
- Content with clear paragraphs/sections
- Semantic coherence matters

**Best for:** Articles, blog posts, books, documentation

**Configuration:**
```bash
python scripts/chunk-semantic.py \
  --input article.txt \
  --max-chunk-size 1500 \
  --min-chunk-size 200
```

### Recursive Chunking

**When to use:**
- Hierarchical documents
- Structured content
- Code files

**Best for:** Technical docs, manuals, source code

**Configuration:**
```bash
python scripts/chunk-recursive.py \
  --input doc.md \
  --chunk-size 1000 \
  --preset markdown  # or: python, javascript, text, code
```

## Chunk Size Guidelines

| Content Type | Chunk Size | Overlap | Strategy |
|--------------|------------|---------|----------|
| Q&A / FAQs | 200-400 | 50 | Semantic |
| Articles | 500-1000 | 100-200 | Semantic |
| Documentation | 1000-1500 | 200-300 | Recursive |
| Books | 1000-2000 | 300-400 | Semantic |
| Source code | 500-1000 | 100 | Recursive |

## Output Format

All chunking scripts output JSON with this structure:

```json
{
  "chunks": [
    {
      "text": "chunk content here...",
      "metadata": {
        "chunk_id": 0,
        "chunk_size": 982,
        "source": "document.txt",
        "strategy": "semantic",
        "params": {
          "max_chunk_size": 1000
        }
      }
    }
  ],
  "total_chunks": 127,
  "strategy": "semantic",
  "statistics": {
    "avg_chunk_size": 987.5,
    "min_chunk_size": 456,
    "max_chunk_size": 1498
  }
}
```

## Benchmarking

The benchmark tool compares strategies on multiple metrics:

```bash
python scripts/benchmark-chunking.py \
  --input your-document.txt \
  --strategies fixed,semantic,recursive \
  --chunk-sizes 500,1000,1500 \
  --output results.json
```

**Metrics evaluated:**
- **Processing time**: Speed of chunking operation
- **Chunk count**: Total chunks generated
- **Size variance**: Consistency of chunk sizes (lower is better)
- **Context score**: Semantic boundary preservation (0-1, higher is better)

**Sample output:**
```
============================================================
RESULTS SUMMARY
============================================================
Strategy             Time       Chunks   Context
------------------------------------------------------------
fixed-500            23.4       254      0.720
fixed-1000           45.1       127      0.718
semantic-1000        156.2      114      0.912
recursive-1000       89.7       119      0.854
============================================================

Recommended: semantic-1000
```

## Advanced Usage

### Using Configuration Files

Create `chunking-config.yaml`:

```yaml
chunking:
  default_strategy: semantic
  strategies:
    semantic:
      max_chunk_size: 1500
      min_chunk_size: 200
```

Then use in your code:

```python
import yaml
from pathlib import Path

# Load config
config = yaml.safe_load(Path("chunking-config.yaml").read_text())

# Use appropriate chunker based on config
# (Implementation in your code)
```

### Creating Custom Chunkers

Use the `templates/custom-splitter.py` template:

```python
from custom_splitter import CustomChunker

# Implement your custom logic
class MyChunker(CustomChunker):
    def _custom_split(self, text: str):
        # Your splitting logic here
        return chunks

# Use it
chunker = MyChunker(chunk_size=1000)
chunks = chunker.chunk(document_text)
```

### Batch Processing

```bash
# Process all files in directory
for file in documents/*.txt; do
  python scripts/chunk-semantic.py \
    --input "$file" \
    --output "chunks/$(basename $file .txt).json"
done
```

## Dependencies

**Core (required):**
- Python 3.8+
- No external dependencies for basic chunking

**Optional (for specific features):**

```bash
# For sentence tokenization (improves fixed-size chunking)
pip install nltk

# For PDF support
pip install pypdf

# For benchmarking statistics
pip install numpy pandas
```

## Testing the Scripts

All scripts can be tested individually:

```bash
# Create test document
echo "This is a test document. It has multiple sentences.

This is a new paragraph. With more content.

## Header

More content under header." > test.txt

# Test fixed-size
python scripts/chunk-fixed-size.py --input test.txt --output test-fixed.json

# Test semantic
python scripts/chunk-semantic.py --input test.txt --output test-semantic.json

# Test recursive
python scripts/chunk-recursive.py --input test.txt --preset text --output test-recursive.json

# Compare with benchmark
python scripts/benchmark-chunking.py --input test.txt --output benchmark.json
```

## Best Practices

1. **Always benchmark first** - Use `benchmark-chunking.py` with your actual data
2. **Start with semantic chunking** - Works well for most natural language content
3. **Use recursive for structure** - Best for hierarchical documents and code
4. **Set overlap to 15-20%** - Balances redundancy vs. coverage
5. **Include metadata** - Helps with retrieval and debugging
6. **Test retrieval quality** - Chunk quality affects RAG performance
7. **Match embedding token limits** - Ensure chunks fit in your embedding model

## Common Issues

**Issue: Chunks too small/large**
- Adjust `--chunk-size` parameter
- Check document structure (may need different strategy)

**Issue: Lost context at boundaries**
- Increase `--overlap`
- Switch to semantic chunking
- Enable `--add-parent-headers` for Markdown

**Issue: Slow processing**
- Use fixed-size chunking for large batches
- Reduce overlap
- Process files in parallel

**Issue: Poor retrieval quality**
- Benchmark different strategies
- Increase chunk size
- Try document-specific chunking (Markdown/Code/PDF)

## Integration with RAG Pipeline

After chunking, use chunks for embedding and retrieval:

```python
import json

# Load chunks
with open('chunks.json') as f:
    data = json.load(f)
    chunks = data['chunks']

# Generate embeddings (example with OpenAI)
from openai import OpenAI
client = OpenAI()

for chunk in chunks:
    response = client.embeddings.create(
        input=chunk['text'],
        model="text-embedding-3-small"
    )
    chunk['embedding'] = response.data[0].embedding

# Store in vector database
# ... your vector DB code here ...
```

## Contributing

To add a new chunking strategy:

1. Create new script in `scripts/` or `examples/`
2. Follow the output format (chunks with metadata)
3. Make script executable: `chmod +x your-script.py`
4. Add documentation to this README
5. Test with benchmark tool

## License

Part of the rag-pipeline plugin for Claude Code.

## Support

For issues or questions:
- Check SKILL.md for detailed documentation
- Review examples in `examples/` directory
- Run benchmark to compare strategies on your data
