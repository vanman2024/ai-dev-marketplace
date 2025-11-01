# Vector Database Migration Guide

Complete guide for migrating data between vector databases with minimal downtime and data integrity validation.

## Table of Contents

1. [Migration Overview](#migration-overview)
2. [Pre-Migration Checklist](#pre-migration-checklist)
3. [Common Migration Paths](#common-migration-paths)
4. [Step-by-Step Migration Procedures](#step-by-step-migration-procedures)
5. [Validation and Testing](#validation-and-testing)
6. [Rollback Procedures](#rollback-procedures)

## Migration Overview

### Why Migrate?

- **Scale requirements changed**: Need to handle more vectors
- **Cost optimization**: Moving to self-hosted or more cost-effective solution
- **Performance needs**: Requiring faster queries or better filtering
- **Feature requirements**: Need specific capabilities (GraphQL, advanced filtering, etc.)
- **Infrastructure changes**: Consolidating with existing PostgreSQL, moving to cloud, etc.

### Migration Strategies

**Big Bang Migration**
- All data migrated at once during maintenance window
- Pros: Simple, clean cutover
- Cons: Requires downtime, risky for large datasets
- Best for: Small to medium datasets (< 1M vectors)

**Dual-Write Migration**
- Write to both old and new databases simultaneously
- Pros: Zero downtime, easy rollback
- Cons: More complex, temporary increased costs
- Best for: Production systems requiring high availability

**Gradual Migration**
- Migrate data in batches over time
- Pros: Minimal impact, can test incrementally
- Cons: More complex logic, longer migration period
- Best for: Very large datasets (> 10M vectors)

## Pre-Migration Checklist

### 1. Inventory Current System

```bash
# Document current setup
- Total vectors: _______
- Vector dimensions: _______
- Metadata schema: _______
- Query patterns: _______
- QPS (queries per second): _______
- Storage size: _______
- Current costs: _______
```

### 2. Choose Target Database

Use the comparison table in SKILL.md to select based on:
- Scale requirements
- Budget constraints
- Feature needs
- Infrastructure preferences
- Team expertise

### 3. Test with Sample Data

```python
# Export 1000-10000 sample vectors
# Test migration script
# Validate results
# Benchmark query performance
# Compare costs
```

### 4. Plan Downtime (if needed)

- Identify lowest traffic period
- Notify stakeholders
- Prepare rollback plan
- Set up monitoring

## Common Migration Paths

### Chroma → pgvector

**Why**: Consolidate with PostgreSQL, transactional consistency

**Steps**:

1. **Export from Chroma**:

```python
import chromadb
import psycopg2
import numpy as np

# Connect to Chroma
client = chromadb.PersistentClient(path="./chroma_data")
collection = client.get_collection("documents")

# Get all data
results = collection.get(
    include=["embeddings", "documents", "metadatas"]
)

# Connect to PostgreSQL
conn = psycopg2.connect("postgresql://user:pass@localhost/db")
cur = conn.cursor()

# Batch insert
for i in range(0, len(results["ids"]), 100):
    batch_ids = results["ids"][i:i+100]
    batch_embeddings = results["embeddings"][i:i+100]
    batch_docs = results["documents"][i:i+100]
    batch_meta = results["metadatas"][i:i+100]

    for id_, emb, doc, meta in zip(batch_ids, batch_embeddings, batch_docs, batch_meta):
        cur.execute(
            "INSERT INTO documents (id, content, metadata, embedding) VALUES (%s, %s, %s, %s)",
            (id_, doc, meta, emb)
        )

conn.commit()
```

2. **Validate**: Compare counts, test queries
3. **Cutover**: Update application to use pgvector
4. **Monitor**: Watch query performance and errors

### pgvector → Pinecone

**Why**: Scale to cloud, managed service, higher performance

**Steps**:

1. **Export from pgvector**:

```python
import psycopg2
from pinecone import Pinecone
import os

# Connect to PostgreSQL
conn = psycopg2.connect("postgresql://user:pass@localhost/db")
cur = conn.cursor()

# Initialize Pinecone
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
index = pc.Index("documents")

# Fetch in batches
batch_size = 100
offset = 0

while True:
    cur.execute(
        """
        SELECT id, content, metadata, embedding
        FROM documents
        ORDER BY id
        LIMIT %s OFFSET %s
        """,
        (batch_size, offset)
    )
    rows = cur.fetchall()

    if not rows:
        break

    # Prepare vectors for Pinecone
    vectors = []
    for row in rows:
        id_, content, metadata, embedding = row
        metadata["text"] = content  # Store text in metadata
        vectors.append({
            "id": str(id_),
            "values": embedding,
            "metadata": metadata
        })

    # Upsert to Pinecone
    index.upsert(vectors=vectors)

    offset += batch_size
    print(f"Migrated {offset} vectors")
```

### Pinecone → Qdrant

**Why**: Self-hosted option, advanced filtering, cost reduction

**Steps**:

1. **Export from Pinecone**:

```python
from pinecone import Pinecone
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import os

# Initialize clients
pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
pinecone_index = pc.Index("documents")

qdrant = QdrantClient(url="http://localhost:6333")

# Fetch all IDs (Pinecone has no list_all)
# You'll need to track IDs or use describe_index_stats to estimate
ids = []  # Your list of IDs

# Migrate in batches
batch_size = 100
for i in range(0, len(ids), batch_size):
    batch_ids = ids[i:i+batch_size]

    # Fetch from Pinecone
    results = pinecone_index.fetch(ids=batch_ids)

    # Convert to Qdrant format
    points = []
    for id_, vector_data in results["vectors"].items():
        points.append(
            PointStruct(
                id=id_,
                vector=vector_data["values"],
                payload=vector_data["metadata"]
            )
        )

    # Upsert to Qdrant
    qdrant.upsert(
        collection_name="documents",
        points=points
    )

    print(f"Migrated {i + len(batch_ids)} vectors")
```

### Weaviate → FAISS

**Why**: Maximum performance, research purposes, batch processing

**Steps**:

1. **Export from Weaviate**:

```python
import weaviate
import faiss
import numpy as np
import pickle

# Connect to Weaviate
client = weaviate.connect_to_local()
collection = client.collections.get("Documents")

# Fetch all objects
all_vectors = []
all_metadata = []

offset = 0
limit = 100

while True:
    results = collection.query.fetch_objects(
        limit=limit,
        offset=offset,
        include_vector=True
    )

    if not results.objects:
        break

    for obj in results.objects:
        all_vectors.append(obj.vector)
        all_metadata.append({
            "id": str(obj.uuid),
            "properties": obj.properties
        })

    offset += limit
    print(f"Fetched {offset} vectors")

# Convert to numpy
vectors = np.array(all_vectors, dtype='float32')

# Create FAISS index
dimensions = vectors.shape[1]
index = faiss.IndexHNSWFlat(dimensions, 32)
index.add(vectors)

# Save index and metadata
faiss.write_index(index, "weaviate_migration.index")
with open("weaviate_migration.meta", "wb") as f:
    pickle.dump(all_metadata, f)

print(f"Migrated {len(all_vectors)} vectors to FAISS")
```

### FAISS → Qdrant

**Why**: Need persistent storage, filtering capabilities, production deployment

**Steps**:

1. **Export from FAISS**:

```python
import faiss
import pickle
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import numpy as np

# Load FAISS index
index = faiss.read_index("faiss_index.index")
with open("faiss_index.meta", "rb") as f:
    metadata = pickle.load(f)

# Get all vectors from FAISS
# Note: FAISS doesn't have a direct "get all" method
# You'll need to reconstruct or store vectors separately
vectors = []  # Your vectors
ids = []  # Your IDs

# Initialize Qdrant
qdrant = QdrantClient(url="http://localhost:6333")

# Migrate in batches
batch_size = 100
for i in range(0, len(vectors), batch_size):
    batch_vectors = vectors[i:i+batch_size]
    batch_ids = ids[i:i+batch_size]
    batch_meta = metadata[i:i+batch_size] if metadata else [{}] * len(batch_ids)

    points = [
        PointStruct(
            id=id_,
            vector=vec.tolist(),
            payload=meta
        )
        for id_, vec, meta in zip(batch_ids, batch_vectors, batch_meta)
    ]

    qdrant.upsert(
        collection_name="documents",
        points=points
    )

    print(f"Migrated {i + len(batch_vectors)} vectors")
```

### Any → Chroma (Universal Import)

**Why**: Development, prototyping, local-first

```python
import chromadb
import numpy as np

# Initialize Chroma
client = chromadb.PersistentClient(path="./migrated_chroma")
collection = client.get_or_create_collection("documents")

# Universal format: lists of IDs, embeddings, documents, metadatas
ids = []          # List of string IDs
embeddings = []   # List of embedding vectors
documents = []    # List of document texts
metadatas = []    # List of metadata dicts

# Batch add (Chroma handles up to 40K at once)
batch_size = 1000
for i in range(0, len(ids), batch_size):
    collection.add(
        ids=ids[i:i+batch_size],
        embeddings=embeddings[i:i+batch_size],
        documents=documents[i:i+batch_size],
        metadatas=metadatas[i:i+batch_size]
    )
    print(f"Migrated {i + batch_size} documents")
```

## Step-by-Step Migration Procedures

### Procedure 1: Zero-Downtime Dual-Write Migration

For production systems that can't afford downtime.

1. **Setup dual-write**:
```python
class DualWriteVectorStore:
    def __init__(self, old_store, new_store):
        self.old = old_store
        self.new = new_store

    def add(self, vectors, metadata):
        # Write to both
        self.old.add(vectors, metadata)
        self.new.add(vectors, metadata)

    def search(self, query, k=10):
        # Read from old (stable)
        return self.old.search(query, k)
```

2. **Backfill historical data** to new store
3. **Switch reads to new store** (with fallback to old)
4. **Monitor for errors**
5. **Stop writing to old store**
6. **Decomission old store**

### Procedure 2: Batch Migration with Validation

For large datasets requiring careful validation.

```python
import hashlib

def migrate_batch(source, target, batch_ids):
    """Migrate single batch with validation"""

    # 1. Extract from source
    vectors, metadata = source.get(batch_ids)

    # 2. Calculate checksum
    checksum = hashlib.sha256(
        str(vectors.tobytes()).encode()
    ).hexdigest()

    # 3. Insert into target
    target.add(vectors, metadata, ids=batch_ids)

    # 4. Verify
    retrieved = target.get(batch_ids)
    verify_checksum = hashlib.sha256(
        str(retrieved.tobytes()).encode()
    ).hexdigest()

    if checksum != verify_checksum:
        raise ValueError(f"Checksum mismatch for batch")

    return len(batch_ids)

# Execute migration
total_migrated = 0
batch_size = 1000

for i in range(0, total_count, batch_size):
    batch_ids = get_batch_ids(i, batch_size)
    migrated = migrate_batch(source, target, batch_ids)
    total_migrated += migrated
    print(f"Progress: {total_migrated}/{total_count}")
```

## Validation and Testing

### 1. Count Validation

```python
source_count = source.count()
target_count = target.count()
assert source_count == target_count, f"Count mismatch: {source_count} != {target_count}"
```

### 2. Sample Query Validation

```python
# Test with known queries
test_vectors = [...]  # Your test queries
tolerance = 0.01  # Allow small ranking differences

for query in test_vectors:
    source_results = source.search(query, k=10)
    target_results = target.search(query, k=10)

    # Compare top result IDs (order might differ slightly)
    source_ids = set([r["id"] for r in source_results[:5]])
    target_ids = set([r["id"] for r in target_results[:5]])

    overlap = len(source_ids & target_ids) / len(source_ids)
    assert overlap >= (1 - tolerance), f"Result mismatch: {overlap}"
```

### 3. Metadata Integrity

```python
# Sample random documents
sample_ids = random.sample(all_ids, 100)

for id_ in sample_ids:
    source_doc = source.get([id_])
    target_doc = target.get([id_])

    assert source_doc["metadata"] == target_doc["metadata"]
```

### 4. Performance Benchmarking

```python
import time

def benchmark(store, queries, k=10):
    start = time.time()
    for query in queries:
        store.search(query, k=k)
    duration = time.time() - start
    qps = len(queries) / duration
    return qps

source_qps = benchmark(source, test_queries)
target_qps = benchmark(target, test_queries)

print(f"Source QPS: {source_qps:.2f}")
print(f"Target QPS: {target_qps:.2f}")
print(f"Speedup: {target_qps/source_qps:.2f}x")
```

## Rollback Procedures

### Quick Rollback Checklist

```bash
# 1. Stop writing to new database
# 2. Revert application config to old database
# 3. Verify old database is still healthy
# 4. Monitor for errors
# 5. Investigate migration issues
```

### Rollback Script Template

```python
def rollback():
    """Rollback to old vector store"""

    # 1. Update config
    config.VECTOR_STORE = "old"

    # 2. Restart services
    restart_services()

    # 3. Verify health
    assert old_store.count() > 0
    test_results = old_store.search(test_query, k=5)
    assert len(test_results) == 5

    # 4. Log rollback
    logger.critical("ROLLBACK: Reverted to old vector store")

    print("Rollback complete")
```

## Migration Troubleshooting

### Common Issues

**Issue**: Out of memory during migration
**Solution**: Reduce batch size, process in smaller chunks

**Issue**: Rate limiting from cloud provider
**Solution**: Add delays between batches, use exponential backoff

**Issue**: Metadata schema differences
**Solution**: Write transformation function to map schemas

**Issue**: Vector dimension mismatch
**Solution**: Re-generate embeddings with correct model, or use dimension reduction

**Issue**: Query results don't match
**Solution**: Check distance metric (L2 vs cosine), verify normalization

## Best Practices

1. **Always test with sample data first**
2. **Validate at each step** (counts, checksums, query results)
3. **Monitor performance** before and after
4. **Keep old system running** until fully validated
5. **Document the process** for future reference
6. **Have a rollback plan** ready
7. **Migrate during low-traffic periods**
8. **Use parallel workers** for large migrations
9. **Log everything** for audit trail
10. **Celebrate successful migration!**
