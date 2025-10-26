# API Schema Analyzer Scripts

Scripts for analyzing OpenAPI and Postman schemas.

## Scripts

### `analyze-openapi.py`
Parse OpenAPI v2/v3 specifications and extract endpoint information.

**Usage:** `./analyze-openapi.py <openapi.json|yaml>`

### `generate-tool-signatures.py`
Generate MCP tool function signatures from API schemas.

**Usage:** `./generate-tool-signatures.py <schema.json> --lang=python|typescript`

### `map-to-mcp-tools.py`
Map API endpoints to MCP tool definitions.

**Usage:** `./map-to-mcp-tools.py <collection.json> --output=tools.json`

## Dependencies
- Python 3.7+
- `pyyaml`, `jsonschema` packages
- jq for JSON processing
