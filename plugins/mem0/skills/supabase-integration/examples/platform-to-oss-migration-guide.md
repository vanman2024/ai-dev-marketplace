# Mem0 Platform to OSS Migration Guide

## Overview

Complete guide for migrating from Mem0 Platform (hosted) to Mem0 OSS (self-hosted) with Supabase backend.

## Migration Scenarios

### Scenario 1: Cost Optimization
- Moving from paid Platform to self-hosted
- Reducing operational costs
- Maintaining full data control

### Scenario 2: Compliance Requirements
- Data sovereignty requirements
- HIPAA/GDPR compliance
- On-premise deployment needs

### Scenario 3: Feature Customization
- Custom embedding models
- Modified schema requirements
- Integration with existing infrastructure

## Pre-Migration Checklist

- [ ] Supabase project set up and configured
- [ ] Backup of Platform data exported
- [ ] OSS schema deployed (tables, indexes, RLS)
- [ ] Test environment validated
- [ ] Migration timeline scheduled
- [ ] Rollback plan documented
- [ ] Team notified of migration window

## Migration Process

### Phase 1: Export from Platform

#### 1.1 Export Memories via API

```bash
#!/bin/bash
# Export all memories from Mem0 Platform

PLATFORM_API_KEY="your-mem0-platform-api-key"
PLATFORM_URL="https://api.mem0.ai"
OUTPUT_FILE="platform-export-$(date +%Y%m%d-%H%M%S).json"

# Export memories for all users
curl -X GET "$PLATFORM_URL/v1/memories" \
  -H "Authorization: Bearer $PLATFORM_API_KEY" \
  -H "Content-Type: application/json" \
  -o "$OUTPUT_FILE"

echo "Exported to: $OUTPUT_FILE"

# Verify export
MEMORY_COUNT=$(jq '. | length' "$OUTPUT_FILE")
echo "Total memories exported: $MEMORY_COUNT"
```

#### 1.2 Export by User

```python
import requests
import json
from datetime import datetime

PLATFORM_API_KEY = "your-api-key"
PLATFORM_URL = "https://api.mem0.ai"

def export_user_memories(user_id: str) -> list:
    """Export all memories for a specific user"""
    headers = {
        "Authorization": f"Bearer {PLATFORM_API_KEY}",
        "Content-Type": "application/json"
    }

    response = requests.get(
        f"{PLATFORM_URL}/v1/memories",
        headers=headers,
        params={"user_id": user_id}
    )

    response.raise_for_status()
    return response.json()

def export_all_users(user_ids: list[str], output_file: str):
    """Export memories for multiple users"""
    all_exports = {}

    for user_id in user_ids:
        print(f"Exporting memories for user: {user_id}")
        try:
            memories = export_user_memories(user_id)
            all_exports[user_id] = memories
            print(f"  Exported {len(memories)} memories")
        except Exception as e:
            print(f"  Error: {e}")

    # Save to file
    with open(output_file, 'w') as f:
        json.dump(all_exports, f, indent=2)

    print(f"\nExport complete: {output_file}")
    return all_exports

# Usage
user_list = ["user-1", "user-2", "user-3"]
export_all_users(user_list, f"platform-export-{datetime.now().strftime('%Y%m%d')}.json")
```

### Phase 2: Transform Data

#### 2.1 Platform to OSS Schema Mapping

Platform format:
```json
{
  "id": "mem_abc123",
  "content": "User prefers dark mode",
  "user_id": "user-123",
  "metadata": {
    "category": "preferences"
  },
  "created_at": "2025-01-15T10:00:00Z"
}
```

OSS format:
```sql
INSERT INTO memories (id, user_id, memory, metadata, embedding, created_at)
VALUES (
  'uuid-here',
  'user-123',
  'User prefers dark mode',
  '{"category": "preferences"}'::jsonb,
  NULL,  -- Will generate embeddings
  '2025-01-15T10:00:00Z'
);
```

#### 2.2 Transform Script

```python
import json
import uuid
from datetime import datetime
from typing import Dict, List

def transform_memory(platform_memory: Dict) -> Dict:
    """Transform Platform memory to OSS format"""
    return {
        "id": str(uuid.uuid4()),  # Generate new UUID
        "user_id": platform_memory.get("user_id"),
        "agent_id": platform_memory.get("agent_id"),
        "run_id": platform_memory.get("run_id"),
        "memory": platform_memory.get("content") or platform_memory.get("memory"),
        "hash": platform_memory.get("hash"),
        "metadata": platform_memory.get("metadata", {}),
        "categories": platform_memory.get("categories", []),
        "embedding": None,  # Will be generated
        "created_at": platform_memory.get("created_at"),
        "updated_at": platform_memory.get("updated_at") or platform_memory.get("created_at")
    }

def transform_export(input_file: str, output_file: str) -> Dict:
    """Transform entire export file"""
    with open(input_file, 'r') as f:
        platform_data = json.load(f)

    transformed = {
        "metadata": {
            "source": "mem0-platform",
            "export_date": datetime.now().isoformat(),
            "total_memories": 0
        },
        "memories": []
    }

    # Handle different export formats
    if isinstance(platform_data, list):
        memories = platform_data
    elif isinstance(platform_data, dict) and "memories" in platform_data:
        memories = platform_data["memories"]
    else:
        memories = list(platform_data.values())[0] if platform_data else []

    # Transform each memory
    for mem in memories:
        try:
            transformed_mem = transform_memory(mem)
            transformed["memories"].append(transformed_mem)
        except Exception as e:
            print(f"Error transforming memory: {e}")
            print(f"Memory data: {mem}")

    transformed["metadata"]["total_memories"] = len(transformed["memories"])

    # Save transformed data
    with open(output_file, 'w') as f:
        json.dump(transformed, f, indent=2)

    print(f"Transformed {len(transformed['memories'])} memories")
    print(f"Output: {output_file}")

    return transformed

# Usage
transform_export(
    "platform-export-20250127.json",
    "oss-import-20250127.json"
)
```

### Phase 3: Generate Embeddings

#### 3.1 Embedding Generation Script

```python
from openai import OpenAI
import json
from typing import List
import time

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def generate_embedding(text: str, model: str = "text-embedding-3-small") -> List[float]:
    """Generate embedding for text"""
    response = client.embeddings.create(
        input=text,
        model=model
    )
    return response.data[0].embedding

def add_embeddings_to_export(input_file: str, output_file: str, batch_size: int = 100):
    """Add embeddings to transformed memories"""
    with open(input_file, 'r') as f:
        data = json.load(f)

    memories = data["memories"]
    total = len(memories)
    processed = 0

    print(f"Generating embeddings for {total} memories...")

    for i in range(0, total, batch_size):
        batch = memories[i:i + batch_size]

        for memory in batch:
            try:
                # Generate embedding for memory content
                embedding = generate_embedding(memory["memory"])
                memory["embedding"] = embedding
                processed += 1

                if processed % 10 == 0:
                    print(f"  Progress: {processed}/{total} ({processed*100//total}%)")

            except Exception as e:
                print(f"  Error generating embedding: {e}")
                memory["embedding"] = None

        # Rate limiting (OpenAI has limits)
        time.sleep(1)

    # Save with embeddings
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)

    print(f"\nCompleted: {processed}/{total} embeddings generated")
    print(f"Output: {output_file}")

# Usage
add_embeddings_to_export(
    "oss-import-20250127.json",
    "oss-import-with-embeddings-20250127.json"
)
```

### Phase 4: Import to Supabase

#### 4.1 Batch Import Script

```python
import psycopg2
import json
from psycopg2.extras import execute_values
from datetime import datetime

def import_memories_to_supabase(
    input_file: str,
    db_url: str,
    batch_size: int = 1000
):
    """Import memories to Supabase PostgreSQL"""
    # Load data
    with open(input_file, 'r') as f:
        data = json.load(f)

    memories = data["memories"]
    total = len(memories)

    print(f"Importing {total} memories to Supabase...")

    # Connect to database
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    # Prepare data for batch insert
    values = []
    for memory in memories:
        embedding_str = f"[{','.join(map(str, memory['embedding']))}]" if memory['embedding'] else None

        values.append((
            memory["id"],
            memory["user_id"],
            memory.get("agent_id"),
            memory.get("run_id"),
            memory["memory"],
            memory.get("hash"),
            json.dumps(memory.get("metadata", {})),
            memory.get("categories", []),
            embedding_str,
            memory.get("created_at"),
            memory.get("updated_at")
        ))

    # Batch insert
    inserted = 0
    for i in range(0, len(values), batch_size):
        batch = values[i:i + batch_size]

        try:
            execute_values(
                cur,
                """
                INSERT INTO memories (
                    id, user_id, agent_id, run_id, memory,
                    hash, metadata, categories, embedding,
                    created_at, updated_at
                )
                VALUES %s
                ON CONFLICT (id) DO UPDATE SET
                    memory = EXCLUDED.memory,
                    metadata = EXCLUDED.metadata,
                    updated_at = EXCLUDED.updated_at
                """,
                batch
            )
            conn.commit()
            inserted += len(batch)
            print(f"  Imported: {inserted}/{total} ({inserted*100//total}%)")

        except Exception as e:
            conn.rollback()
            print(f"  Error in batch: {e}")

    cur.close()
    conn.close()

    print(f"\nImport complete: {inserted}/{total} memories imported")

# Usage
import_memories_to_supabase(
    "oss-import-with-embeddings-20250127.json",
    os.getenv("SUPABASE_DB_URL")
)
```

#### 4.2 Using Migration Script

```bash
# All-in-one migration script
bash scripts/migrate-platform-to-oss.sh \
  --api-key "$PLATFORM_API_KEY" \
  --user-ids "user-1,user-2,user-3" \
  --output-dir "./migration" \
  --supabase-url "$SUPABASE_DB_URL" \
  --generate-embeddings true \
  --batch-size 1000 \
  --dry-run false
```

### Phase 5: Validation

#### 5.1 Verify Import

```python
import psycopg2

def validate_migration(db_url: str, expected_count: int):
    """Validate migration success"""
    conn = psycopg2.connect(db_url)
    cur = conn.cursor()

    # Check total count
    cur.execute("SELECT COUNT(*) FROM memories")
    actual_count = cur.fetchone()[0]

    print(f"Expected: {expected_count}, Actual: {actual_count}")

    if actual_count != expected_count:
        print("⚠️ Warning: Memory count mismatch!")
    else:
        print("✅ Memory count matches")

    # Check embeddings
    cur.execute("SELECT COUNT(*) FROM memories WHERE embedding IS NULL")
    missing_embeddings = cur.fetchone()[0]

    if missing_embeddings > 0:
        print(f"⚠️ Warning: {missing_embeddings} memories missing embeddings")
    else:
        print("✅ All memories have embeddings")

    # Check users
    cur.execute("SELECT COUNT(DISTINCT user_id) FROM memories")
    user_count = cur.fetchone()[0]
    print(f"Unique users: {user_count}")

    # Sample queries
    print("\nSample memory:")
    cur.execute("SELECT id, user_id, LEFT(memory, 50) FROM memories LIMIT 1")
    sample = cur.fetchone()
    print(f"  ID: {sample[0]}")
    print(f"  User: {sample[1]}")
    print(f"  Memory: {sample[2]}...")

    cur.close()
    conn.close()

# Usage
validate_migration(os.getenv("SUPABASE_DB_URL"), expected_count=1500)
```

#### 5.2 Test Vector Search

```python
from mem0 import Memory

def test_oss_search(user_id: str, query: str):
    """Test OSS memory search"""
    memory = Memory.from_config({
        "vector_store": {
            "provider": "postgres",
            "config": {
                "url": os.getenv("SUPABASE_DB_URL")
            }
        }
    })

    results = memory.search(query, user_id=user_id, limit=5)

    print(f"\nSearch results for '{query}':")
    for i, result in enumerate(results, 1):
        print(f"{i}. {result['memory']}")
        print(f"   Score: {result.get('score', 'N/A')}")

# Usage
test_oss_search("user-123", "preferences")
```

### Phase 6: Update Application Configuration

#### 6.1 Switch from Platform to OSS

Before (Platform):
```python
from mem0 import MemoryClient

memory = MemoryClient(api_key="platform-api-key")
```

After (OSS):
```python
from mem0 import Memory

memory = Memory.from_config({
    "vector_store": {
        "provider": "postgres",
        "config": {
            "url": os.getenv("SUPABASE_DB_URL")
        }
    }
})
```

#### 6.2 Environment Variables

Update your `.env`:
```bash
# Remove Platform variables
# MEM0_API_KEY=platform-key

# Add OSS variables
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_DB_URL=postgresql://postgres:password@db.project.supabase.co:5432/postgres
SUPABASE_ANON_KEY=your-anon-key
OPENAI_API_KEY=your-openai-key  # For embeddings
```

### Phase 7: Rollback Plan

#### 7.1 Create Backup Before Migration

```bash
# Backup Supabase database before import
pg_dump "$SUPABASE_DB_URL" -n public -t memories > backup-pre-migration.sql

# Backup Platform export
cp platform-export.json platform-export-backup.json
```

#### 7.2 Rollback Procedure

```bash
# If migration fails, restore from backup
psql "$SUPABASE_DB_URL" -c "TRUNCATE TABLE memories CASCADE;"
psql "$SUPABASE_DB_URL" < backup-pre-migration.sql
```

## Migration Timeline

### Estimated Durations

| Memory Count | Export | Transform | Embeddings | Import | Total |
|--------------|--------|-----------|------------|--------|-------|
| 1,000 | 1 min | 1 min | 5 min | 1 min | ~10 min |
| 10,000 | 5 min | 2 min | 50 min | 5 min | ~1 hour |
| 100,000 | 20 min | 10 min | 8 hours | 30 min | ~9 hours |
| 1,000,000 | 2 hours | 1 hour | 80 hours | 4 hours | ~3.5 days |

### Recommendations

- **< 10K memories**: Run during business hours (quick migration)
- **10K-100K**: Schedule during off-peak hours
- **> 100K**: Plan weekend migration with extended window

## Post-Migration

### Monitoring

```sql
-- Monitor memory growth
SELECT
    DATE(created_at) as date,
    COUNT(*) as memories_created
FROM memories
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Cost Comparison

**Before (Platform)**:
- Platform subscription: $X/month
- Embedding API: Included
- Storage: Included

**After (OSS + Supabase)**:
- Supabase Pro: $25/month
- OpenAI embeddings: ~$0.0001 per 1K tokens
- Storage: ~$0.125/GB/month
- **Estimated savings**: 60-80% for medium-scale deployments

## Troubleshooting

### Issue: Missing Embeddings
**Solution**: Re-run embedding generation for null values
```bash
bash scripts/regenerate-embeddings.sh --filter "embedding IS NULL"
```

### Issue: Slow Import
**Solution**: Increase batch size and disable triggers temporarily
```sql
ALTER TABLE memories DISABLE TRIGGER audit_memory_changes;
-- Run import
ALTER TABLE memories ENABLE TRIGGER audit_memory_changes;
```

### Issue: Memory Mismatch
**Solution**: Run diff script to compare Platform vs OSS
```bash
bash scripts/compare-platform-oss.sh \
  --platform-export platform-export.json \
  --supabase-url "$SUPABASE_DB_URL"
```

## Summary

Migration checklist:
- ✅ Export from Platform
- ✅ Transform data format
- ✅ Generate embeddings
- ✅ Import to Supabase
- ✅ Validate data integrity
- ✅ Update application config
- ✅ Test search functionality
- ✅ Monitor performance

**Result**: Self-hosted Mem0 OSS with full control, lower costs, and enhanced compliance.
