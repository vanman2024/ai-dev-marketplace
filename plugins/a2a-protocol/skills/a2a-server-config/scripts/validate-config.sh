#!/bin/bash
# Validate A2A server configuration

set -e

SERVER_FILE="$1"

if [ -z "$SERVER_FILE" ]; then
    echo "Usage: $0 <server-file>"
    exit 1
fi

if [ ! -f "$SERVER_FILE" ]; then
    echo "Error: Server file not found: $SERVER_FILE"
    exit 1
fi

echo "Validating A2A server configuration: $SERVER_FILE"

ERRORS=0

# Check for hardcoded API keys
echo "Checking for hardcoded API keys..."
if grep -qE '(sk-ant-|sk-proj-|AIza[0-9A-Za-z-_]{35}|[0-9a-f]{32,})' "$SERVER_FILE"; then
    echo "  ERROR: Hardcoded API key detected!"
    echo "  Use environment variables: os.getenv('API_KEY') or process.env.API_KEY"
    ERRORS=$((ERRORS + 1))
else
    echo "  OK: No hardcoded API keys found"
fi

# Check for environment variable usage
echo "Checking for environment variable usage..."
if grep -qE '(os\.getenv|process\.env|ENV\[|getenv)' "$SERVER_FILE"; then
    echo "  OK: Environment variables are used"
else
    echo "  WARNING: No environment variable usage detected"
    echo "  Consider using environment variables for configuration"
fi

# Check for CORS configuration (HTTP servers)
if grep -qE '(uvicorn\.run|app\.listen|\.listen\(|createServer)' "$SERVER_FILE"; then
    echo "Checking CORS configuration..."
    if grep -qE '(CORSMiddleware|cors\(|Access-Control)' "$SERVER_FILE"; then
        echo "  OK: CORS configuration found"
    else
        echo "  WARNING: No CORS configuration found"
        echo "  Add CORS middleware for HTTP servers"
    fi
fi

# Check for transport configuration
echo "Checking transport configuration..."
if grep -qE '(transport=|StdioServerTransport|uvicorn\.run|app\.listen)' "$SERVER_FILE"; then
    echo "  OK: Transport configuration found"
else
    echo "  WARNING: No clear transport configuration"
fi

# Check for .gitignore
PROJECT_DIR=$(dirname "$SERVER_FILE")
while [ "$PROJECT_DIR" != "/" ] && [ ! -f "$PROJECT_DIR/.git/config" ]; do
    PROJECT_DIR=$(dirname "$PROJECT_DIR")
done

if [ -f "$PROJECT_DIR/.gitignore" ]; then
    echo "Checking .gitignore..."
    if grep -qE '(\.env$|\.env\.local)' "$PROJECT_DIR/.gitignore"; then
        echo "  OK: .env files are in .gitignore"
    else
        echo "  WARNING: Add .env files to .gitignore"
    fi
fi

# Check for placeholder patterns
echo "Checking for proper placeholders..."
if grep -qE 'your_.*_key_here|your_.*_token_here|your_.*_secret_here' "$SERVER_FILE"; then
    echo "  OK: Placeholder pattern found"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "Validation PASSED"
    exit 0
else
    echo "Validation FAILED with $ERRORS error(s)"
    exit 1
fi
