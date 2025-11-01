"""
Inference Template
Customize for your trained model
"""

import argparse
import torch
from pathlib import Path


def load_model(model_path, device='cpu'):
    """
    Load trained model

    TODO: Adjust model loading based on your architecture
    """
    checkpoint = torch.load(model_path, map_location=device)

    # TODO: Recreate model architecture
    # Example for transformer:
    # from transformers import AutoModelForSequenceClassification
    # model = AutoModelForSequenceClassification.from_pretrained(model_path)

    # Example for custom model:
    class CustomModel(torch.nn.Module):
        def __init__(self, input_dim=10, num_classes=3):
            super().__init__()
            self.network = torch.nn.Sequential(
                torch.nn.Linear(input_dim, 128),
                torch.nn.ReLU(),
                torch.nn.Dropout(0.3),
                torch.nn.Linear(128, num_classes)
            )

        def forward(self, features):
            return self.network(features)

    model = CustomModel()
    model.load_state_dict(checkpoint['model_state_dict'])
    model.to(device)
    model.eval()

    return model


def preprocess_input(input_data):
    """
    Preprocess input data

    TODO: Implement preprocessing logic
    """
    # Example: tokenize text, normalize features, etc.
    processed = input_data  # Your preprocessing here

    return processed


def predict(input_data, model, device='cpu'):
    """
    Run prediction

    TODO: Customize for your model input/output
    """
    # Preprocess
    processed = preprocess_input(input_data)

    # Convert to tensor
    if isinstance(processed, str):
        # Text input - needs tokenization
        # TODO: Add tokenizer
        raise NotImplementedError("Add tokenizer for text input")
    else:
        # Numerical input
        input_tensor = torch.FloatTensor([processed]).to(device)

    # Predict
    with torch.no_grad():
        logits = model(input_tensor)
        probabilities = torch.softmax(logits, dim=1)[0]
        prediction = torch.argmax(logits, dim=1).item()

    # TODO: Map prediction to label
    class_labels = ['Class0', 'Class1', 'Class2']  # Your class names
    predicted_label = class_labels[prediction]

    return {
        'prediction': predicted_label,
        'confidence': probabilities[prediction].item(),
        'probabilities': {
            label: prob.item()
            for label, prob in zip(class_labels, probabilities)
        }
    }


def main():
    parser = argparse.ArgumentParser(description='Run inference')
    parser.add_argument('--model-path', type=str, required=True,
                        help='Path to trained model')
    parser.add_argument('--input', type=str,
                        help='Input data')
    parser.add_argument('--interactive', action='store_true',
                        help='Interactive mode')
    parser.add_argument('--device', type=str, default='cpu',
                        help='Device (cuda/cpu)')

    args = parser.parse_args()

    # Load model
    print("Loading model...")
    model = load_model(args.model_path, args.device)
    print(f"Model loaded from {args.model_path}")
    print()

    if args.interactive:
        # Interactive mode
        print("=" * 50)
        print("Interactive Prediction")
        print("=" * 50)
        print("\nType 'quit' to exit")
        print()

        while True:
            input_data = input("Enter input: ").strip()

            if input_data.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break

            if not input_data:
                continue

            try:
                result = predict(input_data, model, args.device)

                print()
                print(f"Prediction: {result['prediction']}")
                print(f"Confidence: {result['confidence']:.2%}")
                print(f"Probabilities:")
                for label, prob in result['probabilities'].items():
                    print(f"  {label}: {prob:.2%}")
                print()

            except Exception as e:
                print(f"Error: {e}")
                print()

    elif args.input:
        # Single prediction
        result = predict(args.input, model, args.device)

        print(f"Input: {args.input}")
        print()
        print(f"Prediction: {result['prediction']}")
        print(f"Confidence: {result['confidence']:.2%}")
        print()
        print("Probabilities:")
        for label, prob in result['probabilities'].items():
            print(f"  {label}: {prob:.2%}")

    else:
        # Demo mode
        demo_inputs = [
            "Example input 1",
            "Example input 2",
            "Example input 3"
        ]

        print("=" * 50)
        print("Demo Mode")
        print("=" * 50)
        print()

        for demo_input in demo_inputs:
            result = predict(demo_input, model, args.device)

            print(f"Input: {demo_input}")
            print(f"Prediction: {result['prediction']} ({result['confidence']:.2%})")
            print()


if __name__ == "__main__":
    main()
