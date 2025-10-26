#!/usr/bin/env python3
"""Analyze OpenAPI specification and extract endpoint information."""

import json
import sys
import yaml
from pathlib import Path

def load_spec(spec_file):
    """Load OpenAPI spec from JSON or YAML."""
    content = Path(spec_file).read_text()
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return yaml.safe_load(content)

def analyze_openapi(spec):
    """Extract endpoints, methods, and parameters from OpenAPI spec."""
    paths = spec.get('paths', {})
    endpoints = []

    for path, path_item in paths.items():
        for method, operation in path_item.items():
            if method in ['get', 'post', 'put', 'delete', 'patch']:
                endpoint = {
                    'path': path,
                    'method': method.upper(),
                    'operationId': operation.get('operationId', ''),
                    'summary': operation.get('summary', ''),
                    'parameters': [],
                    'requestBody': None,
                    'responses': {}
                }

                # Extract parameters
                for param in operation.get('parameters', []):
                    endpoint['parameters'].append({
                        'name': param.get('name'),
                        'in': param.get('in'),
                        'required': param.get('required', False),
                        'schema': param.get('schema', {})
                    })

                # Extract request body
                if 'requestBody' in operation:
                    endpoint['requestBody'] = operation['requestBody']

                # Extract responses
                for status, response in operation.get('responses', {}).items():
                    endpoint['responses'][status] = response.get('description', '')

                endpoints.append(endpoint)

    return endpoints

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: analyze-openapi.py <openapi.json|yaml>")
        sys.exit(1)

    spec = load_spec(sys.argv[1])
    endpoints = analyze_openapi(spec)

    print(f"\nFound {len(endpoints)} endpoints:\n")
    for ep in endpoints:
        print(f"{ep['method']} {ep['path']}")
        if ep['summary']:
            print(f"  Summary: {ep['summary']}")
        print(f"  Parameters: {len(ep['parameters'])}")
        print()

    # Output JSON
    print(json.dumps(endpoints, indent=2))
