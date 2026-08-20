#!/bin/bash
# Start the PDF Analysis Server
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

echo "Starting PDF Analysis Server..."
echo "==============================="

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo "Installing dependencies..."
pip install -q -r requirements.txt

# Check if Ollama is running
echo "Checking Ollama connection..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✓ Ollama is running"
else
    echo "✗ Ollama is not running!"
    echo "Please start Ollama with: ollama serve"
    exit 1
fi

# Start the server
echo "Starting FastAPI server on http://localhost:8000"
echo "API documentation: http://localhost:8000/docs"
echo "==============================="
python main.py
