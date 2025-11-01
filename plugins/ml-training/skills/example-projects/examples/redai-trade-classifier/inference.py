"""
Trade Classifier Inference
Local inference for trained trade classifier
"""

import argparse
import json
import torch
import numpy as np
import pandas as pd
from pathlib import Path


class TradeClassifierModel(torch.nn.Module):
    """Trade classifier model (same as training)"""

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


def load_model(model_path, device='cpu'):
    """Load trained model"""
    checkpoint = torch.load(model_path, map_location=device)

    model = TradeClassifierModel(
        input_dim=checkpoint['input_dim'],
        hidden_dim=checkpoint['hidden_dim']
    )
    model.load_state_dict(checkpoint['model_state_dict'])
    model.to(device)
    model.eval()

    return model, checkpoint['scaler']


def predict_signal(features, model, scaler, device='cpu'):
    """Predict trading signal from features"""
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

    # Normalize
    feature_vector = scaler.transform(feature_vector.reshape(1, -1))

    # Predict
    with torch.no_grad():
        features_tensor = torch.FloatTensor(feature_vector).to(device)
        logits = model(features_tensor)
        probabilities = torch.softmax(logits, dim=1)[0]
        prediction = torch.argmax(logits, dim=1).item()

    # Map to signal
    signals = ['SELL', 'HOLD', 'BUY']

    return {
        'signal': signals[prediction],
        'confidence': probabilities[prediction].item(),
        'probabilities': {
            'SELL': probabilities[0].item(),
            'HOLD': probabilities[1].item(),
            'BUY': probabilities[2].item()
        }
    }


def main():
    parser = argparse.ArgumentParser(description='Trade classifier inference')
    parser.add_argument('--model-path', type=str, default='models/trade-classifier/model.pt',
                        help='Path to trained model')
    parser.add_argument('--input', type=str,
                        help='Input file (CSV/JSON) or JSON string')
    parser.add_argument('--interactive', action='store_true',
                        help='Interactive mode')
    parser.add_argument('--device', type=str, default='cpu',
                        help='Device (cuda/cpu)')

    args = parser.parse_args()

    # Load model
    print("Loading model...")
    model, scaler = load_model(args.model_path, args.device)
    print(f"Model loaded from {args.model_path}")
    print()

    if args.interactive:
        # Interactive mode
        print("=" * 50)
        print("Interactive Trade Signal Prediction")
        print("=" * 50)
        print("\nEnter market features (or 'quit' to exit)")
        print()

        while True:
            print("Enter features:")

            try:
                price_change = input("  Price change (-1 to 1): ")
                if price_change.lower() in ['quit', 'exit', 'q']:
                    break

                features = {
                    'price_change': float(price_change),
                    'volume_change': float(input("  Volume change (-1 to 1): ")),
                    'rsi': float(input("  RSI (0-100): ")),
                    'macd': float(input("  MACD: ")),
                    'ma_5': float(input("  MA 5-day: ")),
                    'ma_20': float(input("  MA 20-day: ")),
                    'volatility': float(input("  Volatility (0-1): ")),
                    'sentiment_score': float(input("  Sentiment (-1 to 1): "))
                }

                result = predict_signal(features, model, scaler, args.device)

                print()
                print(f"Signal: {result['signal']}")
                print(f"Confidence: {result['confidence']:.2%}")
                print(f"Probabilities:")
                print(f"  SELL: {result['probabilities']['SELL']:.2%}")
                print(f"  HOLD: {result['probabilities']['HOLD']:.2%}")
                print(f"  BUY:  {result['probabilities']['BUY']:.2%}")
                print()

            except (ValueError, KeyboardInterrupt):
                print("\nGoodbye!")
                break

    elif args.input:
        # File or JSON input
        if Path(args.input).exists():
            # Load from file
            if args.input.endswith('.csv'):
                df = pd.read_csv(args.input)
            elif args.input.endswith('.json'):
                df = pd.read_json(args.input)

            print(f"Processing {len(df)} samples from {args.input}...")
            print()

            results = []
            for idx, row in df.iterrows():
                features = row.to_dict()
                result = predict_signal(features, model, scaler, args.device)
                results.append(result)

                if idx < 5:  # Show first 5
                    print(f"Sample {idx+1}: {result['signal']} ({result['confidence']:.2%})")

            # Save results
            output_file = f"predictions_{Path(args.input).stem}.json"
            with open(output_file, 'w') as f:
                json.dump(results, f, indent=2)

            print()
            print(f"✓ Predictions saved to {output_file}")

        else:
            # Parse JSON string
            try:
                features = json.loads(args.input)
                result = predict_signal(features, model, scaler, args.device)

                print("Prediction:")
                print(f"  Signal: {result['signal']}")
                print(f"  Confidence: {result['confidence']:.2%}")
                print(f"  Probabilities: {result['probabilities']}")

            except json.JSONDecodeError:
                print(f"Error: Invalid JSON input")

    else:
        # Demo mode
        demo_features = [
            {
                'name': 'Bullish signal',
                'features': {
                    'price_change': 0.08,
                    'volume_change': 0.30,
                    'rsi': 70,
                    'macd': 0.8,
                    'ma_5': 101.2,
                    'ma_20': 99.5,
                    'volatility': 0.18,
                    'sentiment_score': 0.9
                }
            },
            {
                'name': 'Bearish signal',
                'features': {
                    'price_change': -0.05,
                    'volume_change': -0.25,
                    'rsi': 30,
                    'macd': -0.6,
                    'ma_5': 97.5,
                    'ma_20': 99.0,
                    'volatility': 0.25,
                    'sentiment_score': -0.7
                }
            },
            {
                'name': 'Neutral signal',
                'features': {
                    'price_change': 0.01,
                    'volume_change': 0.05,
                    'rsi': 50,
                    'macd': 0.0,
                    'ma_5': 99.5,
                    'ma_20': 99.3,
                    'volatility': 0.10,
                    'sentiment_score': 0.2
                }
            }
        ]

        print("=" * 50)
        print("Demo Mode - Sample Predictions")
        print("=" * 50)
        print()

        for example in demo_features:
            print(f"{example['name']}:")
            print(f"  Features: {example['features']}")

            result = predict_signal(example['features'], model, scaler, args.device)

            print(f"  Prediction: {result['signal']} ({result['confidence']:.2%})")
            print(f"  Probabilities: SELL={result['probabilities']['SELL']:.2%}, "
                  f"HOLD={result['probabilities']['HOLD']:.2%}, "
                  f"BUY={result['probabilities']['BUY']:.2%}")
            print()


if __name__ == "__main__":
    main()
