#!/usr/bin/env bash
# Example: Add Postman MCP server to configuration

# Add Postman server
../scripts/add-mcp-server.sh postman npx -y @executeautomation/postman-mcp-server

# Set API key environment variable
../scripts/set-server-env.sh postman POSTMAN_API_KEY="\${POSTMAN_API_KEY}"

# Validate the configuration
../scripts/validate-mcp-config.sh
