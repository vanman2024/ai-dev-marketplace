# Minimal FastAPI Example

A simple, single-file FastAPI application demonstrating basic CRUD operations.

## Structure

```
minimal-api/
├── main.py
├── pyproject.toml
└── .env.example
```

## main.py

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional

app = FastAPI(title="Minimal API", version="1.0.0")

# Models
class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    in_stock: bool = True

# In-memory storage
items: dict[int, Item] = {}
item_counter = 0

# Endpoints
@app.get("/")
async def root():
    return {"message": "Minimal FastAPI Application"}

@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/items")
async def list_items():
    """List all items."""
    return list(items.values())

@app.post("/items", status_code=201)
async def create_item(item: Item):
    """Create a new item."""
    global item_counter
    item_counter += 1
    items[item_counter] = item
    return {"id": item_counter, **item.model_dump()}

@app.get("/items/{item_id}")
async def get_item(item_id: int):
    """Get item by ID."""
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    return items[item_id]

@app.put("/items/{item_id}")
async def update_item(item_id: int, item: Item):
    """Update existing item."""
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    items[item_id] = item
    return {"id": item_id, **item.model_dump()}

@app.delete("/items/{item_id}")
async def delete_item(item_id: int):
    """Delete item."""
    if item_id not in items:
        raise HTTPException(status_code=404, detail="Item not found")
    del items[item_id]
    return {"message": "Item deleted"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## pyproject.toml

```toml
[project]
name = "minimal-api"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115.0",
    "uvicorn[standard]>=0.32.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "httpx>=0.27.0",
]
```

## Usage

```bash
# Install
pip install -e .

# Run
uvicorn main:app --reload

# Test
curl http://localhost:8000/
curl -X POST http://localhost:8000/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Widget", "price": 9.99}'
curl http://localhost:8000/items
```

## API Documentation

Once running, visit:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/redoc (ReDoc)

## Testing

```python
# test_main.py
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()

def test_create_item():
    response = client.post(
        "/items",
        json={"name": "Test Item", "price": 19.99}
    )
    assert response.status_code == 201
    assert response.json()["name"] == "Test Item"

def test_get_items():
    response = client.get("/items")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
```

## When to Use

Perfect for:
- Quick prototypes
- Simple microservices
- Learning FastAPI
- Proof of concept APIs
- Internal tools

Not suitable for:
- Complex applications with many endpoints
- Projects requiring database integration
- Applications needing authentication
- Large codebases requiring organization
