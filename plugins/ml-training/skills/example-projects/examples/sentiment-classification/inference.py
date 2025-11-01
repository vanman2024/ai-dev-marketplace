"""
Sentiment Classification Inference
Run predictions on trained sentiment model
"""

import argparse
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification


def predict_sentiment(text, model, tokenizer, device):
    """Predict sentiment for a single text"""
    model.eval()

    # Tokenize
    inputs = tokenizer(
        text,
        return_tensors='pt',
        truncation=True,
        max_length=512,
        padding=True
    ).to(device)

    # Predict
    with torch.no_grad():
        outputs = model(**inputs)
        prediction = torch.argmax(outputs.logits, dim=1).item()
        probabilities = torch.softmax(outputs.logits, dim=1)[0]

    sentiment = "Positive" if prediction == 1 else "Negative"
    confidence = probabilities[prediction].item()

    return {
        'sentiment': sentiment,
        'confidence': confidence,
        'probabilities': {
            'negative': probabilities[0].item(),
            'positive': probabilities[1].item()
        }
    }


def main():
    parser = argparse.ArgumentParser(description='Sentiment classification inference')
    parser.add_argument('--model-path', type=str, default='models/sentiment-classifier',
                        help='Path to trained model')
    parser.add_argument('--text', type=str, help='Text to classify')
    parser.add_argument('--interactive', action='store_true',
                        help='Run in interactive mode')
    parser.add_argument('--server', action='store_true',
                        help='Run as API server')
    parser.add_argument('--port', type=int, default=8000,
                        help='Server port (if --server)')

    args = parser.parse_args()

    # Load model and tokenizer
    print("Loading model...")
    device = 'cuda' if torch.cuda.is_available() else 'cpu'
    tokenizer = AutoTokenizer.from_pretrained(args.model_path)
    model = AutoModelForSequenceClassification.from_pretrained(args.model_path)
    model.to(device)
    print(f"Model loaded on {device}")
    print()

    if args.server:
        # Run API server
        from fastapi import FastAPI
        from pydantic import BaseModel
        import uvicorn

        app = FastAPI(title="Sentiment Classification API")

        class TextInput(BaseModel):
            text: str

        @app.post("/predict")
        def predict(input_data: TextInput):
            result = predict_sentiment(input_data.text, model, tokenizer, device)
            return result

        @app.get("/health")
        def health():
            return {"status": "healthy"}

        print(f"Starting API server on port {args.port}...")
        print(f"Endpoints:")
        print(f"  POST http://localhost:{args.port}/predict")
        print(f"  GET  http://localhost:{args.port}/health")
        print()

        uvicorn.run(app, host="0.0.0.0", port=args.port)

    elif args.interactive:
        # Interactive mode
        print("Interactive Sentiment Classification")
        print("Type 'quit' to exit")
        print("-" * 50)

        while True:
            text = input("\nEnter text: ").strip()

            if text.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break

            if not text:
                continue

            result = predict_sentiment(text, model, tokenizer, device)

            print(f"\nSentiment: {result['sentiment']}")
            print(f"Confidence: {result['confidence']:.2%}")
            print(f"Probabilities:")
            print(f"  Negative: {result['probabilities']['negative']:.2%}")
            print(f"  Positive: {result['probabilities']['positive']:.2%}")

    elif args.text:
        # Single prediction
        result = predict_sentiment(args.text, model, tokenizer, device)

        print(f"Text: {args.text}")
        print()
        print(f"Sentiment: {result['sentiment']}")
        print(f"Confidence: {result['confidence']:.2%}")
        print()
        print("Probabilities:")
        print(f"  Negative: {result['probabilities']['negative']:.2%}")
        print(f"  Positive: {result['probabilities']['positive']:.2%}")

    else:
        # Demo mode
        demo_texts = [
            "This is absolutely amazing!",
            "Terrible experience, very disappointed.",
            "It's okay, nothing special.",
            "Best product ever! Highly recommend!",
            "Waste of money. Don't buy this."
        ]

        print("Demo Mode - Testing sample texts:")
        print("=" * 50)

        for text in demo_texts:
            result = predict_sentiment(text, model, tokenizer, device)
            print(f"\nText: {text}")
            print(f"Sentiment: {result['sentiment']} ({result['confidence']:.2%})")


if __name__ == "__main__":
    main()
