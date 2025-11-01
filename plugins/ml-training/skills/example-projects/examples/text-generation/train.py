"""
Text Generation Training with LoRA
Fine-tune GPT-2 for custom text generation using PEFT (LoRA)
"""

import os
import yaml
import argparse
import time
from pathlib import Path

import torch
from torch.utils.data import Dataset, DataLoader
from transformers import (
    AutoTokenizer,
    AutoModelForCausalLM,
    TrainingArguments,
    Trainer,
    DataCollatorForLanguageModeling
)
from peft import (
    LoraConfig,
    get_peft_model,
    TaskType,
    PeftModel
)
from datasets import load_dataset


class TextDataset(Dataset):
    """Custom dataset for text generation"""

    def __init__(self, texts, tokenizer, max_length=512):
        self.tokenizer = tokenizer
        self.max_length = max_length
        self.texts = texts

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        text = self.texts[idx]

        # Tokenize
        encoding = self.tokenizer(
            text,
            truncation=True,
            max_length=self.max_length,
            padding='max_length',
            return_tensors='pt'
        )

        return {
            'input_ids': encoding['input_ids'].flatten(),
            'attention_mask': encoding['attention_mask'].flatten(),
            'labels': encoding['input_ids'].flatten()
        }


def load_config(config_path):
    """Load configuration from YAML file"""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def load_training_data(data_path):
    """Load training texts from file or dataset"""
    if data_path.endswith('.txt'):
        # Load from text file
        with open(data_path, 'r') as f:
            texts = f.read().split('\n\n')  # Split on double newline
        return [t.strip() for t in texts if t.strip()]

    elif data_path.endswith('.json'):
        # Load from JSON
        import json
        with open(data_path, 'r') as f:
            data = json.load(f)
        return data if isinstance(data, list) else [data['text']]

    else:
        # Try loading as HuggingFace dataset
        try:
            dataset = load_dataset(data_path, split='train')
            return dataset['text']
        except:
            raise ValueError(f"Unsupported data format: {data_path}")


def main():
    parser = argparse.ArgumentParser(description='Train text generation model with LoRA')
    parser.add_argument('--config', type=str, default='config.yaml',
                        help='Path to config YAML file')
    parser.add_argument('--data', type=str, default='training_data.txt',
                        help='Path to training data')
    parser.add_argument('--output-dir', type=str, default='models/text-generator',
                        help='Output directory')

    args = parser.parse_args()

    # Load configuration
    print("Loading configuration...")
    config = load_config(args.config)
    print(f"  Config: {args.config}")
    print()

    # Extract config values
    model_config = config['model']
    training_config = config['training']
    lora_config_dict = config['lora']

    print("=" * 50)
    print("Text Generation Training (LoRA)")
    print("=" * 50)
    print(f"\nConfiguration:")
    print(f"  Base model: {model_config['name']}")
    print(f"  Max length: {model_config['max_length']}")
    print(f"  Epochs: {training_config['epochs']}")
    print(f"  Batch size: {training_config['batch_size']}")
    print(f"  Learning rate: {training_config['learning_rate']}")
    print(f"  LoRA rank: {lora_config_dict['r']}")
    print(f"  LoRA alpha: {lora_config_dict['alpha']}")
    print()

    # Load tokenizer and model
    print("Loading base model and tokenizer...")
    tokenizer = AutoTokenizer.from_pretrained(model_config['name'])

    # Set pad token if not exists
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    model = AutoModelForCausalLM.from_pretrained(
        model_config['name'],
        torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    )

    print(f"  Base model loaded: {model_config['name']}")
    print(f"  Parameters: {sum(p.numel() for p in model.parameters()):,}")
    print()

    # Configure LoRA
    print("Configuring LoRA...")
    lora_config = LoraConfig(
        task_type=TaskType.CAUSAL_LM,
        r=lora_config_dict['r'],
        lora_alpha=lora_config_dict['alpha'],
        lora_dropout=lora_config_dict['dropout'],
        target_modules=lora_config_dict.get('target_modules', ['q_proj', 'v_proj'])
    )

    # Apply LoRA
    model = get_peft_model(model, lora_config)
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    total_params = sum(p.numel() for p in model.parameters())

    print(f"  LoRA applied!")
    print(f"  Trainable parameters: {trainable_params:,} ({100 * trainable_params / total_params:.2f}%)")
    print()

    # Load training data
    print("Loading training data...")
    texts = load_training_data(args.data)
    print(f"  Total texts: {len(texts)}")
    print(f"  Sample text: {texts[0][:100]}...")
    print()

    # Create dataset
    dataset = TextDataset(texts, tokenizer, max_length=model_config['max_length'])

    # Split train/val
    train_size = int(0.9 * len(dataset))
    val_size = len(dataset) - train_size

    train_dataset, val_dataset = torch.utils.data.random_split(
        dataset, [train_size, val_size]
    )

    print(f"  Training samples: {len(train_dataset)}")
    print(f"  Validation samples: {len(val_dataset)}")
    print()

    # Data collator
    data_collator = DataCollatorForLanguageModeling(
        tokenizer=tokenizer,
        mlm=False  # Causal LM (not masked LM)
    )

    # Training arguments
    training_args = TrainingArguments(
        output_dir=args.output_dir,
        num_train_epochs=training_config['epochs'],
        per_device_train_batch_size=training_config['batch_size'],
        per_device_eval_batch_size=training_config['batch_size'],
        learning_rate=training_config['learning_rate'],
        warmup_steps=training_config.get('warmup_steps', 100),
        logging_steps=10,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        fp16=torch.cuda.is_available(),
        gradient_checkpointing=training_config.get('gradient_checkpointing', False),
        report_to=[]  # Disable wandb, tensorboard
    )

    # Create trainer
    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
        data_collator=data_collator,
    )

    # Train
    print("Starting training...")
    print()

    start_time = time.time()
    trainer.train()
    training_time = time.time() - start_time

    # Save final model
    print()
    print("Saving model...")
    output_path = Path(args.output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    # Save LoRA adapters
    model.save_pretrained(output_path)
    tokenizer.save_pretrained(output_path)

    # Save config
    with open(output_path / 'training_config.yaml', 'w') as f:
        yaml.dump(config, f)

    print(f"  Model saved to: {output_path}")
    print()

    print("=" * 50)
    print("Training Complete!")
    print("=" * 50)
    print(f"Training time: {training_time:.2f} seconds ({training_time/60:.2f} minutes)")
    print(f"Model saved to: {args.output_dir}")
    print()
    print("Next steps:")
    print("  1. Generate text: python generate.py")
    print("  2. Deploy to Modal: modal deploy modal_deploy.py")
    print()

    # Quick generation test
    print("Testing generation...")
    test_prompt = config.get('test_prompt', "Once upon a time")

    model.eval()
    inputs = tokenizer(test_prompt, return_tensors='pt')

    if torch.cuda.is_available():
        inputs = {k: v.cuda() for k, v in inputs.items()}

    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            max_length=100,
            temperature=0.8,
            do_sample=True,
            top_p=0.9
        )

    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    print(f"\nTest prompt: {test_prompt}")
    print(f"Generated: {generated_text}")
    print()


if __name__ == "__main__":
    main()
