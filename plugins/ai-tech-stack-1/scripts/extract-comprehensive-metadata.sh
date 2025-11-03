#!/bin/bash

# Comprehensive AI Tech Stack Phase Metadata Extraction
# Recursively extracts ALL nested slash commands across all plugins

set -euo pipefail

MARKETPLACES_ROOT="/home/gotime2022/.claude/plugins/marketplaces"
PHASE_FILES=("build-full-stack-phase-0.md" "build-full-stack-phase-1.md" "build-full-stack-phase-2.md" "build-full-stack-phase-3.md" "build-full-stack-phase-4.md" "build-full-stack-phase-5.md")
MAX_DEPTH=5

# All marketplace directories to search
MARKETPLACES=("ai-dev-marketplace" "dev-lifecycle-marketplace" "mcp-servers-marketplace" "domain-plugin-builder")

# Command prefix aliases (slash command prefix → actual plugin directory)
declare -A PLUGIN_ALIASES
PLUGIN_ALIASES["agent-sdk-dev"]="claude-agent-sdk"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

declare -A VISITED_COMMANDS
declare -A COMMAND_DEPTH

# Function to extract plugin and command name from slash command
parse_command() {
    local cmd="$1"
    # Remove leading slash and split on colon
    cmd="${cmd#/}"
    local plugin="${cmd%%:*}"
    local command="${cmd#*:}"
    # Remove arguments
    command="${command%% *}"
    echo "$plugin|$command"
}

# Function to find command file path across all marketplaces
find_command_file() {
    local plugin="$1"
    local command="$2"

    # Check if plugin has an alias
    local actual_plugin="${PLUGIN_ALIASES[$plugin]:-$plugin}"

    # Search in all marketplaces
    for marketplace in "${MARKETPLACES[@]}"; do
        local cmd_file="$MARKETPLACES_ROOT/$marketplace/plugins/$actual_plugin/commands/${command}.md"

        if [ -f "$cmd_file" ]; then
            echo "$cmd_file"
            return 0
        fi
    done

    return 1
}

# Function to extract all slash commands from a file
extract_commands() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return
    fi

    # Extract commands using multiple patterns
    {
        # Pattern 1: !{slashcommand /plugin:command ...}
        grep -oP '!{slashcommand\s+/[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null | sed 's/!{slashcommand\s*//' || true

        # Pattern 2: SlashCommand: /plugin:command
        grep -oP 'SlashCommand:\s*/[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null | sed 's/SlashCommand:\s*//' || true

        # Pattern 3: Direct /plugin:command on its own line
        grep -oP '^\s*/[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null || true
    } | sed 's/\s.*$//' | grep '^/' | sort -u
}

# Function to extract agents used in a file
extract_agents() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return
    fi

    # Look for Task(subagent_type= or Task tool calls with specific agents
    grep -oP '(subagent_type=["'"'"']?[a-z0-9-]+["'"'"']?|Task.*agent)' "$file" 2>/dev/null | \
        grep -oP '[a-z0-9-]+' | sort -u || true
}

# Recursive function to build command tree
build_command_tree() {
    local cmd="$1"
    local depth="$2"
    local indent="$3"

    # Prevent infinite recursion
    if [ "$depth" -ge "$MAX_DEPTH" ]; then
        return
    fi

    # Skip if already visited at this or lower depth
    if [ -n "${VISITED_COMMANDS[$cmd]:-}" ]; then
        local prev_depth="${COMMAND_DEPTH[$cmd]}"
        if [ "$prev_depth" -le "$depth" ]; then
            return
        fi
    fi

    VISITED_COMMANDS[$cmd]=1
    COMMAND_DEPTH[$cmd]=$depth

    # Parse command
    local parsed=$(parse_command "$cmd")
    local plugin="${parsed%|*}"
    local command="${parsed#*|}"

    # Find command file
    local cmd_file=$(find_command_file "$plugin" "$command" || echo "")

    if [ -z "$cmd_file" ]; then
        echo "${indent}${cmd} [NOT FOUND]" >&2
        return
    fi

    # Extract nested commands
    local nested_commands=$(extract_commands "$cmd_file")

    if [ -n "$nested_commands" ]; then
        while IFS= read -r nested_cmd; do
            # Recursively process nested command
            build_command_tree "$nested_cmd" $((depth + 1)) "${indent}  "
        done <<< "$nested_commands"
    fi
}

# Function to collect all unique commands at all depths
collect_all_commands() {
    local file="$1"

    # Reset visited tracking
    unset VISITED_COMMANDS
    unset COMMAND_DEPTH
    declare -gA VISITED_COMMANDS
    declare -gA COMMAND_DEPTH

    # Extract top-level commands
    local top_commands=$(extract_commands "$file")

    # Build tree for each top-level command
    while IFS= read -r cmd; do
        if [ -n "$cmd" ]; then
            build_command_tree "$cmd" 0 ""
        fi
    done <<< "$top_commands"

    # Output all visited commands sorted by depth
    for cmd in "${!VISITED_COMMANDS[@]}"; do
        local depth="${COMMAND_DEPTH[$cmd]}"
        echo "${depth}|${cmd}"
    done | sort -t'|' -k1,1n -k2,2
}

# Main execution
echo "{"
echo '  "generatedAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
echo '  "orchestrator": "/ai-tech-stack-1:build-full-stack",'
echo '  "totalPhasesAnalyzed": 6,'
echo '  "phases": ['

for phase_idx in {0..5}; do
    phase_file="../commands/${PHASE_FILES[$phase_idx]}"

    if [ ! -f "$phase_file" ]; then
        echo "  Phase $phase_idx file not found: $phase_file" >&2
        continue
    fi

    # Extract phase name
    phase_name=$(grep -m1 "^description:" "$phase_file" | sed 's/description: "Phase [0-9]: //' | sed 's/"$//')

    echo "    {"
    echo "      \"phase\": $phase_idx,"
    echo "      \"name\": \"$phase_name\","
    echo "      \"file\": \"${PHASE_FILES[$phase_idx]}\","

    # Collect all commands (direct + nested)
    echo "      \"allCommands\": ["

    all_cmds=$(collect_all_commands "$phase_file")

    if [ -n "$all_cmds" ]; then
        while IFS='|' read -r depth cmd; do
            cmd_escaped=$(echo "$cmd" | sed 's/"/\\"/g')
            echo "        {\"depth\": $depth, \"command\": \"$cmd_escaped\"},"
        done <<< "$all_cmds" | sed '$ s/,$//'
    fi

    echo "      ],"

    # Extract agents
    echo "      \"agents\": ["
    agents=$(extract_agents "$phase_file")
    if [ -n "$agents" ]; then
        while IFS= read -r agent; do
            echo "        \"$agent\","
        done <<< "$agents" | sed '$ s/,$//'
    fi
    echo "      ],"

    # Count commands
    total_commands=$(echo "$all_cmds" | grep -c '|' || echo "0")
    echo "      \"totalCommands\": $total_commands"

    if [ $phase_idx -lt 5 ]; then
        echo "    },"
    else
        echo "    }"
    fi
done

echo "  ]"
echo "}"
