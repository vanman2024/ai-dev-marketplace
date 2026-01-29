# Checkpoint Setup

## Memory (Development)

```python
from langgraph.checkpoint.memory import MemorySaver
checkpointer = MemorySaver()
```

## Postgres (Production)

```python
from langgraph.checkpoint.postgres import PostgresSaver
checkpointer = PostgresSaver.from_conn_string(DATABASE_URL)
```
