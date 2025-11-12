# Grounding Citations

Extract and display source citations to verify AI-generated responses against source documents.

## Overview

Grounding citations provide:
- **Source Attribution**: Show which documents support the response
- **Fact Verification**: Enable users to check claims
- **Trust Building**: Transparent sourcing increases credibility
- **Audit Trail**: Track which content influenced responses

## Understanding Grounding Metadata

When you query with File Search, responses include grounding metadata:

```python
response.candidates[0].grounding_metadata
├── grounding_chunks[]       # Retrieved document chunks
│   ├── chunk_id            # Unique identifier
│   ├── content             # Chunk text content
│   └── score               # Relevance score
└── retrieval_metadata      # Additional retrieval info
    └── results[]           # Retrieved document info
```

## Basic Citation Extraction

### Python Example

```python
from google import genai
from google.genai import types
import os

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
store_id = os.getenv("GOOGLE_FILE_SEARCH_STORE_ID")

# Execute search
response = client.models.generate_content(
    model="gemini-2.5-flash",
    contents="What are the security best practices?",
    config=types.GenerateContentConfig(
        tools=[
            types.Tool(
                file_search=types.FileSearch(
                    file_search_store_names=[store_id]
                )
            )
        ]
    )
)

# Extract citations
if response.candidates:
    candidate = response.candidates[0]
    if hasattr(candidate, 'grounding_metadata'):
        grounding = candidate.grounding_metadata

        print("📚 Source Citations:\n")
        if hasattr(grounding, 'grounding_chunks'):
            for i, chunk in enumerate(grounding.grounding_chunks, 1):
                print(f"[{i}] Chunk ID: {chunk.chunk_id}")
                print(f"    Relevance: {chunk.score if hasattr(chunk, 'score') else 'N/A'}")
                snippet = chunk.content[:150] + "..." if len(chunk.content) > 150 else chunk.content
                print(f"    Content: {snippet}\n")
```

### Using the Script

```bash
# Extract citations from live query
python scripts/extract_citations.py \
    --store $GOOGLE_FILE_SEARCH_STORE_ID \
    --query "What are the security best practices?" \
    --extract

# Save citations to JSON
python scripts/extract_citations.py \
    --store $GOOGLE_FILE_SEARCH_STORE_ID \
    --query "What are the security best practices?" \
    --extract \
    --format json \
    --output citations.json

# Save as Markdown
python scripts/extract_citations.py \
    --store $GOOGLE_FILE_SEARCH_STORE_ID \
    --query "What are the security best practices?" \
    --extract \
    --format markdown \
    --output citations.md
```

## Citation Display Patterns

### Pattern 1: Inline Citations

Show citation numbers in the response text:

```python
def format_response_with_citations(response):
    """Format response with inline citation markers"""
    text = response.text
    citations = []

    if response.candidates:
        grounding = response.candidates[0].grounding_metadata
        if hasattr(grounding, 'grounding_chunks'):
            citations = list(grounding.grounding_chunks)

    # Display response with citation markers
    print(text)

    # Display citation details
    if citations:
        print("\n─── Sources ───\n")
        for i, citation in enumerate(citations, 1):
            print(f"[{i}] {citation.content[:100]}...")

# Usage
response = client.models.generate_content(...)
format_response_with_citations(response)
```

Output:
```
Authentication requires API keys obtained from the developer portal [1].
Keys should be rotated every 90 days [2] and stored securely [3].

─── Sources ───

[1] API keys can be generated from the developer portal at https://...
[2] For security compliance, all API keys must be rotated quarterly...
[3] Store API keys in environment variables or secure vaults, never...
```

### Pattern 2: Footnote Citations

```python
def format_with_footnotes(response):
    """Format response with footnote-style citations"""
    text = response.text
    citations = extract_citations(response)

    print(text)
    print("\n" + "─" * 80)
    print("\nReferences:\n")

    for i, citation in enumerate(citations, 1):
        print(f"[{i}] Chunk {citation['chunk_id']}")
        print(f"    {citation['content'][:200]}...\n")

# Usage
format_with_footnotes(response)
```

### Pattern 3: Sidebar Citations (UI)

For web applications, show citations in a sidebar:

```typescript
// React component example
interface Citation {
  chunk_id: string;
  content: string;
  score?: number;
}

function ResponseWithCitations({ response, citations }: Props) {
  return (
    <div className="flex gap-4">
      <div className="flex-1">
        <ResponseText text={response.text} />
      </div>
      <div className="w-80 border-l pl-4">
        <h3 className="font-semibold mb-2">Sources</h3>
        {citations.map((citation, i) => (
          <CitationCard
            key={citation.chunk_id}
            number={i + 1}
            citation={citation}
          />
        ))}
      </div>
    </div>
  );
}
```

## Building a Citation UI

### Complete Python Example

```python
#!/usr/bin/env python3
"""Citation UI Builder - Generate HTML with citations"""

import os
from google import genai
from google.genai import types

class CitationBuilder:
    def __init__(self, api_key):
        self.client = genai.Client(api_key=api_key)

    def search_with_citations(self, store_id, query):
        """Execute search and return response with citations"""
        response = self.client.models.generate_content(
            model="gemini-2.5-flash",
            contents=query,
            config=types.GenerateContentConfig(
                tools=[
                    types.Tool(
                        file_search=types.FileSearch(
                            file_search_store_names=[store_id]
                        )
                    )
                ]
            )
        )

        citations = []
        if response.candidates:
            grounding = response.candidates[0].grounding_metadata
            if hasattr(grounding, 'grounding_chunks'):
                for chunk in grounding.grounding_chunks:
                    citations.append({
                        'chunk_id': chunk.chunk_id,
                        'content': chunk.content,
                        'score': getattr(chunk, 'score', None)
                    })

        return {
            'response': response.text,
            'citations': citations
        }

    def format_as_html(self, result):
        """Format result as HTML with citations"""
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <title>Response with Citations</title>
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 1200px; margin: 40px auto; padding: 0 20px; }}
        .container {{ display: flex; gap: 40px; }}
        .response {{ flex: 1; }}
        .citations {{ width: 400px; background: #f5f5f5; padding: 20px; border-radius: 8px; }}
        .citation {{ background: white; padding: 15px; margin-bottom: 15px; border-radius: 5px; border-left: 3px solid #4CAF50; }}
        .citation-number {{ font-weight: bold; color: #4CAF50; }}
        .citation-content {{ font-size: 14px; color: #555; margin-top: 10px; }}
        .score {{ font-size: 12px; color: #888; }}
    </style>
</head>
<body>
    <h1>AI Response with Source Citations</h1>
    <div class="container">
        <div class="response">
            <h2>Response</h2>
            <p>{result['response']}</p>
        </div>
        <div class="citations">
            <h3>Sources</h3>
"""

        for i, citation in enumerate(result['citations'], 1):
            score_text = f"Relevance: {citation['score']:.2f}" if citation['score'] else ""
            content_preview = citation['content'][:200] + "..." if len(citation['content']) > 200 else citation['content']

            html += f"""
            <div class="citation">
                <div class="citation-number">[{i}]</div>
                <div class="score">{score_text}</div>
                <div class="citation-content">{content_preview}</div>
            </div>
"""

        html += """
        </div>
    </div>
</body>
</html>
"""
        return html

# Usage
builder = CitationBuilder(api_key=os.getenv("GOOGLE_API_KEY"))
result = builder.search_with_citations(
    store_id=os.getenv("GOOGLE_FILE_SEARCH_STORE_ID"),
    query="What are the authentication methods?"
)

html = builder.format_as_html(result)
with open("response_with_citations.html", "w") as f:
    f.write(html)

print("✅ Generated: response_with_citations.html")
```

### FastAPI Endpoint Example

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google import genai
import os

app = FastAPI()
client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

class SearchRequest(BaseModel):
    query: str
    store_id: str

class Citation(BaseModel):
    chunk_id: str
    content: str
    score: float | None

class SearchResponse(BaseModel):
    answer: str
    citations: list[Citation]

@app.post("/search", response_model=SearchResponse)
async def search_with_citations(request: SearchRequest):
    """Search with automatic citation extraction"""
    try:
        response = client.models.generate_content(
            model="gemini-2.5-flash",
            contents=request.query,
            config=types.GenerateContentConfig(
                tools=[
                    types.Tool(
                        file_search=types.FileSearch(
                            file_search_store_names=[request.store_id]
                        )
                    )
                ]
            )
        )

        citations = []
        if response.candidates:
            grounding = response.candidates[0].grounding_metadata
            if hasattr(grounding, 'grounding_chunks'):
                for chunk in grounding.grounding_chunks:
                    citations.append(Citation(
                        chunk_id=chunk.chunk_id,
                        content=chunk.content,
                        score=getattr(chunk, 'score', None)
                    ))

        return SearchResponse(
            answer=response.text,
            citations=citations
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

## Citation Analysis

### Measuring Citation Coverage

```python
def analyze_citations(response):
    """Analyze citation quality and coverage"""
    if not response.candidates:
        return {"error": "No candidates in response"}

    grounding = response.candidates[0].grounding_metadata
    if not hasattr(grounding, 'grounding_chunks'):
        return {"error": "No citations found"}

    chunks = grounding.grounding_chunks

    analysis = {
        "total_citations": len(chunks),
        "avg_score": sum(getattr(c, 'score', 0) for c in chunks) / len(chunks) if chunks else 0,
        "high_quality_citations": sum(1 for c in chunks if getattr(c, 'score', 0) > 0.8),
        "chunks_by_score": {
            "excellent (>0.9)": sum(1 for c in chunks if getattr(c, 'score', 0) > 0.9),
            "good (0.7-0.9)": sum(1 for c in chunks if 0.7 <= getattr(c, 'score', 0) <= 0.9),
            "fair (<0.7)": sum(1 for c in chunks if getattr(c, 'score', 0) < 0.7)
        }
    }

    return analysis

# Usage
result = client.models.generate_content(...)
analysis = analyze_citations(result)
print(f"Citation Analysis: {analysis}")
```

## Best Practices

1. **Always Display Citations**: Build trust by showing sources
2. **Make Citations Clickable**: Link to source documents when possible
3. **Show Relevance Scores**: Help users assess citation quality
4. **Limit Display**: Show top 3-5 most relevant citations
5. **Provide Full Access**: Allow expanding to see all citations
6. **Track Coverage**: Monitor what percentage of responses have citations
7. **Enable Verification**: Let users click through to original content

## Troubleshooting

### No Citations Returned

Check:
1. Documents are successfully indexed
2. Query matches indexed content
3. File Search tool is properly configured
4. Store ID is correct

### Low-Quality Citations

If citation relevance scores are low:
1. Improve chunking configuration
2. Add more relevant documents
3. Refine query phrasing
4. Check document quality (readable text)

### Missing Content in Citations

If citation.content is truncated:
- This is expected for display purposes
- Store full content if needed for verification
- Link to original document for complete context

## Next Steps

- **[Metadata Filtering](./metadata-filtering.md)** - Filter citations by metadata
- **[Multi-Store Management](./multi-store.md)** - Organize citation sources
- **[Basic Setup](./basic-setup.md)** - Review fundamentals

---

Grounding citations transform AI responses from "black box" answers to transparent, verifiable information backed by real sources!
