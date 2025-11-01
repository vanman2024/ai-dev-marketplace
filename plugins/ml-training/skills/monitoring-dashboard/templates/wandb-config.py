"""
Weights & Biases (WandB) Configuration Template
Complete WandB integration for ML training with all features
"""

import wandb
import torch
import numpy as np
from datetime import datetime
from typing import Dict, Any, Optional, List
import os


class WandBConfig:
    """WandB configuration template"""

    def __init__(
        self,
        project: str,
        entity: Optional[str] = None,
        name: Optional[str] = None,
        tags: Optional[List[str]] = None,
        notes: Optional[str] = None,
        config: Optional[Dict[str, Any]] = None,
    ):
        """
        Initialize WandB configuration

        Args:
            project: WandB project name
            entity: WandB username or team name
            name: Run name (auto-generated if None)
            tags: List of tags for filtering
            notes: Description of the experiment
            config: Hyperparameters and configuration
        """
        self.project = project
        self.entity = entity
        self.name = name or f"run-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        self.tags = tags or []
        self.notes = notes
        self.config = config or {}

    def init(self, **kwargs) -> wandb.sdk.wandb_run.Run:
        """
        Initialize WandB run with configuration

        Returns:
            WandB run object
        """
        return wandb.init(
            project=self.project,
            entity=self.entity,
            name=self.name,
            tags=self.tags,
            notes=self.notes,
            config=self.config,
            **kwargs
        )


class WandBLogger:
    """
    Comprehensive WandB logger for ML training

    Features:
    - Metric logging (scalars, histograms, distributions)
    - Media logging (images, videos, audio, tables)
    - Model artifact tracking
    - Hyperparameter tracking
    - System metrics
    - Custom charts and visualizations
    """

    def __init__(
        self,
        project: str,
        config: Dict[str, Any],
        name: Optional[str] = None,
        entity: Optional[str] = None,
        tags: Optional[List[str]] = None,
        resume: Optional[str] = None,
        mode: str = "online",  # online, offline, disabled
    ):
        """
        Initialize WandB logger

        Args:
            project: WandB project name
            config: Training configuration/hyperparameters
            name: Run name
            entity: Team/username
            tags: Tags for filtering runs
            resume: Resume mode ('allow', 'must', 'never', or run_id)
            mode: Logging mode (online, offline, disabled)
        """
        self.run = wandb.init(
            project=project,
            entity=entity,
            name=name,
            config=config,
            tags=tags,
            resume=resume,
            mode=mode,
        )

        self.config = config
        self.step = 0

    def log_metrics(self, metrics: Dict[str, float], step: Optional[int] = None):
        """
        Log scalar metrics

        Args:
            metrics: Dictionary of metric name -> value
            step: Training step (uses internal counter if None)
        """
        if step is None:
            step = self.step
            self.step += 1

        wandb.log(metrics, step=step)

    def log_epoch_metrics(
        self,
        epoch: int,
        train_loss: float,
        val_loss: float,
        train_acc: Optional[float] = None,
        val_acc: Optional[float] = None,
        learning_rate: Optional[float] = None,
        **kwargs
    ):
        """
        Log common epoch-level metrics

        Args:
            epoch: Epoch number
            train_loss: Training loss
            val_loss: Validation loss
            train_acc: Training accuracy
            val_acc: Validation accuracy
            learning_rate: Current learning rate
            **kwargs: Additional metrics
        """
        metrics = {
            "epoch": epoch,
            "train/loss": train_loss,
            "val/loss": val_loss,
        }

        if train_acc is not None:
            metrics["train/accuracy"] = train_acc
        if val_acc is not None:
            metrics["val/accuracy"] = val_acc
        if learning_rate is not None:
            metrics["learning_rate"] = learning_rate

        metrics.update(kwargs)
        self.log_metrics(metrics, step=epoch)

    def log_images(
        self,
        images: Dict[str, Any],
        step: Optional[int] = None,
        captions: Optional[List[str]] = None,
    ):
        """
        Log images

        Args:
            images: Dictionary of name -> image (numpy array or PIL)
            step: Training step
            captions: Image captions
        """
        wandb_images = {}
        for name, img in images.items():
            if isinstance(img, list):
                wandb_images[name] = [
                    wandb.Image(i, caption=captions[idx] if captions else None)
                    for idx, i in enumerate(img)
                ]
            else:
                wandb_images[name] = wandb.Image(img)

        wandb.log(wandb_images, step=step)

    def log_table(self, name: str, columns: List[str], data: List[List[Any]]):
        """
        Log data as table

        Args:
            name: Table name
            columns: Column names
            data: List of rows
        """
        table = wandb.Table(columns=columns, data=data)
        wandb.log({name: table})

    def log_histogram(self, name: str, data: np.ndarray, step: Optional[int] = None):
        """
        Log histogram

        Args:
            name: Histogram name
            data: Data array
            step: Training step
        """
        wandb.log({name: wandb.Histogram(data)}, step=step)

    def log_model_weights(self, model: torch.nn.Module, step: int):
        """
        Log model weight histograms

        Args:
            model: PyTorch model
            step: Training step
        """
        for name, param in model.named_parameters():
            if param.requires_grad:
                self.log_histogram(f"weights/{name}", param.data.cpu().numpy(), step)
                if param.grad is not None:
                    self.log_histogram(
                        f"gradients/{name}", param.grad.data.cpu().numpy(), step
                    )

    def watch_model(
        self,
        model: torch.nn.Module,
        log: str = "all",  # gradients, parameters, all
        log_freq: int = 100,
    ):
        """
        Watch model for gradient and parameter tracking

        Args:
            model: PyTorch model
            log: What to log (gradients, parameters, all)
            log_freq: Logging frequency
        """
        wandb.watch(model, log=log, log_freq=log_freq)

    def log_artifact(
        self,
        artifact_name: str,
        artifact_type: str,
        file_path: str,
        metadata: Optional[Dict] = None,
    ):
        """
        Log model artifacts (checkpoints, files)

        Args:
            artifact_name: Artifact name
            artifact_type: Type (model, dataset, etc.)
            file_path: Path to file
            metadata: Additional metadata
        """
        artifact = wandb.Artifact(artifact_name, type=artifact_type, metadata=metadata)
        artifact.add_file(file_path)
        wandb.log_artifact(artifact)

    def save_model(
        self,
        model: torch.nn.Module,
        name: str = "model",
        epoch: Optional[int] = None,
        metadata: Optional[Dict] = None,
    ):
        """
        Save PyTorch model as artifact

        Args:
            model: PyTorch model
            name: Model name
            epoch: Epoch number (added to name)
            metadata: Additional metadata
        """
        if epoch is not None:
            name = f"{name}_epoch_{epoch}"

        path = f"{name}.pth"
        torch.save(model.state_dict(), path)

        self.log_artifact(
            artifact_name=name,
            artifact_type="model",
            file_path=path,
            metadata=metadata or {"epoch": epoch},
        )

        # Clean up local file
        if os.path.exists(path):
            os.remove(path)

    def alert(
        self,
        title: str,
        text: str,
        level: str = "INFO",  # INFO, WARN, ERROR
        wait_duration: int = 300,  # seconds between alerts
    ):
        """
        Send alert notification

        Args:
            title: Alert title
            text: Alert message
            level: Alert level
            wait_duration: Minimum time between alerts
        """
        level_map = {
            "INFO": wandb.AlertLevel.INFO,
            "WARN": wandb.AlertLevel.WARN,
            "ERROR": wandb.AlertLevel.ERROR,
        }
        wandb.alert(
            title=title,
            text=text,
            level=level_map.get(level, wandb.AlertLevel.INFO),
            wait_duration=wait_duration,
        )

    def finish(self):
        """Finish WandB run"""
        wandb.finish()


# Example hyperparameter sweep configuration
SWEEP_CONFIG = {
    "method": "bayes",  # grid, random, bayes
    "metric": {"name": "val/loss", "goal": "minimize"},
    "parameters": {
        "learning_rate": {"min": 0.0001, "max": 0.1, "distribution": "log_uniform"},
        "batch_size": {"values": [16, 32, 64, 128]},
        "optimizer": {"values": ["adam", "sgd", "adamw"]},
        "weight_decay": {"min": 0.0, "max": 0.1},
        "dropout": {"min": 0.0, "max": 0.5},
        "hidden_size": {"values": [128, 256, 512, 1024]},
    },
    "early_terminate": {
        "type": "hyperband",
        "min_iter": 5,
        "eta": 2,
        "s": 3,
    },
}


# Example usage
if __name__ == "__main__":
    # Basic usage
    logger = WandBLogger(
        project="my-ml-project",
        config={
            "learning_rate": 0.001,
            "batch_size": 32,
            "epochs": 100,
            "model": "resnet50",
        },
        tags=["baseline", "resnet"],
        mode="online",
    )

    # Simulate training
    for epoch in range(10):
        # Training metrics
        train_loss = 1.0 / (epoch + 1)
        val_loss = 1.2 / (epoch + 1)
        train_acc = 0.5 + 0.4 / (epoch + 1)
        val_acc = 0.4 + 0.4 / (epoch + 1)

        # Log epoch metrics
        logger.log_epoch_metrics(
            epoch=epoch,
            train_loss=train_loss,
            val_loss=val_loss,
            train_acc=train_acc,
            val_acc=val_acc,
            learning_rate=0.001 * (0.95 ** epoch),
        )

        # Alert on milestone
        if val_acc > 0.9:
            logger.alert(
                title="High Accuracy Achieved",
                text=f"Validation accuracy reached {val_acc:.2%} at epoch {epoch}",
                level="INFO",
            )

    logger.finish()
    print("✓ WandB logging complete!")
