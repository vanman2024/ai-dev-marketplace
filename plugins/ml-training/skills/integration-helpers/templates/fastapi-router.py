"""
FastAPI ML Inference Router Template
Model Type: {{MODEL_TYPE}}
Endpoint: {{ENDPOINT_NAME}}
"""

from fastapi import APIRouter, HTTPException, Depends, status, UploadFile, File
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Router configuration
router = APIRouter(
    prefix="/ml",
    tags=["machine-learning"],
    responses={
        500: {"description": "Model inference error"},
        400: {"description": "Invalid input data"}
    },
)

# Model version (update when deploying new models)
MODEL_VERSION = "1.0.0"
MODEL_PATH = "models/{{ENDPOINT_NAME}}.pkl"  # Update with actual path


# ============================================================================
# Request/Response Models
# ============================================================================

class PredictionRequest(BaseModel):
    """Request model for ML predictions"""
    text: str = Field(..., min_length=1, max_length=10000, description="Input text for prediction")
    model_version: Optional[str] = Field(None, description="Specific model version to use")
    return_probabilities: bool = Field(False, description="Return class probabilities")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Additional metadata")

    class Config:
        json_schema_extra = {
            "example": {
                "text": "This is a sample input text",
                "return_probabilities": True
            }
        }


class PredictionResponse(BaseModel):
    """Response model for ML predictions"""
    prediction: str = Field(..., description="Model prediction")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Prediction confidence")
    probabilities: Optional[Dict[str, float]] = Field(None, description="Class probabilities")
    model_version: str = Field(..., description="Model version used")
    inference_time_ms: float = Field(..., description="Inference time in milliseconds")
    metadata: Optional[Dict[str, Any]] = None

    class Config:
        json_schema_extra = {
            "example": {
                "prediction": "positive",
                "confidence": 0.95,
                "probabilities": {"positive": 0.95, "negative": 0.05},
                "model_version": "1.0.0",
                "inference_time_ms": 25.3
            }
        }


class BatchPredictionRequest(BaseModel):
    """Request model for batch predictions"""
    texts: List[str] = Field(..., min_items=1, max_items=100, description="List of texts to predict")
    model_version: Optional[str] = None
    return_probabilities: bool = False


class BatchPredictionResponse(BaseModel):
    """Response model for batch predictions"""
    predictions: List[PredictionResponse]
    total_inference_time_ms: float
    batch_size: int


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    model_loaded: bool
    model_version: str
    model_type: str = "{{MODEL_TYPE}}"


# ============================================================================
# Model Loading (Singleton Pattern)
# ============================================================================

class ModelLoader:
    """Singleton model loader for efficient caching"""
    _instance = None
    _model = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def load_model(self, model_path: str = MODEL_PATH):
        """Load model if not already loaded"""
        if self._model is None:
            try:
                # Import model loading library based on your framework
                import joblib
                self._model = joblib.load(model_path)
                logger.info(f"Model loaded successfully from {model_path}")
            except Exception as e:
                logger.error(f"Failed to load model: {str(e)}")
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to load model: {str(e)}"
                )
        return self._model

    def is_loaded(self) -> bool:
        """Check if model is loaded"""
        return self._model is not None


# Model loader dependency
async def get_model():
    """Dependency to get loaded model"""
    loader = ModelLoader()
    return loader.load_model()


# ============================================================================
# Preprocessing Functions
# ============================================================================

def preprocess_input(text: str) -> Any:
    """
    Preprocess input text before inference

    Args:
        text: Raw input text

    Returns:
        Preprocessed input ready for model
    """
    # Add your preprocessing logic here
    # Example: cleaning, tokenization, feature extraction
    processed = text.strip().lower()
    return processed


def postprocess_output(raw_prediction: Any, probabilities: Any = None) -> Dict[str, Any]:
    """
    Postprocess model output

    Args:
        raw_prediction: Raw model output
        probabilities: Class probabilities if available

    Returns:
        Formatted prediction results
    """
    # Add your postprocessing logic here
    return {
        "prediction": str(raw_prediction),
        "probabilities": probabilities
    }


# ============================================================================
# Endpoints
# ============================================================================

@router.get("/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint to verify model availability
    """
    loader = ModelLoader()
    return HealthResponse(
        status="healthy",
        model_loaded=loader.is_loaded(),
        model_version=MODEL_VERSION
    )


@router.post(
    "/predict",
    response_model=PredictionResponse,
    status_code=status.HTTP_200_OK,
    summary="Make a prediction",
    description="Generate prediction for a single input",
    response_description="Prediction result with confidence and optional probabilities"
)
async def predict(
    request: PredictionRequest,
    model = Depends(get_model)
):
    """
    Generate prediction for a single input

    Args:
        request: Prediction request with input data
        model: Loaded ML model (injected)

    Returns:
        Prediction response with results and metadata

    Raises:
        HTTPException: 400 for invalid input, 500 for inference errors
    """
    try:
        start_time = time.time()

        # Preprocess input
        processed_input = preprocess_input(request.text)

        # Run inference
        prediction = model.predict([processed_input])[0]

        # Get probabilities if requested
        probabilities = None
        confidence = 0.0

        if request.return_probabilities and hasattr(model, 'predict_proba'):
            probs = model.predict_proba([processed_input])[0]
            probabilities = {
                label: float(prob)
                for label, prob in zip(model.classes_, probs)
            }
            confidence = float(max(probs))
        else:
            confidence = 1.0  # Default confidence if probabilities not available

        # Calculate inference time
        inference_time = (time.time() - start_time) * 1000

        # Postprocess output
        result = postprocess_output(prediction, probabilities)

        logger.info(f"Prediction successful: {prediction} (confidence: {confidence:.2f})")

        return PredictionResponse(
            prediction=result["prediction"],
            confidence=confidence,
            probabilities=result.get("probabilities"),
            model_version=request.model_version or MODEL_VERSION,
            inference_time_ms=inference_time,
            metadata=request.metadata
        )

    except ValueError as e:
        logger.warning(f"Invalid input: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid input: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Model inference failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Model inference failed: {str(e)}"
        )


@router.post(
    "/predict/batch",
    response_model=BatchPredictionResponse,
    summary="Make batch predictions",
    description="Generate predictions for multiple inputs efficiently"
)
async def predict_batch(
    request: BatchPredictionRequest,
    model = Depends(get_model)
):
    """
    Generate predictions for multiple inputs

    Args:
        request: Batch prediction request
        model: Loaded ML model (injected)

    Returns:
        Batch prediction response with all results
    """
    start_time = time.time()
    predictions = []

    for text in request.texts:
        try:
            pred_request = PredictionRequest(
                text=text,
                model_version=request.model_version,
                return_probabilities=request.return_probabilities
            )
            pred = await predict(pred_request, model)
            predictions.append(pred)
        except Exception as e:
            logger.error(f"Failed to predict for text: {text[:50]}... Error: {str(e)}")
            # Continue with other predictions
            continue

    total_time = (time.time() - start_time) * 1000

    return BatchPredictionResponse(
        predictions=predictions,
        total_inference_time_ms=total_time,
        batch_size=len(predictions)
    )


@router.get("/info")
async def model_info(model = Depends(get_model)):
    """
    Get information about the loaded model
    """
    info = {
        "model_version": MODEL_VERSION,
        "model_type": "{{MODEL_TYPE}}",
        "endpoint_name": "{{ENDPOINT_NAME}}",
    }

    # Add model-specific info if available
    if hasattr(model, 'classes_'):
        info["classes"] = list(model.classes_)
    if hasattr(model, 'n_features_in_'):
        info["n_features"] = int(model.n_features_in_)

    return info


# ============================================================================
# Error Handlers (Optional - add to main app)
# ============================================================================

"""
To add these error handlers to your main FastAPI app:

from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(ValueError)
async def value_error_handler(request: Request, exc: ValueError):
    return JSONResponse(
        status_code=400,
        content={"error": "validation_error", "message": str(exc)}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"error": "internal_error", "message": "An unexpected error occurred"}
    )
"""
