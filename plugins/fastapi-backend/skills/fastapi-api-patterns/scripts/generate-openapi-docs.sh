#!/bin/bash

# generate-openapi-docs.sh
# Generates enhanced OpenAPI documentation from FastAPI application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== FastAPI OpenAPI Documentation Generator ===${NC}\n"

# Default values
APP_MODULE="${1:-app.main:app}"
OUTPUT_FILE="${2:-openapi.json}"
HOST="${3:-127.0.0.1}"
PORT="${4:-8000}"

echo "Configuration:"
echo "  App Module: $APP_MODULE"
echo "  Output File: $OUTPUT_FILE"
echo "  Host: $HOST"
echo "  Port: $PORT"
echo ""

# Check if FastAPI is installed
echo -n "Checking for FastAPI installation... "
if python3 -c "import fastapi" 2>/dev/null; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    echo "Please install FastAPI: pip install fastapi"
    exit 1
fi

# Method 1: Generate from running app (preferred)
echo -e "\n${BLUE}Method 1: Generating from application code${NC}"

PYTHON_SCRIPT=$(cat <<'EOF'
import json
import sys
from importlib import import_module

def load_app(app_path):
    """Load FastAPI app from module path"""
    module_path, app_name = app_path.split(":")
    module = import_module(module_path)
    return getattr(module, app_name)

def generate_openapi(app_module, output_file):
    """Generate OpenAPI schema from FastAPI app"""
    try:
        app = load_app(app_module)
        openapi_schema = app.openapi()

        # Enhance schema with additional metadata
        if "info" in openapi_schema:
            if "x-generated-by" not in openapi_schema["info"]:
                openapi_schema["info"]["x-generated-by"] = "fastapi-api-patterns skill"

        # Write to file
        with open(output_file, "w") as f:
            json.dump(openapi_schema, f, indent=2)

        # Stats
        paths_count = len(openapi_schema.get("paths", {}))
        schemas_count = len(openapi_schema.get("components", {}).get("schemas", {}))

        print(f"✓ Generated OpenAPI schema successfully")
        print(f"  Endpoints: {paths_count}")
        print(f"  Schemas: {schemas_count}")
        print(f"  Output: {output_file}")
        return True

    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        return False

if __name__ == "__main__":
    app_module = sys.argv[1]
    output_file = sys.argv[2]
    success = generate_openapi(app_module, output_file)
    sys.exit(0 if success else 1)
EOF
)

if echo "$PYTHON_SCRIPT" | python3 - "$APP_MODULE" "$OUTPUT_FILE"; then
    echo -e "${GREEN}✓ OpenAPI schema generated successfully${NC}"

    # Generate additional formats
    echo -e "\n${BLUE}Generating additional formats...${NC}"

    # YAML format
    echo -n "  Converting to YAML... "
    if python3 -c "import yaml" 2>/dev/null; then
        OUTPUT_YAML="${OUTPUT_FILE%.json}.yaml"
        python3 -c "
import json, yaml
with open('$OUTPUT_FILE') as f:
    data = json.load(f)
with open('$OUTPUT_YAML', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, sort_keys=False)
print('$OUTPUT_YAML')
" && echo -e "${GREEN}✓ Done${NC}" || echo -e "${YELLOW}⚠ Skipped${NC}"
    else
        echo -e "${YELLOW}⚠ Skipped (pyyaml not installed)${NC}"
    fi

    # HTML documentation
    echo -n "  Generating HTML docs... "
    HTML_OUTPUT="${OUTPUT_FILE%.json}.html"

    cat > "$HTML_OUTPUT" <<'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>API Documentation</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
    <div id="swagger-ui"></div>
    <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
    <script>
        fetch('OPENAPI_FILE')
            .then(response => response.json())
            .then(spec => {
                SwaggerUIBundle({
                    spec: spec,
                    dom_id: '#swagger-ui',
                    deepLinking: true,
                    presets: [
                        SwaggerUIBundle.presets.apis,
                        SwaggerUIBundle.SwaggerUIStandalonePreset
                    ],
                })
            });
    </script>
</body>
</html>
HTML_EOF

    # Replace placeholder with actual file
    sed -i "s|OPENAPI_FILE|$OUTPUT_FILE|g" "$HTML_OUTPUT"
    echo -e "${GREEN}✓ Done ($HTML_OUTPUT)${NC}"

    # Markdown documentation
    echo -n "  Generating Markdown docs... "
    MD_OUTPUT="${OUTPUT_FILE%.json}.md"

    python3 <<MARKDOWN_SCRIPT
import json

with open('$OUTPUT_FILE') as f:
    schema = json.load(f)

with open('$MD_OUTPUT', 'w') as md:
    info = schema.get('info', {})
    md.write(f"# {info.get('title', 'API Documentation')}\n\n")
    md.write(f"{info.get('description', '')}\n\n")
    md.write(f"**Version:** {info.get('version', '1.0.0')}\n\n")

    md.write("## Endpoints\n\n")

    for path, methods in schema.get('paths', {}).items():
        md.write(f"### {path}\n\n")
        for method, details in methods.items():
            if method.startswith('x-'):
                continue
            md.write(f"**{method.upper()}**\n\n")
            md.write(f"{details.get('summary', '')}\n\n")
            if 'description' in details:
                md.write(f"{details['description']}\n\n")

            # Parameters
            if 'parameters' in details:
                md.write("**Parameters:**\n\n")
                for param in details['parameters']:
                    required = " (required)" if param.get('required') else ""
                    md.write(f"- `{param['name']}` ({param['in']}){required}: {param.get('description', '')}\n")
                md.write("\n")

            # Request body
            if 'requestBody' in details:
                md.write("**Request Body:**\n\n")
                content = details['requestBody'].get('content', {})
                for content_type in content:
                    md.write(f"Content-Type: `{content_type}`\n\n")
                md.write("\n")

            # Responses
            if 'responses' in details:
                md.write("**Responses:**\n\n")
                for status, response in details['responses'].items():
                    md.write(f"- `{status}`: {response.get('description', '')}\n")
                md.write("\n")

    # Schemas
    schemas = schema.get('components', {}).get('schemas', {})
    if schemas:
        md.write("## Schemas\n\n")
        for name, schema_def in schemas.items():
            md.write(f"### {name}\n\n")
            md.write(f"{schema_def.get('description', '')}\n\n")
            if 'properties' in schema_def:
                md.write("**Properties:**\n\n")
                required = schema_def.get('required', [])
                for prop, details in schema_def['properties'].items():
                    req = " (required)" if prop in required else ""
                    prop_type = details.get('type', 'any')
                    md.write(f"- `{prop}` ({prop_type}){req}: {details.get('description', '')}\n")
                md.write("\n")

print('$MD_OUTPUT')
MARKDOWN_SCRIPT

    echo -e "${GREEN}✓ Done${NC}"

else
    echo -e "${RED}✗ Failed to generate OpenAPI schema${NC}"
    echo ""
    echo "Alternative: Start the server and download from /openapi.json"
    echo "  uvicorn $APP_MODULE --host $HOST --port $PORT"
    echo "  curl http://$HOST:$PORT/openapi.json > $OUTPUT_FILE"
    exit 1
fi

# Summary
echo -e "\n${BLUE}=== Generated Files ===${NC}"
echo "  JSON:     $OUTPUT_FILE"
[ -f "${OUTPUT_FILE%.json}.yaml" ] && echo "  YAML:     ${OUTPUT_FILE%.json}.yaml"
echo "  HTML:     $HTML_OUTPUT"
echo "  Markdown: $MD_OUTPUT"

echo -e "\n${GREEN}✓ Documentation generation complete${NC}"

# Optional: Validate against OpenAPI spec
echo -e "\n${BLUE}Validation (optional)${NC}"
if python3 -c "import openapi_spec_validator" 2>/dev/null; then
    echo -n "  Validating OpenAPI spec... "
    if python3 -c "
from openapi_spec_validator import validate_spec
import json
with open('$OUTPUT_FILE') as f:
    spec = json.load(f)
try:
    validate_spec(spec)
    print('Valid')
except Exception as e:
    print(f'Invalid: {e}')
    exit(1)
"; then
        echo -e "${GREEN}✓ Valid${NC}"
    else
        echo -e "${YELLOW}⚠ Validation issues found${NC}"
    fi
else
    echo "  openapi-spec-validator not installed (optional)"
    echo "  Install: pip install openapi-spec-validator"
fi

echo ""
echo "View documentation:"
echo "  Browser: open $HTML_OUTPUT"
echo "  Online:  https://editor.swagger.io/ (upload $OUTPUT_FILE)"

exit 0
