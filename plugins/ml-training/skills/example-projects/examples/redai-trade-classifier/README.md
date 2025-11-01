# RedAI Trade Classifier

Multi-class classification for trading signals (BUY/HOLD/SELL) using market indicators.

## Overview

This example demonstrates:
- Financial ML for algorithmic trading
- Multi-class classification with imbalanced data
- Feature engineering from market data
- Class weighting for better predictions
- Modal deployment for production trading

## Quick Start

### 1. Setup

```bash
pip install -r requirements.txt
```

### 2. Train Model

```bash
# Train with sample data
python train.py

# Train with custom data
python train.py --data your_market_data.csv
```

**Training output:**
- Model checkpoint: `models/trade-classifier/model.pt`
- Classification metrics
- Confusion matrix

**Expected results:**
- Training time: 10-20 minutes
- Accuracy: 70-85% (depends on data quality)
- Class distribution handled with weighting

### 3. Run Inference

```bash
# Demo mode
python inference.py

# Interactive mode
python inference.py --interactive

# File prediction
python inference.py --input market_data.csv

# JSON input
python inference.py --input '{"price_change": 0.05, "rsi": 65, ...}'
```

### 4. Deploy to Modal

```bash
# Setup Modal account
modal token new

# Deploy to Modal
modal deploy modal_deploy.py

# Get API endpoint
modal app show redai-trade-classifier
```

## Data Format

### Required Features

All predictions require 8 market indicators:

```python
{
    "price_change": 0.05,        # Price change (-1 to 1)
    "volume_change": 0.20,       # Volume change (-1 to 1)
    "rsi": 65,                   # RSI (0-100)
    "macd": 0.5,                 # MACD indicator
    "ma_5": 100.5,               # 5-day moving average
    "ma_20": 99.2,               # 20-day moving average
    "volatility": 0.15,          # Volatility (0-1)
    "sentiment_score": 0.8       # Sentiment (-1 to 1)
}
```

### Training Data Format

**CSV:**
```csv
price_change,volume_change,rsi,macd,ma_5,ma_20,volatility,sentiment_score,signal
0.05,0.20,65,0.5,100.5,99.2,0.15,0.8,2
-0.03,-0.15,35,-0.3,98.2,99.1,0.20,-0.6,0
```

**JSON:**
```json
[
  {
    "price_change": 0.05,
    "volume_change": 0.20,
    "rsi": 65,
    "macd": 0.5,
    "ma_5": 100.5,
    "ma_20": 99.2,
    "volatility": 0.15,
    "sentiment_score": 0.8,
    "signal": 2
  }
]
```

### Signal Labels

- **0 = SELL** - Bearish signal, exit or short
- **1 = HOLD** - Neutral, maintain position
- **2 = BUY** - Bullish signal, enter or long

## Feature Engineering

### Calculate Features from Raw Data

```python
import pandas as pd
import numpy as np

def calculate_features(df):
    """
    Calculate trading features from OHLCV data

    Args:
        df: DataFrame with columns [date, open, high, low, close, volume]

    Returns:
        DataFrame with engineered features
    """
    # Price change (normalized)
    df['price_change'] = df['close'].pct_change()

    # Volume change
    df['volume_change'] = df['volume'].pct_change()

    # RSI (Relative Strength Index)
    delta = df['close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    rs = gain / loss
    df['rsi'] = 100 - (100 / (1 + rs))

    # MACD
    ema_12 = df['close'].ewm(span=12).mean()
    ema_26 = df['close'].ewm(span=26).mean()
    df['macd'] = ema_12 - ema_26

    # Moving averages
    df['ma_5'] = df['close'].rolling(window=5).mean()
    df['ma_20'] = df['close'].rolling(window=20).mean()

    # Volatility (standard deviation)
    df['volatility'] = df['close'].rolling(window=20).std() / df['close']

    # Sentiment (you need to provide this from news/social media)
    # df['sentiment_score'] = your_sentiment_model(...)

    return df
```

## Model Architecture

### Neural Network

```
Input Layer (8 features)
    ↓
Dense Layer (128 neurons) + ReLU + Dropout(0.3)
    ↓
Dense Layer (128 neurons) + ReLU + Dropout(0.3)
    ↓
Output Layer (3 classes: SELL, HOLD, BUY)
```

### Training Details

- **Optimizer:** Adam
- **Learning rate:** 1e-3
- **Loss:** CrossEntropyLoss with class weights
- **Epochs:** 10
- **Batch size:** 32

### Class Weighting

To handle imbalanced data (more HOLD signals than BUY/SELL):

```python
class_weights = [1.0, 1.5, 1.0]  # [SELL, HOLD, BUY]
```

This gives HOLD signals 1.5x weight in loss calculation.

## Trading Strategy Integration

### Real-time Prediction

```python
from inference import load_model, predict_signal

# Load model once
model, scaler = load_model("models/trade-classifier/model.pt")

# Get current market data
current_features = {
    'price_change': calculate_price_change(),
    'volume_change': calculate_volume_change(),
    'rsi': calculate_rsi(),
    'macd': calculate_macd(),
    'ma_5': calculate_ma(5),
    'ma_20': calculate_ma(20),
    'volatility': calculate_volatility(),
    'sentiment_score': get_sentiment()
}

# Predict signal
result = predict_signal(current_features, model, scaler)

if result['signal'] == 'BUY' and result['confidence'] > 0.7:
    execute_buy_order()
elif result['signal'] == 'SELL' and result['confidence'] > 0.7:
    execute_sell_order()
```

### Backtesting

```python
import pandas as pd

# Load historical data
historical_data = pd.read_csv("historical_prices.csv")

# Calculate features
features_df = calculate_features(historical_data)

# Generate signals
signals = []
for _, row in features_df.iterrows():
    result = predict_signal(row.to_dict(), model, scaler)
    signals.append(result['signal'])

# Evaluate strategy
features_df['predicted_signal'] = signals
features_df['returns'] = features_df['close'].pct_change()

# Calculate strategy returns
strategy_returns = []
for i in range(len(features_df)):
    if features_df.iloc[i]['predicted_signal'] == 'BUY':
        strategy_returns.append(features_df.iloc[i+1]['returns'])
    elif features_df.iloc[i]['predicted_signal'] == 'SELL':
        strategy_returns.append(-features_df.iloc[i+1]['returns'])

cumulative_return = (1 + pd.Series(strategy_returns)).cumprod()[-1]
print(f"Strategy return: {cumulative_return:.2%}")
```

## Production Deployment

### Modal API Usage

```python
import requests

# API endpoint (from modal deploy)
API_URL = "https://your-app.modal.run/predict"

# Market data
features = {
    "price_change": 0.05,
    "volume_change": 0.20,
    "rsi": 65,
    "macd": 0.5,
    "ma_5": 100.5,
    "ma_20": 99.2,
    "volatility": 0.15,
    "sentiment_score": 0.8
}

# Get prediction
response = requests.post(API_URL, json=features)
result = response.json()

print(f"Signal: {result['signal']}")
print(f"Confidence: {result['confidence']:.2%}")
```

### Batch Predictions

```python
# Multiple predictions at once
batch_features = [features1, features2, features3]

response = requests.post(
    "https://your-app.modal.run/batch",
    json={"feature_list": batch_features}
)

results = response.json()
```

## Performance Metrics

### Expected Performance

| Metric | Value | Notes |
|--------|-------|-------|
| Accuracy | 70-85% | Depends on data quality |
| Precision (BUY) | 65-80% | Reduces false signals |
| Recall (BUY) | 60-75% | Catches real opportunities |
| F1 Score | 65-78% | Balanced performance |

### Improving Performance

1. **More training data** - 1000+ samples recommended
2. **Better features** - Add more technical indicators
3. **Feature selection** - Remove redundant features
4. **Ensemble methods** - Combine multiple models
5. **Better sentiment** - Use advanced NLP for news analysis

## Risk Management

### Confidence Thresholds

Only trade on high-confidence signals:

```python
MIN_CONFIDENCE = 0.7

result = predict_signal(features, model, scaler)

if result['confidence'] >= MIN_CONFIDENCE:
    execute_trade(result['signal'])
else:
    print("Low confidence, skipping trade")
```

### Position Sizing

Scale position size by confidence:

```python
def calculate_position_size(confidence, max_position=1.0):
    """
    confidence: 0.0 to 1.0
    max_position: Maximum position size
    """
    return max_position * confidence

result = predict_signal(features, model, scaler)
position = calculate_position_size(result['confidence'])

if result['signal'] == 'BUY':
    buy(shares=position * 100)
```

## Troubleshooting

### Poor Predictions

**Issue:** Model predicts mostly HOLD

**Solution:**
- Increase class weights for BUY/SELL
- Collect more diverse training data
- Adjust feature normalization

### Out of Memory

**Issue:** Training fails with OOM

**Solution:**
```bash
python train.py --batch-size 16  # Reduce from 32
```

### Modal Deployment Issues

**Issue:** Model not found on Modal

**Solution:**
```bash
# Upload model to Modal volume
modal run modal_deploy.py::upload_model
```

## Advanced Topics

### Add More Features

```python
# In train.py, add features:
feature_vector = [
    row['price_change'],
    row['volume_change'],
    row['rsi'],
    row['macd'],
    row['ma_5'],
    row['ma_20'],
    row['volatility'],
    row['sentiment_score'],
    # Add new features:
    row['bollinger_upper'],
    row['bollinger_lower'],
    row['obv'],  # On-Balance Volume
    row['atr'],  # Average True Range
]
```

### Hyperparameter Tuning

```bash
# Try different configurations
python train.py --hidden-dim 256 --dropout 0.4 --learning-rate 5e-4
python train.py --hidden-dim 64 --dropout 0.2 --learning-rate 2e-3
```

### Multi-timeframe Analysis

Combine predictions from different timeframes:

```python
# Get predictions for 1h, 4h, 1d
signal_1h = predict(features_1h)
signal_4h = predict(features_4h)
signal_1d = predict(features_1d)

# Aggregate
if signal_1h == signal_4h == signal_1d == 'BUY':
    # Strong consensus
    execute_buy()
```

## Disclaimer

This is an educational example. Do not use for real trading without:
- Extensive backtesting
- Risk management
- Paper trading validation
- Professional financial advice

Trading involves substantial risk of loss.

## Resources

- **Technical Analysis:** https://www.investopedia.com/technical-analysis-4689657
- **Modal Docs:** https://modal.com/docs
- **TA-Lib:** https://ta-lib.org/ (Advanced indicators)
- **Backtrader:** https://www.backtrader.com/ (Backtesting framework)

## License

MIT - For educational purposes only
