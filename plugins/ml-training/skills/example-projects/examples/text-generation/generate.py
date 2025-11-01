"""
Text Generation Inference
Generate text using fine-tuned GPT-2 + LoRA model
"""

import argparse
import yaml
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from peft import PeftModel


def load_model(model_path, device='auto'):
    """Load fine-tuned model with LoRA adapters"""
    print("Loading model...")

    # Load config
    config_path = f"{model_path}/training_config.yaml"
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        base_model_name = config['model']['name']
    except:
        base_model_name = 'gpt2'

    # Load tokenizer
    tokenizer = AutoTokenizer.from_pretrained(model_path)

    # Load base model
    base_model = AutoModelForCausalLM.from_pretrained(
        base_model_name,
        torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
    )

    # Load LoRA adapters
    model = PeftModel.from_pretrained(base_model, model_path)

    # Move to device
    if device == 'auto':
        device = 'cuda' if torch.cuda.is_available() else 'cpu'

    model = model.to(device)
    model.eval()

    print(f"Model loaded on {device}")
    return model, tokenizer, device


def generate_text(prompt, model, tokenizer, device, **generation_config):
    """Generate text from prompt"""
    # Tokenize input
    inputs = tokenizer(prompt, return_tensors='pt')
    inputs = {k: v.to(device) for k, v in inputs.items()}

    # Generate
    with torch.no_grad():
        outputs = model.generate(
            **inputs,
            **generation_config,
            pad_token_id=tokenizer.eos_token_id
        )

    # Decode
    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

    return generated_text


def main():
    parser = argparse.ArgumentParser(description='Generate text with fine-tuned model')
    parser.add_argument('--model-path', type=str, default='models/text-generator',
                        help='Path to fine-tuned model')
    parser.add_argument('--prompt', type=str,
                        help='Text prompt to continue')
    parser.add_argument('--temperature', type=float, default=0.8,
                        help='Sampling temperature (0.0-2.0)')
    parser.add_argument('--top-p', type=float, default=0.9,
                        help='Nucleus sampling top-p')
    parser.add_argument('--top-k', type=int, default=50,
                        help='Top-k sampling')
    parser.add_argument('--max-length', type=int, default=200,
                        help='Maximum generation length')
    parser.add_argument('--num-sequences', type=int, default=1,
                        help='Number of sequences to generate')
    parser.add_argument('--interactive', action='store_true',
                        help='Interactive mode')

    args = parser.parse_args()

    # Load model
    model, tokenizer, device = load_model(args.model_path)
    print()

    # Generation config
    generation_config = {
        'max_length': args.max_length,
        'temperature': args.temperature,
        'top_p': args.top_p,
        'top_k': args.top_k,
        'num_return_sequences': args.num_sequences,
        'do_sample': True if args.temperature > 0 else False,
    }

    if args.interactive:
        # Interactive mode
        print("=" * 50)
        print("Interactive Text Generation")
        print("=" * 50)
        print("\nCommands:")
        print("  quit/exit - Exit")
        print("  config - Show generation config")
        print("  temp <value> - Set temperature")
        print()

        while True:
            prompt = input("Prompt: ").strip()

            if prompt.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break

            if prompt.lower() == 'config':
                print("\nGeneration config:")
                for k, v in generation_config.items():
                    print(f"  {k}: {v}")
                print()
                continue

            if prompt.lower().startswith('temp '):
                try:
                    generation_config['temperature'] = float(prompt.split()[1])
                    generation_config['do_sample'] = generation_config['temperature'] > 0
                    print(f"Temperature set to {generation_config['temperature']}")
                except:
                    print("Invalid temperature value")
                continue

            if not prompt:
                continue

            print("\nGenerating...\n")

            for i in range(args.num_sequences):
                generated = generate_text(prompt, model, tokenizer, device, **generation_config)

                if args.num_sequences > 1:
                    print(f"--- Sequence {i+1} ---")

                print(generated)
                print()

    elif args.prompt:
        # Single generation
        print(f"Prompt: {args.prompt}")
        print()
        print("Generating...")
        print("=" * 50)

        for i in range(args.num_sequences):
            generated = generate_text(args.prompt, model, tokenizer, device, **generation_config)

            if args.num_sequences > 1:
                print(f"\n--- Sequence {i+1} ---")

            print(generated)
            print()

    else:
        # Demo mode with example prompts
        demo_prompts = [
            "The future of artificial intelligence",
            "In a world where technology",
            "Scientists recently discovered",
            "The innovation that changed everything was"
        ]

        print("=" * 50)
        print("Demo Mode - Generating from sample prompts")
        print("=" * 50)
        print()

        for prompt in demo_prompts:
            print(f"Prompt: {prompt}")
            print("-" * 50)

            generated = generate_text(prompt, model, tokenizer, device, **generation_config)
            print(generated)
            print()
            print()


if __name__ == "__main__":
    main()
