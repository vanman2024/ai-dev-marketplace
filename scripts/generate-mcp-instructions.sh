#!/bin/bash

# Script to generate MCP server usage instructions for agents
# Analyzes each agent and suggests which MCP servers it should use

MARKETPLACE_DIR="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace"
OUTPUT_FILE="$MARKETPLACE_DIR/scripts/mcp-instructions-review.txt"

echo "Analyzing agents and generating MCP server instructions..."
echo ""
echo "Output will be saved to: $OUTPUT_FILE"
echo ""

# Clear/create output file
> "$OUTPUT_FILE"

# Function to determine MCP servers based on plugin
get_mcp_servers_for_plugin() {
    local plugin=$1

    case "$plugin" in
        "supabase")
            echo "mcp__plugin_supabase_supabase"
            ;;
        "nextjs-frontend")
            echo "mcp__plugin_nextjs-frontend_shadcn, mcp__plugin_nextjs-frontend_design-system"
            ;;
        "vercel-ai-sdk")
            echo "mcp__plugin_vercel-ai-sdk_shadcn, mcp__plugin_vercel-ai-sdk_design-system"
            ;;
        "website-builder")
            echo "mcp__plugin_website-builder_shadcn, mcp__plugin_website-builder_design-system"
            ;;
        *)
            echo "NONE"
            ;;
    esac
}

# Function to generate instruction snippet
generate_instruction_snippet() {
    local plugin=$1
    local agent_name=$2
    local mcp_servers=$3

    if [ "$mcp_servers" = "NONE" ]; then
        echo "## MCP Server Usage

**This agent does not require MCP server access.**

Use standard tools (Bash, Read, Write, Edit) for file operations."
        return
    fi

    echo "## MCP Server Usage - CRITICAL

**REQUIRED MCP SERVERS:** $mcp_servers

You have access to multiple MCP servers, but you MUST use ONLY the servers listed above.

**DO NOT USE:**
- Other plugin MCP servers (they are for different purposes)
- MCP servers not listed above will cause errors

All operations must use the MCP servers specified above."
}

# Process each plugin
for plugin_dir in "$MARKETPLACE_DIR/plugins"/*; do
    if [ ! -d "$plugin_dir" ]; then
        continue
    fi

    plugin=$(basename "$plugin_dir")
    agents_dir="$plugin_dir/agents"

    if [ ! -d "$agents_dir" ]; then
        continue
    fi

    echo "=== Plugin: $plugin ===" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Get MCP servers for this plugin
    mcp_servers=$(get_mcp_servers_for_plugin "$plugin")

    echo "MCP Servers: $mcp_servers" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Process each agent
    for agent_file in "$agents_dir"/*.md; do
        if [ ! -f "$agent_file" ]; then
            continue
        fi

        agent_name=$(basename "$agent_file" .md)

        echo "--- Agent: $agent_name ---" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"

        # Generate instruction snippet
        snippet=$(generate_instruction_snippet "$plugin" "$agent_name" "$mcp_servers")

        echo "$snippet" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "File: $agent_file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "---" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done

    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "Done! Review the generated instructions at:"
echo "$OUTPUT_FILE"
echo ""
echo "Next step: Review and customize the instructions, then apply them to agents."
