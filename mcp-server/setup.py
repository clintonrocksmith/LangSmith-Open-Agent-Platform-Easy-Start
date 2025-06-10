#!/usr/bin/env python3
"""
Setup script for Custom MCP Server
"""

import os
import sys
import subprocess
import platform

def main():
    """Main setup function"""
    print("🚀 Setting up Custom MCP Server...")
    
    # Check Python version
    if sys.version_info < (3, 11):
        print("❌ Error: Python 3.11+ is required")
        sys.exit(1)
    
    print(f"✅ Python {sys.version.split()[0]} detected")
    
    # Install dependencies
    print("📦 Installing dependencies...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], 
                      check=True, capture_output=True, text=True)
        print("✅ Dependencies installed successfully")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error installing dependencies: {e}")
        print(f"Output: {e.stdout}")
        print(f"Error: {e.stderr}")
        sys.exit(1)
    
    # Test imports
    print("🔍 Testing imports...")
    try:
        import uvicorn
        from mcp.server import FastMCP
        import aiohttp
        import requests
        import pandas
        print("✅ All imports successful")
    except ImportError as e:
        print(f"❌ Import error: {e}")
        sys.exit(1)
    
    print("🎉 Setup complete! You can now run:")
    print("   python custom_mcp_server/main.py")

if __name__ == "__main__":
    main()
