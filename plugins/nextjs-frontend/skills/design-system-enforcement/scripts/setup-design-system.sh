#!/bin/bash

# Design System Setup Script
# Generates a configured design-system.md file in the project root

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/design-system-template.md"
PROJECT_ROOT="${1:-.}"
OUTPUT_FILE="$PROJECT_ROOT/design-system.md"

echo "🎨 Design System Setup"
echo "====================="
echo ""

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Check if design system already exists
if [ -f "$OUTPUT_FILE" ]; then
    echo "⚠️  Design system file already exists at $OUTPUT_FILE"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo "📝 Project Configuration"
echo "------------------------"
echo ""

# Gather project information
read -p "Project Name: " PROJECT_NAME
read -p "Primary Brand Color (hex or name): " BRAND_COLOR
read -p "Color Scheme (light/dark/both) [both]: " COLOR_SCHEME
COLOR_SCHEME=${COLOR_SCHEME:-both}

echo ""
echo "📏 Typography Configuration"
echo "---------------------------"
echo "Using 4 font sizes (enforced):"
echo "  Size 1: Large headings"
echo "  Size 2: Subheadings"
echo "  Size 3: Body text"
echo "  Size 4: Small text"
echo ""

read -p "Size 1 (e.g., text-2xl or 24px) [text-2xl]: " FONT_SIZE_1
FONT_SIZE_1=${FONT_SIZE_1:-text-2xl}

read -p "Size 2 (e.g., text-lg or 18px) [text-lg]: " FONT_SIZE_2
FONT_SIZE_2=${FONT_SIZE_2:-text-lg}

read -p "Size 3 (e.g., text-base or 16px) [text-base]: " FONT_SIZE_3
FONT_SIZE_3=${FONT_SIZE_3:-text-base}

read -p "Size 4 (e.g., text-sm or 14px) [text-sm]: " FONT_SIZE_4
FONT_SIZE_4=${FONT_SIZE_4:-text-sm}

echo ""
echo "🎨 Color Configuration (OKLCH format)"
echo "-------------------------------------"
echo "You can provide OKLCH values or use defaults"
echo ""

read -p "Background OKLCH [oklch(1 0 0)]: " BACKGROUND_OKLCH
BACKGROUND_OKLCH=${BACKGROUND_OKLCH:-oklch(1 0 0)}

read -p "Foreground OKLCH [oklch(0.145 0 0)]: " FOREGROUND_OKLCH
FOREGROUND_OKLCH=${FOREGROUND_OKLCH:-oklch(0.145 0 0)}

read -p "Primary (Brand) OKLCH [oklch(0.549 0.175 252.417)]: " PRIMARY_OKLCH
PRIMARY_OKLCH=${PRIMARY_OKLCH:-oklch(0.549 0.175 252.417)}

read -p "Primary Foreground OKLCH [oklch(0.985 0 0)]: " PRIMARY_FOREGROUND_OKLCH
PRIMARY_FOREGROUND_OKLCH=${PRIMARY_FOREGROUND_OKLCH:-oklch(0.985 0 0)}

read -p "Muted OKLCH [oklch(0.961 0 0)]: " MUTED_OKLCH
MUTED_OKLCH=${MUTED_OKLCH:-oklch(0.961 0 0)}

read -p "Muted Foreground OKLCH [oklch(0.478 0 0)]: " MUTED_FOREGROUND_OKLCH
MUTED_FOREGROUND_OKLCH=${MUTED_FOREGROUND_OKLCH:-oklch(0.478 0 0)}

echo ""
echo "🌙 Dark Mode Colors"
echo "------------------"
echo ""

read -p "Dark Background OKLCH [oklch(0.145 0 0)]: " DARK_BACKGROUND_OKLCH
DARK_BACKGROUND_OKLCH=${DARK_BACKGROUND_OKLCH:-oklch(0.145 0 0)}

read -p "Dark Foreground OKLCH [oklch(0.985 0 0)]: " DARK_FOREGROUND_OKLCH
DARK_FOREGROUND_OKLCH=${DARK_FOREGROUND_OKLCH:-oklch(0.985 0 0)}

read -p "Dark Primary OKLCH [oklch(0.649 0.175 252.417)]: " DARK_PRIMARY_OKLCH
DARK_PRIMARY_OKLCH=${DARK_PRIMARY_OKLCH:-oklch(0.649 0.175 252.417)}

read -p "Dark Primary Foreground OKLCH [oklch(0.145 0 0)]: " DARK_PRIMARY_FOREGROUND_OKLCH
DARK_PRIMARY_FOREGROUND_OKLCH=${DARK_PRIMARY_FOREGROUND_OKLCH:-oklch(0.145 0 0)}

echo ""
read -p "Figma Design System URL (optional): " FIGMA_URL

# Generate the design system file
echo ""
echo "⚙️  Generating design system file..."

cp "$TEMPLATE_FILE" "$OUTPUT_FILE"

# Replace placeholders
sed -i "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$OUTPUT_FILE"
sed -i "s|{{BRAND_COLOR}}|$BRAND_COLOR|g" "$OUTPUT_FILE"
sed -i "s|{{COLOR_SCHEME}}|$COLOR_SCHEME|g" "$OUTPUT_FILE"
sed -i "s|{{FONT_SIZE_1}}|$FONT_SIZE_1|g" "$OUTPUT_FILE"
sed -i "s|{{FONT_SIZE_2}}|$FONT_SIZE_2|g" "$OUTPUT_FILE"
sed -i "s|{{FONT_SIZE_3}}|$FONT_SIZE_3|g" "$OUTPUT_FILE"
sed -i "s|{{FONT_SIZE_4}}|$FONT_SIZE_4|g" "$OUTPUT_FILE"
sed -i "s|{{BACKGROUND_OKLCH}}|$BACKGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{FOREGROUND_OKLCH}}|$FOREGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{PRIMARY_OKLCH}}|$PRIMARY_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{PRIMARY_FOREGROUND_OKLCH}}|$PRIMARY_FOREGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{MUTED_OKLCH}}|$MUTED_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{MUTED_FOREGROUND_OKLCH}}|$MUTED_FOREGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{DARK_BACKGROUND_OKLCH}}|$DARK_BACKGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{DARK_FOREGROUND_OKLCH}}|$DARK_FOREGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{DARK_PRIMARY_OKLCH}}|$DARK_PRIMARY_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{DARK_PRIMARY_FOREGROUND_OKLCH}}|$DARK_PRIMARY_FOREGROUND_OKLCH|g" "$OUTPUT_FILE"
sed -i "s|{{FIGMA_URL}}|$FIGMA_URL|g" "$OUTPUT_FILE"
sed -i "s|{{LAST_UPDATED}}|$(date +"%B %d, %Y")|g" "$OUTPUT_FILE"

echo ""
echo "✅ Design system configuration complete!"
echo ""
echo "📄 File created: $OUTPUT_FILE"
echo ""
echo "🚀 Next Steps:"
echo "   1. Review the generated design-system.md file"
echo "   2. All agents will automatically read this file before creating UI"
echo "   3. Configure your globals.css with the color variables"
echo "   4. Install shadcn/ui components as needed"
echo ""
echo "⚠️  IMPORTANT: All UI development must follow these guidelines!"
