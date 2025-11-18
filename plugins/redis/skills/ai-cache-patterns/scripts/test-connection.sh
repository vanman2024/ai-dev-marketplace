#!/bin/bash
# Test Redis connection

echo "Testing Redis connection..."
redis-cli ping || echo "Redis connection failed"
