#!/usr/bin/env bash
# Example: Convert OpenAPI spec to Postman collection

# Convert OpenAPI to Postman
../scripts/openapi-to-postman.sh api-spec.json my-api-collection.json

# Extract all endpoints
../scripts/extract-endpoints.sh my-api-collection.json
