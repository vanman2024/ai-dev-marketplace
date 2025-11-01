#!/bin/bash

# add-fastapi-endpoint.sh - Generate FastAPI ML inference endpoint
# Usage: ./add-fastapi-endpoint.sh <model-type> <endpoint-name>

set -e

MODEL_TYPE=$1
ENDPOINT_NAME=$2

if [ -z "$MODEL_TYPE" ] || [ -z "$ENDPOINT_NAME" ]; then
    echo "Usage: ./add-fastapi-endpoint.sh <model-type> <endpoint-name>"
    echo ""
    echo "Model types:"
    echo "  - classification: Text or tabular classification"
    echo "  - regression: Numeric prediction"
    echo "  - text-generation: LLM text generation"
    echo "  - image-classification: Image recognition"
    echo "  - embeddings: Vector embeddings generation"
    echo ""
    echo "Example: ./add-fastapi-endpoint.sh classification sentiment-analysis"
    exit 1
fi

# Determine current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Check if we're in a FastAPI project
if [ ! -d "app" ] && [ ! -d "api" ] && [ ! -d "src" ]; then
    echo "Warning: Not in a FastAPI project root. Creating app/routers/ directory..."
    mkdir -p app/routers
fi

# Find routers directory
if [ -d "app/routers" ]; then
    ROUTERS_DIR="app/routers"
elif [ -d "api/routers" ]; then
    ROUTERS_DIR="api/routers"
elif [ -d "src/routers" ]; then
    ROUTERS_DIR="src/routers"
else
    ROUTERS_DIR="app/routers"
    mkdir -p "$ROUTERS_DIR"
fi

# Create router filename
ROUTER_FILE="$ROUTERS_DIR/ml_${ENDPOINT_NAME//-/_}.py"

if [ -f "$ROUTER_FILE" ]; then
    echo "Error: Router file already exists: $ROUTER_FILE"
    echo "Choose a different endpoint name or delete the existing file."
    exit 1
fi

echo "Generating FastAPI ML endpoint..."
echo "  Model Type: $MODEL_TYPE"
echo "  Endpoint Name: $ENDPOINT_NAME"
echo "  Output File: $ROUTER_FILE"

# Generate router based on model type
case $MODEL_TYPE in
    classification)
        cat "$TEMPLATES_DIR/fastapi-router.py" | \
        sed "s/{{ENDPOINT_NAME}}/$ENDPOINT_NAME/g" | \
        sed "s/{{MODEL_TYPE}}/classification/g" > "$ROUTER_FILE"
        ;;
    regression)
        cat "$TEMPLATES_DIR/fastapi-router.py" | \
        sed "s/{{ENDPOINT_NAME}}/$ENDPOINT_NAME/g" | \
        sed "s/{{MODEL_TYPE}}/regression/g" | \
        sed 's/prediction: str/prediction: float/g' | \
        sed 's/probabilities: dict\[str, float\] | None = None//g' > "$ROUTER_FILE"
        ;;
    text-generation)
        cat "$TEMPLATES_DIR/fastapi-router.py" | \
        sed "s/{{ENDPOINT_NAME}}/$ENDPOINT_NAME/g" | \
        sed "s/{{MODEL_TYPE}}/text-generation/g" | \
        sed 's/prediction: str/generated_text: str/g' > "$ROUTER_FILE"
        ;;
    image-classification)
        cat "$TEMPLATES_DIR/fastapi-router.py" | \
        sed "s/{{ENDPOINT_NAME}}/$ENDPOINT_NAME/g" | \
        sed "s/{{MODEL_TYPE}}/image-classification/g" | \
        sed 's/text: str/image: UploadFile/g' > "$ROUTER_FILE"
        ;;
    embeddings)
        cat "$TEMPLATES_DIR/fastapi-router.py" | \
        sed "s/{{ENDPOINT_NAME}}/$ENDPOINT_NAME/g" | \
        sed "s/{{MODEL_TYPE}}/embeddings/g" | \
        sed 's/prediction: str/embedding: list[float]/g' > "$ROUTER_FILE"
        ;;
    *)
        echo "Error: Unknown model type: $MODEL_TYPE"
        echo "Valid types: classification, regression, text-generation, image-classification, embeddings"
        exit 1
        ;;
esac

echo ""
echo "✓ FastAPI ML endpoint created: $ROUTER_FILE"
echo ""
echo "Next steps:"
echo "  1. Update the model loading logic in the router"
echo "  2. Add the router to your main FastAPI app:"
echo "     from $ROUTERS_DIR.ml_${ENDPOINT_NAME//-/_} import router as ml_router"
echo "     app.include_router(ml_router)"
echo "  3. Install dependencies: pip install fastapi pydantic scikit-learn"
echo "  4. Test the endpoint: curl -X POST http://localhost:8000/ml/predict"
