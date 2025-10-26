# Postman Collection Manager Scripts

Scripts for importing, exporting, and managing Postman collections.

## Scripts

### `openapi-to-postman.sh`
Convert OpenAPI specifications to Postman collections.

**Usage:** `./openapi-to-postman.sh <openapi.json> <output-collection.json>`

### `import-from-url.sh`
Download Postman collection from URL.

**Usage:** `./import-from-url.sh <collection-url> <output.json>`

### `export-collection.sh`
Export collection in various formats.

**Usage:** `./export-collection.sh <collection.json> <format>`

### `extract-endpoints.sh`
List all endpoints in a collection.

**Usage:** `./extract-endpoints.sh <collection.json>`

### `merge-collections.sh`
Merge multiple Postman collections.

**Usage:** `./merge-collections.sh <collection1.json> <collection2.json> <output.json>`

### `filter-collection.sh`
Filter collection requests by pattern.

**Usage:** `./filter-collection.sh <collection.json> <pattern> <output.json>`

## Dependencies
- jq for JSON processing
- curl for URL imports
- openapi-to-postmanv2 (npm package)
