#!/usr/bin/env bash
# Example: Analyze OpenAPI spec and generate MCP tools

# Analyze the OpenAPI specification
../scripts/analyze-openapi.py ../templates/openapi-template.yaml

# Generate Python tool signatures
../scripts/generate-tool-signatures.py ../templates/openapi-template.yaml --lang=python
