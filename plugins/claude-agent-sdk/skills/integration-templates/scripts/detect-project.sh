#!/bin/bash
# Project Detection Script
# Analyzes the current project and outputs detection results
#
# Usage: bash detect-project.sh [project-path]
# Output: Key=Value pairs for use in integration

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" || exit 1

echo "# Project Detection Results"
echo "# Generated at: $(date)"
echo ""

# Detect Language and Framework
detect_framework() {
    if [ -f "bun.lockb" ] || [ -f "bunfig.toml" ]; then
        echo "LANGUAGE=typescript"
        echo "FRAMEWORK=bun"
    elif [ -f "package.json" ]; then
        echo "LANGUAGE=typescript"
        if grep -q '"next"' package.json 2>/dev/null; then
            echo "FRAMEWORK=nextjs"
        elif grep -q '"express"' package.json 2>/dev/null; then
            echo "FRAMEWORK=express"
        elif grep -q '"hono"' package.json 2>/dev/null; then
            echo "FRAMEWORK=hono"
        elif grep -q '"fastify"' package.json 2>/dev/null; then
            echo "FRAMEWORK=fastify"
        else
            echo "FRAMEWORK=node"
        fi
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "LANGUAGE=python"
        if grep -q "fastapi" requirements.txt 2>/dev/null || grep -q "fastapi" pyproject.toml 2>/dev/null; then
            echo "FRAMEWORK=fastapi"
        elif grep -q "flask" requirements.txt 2>/dev/null || grep -q "flask" pyproject.toml 2>/dev/null; then
            echo "FRAMEWORK=flask"
        elif grep -q "django" requirements.txt 2>/dev/null || grep -q "django" pyproject.toml 2>/dev/null; then
            echo "FRAMEWORK=django"
        else
            echo "FRAMEWORK=python"
        fi
    else
        echo "LANGUAGE=unknown"
        echo "FRAMEWORK=unknown"
    fi
}

# Detect Services Directory
detect_services_dir() {
    for dir in "backend/services" "src/services" "services" "lib/services" "app/services"; do
        if [ -d "$dir" ]; then
            echo "SERVICES_DIR=$dir"
            return
        fi
    done
    echo "SERVICES_DIR=not_found"
}

# Detect Routes Directory
detect_routes_dir() {
    for dir in "backend/routes" "src/routes" "routes" "api/routes" "app/api" "backend/api"; do
        if [ -d "$dir" ]; then
            echo "ROUTES_DIR=$dir"
            return
        fi
    done
    echo "ROUTES_DIR=not_found"
}

# Detect Code Style (functional vs class-based)
detect_code_style() {
    local services_dir=""
    for dir in "backend/services" "src/services" "services" "lib/services" "app/services"; do
        if [ -d "$dir" ]; then
            services_dir="$dir"
            break
        fi
    done

    if [ -z "$services_dir" ]; then
        echo "CODE_STYLE=functional"
        return
    fi

    # Check for class-based patterns in service files
    local class_count=0
    local func_count=0

    for file in "$services_dir"/*.ts "$services_dir"/*.py "$services_dir"/*/*.ts "$services_dir"/*/*.py; do
        if [ -f "$file" ]; then
            if grep -q "^export class\|^class " "$file" 2>/dev/null; then
                ((class_count++))
            fi
            if grep -q "^export function\|^export async function\|^async def\|^def " "$file" 2>/dev/null; then
                ((func_count++))
            fi
        fi
    done

    if [ "$class_count" -gt "$func_count" ]; then
        echo "CODE_STYLE=class-based"
    else
        echo "CODE_STYLE=functional"
    fi
}

# Check for Barrel Exports
detect_barrel_exports() {
    if [ -f "backend/services/index.ts" ] || [ -f "src/services/index.ts" ] || [ -f "services/index.ts" ]; then
        echo "HAS_BARREL=true"
    elif [ -f "backend/services/__init__.py" ] || [ -f "src/services/__init__.py" ] || [ -f "services/__init__.py" ]; then
        echo "HAS_BARREL=true"
    else
        echo "HAS_BARREL=false"
    fi
}

# Detect Entry Point
detect_entry_point() {
    for file in "backend/server.ts" "backend/index.ts" "src/server.ts" "src/index.ts" "server.ts" "index.ts"; do
        if [ -f "$file" ]; then
            echo "ENTRY_POINT=$file"
            return
        fi
    done
    for file in "backend/main.py" "src/main.py" "main.py" "app.py"; do
        if [ -f "$file" ]; then
            echo "ENTRY_POINT=$file"
            return
        fi
    done
    echo "ENTRY_POINT=not_found"
}

# Run all detections
detect_framework
detect_services_dir
detect_routes_dir
detect_code_style
detect_barrel_exports
detect_entry_point
echo "PROJECT_ROOT=$(pwd)"
