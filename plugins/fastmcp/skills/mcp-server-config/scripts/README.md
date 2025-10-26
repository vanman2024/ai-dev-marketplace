# MCP Server Config Scripts

Scripts for managing .mcp.json configuration files.

## Scripts

### `add-mcp-server.sh`
Add new MCP server to configuration.

**Usage:** `./add-mcp-server.sh <server-name> <command> [args...]`

### `remove-mcp-server.sh`
Remove server from configuration.

**Usage:** `./remove-mcp-server.sh <server-name>`

### `list-mcp-servers.sh`
List all configured MCP servers.

**Usage:** `./list-mcp-servers.sh`

### `set-server-env.sh`
Configure environment variables for a server.

**Usage:** `./set-server-env.sh <server-name> <VAR=value>`

### `validate-mcp-config.sh`
Validate .mcp.json structure.

**Usage:** `./validate-mcp-config.sh`

## Dependencies
- jq for JSON processing
