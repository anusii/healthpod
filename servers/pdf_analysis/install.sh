#!/bin/bash
# Simple installation script for PDF Analysis Server.
#
# Copyright (C) 2025, Software Innovation Institute ANU
#
# Licensed under the GNU General Public License, Version 3 (the "License");
#
# License: https://opensource.org/license/gpl-3-0
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://opensource.org/license/gpl-3-0>.
#
# Authors: Tony Chen

set -e

echo "=========================================="
echo "PDF Analysis Server - Quick Install"
echo "=========================================="
echo ""

# Check Python 3.11 or 3.12 (not 3.13)
if command -v python3.12 &> /dev/null; then
    PYTHON_CMD=python3.12
    echo "✓ Using Python 3.12"
elif command -v python3.11 &> /dev/null; then
    PYTHON_CMD=python3.11
    echo "✓ Using Python 3.11"
elif command -v python3 &> /dev/null; then
    VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    if [[ "$VERSION" == "3.11" ]] || [[ "$VERSION" == "3.12" ]]; then
        PYTHON_CMD=python3
        echo "✓ Using Python $VERSION"
    else
        echo "⚠️  Warning: Python 3.13 has compatibility issues"
        echo "   Recommended: Install Python 3.11 or 3.12"
        echo "   Trying anyway with python3..."
        PYTHON_CMD=python3
    fi
else
    echo "✗ Python 3 not found"
    echo "  Please install Python 3.11 or 3.12"
    exit 1
fi

# Check Ollama
if ! command -v ollama &> /dev/null; then
    echo "✗ Ollama not found"
    echo "  Please install from: https://ollama.com"
    exit 1
fi
echo "✓ Ollama found"

# Create virtual environment
echo ""
echo "Creating virtual environment..."
rm -rf venv
$PYTHON_CMD -m venv venv
echo "✓ Virtual environment created"

# Activate and install
echo ""
echo "Installing packages..."
source venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Installation successful!"
else
    echo "✗ Installation failed"
    echo ""
    echo "If you see pydantic errors with Python 3.13:"
    echo "1. Install Python 3.11 or 3.12"
    echo "2. Run: brew install python@3.12 or"
    echo "   Run: sudo apt install -y python3.12 python3.12-venv python3.12-dev"
    echo "3. Run this script again"
    exit 1
fi

# Check Ollama status
echo ""
echo "Checking Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✓ Ollama is running"
    
    if ollama list | grep -q "qwen3:8b"; then
        echo "✓ qwen3:8b model installed"
    else
        echo "⚠️  Installing qwen3:8b model..."
        ollama pull qwen3:8b
    fi
else
    echo "⚠️  Ollama not running"
    echo "   Start it with: ollama serve"
fi

echo ""
echo "=========================================="
echo "Installation Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start Ollama (if not running):"
echo "   ollama serve"
echo ""
echo "2. Start the server:"
echo "   ./run.sh"
echo ""
echo "3. Test the server:"
echo "   python test_server.py"
echo ""
