# Metadata Filtering

Use metadata to enable targeted search across large document collections.

## Overview

Metadata filtering allows you to:
- Search specific document subsets
- Filter by author, date, category, etc.
- Combine semantic search with structured queries
- Build multi-tenant RAG systems

## Adding Metadata During Upload

### Python Example

```python
from google import genai

client = genai.Client(api_key="your_google_api_key_here")

# Upload with metadata
operation = client.file_search_stores.upload_to_file_search_store(
    file="document.pdf",
    file_search_store_name=store_id,
    config={
        "display_name": "Product Documentation",
        "custom_metadata": [
            {"key": "author", "string_value": "Jane Doe"},
            {"key": "year", "numeric_value": 2024},
            {"key": "category", "string_value": "API"},
            {"key": "version", "numeric_value": 2.5},
            {"key": "department", "string_value": "engineering"}
        ]
    }
)
```

### Using the Script

```bash
python scripts/upload_documents.py \
    --file document.pdf \
    --metadata \
        author="Jane Doe" \
        year=2024 \
        category=API \
        version=2.5 \
        department=engineering
```

## Metadata Types

### String Values
Best for categorical data:
- `author`, `category`, `department`
- `status`, `type`, `language`
- `project`, `team`, `source`

### Numeric Values
Best for ranges and comparisons:
- `year`, `version`, `priority`
- `page_count`, `word_count`
- `confidence_score`, `rating`

## Filter Syntax (AIP-160)

### Basic Filters

**Equality:**
```python
metadata_filter="author=Jane Doe"
metadata_filter="category=API"
```

**Numeric Comparisons:**
```python
metadata_filter="year>=2023"
metadata_filter="version>2.0"
metadata_filter="priority<=3"
```

### Compound Filters

**AND - All conditions must match:**
```python
metadata_filter="author=Jane Doe AND year=2024"
metadata_filter="category=API AND version>=2.0"
```

**OR - Any condition can match:**
```python
metadata_filter="category=API OR category=SDK"
metadata_filter="year=2023 OR year=2024"
```

**Complex Combinations:**
```python
metadata_filter="(author=Jane Doe OR author=John Smith) AND year=2024"
metadata_filter="category=API AND (version>=2.0 AND version<3.0)"
```

## Common Use Cases

### 1. Search by Author

```bash
python scripts/search_query.py \
    --query "authentication best practices" \
    --metadata-filter "author=Jane Doe"
```

### 2. Recent Documents Only

```bash
python scripts/search_query.py \
    --query "API changes" \
    --metadata-filter "year>=2024"
```

### 3. Department-Specific Search

```bash
python scripts/search_query.py \
    --query "security policies" \
    --metadata-filter "department=security"
```

### 4. Version-Specific Documentation

```bash
python scripts/search_query.py \
    --query "new features" \
    --metadata-filter "version=2.5"
```

### 5. Multi-Tenant Filtering

```bash
# Each tenant's documents tagged with tenant_id
python scripts/search_query.py \
    --query "billing information" \
    --metadata-filter "tenant_id=customer-123"
```

## Complete Example: Document Management System

```python
#!/usr/bin/env python3
"""Document Management with Metadata Filtering"""

import os
from google import genai
from google.genai import types

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
store_id = os.getenv("GOOGLE_FILE_SEARCH_STORE_ID")

# Upload documents with rich metadata
documents = [
    {
        "file": "api-guide-v2.5.pdf",
        "metadata": [
            {"key": "type", "string_value": "documentation"},
            {"key": "category", "string_value": "API"},
            {"key": "version", "numeric_value": 2.5},
            {"key": "author", "string_value": "Jane Doe"},
            {"key": "year", "numeric_value": 2024},
            {"key": "status", "string_value": "published"}
        ]
    },
    {
        "file": "security-policy-2024.pdf",
        "metadata": [
            {"key": "type", "string_value": "policy"},
            {"key": "category", "string_value": "security"},
            {"key": "department", "string_value": "security"},
            {"key": "year", "numeric_value": 2024},
            {"key": "status", "string_value": "active"}
        ]
    }
]

# Upload all documents
for doc in documents:
    operation = client.file_search_stores.upload_to_file_search_store(
        file=doc["file"],
        file_search_store_name=store_id,
        config={"custom_metadata": doc["metadata"]}
    )
    print(f"Uploaded: {doc['file']}")

# Search with filters
def search_with_filter(query, metadata_filter):
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=query,
        config=types.GenerateContentConfig(
            tools=[
                types.Tool(
                    file_search=types.FileSearch(
                        file_search_store_names=[store_id],
                        metadata_filter=metadata_filter
                    )
                )
            ]
        )
    )
    return response.text

# Query examples
print("\n1. Search only API documentation:")
result = search_with_filter(
    "How do I authenticate?",
    "category=API"
)

print("\n2. Search only 2024 documents:")
result = search_with_filter(
    "What are the new policies?",
    "year=2024"
)

print("\n3. Search published API docs from 2024:")
result = search_with_filter(
    "What's new in version 2.5?",
    "category=API AND year=2024 AND status=published"
)
```

## Metadata Schema Design

### Plan Your Schema

Create a metadata schema document:

```json
{
  "metadata_schema": {
    "required_fields": [
      {"key": "type", "type": "string", "values": ["documentation", "policy", "guide"]},
      {"key": "year", "type": "numeric", "description": "Publication year"},
      {"key": "status", "type": "string", "values": ["draft", "published", "archived"]}
    ],
    "optional_fields": [
      {"key": "author", "type": "string"},
      {"key": "category", "type": "string"},
      {"key": "version", "type": "numeric"},
      {"key": "department", "type": "string"}
    ]
  }
}
```

See: `templates/metadata-schema.json`

### Common Metadata Patterns

**Content Management:**
```python
["type", "category", "status", "version", "author", "created_date"]
```

**Multi-Tenant:**
```python
["tenant_id", "organization", "user_id", "access_level"]
```

**Compliance:**
```python
["classification", "retention_period", "last_reviewed", "compliance_status"]
```

**Academic:**
```python
["authors", "year", "journal", "field", "peer_reviewed", "citation_count"]
```

## Best Practices

1. **Plan Ahead**: Design metadata schema before uploading
2. **Be Consistent**: Use same field names across all documents
3. **Use Enums**: Define allowed values for string fields
4. **Normalize Values**: Use lowercase, consistent formats
5. **Numeric When Possible**: Enables range queries
6. **Document Schema**: Maintain schema documentation
7. **Test Filters**: Verify filters return expected results
8. **Minimal But Sufficient**: Don't over-tag documents

## Troubleshooting

### Filter Returns No Results

Check:
1. Metadata key names match exactly (case-sensitive)
2. String values match exactly (case-sensitive)
3. Numeric comparisons use correct operators
4. Documents have the metadata fields you're filtering on

```bash
# Verify metadata by re-uploading with --verbose
python scripts/upload_documents.py --file doc.pdf --metadata key=value --verbose
```

### Filter Syntax Errors

Common mistakes:
- Missing quotes around string values with spaces: `author="Jane Doe"`
- Using `=` for numeric ranges instead of `>=`, `<=`
- Incorrect operator precedence: use parentheses
- Typos in field names

## Advanced Patterns

### Dynamic Filtering

```python
def build_filter(filters):
    """Build filter string from dict"""
    conditions = []
    for key, value in filters.items():
        if isinstance(value, (int, float)):
            conditions.append(f"{key}={value}")
        else:
            conditions.append(f'{key}="{value}"')
    return " AND ".join(conditions)

# Usage
filters = {"author": "Jane Doe", "year": 2024, "category": "API"}
metadata_filter = build_filter(filters)
# Result: author="Jane Doe" AND year=2024 AND category="API"
```

### Multi-Value Filtering

```python
# Search multiple categories
categories = ["API", "SDK", "CLI"]
category_filter = " OR ".join([f"category={c}" for c in categories])
metadata_filter = f"({category_filter}) AND year=2024"
# Result: (category=API OR category=SDK OR category=CLI) AND year=2024
```

### Date Range Filtering

```python
# Documents from 2020-2024
metadata_filter = "year>=2020 AND year<=2024"

# Recent high-priority docs
metadata_filter = "year>=2023 AND priority<=3"
```

## Next Steps

- **[Grounding Citations](./grounding-citations.md)** - Verify filtered results
- **[Multi-Store Management](./multi-store.md)** - Combine with store organization
- **[Basic Setup](./basic-setup.md)** - Review fundamentals

---

Metadata filtering enables powerful, targeted search across large document collections. Plan your schema carefully for maximum flexibility!
