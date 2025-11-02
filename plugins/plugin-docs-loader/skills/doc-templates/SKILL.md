---
skill_name: doc-templates
description: Provides reusable templates for generating documentation loading commands across all plugins
use_when:
  - "creating load-docs commands"
  - "generating doc loader templates"
  - "building plugin documentation loaders"
---

# Documentation Templates Skill

## Purpose

Provides reusable templates for generating documentation loading commands across all plugins.

## Templates

### template-doc-loader-command.md

Reusable template for creating load-docs commands with:
- Intelligent link extraction from markdown files
- Priority-based batching (P0/P1/P2)
- Parallel WebFetch execution
- Flexible scope control (core, all, feature-specific)

## Usage

This template is used by the domain-plugin-builder to generate load-docs commands for all plugins in the marketplace.

## Template Location

`templates/template-doc-loader-command.md`
