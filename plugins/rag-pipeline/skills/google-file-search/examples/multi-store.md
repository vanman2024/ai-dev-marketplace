# Multi-Store Management

Organize documents across multiple file search stores for better performance and organization.

## Overview

Multiple stores enable:
- **Domain Separation**: Separate stores by topic, project, or team
- **Performance Optimization**: Smaller stores = faster retrieval
- **Access Control**: Different stores for different user groups
- **Cost Management**: Track costs per domain
- **Tenant Isolation**: Multi-tenant applications

## When to Use Multiple Stores

### Use Multiple Stores When:

1. **Different Domains**: Technical docs vs. marketing content vs. legal docs
2. **Large Document Collections**: >20 GB in one domain
3. **Multi-Tenant Systems**: Each customer needs isolated data
4. **Different Chunking Strategies**: Code vs. prose vs. scientific papers
5. **Access Patterns Differ**: Some content frequently accessed, some rarely

### Use Single Store When:

1. **Small Collection**: <5 GB total
2. **Homogeneous Content**: All similar document types
3. **Cross-Domain Search Needed**: Frequent need to search everything
4. **Simple Use Case**: Getting started or prototyping

## Creating Multiple Stores

### Option 1: Script-Based Creation

```bash
# Create stores for different domains
python scripts/setup_file_search.py --name "Technical Documentation" --output .env.docs
python scripts/setup_file_search.py --name "Code Repository" --output .env.code
python scripts/setup_file_search.py --name "Marketing Content" --output .env.marketing
python scripts/setup_file_search.py --name "Legal Documents" --output .env.legal
```

### Option 2: Python Program

```python
#!/usr/bin/env python3
"""Create multiple organized stores"""

from google import genai
import os

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# Define store structure
stores = {
    "docs": {"name": "Technical Documentation", "description": "API guides and technical specs"},
    "code": {"name": "Code Repository", "description": "Source code and examples"},
    "blog": {"name": "Blog Posts", "description": "Marketing and educational content"},
    "legal": {"name": "Legal Documents", "description": "Contracts and compliance docs"}
}

# Create all stores
created_stores = {}
for key, config in stores.items():
    store = client.file_search_stores.create(
        config={
            "display_name": config["name"],
            "description": config["description"]
        }
    )
    created_stores[key] = store.name
    print(f"✅ Created: {config['name']} ({store.name})")

# Save store IDs to file
with open(".env.stores", "w") as f:
    for key, store_id in created_stores.items():
        f.write(f"STORE_{key.upper()}={store_id}\n")

print("\n💾 Store IDs saved to .env.stores")
print("Source this file: source .env.stores")
```

## Uploading to Different Stores

### Organize Content by Store

```bash
# Source all store IDs
source .env.stores

# Upload to appropriate stores with optimized chunking
python scripts/upload_documents.py \
    --store $STORE_DOCS \
    --dir ./documentation \
    --chunking-config chunking-techdocs.json \
    --metadata category=documentation

python scripts/upload_documents.py \
    --store $STORE_CODE \
    --dir ./src \
    --chunking-config chunking-code.json \
    --metadata category=code language=python

python scripts/upload_documents.py \
    --store $STORE_BLOG \
    --dir ./blog-posts \
    --chunking-config chunking-general.json \
    --metadata category=marketing

python scripts/upload_documents.py \
    --store $STORE_LEGAL \
    --dir ./legal \
    --chunking-config chunking-legal.json \
    --metadata category=legal confidential=true
```

## Searching Across Multiple Stores

### Option 1: Search One Store at a Time

```python
from google import genai
from google.genai import types
import os

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))

# Search specific store
def search_store(store_id, query):
    response = client.models.generate_content(
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
    return response.text

# Search only documentation
docs_result = search_store(os.getenv("STORE_DOCS"), "How do I authenticate?")

# Search only code
code_result = search_store(os.getenv("STORE_CODE"), "Show me auth examples")
```

### Option 2: Search Multiple Stores Simultaneously

```python
def search_multiple_stores(store_ids, query):
    """Search multiple stores in one query"""
    response = client.models.generate_content(
        model="gemini-2.5-flash",
        contents=query,
        config=types.GenerateContentConfig(
            tools=[
                types.Tool(
                    file_search=types.FileSearch(
                        file_search_store_names=store_ids  # Pass multiple IDs
                    )
                )
            ]
        )
    )
    return response.text

# Search both docs and code stores
result = search_multiple_stores(
    [os.getenv("STORE_DOCS"), os.getenv("STORE_CODE")],
    "authentication examples"
)
```

### Option 3: Smart Store Selection

```python
class StoreRouter:
    """Route queries to appropriate stores based on intent"""

    def __init__(self, client):
        self.client = client
        self.stores = {
            "documentation": os.getenv("STORE_DOCS"),
            "code": os.getenv("STORE_CODE"),
            "marketing": os.getenv("STORE_BLOG"),
            "legal": os.getenv("STORE_LEGAL")
        }

    def route_query(self, query):
        """Determine which store(s) to search based on query"""
        query_lower = query.lower()

        # Simple keyword-based routing
        if any(word in query_lower for word in ["code", "example", "implementation"]):
            return [self.stores["code"]]
        elif any(word in query_lower for word in ["contract", "legal", "terms"]):
            return [self.stores["legal"]]
        elif any(word in query_lower for word in ["blog", "tutorial", "guide"]):
            return [self.stores["marketing"]]
        else:
            # Default to documentation
            return [self.stores["documentation"]]

    def search(self, query):
        """Search appropriate store(s)"""
        store_ids = self.route_query(query)
        return search_multiple_stores(store_ids, query)

# Usage
router = StoreRouter(client)
result = router.search("How do I implement OAuth?")  # Routes to code store
```

## Store Management Operations

### List All Stores

```python
def list_all_stores():
    """List all file search stores with metadata"""
    stores = list(client.file_search_stores.list())

    print(f"📚 Total Stores: {len(stores)}\n")
    for store in stores:
        print(f"  • {store.display_name}")
        print(f"    ID: {store.name}")
        if hasattr(store, 'description'):
            print(f"    Description: {store.description}")
        if hasattr(store, 'create_time'):
            print(f"    Created: {store.create_time}")
        print()

list_all_stores()
```

### Store Statistics

```python
def get_store_stats(store_id):
    """Get statistics about a store"""
    store = client.file_search_stores.get(name=store_id)

    print(f"📊 Store: {store.display_name}")
    print(f"   ID: {store.name}")
    # Add more stats as available from API
    return store

# Get stats for each store
for key in ["STORE_DOCS", "STORE_CODE", "STORE_BLOG", "STORE_LEGAL"]:
    store_id = os.getenv(key)
    if store_id:
        get_store_stats(store_id)
        print()
```

### Delete Unused Stores

```python
def cleanup_stores(keep_stores):
    """Delete all stores except those in keep_stores list"""
    all_stores = list(client.file_search_stores.list())

    for store in all_stores:
        if store.name not in keep_stores:
            print(f"🗑️  Deleting: {store.display_name}")
            client.file_search_stores.delete(
                name=store.name,
                config={"force": True}
            )

# Keep only specific stores
keep = [
    os.getenv("STORE_DOCS"),
    os.getenv("STORE_CODE")
]
# cleanup_stores(keep)  # Uncomment to execute
```

## Multi-Tenant Architecture

### Tenant Isolation Pattern

```python
class TenantStoreManager:
    """Manage isolated stores per tenant"""

    def __init__(self, client):
        self.client = client
        self.tenant_stores = {}  # Cache tenant -> store_id mapping

    def get_or_create_tenant_store(self, tenant_id):
        """Get existing or create new store for tenant"""
        if tenant_id in self.tenant_stores:
            return self.tenant_stores[tenant_id]

        # Create tenant-specific store
        store = self.client.file_search_stores.create(
            config={
                "display_name": f"Tenant {tenant_id} Documents",
                "description": f"Isolated store for tenant {tenant_id}"
            }
        )

        self.tenant_stores[tenant_id] = store.name
        return store.name

    def search_tenant_store(self, tenant_id, query):
        """Search within tenant's isolated store"""
        store_id = self.get_or_create_tenant_store(tenant_id)

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
        return response.text

# Usage
manager = TenantStoreManager(client)

# Each tenant gets isolated search
result_tenant_a = manager.search_tenant_store("tenant-a", "my documents")
result_tenant_b = manager.search_tenant_store("tenant-b", "my documents")
# Results are completely isolated by tenant
```

## Best Practices

1. **Naming Convention**: Use clear, descriptive names
   - Good: "Technical-Documentation-2024"
   - Bad: "Store1", "MyStore"

2. **Document Store Structure**: Keep a registry
   ```json
   {
     "stores": {
       "docs": {"id": "fileSearchStores/abc", "purpose": "API documentation"},
       "code": {"id": "fileSearchStores/xyz", "purpose": "Source code examples"}
     }
   }
   ```

3. **Size Management**: Keep stores under 20 GB for optimal performance

4. **Regular Cleanup**: Delete unused stores to manage costs

5. **Consistent Metadata**: Use same metadata schema across related stores

6. **Access Patterns**: Design store structure around how users search

## Store Migration

### Move Documents Between Stores

```python
def migrate_documents(source_store_id, dest_store_id, file_paths):
    """Migrate documents from one store to another"""
    for file_path in file_paths:
        # Upload to destination
        operation = client.file_search_stores.upload_to_file_search_store(
            file=file_path,
            file_search_store_name=dest_store_id,
            config={"display_name": Path(file_path).name}
        )

        # Wait for completion
        while not operation.done:
            time.sleep(2)
            operation = client.operations.get(operation)

        print(f"✅ Migrated: {file_path}")

    # Note: Original files remain in source store unless manually deleted
```

## Troubleshooting

### Query Performance Issues

If searches are slow:
1. Check store size (should be <20 GB)
2. Split large stores into smaller domain-specific ones
3. Optimize chunking configuration
4. Use metadata filtering to narrow scope

### Cross-Store Search Not Working

When searching multiple stores:
1. Verify all store IDs are valid
2. Check API rate limits
3. Ensure stores contain relevant content
4. Try searching stores individually first

## Next Steps

- **[Metadata Filtering](./metadata-filtering.md)** - Organize within stores
- **[Advanced Chunking](./advanced-chunking.md)** - Optimize per store
- **[Basic Setup](./basic-setup.md)** - Review fundamentals

---

Multi-store architecture enables scalable, organized, and performant RAG systems. Design your store structure based on domain, access patterns, and scale requirements!
