# FastAPI Redis Example

## Setup

```python
from fastapi import FastAPI
from redis import Redis
import os

app = FastAPI()
redis_client = Redis.from_url(os.getenv("REDIS_URL"))

@app.get("/cache/{key}")
async def get_cached(key: str):
    value = redis_client.get(key)
    return {"key": key, "value": value}

@app.post("/cache/{key}")
async def set_cached(key: str, value: str):
    redis_client.set(key, value, ex=3600)
    return {"status": "cached"}
```

## Testing

```bash
curl -X POST "http://localhost:8000/cache/mykey?value=myvalue"
curl "http://localhost:8000/cache/mykey"
```
