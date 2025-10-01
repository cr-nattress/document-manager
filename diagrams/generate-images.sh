#!/bin/bash

# Shell script to generate images from Mermaid diagrams
# Requires: Node.js and @mermaid-js/mermaid-cli installed globally
# Install: npm install -g @mermaid-js/mermaid-cli

echo ""
echo "=== Mermaid Diagram to Image Generator ==="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js not found!"
    echo "Please install Node.js from https://nodejs.org"
    echo ""
    exit 1
fi

# Check if mmdc is installed
if ! command -v mmdc &> /dev/null; then
    echo "ERROR: mermaid-cli (mmdc) not found!"
    echo "Please install it with: npm install -g @mermaid-js/mermaid-cli"
    echo ""
    exit 1
fi

echo "Found Node.js and mermaid-cli"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Run the Node.js script
node "$SCRIPT_DIR/generate-images.js"

echo ""
