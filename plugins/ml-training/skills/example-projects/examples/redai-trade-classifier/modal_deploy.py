"""
Deploy Trade Classifier to Modal
Serverless deployment with GPU support and auto-scaling
"""

import modal

# Create Modal app
stub = modal.Stub("redai-trade-classifier")

# Define container image with dependencies
image = (
    modal.Image.debian_slim()
    .pip_install(
        "torch>=2.0.0",
        "numpy>=1.24.0",
        "pandas>=2.0.0",
        "scikit-learn>=1.3.0",
    )
)

# Mount model directory
model_volume = modal.NetworkFileSystem.persisted("trade-classifier-models")


@stub.function(
    image=image,
    gpu="T4",  # Use NVIDIA T4 GPU
    network_file_systems={"/models": model_volume},
    secrets=[modal.Secret.from_name("huggingface-secret")],  # Optional: for private models
)
def predict_trade_signal(features: dict):
    """
    Predict trading signal from market features

    Args:
        features: Dict with market indicators
            - price_change: float
            - volume_change: float
            - rsi: float
            - macd: float
            - ma_5: float
            - ma_20: float
            - volatility: float
            - sentiment_score: float

    Returns:
        Dict with prediction and confidence
    """
    import torch
    import numpy as np
    from pathlib import Path

    # Model definition (same as training)
    class TradeClassifierModel(torch.nn.Module):
        def __init__(self, input_dim, hidden_dim=128, num_classes=3, dropout=0.3):
            super().__init__()
            self.network = torch.nn.Sequential(
                torch.nn.Linear(input_dim, hidden_dim),
                torch.nn.ReLU(),
                torch.nn.Dropout(dropout),
                torch.nn.Linear(hidden_dim, hidden_dim),
                torch.nn.ReLU(),
                torch.nn.Dropout(dropout),
                torch.nn.Linear(hidden_dim, num_classes)
            )

        def forward(self, features):
            return self.network(features)

    # Load model
    model_path = Path("/models/model.pt")

    if not model_path.exists():
        return {"error": "Model not found. Please upload model to Modal volume."}

    checkpoint = torch.load(model_path)
    model = TradeClassifierModel(
        input_dim=checkpoint['input_dim'],
        hidden_dim=checkpoint['hidden_dim']
    )
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()

    # Extract features in correct order
    feature_vector = np.array([
        features.get('price_change', 0),
        features.get('volume_change', 0),
        features.get('rsi', 50),
        features.get('macd', 0),
        features.get('ma_5', 0),
        features.get('ma_20', 0),
        features.get('volatility', 0),
        features.get('sentiment_score', 0),
    ])

    # Normalize using saved scaler
    scaler = checkpoint['scaler']
    feature_vector = scaler.transform(feature_vector.reshape(1, -1))

    # Predict
    with torch.no_grad():
        features_tensor = torch.FloatTensor(feature_vector)
        logits = model(features_tensor)
        probabilities = torch.softmax(logits, dim=1)[0]
        prediction = torch.argmax(logits, dim=1).item()

    # Map prediction to signal
    signals = ['SELL', 'HOLD', 'BUY']
    signal = signals[prediction]
    confidence = probabilities[prediction].item()

    return {
        'signal': signal,
        'confidence': confidence,
        'probabilities': {
            'SELL': probabilities[0].item(),
            'HOLD': probabilities[1].item(),
            'BUY': probabilities[2].item()
        }
    }


@stub.function(image=image)
@modal.web_endpoint(method="POST")
def predict_api(item: dict):
    """
    Web API endpoint for predictions

    Example request:
    POST /predict
    {
        "price_change": 0.05,
        "volume_change": 0.20,
        "rsi": 65,
        "macd": 0.5,
        "ma_5": 100.5,
        "ma_20": 99.2,
        "volatility": 0.15,
        "sentiment_score": 0.8
    }
    """
    result = predict_trade_signal.remote(item)
    return result


@stub.function(image=image)
def batch_predict(feature_list: list):
    """
    Batch prediction for multiple samples

    Args:
        feature_list: List of feature dicts

    Returns:
        List of predictions
    """
    return [predict_trade_signal.remote(features) for features in feature_list]


@stub.local_entrypoint()
def main():
    """
    Local testing and deployment

    Usage:
        modal run modal_deploy.py           # Test locally
        modal deploy modal_deploy.py        # Deploy to Modal
    """
    # Test prediction
    test_features = {
        'price_change': 0.05,
        'volume_change': 0.20,
        'rsi': 65,
        'macd': 0.5,
        'ma_5': 100.5,
        'ma_20': 99.2,
        'volatility': 0.15,
        'sentiment_score': 0.8
    }

    print("Testing prediction...")
    print(f"Input features: {test_features}")
    print()

    result = predict_trade_signal.remote(test_features)

    print("Prediction result:")
    print(f"  Signal: {result['signal']}")
    print(f"  Confidence: {result['confidence']:.2%}")
    print(f"  Probabilities:")
    print(f"    SELL: {result['probabilities']['SELL']:.2%}")
    print(f"    HOLD: {result['probabilities']['HOLD']:.2%}")
    print(f"    BUY:  {result['probabilities']['BUY']:.2%}")
    print()

    # Test batch prediction
    batch_features = [test_features, test_features]
    print(f"Testing batch prediction with {len(batch_features)} samples...")
    batch_results = batch_predict.remote(batch_features)
    print(f"✓ Batch prediction complete: {len(batch_results)} results")


# Upload model to Modal (run this after training)
@stub.function(
    image=image,
    network_file_systems={"/models": model_volume},
)
def upload_model(local_model_path: str = "models/trade-classifier/model.pt"):
    """
    Upload trained model to Modal volume

    Usage:
        modal run modal_deploy.py::upload_model --local-model-path path/to/model.pt
    """
    import shutil
    from pathlib import Path

    local_path = Path(local_model_path)

    if not local_path.exists():
        print(f"Error: Model file not found at {local_path}")
        return False

    # Copy to Modal volume
    shutil.copy(local_path, "/models/model.pt")
    print(f"✓ Model uploaded to Modal volume: /models/model.pt")

    return True
