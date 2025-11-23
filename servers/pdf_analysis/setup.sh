#!/bin/bash
# Setup Script for PDF Analysis Server
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

set -e  # Exit on error

echo "============================================="
echo "PDF Analysis Server Setup"
echo "============================================="
echo ""

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

# Function to print success messages
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error messages
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info messages
info() {
    echo -e "  $1"
}

echo "Step 1: Checking prerequisites..."
echo ""

# Check Python version
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    success "Python 3 found: $PYTHON_VERSION"
else
    error "Python 3 not found"
    info "Please install Python 3.8 or higher"
    exit 1
fi

# Check if Ollama is installed
if command -v ollama &> /dev/null; then
    success "Ollama found"
else
    error "Ollama not found"
    info "Please install Ollama from: https://ollama.com"
    exit 1
fi

# Check if Tesseract is installed
if command -v tesseract &> /dev/null; then
    TESSERACT_VERSION=$(tesseract --version 2>&1 | head -n1)
    success "Tesseract OCR found: $TESSERACT_VERSION"
else
    error "Tesseract OCR not found"
    info "Please install Tesseract:"
    info "  macOS: brew install tesseract"
    info "  Ubuntu/Debian: sudo apt-get install tesseract-ocr"
    info "  Fedora/RHEL: sudo dnf install tesseract"
    exit 1
fi

# Check if Poppler is installed (optional but recommended)
if command -v pdfinfo &> /dev/null; then
    POPPLER_VERSION=$(pdfinfo -v 2>&1 | grep -i version | head -n1)
    success "Poppler found: $POPPLER_VERSION"
else
    warning "Poppler not found (optional, but recommended for pdf2image)"
    info "To install Poppler:"
    info "  macOS: brew install poppler"
    info "  Ubuntu/Debian: sudo apt-get install poppler-utils"
    info "  Fedora/RHEL: sudo dnf install poppler-utils"
fi

echo ""
echo "Step 2: Setting up Python environment..."
echo ""

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    info "Creating virtual environment..."
    python3 -m venv venv
    success "Virtual environment created"
else
    warning "Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate
success "Virtual environment activated"

# Upgrade pip
info "Upgrading pip..."
pip install --upgrade pip --quiet
success "Pip upgraded"

echo ""
echo "Step 3: Installing Python dependencies..."
echo ""

# Install requirements
info "Installing packages (this may take a minute)..."
pip install -r requirements.txt --quiet
success "All Python packages installed"

echo ""
echo "Step 4: Checking Ollama status..."
echo ""

# Check if Ollama is running
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    success "Ollama server is running"
    
    # Check if qwen3:8b model is installed
    if ollama list | grep -q "qwen3:8b"; then
        success "qwen3:8b model is installed"
    else
        warning "qwen3:8b model not found"
        info "Pulling qwen3:8b model (this will take a few minutes)..."
        ollama pull qwen3:8b
        success "qwen3:8b model installed"
    fi
else
    warning "Ollama server is not running"
    info "Starting Ollama server in background..."
    ollama serve > /dev/null 2>&1 &
    sleep 2
    
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        success "Ollama server started"
        
        # Pull model
        info "Pulling qwen3:8b model (this will take a few minutes)..."
        ollama pull qwen3:8b
        success "qwen3:8b model installed"
    else
        error "Failed to start Ollama server"
        info "Please start Ollama manually: ollama serve"
        exit 1
    fi
fi

echo ""
echo "Step 5: Running tests..."
echo ""

# Test the installation
info "Testing server setup..."
python -c "
import sys
try:
    from fastapi import FastAPI
    import requests
    import pdfplumber
    import pytesseract
    import fitz  # PyMuPDF
    print('✓ All imports successful')
    sys.exit(0)
except ImportError as e:
    print(f'✗ Import error: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    success "Setup validation passed"
else
    error "Setup validation failed"
    exit 1
fi

echo ""
echo "============================================="
echo "Setup Complete"
echo "============================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Start the server:"
echo "   ./run.sh"
echo ""
echo "2. Test the server:"
echo "   python test_server.py"
echo "   python test_server.py /path/to/sample.pdf"
echo ""
echo "3. View API documentation:"
echo "   http://localhost:8000/docs"
echo ""
echo "4. Update your Flutter app:"
echo "   cd ../.."
echo "   flutter pub get"
echo ""
echo "The server now provides complete PDF analysis:"
echo "  • PDF text extraction (PyMuPDF, pdfplumber, PyPDF2)"
echo "  • OCR fallback (Tesseract, EasyOCR)"
echo "  • LLM analysis (Ollama + Qwen3:8b)"
echo "  • Unit validation and normalisation"
echo ""
success "Ready to analyse pathology reports!"
echo ""
