#!/usr/bin/env bash
# Example: Basic Newman test execution

# Run tests on a simple API collection
../scripts/run-newman.sh sample-api-collection.json

# Analyze the results
../scripts/analyze-newman-results.py newman-results/results-*.json
