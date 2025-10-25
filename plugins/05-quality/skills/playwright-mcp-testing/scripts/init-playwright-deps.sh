#!/usr/bin/env bash

# Playwright MCP Testing - Dependency Initialization Script
# Initializes or merges required dependencies into project package.json

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")/templates"
TEMPLATE_FILE="$TEMPLATE_DIR/package.json.template"
PROJECT_ROOT="${1:-.}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎭 Playwright MCP Testing - Dependency Initialization${NC}"
echo "=================================================="

# Check if we're in a project directory
if [ ! -d "$PROJECT_ROOT" ]; then
    echo -e "${YELLOW}⚠️  Project directory not found: $PROJECT_ROOT${NC}"
    exit 1
fi

cd "$PROJECT_ROOT"

# Function to check if Node.js is installed
check_node() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}❌ Node.js is not installed${NC}"
        echo "Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi

    local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_version" -lt 18 ]; then
        echo -e "${YELLOW}⚠️  Node.js version is $node_version, but 18+ is required${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Node.js $(node --version) detected${NC}"
}

# Function to initialize package.json from template
init_from_template() {
    echo -e "${BLUE}📦 Creating package.json from template...${NC}"

    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo -e "${YELLOW}❌ Template file not found: $TEMPLATE_FILE${NC}"
        exit 1
    fi

    cp "$TEMPLATE_FILE" package.json
    echo -e "${GREEN}✅ package.json created${NC}"
}

# Function to merge dependencies into existing package.json
merge_dependencies() {
    echo -e "${BLUE}🔄 Merging Playwright MCP dependencies into existing package.json...${NC}"

    # Use Node.js to merge the dependencies
    node - <<'EOF'
const fs = require('fs');
const path = require('path');

const templatePath = process.env.TEMPLATE_FILE;
const projectPackagePath = 'package.json';

const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
const projectPackage = JSON.parse(fs.readFileSync(projectPackagePath, 'utf8'));

// Merge devDependencies
if (!projectPackage.devDependencies) {
    projectPackage.devDependencies = {};
}

Object.assign(projectPackage.devDependencies, template.devDependencies);

// Merge scripts
if (!projectPackage.scripts) {
    projectPackage.scripts = {};
}

// Add our scripts with 'pw:' prefix to avoid conflicts
Object.entries(template.scripts).forEach(([key, value]) => {
    const prefixedKey = key.startsWith('test') ? `pw:${key}` : key;
    if (!projectPackage.scripts[prefixedKey]) {
        projectPackage.scripts[prefixedKey] = value;
    }
});

// Write back
fs.writeFileSync(projectPackagePath, JSON.stringify(projectPackage, null, 2) + '\n');

console.log('✅ Dependencies merged successfully');
EOF

    echo -e "${GREEN}✅ package.json updated${NC}"
}

# Function to install dependencies
install_dependencies() {
    echo -e "${BLUE}📥 Installing dependencies...${NC}"

    if command -v npm &> /dev/null; then
        npm install
        echo -e "${GREEN}✅ Dependencies installed${NC}"
    else
        echo -e "${YELLOW}⚠️  npm not found, skipping installation${NC}"
        echo "Run 'npm install' manually to install dependencies"
    fi
}

# Function to verify Playwright MCP server
verify_mcp_server() {
    echo -e "${BLUE}🔍 Verifying Playwright MCP server installation...${NC}"

    if [ -d "node_modules/@executeautomation/playwright-mcp-server" ]; then
        echo -e "${GREEN}✅ Playwright MCP server installed${NC}"

        # Check if server is running
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ MCP server is already running${NC}"
        else
            echo -e "${YELLOW}ℹ️  MCP server not running (this is OK)${NC}"
            echo "   Start it with: npx @executeautomation/playwright-mcp-server"
        fi
    else
        echo -e "${YELLOW}⚠️  Playwright MCP server not found in node_modules${NC}"
        echo "   Run: npm install"
    fi
}

# Main execution
main() {
    echo ""
    check_node
    echo ""

    # Set TEMPLATE_FILE environment variable for Node.js script
    export TEMPLATE_FILE

    if [ -f "package.json" ]; then
        echo -e "${YELLOW}📋 Existing package.json found${NC}"
        merge_dependencies
    else
        echo -e "${YELLOW}📋 No package.json found${NC}"
        init_from_template
    fi

    echo ""
    install_dependencies
    echo ""
    verify_mcp_server
    echo ""

    echo -e "${GREEN}🎉 Playwright MCP Testing is ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Start MCP server: npx @executeautomation/playwright-mcp-server"
    echo "  2. Run tests: npm run pw:test"
    echo "  3. Or use: ./plugins/05-quality/skills/playwright-mcp-testing/scripts/key-moments.sh manual"
    echo ""
}

main "$@"
