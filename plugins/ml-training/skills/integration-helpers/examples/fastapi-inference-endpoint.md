# Complete FastAPI Inference Endpoint Example

This example demonstrates a production-ready sentiment analysis API using FastAPI.

## Project Structure

```
fastapi-backend/
├── app/
│   ├── main.py
│   ├── routers/
│   │   └── ml_sentiment.py
│   ├── models/
│   │   └── sentiment_model.pkl
│   └── utils/
│       └── preprocessing.py
├── requirements.txt
└── .env
```

## Step 1: Install Dependencies

```bash
pip install fastapi uvicorn scikit-learn joblib pydantic python-multipart
```

## Step 2: Create the ML Router

Use the skill script to generate the router:

```bash
bash plugins/ml-training/skills/integration-helpers/scripts/add-fastapi-endpoint.sh classification sentiment-analysis
```

This creates `app/routers/ml_sentiment_analysis.py` with the complete router code.

## Step 3: Train and Save Model (Example)

```python
# train_model.py
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib

# Sample training data
texts = [
    "I love this product!",
    "This is terrible",
    "Great experience",
    "Very disappointed",
    # ... more training data
]
labels = ["positive", "negative", "positive", "negative"]  # ...

# Create and train pipeline
model = Pipeline([
    ('tfidf', TfidfVectorizer(max_features=5000)),
    ('classifier', MultinomialNB())
])
model.fit(texts, labels)

# Save model
joblib.dump(model, 'app/models/sentiment_model.pkl')
print("Model saved successfully!")
```

## Step 4: Customize the Router

Update `app/routers/ml_sentiment_analysis.py`:

```python
# Update MODEL_PATH
MODEL_PATH = "app/models/sentiment_model.pkl"

# Customize preprocessing
def preprocess_input(text: str) -> str:
    """Clean and prepare text for sentiment analysis"""
    # Remove URLs
    text = re.sub(r'http\S+', '', text)
    # Remove special characters (keep basic punctuation)
    text = re.sub(r'[^\w\s.!?]', '', text)
    # Normalize whitespace
    text = ' '.join(text.split())
    return text.lower()
```

## Step 5: Integrate with Main App

Update `app/main.py`:

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import ml_sentiment_analysis

app = FastAPI(
    title="Sentiment Analysis API",
    description="ML-powered sentiment analysis service",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Next.js frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include ML router
app.include_router(ml_sentiment_analysis.router)

@app.get("/")
def read_root():
    return {
        "message": "Sentiment Analysis API",
        "docs": "/docs",
        "health": "/ml/health"
    }
```

## Step 6: Run the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Step 7: Test the Endpoints

### Health Check

```bash
curl http://localhost:8000/ml/health
```

Response:
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_version": "1.0.0",
  "model_type": "classification"
}
```

### Single Prediction

```bash
curl -X POST http://localhost:8000/ml/predict \
  -H "Content-Type: application/json" \
  -d '{
    "text": "This product exceeded my expectations!",
    "return_probabilities": true
  }'
```

Response:
```json
{
  "prediction": "positive",
  "confidence": 0.95,
  "probabilities": {
    "positive": 0.95,
    "negative": 0.05
  },
  "model_version": "1.0.0",
  "inference_time_ms": 12.3
}
```

### Batch Prediction

```bash
curl -X POST http://localhost:8000/ml/predict/batch \
  -H "Content-Type: application/json" \
  -d '{
    "texts": [
      "I love this!",
      "This is terrible",
      "Pretty good overall"
    ],
    "return_probabilities": true
  }'
```

Response:
```json
{
  "predictions": [
    {
      "prediction": "positive",
      "confidence": 0.92,
      "probabilities": {"positive": 0.92, "negative": 0.08},
      "model_version": "1.0.0",
      "inference_time_ms": 8.5
    },
    {
      "prediction": "negative",
      "confidence": 0.88,
      "probabilities": {"positive": 0.12, "negative": 0.88},
      "model_version": "1.0.0",
      "inference_time_ms": 7.9
    },
    {
      "prediction": "positive",
      "confidence": 0.73,
      "probabilities": {"positive": 0.73, "negative": 0.27},
      "model_version": "1.0.0",
      "inference_time_ms": 8.2
    }
  ],
  "total_inference_time_ms": 35.6,
  "batch_size": 3
}
```

### Model Info

```bash
curl http://localhost:8000/ml/info
```

Response:
```json
{
  "model_version": "1.0.0",
  "model_type": "classification",
  "endpoint_name": "sentiment-analysis",
  "classes": ["positive", "negative"]
}
```

## Step 8: Add to Supabase Logging (Optional)

Log predictions to Supabase for monitoring:

```python
from supabase import create_client

# In the predict endpoint, after successful prediction:
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

supabase.table("predictions").insert({
    "model_id": "uuid-of-model",
    "model_version": MODEL_VERSION,
    "input_data": {"text": request.text},
    "prediction": {"label": result["prediction"]},
    "confidence": confidence,
    "inference_time_ms": inference_time,
    "user_id": "user-uuid-from-auth"
}).execute()
```

## Performance Considerations

### Model Caching

The singleton pattern ensures the model is loaded only once:

```python
# Model loads once on first request
loader = ModelLoader()
model = loader.load_model()  # Cached for subsequent requests
```

### Async Processing

For long-running inference:

```python
from fastapi import BackgroundTasks

@router.post("/predict/async")
async def predict_async(
    request: PredictionRequest,
    background_tasks: BackgroundTasks
):
    task_id = str(uuid.uuid4())

    background_tasks.add_task(
        run_prediction_task,
        task_id,
        request
    )

    return {"task_id": task_id, "status": "processing"}
```

### Rate Limiting

Add rate limiting for production:

```bash
pip install slowapi
```

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/predict")
@limiter.limit("100/minute")
async def predict(...):
    # ...
```

## Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:

```bash
docker build -t sentiment-api .
docker run -p 8000:8000 sentiment-api
```

## Environment Variables

Create `.env`:

```env
MODEL_PATH=app/models/sentiment_model.pkl
MODEL_VERSION=1.0.0
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
LOG_LEVEL=INFO
```

## Monitoring and Observability

Add request logging:

```python
import logging

logger = logging.getLogger(__name__)

@router.post("/predict")
async def predict(...):
    logger.info(f"Prediction request: {request.text[:50]}...")
    # ... inference ...
    logger.info(f"Prediction result: {prediction} (confidence: {confidence})")
```

## Next Steps

1. Add authentication with JWT tokens
2. Implement A/B testing for model versions
3. Add metrics collection with Prometheus
4. Set up automated model retraining pipeline
5. Implement model versioning and rollback
6. Add input validation and sanitization
7. Set up error alerting with Sentry

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Pydantic Models](https://docs.pydantic.dev/)
- [scikit-learn Model Persistence](https://scikit-learn.org/stable/model_persistence.html)
