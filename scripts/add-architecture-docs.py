#!/usr/bin/env python3
"""
Script to add architecture doc loading to all agents
Usage: python3 add-architecture-docs.py <plugin-name>
"""

import sys
import re
from pathlib import Path

# Architecture doc mapping by plugin
PLUGIN_DOCS = {
    'openrouter': {
        'docs': ['ai.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI/ML architecture, model routing, provider config)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'rag-pipeline': {
        'docs': ['ai.md', 'data.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI/ML architecture, RAG configuration, embeddings)',
            '- Read: docs/architecture/data.md (if exists - vector store, database schema, indexing)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'elevenlabs': {
        'docs': ['ai.md', 'frontend.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI/ML architecture, voice features, models)',
            '- Read: docs/architecture/frontend.md (if exists - UI components, integration patterns)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'supabase': {
        'docs': ['data.md', 'security.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/data.md (if exists - database schema, tables, relationships)',
            '- Read: docs/architecture/security.md (if exists - RLS policies, auth, encryption)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'vercel-ai-sdk': {
        'docs': ['ai.md', 'frontend.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI/ML architecture, model config, streaming)',
            '- Read: docs/architecture/frontend.md (if exists - Next.js architecture, API routes)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'nextjs-frontend': {
        'docs': ['frontend.md', 'data.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/frontend.md (if exists - pages, components, routing, state)',
            '- Read: docs/architecture/data.md (if exists - API integration, data fetching)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'fastapi-backend': {
        'docs': ['backend.md', 'data.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/backend.md (if exists - API endpoints, services, architecture)',
            '- Read: docs/architecture/data.md (if exists - database models, repositories)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'claude-agent-sdk': {
        'docs': ['ai.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI agent orchestration, tools, workflows)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
    'mem0': {
        'docs': ['ai.md', 'data.md', 'ROADMAP.md'],
        'descriptions': [
            '- Read: docs/architecture/ai.md (if exists - AI/ML architecture, memory config)',
            '- Read: docs/architecture/data.md (if exists - memory storage, vector database)',
            '- Read: docs/ROADMAP.md (if exists - project timeline, milestones, feature priorities)',
        ]
    },
}

def add_architecture_section(agent_path, plugin):
    """Add architecture documentation section to agent file"""

    content = agent_path.read_text()

    # Check if already has architecture section
    if '### 1. Architecture & Documentation Discovery' in content:
        return False, "already has architecture section"

    # Check for Project Approach section
    if '## Project Approach' not in content:
        return False, "no '## Project Approach' section found"

    # Get docs for this plugin
    plugin_config = PLUGIN_DOCS.get(plugin, PLUGIN_DOCS['openrouter'])  # Default fallback
    doc_descriptions = '\n'.join(plugin_config['descriptions'])

    # Create architecture section
    arch_section = f"""### 1. Architecture & Documentation Discovery

Before building, check for project architecture documentation:

{doc_descriptions}
- Extract requirements from architecture
- If architecture exists: Build from specifications
- If no architecture: Use defaults and best practices

"""

    # Insert after "## Project Approach" and renumber sections
    lines = content.split('\n')
    new_lines = []
    in_project_approach = False
    inserted = False

    for line in lines:
        if line.strip() == '## Project Approach':
            new_lines.append(line)
            new_lines.append('')
            new_lines.extend(arch_section.split('\n'))
            in_project_approach = True
            inserted = True
            continue

        # Renumber sections after insertion
        if in_project_approach and inserted:
            if line.startswith('### 1.') and 'Architecture' not in line:
                line = line.replace('### 1.', '### 2.', 1)
            elif line.startswith('### 2.') and 'Discovery' not in line:
                line = line.replace('### 2.', '### 3.', 1)
            elif line.startswith('### 3.') and 'Analysis' not in line:
                line = line.replace('### 3.', '### 4.', 1)
            elif line.startswith('### 4.') and 'Planning' not in line:
                line = line.replace('### 4.', '### 5.', 1)
            elif line.startswith('### 5.') and 'Implementation' not in line:
                line = line.replace('### 5.', '### 6.', 1)

        new_lines.append(line)

    # Write back
    agent_path.write_text('\n'.join(new_lines))
    return True, "updated"

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 add-architecture-docs.py <plugin-name>")
        print("Example: python3 add-architecture-docs.py supabase")
        sys.exit(1)

    plugin = sys.argv[1]
    agent_dir = Path(f"plugins/{plugin}/agents")

    if not agent_dir.exists():
        print(f"Error: Directory {agent_dir} not found")
        sys.exit(1)

    print(f"Processing agents in {agent_dir}...")
    docs = PLUGIN_DOCS.get(plugin, PLUGIN_DOCS['openrouter'])
    print(f"Architecture docs: {', '.join(docs['docs'])}")
    print()

    updated_count = 0
    skipped_count = 0

    for agent_path in sorted(agent_dir.glob('*.md')):
        success, message = add_architecture_section(agent_path, plugin)

        if success:
            print(f"✓ {agent_path.name}")
            updated_count += 1
        else:
            print(f"⏩ {agent_path.name} - {message}")
            skipped_count += 1

    print()
    print(f"Updated {updated_count} agents, skipped {skipped_count}")

if __name__ == '__main__':
    main()
