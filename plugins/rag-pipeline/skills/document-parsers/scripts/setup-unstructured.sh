#!/bin/bash

# Setup Unstructured.io for multi-format document parsing
# Usage: ./setup-unstructured.sh [--with-ocr]

set -e

echo "Setting up Unstructured.io..."

# Parse command line arguments
WITH_OCR=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-ocr)
            WITH_OCR=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--with-ocr]"
            exit 1
            ;;
    esac
done

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    OS="windows"
fi

echo "Detected OS: $OS"

# Install system dependencies
echo "Installing system dependencies..."
if [ "$OS" = "linux" ]; then
    # Check if running with sudo
    if [ "$EUID" -ne 0 ]; then
        echo "Installing system packages (may require sudo password)..."
        sudo apt-get update
        sudo apt-get install -y poppler-utils libmagic-dev

        if [ "$WITH_OCR" = true ]; then
            echo "Installing OCR dependencies..."
            sudo apt-get install -y tesseract-ocr libtesseract-dev
        fi
    else
        apt-get update
        apt-get install -y poppler-utils libmagic-dev

        if [ "$WITH_OCR" = true ]; then
            apt-get install -y tesseract-ocr libtesseract-dev
        fi
    fi

elif [ "$OS" = "macos" ]; then
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew not found. Install from https://brew.sh"
        exit 1
    fi

    brew install poppler libmagic

    if [ "$WITH_OCR" = true ]; then
        echo "Installing OCR dependencies..."
        brew install tesseract
    fi

elif [ "$OS" = "windows" ]; then
    echo "Warning: Windows detected. Manual installation may be required."
    echo "Install poppler and libmagic using conda or pre-built binaries"
fi

# Install Python packages
echo "Installing Python packages..."
if [ "$WITH_OCR" = true ]; then
    pip install "unstructured[local-inference]" pytesseract
else
    pip install "unstructured[local-inference]"
fi

# Install additional dependencies for various formats
pip install python-magic-bin pillow pdf2image python-docx markdown beautifulsoup4 lxml

# Create test script
cat > test_unstructured.py <<'EOF'
#!/usr/bin/env python3
"""Test Unstructured installation"""

import sys

# Test imports
print("Testing imports...")
try:
    from unstructured.partition.auto import partition
    print("✓ unstructured imported successfully")
except ImportError as e:
    print(f"✗ Failed to import unstructured: {e}")
    sys.exit(1)

try:
    import magic
    print("✓ python-magic imported successfully")
except ImportError as e:
    print(f"✗ Failed to import python-magic: {e}")
    print("  Try: pip install python-magic-bin")
    sys.exit(1)

# Test PDF support
try:
    from unstructured.partition.pdf import partition_pdf
    print("✓ PDF support available")
except ImportError:
    print("✗ PDF support not available")

# Test DOCX support
try:
    from unstructured.partition.docx import partition_docx
    print("✓ DOCX support available")
except ImportError:
    print("✗ DOCX support not available")

# Test HTML support
try:
    from unstructured.partition.html import partition_html
    print("✓ HTML support available")
except ImportError:
    print("✗ HTML support not available")

# Test OCR
try:
    import pytesseract
    tesseract_version = pytesseract.get_tesseract_version()
    print(f"✓ OCR support available (Tesseract {tesseract_version})")
except:
    print("✗ OCR support not available (optional)")

print("\nUnstructured.io is ready to use!")
print("\nExample usage:")
print("  from unstructured.partition.auto import partition")
print("  elements = partition('document.pdf')")
print("  for element in elements:")
print("      print(f'{element.category}: {element.text}')")
EOF

chmod +x test_unstructured.py

# Run test
echo ""
echo "Testing installation..."
python3 test_unstructured.py

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Use parse-pdf.py with Unstructured backend"
echo "  2. See templates/multi-format-parser.py for integration"
echo "  3. Process multiple formats: PDF, DOCX, HTML, PPTX, Images"
echo ""
if [ "$WITH_OCR" = true ]; then
    echo "OCR enabled: Can process scanned documents and images"
fi
