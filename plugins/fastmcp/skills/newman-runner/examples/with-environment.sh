#!/usr/bin/env bash
# Example: Newman tests with environment variables

# Run tests with specific environment
../scripts/run-newman.sh api-tests.json staging-env.json

# Check if tests passed
if ../scripts/analyze-newman-results.py newman-results/results-*.json; then
    echo "All tests passed!"
else
    echo "Tests failed - check report"
    exit 1
fi
