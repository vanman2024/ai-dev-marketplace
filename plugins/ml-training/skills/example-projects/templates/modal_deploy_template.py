"""
Modal Deployment Template
Serverless ML model deployment
"""

import modal

# Create Modal app
stub = modal.Stub("my-ml-model")

# Define container image
image = (
    modal.Image.debian_slim()
    .pip_install(
        "torch>=2.0.0",
        "numpy>=1.24.0",
        # TODO: Add your dependencies
    )
)

# Optional: Persistent storage for models
model_volume = modal.NetworkFileSystem.persisted("my-model-storage")


@stub.function(
    image=image,
    gpu="T4",  # Use GPU (or remove for CPU-only)
    network_file_systems={"/models": model_volume},
    # Optional: Add secrets for API keys
    # secrets=[modal.Secret.from_name("my-secret")],
)
def predict(input_data: dict):
    """
    Run prediction

    Args:
        input_data: Dict with model inputs

    Returns:
        Dict with prediction results
    """
    import torch
    from pathlib import Path

    # TODO: Define your model architecture
    class MyModel(torch.nn.Module):
        def __init__(self):
            super().__init__()
            # Your model layers here
            self.network = torch.nn.Sequential(
                torch.nn.Linear(10, 128),
                torch.nn.ReLU(),
                torch.nn.Linear(128, 3)
            )

        def forward(self, x):
            return self.network(x)

    # Load model
    model_path = Path("/models/model.pt")

    if not model_path.exists():
        return {"error": "Model not found. Upload model first."}

    checkpoint = torch.load(model_path)
    model = MyModel()
    model.load_state_dict(checkpoint['model_state_dict'])
    model.eval()

    # TODO: Preprocess input
    # features = preprocess(input_data)

    # TODO: Run inference
    # with torch.no_grad():
    #     output = model(features)
    #     prediction = process_output(output)

    # Placeholder prediction
    return {
        "prediction": "example",
        "confidence": 0.95
    }


@stub.function(image=image)
@modal.web_endpoint(method="POST")
def predict_api(item: dict):
    """
    HTTP API endpoint

    Example:
        POST /predict
        {
            "input_field": "value"
        }
    """
    result = predict.remote(item)
    return result


@stub.function(image=image)
def batch_predict(inputs: list):
    """
    Batch prediction

    Args:
        inputs: List of input dicts

    Returns:
        List of predictions
    """
    return [predict.remote(inp) for inp in inputs]


@stub.local_entrypoint()
def main():
    """
    Local testing

    Usage:
        modal run modal_deploy.py           # Test
        modal deploy modal_deploy.py        # Deploy
    """
    # Test prediction
    test_input = {
        "input_field": "test value"
        # TODO: Add your test inputs
    }

    print("Testing prediction...")
    print(f"Input: {test_input}")
    print()

    result = predict.remote(test_input)

    print("Result:")
    print(result)
    print()

    # Test batch
    batch_inputs = [test_input, test_input]
    print(f"Testing batch prediction ({len(batch_inputs)} samples)...")

    batch_results = batch_predict.remote(batch_inputs)
    print(f"✓ Batch prediction complete: {len(batch_results)} results")


# Helper: Upload model to Modal
@stub.function(
    image=image,
    network_file_systems={"/models": model_volume},
)
def upload_model(local_path: str = "models/my-model/model.pt"):
    """
    Upload trained model to Modal

    Usage:
        modal run modal_deploy.py::upload_model --local-path path/to/model.pt
    """
    import shutil
    from pathlib import Path

    source = Path(local_path)

    if not source.exists():
        print(f"Error: Model not found at {source}")
        return False

    shutil.copy(source, "/models/model.pt")
    print(f"✓ Model uploaded to Modal: /models/model.pt")

    return True


# Optional: Scheduled inference
@stub.function(
    image=image,
    schedule=modal.Period(hours=1),  # Run every hour
)
def scheduled_inference():
    """
    Run scheduled predictions

    TODO: Implement scheduled task logic
    """
    print("Running scheduled inference...")

    # Example: Fetch data and run predictions
    # data = fetch_latest_data()
    # results = [predict.remote(item) for item in data]
    # save_results(results)

    print("Scheduled inference complete")
