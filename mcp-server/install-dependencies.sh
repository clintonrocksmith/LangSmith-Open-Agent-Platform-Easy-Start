#!/bin/bash

set -e

echo "🚀 Setting up MCP Server dependencies..."

# Check if we're in a virtual environment
if [[ "$VIRTUAL_ENV" != "" ]]; then
    echo "✅ Virtual environment detected: $VIRTUAL_ENV"
else
    echo "❌ No virtual environment detected. Please activate the virtual environment first:"
    echo "   Windows: Scripts\\activate"
    echo "   Unix: bin/activate"
    exit 1
fi

# Install dependencies
echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Test imports
echo "🔍 Testing imports..."
python -c "
import uvicorn
from mcp.server import FastMCP
import aiohttp
import requests
import pandas
print('✅ All imports successful')
"

echo "🎉 MCP Server setup complete!"
echo ""
echo "To run the server:"
echo "1. cd custom_mcp_server"
echo "2. python main.py"
echo ""
echo "The server will be available at http://localhost:8002"
