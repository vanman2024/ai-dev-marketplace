#!/bin/bash

# add-nextjs-component.sh - Generate Next.js ML prediction form component
# Usage: ./add-nextjs-component.sh <component-type> <component-name>

set -e

COMPONENT_TYPE=$1
COMPONENT_NAME=$2

if [ -z "$COMPONENT_TYPE" ] || [ -z "$COMPONENT_NAME" ]; then
    echo "Usage: ./add-nextjs-component.sh <component-type> <component-name>"
    echo ""
    echo "Component types:"
    echo "  - classification-form: Text input classification form"
    echo "  - regression-form: Numeric input regression form"
    echo "  - image-upload: Image upload and classification"
    echo "  - chat-interface: Chat interface for LLM interaction"
    echo ""
    echo "Example: ./add-nextjs-component.sh classification-form sentiment-form"
    exit 1
fi

# Determine current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../templates"

# Check if we're in a Next.js project
if [ ! -f "package.json" ] && [ ! -f "next.config.js" ] && [ ! -f "next.config.mjs" ]; then
    echo "Warning: Not in a Next.js project root."
fi

# Find components directory
if [ -d "components/ml" ]; then
    COMPONENTS_DIR="components/ml"
elif [ -d "components" ]; then
    COMPONENTS_DIR="components/ml"
    mkdir -p "$COMPONENTS_DIR"
elif [ -d "src/components" ]; then
    COMPONENTS_DIR="src/components/ml"
    mkdir -p "$COMPONENTS_DIR"
else
    COMPONENTS_DIR="components/ml"
    mkdir -p "$COMPONENTS_DIR"
fi

# Create component filename
COMPONENT_FILE="$COMPONENTS_DIR/${COMPONENT_NAME}.tsx"

if [ -f "$COMPONENT_FILE" ]; then
    echo "Error: Component file already exists: $COMPONENT_FILE"
    echo "Choose a different component name or delete the existing file."
    exit 1
fi

echo "Generating Next.js ML component..."
echo "  Component Type: $COMPONENT_TYPE"
echo "  Component Name: $COMPONENT_NAME"
echo "  Output File: $COMPONENT_FILE"

# Convert kebab-case to PascalCase for component name
COMPONENT_CLASS=$(echo "$COMPONENT_NAME" | sed -r 's/(^|-)([a-z])/\U\2/g')

# Generate component based on type
case $COMPONENT_TYPE in
    classification-form)
        cat "$TEMPLATES_DIR/nextjs-prediction-form.tsx" | \
        sed "s/{{COMPONENT_NAME}}/$COMPONENT_CLASS/g" | \
        sed "s/{{FORM_TYPE}}/classification/g" > "$COMPONENT_FILE"
        ;;
    regression-form)
        cat "$TEMPLATES_DIR/nextjs-prediction-form.tsx" | \
        sed "s/{{COMPONENT_NAME}}/$COMPONENT_CLASS/g" | \
        sed "s/{{FORM_TYPE}}/regression/g" | \
        sed 's/text: z\.string/features: z.array(z.number())/g' > "$COMPONENT_FILE"
        ;;
    image-upload)
        cat "$TEMPLATES_DIR/nextjs-prediction-form.tsx" | \
        sed "s/{{COMPONENT_NAME}}/$COMPONENT_CLASS/g" | \
        sed "s/{{FORM_TYPE}}/image-upload/g" | \
        sed 's/Textarea/Input type="file"/g' > "$COMPONENT_FILE"
        ;;
    chat-interface)
        cat "$TEMPLATES_DIR/nextjs-prediction-form.tsx" | \
        sed "s/{{COMPONENT_NAME}}/$COMPONENT_CLASS/g" | \
        sed "s/{{FORM_TYPE}}/chat/g" | \
        sed 's/Analyze/Send/g' > "$COMPONENT_FILE"
        ;;
    *)
        echo "Error: Unknown component type: $COMPONENT_TYPE"
        echo "Valid types: classification-form, regression-form, image-upload, chat-interface"
        exit 1
        ;;
esac

echo ""
echo "✓ Next.js ML component created: $COMPONENT_FILE"
echo ""
echo "Next steps:"
echo "  1. Install dependencies if not already installed:"
echo "     npm install react-hook-form @hookform/resolvers zod"
echo "     npx shadcn@latest add button textarea card"
echo "  2. Import and use the component in your page:"
echo "     import { $COMPONENT_CLASS } from '@/components/ml/${COMPONENT_NAME}'"
echo "     <$COMPONENT_CLASS />"
echo "  3. Create API route for ML predictions: app/api/ml/predict/route.ts"
echo "  4. Configure FASTAPI_URL environment variable"
