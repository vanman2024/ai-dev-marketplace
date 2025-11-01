"""
Modal GPU Image Template
Configurable Modal image with GPU support for ML training

Usage:
1. Replace {{GPU_TYPE}} with desired GPU (T4, L4, A10, L40S, A100, H100, etc.)
2. Replace {{GPU_COUNT}} with number of GPUs (1-8)
3. Replace {{PYTHON_VERSION}} with Python version (e.g., 3.11)
4. Add your dependencies to pip_install()
5. Implement your training logic in train_model()
"""

import modal

# Create Modal app
app = modal.App("{{APP_NAME}}")

# GPU Configuration
# Options: T4, L4, A10, L40S, A100, A100-80GB, H100, H100!, H200, B200
# Multi-GPU: Append :count (e.g., "A100:4" for 4 A100s)
GPU_CONFIG = "{{GPU_TYPE}}"  # Single GPU
# GPU_CONFIG = "{{GPU_TYPE}}:{{GPU_COUNT}}"  # Multi-GPU

# GPU Fallback (recommended for faster scheduling)
GPU_FALLBACK = ["{{GPU_TYPE}}", "A100", "L40S"]

# Create image with ML dependencies
image = (
    modal.Image.debian_slim(python_version="{{PYTHON_VERSION}}")
    .pip_install(
        # Core ML frameworks
        "torch",
        "torchvision",
        "torchaudio",

        # Hugging Face ecosystem
        "transformers",
        "accelerate",
        "datasets",
        "evaluate",
        "peft",
        "bitsandbytes",

        # Training utilities
        "wandb",
        "tensorboard",

        # Data science
        "numpy",
        "pandas",
        "scikit-learn",

        # Visualization
        "matplotlib",
        "seaborn",

        # Add your dependencies here
    )
    .apt_install(
        "git",
        "wget",
        "curl",
        "vim",
    )
)

# Shared volume for datasets and checkpoints (optional)
volume = modal.Volume.from_name("ml-training-volume", create_if_missing=True)

@app.function(
    gpu=GPU_CONFIG,
    image=image,
    timeout=3600 * 4,  # 4 hours
    memory=16384,      # 16GB RAM
    volumes={"/data": volume},  # Mount volume
)
def train_model(
    model_name: str = "bert-base-uncased",
    dataset_name: str = "imdb",
    epochs: int = 3,
    batch_size: int = 16,
    learning_rate: float = 2e-5,
):
    """
    Main training function with GPU

    Args:
        model_name: Hugging Face model name
        dataset_name: Hugging Face dataset name
        epochs: Number of training epochs
        batch_size: Training batch size
        learning_rate: Learning rate
    """
    import torch
    from transformers import (
        AutoModelForSequenceClassification,
        AutoTokenizer,
        Trainer,
        TrainingArguments,
    )
    from datasets import load_dataset
    import wandb

    # Print GPU info
    print(f"GPU Available: {torch.cuda.is_available()}")
    print(f"GPU Count: {torch.cuda.device_count()}")

    if torch.cuda.is_available():
        for i in range(torch.cuda.device_count()):
            props = torch.cuda.get_device_properties(i)
            print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
            print(f"  Memory: {props.total_memory / 1e9:.2f} GB")
            print(f"  Compute Capability: {props.major}.{props.minor}")

    # Initialize Weights & Biases (optional)
    # wandb.init(project="modal-training", config={
    #     "model": model_name,
    #     "dataset": dataset_name,
    #     "epochs": epochs,
    #     "batch_size": batch_size,
    #     "learning_rate": learning_rate,
    # })

    # Load dataset
    print(f"Loading dataset: {dataset_name}")
    dataset = load_dataset(dataset_name)

    # Load model and tokenizer
    print(f"Loading model: {model_name}")
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(
        model_name,
        num_labels=2,
    )

    # Tokenize dataset
    def tokenize_function(examples):
        return tokenizer(
            examples["text"],
            padding="max_length",
            truncation=True,
            max_length=512,
        )

    print("Tokenizing dataset...")
    tokenized_datasets = dataset.map(tokenize_function, batched=True)

    # Training arguments
    training_args = TrainingArguments(
        output_dir="/data/checkpoints",
        num_train_epochs=epochs,
        per_device_train_batch_size=batch_size,
        per_device_eval_batch_size=batch_size,
        learning_rate=learning_rate,
        warmup_steps=500,
        weight_decay=0.01,
        logging_dir="/data/logs",
        logging_steps=100,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        # report_to="wandb",  # Enable for W&B logging
    )

    # Create Trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_datasets["train"],
        eval_dataset=tokenized_datasets["test"],
    )

    # Train model
    print("Starting training...")
    trainer.train()

    # Save model
    print("Saving model...")
    model.save_pretrained("/data/final_model")
    tokenizer.save_pretrained("/data/final_model")

    # Commit volume
    volume.commit()

    print("Training complete!")

    return {
        "status": "success",
        "model_path": "/data/final_model",
    }


@app.function(
    gpu=GPU_FALLBACK,  # Use fallback for faster scheduling
    image=image,
    timeout=3600,
)
def train_with_fallback(**kwargs):
    """Training function with GPU fallback"""
    import torch
    print(f"Running on GPU: {torch.cuda.get_device_name(0)}")
    return train_model.local(**kwargs)


@app.function(
    gpu=GPU_CONFIG,
    image=image,
    timeout=600,
)
def inference(text: str, model_path: str = "/data/final_model"):
    """
    Run inference with trained model

    Args:
        text: Input text
        model_path: Path to trained model
    """
    from transformers import AutoModelForSequenceClassification, AutoTokenizer
    import torch

    # Load model
    model = AutoModelForSequenceClassification.from_pretrained(model_path)
    tokenizer = AutoTokenizer.from_pretrained(model_path)

    # Tokenize
    inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512)

    # Move to GPU
    if torch.cuda.is_available():
        model = model.cuda()
        inputs = {k: v.cuda() for k, v in inputs.items()}

    # Inference
    with torch.no_grad():
        outputs = model(**inputs)
        predictions = torch.nn.functional.softmax(outputs.logits, dim=-1)

    return {
        "text": text,
        "predictions": predictions.cpu().tolist(),
    }


@app.local_entrypoint()
def main(
    mode: str = "train",
    text: str = None,
    **kwargs,
):
    """
    Local entrypoint for running training or inference

    Args:
        mode: 'train' or 'inference'
        text: Text for inference mode
        **kwargs: Additional arguments for training
    """
    if mode == "train":
        print("Starting training job...")
        result = train_model.remote(**kwargs)
        print(f"Training result: {result}")

    elif mode == "inference":
        if not text:
            text = "This is a test sentence for inference."
        print(f"Running inference on: {text}")
        result = inference.remote(text=text)
        print(f"Inference result: {result}")

    else:
        print(f"Unknown mode: {mode}")
        print("Use mode='train' or mode='inference'")


# Usage examples:
# modal run modal_image.py --mode train
# modal run modal_image.py --mode train --model-name roberta-base --epochs 5
# modal run modal_image.py --mode inference --text "This movie was great!"
# modal deploy modal_image.py
