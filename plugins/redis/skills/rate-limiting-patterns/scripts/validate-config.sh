#!/bin/bash
# Validate Redis configuration

echo "Validating Redis configuration..."

# Check environment variables
if [ -z "$REDIS_URL" ]; then
    echo "⚠️  REDIS_URL not set"
fi

# Test connection
if redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis connection successful"
else
    echo "❌ Redis connection failed"
    exit 1
fi

echo "Validation complete!"
