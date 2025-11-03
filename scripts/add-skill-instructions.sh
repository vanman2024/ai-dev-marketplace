#!/bin/bash

# Script to add skill availability instructions to all agents and commands
# Usage: bash add-skill-instructions.sh (can be run from anywhere)

set -e

# Find marketplace root by looking for plugins/ directory
find_marketplace_root() {
    local current_dir="$PWD"

    # Check if we're already in marketplace root
    if [ -d "$current_dir/plugins" ] && [ -d "$current_dir/scripts" ]; then
        echo "$current_dir"
        return 0
    fi

    # Check if script is in scripts/ subdirectory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local parent_dir="$(dirname "$script_dir")"
    if [ -d "$parent_dir/plugins" ] && [ -d "$parent_dir/scripts" ]; then
        echo "$parent_dir"
        return 0
    fi

    # Search upwards for marketplace root
    while [ "$current_dir" != "/" ]; do
        if [ -d "$current_dir/plugins" ] && [ -d "$current_dir/scripts" ] && [ -f "$current_dir/.claude-plugin/marketplace.json" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    echo "ERROR: Could not find ai-dev-marketplace root directory" >&2
    echo "Please run this script from within the marketplace directory" >&2
    return 1
}

MARKETPLACE_DIR=$(find_marketplace_root)
if [ $? -ne 0 ]; then
    exit 1
fi

cd "$MARKETPLACE_DIR"
echo "📍 Working in: $MARKETPLACE_DIR"
echo ""

echo "🔍 Adding skill availability instructions to agents and commands..."
echo ""

# Counters
agents_updated=0
commands_updated=0
agents_skipped=0
commands_skipped=0

# Function to get skills for a plugin
get_plugin_skills() {
    local plugin_path="$1"
    local skills_dir="$plugin_path/skills"

    if [ -d "$skills_dir" ]; then
        # List all skill directories
        ls "$skills_dir" 2>/dev/null | sort
    fi
}

# Function to add skills section to a file
add_skills_section() {
    local file="$1"
    local plugin_name="$2"
    local plugin_path="plugins/$plugin_name"

    # Check if file already has skill instructions
    if grep -q "## Available Skills" "$file"; then
        return 1  # Skip
    fi

    # Get skills for this plugin
    local skills=$(get_plugin_skills "$plugin_path")
    local skill_count=$(echo "$skills" | grep -v "^$" | wc -l)

    if [ "$skill_count" -eq 0 ]; then
        return 1  # No skills, skip
    fi

    # Build skill list
    local skill_list=""
    while IFS= read -r skill; do
        if [ -n "$skill" ]; then
            # Read skill description from SKILL.md if available
            local skill_file="$plugin_path/skills/$skill/SKILL.md"
            if [ -f "$skill_file" ]; then
                local description=$(grep "^description:" "$skill_file" | sed 's/description: //')
                skill_list="${skill_list}- **$skill**: $description
"
            else
                skill_list="${skill_list}- **$skill**
"
            fi
        fi
    done <<< "$skills"

    # Create skills section
    local skills_section="## Available Skills

This $(basename $(dirname "$file")) has access to the following skills from the $plugin_name plugin:

$skill_list
**To use a skill:**
\`\`\`
!{skill skill-name}
\`\`\`

Use skills when you need:
- Domain-specific templates and examples
- Validation scripts and automation
- Best practices and patterns
- Configuration generators

Skills provide pre-built resources to accelerate your work.

---

"

    # Find insertion point (after security section, before main content)
    # Look for the first ## that's not "Security"
    local line_num=$(grep -n "^## " "$file" | grep -v "## Security" | grep -v "## Available Skills" | head -1 | cut -d: -f1)

    if [ -z "$line_num" ]; then
        # No section found, add after frontmatter and security
        line_num=$(grep -n "^---$" "$file" | tail -1 | cut -d: -f1)
        line_num=$((line_num + 1))

        # Skip past security section
        local security_end=$(tail -n +$line_num "$file" | grep -n "^---$" | head -1 | cut -d: -f1)
        if [ -n "$security_end" ]; then
            line_num=$((line_num + security_end))
        fi
    fi

    # Insert skills section
    if [ -n "$line_num" ]; then
        # Insert at line_num
        echo "$skills_section" | cat - <(tail -n +$line_num "$file") > "$file.tmp"
        head -n $((line_num - 1)) "$file" >> "$file.tmp.header"
        cat "$file.tmp.header" "$file.tmp" > "$file"
        rm "$file.tmp" "$file.tmp.header"
        return 0
    else
        # Couldn't find insertion point, append at end
        echo "" >> "$file"
        echo "$skills_section" >> "$file"
        return 0
    fi
}

# Process all agent files
echo "📝 Processing agents..."
for plugin_dir in plugins/*/; do
    plugin_name=$(basename "$plugin_dir")

    for agent_file in "$plugin_dir"agents/*.md; do
        if [[ -f "$agent_file" ]]; then
            if add_skills_section "$agent_file" "$plugin_name"; then
                echo "  ✅ Updated: $agent_file"
                agents_updated=$((agents_updated + 1))
            else
                agents_skipped=$((agents_skipped + 1))
            fi
        fi
    done
done

echo ""
echo "📝 Processing commands..."
for plugin_dir in plugins/*/; do
    plugin_name=$(basename "$plugin_dir")

    for command_file in "$plugin_dir"commands/*.md; do
        if [[ -f "$command_file" ]]; then
            if add_skills_section "$command_file" "$plugin_name"; then
                echo "  ✅ Updated: $command_file"
                commands_updated=$((commands_updated + 1))
            else
                commands_skipped=$((commands_skipped + 1))
            fi
        fi
    done
done

echo ""
echo "✨ Summary:"
echo "  Agents updated: $agents_updated"
echo "  Agents skipped (no skills or already has section): $agents_skipped"
echo "  Commands updated: $commands_updated"
echo "  Commands skipped (no skills or already has section): $commands_skipped"
echo ""
echo "Total updated: $((agents_updated + commands_updated))"
echo ""
echo "✅ Done! Run 'git diff' to review changes."
