#!/bin/bash

# Recursively extract ALL commands from all phases and sub-commands

MARKETPLACE_ROOT="/home/gotime2022/.claude/plugins/marketplaces/ai-dev-marketplace/plugins"

# Function to extract commands from a file
extract_commands_from_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi

    # Find all slash commands in the file
    {
        grep -oP '!{slashcommand\s+/[^}]+' "$file" 2>/dev/null | sed 's/!{slashcommand\s*//'
        grep -oP 'SlashCommand:\s*/[^}\s]+' "$file" 2>/dev/null | sed 's/SlashCommand:\s*//'
        grep -oP '^\s*/[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null
    } | grep '^/' | sed 's/\s.*$//' | sort -u
}

# Function to find command file
find_command_file() {
    local cmd="$1"
    # Extract plugin and command name: /plugin:command
    local plugin=$(echo "$cmd" | sed 's|^/||' | cut -d: -f1)
    local command=$(echo "$cmd" | sed 's|^/||' | cut -d: -f2)

    local cmd_file="$MARKETPLACE_ROOT/$plugin/commands/${command}.md"
    echo "$cmd_file"
}

# Recursive function to get all commands
get_all_commands() {
    local file="$1"
    local indent="$2"

    local commands=$(extract_commands_from_file "$file")

    for cmd in $commands; do
        echo "${indent}${cmd}"

        # Find the command file and recurse
        local cmd_file=$(find_command_file "$cmd")
        if [ -f "$cmd_file" ]; then
            get_all_commands "$cmd_file" "${indent}  "
        fi
    done
}

echo "{"
echo '  "orchestrator": "/ai-tech-stack-1:build-full-stack",'
echo '  "phases": ['

for phase in 0 1 2 3 4 5; do
    file="build-full-stack-phase-${phase}.md"

    if [ ! -f "$file" ]; then
        continue
    fi

    name=$(grep -m1 "^description:" "$file" | sed 's/description: "Phase [0-9]: //' | sed 's/"$//')

    echo "    {"
    echo "      \"phase\": ${phase},"
    echo "      \"name\": \"${name}\","
    echo "      \"allCommands\": ["

    # Get all commands recursively
    all_cmds=$(get_all_commands "$file" "" | sort -u)

    for cmd in $all_cmds; do
        cmd_escaped=$(echo "$cmd" | sed 's/"/\\"/g')
        echo "        \"${cmd_escaped}\","
    done | sed '$ s/,$//'

    echo "      ]"

    if [ $phase -lt 5 ]; then
        echo "    },"
    else
        echo "    }"
    fi
done

echo "  ]"
echo "}"
