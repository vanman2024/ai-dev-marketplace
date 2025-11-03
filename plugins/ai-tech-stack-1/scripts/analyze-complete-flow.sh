#!/bin/bash

# Complete flow analysis: Commands → Agents → Skills → Output Files

MARKETPLACES_ROOT="/home/gotime2022/.claude/plugins/marketplaces"
OUTPUT_JSON="complete-flow-analysis.json"

echo "Analyzing complete AI Tech Stack flow..."
echo "{"
echo '  "generatedAt": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
echo '  "analysis": {'

# Function to extract agents from command file
extract_agents_from_command() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi

    # Look for Task(subagent_type= patterns
    grep -oP 'subagent_type=["'"'"']?[a-z0-9-]+["'"'"']?' "$file" 2>/dev/null | \
        grep -oP '[a-z0-9-]+' | sort -u
}

# Function to extract skills from command file
extract_skills_from_command() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi

    # Look for Skill( patterns and @skill references
    {
        grep -oP 'Skill\([^)]+\)' "$file" 2>/dev/null
        grep -oP '@[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null
    } | sort -u
}

# Function to find agent file
find_agent_file() {
    local plugin="$1"
    local agent="$2"

    local agent_file="$MARKETPLACES_ROOT/ai-dev-marketplace/plugins/$plugin/agents/${agent}.md"
    if [ -f "$agent_file" ]; then
        echo "$agent_file"
        return 0
    fi

    # Try dev-lifecycle-marketplace
    agent_file="$MARKETPLACES_ROOT/dev-lifecycle-marketplace/plugins/$plugin/agents/${agent}.md"
    if [ -f "$agent_file" ]; then
        echo "$agent_file"
        return 0
    fi

    return 1
}

# Function to extract skills from agent file
extract_skills_from_agent() {
    local file="$1"
    if [ ! -f "$file" ]; then
        return
    fi

    grep -oP '@[a-z0-9-]+\.md|@[a-z0-9-]+:[a-z0-9-]+' "$file" 2>/dev/null | sort -u
}

# Analyze Phase 0
echo '    "phase0": {'
echo '      "name": "Dev Lifecycle Foundation",'
echo '      "commands": ['

# /planning:init-project
echo '        {'
echo '          "command": "/planning:init-project",'
cmd_file="$MARKETPLACES_ROOT/dev-lifecycle-marketplace/plugins/planning/commands/init-project.md"
if [ -f "$cmd_file" ]; then
    agents=$(extract_agents_from_command "$cmd_file")
    echo '          "agents": ['
    for agent in $agents; do
        echo '            "'$agent'",'
    done | sed '$ s/,$//'
    echo '          ],'

    echo '          "skills": ['
    skills=$(extract_skills_from_command "$cmd_file")
    for skill in $skills; do
        echo '            "'$skill'",'
    done | sed '$ s/,$//'
    echo '          ],'

    echo '          "outputFiles": ['
    echo '            "specs/**/*.md",'
    echo '            "specs/**/spec.md",'
    echo '            "specs/**/plan.md",'
    echo '            "specs/**/tasks.md"'
    echo '          ]'
fi
echo '        }'

echo '      ]'
echo '    },'

# Analyze Phase 1 - /nextjs-frontend:build-full-stack
echo '    "phase1": {'
echo '      "name": "Foundation Stack",'
echo '      "commands": ['
echo '        {'
echo '          "command": "/nextjs-frontend:build-full-stack",'

cmd_file="$MARKETPLACES_ROOT/ai-dev-marketplace/plugins/nextjs-frontend/commands/build-full-stack.md"
if [ -f "$cmd_file" ]; then
    agents=$(extract_agents_from_command "$cmd_file")
    echo '          "agents": ['
    for agent in $agents; do
        echo '            "'$agent'",'
    done | sed '$ s/,$//'
    echo '          ],'

    echo '          "nestedCommands": ['
    echo '            "/nextjs-frontend:init",'
    echo '            "/nextjs-frontend:integrate-supabase",'
    echo '            "/nextjs-frontend:integrate-ai-sdk",'
    echo '            "/nextjs-frontend:add-page",'
    echo '            "/nextjs-frontend:add-component"'
    echo '          ],'

    echo '          "outputFiles": ['
    echo '            "package.json",'
    echo '            "next.config.js",'
    echo '            "tailwind.config.ts",'
    echo '            "src/app/**/*.tsx",'
    echo '            "src/components/**/*.tsx",'
    echo '            ".env.local"'
    echo '          ]'
fi

echo '        }'
echo '      ]'
echo '    }'

echo '  }'
echo "}"
